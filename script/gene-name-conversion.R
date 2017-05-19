#!/usr/bin/env Rscript
library(tidyverse)
library(stringr)

# ========== prepare directory
dir.create('data/current/robj', showWarnings = FALSE)

# ===== process human gene
order <- read_tsv("data/current/Homo_sapiens.gene_order") %>%
    select(GeneID) %>%
    mutate(order = row_number())

gene2pubmed <- read_tsv('data/current/Homo_sapiens.gene2pubmed') %>%
    select(-1) %>%
    group_by(GeneID) %>%
    nest() %>%
    rename(PubMed_ID = data) %>%
    mutate(pmid_count = map_int(PubMed_ID, ~nrow(.)))

gene_info <- read_tsv("data/current/Homo_sapiens.gene_info") %>%
    select(-1) %>%
    inner_join(as.tibble(order), by = c('GeneID' = 'GeneID')) %>%
    group_by(Symbol) %>%
    arrange(order) %>%
    slice(1) %>%
    ungroup() %>%
    arrange(order) %>%
    mutate(order = 1:n()) %>%
    arrange(GeneID) %>%
    left_join(gene2pubmed, by = "GeneID") %>%
    select(-PubMed_ID)

symbol2id <- gene_info %>%
    select(Symbol, GeneID) %>%
    arrange(Symbol)

ensembl <- str_extract_all(gene_info$dbXrefs, '(?<=Ensembl:)ENSG[0-9]*')
ensembl2id <- data_frame(
    Ensembl = unlist(ensembl),
    GeneID = rep(gene_info$GeneID, sapply(ensembl, length)),
    order = rep(gene_info$order, sapply(ensembl, length))
) %>%
    group_by(Ensembl) %>%
    arrange(order) %>%
    slice(1) %>%
    ungroup() %>%
    select(-order)

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

save(gene_info, symbol2id, synonym2id, ensembl2id, gene2pubmed,
     file = 'data/current/robj/human.RData')
human.id = c(gene_info$GeneID,
             symbol2id$Symbol,
             ensembl2id$Ensembl,
             synonym2id$Synonym)

# ===== process mouse gene
order <- read_tsv("data/current/Mus_musculus.gene_order") %>%
    select(GeneID) %>%
    mutate(order = row_number())

gene2pubmed <- read_tsv('data/current/Mus_musculus.gene2pubmed') %>%
    select(-1) %>%
    group_by(GeneID) %>%
    nest() %>%
    rename(PubMed_ID = data) %>%
    mutate(pmid_count = map_int(PubMed_ID, ~nrow(.)))

gene_info <- read_tsv("data/current/Mus_musculus.gene_info") %>%
    select(-1) %>%
    inner_join(as.tibble(order), by = c('GeneID' = 'GeneID')) %>%
    group_by(Symbol) %>%
    arrange(order) %>%
    slice(1) %>%
    ungroup() %>%
    arrange(order) %>%
    mutate(order = 1:n()) %>%
    arrange(GeneID) %>%
    left_join(gene2pubmed, by = "GeneID") %>%
    select(-PubMed_ID)

symbol2id <- gene_info %>%
    select(Symbol, GeneID) %>%
    arrange(Symbol)

ensembl <- str_extract_all(gene_info$dbXrefs, '(?<=Ensembl:)ENSMUSG[0-9]*')
ensembl2id <- data_frame(
    Ensembl = unlist(ensembl),
    GeneID = rep(gene_info$GeneID, sapply(ensembl, length)),
    order = rep(gene_info$order, sapply(ensembl, length))
) %>%
    group_by(Ensembl) %>%
    arrange(order) %>%
    slice(1) %>%
    ungroup() %>%
    select(-order)

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

save(gene_info, symbol2id, synonym2id, ensembl2id, gene2pubmed,
     file = 'data/current/robj/mouse.RData')
mouse.id = c(gene_info$GeneID,
             symbol2id$Symbol,
             ensembl2id$Ensembl,
             synonym2id$Synonym)

# ==========
write_rds(set_names(list(human.id, mouse.id), c('human', 'mouse')),
          path = 'data/current/robj/id.rds')
