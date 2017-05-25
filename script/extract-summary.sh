#!/usr/bin/env bash
set -ue
cd $(dirname $0)/..

outdir='data/current'

cat $outdir/human/?.xml $outdir/human/??.xml \
    | xtract -pattern Entrezgene -element Gene-track_geneid -element Entrezgene_summary \
    > $outdir/Homo_sapiens.gene_summary

cat $outdir/mouse/?.xml $outdir/mouse/??.xml \
    | xtract -pattern Entrezgene -element Gene-track_geneid -element Entrezgene_summary \
    > $outdir/Mus_musculus.gene_summary
