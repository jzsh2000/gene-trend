#!/usr/bin/env bash

tmpfile=`mktemp`
echo $tmpfile
cat data/pubmed/data/pubmed/clean_data/author_fl.txt \
    | awk -F'\t' '{printf "%s\t%s %s\n",$1,$2,$4}' \
    | sort -k1b,1 \
    > $tmpfile

cat data/current/Homo_sapiens.gene2pubmed \
    | awk -F'\t' 'BEGIN{OFS="\t"}NR>1{print $3,$2}' \
    | sort -k1b,1 \
    | join -t '\t' $tmpfile - \
    | cut -f2-3 \
    | sort \
    | uniq -c \
    | sed -e 's/^  *//g' -e 's/ /\t/' \
    | awk -F'\t' 'BEGIN{OFS="\t"}{print $3,$2,$1}' \
    | sort -t '\t' -k1n -k2nr \
    > data/current/Homo_sapiens.gene2author

cat data/current/Mus_musculus.gene2pubmed \
    | awk -F'\t' 'BEGIN{OFS="\t"}NR>1{print $3,$2}' \
    | sort -k1b,1 \
    | join -t '\t' $tmpfile - \
    | cut -f2-3 \
    | sort \
    | uniq -c \
    | sed -e 's/^  *//g' -e 's/ /\t/' \
    | awk -F'\t' 'BEGIN{OFS="\t"}{print $3,$2,$1}' \
    | sort -t '\t' -k1n -k2nr \
    > data/current/Mus_musculus.gene2author

rm $tmpfile