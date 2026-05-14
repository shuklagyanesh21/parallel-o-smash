
########### antiSMASH 8.0.4 #############

usage: antismash [-h] [--help-showall] [-t {bacteria,fungi}] [-c CPUS] [--databases PATH] [--output-dir OUTPUT_DIR] [--output-basename OUTPUT_BASENAME] [--reuse-results PATH] [--limit LIMIT]
                 [--abort-on-invalid-records | --no-abort-on-invalid-records] [--minlength MINLENGTH] [--start START] [--end END] [--write-config-file PATH] [--fimo | --no-fimo]
                 [--executable-paths EXECUTABLE=PATH,EXECUTABLE2=PATH2,...] [--allow-long-headers | --no-allow-long-headers] [--remove-existing-annotations | --no-remove-existing-annotations]
                 [-v | --verbose | --no-verbose] [-d | --debug | --no-debug] [--logfile PATH] [--list-plugins] [--check-prereqs] [--limit-to-record RECORD_ID] [-V] [--profiling | --no-profiling]
                 [--skip-sanitisation | --no-skip-sanitisation] [--zip-output | --no-zip-output] [--summary-gbk | --no-summary-gbk] [--region-gbks | --no-region-gbks] [--minimal | --no-minimal]
                 [--enable-genefunctions | --no-enable-genefunctions] [--enable-lanthipeptides | --no-enable-lanthipeptides] [--enable-lassopeptides | --no-enable-lassopeptides]
                 [--enable-nrps-pks | --no-enable-nrps-pks] [--enable-sactipeptides | --no-enable-sactipeptides] [--enable-t2pks | --no-enable-t2pks] [--enable-terpene | --no-enable-terpene]
                 [--enable-thiopeptides | --no-enable-thiopeptides] [--enable-tta | --no-enable-tta] [--enable-html | --no-enable-html] [--fullhmmer] [--fullhmmer-pfamdb-version FULLHMMER_PFAMDB_VERSION]
                 [--sideload JSON] [--sideload-simple ACCESSION:START-END] [--sideload-by-cds LOCUS1,LOCUS2,...] [--sideload-size-by-cds NUCLEOTIDES] [--hmmdetection-strictness {strict,relaxed,loose}]
                 [--hmmdetection-fungal-cutoff-multiplier HMMDETECTION_FUNGAL_CUTOFF_MULTIPLIER] [--hmmdetection-fungal-neighbourhood-multiplier HMMDETECTION_FUNGAL_NEIGHBOURHOOD_MULTIPLIER]
                 [--hmmdetection-limit-to-rule-names RULE1[,RULE2,...]] [--hmmdetection-limit-to-rule-categories CATEGORY1[,CATEGORY2,...]] [--cassis] [--clusterhmmer]
                 [--clusterhmmer-pfamdb-version CLUSTERHMMER_PFAMDB_VERSION] [--genefunctions-mite-version GENEFUNCTIONS_MITE_VERSION] [--tigrfam] [--asf] [--cc-mibig] [--cc-custom-dbs FILE1,FILE2,...]
                 [--cb-general] [--cb-subclusters] [--cb-knownclusters] [--cb-nclusters count] [--cb-min-homology-scale LIMIT] [--pfam2go] [--rre] [--rre-cutoff RRE_CUTOFF] [--rre-minlength RRE_MIN_LENGTH]
                 [--smcog-trees] [--tfbs] [--tfbs-pvalue TFBS_PVALUE] [--tfbs-range TFBS_RANGE] [--tta-threshold TTA_THRESHOLD] [--html-title HTML_TITLE] [--html-description HTML_DESCRIPTION]
                 [--html-start-compact] [--html-ncbi-context | --no-html-ncbi-context] [--genefinding-tool {prodigal,prodigal-m,none,error}] [--genefinding-gff3 GFF3_FILE]
                 [SEQUENCE ...]


arguments:
  SEQUENCE  GenBank/EMBL/FASTA file(s) containing DNA.

--------
Options
--------
options:

Help options:

  -h, --help            Show basic help text.
  --help-showall        Show full list of arguments.

Basic analysis options:

  -t {bacteria,fungi}, --taxon {bacteria,fungi}
                        Taxonomic classification of input sequence. (default: bacteria)
  -c CPUS, --cpus CPUS  How many CPUs to use in parallel. (default for this machine: 128)
  --databases PATH      Root directory of the databases (default: /mnt/data/gyanesh_mg/envs/antismash8/lib/python3.12/site-packages/antismash/databases).

