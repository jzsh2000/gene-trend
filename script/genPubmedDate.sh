#!/usr/bin/env bash

[ $# -eq 0 ] && txid=9606 || txid=$1
paste data/$txid/pubmed/{gene.pmid,gene.pmdate} > data/$txid/summary/pubmedDate.txt
