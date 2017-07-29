#!/usr/bin/env bash

# number of associated genes in each pubmed article
# output format:
#	pmid	number_of_genes
mkdir -p data/current/genes-per-article
zcat data/current/gene2pubmed.gz \
    | awk '$1=="9606"' \
    | cut -f3 \
    | sort \
    | uniq -c \
    | sort -k1,1nr \
    | awk 'BEGIN{OFS="\t"}{print $2,$1}' \
    > data/current/genes-per-article/human.txt

zcat data/current/gene2pubmed.gz \
    | awk '$1=="10090"' \
    | cut -f3 \
    | sort \
    | uniq -c \
    | sort -k1,1nr \
    | awk 'BEGIN{OFS="\t"}{print $2,$1}' \
    > data/current/genes-per-article/mouse.txt
