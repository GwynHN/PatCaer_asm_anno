# PatCaer1 Assembly

## kmer frequencies

Generated using meryl v1.3

```
$ meryl-1.3/bin/meryl k=21 count output Pcaer_hifi_k21.meryl m64141e_230805_003202.hifi_reads.fastq.gz threads=32 memory=64
$ meryl-1.3/bin/meryl histogram Pcaer_hifi_k21.meryl > Pcaer_hifi_k21.hist
```
Pcaer_hifi_k21.hist was used as input to GenomeScope2.0 via web portal http://genomescope.org/genomescope2.0 with ploidy = 2.

## hifiasm

```
$ hifiasm-0.19.6/hifiasm -o Pcaer_l3_s035v0.19.6 -t 32 -l3 -s 0.35 m64141e_230805_003202.hifi_reads.fastq.gz
```

## Metrics

A bash script to convert hifiasm GFA to FASTA format and assess basic statistics like N50 and L90 and generate fasta index (.fai) file.

```
$ bash scripts/run_asmstats.sh Pcaer_l3_s035v0.19.6.bp.p_ctg.gfa
```

Calculate GC content using seqtk.

```
$ seqtk comp Pcaer_l3_s035v0.19.6.bp.p_ctg.fa | awk -v OFS='\t' '{$14 = ($4 + $5) / ($3 + $4 + $5 + $6); $15 = $9 / $2}1' | sort -n -r -k 2 > GC_propN_Pcaer_l3_s035v0.19.6_primary.txt
```

To calculate the mean coverage of HiFi reads mapped back to assembly. Reads are mapped using minimap2 and mean coverage (mean depth) is calculated using samtools. 

```
$ minimap2 -xmap-hifi -c -t 12 Pcaer_l3_s035v0.19.6.bp.p_ctg.fa -a m64141e_230805_003202.hifi_reads.fastq.gz | samtools view -b -@ 8 | samtools sort -@ 8 -o Pcaer_l3_s035v0.19.6_prim_hifi.sorted.bam
$ samtools coverage Pcaer_l3_s035v0.19.6_prim_hifi.sorted.bam > Pcaer_l3_s035v0.19.6_prim_hifi_cov_stats.txt
```

Contigs were classified using Tiara to check for contaminants and find candidate mitchondrial contigs.

```
$ tiara -i Pcaer_l3_s035v0.19.6.bp.p_ctg.fa -o tiara_Pcaer_s035 --gzip -t 8 --pr
```

BUSCO v5.2.2 

```
$ busco -c 24 -o mollusca_prim_PatCaer -i Pcaer_l3_s035v0.19.6.bp.p_ctg.fa -l orthoDB/mollusca_odb10 -m genome
```

Merqury kmer copy number analysis

```
$ /usr/local/merqury-1.3/merqury.sh Pcaer_hifi_k21.meryl Pcaer_l3_s035v0.19.6.bp.p_ctg.fa Pcaer_l3_s035_primary
```

# PatCaer1 Annotation

## Repeat Masking

Run RepeatModeler filtered assembly and combine families with mollusca lineage repeats from DFam. Run RepeatMasker

```
## RepeatModeler
$ BuildDatabase -name Pcaer1_rep PatCaer1.fa
$ RepeatModeler -database Pcaer1_rep -pa 4 -LTRStruct 

## extract the lineage specific family sequences
$ python3 RepeatMasker/famdb.py -i RepeatMasker/Libraries/Dfam.h5 families -ad mollusca -f fasta_acc > mollusca_DFam.fa
$ cat Pcaer1_rep.fa mollusca_DFam.fa > Pcaer1_mollusca.lib.fa

## RepeatMasker
$ RepeatMasker -pa 8 -xsmall -gccalc -lib Pcaer1_mollusca.lib.fa PatCaer1.fa -gff
```

## RNAseq alignment

```
$ hisat2 -x PatCaer1.masked.fa -1 Patella-total-RNA_S104_R1_001.fastq.gz -2 Patella-total-RNA_S104_R2_001.fastq.gz -p 8 -S patella_totalRNA.sam
$ samtools view -@ 8 -b patella_totalRNA.sam -o patella_totalRNA.bam
```

## BRAKER1 + BRAKER2 + TSEBRA

```
## RNA evidence
$ braker.pl --genome PatCaer1.masked.fa --bam patella_totalRNA.bam --softmasking --cores 8 --species=Patella_total --workingdir="patella_total_RNA"

## Protein evidence
$ braker.pl --genome PatCaer1.masked.fa --prot_seq=orthoDB/metazoa_odbv11.fa --softmasking --cores 8 species="patella_metazoa_odbv11" --workingdir="patella_metazoav11_prot"

## Combine gene models
$ TSEBRA/bin/tsebra.py -g patella_total_RNA/braker.gtf,patella_metazoav11_prot/braker.gtf -e patella_total_RNA/hintsfile.gff,patella_metazoav11_prot/hintsfile.gff -o Pcaer_totalRNA_metazoaODBv11_brakerGTF_ignore_phase.gtf --ignore_tx_phase

## Rename and convert to GFF3
$ TSEBRA/bin/rename_gtf.py --gtf Pcaer_totalRNA_metazoaODBv11_brakerGTF_ignore_phase.gtf --out Pcaer_totalRNA_metazoaODBv11_brakerGTF_ignore_phase.rename.gtf --translation_tab Pcaer_totalRNA_metazoaODBv11_brakerGTF_ignore_phase_renamed_genes.txt --prefix PatCaer1
$ Augustus-3.5.0/scripts/gtf2gff.pl < Pcaer_totalRNA_metazoaODBv11_brakerGTF_ignore_phase.rename.gtf --out PatCaer1.gff3
```




