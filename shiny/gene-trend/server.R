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
load('data/human-mouse.Rdata')

# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {
    get_input_value <- reactive({
        list(species = input$species,
             date = input$date,
             gene_num = input$gene_num)
    }) %>% debounce(800)

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

        if (get_input_value()$species == "human") {
            gene_info = human_gene_info
            gene2pdat = human_gene2pdat
        } else if (get_input_value()$species == 'mouse') {
            gene_info = mouse_gene_info
            gene2pdat = mouse_gene2pdat
        } else {
            gene_info = data_frame()
            gene2pdat = data_frame()
        }
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
            rename(Description = description, Articles = count) %>%
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
                            columns = c(1,3,4,5,6))
        ),
        columnDefs = list(list(visible = FALSE, targets = c(3, 5)))
    ))
})