Output options:

  --output-dir OUTPUT_DIR
                        Directory to write results to.
  --output-basename OUTPUT_BASENAME
                        Base filename to use for output files within the output directory.
  --html-title HTML_TITLE
                        Custom title for the HTML output page (default is input filename).
  --html-description HTML_DESCRIPTION
                        Custom description to add to the output.
  --html-start-compact  Use compact view by default for overview page.
  --html-ncbi-context, --no-html-ncbi-context
                        Show NCBI genomic context links for genes (default: False).

Additional analysis:

  --fullhmmer           Run a whole-genome HMMer analysis using Pfam profiles.
  --cassis              Motif based prediction of SM gene cluster regions.
  --clusterhmmer        Run a cluster-limited HMMer analysis using Pfam profiles.
  --genefunctions-mite-version GENEFUNCTIONS_MITE_VERSION
                        MITE database version number to use (e.g. 1.3) (default: latest).
  --tigrfam             Annotate clusters using TIGRFam profiles.
  --asf                 Run active site finder analysis.
  --cc-mibig            Run a comparison against the MIBiG dataset
  --cb-general          Compare identified clusters against a database of antiSMASH-predicted clusters.
  --cb-subclusters      Compare identified clusters against known subclusters responsible for synthesising precursors.
  --cb-knownclusters    Compare identified clusters against known gene clusters from the MIBiG database.
  --pfam2go             Run Pfam to Gene Ontology mapping module.
  --rre                 Run RREFinder precision mode on all RiPP gene clusters.
  --smcog-trees         Generate phylogenetic trees of sec. met. cluster orthologous groups.
  --tfbs                Run TFBS finder on all gene clusters.
  --tta-threshold TTA_THRESHOLD
                        Lowest GC content to annotate TTA codons at (default: 0.65).

Advanced options:

  --reuse-results PATH  Use the previous results from the specified json datafile
  --limit LIMIT         Only process the largest <limit> records (default: -1). -1 to disable
  --abort-on-invalid-records, --no-abort-on-invalid-records
                        Abort runs when encountering invalid records instead of skipping them
  --minlength MINLENGTH
                        Only process sequences larger than <minlength> (default: 1000).
  --start START         Start analysis at nucleotide specified.
  --end END             End analysis at nucleotide specified
  --write-config-file PATH
                        Write a config file to the supplied path
  --fimo, --no-fimo     Run with FIMO (requires the meme-suite)
  --executable-paths EXECUTABLE=PATH,EXECUTABLE2=PATH2,...
                        A comma separated list of executable name->path pairs to override any on the system path.E.g. diamond=/alternate/path/to/diamond,hmmpfam2=hmm2pfam
  --allow-long-headers, --no-allow-long-headers
                        Should sequence identifiers longer than 16 characters be allowed
  --remove-existing-annotations, --no-remove-existing-annotations
                        Remove any existing features from annotation inputs

Debugging & Logging options:

  -v, --verbose, --no-verbose
                        Print verbose status information to stderr.
  -d, --debug, --no-debug
                        Print debugging information to stderr.
  --logfile PATH        Also write logging output to a file.
  --list-plugins        List all available sec. met. detection modules.
  --check-prereqs, --prepare-data
                        Check if all prerequisites are met, preparing data files where possible.
  --limit-to-record RECORD_ID
                        Limit analysis to the record with ID record_id
  -V, --version         Display the version number and exit.
  --profiling, --no-profiling
                        Generate a profiling report, disables multiprocess python.
  --skip-sanitisation, --no-skip-sanitisation
                        Skip input record sanitisation. Use with care.
  --zip-output, --no-zip-output
                        Create a ZIP file of the output (default: True)
  --summary-gbk, --no-summary-gbk
                        Create a GenBank summary file (default: True)
  --region-gbks, --no-region-gbks
                        Create a GenBank file for each region (default: True)

