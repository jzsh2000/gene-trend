#!/usr/bin/env bash

# collect following information:
# * journal id
# * date the record entered PubMed
# * date received
# * data revised
# * data accepted
# * author information

[ $# -eq 0 ] && txid=9606 || txid=$1
cat data/$txid/pubmed/gene.pmid | parallel -N 1000 echo | tr ' ' ',' \
    | parallel -j1 efetch -db pubmed -id {} -format medline \
    | tee -a data/$txid/pubmed/gene.pmid.dat \
    | grep -oP '(?<=^EDAT- )[^ ]*' > data/$txid/pubmed/gene.pmdate

gzip data/$txid/pubmed/gene.pmid.dat
mv data/$txid/pubmed/gene.pmid.dat.gz data/$txid/archives/
