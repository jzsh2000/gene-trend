#!/usr/bin/env bash

zcat data/current/gene2pubmed.gz \
    | tail -n+2 \
    | cut -f1 \
    | sort \
    | uniq -c \
    | sort -k1,1nr \
    | awk 'BEGIN{OFS="\t"}{print $2,$1}' \
    > data/current/tax_id.top.txt
