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
  titlePanel("Gene Trend (~> - 2016)"),

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
        tags$hr(),
        sliderInput(
            inputId = 'gene_num',
            label = 'Number of genes',
            min = 10,
            max = 100,
            step = 5,
            value = 20
        )
        # actionButton(
        #     inputId = 'update',
        #     label = "Let's go!",
        #     class = 'btn-primary pull-right'
        # )
    ),

    # Show a plot of the generated distribution
    mainPanel(
        dataTableOutput('top_gene')
    )
  )
))
