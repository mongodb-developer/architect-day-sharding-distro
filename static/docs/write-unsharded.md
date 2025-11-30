# Write (Unsharded)

## Overview

This operation type performs write (insert) operations on an **unsharded** MongoDB collection. New documents are inserted into a collection that exists on a single shard or replica set.

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

2. Documents are inserted in batches (configurable via Write Batch Size)
3. All writes are processed by the single shard containing the collection

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

## Performance Characteristics

- **Latency**: Consistent as all writes go to the same shard
- **Throughput**: Limited by the capacity of a single shard
- **Write Conflicts**: Lower chance of conflicts since all writes go to one location
- **Scalability**: Cannot scale horizontally beyond the single shard's capacity
- **Batch Performance**: Batch inserts improve throughput compared to single inserts

## Use Cases

- Small to medium datasets that fit on a single shard
- Applications with moderate write volumes
- Development and testing environments
- Collections that don't require sharding for writes
- Applications where write performance is acceptable on a single shard

## Considerations

- **Single Point of Load**: All write operations are concentrated on one shard
- **Write Capacity**: Limited by the single shard's write capacity
- **No Horizontal Scaling**: Cannot distribute write load across multiple shards
- **Order Number Generation**: Monotonically increasing order numbers can create hotspots
- **Migration Complexity**: Migrating to sharded collection requires careful planning

## Write Batch Size

The Write Batch Size determines how many documents are inserted in a single `InsertMany` operation:

- **Small batches (1-10)**: Lower latency per operation, more network round trips
- **Medium batches (10-100)**: Balanced performance
- **Large batches (100+)**: Higher throughput, but may hit document size limits

## Best Practices

- **Batch Inserts**: Use appropriate batch sizes to optimize throughput
- **Index Management**: Ensure proper indexes exist for query performance
- **Write Concern**: Use appropriate write concern for data durability
- **Monitor Performance**: Track write performance and shard capacity
- **Consider Sharding**: Plan for sharding if write volume will exceed single shard capacity

## Performance Optimization

- Use batch inserts to reduce network round trips
- Monitor write queue depth and latency
- Ensure adequate write capacity on the shard
- Consider write concern settings for durability vs. performance trade-offs

