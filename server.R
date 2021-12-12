#################################
# Server Function
# Code MAP:
# 1- get_user_ratings
# 2- Read movie data
# 3- Read the ratings data
# 4- Read movie images
# 5- Reshape to movies x user matrix 
# 6- shinyServer (main server function)
#################################
library(shiny)
# load functions
source('cf_algorithm.R') # collaborative filtering
source('similarity_measures.R') # similarity measures

get_user_ratings = function(value_list) {
  dat = data.table(MovieID = sapply(strsplit(names(value_list), "_"),
                                    function(x) ifelse(length(x) > 1, x[[2]], NA)),
                   Rating = unlist(as.character(value_list)))
  dat = dat[!is.null(Rating) & !is.na(MovieID)]
  dat[Rating == " ", Rating := 0]
  dat[, ':=' (MovieID = as.numeric(MovieID), Rating = as.numeric(Rating))]
  dat = dat[Rating > 0]
  dat = na.omit(dat)
  
  # add the user ratings to the existing rating matrix
  user_ratings = sparseMatrix(i = dat$MovieID,
                              j = rep(1,nrow(dat)),
                              x = dat$Rating,
                              dims = c(nrow(ratingmat), 1))
}

# Read movie data
myurl = "https://liangfgithub.github.io/MovieData/"
movies = readLines(paste0(myurl, 'movies.dat?raw=true'))
movies = strsplit(movies, split = "::", fixed = TRUE, useBytes = TRUE)
movies = matrix(unlist(movies), ncol = 3, byrow = TRUE)
movies = data.frame(movies, stringsAsFactors = FALSE)
colnames(movies) = c('MovieID', 'Title', 'Genres')
movies$MovieID = as.integer(movies$MovieID)
movies$Title = iconv(movies$Title, "latin1", "UTF-8")

# Read the ratings data
myurl = "https://liangfgithub.github.io/MovieData/"
ratings = read.csv(paste0(myurl, 'ratings.dat?raw=true'), 
                   sep = ':',
                   colClasses = c('integer', 'NULL'), 
                   header = FALSE)
colnames(ratings) = c('UserID', 'MovieID', 'Rating', 'Timestamp')

# Read movie images
small_image_url = "https://liangfgithub.github.io/MovieImages/"
movies$image_url = sapply(movies$MovieID, 
                          function(x) paste0(small_image_url, x, '.jpg?raw=true'))

# reshape to movies x user matrix 
ratingmat = sparseMatrix(ratings$MovieID, ratings$UserID, x=ratings$Rating) # movie x user matrix
ratingmat = ratingmat[, unique(summary(ratingmat)$j)] # remove users with no ratings
dimnames(ratingmat) = list(MovieID = as.character(1:nrow(ratingmat)), UserID = as.character(sort(unique(ratings$UserID))))

