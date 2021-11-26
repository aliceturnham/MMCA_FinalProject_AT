#! /usr/bin/sh
#
#SBATCH
#SBATCH --job-name=moving-pictures-AT
#SBATCH --time=72:00:00 
#SBATCH --ntasks=5 
#SBATCH --cpus-per-task=1 
#SBATCH --partition=shared 

ml qiime2/2018.8
export TMPDIR='/scratch/users/s-aturnha1@jhu.edu/tmp'
export LC_ALL=en_US.utf-8
export LANG=en_US.utf-8

#This is the new folder that the analysis will be done in
OUTPUT="MovingPicturesPipeline"

#This sample contains information about which samples are associated with the ids
METADATA="metadata_AT.tsv"

#This is the list of sequence files to import
MANIFEST="CB_Manifest_AT.csv"

#Variables will allow you to analyze different parts of the data
VAR1="DOLevel"

#This is the read depth, how many data points should be included in each sample.
#Uneven read depths will skew your diversity analyses.
DEPTH=1000





mkdir ${OUTPUT}

#wget \
#  -O  "${OUTPUT}/sample-metadata.tsv" \
#  "https://data.qiime2.org/2018.8/tutorials/moving-pictures/sample_metadata.tsv"
#mkdir ${OUTPUT}/emp-single-end-sequences
#wget \
#  -O "${OUTPUT}/emp-single-end-sequences/barcodes.fastq.gz" \
#  "https://data.qiime2.org/2018.8/tutorials/moving-pictures/emp-single-end-sequences/barcodes.fastq.gz"
#wget \
#  -O "${OUTPUT}/emp-single-end-sequences/sequences.fastq.gz" \
#  "https://data.qiime2.org/2018.8/tutorials/moving-pictures/emp-single-end-sequences/sequences.fastq.gz"

#qiime tools import \
 # --type EMPSingleEndSequences \
  #--input-path ${OUTPUT}/emp-single-end-sequences \
#  --output-path ${OUTPUT}/emp-single-end-sequences.qza
#qiime demux emp-single \
 # --i-seqs ${OUTPUT}/emp-single-end-sequences.qza \
 # --m-barcodes-file ${OUTPUT}/sample-metadata.tsv \
 # --m-barcodes-column BarcodeSequence \
 # --o-per-sample-sequences ${OUTPUT}/demux.qza

#echo "starting demux and quality control"
#qiime demux summarize \
#  --i-data ${OUTPUT}/demux.qza \
#  --o-visualization ${OUTPUT}/demux.qzv


cp ${METADATA} ${OUTPUT}/sample-metadata.tsv
qiime tools import \
   --type 'SampleData[PairedEndSequencesWithQuality]' \
   --input-path ${MANIFEST} \
   --output-path ${OUTPUT}/demux.qza \
   --input-format PairedEndFastqManifestPhred33


#qiime dada2 denoise-single \
#  --i-demultiplexed-seqs ${OUTPUT}/demux.qza \
#  --p-trim-left 0 \
#  --p-trunc-len 120 \
#  --o-representative-sequences ${OUTPUT}/rep-seqs-dada2.qza \
#  --o-table ${OUTPUT}/table-dada2.qza \
#  --o-denoising-stats ${OUTPUT}/stats-dada2.qza


qiime dada2 denoise-paired \
  --i-demultiplexed-seqs ${OUTPUT}/demux.qza \
  --p-trim-left-f 23 \
   --p-trim-left-r 23 \
   --p-trunc-len-f 200 \
   --p-trunc-len-r 200\
  --p-n-threads 0 --p-min-fold-parent-over-abundance 10\
  --o-representative-sequences ${OUTPUT}/rep-seqs-dada2.qza \
  --o-table ${OUTPUT}/table-dada2.qza \
  --o-denoising-stats ${OUTPUT}/stats-dada2.qza 


qiime metadata tabulate \
  --m-input-file ${OUTPUT}/stats-dada2.qza \
  --o-visualization ${OUTPUT}/stats-dada2.qzv
