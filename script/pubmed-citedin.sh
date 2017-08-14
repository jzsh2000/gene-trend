#!/usr/bin/env bash
set -ueo pipefail

pmid=$1
elink -db pubmed -id $pmid -target pubmed -name pubmed_pubmed_citedin \
    | efetch -format uid
