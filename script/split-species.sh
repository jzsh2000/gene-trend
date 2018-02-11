#!/usr/bin/env bash

cd $(dirname $0)/..
outdir=${1:-.}

echo 'Homo_sapiens.gene2pubmed'
zcat ${outdir}/gene2pubmed.gz \
    | awk 'NR == 1 || $1 == "9606"' \
    > ${outdir}/Homo_sapiens.gene2pubmed

echo 'Mus_musculus.gene2pubmed'
zcat ${outdir}/gene2pubmed.gz \
    | awk 'NR == 1 || $1 == "10090"' \
    > ${outdir}/Mus_musculus.gene2pubmed
