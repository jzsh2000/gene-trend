#!/usr/bin/env bash
set -ue

outdir=$1
if [ ! -d "$outdir" ]; then
    false
fi

> ${outdir}/pmid.info2
pmid=10000
pmid_gap=10000
ne=0
while true
do
    pmid_date=$(efetch -db pubmed -id $pmid -format medline \
        | grep '^EDAT-' \
        | cut -d' ' -f2 \
        | tr '/' '-')
    if [ "${pmid_date}" == "" ]; then
        echo -e "${pmid}\tNA" | tee -a ${outdir}/pmid.info2
        ne=$[${ne}+1]
        if [ $ne -eq 5 ]; then
            break
        fi
    else
        echo -e "${pmid}\t${pmid_date}" | tee -a ${outdir}/pmid.info2
        ne=0
    fi

    pmid=$[${pmid} + ${pmid_gap}]
    sleep 1
done
