#!/usr/bin/env Rscript
# get list of genes with similiar names (e.g. SIGLEC1 & SIGLEC2)

library(tidyverse)
library(stringr)
library(forcats)
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
    mutate(name_official_lgl = (name == name_official)) %>%
    left_join(gene_info %>% select(GeneID, description, type_of_gene),
         by = c('id' = 'GeneID')) %>%
    replace_na(list(description = ''))

write_rds(id_candidate, path = 'data/current/robj/human.gene-group.rds')

# get description of gene groups
group_stat = id_candidate %>%
    select(root, genes_alike) %>%
    unique() %>%
    arrange(desc(genes_alike)) %>%
    mutate(description = map_chr(root, function(group_name) {
        description_all = id_candidate %>%
            filter(root == group_name, name_official_lgl) %>%
            pull(description)
        if (length(description_all) == 0) {return('')}

        description_max_length = max(str_length(description_all))
        description_header = ''
        for (i in seq(description_max_length)) {
            description_header_df = str_sub(description_all, end = i) %>%
                fct_count(sort = TRUE) %>%
                mutate(prop = n / sum(n))
            if ((description_header_df %>% slice(1) %>% pull(prop)) < .8) {
                description_header = description_header_df %>%
                    slice(1) %>%
                    pull(f) %>%
                    as.character() %>%
                    str_sub(end = -2) %>%
                    str_trim() %>%
                    str_replace(',$', '')
                break
            }
        }
        print(description_header)
        return(description_header)
    }))

write_rds(group_stat, path = 'data/current/robj/human.gene-group.stat.rds')
