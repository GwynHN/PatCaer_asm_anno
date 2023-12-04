##########
# GC, coverage, classification and size plots
# Cumulative sum plot
##########

library(tidyverse)
library(ggplot2)

GC_cov_size_plot <- function(fileGC, fileCov, fileFAI, tiaraFile, title){
  
  ## GC content calculated using seqtk, expecting 2 columns "chr" and "GC_content"
  GC.contigs <- read.delim(fileGC, header = T, sep = '\t')
  
  ## mean coverage of hifi reads mapped using minimap2 and calculated using samtools
  ## select columns with contig name and meandepth
  hifi.contigs <- read.delim(fileCov, header = F, sep = '\t')
  colnames(hifi.contigs) <- c("chr", "cov")
  gc.hifi <- merge(GC.contigs, hifi.contigs, by = "chr")
  
  ## Add contig length information from FAI file
  contig.lengths <- read.delim(fileFAI, header = F, sep = '\t') %>%
    select(V1, V2)
  colnames(contig.lengths) <- c("chr", "contig_length")
  gc.hifi.length <- merge(gc.hifi, contig.lengths, by = "chr")
  
  ## Add tiara sequence classification
  tiara <- read.delim(tiaraFile, header = F, sep = '\t') %>%
    unite("classification", V2:V3, remove = TRUE)
  colnames(tiara) <- c("chr", "classification")
  gc.hifi.length.tiara <- merge(gc.hifi.length, tiara, by = "chr")
  
  ## Assign colors for the classifications
  tiara.colors <- c("eukarya_n/a" = "#E69F00", 
                    "organelle_mitochondrion" = "#0072B2",  "organelle_plastid" = "#009E73",
                    "archaea_n/a" = "#CC79A7", "bacteria_n/a" = "#D55E00",
                    "organelle_unknown" = "#999999", "unknown_n/a" = "#999999")
  
  
  ggplot(gc.hifi.length.tiara, aes(x=GC_content, y=cov, color = classification)) + 
    
    ## set up geom_point this way to get both fill to be the colors set manually and there to be an outline,
    ## stroke determines the thickness of the outline, shape is needed to modify these options
    geom_point(aes(fill = classification, size = contig_length), 
               alpha=0.75, shape = 21, color = "darkgrey", stroke=0.25) +
    
    scale_size_continuous(name = "Contig Length", limits = c(10000,81000000), 
                          breaks=c(50000, 40000000,80000000), # seq(0, 50000000, by =10000000),
                          labels = scales::comma) + 
    
    ## Added drop = TRUE and limits = forces (required) in order to drop unused classifications
    scale_fill_manual(name="Sequence", values=tiara.colors, drop = TRUE, limits = force,
                      ## Specific for final assembly
                      labels=c("Nuclear", "Mitochondrial")) +
    guides(fill = guide_legend(override.aes = list(size=3))) +
    xlab("GC content") + 
    ylab("HiFi coverage") +
    scale_y_continuous(trans=scales::pseudo_log_trans(base = 10)) +
    ggtitle(title) + 
    theme_light()
  
}


### Final Assembly
GC_cov_size_plot("GC_contigs_Pcaer_l3_s035v0.19.6.bp.p_ctg.txt", "Pcaer_s035_0.19_hifi_meancov.txt", 
                 "PatCaer1.fa.fai", "tiara_Pcaer_s035_0.19_primary_modified.classifications.txt",
                 "PatCaer1")
ggsave("PatCaer1_withMito_GCcovClassification.png", width = 5.2, height = 3.15, units = "in")


## Plot cumulative sum of contigs ordered largest to smallest

gc.hifi.length.tiara.PatCaer1 %>%
  arrange(desc(contig_length)) %>%
  ggplot(aes(x=1:nrow(gc.hifi.length.tiara.PatCaer1), y=cumsum(contig_length))) + geom_line() +
  scale_y_continuous(labels = scales::comma) +
  xlab("Contigs") + ylab("Cumulative sum") +
  theme_light()
ggsave("PatCaer1_withMito_cumsum.png", width = 3, height = 3.15, units = "in")

#########
# Annotation feature length distributions
#########

library(tidyverse)
library(ggplot2)

lengths.gtf <- function(file, prefix){
  
  gtf <- read.delim(file, header=F, sep="\t", comment.char = '#')
  
  colnames(gtf) <- c("scaffold", "source", "feature", "start", "end", "score", "strand", "phase", "attribute")
  
  lengths <- gtf %>%
    mutate(length = abs(end-start),
           name= prefix) %>%
    filter(feature %in% c("gene", "exon")) %>%
    select(feature, length, name)
  
  assign(paste(prefix, "lengths", sep="."), lengths, .GlobalEnv)
  
}

lengths.gtf("Annotation/Pcaer_totalRNA_metazoaODBv11_brakerGTF_ignore_phase.gtf", "P. caerulea")
lengths.gtf("other_Patella/Patella_depressa-GCA_948474765.1-2023_05-genes.gtf", "P. depressa") # ensembl with RNA
lengths.gtf("other_Patella/Patella_vulgata-GCA_932274485.1-2022_08-genes.gtf", "P. vulgata") # ensembl using only protein; BRAKER2
lengths.gtf("other_Patella/Patella_pellucida-GCA_917208275.1-2022_02-genes.gtf", "P. pellucida") # ensembl with RNA

plotDF <- rbind(`P. caerulea.lengths`, `P. depressa.lengths`, `P. vulgata.lengths`, `P. pellucida.lengths`)

ggplot(data=plotDF, aes(x=name, y=length, fill=feature)) + 
  geom_boxplot() + 
  scale_y_continuous(trans='log10') +
  annotation_logticks(sides = "l") +
  ggtitle("Patella annotation feature length comparison") + 
  theme_bw() +
  xlab("Species") +
  ylab("Feature length") + 
  guides(fill=guide_legend(title="Feature"))
ggsave("Patella_GTF_feature_comparisons.jpg")


## Example command to summarize feature lengths
`P. pellucida.lengths` %>%
  group_by(feature) %>%
  summarize(mean(length), median(length))
