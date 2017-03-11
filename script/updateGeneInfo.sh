#!/usr/bin/env bash
set -ue

cd $(dirname $0)/..
outdir="data/`date +%F`"

if [ -d "$outdir" ]; then
    echo "Already up-to-date."
    exit 0
else
    mkdir -p $outdir
fi

wget -P $outdir ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/gene_info.gz
wget -P $outdir ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/gene2pubmed.gz
wget -P $outdir ftp://ftp.ncbi.nih.gov/gene/GeneRIF/generifs_basic.gz
wget -P $outdir ftp://ftp.ncbi.nih.gov/pub/HomoloGene/current/homologene.data

zcat $outdir/gene2pubmed.gz | tail -n+2 | cut -f1 | uniq \
    | parallel -N 1000 echo | tr ' ' ',' \
    | parallel -j1 efetch -db taxonomy -id {} \
    | xtract -pattern TaxaSet/Taxon \
        -first TaxId -first ScientificName -first Rank \
        -XXX "(-)" -XXX GenbankCommonName -element "&XXX" \
        -YYY "(-)" -YYY CommonName -element "&YYY"
    > $outdir/tax_id.info
chmod -w $outdir/{tax_id.*,*.gz,*.data}

cd data
ln -s $current_date current
