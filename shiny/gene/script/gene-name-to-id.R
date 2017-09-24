library(tidyverse)
library(stringr)

if (basename(getwd()) == 'gene-trend') {
    setwd('shiny/gene')
}
load('robj/human.RData')
# gene_info <- read_tsv('../../data/current/Homo_sapiens.gene_info')

walk(Sys.glob('gene-list/*.txt'), function(gene_list_file) {
    gene_list_name = str_extract(basename(gene_list_file), '.*(?=.txt)')
    gene_rds_file = file.path(dirname(gene_list_file), paste0(gene_list_name, '.rds'))

    print(gene_list_name)
    if (!file.exists(gene_rds_file)) {
        data_frame(Symbol = read_lines(gene_list_file)) %>%
            left_join(gene_info) %>%
            group_by(Symbol) %>%
            summarise(GeneID = min(GeneID)) %>%
            mutate(GeneID = as.integer(GeneID)) %>%
            select(GeneID, Symbol) %>%
            arrange(GeneID) %>%
            write_rds(file.path(dirname(gene_list_file),
                                paste0(gene_list_name, '.rds')))
    }
})
