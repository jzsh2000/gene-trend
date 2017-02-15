#!/usr/bin/env bash

[ $# -eq 0 ] && txid=9606 || txid=$1
mkdir -p data/$txid/{archives,gene,pubmed,summary}

esearch -db gene -query "$txid[Taxonomy ID] AND alive[prop]" \
    | efetch -format uid \
    | sort -n > data/$txid/gene/geneList.txt
