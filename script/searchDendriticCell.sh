#!/usr/bin/env bash

esearch -db pubmed -query '"dendritic cells"[MeSH Terms]' \
    | efetch -format uid \
    | sort -n > data/pubmed/dc.pmid
