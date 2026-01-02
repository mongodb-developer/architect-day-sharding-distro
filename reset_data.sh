#!/bin/bash

# Reset the data in the database
export mongo_uri="mongodb+srv://perfUser:nQwvQxHSayyyf6nF@architectdaysharded.azzy6.mongodb.net/architect_day?authSource=admin"
mongosh --uri=$mongo_uri --eval "db.dropDatabase()"
mongosh --uri=$mongo_uri --file=createAndShardCols.js

# Import the data into the database
if [ -f "orders.json.gz" ]; then
  gunzip -f orders.json.gz
fi
if [ -f "orders.json" ]; then
  mongoimport --uri=$mongo_uri --collection=orders --file=orders.json
  mongoimport --uri=$mongo_uri --collection=orders_ci --file=orders.json
  mongoimport --uri=$mongo_uri --collection=orders_dc --file=orders.json
  mongoimport --uri=$mongo_uri --collection=orders_dch --file=orders.json
fi