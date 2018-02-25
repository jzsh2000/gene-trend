.PHONY: usage update
date := $(shell date +%F)
outdir := data/${date}

usage:
	@echo "make <usage | update>"

ifneq ($(wildcard ${outdir}/.),)
update:
	@echo "Already up-to-date."
else
update: download efetch-taxonomy efetch-pubmed generate-robj relink 
endif

download:
	@echo "## current date: ${date}"
	@mkdir -p ${outdir}
	@echo "## download files"
	# wget -P ${outdir} ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/gene_info.gz
	wget -P ${outdir} ftp://ftp.ncbi.nih.gov/gene/DATA/GENE_INFO/Mammalia/Homo_sapiens.gene_info.gz
	wget -P ${outdir} ftp://ftp.ncbi.nih.gov/gene/DATA/GENE_INFO/Mammalia/Mus_musculus.gene_info.gz
	wget -P ${outdir} ftp://ftp.ncbi.nih.gov/gene/DATA/gene2pubmed.gz
	wget -P ${outdir} ftp://ftp.ncbi.nih.gov/gene/GeneRIF/generifs_basic.gz
	wget -P ${outdir} ftp://ftp.ncbi.nih.gov/pub/HomoloGene/current/homologene.data

efetch-gene-order:
	@echo "## fetch NCBI gene order"
	bash ./script/ncbi-gene-order.sh ${outdir}

efetch-gene-summary:
	@echo "## fetch NCBI gene summary"
	bash ./script/download-gene-info-xml.sh ${outdir}
	bash ./script/extract-summary.sh ${outdir}

efetch-taxonomy:
	@echo "## fetch taxonomy information"
	bash ./script/efetch-taxonomy.sh ${outdir}

efetch-pubmed:
	@echo "## fetch pubmed topic information"
	mkdir -p ${outdir}/topic
	parallel -j1 bash ./script/search-pubmed-mesh-heading.sh {} ${outdir}/topic \
	    :::: data/mesh-heading.txt
	parallel -j1 bash ./script/search-pubmed-mesh-subheading.sh {} ${outdir}/topic \
	    :::: data/mesh-subheading.txt

relink:
	@echo "## use new database as default"
	find data -type l -name current -delete
	cd data/; mkdir -p ${date}; ln -s ${date} current

generate-robj:
	bash ./script/split-species.sh ${outdir}
	Rscript ./script/create-gene-rdata.R ${date}

# BE CAREFUL
clean:
	rm -ir ${outdir}
