# PatCaer_asm_anno

## kmer frequencies

Generated using meryl v1.3

```
$ /usr/local/meryl-1.3/bin/meryl k=21 count output Pcaer_hifi_k21.meryl m64141e_230805_003202.hifi_reads.fastq.gz threads=32 memory=64
$ /usr/local/meryl-1.3/bin/meryl histogram Pcaer_hifi_k21.meryl > Pcaer_hifi_k21.hist
```
Pcaer_hifi_k21.hist was used as input to GenomeScope2.0 via web portal http://genomescope.org/genomescope2.0 with ploidy = 2.

## hifiasm

```
$ /usr/local/hifiasm-0.19.6/hifiasm -o Pcaer_l3_s035v0.19.6 -t 32 -l3 -s 0.35 01_raw_data/PacBioSequel2_r64141e_20230803_150341_o32374/2_B01/m64141e_230805_003202.hifi_reads.fastq.gz
```

## Metrics

I have basic bash scripts to convert hifiasm GFA and assess basic statistics like N50 and L90 and generate fasta index (.fai) file.

```
$ bash scripts/run_asmstats.sh Pcaer_l3_s035v0.19.6.bp.p_ctg.gfa
```

Another script to calculate GC content using seqtk and extract coverage estimated by hifiasm (although not used for final coverage statistics).

```
$ bash scripts/GC_hifiCov.sh Pcaer_l3_s035v0.19.6.bp.p_ctg.fa
```

To calculate the mean coverage of HiFi reads mapped back to assembly. Reads are mapped using minimap2 and mean coverage (mean depth) is calculated using samtools. 

```
$ bash scripts/run_XXXXX.sh
```

Contigs were classified using Tiara to check for contaminants and find candidate mitchondrial contigs.

```
$ tiara -i 03_hifiasm/Pcaer_l3_s035v0.19.6 -o tiara_Pcaer_s035
dups.txt --gzip -t 8 --pr
```

BUSCO v5.2.2 (CHECK) using MetaEuk.

```
$ busco -c 24 -o mollusca_prim_PatCaer -i Pcaer_l3_s035.bp.p_ctg.fa -l orthoDB/mollusca_odb10 -m genome
```

Merqury kmer copy number analysis

```
$ /usr/local/merqury-1.3/merqury.sh 02_kmer_genomescope/Pcaer_hifi_k21.meryl 03_hifiasm/Pcaer_l3_default/Pcaer_l3_s035.bp.p_ctg.fa Pcaer_l3_prim
```