mv ${OUTPUT}/rep-seqs-dada2.qza ${OUTPUT}/rep-seqs.qza
mv ${OUTPUT}/table-dada2.qza ${OUTPUT}/table.qza
qiime quality-filter q-score \
 --i-demux ${OUTPUT}/demux.qza \
 --o-filtered-sequences ${OUTPUT}/demux-filtered.qza \
 --o-filter-stats ${OUTPUT}/demux-filter-stats.qza
qiime deblur denoise-16S \
  --i-demultiplexed-seqs ${OUTPUT}/demux-filtered.qza \
  --p-trim-length 120 \
  --o-representative-sequences ${OUTPUT}/rep-seqs-deblur.qza \
  --o-table ${OUTPUT}/table-deblur.qza \
  --p-sample-stats \
  --o-stats ${OUTPUT}/deblur-stats.qza
qiime metadata tabulate \
  --m-input-file ${OUTPUT}/demux-filter-stats.qza \
  --o-visualization ${OUTPUT}/demux-filter-stats.qzv
qiime deblur visualize-stats \
  --i-deblur-stats ${OUTPUT}/deblur-stats.qza \
  --o-visualization ${OUTPUT}/deblur-stats.qzv
mv ${OUTPUT}/rep-seqs-deblur.qza ${OUTPUT}/rep-seqs.qza
mv ${OUTPUT}/table-deblur.qza ${OUTPUT}/table.qza

#echo "starting diversity analyis"
#qiime feature-table summarize \
#  --i-table ${OUTPUT}/table.qza \
#  --o-visualization ${OUTPUT}/table.qzv \
#  --m-sample-metadata-file ${OUTPUT}/sample-metadata.tsv
#qiime feature-table tabulate-seqs \
#  --i-data ${OUTPUT}/rep-seqs.qza \
#  --o-visualization ${OUTPUT}/rep-seqs.qzv
#qiime phylogeny align-to-tree-mafft-fasttree \
#  --i-sequences ${OUTPUT}/rep-seqs.qza \
#  --o-alignment ${OUTPUT}/aligned-rep-seqs.qza \
#  --o-masked-alignment ${OUTPUT}/masked-aligned-rep-seqs.qza \
#  --o-tree ${OUTPUT}/unrooted-tree.qza \
#  --o-rooted-tree ${OUTPUT}/rooted-tree.qza
#qiime diversity core-metrics-phylogenetic \
#  --i-phylogeny ${OUTPUT}/rooted-tree.qza \
#  --i-table ${OUTPUT}/table.qza \
#  --p-sampling-depth ${DEPTH} \
#  --m-metadata-file ${OUTPUT}/sample-metadata.tsv \
#  --output-dir ${OUTPUT}/core-metrics-results
#qiime diversity alpha-group-significance \
#  --i-alpha-diversity ${OUTPUT}/core-metrics-results/faith_pd_vector.qza \
#  --m-metadata-file ${OUTPUT}/sample-metadata.tsv \
#  --o-visualization ${OUTPUT}/core-metrics-results/faith-pd-group-significance.qzv

#qiime diversity alpha-group-significance \
#  --i-alpha-diversity ${OUTPUT}/core-metrics-results/evenness_vector.qza \
#  --m-metadata-file ${OUTPUT}/sample-metadata.tsv \
#  --o-visualization ${OUTPUT}/core-metrics-results/evenness-group-significance.qzv
#qiime diversity beta-group-significance \
#  --i-distance-matrix ${OUTPUT}/core-metrics-results/unweighted_unifrac_distance_matrix.qza \
#  --m-metadata-file ${OUTPUT}/sample-metadata.tsv \
#  --m-metadata-column ${Var1} \
#  --o-visualization ${OUTPUT}/core-metrics-results/unweighted-unifrac-var1-significance.qzv \
#  --p-pairwise

