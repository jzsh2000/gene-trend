#!/usr/bin/env bash

[ $# -eq 0 ] && txid=9606 || txid=$1
paste data/$txid/gene/{geneList.txt,geneName.txt} > data/$txid/summary/geneNames.txt
