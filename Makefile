date := $(shell date +%F)

usage:
	@echo "make <usage | update>"
update:
	@echo "current date: ${date}"
