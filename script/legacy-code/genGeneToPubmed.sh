#!/usr/bin/env bash

txid=${1:-9606}
grep -r '' data/$txid/pubmed/? \
    | sed -e 's#^.*/##' -e 's#.pmid:# #' \
    | sort -k1n -k2n \
    | tr ' ' '\t' > data/$txid/summary/geneToPubmed.txt
