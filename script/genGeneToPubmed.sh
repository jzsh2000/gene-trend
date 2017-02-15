#!/usr/bin/env bash

[ $# -eq 0 ] && txid=9606 || txid=$1
grep -r '' data/$txid/pubmed/? \
    | sed -e 's#^.*/##' -e 's#.pmid:# #' \
    | sort -k1n -k2n \
    | tr ' ' '\t' > data/$txid/summary/geneToPubmed.txt
