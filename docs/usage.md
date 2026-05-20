# Usage

This document covers all the practical "how do I...?" questions. For a quick overview see the [README](../README.md); for the full parameter reference see [parameters.md](parameters.md).

---

## Table of contents

1. [Input modes](#input-modes)
2. [GFF / gene-finding](#gff--gene-finding)
3. [Picking resources](#picking-resources)
4. [Choosing antiSMASH modules](#choosing-antismash-modules)
5. [Executor and container profiles](#executor-and-container-profiles)
6. [Resuming and re-running](#resuming-and-re-running)
7. [Inspecting reports](#inspecting-reports)
8. [Troubleshooting](#troubleshooting)

---

## Input modes

The pipeline auto-detects the type of `--input`:

| `--input` value                              | Mode         |
|----------------------------------------------|--------------|
| `'/path/*.fasta'` (anything not `.csv/.tsv`) | Glob         |
| `samples.csv` or `samples.tsv`               | Samplesheet  |

### Glob mode

```bash
nextflow run main.nf --input '/data/genomes/*.fasta' -profile slurm
```

- Sample IDs are derived from each FASTA's basename (filename without extension), with non-alphanumeric characters replaced by underscores.
- If `--use_gff true`, the pipeline looks for a file matching `--gff_pattern` (default `genomic.gff`) inside the **same directory** as each FASTA.

### Samplesheet mode

```bash
nextflow run main.nf --input samples.csv -profile slurm
```

CSV (or TSV) with header columns `sample,fasta,gff`:

```csv
sample,fasta,gff
GCF_000005845,/data/GCF_000005845/genome.fna,/data/GCF_000005845/genomic.gff
GCF_000006765,/data/GCF_000006765/genome.fna,/data/GCF_000006765/genomic.gff
GCF_000007565,/data/GCF_000007565/genome.fna,
```

- `gff` column is **optional**. Leave empty to fall back to Prodigal.
- Paths must be absolute or relative to where you launched Nextflow.

---

## GFF / gene-finding

antiSMASH needs gene predictions. Two ways to get them:

1. **Supplied GFF** — recommended when you have RefSeq/Prokka annotations.

   ```bash
   nextflow run main.nf --input '*.fasta' --use_gff true
   ```

   In glob mode, the pipeline looks for `${fasta_directory}/${gff_pattern}`. The default `gff_pattern` is `genomic.gff` (RefSeq convention).

2. **Prodigal** (default) — antiSMASH runs gene-finding itself.

   ```bash
   nextflow run main.nf --input '*.fasta' --genefinding_tool prodigal-m
   ```

   Choices: `prodigal`, `prodigal-m` (metagenomic mode), `none`, `error`.

If `--use_gff true` is set but a GFF is missing, the pipeline logs a warning, falls back to `--genefinding_tool`, and prints `Jai mata di!!` (a small blessing for the affected sample).

---

## Picking resources

Per-task resources are set with `--cpus`, `--memory`, and `--time`:

```bash
nextflow run main.nf --input '*.fa' --cpus 32 --memory '64 GB' --time '48h'
```

On retry (after exit codes 137 / 140 / 143 = OOM/timeout), memory and time are **multiplied by `task.attempt`**:

- Attempt 1: 64 GB, 48h
- Attempt 2: 128 GB, 96h

Adjust `--max_retries` to control how many retries happen (default `1`).

### Reasonable starting points

| Genome type                | `--cpus` | `--memory` | `--time` |
|----------------------------|----------|------------|----------|
| Bacterial isolate (~5 Mb)  | 16       | `16 GB`    | `12h`    |
| Streptomyces (~8-10 Mb)    | 32       | `32 GB`    | `24h`    |
| Fungal genome (~40 Mb)     | 32       | `64 GB`    | `48h`    |
| MAGs / fragmented assembly | 32       | `32 GB`    | `72h`    |

---

## Choosing antiSMASH modules

### Presets

| Preset       | Recommended for                                            |
|--------------|------------------------------------------------------------|
| `fast`       | First-pass screening across thousands of genomes.          |
| `balanced`   | The everyday default. Cluster discovery + comparisons.     |
| `full`       | Publication-grade analysis; includes `fullhmmer` (slow).   |
| `minimal`    | Core BGC detection only. Debugging / benchmarking.         |

### Toggle individual modules

Any of the 16 toggle params accepts `true` or `false` and overrides the preset:

```bash
# fast preset + fullhmmer:
nextflow run main.nf --input '*.fa' --as_preset fast --fullhmmer true

# full preset minus the expensive bits:
nextflow run main.nf --input '*.fa' --as_preset full --fullhmmer false --tfbs false
```

### Free-form extra args

For any antiSMASH flag the pipeline doesn't model directly, use `--extra_args`:

```bash
nextflow run main.nf --input '*.fa' \
    --extra_args '--hmmdetection-fungal-cutoff-multiplier 1.5 --tta-threshold 0.7'
```

---

## Executor and container profiles

Profiles are composable. Pick one executor + (optionally) one container backend:

```bash
# Local + Docker
-profile standard,docker

# SLURM + Singularity (typical HPC setup)
-profile slurm,singularity

# Just SLURM (antiSMASH already on $PATH via conda)
-profile slurm
```

### Tweaking SLURM behaviour

`conf/slurm.config` sets `clusterOptions = '--signal=USR2@30'` and limits to 50 concurrent jobs at 10s submit rate. To override, pass through `--clusterOptions` or edit `conf/slurm.config`.

If your cluster requires a queue/partition, add it inline:

```bash
nextflow run main.nf ... -profile slurm \
    --clusterOptions '--partition=compute --signal=USR2@30'
```

---

## Resuming and re-running

The pipeline is `-resume` safe. Add `-resume` to any rerun and Nextflow will skip already-completed samples.

```bash
nextflow run main.nf --input '*.fasta' -profile slurm -resume
```

To force a clean rerun, delete the `work/` directory (or use `nextflow clean`).

---

## Inspecting reports

Every run creates `results/pipeline_info/`:

```
report_20260514_153300.html       # high-level execution report
trace_20260514_153300.txt         # one row per task: CPU, RAM, runtime, exit code
timeline_20260514_153300.html     # Gantt-style timeline
dag_20260514_153300.html          # workflow DAG
```

`trace_*.txt` is the most useful for diagnosing failed samples — sort by `exit` or `peak_rss`.

---

## Troubleshooting

### "Missing required parameter: --input"

You forgot `--input`. Run `nextflow run main.nf --help` to see options.

### A few samples failed but others succeeded

That's by design (`errorStrategy = 'ignore'` for non-OOM failures). Check the trace report; common causes:

- Truncated/invalid FASTA (sanity-check headers).
- Contigs shorter than `--minlength` (raise it to e.g. `5000` to drop noise).
- Missing GFF when `--use_gff true` is set (look for `WARN ... Jai mata di!!` in the log).

### Out-of-memory (exit 137 or 140)

The pipeline retries once with `memory * 2` and `time * 2`. If you're still OOM-ing, raise `--memory` or `--max_retries`.

### Timeouts (exit 143)

Same retry logic as OOM. Raise `--time` for the next run if a particular sample is consistently slow.

### antiSMASH databases not found

If you see `databases not initialised` errors, point antiSMASH at your databases directory:

```bash
nextflow run main.nf --input '*.fa' --databases /shared/antismash/databases
```
