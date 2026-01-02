use("architect_day")

collections = [
    "orders",
    "orders_ci",
    "orders_dc",
    "orders_dch"
]

const shardNames = db.getSiblingDB("config")
  .shards
  .distinct("_id");

for (const collection of collections) {
    db.createCollection(collection)
    col = db.getCollection(collection)
    col.createIndex({ customerID: 1, orderStatus: 1 })
    col.createIndex({ productNumber: 1, dateCreated: 1 })
    col.createIndex({ dateCreated: 1 })
    col.createIndex({ orderStatus: 1 })
    col.createIndex({ orderNumber: 1 })

    adminDB  = db.getSiblingDB("admin")
    if (collection.endsWith("_ci")) {
        adminDB.runCommand({ shardCollection: "architect_day." + collection, key: { customerID: 1 } })
        adminDB.runCommand({ moveRange: "architect_day." + collection, min: { customerID: MinKey() }, max: { customerID: 33333 }, toShard: shardNames[0] })
        adminDB.runCommand({ moveRange: "architect_day." + collection, min: { customerID: 33333 }, max: { customerID: 66666 }, toShard: shardNames[1] })
        adminDB.runCommand({ moveRange: "architect_day." + collection, min: { customerID: 66666 }, max: { customerID: MaxKey() }, toShard: shardNames[2] })
    }
    if (collection.endsWith("_dc")) {
        adminDB.runCommand({ shardCollection: "architect_day." + collection, key: { dateCreated: 1 } })
        adminDB.runCommand({ moveRange: "architect_day." + collection, min: { dateCreated: MinKey() }, max: { dateCreated: ISODate('2025-12-31T20:53:57.657Z')}, toShard: shardNames[0] })
        adminDB.runCommand({ moveRange: "architect_day." + collection, min: { dateCreated: ISODate('2025-12-31T20:53:57.657Z')}, max: { dateCreated: ISODate('2026-01-01T20:53:57.657Z')}, toShard: shardNames[1] })
        adminDB.runCommand({ moveRange: "architect_day." + collection, min: { dateCreated: ISODate('2026-01-01T20:53:57.657Z')}, max: { dateCreated: MaxKey() }, toShard: shardNames[2] })
    }
    if (collection.endsWith("_dch")) {
        col.createIndex({ dateCreated: "hashed" })
        adminDB.runCommand({ shardCollection: "architect_day." + collection, key: { dateCreated: "hashed" } })
    }
}

