#!/usr/bin/env bash

[ $# -eq 0 ] && txid=9606 || txid=$1
parallel mkdir -p data/$txid/pubmed/{} ::: $(seq 0 9)
parallel --jobs 1 \
    "esearch -db gene -query '{}[uid]' \
    | elink -target pubmed \
    | efetch -format uid \
    | sort -n > data/$txid/pubmed/{= s/.*(?=.)// =}/{}.pmid" \
    :::: data/$txid/gene/geneList.txt

cat data/$txid/pubmed/*/*.pmid | sort -nu > data/$txid/pubmed/gene.pmid
