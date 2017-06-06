#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinyjs)
library(DT)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
    useShinyjs(),

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
                            'PubMed articles (immunology)' = 'pubmed_immuno',
                            'PubMed articles (tumour)' = 'pubmed_tumor')
            ),
            hr(),
            fileInput(
                inputId = 'gene_list_file',
                label = 'Upload gene list',
                accept = 'text/plain'
            ),
            fluidRow(
                column(width = 9,
                       textAreaInput(
                           inputId = 'gene',
                           label = "Gene List",
                           height = '200px',
                           placeholder = 'Your awesome gene list'
                       )),
                column(width = 3,
                       actionLink(inputId = 'clear', label = 'clear'),
                       hr(),
                       actionLink(inputId = 'list1', label = 'List 1'),
                       br(),
                       actionLink(inputId = 'list2', label = 'List 2'))
            ),
            tableOutput('gene_list_summary')
        ),

        # Show a plot of the generated distribution
        mainPanel(
            uiOutput('output_panel'),
            hr(),
            fluidRow(
                column(width = 6,
                       textOutput('gene_summary')),
                column(width = 6,
                       uiOutput('pmid'))
            )
        )
    )
))
