library(tidyverse)
library(stringr)

gene_summary <- read_tsv('data/current/Homo_sapiens.gene_summary',
                         col_names = c('id', 'summary'),
                         col_types = 'ic')
load('data/current/robj/human.RData')
CD.symbol = symbol2id %>%
    filter(grepl('^CD[0-9]+[A-Za-z]?$', Symbol, perl = TRUE)) %>%
    mutate(Number = Symbol %>% map_chr(~str_extract(., '(?<=CD)[0-9]*'))) %>%
    mutate(Number = as.integer(Number)) %>%
    arrange(Number, Symbol)

CD.synonym = synonym2id %>%
    filter(!(GeneID %in% CD.symbol$GeneID)) %>%
    filter(grepl('^CD[0-9]+[A-Za-z]?$', Synonym, perl = TRUE)) %>%
    mutate(Number = Synonym %>%
               map_chr(~str_extract(., '(?<=CD)[0-9]*'))) %>%
    mutate(Number = as.integer(Number)) %>%
    arrange(Number, Synonym)
