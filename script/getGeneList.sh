#!/usr/bin/env bash

esearch -db gene -query "9606[Taxonomy ID] AND alive[prop]" \
    | efetch -format uid \
    | sort -n > data/geneList.txt
