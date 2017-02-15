#!/usr/bin/env bash

# collect following information:
# * journal id
# * date the record entered PubMed
# * date received
# * data revised
# * data accepted
# * author information

cat data/pubmed/gene.pmid | parallel -N 1000 echo | tr ' ' ',' \
    | parallel -j1 efetch -db pubmed -id {} -format medline \
    | tee -a data/pubmed/gene.pmid.dat \
    | grep -oP '(?<=^EDAT- )[^ ]*' > data/pubmed/gene.pmdate

gzip data/pubmed/gene.pmid.dat
mv data/pubmed/gene.pmid.dat.gz data/archives/
