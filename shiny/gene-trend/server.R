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
shinyServer(function(input, output) {
    get_input_value <- reactive({
        list(species = input$species,
             date = input$date,
             gene_num = input$gene_num)
    }) %>% debounce(1500)

    output$top_gene <- renderDataTable({

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
        gene2pdat %>%
            filter(year >= year_bot, year <= year_top) %>%
            group_by(GeneID) %>%
            summarise(count = sum(count)) %>%
            arrange(desc(count)) %>%
            top_n(get_input_value()$gene_num) %>%
            left_join(gene_info, by = 'GeneID') %>%
            select(GeneID, Symbol, Synonyms, description, count)
    })
})
