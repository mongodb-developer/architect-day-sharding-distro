mongosh --uri="mongodb+srv://perfUser:nQwvQxHSayyyf6nF@architectdaysharded.azzy6.mongodb.net/architect_day?authSource=admin" --eval "db.dropDatabase()"
mongosh --uri="mongodb+srv://perfUser:nQwvQxHSayyyf6nF@architectdaysharded.azzy6.mongodb.net/architect_day?authSource=admin" --file=createAndShardCols.js
if [ -f "orders.json.gz" ]; then
  gunzip -f orders.json.gz
fi
if [ -f "orders.json" ]; then
  mongoimport --uri="mongodb+srv://perfUser:nQwvQxHSayyyf6nF@architectdaysharded.azzy6.mongodb.net/architect_day?authSource=admin" --collection=orders --file=orders.json
  mongoimport --uri="mongodb+srv://perfUser:nQwvQxHSayyyf6nF@architectdaysharded.azzy6.mongodb.net/architect_day?authSource=admin" --collection=orders_ci --file=orders.json
  mongoimport --uri="mongodb+srv://perfUser:nQwvQxHSayyyf6nF@architectdaysharded.azzy6.mongodb.net/architect_day?authSource=admin" --collection=orders_dc --file=orders.json
  mongoimport --uri="mongodb+srv://perfUser:nQwvQxHSayyyf6nF@architectdaysharded.azzy6.mongodb.net/architect_day?authSource=admin" --collection=orders_dch --file=orders.json
fi