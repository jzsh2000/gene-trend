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
shinyServer(function(input, output, session) {
    get_gene_list <- reactive({
        gene_list = str_split(input$gene, '\\n')[[1]] %>%
            map_chr(str_trim)

        # remove empty stings
        str_subset(gene_list, '.')
    }) %>% debounce(2000)

    get_species <- reactive({
        species = input$species
        print(paste('Load RData of', species))
        load(file.path('robj', paste0(species, '.RData')))
        return(list(
            species = species,
            gene_info = gene_info,
            symbol2id = symbol2id,
            synonym2id = synonym2id,
            ensembl2id = ensembl2id
            ))
    })

    get_search_result <- reactive({
        # three columns:
        # name | GeneID | type
        gene_list = get_gene_list()
        species = get_species()[['species']]
        gene_info = get_species()[['gene_info']]
        symbol2id = get_species()[['symbol2id']]
        synonym2id = get_species()[['synonym2id']]
        ensembl2id = get_species()[['ensembl2id']]

        if (length(gene_list) == 0) {
            return(tibble(name = character(),
                          GeneID = integer(),
                          type = character()))
        }

        bind_rows(
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
    })

    output$gene_table = renderDataTable({
        search.res = get_search_result()
        gene_info = get_species()[['gene_info']]
        search.res %>%
            left_join(gene_info, by = c('GeneID' = 'GeneID')) %>%
            arrange(order) %>%
            select(name, type, Symbol, description, map_location, GeneID) %>%
            mutate(Symbol = paste0('<a href="http://www.ncbi.nlm.nih.gov/gene/', GeneID, '" target=_black>', Symbol,'</a>')) %>%
            select(-GeneID)

    },
    server = FALSE,
    escape = FALSE,
    extension = 'Buttons',
    options = list(
        lengthMenu = list(c(10, 25, 50, 100, -1),
                          c('10', '25', '50', '100', 'ALL')),
        dom = 'Bfrtip',
        buttons =
            list('copy', list(
                extend = 'collection',
                buttons = c('csv', 'excel', 'pdf'),
                text = 'Download'
            ))
    ))

    output$unmatched <- renderText({
        gene_list = get_gene_list()
        search.res = get_search_result()
        setdiff(gene_list, search.res$name)
    })

    output$gene_list_summary <- renderPrint({
        inFile <- input$gene_list_file
        gene_list = get_gene_list()
        if (is.null(inFile)) {
            if (length(gene_list) == 0) {
                return(as.character(Sys.time()))
            } else {
                search.res = get_search_result()
                return(data_frame(name = gene_list) %>%
                           left_join(search.res, by = "name") %>%
                           count(type))
            }
        } else {
            updateTextAreaInput(session, 'gene',
                                value = paste(readLines(inFile$datapath),
                                              collapse = '\n'))
            search.res = get_search_result()
            return(data_frame(name = gene_list) %>%
                       left_join(search.res, by = "name") %>%
                       count(type))
        }
    })
})