shinyServer(function(input, output, session) {
  
  # Calculate recommendations for System 1 when the submit button is clicked 
  # Based on selected genre by user, we will recommend all movies with a rating >= 4 in the selected genre
  system1 = eventReactive(input$btn_genre_movies, {
    withBusyIndicatorServer("btn_genre_movies", {
      
      
      # Select movies for the selected genre by user
      selectedMoviesByGenre = subset(movies, grepl(input$selected_genre, movies$Genres, fixed = TRUE), select = c(MovieID, Title, image_url ))
      
      selectedMoviesByGenre$MovieID = as.integer(selectedMoviesByGenre$MovieID)
      # Select movies with ratings >= 4
      selectedMoviesByRating = subset(ratings, Rating>=4, select = c(MovieID, Rating))
      system1Result = selectedMoviesByRating %>% inner_join(selectedMoviesByGenre, by= "MovieID")
      rating_summary = system1Result %>% group_by(Rating) %>% summarise(rating_count=n())
      
      final_selected_movies = c()
      if (rating_summary$rating_count[1] > 1000 || rating_summary$rating_count[2] > 1000) {
        final_selected_movies = head(subset(system1Result[sample(nrow(system1Result), 50),], !duplicated(MovieID)), 10)
      }
      
      final_selected_movies
    })
  })
  
  
  output$selectedGenreMovies = renderUI({
    recom_result1 = system1()
    num_movies = 5
    num_rows = 2
    
    lapply(1:num_rows, function(i) {
      list(fluidRow(lapply(1:num_movies, function(j) {
        box(width = 2, status = "success", solidHeader = TRUE, title = paste0("Rank ", (i - 1) * num_movies + j),
            div(style = "text-align:center", img(src = recom_result1$image_url[(i - 1) * num_movies + j], height="60%", width="60%")),
            div(style = "text-align:center; color: #999999; font-size: 80%", 
                paste0( recom_result1$Title[(i - 1) * num_movies + j])
            ),
            div(style="text-align:center; font-size: 100%", 
                strong(paste0( recom_result1$Title[(i - 1) * num_movies + j]))
            )
        )        
      })))
    })
  }) # renderUI function
  
  # show the movies to be rated (System 2 UI)
  output$ratings = renderUI({
    num_rows = 20
    num_movies = 6 # movies per row
    lapply(1:num_rows, function(i) {
      list(fluidRow(lapply(1:num_movies, function(j) {
        list(box(width = 2,
                 div(style = "text-align:center", img(src = movies$image_url[(i - 1) * num_movies + j], height = 150)),
                 div(style = "text-align:center", strong(movies$Title[(i - 1) * num_movies + j])),
                 div(style = "text-align:center; font-size: 150%; color: #f0ad4e;", ratingInput(paste0("select_", movies$MovieID[(i - 1) * num_movies + j]), label = "", dataStop = 5))))
      })))
    })
  })
  
  
  # Calculate recommendations when the sbumbutton is clicked
  system2 = eventReactive(input$btn_rated_movies, {
    withBusyIndicatorServer("btn_rated_movies", { # showing the busy indicator
      # hide the rating container
      useShinyjs()
      jsCode = "document.querySelector('[data-widget=collapse]').click();"
      runjs(jsCode)
      
      # get the user's rating data
      value_list = reactiveValuesToList(input)
      user_ratings = get_user_ratings(value_list)
      
      # add user's ratings as first column to rating matrix
      rmat = cbind(user_ratings, ratingmat)
      
      # get the indices of which cells in the matrix should be predicted
      # predict all movies the current user has not yet rated
      items_to_predict = which(rmat[, 1] == 0)
      prediction_indices = as.matrix(expand.grid(items_to_predict, 1))
      
      # run the ubcf-alogrithm
      res = predict_cf(rmat, prediction_indices, "ubcf", TRUE, cal_cos, 1000, FALSE, 2000, 1000)
      # sort, organize, and return the results
      user_results = sort(res[, 1], decreasing = TRUE)[1:20]
      user_predicted_ids = as.numeric(names(user_results))
      recom_results = data.table(Rank = 1:20,
                                 MovieID = ratings$MovieID[user_predicted_ids], 
                                 Predicted_rating =  user_results)
    }) # still busy
  }) # clicked on button
  
  
  # display the recommendations
  output$results = renderUI({
    num_rows = 2
    num_movies = 5
    recom_result = system2()
    lapply(1:num_rows, function(i) {
      list(fluidRow(lapply(1:num_movies, function(j) {
        box(width = 2, status = "success", solidHeader = TRUE, title = paste0("Rank ", (i - 1) * num_movies + j),
            div(style = "text-align:center", 
                a(img(src = movies$image_url[recom_result$MovieID[(i - 1) * num_movies + j]], height = 150))
            ),
            div(style="text-align:center; font-size: 100%", 
                strong(movies$Title[recom_result$MovieID[(i - 1) * num_movies + j]])
            )
        )        
      }))) # columns
    }) # rows
    
  }) # renderUI function
  
}) # server function