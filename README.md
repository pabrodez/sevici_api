I created a simple script in R that uses https://api.citybik.es/v2/ API and https://developer.jcdecaux.com/#/opendata/vls?page=getstarted to retrieve and map current usage of bike stations in Seville.

I recommend to use the later.

However I would recommend signing up in https://developer.jcdecaux.com/#/opendata/vls?page=getstarted, get an Api Key and make requests using this uri https://api.jcdecaux.com/vls/v1/stations?contract=Seville&apiKey={}

Each JSON file from requests to JCDecaux api takes 85kb (aprox.) while Citybik's take 151kb(aprox.). Also, the date-time of the updates in the former are more accurate: it is a timestamp indicating the last change in the station's use, whereas CityBik's timestamp indicates last time they run an update on their systems.  
This can mean that a station has not had any changes on the number of available bikes in hours. JCDecaux timestamp reflects this.
To know when the request was made, I just added a current timestamp column.

Contains material provided by Gerencia de Urbanismo de Sevilla. Ayuntamiento de Sevilla © 2018 (http://sevilla-idesevilla.opendata.arcgis.com/datasets/38827fc3eac142149801c2efa2a0bdf9_0)
