#!/usr/bin/env nextflow

/*
 * =============================================================================
 *  parallel-o-smash
 *  Parallel antiSMASH 8 runs across many genomes, powered by Nextflow.
 * =============================================================================
 */

nextflow.enable.dsl = 2

// =============================================================================
//  HELP MESSAGE
// =============================================================================
def helpMessage() {
    log.info """
    ===============================================================================
     ${workflow.manifest.name} ${workflow.manifest.version}
     ${workflow.manifest.description}
    ===============================================================================

    Usage:
      nextflow run main.nf --input <glob|samplesheet.csv> [options] -profile <profile>

    Required:
      --input            Glob to FASTAs (e.g. "/data/*.fasta") OR a path to
                         a CSV/TSV samplesheet with columns: sample,fasta,gff

    Common options:
      --outdir           Output directory                    (default: ${params.outdir})
      --cpus             CPUs per task                       (default: ${params.cpus})
      --memory           Memory per task                     (default: ${params.memory})
      --time             Wallclock per task                  (default: ${params.time})
      --taxon            bacteria | fungi                    (default: ${params.taxon})
      --use_gff          true | false                        (default: ${params.use_gff})
      --gff_pattern      GFF filename next to each FASTA     (default: ${params.gff_pattern})
      --genefinding_tool prodigal | prodigal-m | none | error (default: error — must set explicitly when no GFF)
      --databases        Path to antiSMASH databases         (default: bundled)
      --extra_args       Free-form extra antiSMASH flags (quoted)

    antiSMASH presets/toggles:
      --as_preset        fast | balanced | full | minimal    (default: ${params.as_preset})
      --fullhmmer / --clusterhmmer / --tigrfam / --cc_mibig / --asf
      --cb_general / --cb_subclusters / --cb_knownclusters / --pfam2go
      --rre (--rre_cutoff N) / --smcog_trees / --tfbs / --cassis
      --allow_long_headers / --html_start_compact / --html_ncbi_context
      (each takes true/false to override the preset)

    Profiles (combine with comma):
      -profile standard      Run locally
      -profile slurm         Submit to SLURM
      -profile docker        Use the antiSMASH Docker image
      -profile singularity   Use the antiSMASH Singularity image

    Examples:
      nextflow run main.nf --input '/data/*.fasta' -profile slurm
      nextflow run main.nf --input samples.csv --as_preset full -profile slurm,singularity
      nextflow run main.nf --input '/data/*.fa' --as_preset balanced --fullhmmer true -resume
    """.stripIndent()
}

// =============================================================================
//  PARAMETER VALIDATION
// =============================================================================
if (params.help) {
    helpMessage()
    exit 0
}

if (!params.input) {
    log.error "Missing required parameter: --input"
    helpMessage()
    exit 1
}

if (!(params.as_preset in ['fast', 'balanced', 'full', 'minimal'])) {
    log.error "--as_preset must be one of: fast, balanced, full, minimal (got '${params.as_preset}')"
    exit 1
}

if (!(params.taxon in ['bacteria', 'fungi'])) {
    log.error "--taxon must be one of: bacteria, fungi (got '${params.taxon}')"
    exit 1
}

if (!(params.genefinding_tool in ['prodigal', 'prodigal-m', 'none', 'error'])) {
    log.error "--genefinding_tool must be one of: prodigal, prodigal-m, none, error (got '${params.genefinding_tool}')"
    exit 1
}

// =============================================================================
//  ANTISMASH PRESET + TOGGLE MERGE
// =============================================================================
//
// Each preset is a map of {flag -> on/off}. Per-flag CLI params override the
// preset entry when not null. The list `MODULE_KEYS` is the authoritative
// list of toggleable antiSMASH modules.
//
def MODULE_KEYS = [
    'fullhmmer', 'clusterhmmer', 'tigrfam', 'cc_mibig', 'asf',
    'cb_general', 'cb_subclusters', 'cb_knownclusters', 'pfam2go',
    'rre', 'smcog_trees', 'tfbs', 'cassis',
    'allow_long_headers', 'html_start_compact', 'html_ncbi_context'
]

def PRESETS = [
    fast: [
        cb_knownclusters: true, cc_mibig: true,
        allow_long_headers: true, html_start_compact: true
    ],
    balanced: [
        cb_general: true, cb_subclusters: true, cb_knownclusters: true,
        cc_mibig: true, asf: true, pfam2go: true, smcog_trees: true, rre: true,
        allow_long_headers: true, html_start_compact: true
    ],
    full: [
        fullhmmer: true, clusterhmmer: true, tigrfam: true,
        cb_general: true, cb_subclusters: true, cb_knownclusters: true,
        cc_mibig: true, asf: true, pfam2go: true, smcog_trees: true,
        rre: true, tfbs: true,
        allow_long_headers: true, html_start_compact: true, html_ncbi_context: true
    ],
    minimal: [:]
]

