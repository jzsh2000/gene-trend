#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinyjs)
library(DT)
library(tidyverse)
library(stringr)
library(htmltools)

# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {
    rv <- reactiveValues(data = NULL, summary = '', pmid = integer())
    observe({
        req(input$gene_list_file)
        rv$data <- paste(readLines(input$gene_list_file$datapath),
                         collapse = '\n')
    })

    get_gene_list <- reactive({
        gene_list = str_split(input$gene, '\\n')[[1]] %>%
            map_chr(str_trim)

        # remove empty stings
        str_subset(gene_list, '.')
    }) %>% debounce(1000)

    get_species <- reactive({
        species = input$species
        print(paste('Load RData of', species))
        load(file.path('robj', paste0(species, '.RData')))
        return(list(
            species = species,
            gene_info = gene_info,
            symbol2id = symbol2id,
            synonym2id = synonym2id,
            ensembl2id = ensembl2id,
            gene2pubmed = gene2pubmed,
            gene2pubmed.immuno = gene2pubmed.immuno,
            gene2pubmed.tumor = gene2pubmed.tumor
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
            return(list(
                matched = tibble(name = character(),
                                 GeneID = integer(),
                                 type = character()),
                unmatched = character()))
        }
        res.unmatched = gene_list

        res_part.id = gene_info %>%
            filter(GeneID %in% res.unmatched) %>%
            mutate(name = as.character(GeneID)) %>%
            select(name, GeneID) %>%
            mutate(type = 'entrez id')
        res.unmatched = setdiff(res.unmatched, res_part.id$name)

        res_part.symbol = symbol2id %>%
            mutate(Symbol.l = tolower(Symbol)) %>%
            inner_join(
                data_frame(
                    name = res.unmatched,
                    Symbol.l = tolower(name)
                ),
                by = 'Symbol.l'
            ) %>%
            select(name, GeneID) %>%
            mutate(type = 'symbol')
        res.unmatched = setdiff(res.unmatched, res_part.symbol$name)

        res_part.synonym = synonym2id %>%
            mutate(Synonym.l = tolower(Synonym)) %>%
            inner_join(
                data_frame(
                    name = res.unmatched,
                    Synonym.l = tolower(name)
                ),
                by = 'Synonym.l'
            ) %>%
            select(name, GeneID) %>%
            mutate(type = 'synonym')
        res.unmatched = setdiff(res.unmatched, res_part.synonym$name)

            # 'ENSG00000000003.14' should be treated as 'ENSG00000000003'
        res_part.ensembl = data_frame(name = res.unmatched,
                                      gene = str_extract(name,
                                                         '^[^.]*')) %>%
            inner_join(ensembl2id, by = c("gene" = "Ensembl")) %>%
            select(name, GeneID) %>%
            mutate(type = 'ensembl id')
        res.unmatched = setdiff(res.unmatched, res_part.ensembl$name)

        list(matched = bind_rows(res_part.id,
                                 res_part.symbol,
                                 res_part.synonym,
                                 res_part.ensembl),
             unmatched = res.unmatched)
    })

    get_unmatched <- reactive({
        gene_list = get_gene_list()
        gene_list.unmatched = get_search_result()[['unmatched']]
        gene_list[gene_list %in% gene_list.unmatched]
    })

    get_ordered_table <- reactive({
        gene_list = get_gene_list()
        gene_info = get_species()[['gene_info']]
        search.res = get_search_result()[['matched']] %>%
            left_join(gene_info, by = c('GeneID' = 'GeneID')) %>%
            mutate(Symbol =
                       paste0('<a ',
                              'href="http://www.ncbi.nlm.nih.gov/gene/',
                              GeneID, '" ',
                              'target=_black ',
                              '>', Symbol,'</a>'))

        if (input$orderby == 'na') {
            search.res = search.res %>%
                inner_join(data_frame(
                    name = gene_list,
                    original_order = seq_along(gene_list)
                ), by = 'name') %>%
                arrange(original_order)
        } else if (input$orderby == 'ncbi') {
            search.res = search.res %>%
                arrange(order)
        } else if (input$orderby == 'pubmed') {
            search.res = search.res %>%
                arrange(pm_rank) %>%
                mutate(pubmed = paste0(pm_rank, ' (', pm_count, ')'))
        } else if (input$orderby == 'pubmed_immuno') {
            search.res = search.res %>%
                arrange(pm_rank_immuno) %>%
                mutate(pubmed = paste0(pm_rank_immuno,
                                       ' (', pm_count_immuno, ')'))
        } else if (input$orderby == 'pubmed_tumor') {
            search.res = search.res %>%
                arrange(pm_rank_tumor) %>%
                mutate(pubmed = paste0(pm_rank_tumor,
                                       ' (', pm_count_tumor, ')'))
        }
        rv$summary = ''
        rv$pmid = integer()
        search.res %>%
            select(-c(dbXrefs, chromosome,
                      Symbol_from_nomenclature_authority,
                      Full_name_from_nomenclature_authority,
                      Other_designations,
                      starts_with('pm_')))
    })

    get_selected_geneid <- reactive({
        if (!is.null(input$gene_table_row_last_clicked)) {
            row.idx = input$gene_table_row_last_clicked
            get_ordered_table()[['GeneID']][row.idx]
        } else {
            return(NULL)
        }
    })

    output$gene_table = DT::renderDataTable({
        get_ordered_table() %>%
            select(-GeneID)
    },
    rownames = FALSE,
    server = FALSE,
    escape = FALSE,
    selection = 'single',
    extension = 'Buttons',
    options = list(
        lengthMenu = list(c(10, 25, 50, 100, -1),
                          c('10', '25', '50', '100', 'ALL')),
        dom = 'Bfrtip',
        buttons =
            list('copy',
                 list(
                     extend = 'collection',
                     buttons = c('csv', 'excel', 'pdf'),
                     text = 'Download'
                 ),
                 list(extend = 'colvis',
                      columns = c(0,1,3,4,5,6,7,8))
            ),
        columnDefs = list(list(visible = FALSE,
                               targets = c(0,1,5,6,8)))
    ))

    output$unmatched <- renderText({
        paste(get_unmatched(), collapse = '\n')
    })

    output$gene_list_summary <- renderTable({
        inFile <- input$gene_list_file
        gene_list = get_gene_list()
        if (is.null(inFile)) {
            if (length(gene_list) == 0) {
                return(data_frame('current time' = as.character(Sys.time())))
            } else {
                search.res = get_search_result()[['matched']]
                return(data_frame(name = gene_list) %>%
                           left_join(search.res, by = "name") %>%
                           count(type))
            }
        } else {
            print(inFile$datapath)
            updateTextAreaInput(session, 'gene', value = rv$data)
            search.res = get_search_result()[['matched']]
            return(data_frame(name = gene_list) %>%
                       left_join(search.res, by = "name") %>%
                       count(type))
        }
    })

    output$gene_info_database <- DT::renderDataTable({
        gene_info = get_species()[['gene_info']] %>%
            mutate(Symbol =
                       paste0('<a ',
                              'href="http://www.ncbi.nlm.nih.gov/gene/',
                              GeneID, '" ',
                              'target=_black ',
                              '>', Symbol,'</a>'))

        if (input$orderby == 'ncbi') {
            gene_info = gene_info %>%
                arrange(order)
        } else if (input$orderby == 'pubmed') {
            gene_info = gene_info %>%
                arrange(pm_rank) %>%
                mutate(pubmed = paste0(pm_rank, ' (', pm_count, ')'))
        } else if (input$orderby == 'pubmed_immuno') {
            gene_info = gene_info %>%
                arrange(pm_rank_immuno) %>%
                mutate(pubmed = paste0(pm_rank_immuno,
                                       ' (', pm_count_immuno, ')'))
        } else if (input$orderby == 'pubmed_tumor') {
            gene_info = gene_info %>%
                arrange(pm_rank_tumor) %>%
                mutate(pubmed = paste0(pm_rank_tumor,
                                       ' (', pm_count_tumor, ')'))
        }
        gene_info %>%
            select(Symbol, Synonyms, description)
    },
    escape = FALSE,
    rownames = FALSE,
    selection = 'single'
    )

    output$output_panel <- renderUI({
        if (length(get_unmatched()) == 0) {
            tabsetPanel(
                id = 'output_panel',
                tabPanel(
                    title = "gene table",
                    dataTableOutput("gene_table")
                ),
                tabPanel(
                    title = 'database',
                    dataTableOutput("gene_info_database")
                )
            )
        } else {
            tabsetPanel(
                id = 'output_panel',
                tabPanel(
                    title = "gene table",
                    dataTableOutput("gene_table")
                ),
                tabPanel(
                    title = "unmatched",
                    verbatimTextOutput('unmatched')
                ),
                tabPanel(
                    title = 'database',
                    dataTableOutput("gene_info_database")
                )
            )
        }
    })

    output$gene_summary <- renderUI(
        tags$div(class = "panel panel-default",
                 tags$div(class = 'panel-heading', 'Gene Summary'),
                 tags$div(class = "panel-body", rv$summary))
    )

    output$pmid <- renderUI({
        get_pmid_link <- function(pmid_list) {
            tags$ul(lapply(pmid_list, function(id) {
                tags$li(tags$a(
                    as.character(id),
                    target = '_blank',
                    href = paste('https://www.ncbi.nlm.nih.gov/pubmed',
                                 as.character(id), sep = '/')))
            }))
        }
        if (length(rv$pmid) > 20) {
            tags$div(class = "panel panel-default",
                     tags$div(class = 'panel-heading', 'Citations in PubMed'),
                     tags$div(class = "panel-body",
                              tagList(
                                  tags$a('See all citations in PubMed',
                                         href = paste0('https://www.ncbi.nlm.nih.gov/pubmed?LinkName=gene_pubmed&from_uid=',
                                                       get_selected_geneid())),
                                  get_pmid_link(sort(rv$pmid, decreasing = TRUE)[1:20])
                              )))

        } else {
            tags$div(class = "panel panel-default",
                     tags$div(class = 'panel-heading', 'Citations in PubMed'),
                     tags$div(class = "panel-body",
                                  get_pmid_link(sort(rv$pmid, decreasing = TRUE))
                              ))
        }

    })

    observeEvent(input$clear, {
        rv$data <- NULL
        reset("gene_list_file")
        updateTextAreaInput(session, 'gene', value = '')
    })

    observeEvent(input$list1, {
        rv$data <- NULL
        reset("gene_list_file")
        updateTextAreaInput(session, 'gene',
                            value = paste(readLines('example/1.txt'),
                                          collapse = '\n'))
    })

    observeEvent(input$list2, {
        rv$data <- NULL
        reset("gene_list_file")
        updateTextAreaInput(session, 'gene',
                            value = paste(readLines('example/2.txt'),
                                          collapse = '\n'))
    })

    # update gene summary text when a gene is selected
    observe(
        if (!is.null(input$gene_table_row_last_clicked)) {
            row.idx = input$gene_table_row_last_clicked
            rv$summary = get_ordered_table()$Summary[row.idx]

            gene_id = get_selected_geneid()
            if (input$orderby == 'pubmed_immuno') {
                gene2pubmed.immuno = get_species()[['gene2pubmed.immuno']]
                rv$pmid = unname(
                    unlist((gene2pubmed.immuno %>%
                                filter(GeneID == gene_id))[['PubMed_ID']]))
            } else if (input$orderby == 'pubmed_tumor') {
                gene2pubmed.tumor = get_species()[['gene2pubmed.tumor']]
                rv$pmid = unname(
                    unlist((gene2pubmed.tumor %>%
                                filter(GeneID == gene_id))[['PubMed_ID']]))
            } else {
                gene2pubmed = get_species()[['gene2pubmed']]
                rv$pmid = unname(
                    unlist((gene2pubmed %>%
                                filter(GeneID == gene_id))[['PubMed_ID']]))
            }
        }
    )
})
