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

tmpfile=$(mktemp)
echo "=== temp file: $tmpfile"

# pubmed_id | txid | gene_id
if [ ! -f $outdir/pubmed-gene.txt ]; then
    echo "Generating $outdir/pubmed-gene.txt"
    zcat data/current/gene2pubmed.gz \
        | tail -n+2 \
        | awk 'BEGIN{OFS="\t"}{print $3,$1,$2}' \
        | sort -k1b,1 \
        > $outdir/pubmed-gene.txt
fi

if [ ! -f $outdir/pubmed-gene.filtered.txt ]; then
    echo "Get valid pubmed id"
    cat $outdir/pubmed-gene.txt \
        | cut -f1 \
        | uniq \
        | comm -23 - $outdir/blacklist.pmid \
        > $tmpfile

    # pubmed id can be mapped to 99 genes at maximal
    echo "Generating $outdir/pubmed-gene.filtered.txt"
    join $tmpfile $outdir/pubmed-gene.txt \
        > $outdir/pubmed-gene.filtered.txt
fi

rm $tmpfile

if [ ! -f data/pubmed/data/pubmed/clean_data/pubmed-mesh.txt ]; then
    echo 'ERROR: please generate "pubmed-mesh.txt" file first'
else
    echo "Generating $outdir/pubmed-gene-mesh.txt"
    join $outdir/pubmed-gene.filtered.txt \
        data/pubmed/data/pubmed/clean_data/pubmed-mesh.txt \
        > $outdir/pubmed-gene-mesh.txt
fi