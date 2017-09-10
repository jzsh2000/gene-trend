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
library(plotly)
library(tidyverse)

mesh_choices <- read_rds('data/mesh_dat.rds') %>%
    select(mesh_term, mesh_id) %>%
    unique() %>%
    deframe()

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  shinyjs::useShinyjs(),

  # Application title
  titlePanel("Gene Trend (~1991 -> 2016)"),

  # Sidebar with a slider input for number of bins
  sidebarLayout(
    sidebarPanel(
        radioButtons(
            inputId = 'species',
            label = 'Species',
            choices = c('Homo sapiens' = 'human',
                        'Mus musculus' = 'mouse'),
            selected = 'human'
        ),
        conditionalPanel(
            condition = 'input.tabset_main == "Total"',
            sliderInput(
                inputId = 'date',
                label = 'Date range',
                min = 1991,
                max = 2016,
                value = c(2016,2016)
            ),
            fluidRow(
                column(width = 4, actionButton('previous', label = '<--')),
                column(
                    width = 4,
                    actionButton('nextyear', label = '-->',
                                 style = "float:right"),
                    offset = 4
                )
            ),
            checkboxInput('useall_date', 'Use all', value = TRUE),

            tags$hr(),
            selectizeInput('mesh', label = 'MeSH term',
                           choices = mesh_choices, selected = 'D003713'),
            checkboxInput('useall_mesh', 'Use all', value = FALSE),

            tags$hr(),
            sliderInput(
                inputId = 'gene_num',
                label = 'Number of genes',
                min = 5,
                max = 100,
                step = 5,
                value = 10
            )
            # actionButton(
            #     inputId = 'update',
            #     label = "Let's go!",
            #     class = 'btn-primary pull-right'
            # )
        ),
        conditionalPanel(
            condition = 'input.tabset_main == "Search"',
            fluidRow(
                column(width = 9,
                       selectizeInput('gene_name', label = 'Gene name',
                                      choices = 'hello, world')),
                column(width = 3,
                       actionButton('random_gene', label = tags$img(src = 'dice.png')))
            )
        )
    ),

    # Show a plot of the generated distribution
    mainPanel(
        tabsetPanel(id = 'tabset_main',
                    tabPanel('Total',
                             uiOutput('mesh_tree'),
                             dataTableOutput('top_gene')),
                    tabPanel('Search', plotlyOutput('gene_plot')))

    )
  )
))
