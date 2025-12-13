# Read Range (Sharded / Directed)

## Overview

This operation type performs **range queries** on a **sharded** MongoDB collection using **directed** queries. Directed range queries include the shard key in the range filter, allowing MongoDB to route queries directly to the specific shard(s) containing the data within that range.

## How It Works

When using this operation type:

1. The application executes range queries **with** the shard key included in the range filter
2. MongoDB's query router (mongos) uses the shard key range to determine which shard(s) contain the data
3. The query is sent **only** to the relevant shard(s) that contain data within the range
4. Results are returned directly from the targeted shard(s) without querying other shards
5. Range queries on shard keys are highly efficient when the range aligns with chunk boundaries

## Query Types

The application performs the following range query against a collection sharded by the dateCreated field:

```json
db.orders_dc.find({
	"dateCreated": {
			$gte: ISODate(<startDate>),
			$lt:  ISODate(<endDate>)
		}
}).limit(100)
```

In each iteration, `<startDate>` is set to a randomly selected value within the range of `dateCreated` values in the dataset. `<endDate>` is set to be one hour later than `<startDate>`. Since `dateCreated` is the shard key in the target collection, MongoDB can route this query directly to the appropriate shard(s).

## Performance Characteristics

- **Latency**: Lower than undirected range queries because only relevant shards are queried
- **Throughput**: High, as queries are targeted to specific shards
- **Resource Usage**: Only relevant shards process queries
- **Scalability**: Excellent - performance improves as you add shards
- **Index Efficiency**: Indexes on shard keys work effectively for range queries

## Use Cases

- Range queries where the shard key value range is known
- Time-series queries on shard keys (e.g., date ranges)
- High-performance range read operations
- Applications with predictable range query patterns
- Production workloads requiring optimal range query performance

## Considerations

- **Shard Key Required**: Range queries must include the shard key in the filter
- **Query Patterns**: Application must be designed to include shard key in range queries
- **Chunk Boundaries**: Range queries that span multiple chunks may query multiple shards
- **Index Design**: Indexes on shard key and other queried fields improve performance

## Best Practices

- Design shard keys that match common range query patterns
- Always include shard key in range query filters when possible
- Monitor query performance to ensure shard key effectiveness
- Design ranges to align with chunk boundaries when possible

## Advantages

- **Targeted Routing**: Queries go directly to the right shard(s)
- **Reduced Network Traffic**: No broadcasting to all shards
- **Better Scalability**: Performance improves as you add shards
- **Efficient Index Usage**: Indexes work effectively on targeted shards

## Limitations

- **Shard Key Dependency**: Requires shard key in range filter
- **Multi-Shard Ranges**: Ranges spanning multiple chunks query multiple shards
- **Query Design**: Application must be designed around shard key ranges


