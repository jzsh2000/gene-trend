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

mouse_gene2pdat <- read_tsv('data/current/Mus_musculus.gene2pdat',
                            col_names = c('GeneID', 'year', 'count'),
                            col_types = 'iii') %>%
    arrange(GeneID)
mouse_gene_info <- read_tsv('data/current/Mus_musculus.gene_info') %>%
    filter(GeneID %in% mouse_gene2pdat$GeneID) %>%
    select(GeneID, Symbol, Synonyms, description) %>%
    arrange(GeneID)

save(human_gene2pdat, human_gene_info, mouse_gene2pdat, mouse_gene_info,
     file = 'shiny/gene-trend/data/human-mouse.Rdata')
