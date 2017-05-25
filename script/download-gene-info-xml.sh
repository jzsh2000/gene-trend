#!/usr/bin/env bash
set -ue
cd $(dirname $0)/..

outdir='data/current'

cat $outdir/Homo_sapiens.gene_info \
    | tail -n+2 \
    | cut -f 2 \
    | parallel -N 1000 echo \
    | tr ' ' ',' \
    | parallel --jobs 1 --keep-order efetch -db gene -id {} -format xml '>' $outdir/human/{#}.xml

cat $outdir/Mus_musculus.gene_info \
    | tail -n+2 \
    | cut -f 2 \
    | parallel -N 1000 echo \
    | tr ' ' ',' \
    | parallel --jobs 1 --keep-order efetch -db gene -id {} -format xml '>' $outdir/mouse/{#}.xml
