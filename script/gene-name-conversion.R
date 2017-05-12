#!/usr/bin/env Rscript
library(tidyverse)
library(stringr)

# ===== process human gene
order <- as.integer(readLines("data/current/Homo_sapiens.gene_order"))
order <- data_frame(
    GeneID = order,
    order = seq(length(order))
)
gene_info <- read_tsv("data/current/Homo_sapiens.gene_info") %>%
    select(-1) %>%
    inner_join(as.tibble(order), by = c('GeneID' = 'GeneID')) %>%
    arrange(order) %>%
    group_by(Symbol) %>%
    slice(1) %>%
    ungroup() %>%
    arrange(order) %>%
    mutate(order = 1:n()) %>%
    arrange(GeneID)

symbol2id <- gene_info %>%
    select(Symbol, GeneID) %>%
    arrange(Symbol)

ensembl <- str_extract_all(gene_info$dbXrefs, '(?<=Ensembl:)ENSG[0-9]*')
ensembl2id <- data_frame(
    Ensembl = unlist(ensembl),
    GeneID = rep(gene_info$GeneID, sapply(ensembl, length))
)

synonym <- str_split(gene_info$Synonyms, '\\|')
synonym2id <- data_frame(
    Synonym = unlist(synonym),
    GeneID = rep(gene_info$GeneID, sapply(synonym, length))
) %>%
    filter(Synonym != '-') %>%
    filter(!(Synonym %in% gene_info$Symbol)) %>%
    group_by(Synonym) %>%
    filter(n() == 1) %>%
    ungroup()

# ===== process mouse gene
order <- as.integer(readLines("data/current/Mus_musculus.gene_order"))
order <- data_frame(
    GeneID = order,
    order = seq(length(order))
)
gene_info <- read_tsv("data/current/Mus_musculus.gene_info") %>%
    select(-1) %>%
    inner_join(as.tibble(order), by = c('GeneID' = 'GeneID')) %>%
    arrange(order) %>%
    group_by(Symbol) %>%
    slice(1) %>%
    ungroup() %>%
    arrange(order) %>%
    mutate(order = 1:n()) %>%
    arrange(GeneID)

symbol2id <- gene_info %>%
    select(Symbol, GeneID) %>%
    arrange(Symbol)

ensembl <- str_extract_all(gene_info$dbXrefs, '(?<=Ensembl:)ENSMUSG[0-9]*')
ensembl2id <- data_frame(
    Ensembl = unlist(ensembl),
    GeneID = rep(gene_info$GeneID, sapply(ensembl, length))
)

synonym <- str_split(gene_info$Synonyms, '\\|')
synonym2id <- data_frame(
    Synonym = unlist(synonym),
    GeneID = rep(gene_info$GeneID, sapply(synonym, length))
) %>%
    filter(Synonym != '-') %>%
    filter(!(Synonym %in% gene_info$Symbol)) %>%
    group_by(Synonym) %>%
    filter(n() == 1) %>%
    ungroup()
