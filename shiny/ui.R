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
            choices = c('Homo sapiens' = 'human',
                        'Mus musculus' = 'mouse'),
            selected = "human"
        ),
        selectizeInput(
            inputId = 'orderby',
            label = "Order by",
            choices = c('None' = 'na',
                        'NCBI gene weight' = 'ncbi',
                        'PubMed articles' = 'pubmed',
                        'PubMed articles (immunology)' = 'pubmed_immuno')
        ),
        fileInput(
            inputId = 'gene_list_file',
            label = 'Upload gene list',
            accept = 'text/plain'
        ),
        textAreaInput(
            inputId = 'gene',
            label = "Gene List",
            height = '250px'
        ),
        verbatimTextOutput('gene_list_summary')
    ),

    # Show a plot of the generated distribution
    mainPanel(
        uiOutput('output_panel')
        # tabsetPanel(
        #     id = 'output_panel',
        #     tabPanel(
        #         title = "gene table",
        #         dataTableOutput("gene_table")
        #     ),
        #     tabPanel(
        #         title = "unmatched",
        #         verbatimTextOutput('unmatched')
        #     )
        # )
    )
  )
))
