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

if [ ! -f $outdir/pubmed-gene-mesh.txt ]; then
    if [ ! -f data/pubmed/data/pubmed/clean_data/pubmed-mesh.txt ]; then
        echo 'ERROR: please generate "pubmed-mesh.txt" file first'
    else
        echo "Generating $outdir/pubmed-gene-mesh.txt"
        join $outdir/pubmed-gene.filtered.txt \
            data/pubmed/data/pubmed/clean_data/pubmed-mesh.txt \
            | tr ' ' '\t' \
            > $outdir/pubmed-gene-mesh.txt
    fi
fi

# output example:
# pmid | txid | gene_id | mesh_id | major_topic (Y/N)
# ---------------------------------------------------
# 100	10090	69192	D000818	N
# 100	10090	69192	D001769	N
# 100	10090	69192	D002239	Y
# 100	10090	69192	D002417	N
# 100	10090	69192	D002418	Y
# 100	10090	69192	D004195	Y
# 100	10090	69192	D006579	N
# 100	10090	69192	D006863	N
# 100	10090	69192	D008214	N
# 100	10090	69192	D008247	Y

# get gene-mesh link for top species
for species in $(cut -f1 data/current/tax_id.top.txt | head -5)
do
    echo "Species: $species"
    mkdir -p $outdir/$species
    cat $outdir/pubmed-gene-mesh.txt \
        | awk -v s=$species '$2==s{print $3,$4}' \
        | sort \
        | uniq -c \
        | awk 'BEGIN{OFS="\t"}{print $2,$3,$1}' \
        > $outdir/$species/gene-mesh.txt

    cat $outdir/pubmed-gene-mesh.txt \
        | awk -v s=$species '$2==s && $5=="Y"{print $3,$4}' \
        | sort \
        | uniq -c \
        | awk 'BEGIN{OFS="\t"}{print $2,$3,$1}' \
        > $outdir/$species/gene-mesh.major.txt
done
