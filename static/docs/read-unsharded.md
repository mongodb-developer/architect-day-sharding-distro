# Read (Unsharded)

## Overview

This operation type performs read queries on an **unsharded** MongoDB collection. An unsharded collection exists on a single shard or replica set, meaning all data is stored in one location.

## How It Works

When using this operation type, the application will:

1. Execute read queries against the collection
2. MongoDB will route all queries to the single shard containing the data
3. No shard key routing logic is involved
4. All queries are processed by the same shard

## Query Types

The application performs the following query:

```json
db.orders.find({
	customerID: 47239
	orderStatus: 'shipped'
})
```
In each iteration of the query, customerID and orderStatus are set to random values from the range of avaialble values.


## Performance Characteristics

- **Latency**: Generally consistent as all queries go to the same shard
- **Throughput**: Limited by the capacity of a single shard
- **Scalability**: Cannot scale horizontally beyond the single shard's capacity

## Use Cases

- Small to medium datasets that fit comfortably on a single shard
- Applications that don't require horizontal scaling
- Development and testing environments
- Collections that don't need sharding

## Considerations

- If your data grows beyond a single shard's capacity, you'll need to migrate to a sharded collection
- All read operations are concentrated on one shard, which can become a bottleneck

