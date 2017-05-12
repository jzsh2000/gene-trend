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
        str_subset(gene_list, '.')
    }) %>% debounce(2000)

    output$gene_table = renderDataTable({
        gene_list = get_gene_list()
        if (length(gene_list) == 0) {
            return(as_data_frame(iris))
        }

        if (input$species == 'auto') {
            match.human = sum(tolower(gene_list) %in%
                                  tolower(ids[['human']]))
            match.mouse = sum(tolower(gene_list) %in%
                                  tolower(ids[['mouse']]))
            species = ifelse(match.human >= match.mouse,
                             'human', 'mouse')
            print(paste('Use species:', species))
        } else {
            species = input$species
        }

        load(file.path('robj',
                       paste0(species, '.RData')))

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
            ensembl2id %>%
                filter(Ensembl %in% gene_list) %>%
                rename(name = Ensembl) %>%
                mutate(type = 'ensembl id'),
            data_frame(
                name = setdiff(gene_list, ids[[species]])
            ) %>%
                mutate(GeneID = NA_integer_,
                       type = 'unmatched')
        )

        search.res %>%
            left_join(gene_info, by = c('GeneID' = 'GeneID')) %>%
            arrange(order) %>%
            select(name, type, Symbol, description, map_location, GeneID) %>%
            mutate(Symbol = paste0('<a href="http://www.ncbi.nlm.nih.gov/gene/', GeneID, '" target=_black>', Symbol,'</a>')) %>%
            select(-GeneID)

    }, escape = FALSE)
})
