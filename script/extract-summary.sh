#!/usr/bin/env bash
set -ue
cd $(dirname $0)/..

outdir=${1:-.}

zcat $outdir/human/*.xml.gz \
    | xtract -pattern Entrezgene -element Gene-track_geneid -element Entrezgene_summary \
    > $outdir/Homo_sapiens.gene_summary

zcat $outdir/mouse/*.xml.gz \
    | xtract -pattern Entrezgene -element Gene-track_geneid -element Entrezgene_summary \
    > $outdir/Mus_musculus.gene_summary
