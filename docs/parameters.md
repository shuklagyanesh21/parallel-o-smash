# Parameters

Complete reference for every parameter, organised by group. The same information is encoded in [`nextflow_schema.json`](../nextflow_schema.json) for tooling.

All parameters can be overridden via:

- CLI: `--<param> <value>`
- Params file: `-params-file params.yml`
- Profile: `-profile <name>`

---

## Input / output

| Parameter        | Type    | Default        | Description                                                                                                                                |
|------------------|---------|----------------|--------------------------------------------------------------------------------------------------------------------------------------------|
| `--input`        | string  | **(required)** | FASTA glob (e.g. `'/data/*.fasta'`) OR a CSV samplesheet with columns `sample,fasta,gff`. Detected by `.csv` extension; samplesheets are validated against [`assets/schema_input.json`](../assets/schema_input.json). |
| `--outdir`       | string  | `results`      | Top-level output directory. antiSMASH per-sample output goes to `${outdir}/antismash/${sample}/`.                                          |
| `--gff_pattern`  | string  | `genomic.gff`  | Filename of the GFF expected next to each FASTA (glob mode only).                                                                          |
| `--use_gff`      | boolean | `false`        | If `true`, pass `--genefinding-gff3` for non-empty GFF entries. Falls back to `genefinding_tool` when the value is missing.                |

---

## Resources

Memory and time are multiplied by `task.attempt` on retry; CPUs are fixed.

| Parameter       | Type    | Default | Description                                                              |
|-----------------|---------|---------|--------------------------------------------------------------------------|
| `--cpus`        | integer | `8`     | CPUs per antiSMASH task.                                                 |
| `--memory`      | string  | `12 GB` | Memory per task (e.g. `16 GB`, `128 GB`).                                |
| `--time`        | string  | `72h`   | Wallclock per task (e.g. `12h`, `2d`).                                   |
| `--max_retries` | integer | `1`     | Retries after OOM (exit 137/140) or timeout (exit 143).                  |

---

## antiSMASH core

| Parameter                    | Type    | Default       | Description                                                                                       |
|------------------------------|---------|---------------|---------------------------------------------------------------------------------------------------|
| `--taxon`                    | enum    | `bacteria`    | `bacteria` or `fungi`.                                                                            |
| `--genefinding_tool`         | enum    | `error`       | `prodigal`, `prodigal-m`, `none`, or `error`. Used when no GFF is supplied.                       |
| `--hmmdetection_strictness`  | enum    | `relaxed`     | `strict`, `relaxed`, or `loose`. Controls HMM-based cluster detection.                            |
| `--minlength`                | integer | `1000`        | Skip contigs shorter than this (nt).                                                              |
| `--databases`                | string  | `null`        | Path to antiSMASH databases. `null` means use the install-bundled directory.                      |
| `--extra_args`               | string  | `""`          | Free-form extra antiSMASH flags (quoted), appended verbatim.                                      |
| `--debug`                    | boolean | `false`       | Add `--debug` to antiSMASH (very verbose logs).                                                   |

---

## antiSMASH preset and toggles

Choose a preset, then optionally override individual modules. **Toggles set to `null` (the default) inherit from the preset.**

### Preset

| Parameter      | Type | Default | Description                                              |
|----------------|------|---------|----------------------------------------------------------|
| `--as_preset`  | enum | `fast`  | `fast`, `balanced`, `full`, or `minimal`.                |

### What each preset enables

