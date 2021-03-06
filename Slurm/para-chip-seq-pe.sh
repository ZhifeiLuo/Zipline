#!/bin/bash
. /home/rcf-proj/pjf/zhifeilu/miniconda3/etc/profile.d/conda.sh
conda activate z
n=`nproc`
cd `pwd`
base=$1
#=================================
#alignment
bwa mem -t $n /home/rcf-proj/zl1/refs/hg38/bwa/hg38 <( zcat ${base}_R1.fastq.gz ) <(zcat ${base}_R2.fastq.gz) | samblaster 2> ${base}.dup.qc | samtools view -Su - | sambamba sort -o ${base}.mark.bam /dev/stdin
#generate sorted bam file
echo 'Alignment done'
sambamba view -p -t $n -h -f bam -F "not (supplementary or secondary_alignment or unmapped or duplicate) and mapping_quality>=30" ${base}.mark.bam > ${base}.filt.bam
echo 'Reads filtered'
sambamba index -t $n ${base}.filt.bam
sambamba flagstat -t $n ${base}.mark.bam > ${base}.raw.flagstat
sambamba flagstat -t $n ${base}.filt.bam > ${base}.filt.flagstat
echo 'QC done'
bamCoverage -b ${base}.filt.bam -o ${base}.bigwig -of bigwig --binSize 10 -p $n \
	--ignoreForNormalization chrX chrM \
	-bl /home/rcf-proj/zl1/refs/hg38/hg38.blacklist.bed \
	--effectiveGenomeSize 2701495761 \
	--extendReads --normalizeUsing RPGC
echo 'Track generated'
mkdir -p bam qc peaks fastq track
rm ${base}*mark* ${base}.sai
mv ${base}*fastq.gz fastq
mv ${base}*.bam ${base}*.bam.bai bam
mv ${base}*bigwig track
mv ${base}*flagstat ${base}*.qc qc

