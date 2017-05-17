#!/usr/bin/env bash
set -uexo pipefail

query_string="$1"
output_file=$(echo "$query_string" | tr ' ' '-').txt
esearch -db pubmed -query "${query_string}[mesh]" \
    | efetch -format uid \
    > $output_file
