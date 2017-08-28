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
    tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "style.css")
    ),
    # Application title
    titlePanel("Gene ID conversion (version: 2017-03-12)"),

    tabsetPanel(
        tabPanel('Gene List', {
            # Sidebar with a slider input for number of bins
            sidebarLayout(
                sidebarPanel(
                    width = 3,
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
                               actionLink(inputId = 'list1',
                                          label = tags$span('List 1',
                                                            class = 'red-box')),
                               br(),
                               actionLink(inputId = 'list2',
                                          label = tags$span('List 2',
                                                            class = 'blue-box')))
                    ),
                    tableOutput('gene_list_summary')
                ),

                # Show a plot of the generated distribution
                mainPanel(
                    width = 9,
                    uiOutput('output_panel')
                )
            )
        }),

        tabPanel('Homologous Gene', {
            sidebarLayout(
                sidebarPanel(
                    width = 3,
                    radioButtons(
                        inputId = 'species_2',
                        label = 'Species',
                        choices = c('Mouse => Human' = 'm2h',
                                    'Human => Mouse' = 'h2m'),
                        selected = "m2h"
                    ),
                    hr(),

                    textAreaInput(
                        inputId = 'gene_2',
                        label = "Gene List",
                        height = '200px',
                        placeholder = 'Your awesome gene list'
                    )
                ),
                mainPanel(
                    width = 9,
                    DT::dataTableOutput('homologene')
                )
            )
        })
    )
))
