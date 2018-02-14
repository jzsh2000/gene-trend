#!/usr/bin/env Rscript
library(tidyverse)
library(glue)
library(here)

species <- read_csv('data/species.csv', col_types = 'ccdcc')
supported_species <- deframe(species %>% select(short_name, full_name))
mydate = commandArgs(trailingOnly = TRUE)
if (length(mydate) == 0 || 
        !str_detect(mydate[1], '^\\d{4}-\\d{2}-\\d{2}$') ||
        !file.exists(file.path(here(), 'data', mydate[1]))) {
    cat('ERROR! should prepare raw data first\n')
    q(save = 'no')
}
maindir = file.path(here(), 'data', mydate[1])

# ========== prepare directory
dir.create(file.path(maindir, 'robj'), showWarnings = FALSE)
write_lines(mydate[1], file.path(maindir, 'robj', 'VERSION'))

immuno <- as.integer(read_lines(file.path(maindir, "topic", "immunology.txt")))
tumor <- as.integer(read_lines(file.path(maindir, "topic", "neoplasms.txt")))

walk(seq_len(nrow(species)),
      function(n) {
          tax_id = species$tax_id[n]
          full_name = species$full_name[n]
          short_name = species$short_name[n]
          suffix = species$suffix[n]
          ensembl_pattern = species$ensembl_pattern[n]

          print(paste('Species:', full_name))
          gene_order_file = file.path(maindir, glue('{full_name}.gene_order'))
          gene_info_file = file.path(maindir, glue('{full_name}.gene_info.gz'))
          gene_summary_file = file.path(maindir, glue('{full_name}.gene_summary'))
          gene2pubmed_file = file.path(maindir, glue('{full_name}.gene2pubmed'))
          rdata_file = file.path(maindir, 'robj', glue('{short_name}.RData'))

          order <- suppressMessages(
              read_lines(gene_order_file) %>%
                  as.integer() %>%
                  enframe(name = 'order', value = 'GeneID')
          )

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

          gene_summary <- suppressWarnings(read_tsv(gene_summary_file,
                                   col_names = c('GeneID', 'Summary'),
                                   col_types = 'ic')) %>%
              replace_na(list(Summary = ''))

          gene_info <- suppressMessages(
              read_tsv(gene_info_file,
                       col_types = 'iic_cccccccc_c__')) %>%
              filter(`#tax_id` == tax_id) %>%
              select(-`#tax_id`) %>%
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

          obj_list = c('gene_info', 'symbol2id', 'synonym2id', 'ensembl2id',
                       'gene2pubmed', 'gene2pubmed.immuno', 'gene2pubmed.tumor')
          walk2(obj_list, paste(obj_list, suffix, sep = '.'),
                ~assign(.y, get(.x), envir=globalenv()))
          save(list = paste(obj_list, suffix, sep = '.'),
               file = rdata_file)
      })

# ========== homologene (human and mouse)
homologene <- read_tsv(file.path(maindir, 'homologene.data'),
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
    write_rds(file.path(maindir, 'robj', 'human-mouse-homologene.rds'))
