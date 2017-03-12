#!/usr/bin/env bash
set -ueo pipefail
outdir=$1
if [ ! -d "$outdir" ]; then
    false
fi

zcat ${outdir}/gene2pubmed.gz | tail -n+2 | cut -f1 | uniq \
    | parallel -N 1000 echo | tr ' ' ',' \
    | parallel -j1 efetch -db taxonomy -id {} -format xml \
    | xtract -pattern TaxaSet/Taxon \
        -first TaxId -first ScientificName -first Rank \
        -XXX "(-)" -XXX GenbankCommonName -element "&XXX" \
        -YYY "(-)" -YYY CommonName -element "&YYY" \
    > ${outdir}/tax_id.info

cat ${outdir}/tax_id.info | sort -k1,1n > ${outdir}/tax_id.info.tmp
mv ${outdir}/tax_id.info.tmp ${outdir}/tax_id.info
