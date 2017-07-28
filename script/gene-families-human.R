#!/usr/bin/env Rscript
# get list of genes with similiar names (e.g. SIGLEC1 & SIGLEC2)

library(tidyverse)
library(stringr)
load("data/current/robj/human.RData")

gene_name_pattern = '^[A-Z]+[0-9]+[A-Za-z]?$'
gene_root_pattern = '^[A-Z]+'
gene_number_pattern = '[0-9]+'
symbol2id_candidate = symbol2id %>%
    filter(str_detect(Symbol, gene_name_pattern)) %>%
    mutate(root = str_extract(Symbol, gene_root_pattern),
           number = str_extract(Symbol, gene_number_pattern)) %>%
    rename(name = Symbol, id = GeneID) %>%
    mutate(official_name = TRUE)
synonym2id_candidate = synonym2id %>%
    filter(str_detect(Synonym, gene_name_pattern)) %>%
    mutate(root = str_extract(Synonym, gene_root_pattern),
           number = str_extract(Synonym, gene_number_pattern)) %>%
    rename(name = Synonym, id = GeneID) %>%
    mutate(official_name = FALSE)

id_candidate = bind_rows(symbol2id_candidate, synonym2id_candidate) %>%
    mutate(number = as.integer(number)) %>%
    group_by(root) %>%
    mutate(gene_count = n_distinct(id)) %>%
    ungroup() %>%
    filter(gene_count >= 3) %>%
    arrange(root, number, name) %>%
    left_join(symbol2id, by = c('id' = 'GeneID')) %>%
    rename(name_official = Symbol, genes_alike = gene_count) %>%
    select(-official_name) %>%
    left_join(gene_info %>% select(GeneID, description, type_of_gene),
         by = c('id' = 'GeneID'))

write_rds(id_candidate, path = 'data/current/robj/human.gene-group.rds')
