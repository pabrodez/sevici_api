I created a simple script in R that uses https://api.citybik.es/v2/ API to retrieve and map current usage of bike stations in Seville.

However I would recommend signing up in https://developer.jcdecaux.com/#/opendata/vls?page=getstarted, get an Api Key and make requests using this url https://api.jcdecaux.com/vls/v1/stations?contract=Seville&apiKey={}

Each JSON file from requests to JCDecaux api take 85kb (aprox.) while Citybik's take 151kb(aprox.). Also, the date-time of the updates are more accurate. 
