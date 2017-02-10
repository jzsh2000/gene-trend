#!/usr/bin/env bash

# collect following information:
# * journal id
# * date the record entered PubMed
# * date received
# * data revised
# * data accepted
# * author information

> data/pubmed/gene.pmid.dat
> data/pubmed/gene.pmdate

cat data/pubmed/gene.pmid | parallel -N 1000 echo | tr ' ' ',' \
    | parallel -j1 efetch -db pubmed -id {} -format medline \
    | tee -a data/pubmed/gene.pmid.dat \
    | grep -oP '(?<=^EDAT- )[^ ]*' > data/pubmed/gene.pmdate
