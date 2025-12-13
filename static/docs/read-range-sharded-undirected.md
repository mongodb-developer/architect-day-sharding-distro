# Read Range (Sharded / Undirected)

## Overview

This operation type performs **range queries** on a **hash-sharded** MongoDB collection resulting in **undirected** queries. The hash function results in documents with different shard key values bening randomly distributed across the available shards rather than in contiguous ranges of shard key values. Undirected range queries require MongoDB to broadcast the query to all shards and then merge the results.

## How It Works

When using this operation type:

1. The application executes range queries against the hash sharded collection
2. MongoDB's query router (mongos) cannot determine which shard(s) contain the data range.
3. The query is **broadcast** to all shards in the cluster
4. Each shard processes the query and returns matching documents
5. MongoDB merges the results from all shards and returns them to the client
6. This is also known as a "scatter-gather" query pattern

## Query Types

The application performs the following range query against a collection sharded by the customerID field, but without including customerID in the filter:

```json
db.orders_dc.find({
	"dateCreated": {
			$gte: ISODate(<startDate>),
			$lt:  ISODate(<endDate>)
		}
}).limit(100)
```

In each iteration, `<startDate>` is set to a randomly selected value within the range of `dateCreated` values in the dataset. `<endDate>` is set to be one hour later than `<startDate>`. Because the hash function randomly distributed `dateCreated` values across the available shards, MongoDB cannot determine which values are on which shard and must direct the query all shards.

## Performance Characteristics

- **Latency**: Higher than directed queries because all shards must be queried
- **Throughput**: Lower than directed queries due to scatter-gather overhead
- **Resource Usage**: All shards process every query
- **Network Traffic**: Higher network traffic due to broadcasting
- **Scalability**: Improves as shards are added (each shard has less data to query), but gains not as great as directed querying.

## Use Cases

- Range queries where the shard key is a monotonically increasing value

## Considerations

- **Performance Impact**: Undirected range queries caused by hashed-sharding are less efficient than directed queries
- **Shard Key Design**: Cannot leverage shard key for routing
- **Index Usage**: Ensure a secondary, un-hashed index exists on the field being range-queried.
- **Result Merging**: MongoDB must merge results from multiple shards

## Best Practices

- **Avoid When Possible**: Hashed shard keys should be avoided if range queries are regularly needed.
- **Index Design**: Create secondary (unhashed) indexes on fields used in range queries


