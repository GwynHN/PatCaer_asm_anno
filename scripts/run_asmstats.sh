#!/bin/bash -eu

GFA=$1

if [[ ${GFA} == *.gz ]]; then
	ASM_NAME=$(echo ${GFA} | sed 's/\.gz$//')
	gunzip ${GFA}
	GFA=${ASM_NAME}
fi

BASE_NAME=$(echo ${GFA} | sed 's/\.gfa$//')	

# Convert to FASTA format
awk '/^S/{print ">"$2;print $3}' ${GFA} > ${BASE_NAME}.fa

# Generate FAI file
module load samtools

samtools faidx ${BASE_NAME}.fa

# Get assembly statistics
module load seqtk

/usr/local/asmstats ${BASE_NAME}.fa > ${BASE_NAME}.STATS.txt

module unload seqtk
module unload samtools

pigz -p8 ${BASE_NAME}.fa
pigz -p8 ${GFA}
