#!/usr/bin/env bash

outdir='data/current/gene-mesh'
mkdir -p $outdir

if [ ! -f $outdir/blacklist.pmid ]; then
    zcat data/current/gene2pubmed.gz \
        | tail -n+2 \
        | cut -f3 \
        | sort \
        | uniq -c \
        | awk '$1>99{print $2}' \
        | sort \
       > $outdir/blacklist.pmid
fi
