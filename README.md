# Movie Recommender
### Dataset
This app is using the Movielense Data. The dataset contains about 1 million anonymous ratings of approximately 3,900 movies made by 6,040 MovieLens users who joined MovieLens in 2000.

This is shiny app code for a movie recommender based on 2 systems - Favorite Genre & Collaborative Filtering. 

### Systems I & II
System I - Favorite Genre

By default, the System I View will be displayed when the app is run. You can select a genre from the dropdown and click on the button to get recommendations. The movies that are highly rated i.e. at least 1000 users have rated the movie with ratings of 4 stars or 5 stars in the selected genre are recommended.


System II - Collaborative filtering. 

To navigate to System II, go from the left menu and you will be presented with few movies that you can rate. Once you have rated as many movies you want, click on the button below to get your recommendations.
Here the  User-Based Collaborative filtering algorithm is used.



## How to run the App

Download/clone the above repo and open the ui.R or server.R file in IDE and click on Run App .

The app is hosted on shinyapps.io - https://mehrdadmhmdi.shinyapps.io/project4_movie_recommender/
