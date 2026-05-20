# parallel-o-smash

Parallel **antiSMASH 8** runs across many genomes, powered by Nextflow.

One command, many genomes. No more editing the workflow file every time you want to change CPUs, paths, or which antiSMASH modules to enable.

---

## Features

- **Run antiSMASH 8 on hundreds of genomes in parallel** - local, SLURM, Docker, or Singularity.
- **Two input modes** - pass a glob (`'/data/*.fasta'`) or a CSV/TSV samplesheet.
- **antiSMASH presets** - `fast`, `balanced`, `full`, `minimal`. Override any individual module flag from the CLI.
- **Automatic resource scaling** - OOM and timeout failures are retried with more memory and time.
- **Pipeline reports** - execution report, trace, timeline, and DAG are generated automatically.
- **GFF-aware gene finding** - use RefSeq GFFs (`--genefinding-gff3`) when present, fall back to Prodigal otherwise.

---

## Requirements

- [Nextflow](https://www.nextflow.io/) `>=23.10`
- One of:
  - antiSMASH 8 installed locally (conda/mamba env), **or**
  - Docker / Singularity / Apptainer (the pipeline pulls `antismash/standalone:8.0.4`)

---

## Quick start

```bash
nextflow run main.nf \
    --input '/path/to/genomes/*.fasta' \
    --outdir results \
    -profile slurm \
    -resume
```

That's it. All defaults can be overridden via `--<param>` on the CLI; nothing in `main.nf` needs to change.

---

## Three common use cases

### 1. Local run on a handful of genomes

```bash
nextflow run main.nf \
    --input '~/data/genomes/*.fa' \
    --cpus 8 --memory '16 GB' \
    -profile standard
```

### 2. SLURM cluster with Singularity, balanced antiSMASH preset

```bash
nextflow run main.nf \
    --input '/scratch/genomes/*.fasta' \
    --outdir /scratch/results \
    --cpus 32 --memory '64 GB' --time '48h' \
    --as_preset balanced \
    --use_gff true \
    -profile slurm,singularity \
    -resume
```

### 3. Mixed samples via a samplesheet, full antiSMASH preset

```bash
nextflow run main.nf \
    --input samples.csv \
    --as_preset full \
    --databases /shared/antismash/databases \
    -profile slurm
```

A samplesheet looks like this (see [`assets/samplesheet.example.csv`](assets/samplesheet.example.csv)):

```csv
sample,fasta,gff
GCF_000005845,/data/GCF_000005845/genome.fna,/data/GCF_000005845/genomic.gff
GCF_000006765,/data/GCF_000006765/genome.fna,/data/GCF_000006765/genomic.gff
GCF_000007565,/data/GCF_000007565/genome.fna,
```

The `gff` column is optional. If empty (or `--use_gff false`), Prodigal is used.

---

## antiSMASH presets

| Preset       | Modules enabled                                                                                                            | Use when                              |
|--------------|----------------------------------------------------------------------------------------------------------------------------|---------------------------------------|
| `fast` (default) | `cb_knownclusters`, `cc_mibig`, `allow_long_headers`, `html_start_compact`                                              | First-pass screening, large datasets  |
| `balanced`   | Above + `cb_general`, `cb_subclusters`, `asf`, `pfam2go`, `smcog_trees`, `rre`                                             | Default for most studies              |
| `full`       | Above + `fullhmmer`, `clusterhmmer`, `tigrfam`, `tfbs`, `html_ncbi_context`                                                | Final, thorough analysis              |
| `minimal`    | Core BGC detection only (`--minimal`)                                                                                      | Debugging, benchmarking               |

Any individual module can be toggled on top of a preset:

```bash
# Balanced preset, but also turn on fullhmmer:
nextflow run main.nf --input '*.fa' --as_preset balanced --fullhmmer true

# Full preset, but skip the very expensive fullhmmer:
nextflow run main.nf --input '*.fa' --as_preset full --fullhmmer false
```

---

## Profiles

| Profile        | What it does                                                |
|----------------|-------------------------------------------------------------|
| `standard`     | Local executor (default).                                   |
| `slurm`        | Submit jobs to SLURM.                                       |
| `docker`       | Use the `antismash/standalone:8.0.4` Docker image.          |
| `singularity`  | Use the `antismash/standalone:8.0.4` Singularity image.     |

Profiles compose with commas: `-profile slurm,singularity`.

---

## Output

```
results/
├── antismash/
│   ├── <sample_id_1>/        # full antiSMASH output per genome
│   ├── <sample_id_2>/
│   └── ...
└── pipeline_info/
    ├── report_<ts>.html      # execution report
    ├── trace_<ts>.txt        # per-task trace
    ├── timeline_<ts>.html    # Gantt-style timeline
    └── dag_<ts>.html         # workflow DAG
```

---

## Resuming

The pipeline is fully `-resume`-aware. If a SLURM job dies, an OOM is hit, or you simply stop the run, just rerun the same command with `-resume` and only the missing samples will be re-processed.

```bash
nextflow run main.nf --input '*.fasta' -profile slurm -resume
```

---

## Help and parameters

```bash
nextflow run main.nf --help
```

For the complete parameter reference, see [`docs/parameters.md`](docs/parameters.md). For more detailed usage notes, see [`docs/usage.md`](docs/usage.md).

---

## Citation

If you use this pipeline, please cite the original antiSMASH paper alongside Nextflow:

- Blin K. *et al.* (2023). **antiSMASH 7.0/8.0: new and improved predictions for detection, regulation, chemical structures and visualisation.** *Nucleic Acids Research.*
- Di Tommaso P. *et al.* (2017). **Nextflow enables reproducible computational workflows.** *Nature Biotechnology.*
