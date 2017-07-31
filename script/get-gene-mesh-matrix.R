#!/usr/bin/env Rscript

library(tidyverse)
library(stringr)
library(Matrix)
library(tidytext)

# minimal gene-mesh link
threshold = 1
species = str_subset(dir('data/current/gene-mesh'), '^[0-9]+$')

walk(species, function(tax_id) {
    main_path = file.path('data/current/gene-mesh', tax_id)
    print(main_path)

    walk(c('gene-mesh', 'gene-mesh.major'), function(gene_mesh) {
        gene_mesh_file = paste(gene_mesh, 'txt', sep = '.')
        gene_mesh_matrix_rds = paste(gene_mesh, 'maitrx.rds', sep = '.')
        gene_mesh_tf_idf_rds = paste(gene_mesh, 'tf-idf.rds', sep = '.')

        print(gene_mesh_file)
        dat <- read_tsv(file.path(main_path, gene_mesh_file),
                        col_names = c('gene_id','mesh_id','count'),
                        col_types = 'cci') %>%
            filter(count >= threshold)
        dat_gene = dat %>% pull(gene_id) %>% unique() %>% sort()
        dat_mesh = dat %>% pull(mesh_id) %>% unique() %>% sort()

        dat_matrix = sparseMatrix(i = dat %>% pull(gene_id) %>% match(dat_gene),
                                  j = dat %>% pull(mesh_id) %>% match(dat_mesh),
                                  x = dat %>% pull(count),
                                  dims = c(length(dat_gene), length(dat_mesh)),
                                  dimnames = list(dat_gene, dat_mesh))
        write_rds(dat_matrix, file.path(main_path, gene_mesh_matrix_rds))

        dat_tf_idf = dat %>%
            bind_tf_idf(mesh_id, gene_id, count) %>%
            arrange(gene_id, desc(tf_idf))
        write_rds(dat_tf_idf, file.path(main_path, gene_mesh_tf_idf_rds))
    })
})
