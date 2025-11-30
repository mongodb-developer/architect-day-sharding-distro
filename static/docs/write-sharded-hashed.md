# Write (Sharded / Hashed)

## Overview

This operation type performs write (insert) operations on a **sharded** MongoDB collection using a **hashed shard key**. A hashed shard key uses a hash function to distribute documents evenly across all shards, providing automatic load balancing.

## How It Works

When using this operation type:

1. The application generates documents with a field that will be used as a hashed shard key
2. MongoDB applies a hash function to the shard key value
3. The hash value determines which shard receives the document
4. Documents are inserted in batches (configurable via Write Batch Size)
5. The hash function ensures even distribution across all shards

## Document Structure

```json
{
  "_id": ObjectId("..."),
  "dateCreated": ISODate("..."),
  "dateUpdated": ISODate("..."),
  "customerID": 12345,
  "productNumber": 5678,
  "orderNumber": 1000,
  "orderValue": 123.45,
  "orderStatus": "received"
}
```

## Shard Key Strategy

For hashed sharding:
- A single field (or compound fields) is designated as the shard key
- MongoDB applies a hash function to the shard key value
- The hash value maps to a specific shard
- Distribution is automatic and even

## Performance Characteristics

- **Latency**: Consistent across shards due to even distribution
- **Throughput**: High, as writes are automatically distributed across all shards
- **Scalability**: Excellent - performance improves as you add shards
- **Load Balancing**: Automatic and even distribution via hash function
- **Write Conflicts**: Lower chance of conflicts with distributed writes

## Use Cases

- High-volume write workloads requiring even distribution
- Applications where shard key values are not known in advance
- Collections needing automatic load balancing
- Production systems requiring predictable write distribution

## Considerations

- **Range Queries**: Hashed shard keys don't support efficient range queries
- **Query Patterns**: Directed queries require exact shard key matches
- **Chunk Management**: MongoDB automatically balances chunks
- **Shard Key Choice**: Choose a field with high cardinality

## Write Batch Size

The Write Batch Size determines how many documents are inserted in a single `InsertMany` operation:

- **Small batches (1-10)**: Lower latency per operation, more network round trips
- **Medium batches (10-100)**: Balanced performance
- **Large batches (100+)**: Higher throughput, but may hit document size limits

## Best Practices

- **High Cardinality**: Use fields with many unique values for hashed shard keys
- **Avoid Low Cardinality**: Don't use fields with few unique values
- **Monitor Distribution**: Track write distribution to ensure balance
- **Batch Inserts**: Use appropriate batch sizes to optimize throughput
- **Query Considerations**: Design queries to work with hashed shard keys

## Advantages

- **Automatic Distribution**: Hash function ensures even distribution
- **No Hotspots**: Eliminates write hotspots from poor shard key choice
- **Horizontal Scaling**: Write capacity scales with number of shards
- **Predictable Performance**: Consistent write performance across shards

## Limitations

- **Range Queries**: Inefficient for range queries on shard key
- **Directed Queries**: Requires exact shard key match for efficient queries
- **Shard Key Flexibility**: Less flexible than range-based sharding for queries

## Performance Optimization

- Monitor chunk distribution and balance
- Ensure shard key field has high cardinality
- Use appropriate batch sizes
- Monitor write performance per shard
- Consider query patterns when choosing hashed shard key

