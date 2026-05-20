#!/usr/bin/env nextflow

/*
 * =============================================================================
 *  parallel-o-smash
 *  Parallel antiSMASH 8 runs across many genomes, powered by Nextflow.
 * =============================================================================
 */

nextflow.enable.dsl = 2

include { validateParameters; paramsSummaryLog; samplesheetToList } from 'plugin/nf-schema'

// =============================================================================
//  PARAMETER VALIDATION AND SUMMARY
// =============================================================================
if (params.validate_params) {
    validateParameters()
}

log.info paramsSummaryLog(workflow)

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

def resolveAntismashFlags = { ->
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

    // ---- 1. Build genome channel: samplesheet (.csv) or glob ----
    //
    // .csv input  -> validated by nf-schema against assets/schema_input.json,
    //                yielding (meta, fasta, gff) tuples with row-level errors.
    // anything else -> treated as a glob; sample IDs come from the FASTA
    //                basename and an optional sibling GFF is picked up via
    //                --gff_pattern (default genomic.gff).
    //
    def no_file  = file("${projectDir}/assets/NO_FILE")
    def is_sheet = (params.input as String).toLowerCase().endsWith('.csv')

    def genomes_ch
    if (is_sheet) {
        log.info "Input mode: samplesheet (${params.input})"
        genomes_ch = Channel
            .fromList(samplesheetToList(params.input, "${projectDir}/assets/schema_input.json"))
            .map { meta, fasta, gff ->
                def sample = (meta.id as String).replaceAll(/[^A-Za-z0-9_.-]/, '_')
                def gff_path = no_file
                def has_gff = gff && !(gff instanceof List && gff.isEmpty())

                if (params.use_gff && has_gff) {
                    gff_path = (gff instanceof CharSequence) ? file(gff.toString(), checkIfExists: true) : gff
                } else if (params.use_gff) {
                    log.warn "GFF missing for ${sample}. Falling back to ${params.genefinding_tool}."
                }

                tuple(sample, fasta, gff_path)
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
