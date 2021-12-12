#################################
# UI file for the shiny app
#################################
# See the code map below
#################################
## Code MAP: 
#
## UI file has 4 elements for dashboard page
# 0 - Packages
# 1- skin = "red", dashboardHeader(title = "Movie Recommender")
#
# 2- Sidebar:
#           2.1 - menuItem("Recommender by Genre (System I)" ...
#           2.2 - menuItem("Collaborative Recommender (System II)" ...
#
# 3- Body:
#           3.1 - Tab Item 1:  tabName = "first"
#                             3.1.1 -  "Step 1: Select Your Favorite Genre" .... 
#                             3.1.2 -  "Step 2: Get Recommmended Movies For Selected Favorite Genre" .... 
#                             3.1.3 -  "Step 3: actionButton("btn_genre_movies", "Click to get your recommendations!!" .... 
#                             3.1.4 -  "Step 4: tableOutput("selectedGenreMovies")
#
#           3.2 - Tab Item 2: tabName = "second"
#                             3.2.1 -  "Step 1: Rate as many movies as possible" .... 
#                             3.2.2 -  "Step 2: Discover Movies you might like" .... 
#                             3.2.3 -  "Step 3: "Click here to get your recommendations" .... 
#                             3.2.4 -  "Step 4: tableOutput("results")
#
#################################
#Packages
devtools::install_github("stefanwilhelm/ShinyRatingInput")
mypackages = c("shiny","devtools", "shinydashboard", "recommenderlab", "data.table", "ShinyRatingInput", "shinyjs", "dplyr", "tidyr")
tmp = setdiff(mypackages, rownames(installed.packages()))  # packages need to be installed
if (length(tmp) > 0) install.packages(tmp)
lapply(mypackages, require, character.only = TRUE)

## ui.R
library(shiny)
library(shinydashboard)
library(recommenderlab)
library(data.table)
library(ShinyRatingInput)
library(shinyjs)
library(dplyr)
library(tidyr)

source('helpers.R')
#################################
dashboardPage(skin = "red", dashboardHeader(title = "Movie Recommender"),
              dashboardSidebar(tags$head(tags$link(rel = "stylesheet")),
                               sidebarMenu(menuItem("Recommender by Genre (System I)", tabName="first"),
                                           menuItem("Collaborative Recommender (System II)", tabName = "second"))),
              dashboardBody(tabItems(tabItem(tabName = "first",
                                             fluidRow(box(width = 12,title = "Step 1: Select Your Favorite Genre", 
                                                                             status = "info", solidHeader = TRUE, collapsible = TRUE,
                                                                             div(class = "genres",selectInput("select", h3("Select Your Favorite Genre"), 
                                                                                                             choices = list("Action"=1, "Animation" = 2, "Adventure" = 3,
                                                                                                                            "Comedy" = 4, "Drama"=5,"Thriller"=6, "Crime"=7,
                                                                                                                            "Romance"= 8,"Children's"= 9,"Documentary"= 10,
                                                                                                                            "Sci-Fi"= 11,"Horror"= 12,"Western"= 13,"Mystery"= 14,
                                                                                                                            "Film-Noir"= 15,"War"= 16,"Fantasy"= 17,"Musical"= 18)
                                                                                                             , selected = 1),))),
                                             fluidRow(useShinyjs(),box( width = 12, status = "info", solidHeader = TRUE,title = "Step 2: Get Recommmended Movies For Selected Favorite Genre",
                                                                        br(),
                                                                        withBusyIndicatorUI(actionButton("btn_genre_movies", "Click to get your recommendations!!", class = "btn-warning")),
                                                                        br(),
                                                                        tableOutput("selectedGenreMovies")))),
                                     tabItem(tabName = "second",fluidRow(box(width = 12, title = "Step 1: Rate as many movies as possible", status = "info", solidHeader = TRUE, collapsible = TRUE,
                                                                             div(class = "rateitems",uiOutput('ratings')))),
                                             fluidRow(useShinyjs(),box(width = 12, status = "info", solidHeader = TRUE,title = "Step 2: Discover Movies you might like",
                                                                       br(),
                                                                       withBusyIndicatorUI(actionButton("btn_rated_movies", "Click here to get your recommendations", class = "btn-warning")),
                                                                       h4("Note: User-based collaborative filtering algorithm is used to recommend the movies."),
                                                                       br(),
                                                                       tableOutput("results")))))))

