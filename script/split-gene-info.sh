#!/usr/bin/env bash

cd $(dirname $0)/..
zcat data/current/gene_info.gz \
    | awk 'NR == 1 || $1 == "9606"' \
    > data/current/Homo_sapiens.gene_info

zcat data/current/gene_info.gz \
    | awk 'NR == 1 || $1 == "10090"' \
    > data/current/Mus_musculus.gene_info
