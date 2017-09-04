library(tidyverse)
library(stringr)

human_gene2pdat <- read_tsv('data/current/Homo_sapiens.gene2pdat',
                            col_names = c('GeneID', 'year', 'count'),
                            col_types = 'iii') %>%
    arrange(GeneID)
human_gene_info <- read_tsv('data/current/Homo_sapiens.gene_info') %>%
    filter(GeneID %in% human_gene2pdat$GeneID) %>%
    select(GeneID, Symbol, Synonyms, description) %>%
    arrange(GeneID)
human_gene_name <- human_gene2pdat %>%
    select(GeneID) %>%
    unique() %>%
    left_join(human_gene_info, by = 'GeneID') %>%
    pull(Symbol) %>%
    sort() %>%
    str_subset('^[A-Z][-A-z0-9]+')

mouse_gene2pdat <- read_tsv('data/current/Mus_musculus.gene2pdat',
                            col_names = c('GeneID', 'year', 'count'),
                            col_types = 'iii') %>%
    arrange(GeneID)
mouse_gene_info <- read_tsv('data/current/Mus_musculus.gene_info') %>%
    filter(GeneID %in% mouse_gene2pdat$GeneID) %>%
    select(GeneID, Symbol, Synonyms, description) %>%
    arrange(GeneID)
mouse_gene_name <- mouse_gene2pdat %>%
    select(GeneID) %>%
    unique() %>%
    left_join(mouse_gene_info, by = 'GeneID') %>%
    pull(Symbol) %>%
    sort() %>%
    str_subset('^[A-Z][-A-z0-9]+')

save(human_gene2pdat,
     human_gene_info,
     human_gene_name,
     mouse_gene2pdat,
     mouse_gene_info,
     mouse_gene_name,
     file = 'shiny/gene-trend/data/human-mouse.Rdata')
