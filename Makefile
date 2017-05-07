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
	bash ./script/efetch-taxonomy.sh ${outdir}

efetch-pubmed:
	@echo "## fetch pubmed article information"
	bash ./script/efetch-pubmed.sh ${outdir}

clean:
	rm -ir ${outdir}