def resolveAntismashFlags() {
    // Start with preset defaults (false for unset keys)
    def cfg = [:]
    MODULE_KEYS.each { cfg[it] = false }
    PRESETS[params.as_preset].each { k, v -> cfg[k] = v }

    // Apply per-flag overrides (null = inherit)
    MODULE_KEYS.each { k ->
        if (params.containsKey(k) && params[k] != null) {
            cfg[k] = params[k] as Boolean
        }
    }

    def flags = []
    if (params.as_preset == 'minimal') flags << '--minimal'

    cfg.each { k, v ->
        if (v) {
            // Convert snake_case -> --kebab-case (antiSMASH flag style)
            flags << "--${k.replace('_', '-')}"
        }
    }

    if (cfg.rre) {
        flags << "--rre-cutoff ${params.rre_cutoff}"
    }
    return flags.join(' ')
}

// =============================================================================
//  PROCESS: ANTISMASH
// =============================================================================
process ANTISMASH {

    tag "$sample_id"

    input:
    tuple val(sample_id), path(fasta), path(gff)
    val   as_flags

    output:
    path "${sample_id}", emit: results

    script:
    // When a GFF is provided antiSMASH does not need a gene-finder; suppress --genefinding-tool.
    // When no GFF is provided the default (error) forces the user to explicitly choose a tool,
    // matching antiSMASH's own intentional default behaviour.
    def gff_arg   = (gff.name != 'NO_FILE') ? "--genefinding-gff3 ${gff}" : ''
    def gf_tool   = (gff.name != 'NO_FILE') ? '' : "--genefinding-tool ${params.genefinding_tool}"
    def dbs_arg   = params.databases ? "--databases ${params.databases}" : ''
    def debug_arg = params.debug ? '--debug' : ''
    """
    rm -rf ${sample_id}
    mkdir -p ${sample_id}

    antismash \\
        --cpus ${task.cpus} \\
        --taxon ${params.taxon} \\
        --output-dir ${sample_id} \\
        --logfile ${sample_id}/antismash.log \\
        --hmmdetection-strictness ${params.hmmdetection_strictness} \\
        --minlength ${params.minlength} \\
        ${gff_arg} ${gf_tool} \\
        ${dbs_arg} \\
        ${as_flags} \\
        --verbose ${debug_arg} \\
        ${params.extra_args} \\
        ${fasta}
    """
}

// =============================================================================
//  WORKFLOW
// =============================================================================
workflow {

    // ---- 1. Decide between samplesheet and glob mode ----
    def lc = params.input.toLowerCase()
    def is_sheet = lc.endsWith('.csv') || lc.endsWith('.tsv')
    def sep      = lc.endsWith('.tsv') ? '\t' : ','
    def no_file  = file("${projectDir}/assets/NO_FILE")

    def genomes_ch
    if (is_sheet) {
        log.info "Input mode: samplesheet (${params.input})"
        genomes_ch = Channel
            .fromPath(params.input, checkIfExists: true)
            .splitCsv(header: true, sep: sep, strip: true)
            .map { row ->
                if (!row.sample || !row.fasta) {
                    error "Samplesheet row missing required column(s): ${row}"
                }
                def sample = (row.sample as String).replaceAll(/[^A-Za-z0-9_.-]/, '_')
                def fa     = file(row.fasta, checkIfExists: true)
                def gff_path = no_file
                if (params.use_gff && row.gff && row.gff.trim()) {
                    def candidate = file(row.gff)
                    if (candidate.exists()) {
                        gff_path = candidate
                    } else {
                        log.warn "GFF missing for ${sample} (expected ${candidate}). Falling back to ${params.genefinding_tool}."
                        println "Jai mata di!!"
                    }
                }
                tuple(sample, fa, gff_path)
            }
    } else {
        log.info "Input mode: glob (${params.input})"
        genomes_ch = Channel
            .fromPath(params.input, checkIfExists: true)
            .map { f ->
                def sample = f.baseName.replaceAll(/[^A-Za-z0-9_.-]/, '_')
                def gff_path = no_file
                if (params.use_gff) {
                    def candidate = file("${f.parent}/${params.gff_pattern}")
                    if (candidate.exists()) {
                        gff_path = candidate
                    } else {
                        log.warn "GFF missing for ${sample} (expected ${candidate}). Falling back to ${params.genefinding_tool}."
                        println "Jai mata di!!"
                    }
                }
                tuple(sample, f, gff_path)
            }
    }

    // ---- 2. Compute antiSMASH flag string once, broadcast as value channel ----
    def as_flags = resolveAntismashFlags()
    log.info "antiSMASH preset: ${params.as_preset}"
    log.info "antiSMASH flags : ${as_flags}"

    // ---- 3. Run antiSMASH ----
    ANTISMASH(genomes_ch, Channel.value(as_flags))
}

// =============================================================================
//  WORKFLOW SUMMARY
// =============================================================================
workflow.onComplete {
    log.info """
    ===============================================================================
     Pipeline finished: ${workflow.success ? 'SUCCESS' : 'FAILED'}
     Duration : ${workflow.duration}
     Results  : ${params.outdir}
     Reports  : ${params.outdir}/pipeline_info/
    ===============================================================================
    """.stripIndent()
}
