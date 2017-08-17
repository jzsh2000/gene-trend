#!/usr/bin/env bash

txid=${1:-9606}
mkdir -p data/$txid/{archives,gene,pubmed,summary}

esearch -db gene -query "$txid[Taxonomy ID] AND alive[prop]" \
    | efetch -format uid \
    | sort -n > data/$txid/gene/geneList.txt
