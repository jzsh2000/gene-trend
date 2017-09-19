library(tidyverse)

gene_info <- read_tsv('../../data/current/Homo_sapiens.gene_info')
data_frame(Symbol = read_lines('gene-list/surface-marker.txt')) %>%
    left_join(gene_info) %>%
    group_by(Symbol) %>%
    summarise(GeneID = min(GeneID)) %>%
    mutate(GeneID = as.integer(GeneID)) %>%
    select(GeneID, Symbol) %>%
    arrange(GeneID) %>%
    write_rds('gene-list/surface-marker.rds')
