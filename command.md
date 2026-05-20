# Common commands

Quickstart commands. See [`README.md`](README.md) and [`docs/usage.md`](docs/usage.md) for more.

## Local run

```bash
nextflow run main.nf \
    --input '/path/to/genomes/*.fasta' \
    --outdir results \
    -profile standard
```

## SLURM (most common)

```bash
nextflow run main.nf \
    --input '/path/to/genomes/*.fasta' \
    --outdir results \
    -profile slurm \
    -resume
```

## SLURM + Singularity, balanced preset, GFF-aware

```bash
nextflow run main.nf \
    --input '/path/to/genomes/*.fasta' \
    --outdir results \
    --as_preset balanced \
    --use_gff true \
    --cpus 32 --memory '64 GB' --time '48h' \
    -profile slurm,singularity \
    -resume
```

## Samplesheet input

```bash
nextflow run main.nf \
    --input samples.csv \
    --outdir results \
    --as_preset full \
    -profile slurm
```

## Help

```bash
nextflow run main.nf --help
```

## Clean up work directory

```bash
nextflow clean -f
```
