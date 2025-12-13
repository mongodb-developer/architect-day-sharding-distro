# Write (Sharded / Equal Distribution)

## Overview

This operation type performs write (insert) operations on a **sharded** MongoDB collection using a strategy that aims for **equal distribution** of writes across all shards. This is achieved by using a shard key that distributes documents evenly.

## How It Works

When using this operation type:

1. The application generates documents with the following structure:
   - `dateCreated`: Current timestamp
   - `dateUpdated`: Current timestamp
   - `customerID`: Random integer between 1 and 100,000
   - `productNumber`: Random integer between 1 and 10,000
   - `orderNumber`: Monotonically increasing integer starting at 1000
   - `orderValue`: Random monetary value with two decimal places
   - `orderStatus`: "received"
2. The `customerID` field is used as the shard key.
3. Documents are inserted in batches (configurable via Write Batch Size)
4. MongoDB's query router (mongos) uses the shard key to route writes to shards
5. With randomly assinged customeriD values, writes are distributed evenly across all shards

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

For equal distribution, the shard key should:
- Have high cardinality (many unique values)
- Have good distribution of values
- Avoid hotspots (concentrated writes to specific shards)


## Performance Characteristics

- **Latency**: Consistent across shards when distribution is even
- **Throughput**: High, as writes are distributed across all shards
- **Scalability**: Excellent - performance improves as you add shards
- **Load Balancing**: Writes are evenly distributed across shards

## Use Cases

- High-volume write workloads
- Applications requiring horizontal write scaling
- Collections with high write throughput requirements
- Production systems needing distributed write capacity

## Considerations

- **Shard Key Design**: Critical for achieving equal distribution
- **Hotspots**: Poor shard key choice can create write hotspots
- **Chunk Management**: MongoDB automatically balances chunks
- **Monitoring**: Monitor shard write distribution to ensure balance

## Write Batch Size

The Write Batch Size determines how many documents are inserted in a single `InsertMany` operation:

- **Small batches (1-10)**: Lower latency per operation, more network round trips
- **Medium batches (10-100)**: Balanced performance
- **Large batches (100+)**: Higher throughput, but may hit document size limits

## Best Practices

- **Shard Key Selection**: Choose shard keys with high cardinality and good distribution
- **Avoid Monotonic Keys**: Don't use monotonically increasing values as shard keys
- **Hash Shard Keys**: Consider hashed shard keys for automatic distribution
- **Monitor Distribution**: Track write distribution across shards
- **Batch Inserts**: Use appropriate batch sizes to optimize throughput

## Advantages

- **Horizontal Scaling**: Write capacity scales with number of shards
- **Load Distribution**: Writes are spread across all shards
- **Better Performance**: Higher overall write throughput
- **No Single Bottleneck**: No single shard becomes a write bottleneck

## Performance Optimization

- Monitor chunk distribution and balance
- Ensure shard key provides good write distribution
- Use appropriate batch sizes
- Monitor write performance per shard
- Adjust shard key if hotspots develop

