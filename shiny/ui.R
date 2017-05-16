#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(DT)

# Define UI for application that draws a histogram
shinyUI(fluidPage(

  # Application title
  titlePanel("Gene ID conversion"),

  # Sidebar with a slider input for number of bins
  sidebarLayout(
    sidebarPanel(
        radioButtons(
            inputId = 'species',
            label = 'Species',
            choices = setNames(c('auto', 'human', 'mouse'),
                               c("Auto detect",
                                 "Homo sapiens",
                                 "Mus musculus")),
            selected = "auto"
        ),
        fileInput(
            inputId = 'gene_list_file',
            label = 'Upload gene list',
            accept = 'text/plain'
        ),
        textAreaInput(
            inputId = 'gene',
            label = "Gene List",
            height = '300px'
        )
    ),

    # Show a plot of the generated distribution
    mainPanel(
        verbatimTextOutput('gene_list_summary'),
        tabsetPanel(
            id = 'output_panel',
            type = 'pills',
            tabPanel(
                title = "gene table",
                dataTableOutput("gene_table")
            ),
            tabPanel(
                title = "unmatched",
                verbatimTextOutput('unmatched')
            )
        )
    )
  )
))
