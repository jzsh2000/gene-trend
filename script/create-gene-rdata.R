#!/usr/bin/env Rscript
library(tidyverse)
library(magrittr)
library(glue)
library(here)

species <- read_csv('data/species.csv', col_types = 'ccdcc', comment = '#')

mydate = commandArgs(trailingOnly = TRUE)
if (length(mydate) == 0 ||
        !str_detect(mydate[1], '^\\d{4}-\\d{2}-\\d{2}$') ||
        !file.exists(file.path(here(), 'data', mydate[1]))) {
    cat('ERROR! should prepare raw data first\n')
    q(save = 'no')
}
datadir = file.path(here(), 'data')
maindir = file.path(here(), 'data', mydate[1])

# ========== prepare directory
dir.create(file.path(maindir, 'robj'), showWarnings = FALSE)
write_lines(mydate[1], file.path(maindir, 'robj', 'VERSION'))

mesh_headings <- read_lines(file.path(datadir, "mesh-heading.txt"))
mesh_subheadings <- read_lines(file.path(datadir, "mesh-subheading.txt"))

write_lines(c(mesh_headings, mesh_subheadings),
            path = file.path(maindir, 'robj', 'mesh.txt'))

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
          # pmid.immuno  = intersect(pmid, immuno)
          # pmid.tumor = intersect(pmid, tumor)

          gene2pubmed <-
              read_tsv(gene2pubmed_file, col_types = '_ii') %>%
              group_by(GeneID) %>%
              nest() %>%
              rename(pm_id = data) %>%
              mutate(pm_count = map_int(pm_id, ~nrow(.))) %>%
              mutate(pm_rank = min_rank(desc(pm_count)))

          walk(c(mesh_headings, mesh_subheadings), function(mesh_term) {
              mesh_pmid <- read_lines(file.path(maindir, 'topic', paste0(mesh_term, '.txt')))

              pm_id_cname = paste0('pm_id_', mesh_term)
              pm_count_cname = paste0('pm_count_', mesh_term)
              pm_rank_cname = paste0('pm_rank_', mesh_term)

              gene2pubmed_mesh <-
                  read_tsv(gene2pubmed_file, col_types = '_ii') %>%
                  filter(PubMed_ID %in% mesh_pmid) %>%
                  group_by(GeneID) %>%
                  nest() %>%
                  mutate(pm_count_mesh = map_int(data, ~nrow(.))) %>%
                  mutate(pm_rank_mesh = min_rank(desc(pm_count_mesh))) %>%
                  select_(.dots = set_names(list('GeneID', 'data',
                                                 'pm_count_mesh',
                                                 'pm_rank_mesh'),
                                            c('GeneID', pm_id_cname,
                                              pm_count_cname,
                                              pm_rank_cname)))

              gene2pubmed <<-
                  gene2pubmed %>%
                    left_join(gene2pubmed_mesh, by = 'GeneID')
          })

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
              select(-starts_with('pm_id'))

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
                       'gene2pubmed')
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
