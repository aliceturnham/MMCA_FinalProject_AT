#! /usr/bin/sh
#
#WBATCH
#SBATCH --job-name=FAPROTAx-AT
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


#Make an OTU table with the species names instead of ASVs
#qiime taxa collapse --i-table ${OUTPUT}/table.qza --i-taxonomy ${OUTPUT}/taxonomy.qza --p-level 7 --o-collapsed-table table_l7.qza

#Export to .biom file
#qiime tools export --input-path table_l7.qza --output-path table_l7_export

#Run the FAPROTAX code
./collapse_table.py -i table_l7_export/feature-table.biom -o table_l7_export/FAPROTAX_output_table.txt -r table_l7_export/FAPROTAX_report.txt -l table_l7_export/FAPROTAX_log.txt --input_groups_file ~/work/code/FAPROTAX_1.2.4/FAPROTAX.txt

#If you want to get: the data back into QIIME (with functions instead of #taxonomic names), use these commands:
biom convert -i table_l7_export/FAPROTAX_output_table.txt -o table_l7_export/FAPROTAX_output_table.biom --table-type="OTU table" --to-hdf5

qiime tools import --input-path table_l7_export/FAPROTAX_output_table.biom --type 'FeatureTable[Frequency]' --output-path table_l7_export/FAPROTAX_output_table.qza

#ancom analysis

qiime feature-table filter-samples \
  --i-table table_l7_export/FAPROTAX_output_table.qza \
  --m-metadata-file metadata_AT_NoControls.tsv \
  --o-filtered-table MovingPicturesPipeline/FTAX-table.qza

qiime composition add-pseudocount \
  --i-table ${OUTPUT}/FTAX-table.qza \
  --o-composition-table ${OUTPUT}/FTAX-comp-table.qza
qiime composition ancom \
  --i-table ${OUTPUT}/FTAX-comp-table.qza \
  --m-metadata-file ${OUTPUT}/sample-metadata.tsv \
  --m-metadata-column ${VAR1} \
  --o-visualization ${OUTPUT}/FTAX-ancom.qzv

#barplot
qiime taxa barplot \
  --i-table table_l7_export/FAPROTAX_output_table.qza \
  --m-metadata-file ${OUTPUT}/sample-metadata.tsv \
  --o-visualization ${OUTPUT}/fxn-taxa-bar-plots.qzv