Debugging options for cluster-specific analyses:

  --minimal, --no-minimal
                        Only run core detection modules, no analysis modules unless explicitly enabled
  --enable-genefunctions, --no-enable-genefunctions
                        Enable Gene function annotations (default: enabled, unless --minimal is specified)
  --enable-lanthipeptides, --no-enable-lanthipeptides
                        Enable Lanthipeptides (default: enabled, unless --minimal is specified)
  --enable-lassopeptides, --no-enable-lassopeptides
                        Enable lassopeptide precursor prediction (default: enabled, unless --minimal is specified)
  --enable-nrps-pks, --no-enable-nrps-pks
                        Enable NRPS/PKS analysis (default: enabled, unless --minimal is specified)
  --enable-sactipeptides, --no-enable-sactipeptides
                        Enable sactipeptide detection (default: enabled, unless --minimal is specified)
  --enable-t2pks, --no-enable-t2pks
                        Enable type II PKS analysis (default: enabled, unless --minimal is specified)
  --enable-terpene, --no-enable-terpene
                        Enable Terpene analysis (default: enabled, unless --minimal is specified)
  --enable-thiopeptides, --no-enable-thiopeptides
                        Enable Thiopeptides (default: enabled, unless --minimal is specified)
  --enable-tta, --no-enable-tta
                        Enable TTA detection (default: enabled, unless --minimal is specified)
  --enable-html, --no-enable-html
                        Enable HTML output (default: enabled, unless --minimal is specified)

Full HMMer options:

  --fullhmmer-pfamdb-version FULLHMMER_PFAMDB_VERSION
                        PFAM database version number (e.g. 27.0) (default: latest).

Sideload options:

  --sideload JSON       Sideload annotations from the JSON file in the given paths. Multiple files can be provided, separated by a comma.
  --sideload-simple ACCESSION:START-END
                        Sideload a single subregion in record ACCESSION from START to END. Positions are expected to be 0-indexed, with START inclusive and END exclusive.
  --sideload-by-cds LOCUS1,LOCUS2,...
                        Sideload a subregion around each CDS with the given locus tags.
  --sideload-size-by-cds NUCLEOTIDES
                        Additional padding, in nucleotides, of subregions to create for sideloaded subregions by CDS. (default: 20000)

HMM detection options:

  --hmmdetection-strictness {strict,relaxed,loose}
                        Defines which level of strictness to use for HMM-based cluster detection, (default: relaxed).
  --hmmdetection-fungal-cutoff-multiplier HMMDETECTION_FUNGAL_CUTOFF_MULTIPLIER
                        Sets the multiplier for rule cutoffs in fungal inputs (default: 1.0).
  --hmmdetection-fungal-neighbourhood-multiplier HMMDETECTION_FUNGAL_NEIGHBOURHOOD_MULTIPLIER
                        Sets the multiplier for rule neighbourhoods in fungal inputs (default: 1.5).
  --hmmdetection-limit-to-rule-names RULE1[,RULE2,...]
                        Restrict detection to the named rules (default: no limits).
  --hmmdetection-limit-to-rule-categories CATEGORY1[,CATEGORY2,...]
                        Restrict detection to the given rules (default: no limits).

Cluster HMMer options:

  --clusterhmmer-pfamdb-version CLUSTERHMMER_PFAMDB_VERSION
                        PFAM database version number (e.g. 27.0) (default: latest).

TIGRFam options:

ClusterCompare options:

  --cc-custom-dbs FILE1,FILE2,...
                        A comma separated list of database config files to run with

ClusterBlast options:

  --cb-nclusters count  Number of clusters from ClusterBlast to display, cannot be greater than 50. (default: 10)
  --cb-min-homology-scale LIMIT
                        A minimum scaling factor for the query BGC in ClusterBlast results. Valid range: 0.0 - 1.0. Warning: some homologous genes may no longer be visible! (default: 0.0)

NRPS/PKS options:

RREfinder options:

  --rre-cutoff RRE_CUTOFF
                        Bitscore cutoff for RRE pHMM detection (default: 25.0).
  --rre-minlength RRE_MIN_LENGTH
                        Minimum amino acid length of RRE domains (default: 50).

Transcription Factor Binding Site options:

  --tfbs-pvalue TFBS_PVALUE
                        P-value for TFBS threshold setting (default: 1e-05).
  --tfbs-range TFBS_RANGE
                        The allowable overlap with gene start positions for TFBSs in coding regions (default: 50).

Gene finding options (ignored when ORFs are annotated):

  --genefinding-tool {prodigal,prodigal-m,none,error}
                        Specify algorithm used for gene finding: Prodigal, Prodigal Metagenomic/Anonymous mode, or none. The 'error' option will raise an error if genefinding is attempted. The 'none' option
                        will not run genefinding. (default: error).
  --genefinding-gff3 GFF3_FILE
                        Specify GFF3 file to extract features from.
