## CD-molecules.R
find CD molecules according to gene official names and synonyms, no output

## collectPmid.sh
merge pubmed ID files to one file (not used anymore)

## download-gene-info-xml.sh
download NCBI gene xml for human and mouse (not used anymore)
it would be better to download gene asn.1 format and convert it to xml

e.g.
```bash
wget ftp://ftp.ncbi.nlm.nih.gov/toolbox/ncbi_tools/cmdline/gene2xml.Linux-2.6.32-696.1.1.el6.x86_64-x86_64.gz
gunzip gene2xml.Linux-2.6.32-696.1.1.el6.x86_64-x86_64.gz
chmod +x gene2xml.Linux-2.6.32-696.1.1.el6.x86_64-x86_64
mv gene2xml.Linux-2.6.32-696.1.1.el6.x86_64-x86_64 gene2xml
wget ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/ASN_BINARY/Mammalia/Homo_sapiens.ags.gz
./gene2xml -i Homo_sapiens.ags.gz -c T -o Homo_sapiens.xml
```

## efetch-pubmed.sh
## efetch-pubmed2.sh
## efetch-pubmed3.sh
## efetch-taxonomy.sh
## extract-summary.sh
## genGeneNames.sh
## genGeneToPubmed.sh
## genPubmedDate.sh
## genRDS.R
## gene-author.sh
## gene-families-human.R
## gene-name-conversion.R
## gene-to-pdat.sh
## genes-per-article.sh
## get-gene-mesh-matrix.R
## get-gene-mesh-matrix.sh
## get-top-species.sh
## getArticleInfo.sh
## getGeneInfo.sh
## getGeneList.sh
## linkGeneToPubmed.sh
## mesh-id-to-root.sh
## ncbi-gene-order.sh
## pubmed-citedin.sh
## search-pubmed-mesh-subheading.sh
## search-pubmed-mesh.sh
## searchDendriticCell.sh
## split-gene-info.sh
