#!/usr/bin/env bash

txid=${1:-9606}
paste data/$txid/pubmed/{gene.pmid,gene.pmdate} > data/$txid/summary/pubmedDate.txt
