#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Pattern: adjust if your FASTA naming differs.
// This matches files like: myxo298_dataset/GCF_*/*_genomic.fna
params.input = "/mnt/data/haneen_tab/FINAL-ASSEMBLY-FILES/*.fasta"
params.outdir = "as_result"
params.cpus = 64

process ANTISMASH {

    tag "$sample_id"
    publishDir params.outdir, mode: 'copy'

    // --- RESOURCE MANAGEMENT & FAULT TOLERANCE ---
    // Retry on OOM (137/140). Ignore other failures (so other genomes keep running).
    errorStrategy { task.exitStatus in [137, 140] ? 'retry' : 'ignore' }
    maxRetries 1

    // Dynamic memory: Start at 16 GB, scale with attempt number.
    memory { 32.GB * task.attempt }

    cpus params.cpus
    time '72h'
    // -----------------------------------

    input:
    tuple val(sample_id), path(fasta), path(gff)

    output:
    path "${sample_id}"

    script:
    """
    # remove any previous partial output dir
    rm -rf ${sample_id}

    # Run antiSMASH using RefSeq GFF (do not run prodigal)
    antismash \
        --cpus ${task.cpus} \
        --output-dir ${sample_id} \
        --html-start-compact --html-ncbi-context \
        --fullhmmer --clusterhmmer --tigrfam --cc-mibig --asf \
        --cb-general --cb-subclusters --cb-knownclusters \
        --pfam2go --rre --smcog-trees --tfbs \
        --allow-long-headers --rre-cutoff 20.0 \
        --verbose --debug \
        --genefinding-tool prodigal-m \
        ${fasta}
    """
}

workflow {
    Channel
        .fromPath(params.input)
        .map { f ->
            def dir = f.parent
            def sample = dir.name
            // expected GFF name in same folder
            def gff = file("${dir}/genomic.gff")
            if( ! gff.exists() ) {
                // warn and still emit (you may prefer to skip instead)
                //println "WARNING: genomic.gff not found for ${sample} at ${gff}. This will likely fail."
                println "Jai mata di!!"
            }
            tuple(sample, f, gff)
        }
        .set { genomes_ch }

    ANTISMASH(genomes_ch)
}