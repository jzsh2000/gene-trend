#!/usr/bin/env bash

txid=${1:-9606}
find data/$txid/pubmed/?/*.pmid -exec cat {} + \
    | sort -nu > data/$txid/pubmed/gene.pmid
