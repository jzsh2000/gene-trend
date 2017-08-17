#!/usr/bin/env bash
set -ueo pipefail
outdir=$1
if [ ! -d "$outdir" ]; then
    false
fi

year=$(basename $outdir | grep -oP '^[0-9]+')
> ${outdir}/pmid.info
for var in `seq 1990 $year`
do
    esearch -db pubmed -query '("'$var'/01/01"[EDAT] : "'$var'/01/31"[EDAT])' \
        | efetch -format uid | datamash min 1 \
        | paste <(echo $var) - \
        >> ${outdir}/pmid.info
done
