#!/usr/bin/env bash

cat data/gene/geneList.txt | parallel -N 1000 echo | tr ' ' ',' \
    | parallel -j1 efetch -db gene -id {} -format native \
    | tee -a data/geneList.dat \
    | grep -P '^[0-9]+\. ' \
    | cut -d' ' -f2 > data/gene/geneName.txt

gzip data/geneList.dat
mv data/geneList.dat.gz data/archives/
