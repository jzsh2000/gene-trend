#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
suppressMessages(library(shinyjs))
suppressMessages(library(DT))
suppressMessages(library(tidyverse))
library(htmltools)
suppressMessages(library(glue))

species_df = read_rds('robj/species.rds')
homologene <- read_rds('robj/human-mouse-homologene.rds')
surface_marker <- read_rds('gene-list/surface-marker.rds')
cd_molecules <- read_rds('gene-list/cd.rds')

for (species in species_df$short_name) {
    load(glue('robj/{species}.RData'))
    suffix = species_df$suffix[species_df$short_name == species]
    assign(glue('all2id.{suffix}'),
           bind_rows(
               get(glue('symbol2id.{suffix}')) %>% rename(label = Symbol),
               get(glue('synonym2id.{suffix}')) %>% rename(label = Synonym),
               get(glue('ensembl2id.{suffix}')) %>% rename(label = Ensembl),
               data_frame(
                   label = as.character(get(glue('gene_info.{suffix}'))$GeneID),
                   GeneID = get(glue('gene_info.{suffix}'))$GeneID
               )
           ),
           envir = globalenv())
}

alias_to_id <- function(gene_list, species = 'human') {
    suffix = species_df$suffix[species_df$short_name == species]
    if (!exists(glue('gene_info.{species}'))) {
        load(glue('robj/{species}.RData'))
    }

    data_frame(label = gene_list) %>%
        unique() %>%
        left_join(get(glue('all2id.{suffix}')), by = 'label') %>%
        mutate(GeneID = as.character(GeneID))
}

# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {
    rv <- reactiveValues(data = NULL,
                         summary = '',
                         pmid = integer())
    observe({
        req(input$gene_list_file)
        rv$data <- paste(readLines(input$gene_list_file$datapath),
                         collapse = '\n')
    })

    observeEvent(input$species, {
        if (input$species == 'human') {
            enable('filterby')
        } else {
            disable('filterby')
        }
    })

    get_gene_list <- reactive({
        gene_list = str_split(input$gene, '[,\\s]+')[[1]] %>%
            map_chr(str_trim)

        # remove empty stings
        str_subset(gene_list, '.')
    }) %>% debounce(1000)

    get_gene_list_2 <- reactive({
        gene_list = str_split(input$gene_2, '[,\\s]+')[[1]] %>%
            map_chr(str_trim)

        # remove empty stings
        str_subset(gene_list, '.')
    }) %>% debounce(1000)

    get_species <- reactive({
        species = input$species
        appendix = 'h'
        if (species == 'mouse') {
            appendix = 'm'
        }
        # glue('Load RData of {species}')

        return(list(
            species = species,
            gene_info = get(glue('gene_info.{appendix}')),
            symbol2id = get(glue('symbol2id.{appendix}')),
            synonym2id = get(glue('synonym2id.{appendix}')),
            ensembl2id = get(glue('ensembl2id.{appendix}')),
            gene2pubmed = get(glue('gene2pubmed.{appendix}'))
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
            disable('d_symbol')
            disable('d_entrezid')
            hideTab(inputId = 'output_panel', target = 'unmatched')
            return(list(
                matched = tibble(name = character(),
                                 GeneID = integer(),
                                 type = character()),
                unmatched = character()))
        }
        # enable('d_symbol')
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
        # print(length(res.unmatched))
        if (length(res.unmatched) > 0) {
            showTab(inputId = 'output_panel', target = 'unmatched')
        } else {
            hideTab(inputId = 'output_panel', target = 'unmatched')
        }

        res.matched = bind_rows(res_part.id,
                                res_part.symbol,
                                res_part.synonym,
                                res_part.ensembl)

        if (nrow(res.matched) > 0) {
            enable('d_symbol')
            enable('d_entrezid')
        }

        if (input$filterby != 'na') {
            if (input$filterby == 'surface') {
                res.matched = res.matched %>%
                    semi_join(surface_marker, by = 'GeneID')
            } else if (input$filterby == 'cd') {
                res.matched = res.matched %>%
                    semi_join(cd_molecules, by = 'GeneID')
            }
        }
        list(matched = res.matched,
             unmatched = res.unmatched)
    })

    get_unmatched <- reactive({
        gene_list = get_gene_list()
        gene_list.unmatched = get_search_result()[['unmatched']]
        gene_list[gene_list %in% gene_list.unmatched]
    })

    get_matched_df <- reactive({
        gene_list = get_gene_list()
        gene_info = get_species()[['gene_info']]
        get_search_result()[['matched']] %>%
            left_join(gene_info, by = c('GeneID' = 'GeneID'))
    })

    get_matched_df_full <- reactive({
        gene_list = get_gene_list()
        search.res = get_matched_df() %>%
            mutate(Symbol.origin = Symbol,
                   Symbol =
                       glue('<a href="http://www.ncbi.nlm.nih.gov/gene/{GeneID}"
                            target=_black>{Symbol}</a>'))

        if (input$orderby == 'na') {
            search.res = search.res %>%
                inner_join(data_frame(
                    name = gene_list,
                    original_order = seq_along(gene_list)
                ), by = 'name') %>%
                arrange(original_order)
        } else if (input$orderby == 'ncbi') {
            search.res = search.res %>%
                mutate(ncbi_order = order) %>%
                arrange(ncbi_order)
        } else if (input$orderby == 'pubmed') {
            search.res = search.res %>%
                arrange(pm_rank) %>%
                mutate(pubmed = glue('{pm_rank} ({pm_count})'))
        } else {
            mesh_term = str_extract(input$orderby, '(?<=pubmed_).*')
            search.res = search.res %>%
                arrange_(glue('pm_rank_{mesh_term}')) %>%
                mutate(pubmed = paste0(.[[glue('pm_rank_{mesh_term}')]], ' (',
                                       .[[glue('pm_count_{mesh_term}')]], ')'))
        }

        rv$summary = ''
        rv$pmid = integer()

        search.res
    })

    get_ordered_table <- reactive({

        get_matched_df_full() %>%
            select(-c(dbXrefs, chromosome,
                      Symbol_from_nomenclature_authority,
                      Full_name_from_nomenclature_authority,
                      Other_designations, order,
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
        DT::datatable(get_ordered_table() %>% select(-c(GeneID, name)),
                  rownames = get_ordered_table()$name,
                  escape = FALSE,
                  selection = 'single',
                  extension = 'Buttons',
                  options = list(
                      dom = 'Bfrtip',
                      buttons =
                          list('copy',
                               list(
                                   extend = 'collection',
                                   buttons = c('csv', 'excel', 'pdf'),
                                   text = 'Download'
                               ),
                               list(extend = 'colvis',
                                    columns = c(1,3:9))
                          ),
                      columnDefs = list(list(visible = FALSE,
                                             targets = c(1,3:4,6:8))),
                      scrollX = TRUE)
        )
    },
    # rownames = FALSE,
    server = FALSE
    )

    output$unmatched <- renderText({
        paste(get_unmatched(), collapse = '\n')
    })

    output$gene_list_summary <- renderTable({
        inFile <- input$gene_list_file
        gene_list = get_gene_list()
        if (is.null(inFile)) {
            if (length(gene_list) == 0) {
                # return(data_frame('current time' = as.character(Sys.time())))
                return(NULL)
            } else {
                search.res = get_search_result()[['matched']]
                return(data_frame(name = gene_list) %>%
                           left_join(search.res, by = "name") %>%
                           count(type) %>%
                           replace_na(list(type = '-'))
                       )
            }
        } else {
            print(inFile$datapath)
            updateTextAreaInput(session, 'gene', value = rv$data)
            search.res = get_search_result()[['matched']]
            return(data_frame(name = gene_list) %>%
                       left_join(search.res, by = "name") %>%
                       count(type) %>%
                       replace_na(list(type = '-'))
                   )
        }
    })

    output$gene_info_database <- DT::renderDataTable({
        gene_info = get_species()[['gene_info']] %>%
            mutate(Symbol =
                       glue('<a href="http://www.ncbi.nlm.nih.gov/gene/{GeneID}"
                            target=_black>{Symbol}</a>'))

        if (input$orderby == 'ncbi') {
            gene_info = gene_info %>%
                arrange(order)
        } else if (input$orderby == 'pubmed') {
            gene_info = gene_info %>%
                arrange(pm_rank)
        } else if (str_detect(input$orderby, '^pubmed_')) {
            mesh_term = str_extract(input$orderby, '(?<=pubmed_).*')
            gene_info = gene_info %>%
                arrange_(glue('pm_rank_{mesh_term}'))
        }

        gene_info %>%
            select(Symbol, Synonyms, description, type_of_gene) %>%
            mutate(type_of_gene = as.factor(type_of_gene))
    },
    filter = 'top',
    escape = c(-2),
    rownames = TRUE,
    selection = 'none'
    )

    output$gene_summary <- renderText(
        ifelse(rv$summary == '',
               '-',
               rv$summary)
    )

    output$pmid <- renderUI({
        if (length(rv$pmid) == 0) {
            tags$p(
                # class = "container",
                tags$span('no citations', class = "none")
            )
        }
        else if (length(rv$pmid) < 100) {
            tags$p(
                # class = "container",
                tags$a(glue('See {length(rv$pmid)} citations in PubMed'),
                       href = paste0('https://www.ncbi.nlm.nih.gov/pubmed/',
                                    paste(rv$pmid, collapse = ','))
                       )
            )
        } else {
            selected_id = sort(rv$pmid, decreasing = TRUE)[1:20]
            tags$p(
                # class = "container",
                tags$a(paste('See over 100 citations in PubMed'),
                       href = paste0('https://www.ncbi.nlm.nih.gov/pubmed/',
                                     paste(selected_id, collapse = ','))
                       )
            )
        }

    })

    output$pmid_panel <- renderUI({
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
                     tags$div(class = "panel-body fixed-panel",
                              tagList(
                                  tags$a('See all citations in PubMed',
                                         href = glue('https://www.ncbi.nlm.nih.gov/pubmed?LinkName=gene_pubmed&from_uid={get_selected_geneid()}')),
                                  get_pmid_link(sort(rv$pmid, decreasing = TRUE)[1:20])
                              )))

        } else {
            tags$div(class = "panel panel-default",
                     tags$div(class = 'panel-heading', 'Citations in PubMed'),
                     tags$div(class = "panel-body fixed-panel",
                                  get_pmid_link(sort(rv$pmid, decreasing = TRUE))
                              ))
        }

    })

    output$d_symbol <- downloadHandler(
        filename = 'gene_name.txt',
        content = function(con) {
            writeLines(get_matched_df_full()$Symbol.origin %>%
                           unique(),
                       con)
        }
    )

    output$d_entrezid <- downloadHandler(
        filename = 'gene_id.txt',
        content = function(con) {
            writeLines(get_matched_df_full()$GeneID %>%
                           as.character() %>%
                           unique(),
                       con)
        }
    )

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

    observeEvent(input$list3, {
        rv$data <- NULL
        reset("gene_list_file")
        updateTextAreaInput(session, 'gene',
                            value = paste(readLines('example/3.txt'),
                                          collapse = '\n'))
    })

    # update gene summary text when a gene is selected
    observe(
        if (!is.null(input$gene_table_row_last_clicked)) {
            row.idx = input$gene_table_row_last_clicked
            rv$summary = get_ordered_table()$Summary[row.idx]
            shinyjs::html('summary_head',
                          paste0('Gene Summary (',
                                 get_ordered_table()$Symbol[row.idx],
                                 ')'),
                          add = FALSE)

            gene_id = get_selected_geneid()
            gene2pubmed = get_species()[['gene2pubmed']]
            if (str_detect(input$orderby, '^pubmed_')) {
                mesh_term = str_extract(input$orderby, '(?<=pubmed_).*')
                rv$pmid = unname(
                    unlist((gene2pubmed %>%
                                filter(GeneID == gene_id))[[glue('pm_id_{mesh_term}')]]))
            } else {
                rv$pmid = unname(
                    unlist((gene2pubmed %>%
                                filter(GeneID == gene_id))[['pm_id']]))
            }
        }
    )

    output$homologene <- DT::renderDataTable({
        gene_list = get_gene_list_2()
        # print(gene_list)

        if (length(gene_list) == 0) {
            tribble(~human_gene_name, ~mouse_gene_name)
        } else {
            rv$data <- NULL
            reset("gene_list_file")
            updateTextAreaInput(session, 'gene', value = '')

            if (input$species_2 == 'h2m') {
                updateRadioButtons(session, 'species', selected = 'human')

                gene_list_df = alias_to_id(gene_list, 'human')
                out_df = gene_list_df %>%
                    left_join(homologene, by = c('GeneID' = 'human_gene_id')) %>%
                    select(label, human_gene_name, mouse_gene_name) %>%
                    replace_na(list(
                        human_gene_name = '',
                        mouse_gene_name = ''
                        )) %>%
                    as.data.frame() %>%
                    column_to_rownames('label')
            } else {
                updateRadioButtons(session, 'species', selected = 'mouse')

                gene_list_df = alias_to_id(gene_list, 'mouse')
                out_df = gene_list_df %>%
                    left_join(homologene, by = c('GeneID' = 'mouse_gene_id')) %>%
                    select(label, mouse_gene_name, human_gene_name) %>%
                    replace_na(list(
                        mouse_gene_name = '',
                        human_gene_name = ''
                        )) %>%
                    as.data.frame() %>%
                    column_to_rownames('label')
            }
            if (input$hide_unmatched) {
                subset(out_df, human_gene_name != '' & mouse_gene_name != '')
            } else {
                out_df
            }
        }
    },
    server = FALSE,
    extension = 'Buttons',
    options = list(
        lengthMenu = list(c(10, 25, 50, 100, -1),
                          c('10', '25', '50', '100', 'ALL')),
        dom = 'Bfrtip',
        buttons = list('copy',
                       list(
                           extend = 'collection',
                           buttons = c('csv', 'excel', 'pdf'),
                           text = 'Download'
                       )))
    )
})
