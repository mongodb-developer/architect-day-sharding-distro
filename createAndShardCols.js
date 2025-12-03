use("architect_day")

collections = [
    "orders",
    "orders_ci",
    "orders_dc",
    "orders_dch"
]

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
        adminDB.runCommand({ moveRange: "architect_day." + collection, min: { customerID: MinKey() }, max: { customerID: 33333 }, toShard: "sh2" })
        adminDB.runCommand({ moveRange: "architect_day." + collection, min: { customerID: 33333 }, max: { customerID: 66666 }, toShard: "sh3" })
        adminDB.runCommand({ moveRange: "architect_day." + collection, min: { customerID: 66666 }, max: { customerID: MaxKey() }, toShard: "sh4" })
    }
    if (collection.endsWith("_dc")) {
        adminDB.runCommand({ shardCollection: "architect_day." + collection, key: { dateCreated: 1 } })
        adminDB.runCommand({ moveRange: "architect_day." + collection, min: { dateCreated: MinKey() }, max: { dateCreated: ISODate('2025-11-30T20:23:27.533Z')}, toShard: "sh2" })
        adminDB.runCommand({ moveRange: "architect_day." + collection, min: { dateCreated: ISODate('2025-11-30T20:23:27.533Z')}, max: { dateCreated: ISODate('2025-12-01T20:23:27.533Z')}, toShard: "sh3" })
        adminDB.runCommand({ moveRange: "architect_day." + collection, min: { dateCreated: ISODate('2025-12-01T20:23:27.533Z')}, max: { dateCreated: MaxKey() }, toShard: "sh4" })
    }
    if (collection.endsWith("_dch")) {
        col.createIndex({ dateCreated: "hashed" })
        adminDB.runCommand({ shardCollection: "architect_day." + collection, key: { dateCreated: "hashed" } })
    }
}

