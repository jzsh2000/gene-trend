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

# prepare MeSH names
mesh_tree <- read_tsv("data/mesh/2017MeshTree.txt",
                      col_types = 'ccc')
human_mesh_id = read_tsv("data/current/gene-mesh/9606/gene-mesh.major.txt",
                         col_types = 'ccc',
                         col_names = c('gene_id', 'mesh_id', 'n')) %>%
    select(mesh_id) %>%
    unique()
mouse_mesh_id = read_tsv("data/current/gene-mesh/10090/gene-mesh.major.txt",
                         col_types = 'ccc',
                         col_names = c('gene_id', 'mesh_id', 'n')) %>%
    select(mesh_id) %>%
    unique()

human_gene_mesh <- read_tsv("data/current/gene-mesh/9606/gene-mesh-pubmed-pdat.major.txt",
                            col_types = 'icii',
                            col_names = c('GeneID', 'mesh_id', 'year', 'pubmed_id'))
mouse_gene_mesh <- read_tsv("data/current/gene-mesh/10090/gene-mesh-pubmed-pdat.major.txt",
                            col_types = 'icii',
                            col_names = c('GeneID', 'mesh_id', 'year', 'pubmed_id'))

# save RData to file
save(human_gene2pdat,
     human_gene_info,
     human_gene_name,
     human_gene_mesh,
     mouse_gene2pdat,
     mouse_gene_info,
     mouse_gene_name,
     mouse_gene_mesh,
     file = 'shiny/gene-trend/data/human-mouse.Rdata')

mesh_dat = mesh_tree %>%
    rename(mesh_id = `Desc Ui`,
           tree_number = `Tree Number`,
           mesh_term = Term) %>%
    select(mesh_id, mesh_term, tree_number)

write_rds(mesh_dat, 'shiny/gene-trend/data/mesh_dat.rds')
