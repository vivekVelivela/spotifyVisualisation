# spotifyVisualisation![SpotifyVisualisationV1Architecture](https://user-images.githubusercontent.com/36952071/188436855-b6591f43-7611-44f2-8425-565fdf41d87c.png)
The above picture is V1 architecture of spotifyVisualisation(https://master.d2h5gxb569cuim.amplifyapp.com/). 
As shown above a cloudwatch event has been setup which triggers lambda once everyday.

The lambda selects a random country among India(IN), Australia(AU), Great Britain(GB) to pull spotify featured playlist from and uses those playlist ID's to pull more information like each track details, playlist followers, artist details of every track




This architecture has its own disadvantages.For example commiting data into github repo is not a standard practice but this is still a v1. Many components of this architecture can be improved. API gateway can be used to fetch and visualise the data in the frontend. A database can be used to store the collected data and query the database to view historic results instead of calling Spotify API everytime.


