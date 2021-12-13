#===========================================
# UI file for the shiny app
#===========================================
# See the code map below
#===========================================
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
#===========================================

# Load required R packages
mypackages = c("shiny", "shinydashboard", "recommenderlab", "data.table", "ShinyRatingInput", "shinyjs", "dplyr", "tidyr")
tmp = setdiff(mypackages, rownames(installed.packages()))  # packages need to be installed
if (length(tmp) > 0) install.packages(tmp)
lapply(mypackages, require, character.only = TRUE)
#install.packages("devtools")
#devtools::install_github("stefanwilhelm/ShinyRatingInput")

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

all_genres = c("Action", "Adventure", "Animation", "Children", 
               "Comedy", "Crime","Documentary", "Drama", "Fantasy", "Film-Noir",
               "Horror", "Musical", "Mystery","Romance", "Sci-Fi", "Thriller", "War", "Western")

shinyUI(
  dashboardPage(skin = "purple",
                dashboardHeader(title = "Movie Recommender"),
                dashboardSidebar(tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "css/books.css")),
                                 sidebarMenu(menuItem("By Genre (System I)", tabName="first"),
                                             menuItem("CF (System II)", tabName = "second")
                  )
                ),
                dashboardBody(tabItems(tabItem(tabName = "first",fluidRow(box(background = "olive",width = 12,title = "Step 1: Select Your Favorite Genre",
                                                                              status = "success", solidHeader = TRUE, div(class = "genres",
                                                                                                                          selectInput("selected_genre", "Select a Genre ", all_genres),
                                  )
                              )
                            ),
                            fluidRow(useShinyjs(),
                                     box(background = "olive",width = 12, status = "success", solidHeader = TRUE,
                                         title = "Step 2: Get Recommmended Movies For Selected Favorite Genre",
                                         br(),
                                         withBusyIndicatorUI(actionButton("btn_genre_movies", "Click to get your recommendations!!", class = "btn-warning")),
                                         h4("Note: Be Patient ... It Takes a While to Load the Data"), 
                                         h4("Algorithm: The movies are recommended if at least 1000 users have rated the movie with ratings of 4 stars or 5 stars in the selected genre."),
                                         br(),
                                         tableOutput("selectedGenreMovies")
                              )
                            )
                    ),
                    
                    tabItem(tabName = "second",fluidRow(box(background = "teal",width = 12, title = "Step 1: Rate as many movies as possible then scroll down to the bottom of the page", status = "primary", solidHeader = TRUE,
                                  div(class = "rateitems",uiOutput('ratings')
                                  ))
                            ),
                            fluidRow(useShinyjs(),box(background = "teal",width = 12, status = "primary", solidHeader = TRUE,
                                                      title = "Step 2: Discover Movies you might like",
                                                      br(),
                                                      withBusyIndicatorUI(actionButton("btn_rated_movies", "Click here to get your recommendations", class = "btn-warning")),
                                                      h4("Note: Be Patient ... It Takes a While to Load the Data"), 
                                                      h4("Algorithm: User-Based Collaborative Filtering "),
                                                      br(),
                                                      tableOutput("results")
                              )
                            )
                    )
                  )
                )
  )
) 