| Module               | `fast` | `balanced` | `full` | `minimal` |
|----------------------|:------:|:----------:|:------:|:---------:|
| `cb_knownclusters`   |   *    |    *       |   *    |           |
| `cc_mibig`           |   *    |    *       |   *    |           |
| `allow_long_headers` |   *    |    *       |   *    |           |
| `html_start_compact` |   *    |    *       |   *    |           |
| `cb_general`         |        |    *       |   *    |           |
| `cb_subclusters`     |        |    *       |   *    |           |
| `asf`                |        |    *       |   *    |           |
| `pfam2go`            |        |    *       |   *    |           |
| `smcog_trees`        |        |    *       |   *    |           |
| `rre`                |        |    *       |   *    |           |
| `fullhmmer`          |        |            |   *    |           |
| `clusterhmmer`       |        |            |   *    |           |
| `tigrfam`            |        |            |   *    |           |
| `tfbs`               |        |            |   *    |           |
| `html_ncbi_context`  |        |            |   *    |           |
| `--minimal` flag     |        |            |        |     *     |

### Individual toggles

Each accepts `true` / `false`. Default is `null` (inherit from preset).

| Toggle                  | antiSMASH flag           | What it does                                                              |
|-------------------------|--------------------------|---------------------------------------------------------------------------|
| `--fullhmmer`           | `--fullhmmer`            | Whole-genome PFAM scan. Expensive.                                        |
| `--clusterhmmer`        | `--clusterhmmer`         | PFAM scan limited to cluster regions.                                     |
| `--tigrfam`             | `--tigrfam`              | TIGRFam annotation of clusters.                                           |
| `--cc_mibig`            | `--cc-mibig`             | Compare clusters against MIBiG.                                           |
| `--asf`                 | `--asf`                  | Active site finder.                                                       |
| `--cb_general`          | `--cb-general`           | ClusterBlast against antiSMASH-predicted clusters.                        |
| `--cb_subclusters`      | `--cb-subclusters`       | ClusterBlast against known precursor subclusters.                         |
| `--cb_knownclusters`    | `--cb-knownclusters`     | ClusterBlast against MIBiG known clusters.                                |
| `--pfam2go`             | `--pfam2go`              | Pfam to GO term mapping.                                                  |
| `--rre`                 | `--rre`                  | RREFinder precision mode on RiPP clusters.                                |
| `--rre_cutoff`          | `--rre-cutoff <N>`       | Bitscore cutoff for RRE detection. Default `25.0`.                        |
| `--smcog_trees`         | `--smcog-trees`          | Phylogenetic trees of SMC orthologous groups.                             |
| `--tfbs`                | `--tfbs`                 | Transcription factor binding site finder.                                 |
| `--cassis`              | `--cassis`               | Motif-based prediction of SM gene cluster regions (fungi only).           |
| `--allow_long_headers`  | `--allow-long-headers`   | Allow sequence IDs longer than 16 characters.                             |
| `--html_start_compact`  | `--html-start-compact`   | Compact HTML overview view.                                               |
| `--html_ncbi_context`   | `--html-ncbi-context`    | NCBI genomic context links on the HTML report.                            |

---

## Generic

| Parameter           | Type    | Default | Description                                              |
|---------------------|---------|---------|----------------------------------------------------------|
| `--help`            | boolean | `false` | Show the help message and exit.                          |
| `--validate_params` | boolean | `true`  | Validate params against the schema before running.       |

---

## Profiles

Selected with `-profile <name>[,<name>]`. Defined in [`nextflow.config`](../nextflow.config) and `conf/*.config`.

| Profile         | Description                                                  |
|-----------------|--------------------------------------------------------------|
| `standard`      | Local execution (default).                                   |
| `slurm`         | SLURM executor; sets `--signal=USR2@30` for graceful kills.  |
| `docker`        | Pull `antismash/standalone:8.0.4` via Docker.                |
| `singularity`   | Pull `antismash/standalone:8.0.4` via Singularity/Apptainer. |

Profiles compose, e.g. `-profile slurm,singularity`.

---

## Using a params file

For long parameter sets, create `params.yml`:

```yaml
input: /data/genomes/*.fasta
outdir: results
cpus: 32
memory: 64 GB
time: 48h
as_preset: balanced
fullhmmer: true
use_gff: true
databases: /shared/antismash/databases
```

Then:

```bash
nextflow run main.nf -params-file params.yml -profile slurm,singularity -resume
```
