#!/usr/bin/env bash

cd $(dirname $0)/..

if [ ! -f data/current/Homo_sapiens.gene_info ]; then
    echo 'Homo_sapiens.gene_info'
    zcat data/current/gene_info.gz \
        | awk 'NR == 1 || $1 == "9606"' \
        > data/current/Homo_sapiens.gene_info
fi

if [ ! -f data/current/Mus_musculus.gene_info ]; then
    echo 'Mus_musculus.gene_info'
    zcat data/current/gene_info.gz \
        | awk 'NR == 1 || $1 == "10090"' \
        > data/current/Mus_musculus.gene_info
fi

if [ ! -f data/current/Homo_sapiens.gene2pubmed ]; then
    echo 'Homo_sapiens.gene2pubmed'
    zcat data/current/gene2pubmed.gz \
        | awk 'NR == 1 || $1 == "9606"' \
        > data/current/Homo_sapiens.gene2pubmed
fi

if [ ! -f data/current/Mus_musculus.gene2pubmed ]; then
    echo 'Mus_musculus.gene2pubmed'
    zcat data/current/gene2pubmed.gz \
        | awk 'NR == 1 || $1 == "10090"' \
        > data/current/Mus_musculus.gene2pubmed
fi
