#!/usr/bin/env bash
set -ueo pipefail

query_string="$1"
output_file=$(echo "$query_string" | tr ' ' '-').txt
esearch -db pubmed -query "${query_string}[MeSH Subheading]" \
    | efetch -format uid \
    > $output_file
