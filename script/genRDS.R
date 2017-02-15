#!/usr/bin/env Rscript

library(tidyverse)
library(lubridate)

setwd("data/summary")

# ===== read data
pubmed_date <- read_tsv("pubmedDate.txt",
                        col_names = c("pmid", "date"),
                        col_types = "iD")
gene_pubmed = read_tsv("geneToPubmed.txt",
                       col_names = c("gid", "pmid"),
                       col_types = "ii")
gene_name = read_tsv("geneNames.txt",
                     col_names = c("gid", "gname"),
                     col_types = "ic")

# ===== merge mulitple tables
gene_pubmed = left_join(gene_pubmed, pubmed_date,
                        by = "pmid") %>%
    left_join(gene_name, by = "gid") %>%
    select(gid, gname, everything())

# gene_pubmed_all = gene_pubmed %>%
#     mutate(year = year(date)) %>%
#     group_by(gid, gname) %>%
#     summarise(count = n()) %>%
#     ungroup() %>%
#     mutate(rank = min_rank(desc(count))) %>%
#     arrange(desc(count))

# gene_pubmed_byYear = gene_pubmed %>%
#     mutate(year = year(date)) %>%
#     group_by(gid, gname, year) %>%
#     summarise(count = n())

# ===== write RDS object
write_rds(gene_pubmed, "gene_pubmed.rds", compress="gz")
# write_rds(gene_pubmed_all, "gene_pubmed_all.rds", compress="gz")
# write_rds(gene_pubmed_byYear, "gene_pubmed_byYear.rds", compress="gz")
