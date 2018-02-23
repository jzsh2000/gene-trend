#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
suppressMessages(library(shinyjs))
suppressMessages(library(DT))
suppressMessages(library(tidyverse))

version = readLines('robj/VERSION')
mesh_list = read_rds('robj/mesh.rds') %>% pull(mesh_term)
species = read_rds('robj/species.rds')

order_choices = set_names(
    c('na', 'ncbi', 'pubmed', paste('pubmed', mesh_list, sep = '_')),
    c('None', 'NCBI gene weight', 'PubMed articles',
      paste0('PubMed articles (', mesh_list, ')'))
)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
    useShinyjs(),
    tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "style.css")
    ),
    # Application title
    titlePanel(paste0("Gene ID conversion (version: ", version, ")")),

    tabsetPanel(type = "tabs",
        tabPanel('Gene List', {
            # Sidebar with a slider input for number of bins
            sidebarLayout(
                sidebarPanel(
                    width = 3,
                    radioButtons(
                        inputId = 'species',
                        label = 'Species',
                        choices = deframe(species %>%
                                              dplyr::select(full_name,
                                                            short_name))
                    ),
                    selectizeInput(
                        inputId = 'orderby',
                        label = "Order by",
                        choices = order_choices
                    ),
                    selectizeInput(
                        inputId = 'filterby',
                        label = "Filter by",
                        choices = c('None' = 'na',
                                    'Surface Marker' = 'surface',
                                    'CD Molecules' = 'cd')
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
                                                            class = 'blue-box')),
                               br(),
                               actionLink(inputId = 'list3',
                                          label = tags$span('List 3',
                                                            class = 'green-box')))
                    ),
                    tableOutput('gene_list_summary')
                ),

                # Show a plot of the generated distribution
                mainPanel(
                    width = 9,
                    tabsetPanel(
                        id = 'output_panel',
                        tabPanel(
                            title = "gene table",
                            fluidRow(
                                column(width = 8,
                                       dataTableOutput("gene_table"),
                                       hr(),
                                       tags$div(class = 'btn-group',
                                                downloadButton('d_symbol',
                                                               label = 'Download gene symbol'),
                                                downloadButton('d_entrezid',
                                                               label = 'Download gene entrez id'))
                                       ),
                                # column(width = 4)
                                column(width = 4,
                                       tags$div(class = "panel panel-default",
                                                tags$div(class = 'panel-heading',
                                                         id = 'summary_head',
                                                         'Gene Summary'),
                                                tags$div(class = "panel-body",
                                                         # tags$span("hello")
                                                         textOutput('gene_summary')
                                                )
                                       ),
                                       hr(),
                                       uiOutput('pmid'))
                            )
                        ),
                        tabPanel(
                            title = "unmatched",
                            verbatimTextOutput('unmatched')
                        ),
                        tabPanel(
                            title = 'database',
                            dataTableOutput("gene_info_database"),
                            hr(),
                            tags$p('See also:',
                                   tags$ul(
                                       tags$li(
                                           tags$a('https://www.ncbi.nlm.nih.gov/gene', href = 'https://www.ncbi.nlm.nih.gov/gene', target = '_blank')
                                           ),
                                       tags$li(
                                           tags$a('ftp://ftp.ncbi.nih.gov/gene/', href = 'ftp://ftp.ncbi.nih.gov/gene/', target = '_blank'))
                                       )
                            )
                        )
                    )
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
                    ),
                    checkboxInput('hide_unmatched',
                                  label = 'Hide unmatched genes',
                                  value = TRUE)
                ),
                mainPanel(
                    width = 9,
                    DT::dataTableOutput('homologene')
                )
            )
        })
    )
))
