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
library(lubridate)
# library(magrittr)
library(plotly)
load('data/human-mouse.Rdata')
mesh_dat <- read_rds('data/mesh_dat.rds')
# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {

    observeEvent(input$useall_date, {
        if (input$useall_date == FALSE) {
            enable('date')
            enable('previous')
            enable('nextyear')
        } else {
            disable('date')
            disable('previous')
            disable('nextyear')
        }
    })

    observeEvent(input$useall_mesh,  {
        if (input$useall_mesh == FALSE) {
            enable('mesh')
            enable('child_mesh')
            show('mesh_tree')
        } else {
            disable('mesh')
            disable('child_mesh')
            mesh('mesh_tree')
        }
    })

    get_input_value <- reactive({
        list(species = input$species,
             date = input$date,
             mesh = input$mesh,
             gene_num = input$gene_num)
    }) %>% debounce(800)

    get_input_gene <- reactive({
        input$gene_name
    }) %>% debounce(1000)

    get_dat <- reactive({
        if (get_input_value()$species == "human") {
            gene_info = human_gene_info
            gene2pdat = human_gene2pdat
            gene_name = human_gene_name
            gene_mesh = human_gene_mesh
        } else if (get_input_value()$species == 'mouse') {
            gene_info = mouse_gene_info
            gene2pdat = mouse_gene2pdat
            gene_name = mouse_gene_name
            gene_mesh = mouse_gene_mesh
        } else {
            gene_info = data_frame()
            gene2pdat = data_frame()
            gene_name = c('')
            gene_mesh = data_frame()
        }
        candidate_gene = gene2pdat %>%
            group_by(GeneID) %>%
            summarise(count = sum(count)) %>%
            arrange(desc(count)) %>%
            head(100) %>%
            select(GeneID) %>%
            left_join(gene_info, by = 'GeneID') %>%
            pull(Symbol)

        updateSelectizeInput(session, 'gene_name', choices = gene_name)
        return(list(gene_info = gene_info,
                    gene2pdat = gene2pdat,
                    gene_name = gene_name,
                    gene_mesh = gene_mesh,
                    candidate_gene = candidate_gene))
    })

    observeEvent(input$previous, {
        if (input$date[1] > 1991 && input$date[2] > 1991) {
            updateSliderInput(session, inputId = 'date',
                              value = c(input$date[1] - 1, input$date[2] - 1))
        }
    })

    observeEvent(input$nextyear, {
        if (input$date[1] < 2016 && input$date[2] < 2016) {
            updateSliderInput(session, inputId = 'date',
                              value = c(input$date[1] + 1, input$date[2] + 1))
        }
    })

    output$top_gene <- DT::renderDataTable({

        gene_info = get_dat()$gene_info
        mesh_ = get_input_value()$mesh
        # gene2pdat = get_dat()$gene2pdat
        # gene_mesh = get_dat()$gene_mesh

        if (input$useall_mesh || is.null(mesh_)) {
            gene2pdat = get_dat()$gene2pdat
        } else {
            if (input$child_mesh) {
                mesh_ids = mesh_dat %>%
                    filter(mesh_id == mesh_) %>%
                    pull(tree_number) %>%
                    unique()
                # print(mesh_ids)
                mesh_ids_extended = Reduce(union, lapply(mesh_ids, function(id) {
                    str_subset(mesh_dat$tree_number, fixed(id))
                }))
                # print(mesh_ids_extended)
                mesh_ids_extended = mesh_dat %>%
                    filter(tree_number %in% mesh_ids_extended) %>%
                    pull(mesh_id) %>%
                    unique()
                # print(mesh_ids_extended)
                gene2pdat = get_dat()$gene_mesh %>%
                    filter(mesh_id %in% mesh_ids_extended) %>%
                    select(-mesh_id) %>%
                    group_by(GeneID, year) %>%
                    summarise(count = n_distinct(pubmed_id)) %>%
                    ungroup()
            } else {
                gene2pdat = get_dat()$gene_mesh %>%
                    filter(mesh_id == mesh_) %>%
                    select(-mesh_id) %>%
                    group_by(GeneID, year) %>%
                    summarise(count = n_distinct(pubmed_id)) %>%
                    ungroup()
            }
        }

        if (input$useall_date) {
            gene2pdat %>%
                group_by(GeneID) %>%
                summarise(count = sum(count)) %>%
                mutate(rank = min_rank(desc(count))) %>%
                arrange(desc(count)) %>%
                filter(rank <= get_input_value()$gene_num) %>%
                left_join(gene_info, by = 'GeneID') %>%
                select(GeneID, Symbol, Synonyms, description, count) %>%
                dplyr::rename(Description = description, Articles = count) %>%
                mutate(Symbol = paste0('<a href="https://www.ncbi.nlm.nih.gov/gene/',
                                       GeneID, '" target=_blank>',
                                       Symbol,'</a>'),
                       Articles = paste0('<a href="https://www.ncbi.nlm.nih.gov/pubmed?LinkName=gene_pubmed&from_uid=', GeneID, '" target=_blank>', Articles, '</a>')) %>%
                mutate(`Ranking change` = '-')
        } else {
            year_bot = get_input_value()$date[1]
            year_top = get_input_value()$date[2]
            year_span = year_top - year_bot + 1

            dat_now <- gene2pdat %>%
                filter(year >= year_bot, year <= year_top) %>%
                group_by(GeneID) %>%
                summarise(count = sum(count)) %>%
                mutate(rank = min_rank(desc(count))) %>%
                arrange(desc(count)) %>%
                filter(rank <= get_input_value()$gene_num)

            dat_prev = gene2pdat %>%
                filter(year >= year_bot - year_span,
                       year <= year_top - year_span) %>%
                group_by(GeneID) %>%
                summarise(count = sum(count)) %>%
                mutate(rank_prev = min_rank(desc(count))) %>%
                filter(GeneID %in% dat_now$GeneID) %>%
                select(GeneID, rank_prev)

            dat_now %>%
                left_join(gene_info, by = 'GeneID') %>%
                left_join(dat_prev, by = 'GeneID') %>%
                replace_na(list(rank_prev = max(.$rank_prev, na.rm = TRUE) + 1)) %>%
                mutate(rank_diff = rank_prev - rank) %>%
                select(GeneID, Symbol, Synonyms, description, count, rank_diff) %>%
                dplyr::rename(Description = description, Articles = count) %>%
                mutate(Symbol = paste0('<a href="https://www.ncbi.nlm.nih.gov/gene/',
                                       GeneID, '" target=_blank>',
                                       Symbol,'</a>')) %>%
                mutate(`Ranking change` = map_chr(rank_diff, function(x) {
                    if (x > 0) {
                        paste0('<span style="color:green">▲</span>', x)
                    } else if (x < 0) {
                        paste0('<span style="color:red">▼</span>', -x)
                    } else {
                        return('-')
                    }
                })) %>%
                select(-rank_diff)
        }
    },
    escape = FALSE,
    selection = 'single',
    extension = 'Buttons',
    options = list(
        dom = 'Bfrt',
        pageLength = -1,
        buttons = list('copy',
                       list(
                           extend = 'collection',
                           buttons = c('csv', 'excel', 'pdf'),
                           text = 'Download'
                       ),
                       list(extend = 'colvis',
                            columns = c(1,3:6))
                            # columns = c(1,3:ifelse(input$useall_date, 5, 6)))
        ),
        columnDefs = list(list(visible = FALSE, targets = c(3, 5)))
    ))

    output$gene_plot <- renderPlotly({
        gene_name = get_input_gene()
        gene_info = get_dat()$gene_info
        gene2pdat = get_dat()$gene2pdat

        if (gene_name %in% gene_info$Symbol) {
            gene_row_idx = match(gene_name, gene_info$Symbol)
            gene_id = gene_info$GeneID[gene_row_idx]
            gene_description = gene_info$description[gene_row_idx]
            gene_dat = gene2pdat %>%
                group_by(year) %>%
                mutate(rank = min_rank(desc(count))) %>%
                ungroup() %>%
                filter(GeneID == gene_id) %>%
                select(-GeneID) %>%
                complete(year = full_seq(year, 1)) %>%
                replace_na(list(count = 0, rank = 99999)) %>%
                mutate(rank_group = map_chr(rank, function(x) {
                    if (x <= 1) return('top1')
                    else if (x <= 10) return('top10')
                    else if (x <= 100) return('top100')
                    else if (x <= 1000) return('top1000')
                    else return('*')
                })) %>%
                mutate(rank_group = factor(rank_group,
                                           levels = c('top1',
                                                      'top10',
                                                      'top100',
                                                      'top1000',
                                                      '*')))
            ggplotly(ggplot(gene_dat, aes(x = year, y = count, rank = rank)) +
                         geom_point(aes(color = rank_group)) +
                         ylab('Number of articles') +
                         ylim(0, NA) +
                         scale_colour_hue(limits = levels(gene_dat$rank_group)) +
                         ggtitle(paste0(gene_name,
                                        ' (',gene_description, ')')) +
                         theme_bw(),
                     tooltip = c('year', 'count', 'rank'))
        } else {
            return(list())
        }
    })

    observeEvent(input$random_gene, {
        updateSelectizeInput(session,
                             'gene_name',
                             selected = sample(get_dat()$candidate_gene, 1))
    })

    output$mesh_tree <- renderUI({
        mesh_ = get_input_value()$mesh
        mesh_tree_id = mesh_dat %>%
            filter(mesh_id == mesh_) %>%
            pull(tree_number)
        # print(mesh_tree_id)
        output = map_chr(mesh_tree_id, function(id) {
            id_split = str_split(id, '\\.')[[1]]
            paste(map_chr(seq_along(id_split), function(n) {
                id_part = paste(id_split[1:n], collapse = '.')
                # print(id_part)
                mesh_dat %>%
                    filter(tree_number == id_part) %>%
                    pull(mesh_term) %>%
                    head(1)
            }), collapse = ' > ')
        })

        tagList(tags$ul(lapply(output, function(x) {tags$li(x)})),
                tags$hr())
    })
})
