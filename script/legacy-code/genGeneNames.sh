#!/usr/bin/env bash

txid=${1:-9606}
paste data/$txid/gene/{geneList.txt,geneName.txt} > data/$txid/summary/geneNames.txt