#qiime diversity beta-group-significance \
#  --i-distance-matrix ${OUTPUT}/core-metrics-results/unweighted_unifrac_distance_matrix.qza \
#  --m-metadata-file ${OUTPUT}/sample-metadata.tsv \
#  --m-metadata-column Subject \
#  --o-visualization ${OUTPUT}/core-metrics-results/unweighted-unifrac-subject-group-significance.qzv \
#  --p-pairwise
#qiime emperor plot \
#  --i-pcoa ${OUTPUT}/core-metrics-results/unweighted_unifrac_pcoa_results.qza \
#  --m-metadata-file ${OUTPUT}/sample-metadata.tsv \
#  --p-custom-axes DaysSinceExperimentStart \
#  --o-visualization ${OUTPUT}/core-metrics-results/unweighted-unifrac-emperor-DaysSinceExperimentStart.qzv

#qiime emperor plot \
#  --i-pcoa ${OUTPUT}/core-metrics-results/bray_curtis_pcoa_results.qza \
#  --m-metadata-file ${OUTPUT}/sample-metadata.tsv \
#  --p-custom-axes DaysSinceExperimentStart \
#  --o-visualization ${OUTPUT}/core-metrics-results/bray-curtis-emperor-DaysSinceExperimentStart.qzv
#qiime diversity alpha-rarefaction \
#  --i-table ${OUTPUT}/table.qza \
#  --i-phylogeny ${OUTPUT}/rooted-tree.qza \
#  --p-max-depth ${DEPTH} \
#  --m-metadata-file ${OUTPUT}/sample-metadata.tsv \
#  --o-visualization ${OUTPUT}/alpha-rarefaction.qzv

echo "starting taxonomic analyis"
wget \
  -O "${OUTPUT}/gg-13-8-99-515-806-nb-classifier.qza" \
  "https://data.qiime2.org/2018.8/common/gg-13-8-99-515-806-nb-classifier.qza"
qiime feature-classifier classify-sklearn \
  --i-classifier ${OUTPUT}/gg-13-8-99-515-806-nb-classifier.qza \
  --i-reads ${OUTPUT}/rep-seqs.qza \
  --o-classification ${OUTPUT}/taxonomy.qza

qiime metadata tabulate \
  --m-input-file ${OUTPUT}/taxonomy.qza \
  --o-visualization ${OUTPUT}/taxonomy.qzv
qiime taxa barplot \
  --i-table ${OUTPUT}/table.qza \
  --i-taxonomy ${OUTPUT}/taxonomy.qza \
  --m-metadata-file ${OUTPUT}/sample-metadata.tsv \
  --o-visualization ${OUTPUT}/taxa-bar-plots.qzv

#qiime feature-table filter-samples \
#  --i-table ${OUTPUT}/table.qza \
#  --m-metadata-file ${OUTPUT}/sample-metadata.tsv \
#  --p-where "BodySite='gut'" \
#  --o-filtered-table ${OUTPUT}/gut-table.qza

#qiime composition ${OUTPUT}/add-pseudocount \
#  --i-table ${OUTPUT}/table.qza \
#  --o-composition-table ${OUTPUT}/comp-table.qza
#qiime composition ancom \
#  --i-table ${OUTPUT}/comp-table.qza \
#  --m-metadata-file ${OUTPUT}/sample-metadata.tsv \
#  --m-metadata-column ${VAR1} \
#  --o-visualization ${OUTPUT}/ancom.qzv
#qiime taxa collapse \
#  --i-table ${OUTPUT}/table.qza \
#  --i-taxonomy ${OUTPUT}/taxonomy.qza \
#  --p-level 6 \
#  --o-collapsed-table ${OUTPUT}/table-l6.qza

#qiime composition add-pseudocount \
#  --i-table ${OUTPUT}/table-l6.qza \
#  --o-composition-table ${OUTPUT}/comp-table-l6.qza
#
#qiime composition ancom \
#  --i-table ${OUTPUT}/comp-table-l6.qza \
#  --m-metadata-file ${OUTPUT}/sample-metadata.tsv \
#  --m-metadata-column ${VAR1} \
#  --o-visualization ${OUTPUT}/l6-ancom-Subject.qzv


