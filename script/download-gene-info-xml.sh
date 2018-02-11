#!/usr/bin/env bash
set -ue
cd $(dirname $0)/..

outdir=${1:-.}
mkdir -p ${outdir}/{human,mouse}

zcat $outdir/Homo_sapiens.gene_info.gz \
    | tail -n+2 \
    | cut -f 2 \
    | parallel -N 200 echo \
    | tr ' ' ',' \
    | parallel --jobs 1 --keep-order --verbose \
        efetch -db gene -id {} -format xml \
            '|' gzip -c \
            '>' $outdir/human/{\#}.xml.gz

zcat $outdir/Mus_musculus.gene_info.gz \
    | tail -n+2 \
    | cut -f 2 \
    | parallel -N 200 echo \
    | tr ' ' ',' \
    | parallel --jobs 1 --keep-order --verbose \
        efetch -db gene -id {} -format xml \
            '|' gzip -c \
            '>' $outdir/mouse/{\#}.xml.gz
