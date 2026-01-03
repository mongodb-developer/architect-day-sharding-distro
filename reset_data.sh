#!/bin/bash

# Reset the data in the database
export MONGO_URI=""
mongosh $MONGO_URI --eval "db.dropDatabase()"
mongosh $MONGO_URI --file=createAndShardCols.js

# Import the data into the database
if [ -f "orders.json.gz" ]; then
  gunzip -f orders.json.gz
fi
if [ -f "orders.json" ]; then
  mongoimport --uri=$MONGO_URI --collection=orders --file=orders.json
  mongoimport --uri=$MONGO_URI --collection=orders_ci --file=orders.json
  mongoimport --uri=$MONGO_URI --collection=orders_dc --file=orders.json
  mongoimport --uri=$MONGO_URI --collection=orders_dch --file=orders.json
fi