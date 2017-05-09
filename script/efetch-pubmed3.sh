#!/usr/bin/env bash
set -ue

outdir=$1
if [ ! -d "$outdir" ]; then
    false
fi

> ${outdir}/pmid.info3
pmid=1000
pmid_gap=1000
while true
do
    # echo -e "${pmid}\t${pmid_gap}\t$[${pmid} + ${pmid_gap} * 999]"
    query_ids=$(seq ${pmid} ${pmid_gap} $[${pmid} + ${pmid_gap} * 999] \
        | xargs echo \
        | tr ' ' ',')
    res=$(efetch -db pubmed -id $query_ids -format medline \
        | grep -e '^PMID' -e '^EDAT' \
        | cut -d' ' -f2 \
        | paste - -)

    echo "$res" | tee -a ${outdir}/pmid.info3
    if [ $(echo "$res" | wc -l) -lt 500 ]; then
        break
    fi

    pmid=$[${pmid} + ${pmid_gap} * 1000]
    sleep 1
done
