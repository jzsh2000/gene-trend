#!/usr/bin/env bash

txid=${1:-9606}
parallel mkdir -p data/$txid/pubmed/{} ::: $(seq 0 9)
parallel --jobs 1 \
    "esearch -db gene -query '{}[uid]' \
    | elink -target pubmed \
    | efetch -format uid \
    | sort -n > data/$txid/pubmed/{= s/.*(?=.)// =}/{}.pmid" \
    :::: data/$txid/gene/geneList.txt
