#!/usr/bin/env bash
prefix=${1:-.}

esearch -db gene -query '"Homo sapiens"[Organism] AND alive[prop]' \
        -sort 'Gene Weight' \
    | efetch -format tabular \
    | sed -e 's/\ttax_id/\ntax_id/g' \
    | awk 'NR == 1 || $1~/9606/' \
    | sed -e 's/\t$//' \
    | grep -v '^$' \
    | tail -n+2 \
    | cut -f3 \
    > ${prefix}/Homo_sapiens.gene_order

esearch -db gene -query '"Mus musculus"[Organism] AND alive[prop]' \
        -sort 'Gene Weight' \
    | efetch -format tabular \
    | sed -e 's/\ttax_id/\ntax_id/g' \
    | awk 'NR == 1 || $1~/10090/' \
    | sed -e 's/\t$//' \
    | grep -v '^$' \
    | tail -n+2 \
    | cut -f3 \
    > ${prefix}/Mus_musculus.gene_order
