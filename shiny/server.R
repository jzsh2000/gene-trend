#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(DT)
library(tidyverse)
library(stringr)

ids = read_rds('robj/id.rds')

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
    get_gene_list <- reactive({
        gene_list = str_split(input$gene, '\\n')[[1]] %>%
            map_chr(str_trim)

        # remove empty stings
        str_subset(gene_list, '.')
    }) %>% debounce(2000)

    get_species <- reactive({
        if (input$species == 'auto') {
            gene_list = get_gene_list()
            if (length(gene_list) == 0) {
                species = 'auto'
            } else {
                match.human = sum(tolower(gene_list) %in%
                                      tolower(ids[['human']]))
                match.mouse = sum(tolower(gene_list) %in%
                                      tolower(ids[['mouse']]))
                species = ifelse(match.human >= match.mouse,
                                 'human', 'mouse')
                print(paste('Use species:', species))
            }
        } else {
            species = input$species
        }
        species
    })

    output$gene_table = renderDataTable({
        gene_list = get_gene_list()
        species = get_species()

        if (length(gene_list) == 0) {
            return(tribble(~name, ~type, ~Symbol,
                           ~description, ~map_location, ~GeneID))
        }

        print(paste('Load RData of', species))
        load(file.path('robj', paste0(species, '.RData')))

        search.res = bind_rows(
            gene_info %>%
                filter(GeneID %in% gene_list) %>%
                mutate(name = as.character(GeneID)) %>%
                select(name, GeneID) %>%
                mutate(type = 'entrez id'),
            symbol2id %>%
                filter(Symbol %in% gene_list) %>%
                rename(name = Symbol) %>%
                mutate(type = 'symbol'),
            synonym2id %>%
                filter(Synonym %in% gene_list) %>%
                rename(name = Synonym) %>%
                mutate(type = 'synonym'),
            # 'ENSG00000000003.14' should be treated as 'ENSG00000000003'
            data_frame(name = gene_list,
                       gene = str_extract(gene_list, '^[^.]*')) %>%
                inner_join(ensembl2id, by = c("gene" = "Ensembl")) %>%
                select(name, GeneID) %>%
                mutate(type = 'ensembl id')
            # data_frame(
            #     name = setdiff(gene_list, ids[[species]])
            # ) %>%
            #     mutate(GeneID = NA_integer_,
            #            type = 'unmatched')
        )

        search.res %>%
            left_join(gene_info, by = c('GeneID' = 'GeneID')) %>%
            arrange(order) %>%
            select(name, type, Symbol, description, map_location, GeneID) %>%
            mutate(Symbol = paste0('<a href="http://www.ncbi.nlm.nih.gov/gene/', GeneID, '" target=_black>', Symbol,'</a>')) %>%
            select(-GeneID)

    }, escape = FALSE)
})
