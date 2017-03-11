.PHONY: usage update
date := $(shell date +%F)
outdir := data/${date}

usage:
	@echo "make <usage | update>"

ifneq ($(wildcard ${outdir}/.),)
update:
	@echo "Already up-to-date."
else
update: download efetch-taxonomy efetch-pubmed
endif

download:
	@echo "## current date: ${date}"
	@mkdir -p ${outdir}
	@echo "## download files"
	wget -P ${outdir} ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/gene_info.gz
	wget -P ${outdir} ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/gene2pubmed.gz
	wget -P ${outdir} ftp://ftp.ncbi.nih.gov/gene/GeneRIF/generifs_basic.gz
	wget -P ${outdir} ftp://ftp.ncbi.nih.gov/pub/HomoloGene/current/homologene.data
	cd data/; rm current; ln -s ${date} current

efetch-taxonomy:
	@echo "## fetch taxonomy information"
	zcat ${outdir}/gene2pubmed.gz | tail -n+2 | cut -f1 | uniq \
	    | parallel -N 1000 echo | tr ' ' ',' \
	    | parallel -j1 efetch -db taxonomy -id {} -format xml \
	    | xtract -pattern TaxaSet/Taxon \
	        -first TaxId -first ScientificName -first Rank \
	        -XXX "(-)" -XXX GenbankCommonName -element "&XXX" \
	        -YYY "(-)" -YYY CommonName -element "&YYY" \
	    > ${outdir}/tax_id.info
	cat ${outdir}/tax_id.info | sort -k1,1n > ${outdir}/tax_id.info.tmp
	mv ${outdir}/tax_id.info.tmp ${outdir}/tax_id.info

efetch-pubmed:
	@echo "## fetch pubmed article information"

clean:
	rm -r ${outdir}
