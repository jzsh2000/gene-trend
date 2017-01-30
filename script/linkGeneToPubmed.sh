#!/usr/bin/env bash

parallel mkdir -p data/pubmed/{} ::: $(seq 0 9)
parallel --jobs 1 \
    "esearch -db gene -query '{}[uid]' \
    | elink -target pubmed \
    | efetch -format uid \
    | sort -n > data/pubmed/{= s/.*(?=.)// =}/{}.pmid" \
    :::: data/geneList.txt

cat data/pubmed/*/*.pmid | sort -nu > data/pubmed/gene.pmid
