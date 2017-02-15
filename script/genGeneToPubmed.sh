#!/usr/bin/env bash

grep -r '' data/pubmed/? \
    | sed -e 's#^.*/##' -e 's#.pmid:# #' \
    | sort -k1n -k2n \
    | tr ' ' '\t' > data/summary/geneToPubmed.txt
