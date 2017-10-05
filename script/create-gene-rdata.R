#!/usr/bin/env Rscript
library(tidyverse)
library(stringr)

supported_species <- c(
    'human' = 'Homo_sapiens',
    'mouse' = 'Mus_musculus'
)

# ========== prepare directory
dir.create('data/current/robj', showWarnings = FALSE)
immuno <- as.integer(read_lines("data/current/topic/immunology.txt.gz"))
tumor <- as.integer(read_lines("data/current/topic/neoplasms.txt.gz"))

writeLines(Sys.readlink('data/current'),
           file.path('data/current/robj', 'VERSION'))

walk2(unname(supported_species),
      names(supported_species),
      function(full_name, short_name) {
          print(paste('Species:', full_name))
          gene_order_file = paste0('data/current/',full_name,'.gene_order')
          gene_info_file = paste0('data/current/',full_name,'.gene_info')
          gene_summary_file = paste0('data/current/',full_name,
                                     '.gene_summary')
          gene2pubmed_file = paste0('data/current/',full_name,
                                    '.gene2pubmed')
          rdata_file = paste0('data/current/robj/',short_name,'.RData')

          ensembl_pattern = 'some_strange_pattern'
          if (short_name == 'human') {
              ensembl_pattern = '(?<=Ensembl:)ENSG[0-9]*'
          } else if (short_name == 'mouse') {
              ensembl_pattern = '(?<=Ensembl:)ENSMUSG[0-9]*'
          }

          order <- suppressMessages(
              read_tsv(gene_order_file,
                       col_types = '__i______________')) %>%
              mutate(order = seq_along(GeneID))

          pmid = unique(read_tsv(gene2pubmed_file,col_types = '__i'))[[1]]
          pmid.immuno  = intersect(pmid, immuno)
          pmid.tumor = intersect(pmid, tumor)

          gene2pubmed <-
              read_tsv(gene2pubmed_file, col_types = '_ii') %>%
              group_by(GeneID) %>%
              nest() %>%
              rename(PubMed_ID = data) %>%
              mutate(pm_count = map_int(PubMed_ID, ~nrow(.))) %>%
              mutate(pm_rank = min_rank(desc(pm_count)))

          gene2pubmed.immuno <-
              read_tsv(gene2pubmed_file, col_types = '_ii') %>%
              group_by(GeneID) %>%
              filter(PubMed_ID %in% pmid.immuno) %>%
              nest() %>%
              rename(PubMed_ID = data) %>%
              mutate(pm_count_immuno = map_int(PubMed_ID, ~nrow(.))) %>%
              mutate(pm_rank_immuno = min_rank(desc(pm_count_immuno)))

          gene2pubmed.tumor <-
              read_tsv(gene2pubmed_file, col_types = '_ii') %>%
              group_by(GeneID) %>%
              filter(PubMed_ID %in% pmid.tumor) %>%
              nest() %>%
              rename(PubMed_ID = data) %>%
              mutate(pm_count_tumor = map_int(PubMed_ID, ~nrow(.))) %>%
              mutate(pm_rank_tumor = min_rank(desc(pm_count_tumor)))

          gene_summary <- read_tsv(gene_summary_file,
                                   col_names = c('GeneID', 'Summary'),
                                   col_types = 'ic') %>%
              replace_na(list(Summary = ''))

          gene_info <- suppressMessages(
              read_tsv(gene_info_file,
                       col_types = '_ic_cccccccc_c_')) %>%
              inner_join(as.tibble(order), by = c('GeneID' = 'GeneID')) %>%
              group_by(Symbol) %>%
              arrange(order) %>%
              slice(1) %>%
              ungroup() %>%
              arrange(order) %>%
              mutate(order = 1:n()) %>%
              arrange(GeneID) %>%
              left_join(gene_summary, by = "GeneID") %>%
              left_join(gene2pubmed, by = "GeneID") %>%
              select(-PubMed_ID) %>%
              replace_na(list(pm_count = 0,
                              pm_rank = max(.$pm_rank, na.rm = T) + 1)) %>%
              left_join(gene2pubmed.immuno, by = "GeneID") %>%
              select(-PubMed_ID) %>%
              replace_na(list(pm_count_immuno = 0,
                              pm_rank_immuno = max(.$pm_rank_immuno,
                                            na.rm = T) + 1)) %>%
              left_join(gene2pubmed.tumor, by = "GeneID") %>%
              select(-PubMed_ID) %>%
              replace_na(list(pm_count_tumor = 0,
                              pm_rank_tumor = max(.$pm_rank_tumor,
                                            na.rm = T) + 1))

          symbol2id <- gene_info %>%
              select(Symbol, GeneID) %>%
              arrange(Symbol)

          ensembl <- str_extract_all(gene_info$dbXrefs, ensembl_pattern)
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

          save(gene_info, symbol2id, synonym2id, ensembl2id,
               gene2pubmed, gene2pubmed.immuno, gene2pubmed.tumor,
               file = rdata_file)
      })

# ========== homologene (human and mouse)
homologene <- read_tsv('data/current/homologene.data',
         col_types = 'cccc__',
         col_names = c('id', 'tax_id', 'gene_id', 'gene_name')) %>%
    filter(tax_id %in% c('9606', '10090'))

homologene_human <- homologene %>%
    filter(tax_id == '9606') %>%
    rename(human_gene_id = gene_id,
           human_gene_name = gene_name) %>%
    select(-tax_id)

homologene_mouse <- homologene %>%
    filter(tax_id == '10090') %>%
    rename(mouse_gene_id = gene_id,
           mouse_gene_name = gene_name) %>%
    select(-tax_id)

inner_join(homologene_human, homologene_mouse, by = 'id') %>%
    write_rds('data/current/robj/human-mouse-homologene.rds')
