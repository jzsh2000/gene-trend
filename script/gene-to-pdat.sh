#!/usr/bin/env bash

# output format:
# txid | gene_id | date (%Y-%m) | count

# output example:
# 1000373	11569613	2012-02	1
# 1000373	11604940	2012-02	1
# 1000373	11604942	2012-02	1
# 1000373	11604944	2012-02	1
# 1001283	26220056	2015-10	1
# 1001283	26220057	2015-10	1
# 1001283	26220061	2015-10	1
# 1001283	26220063	2015-10	1
# 1001283	26220067	2015-10	1
# 1001283	26220070	2015-10	1

# Filter out data of human TP53 gene
# cat data/current/gene-pdat.txt | awk '$1=="9606" && $2=="7157"'

zcat data/current/gene2pubmed.gz \
    | awk -F'\t' 'BEGIN{OFS="\t"}NR>1{print $3,$1,$2}' \
    | sort -k1b,1 \
    | join - data/pubmed/data/pubmed/clean_data/pubmed-pdat.txt \
    | tr ' ' '\t' \
    | cut -f2-4 \
    | awk -F'\t' 'BEGIN{OFS="\t"}
        {
            split($3,d,"-");
            printf "%s\t%s\t%s-%s\n",$1,$2,d[1],d[2]
        }' \
    | sort \
    | uniq -c \
    | awk 'BEGIN{OFS="\t"}{print $2,$3,$4,$1}' \
    > data/current/gene-pdat.txt
