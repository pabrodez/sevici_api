I created a simple script in R that uses https://api.citybik.es/v2/ API to retrieve and map current usage of bike stations in Seville.

However I would recommend signing up in https://developer.jcdecaux.com/#/opendata/vls?page=getstarted, get an Api Key and make requests using this url https://api.jcdecaux.com/vls/v1/stations?contract=Seville&apiKey={}
Each request from JCDecaux api take less space than Citybik's and less fuss to extract a data frame. 
