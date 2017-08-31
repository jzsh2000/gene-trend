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
            checkboxInput('useall', 'Use all', value = FALSE),
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
            textInput('gene_name', label = 'Gene name',
                      placeholder = 'Your awesome gene')
        )
    ),

    # Show a plot of the generated distribution
    mainPanel(
        tabsetPanel(id = 'tabset_main',
                    tabPanel('Total', dataTableOutput('top_gene')),
                    tabPanel('Search', plotlyOutput('gene_plot')))

    )
  )
))
