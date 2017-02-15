#!/usr/bin/env bash

[ $# -eq 0 ] && txid=9606 || txid=$1
cat data/$txid/gene/geneList.txt | parallel -N 1000 echo | tr ' ' ',' \
    | parallel -j1 efetch -db gene -id {} -format native \
    | tee -a data/$txid/geneList.dat \
    | grep -P '^[0-9]+\. ' \
    | cut -d' ' -f2 > data/$txid/gene/geneName.txt

gzip data/$txid/geneList.dat
mv data/$txid/geneList.dat.gz data/$txid/archives/
