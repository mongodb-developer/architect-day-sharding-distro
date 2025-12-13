# Write (Sharded / Monotonically Increasing)

## Overview

This operation type performs write (insert) operations on a **sharded** MongoDB collection using a **monotonically increasing** shard key. A monotonically increasing shard key uses values that always increase (or decrease) sequentially, such as timestamps, auto-incrementing IDs, or sequential order numbers.

## How It Works

When using this operation type:

1. The application generates documents with a monotonically increasing shard key value (dateCreated)
2. MongoDB uses the shard key to route writes to shards
3. Since values are sequential, writes will target the shard allocated the highest shard key values.
4. This creates a "hotspot" where all writes go to one shard
5. Documents are inserted in batches (configurable via Write Batch Size)

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

For this operation type, the `dateCreated` field is used as the shard key, and it increases monotonically with each insert.

## Shard Key Strategy

With monotonically increasing shard keys:
- Values always increase (or decrease) in sequence
- Examples: timestamps, auto-increment IDs, sequential order numbers
- Writes tend to target the same shard (the "hot" shard)
- Creates write hotspots and uneven distribution

## Performance Characteristics

- **Latency**: May be inconsistent due to hotspot on one shard
- **Throughput**: Limited by the capacity of the "hot" shard
- **Scalability**: Poor - does not scale well as you add shards
- **Load Balancing**: Poor - writes concentrate on one or few shards
- **Write Conflicts**: Higher chance of conflicts on the hot shard

## Use Cases

- **Time-Series Data**: When data naturally has sequential timestamps
- **Legacy Systems**: Migrating systems with auto-incrementing IDs
- **Sequential Ordering**: Applications requiring sequential order numbers
- **Testing Scenarios**: Understanding the impact of poor shard key choice
- **Educational Purposes**: Demonstrating shard key design principles

## Considerations

- **Write Hotspots**: Most writes go to one shard, creating a bottleneck
- **Poor Distribution**: Writes are not evenly distributed across shards
- **Scalability Issues**: Performance does not improve significantly with more shards
- **Chunk Management**: MongoDB may need to split chunks frequently on the hot shard and/or rebalance data between shards
- **Not Recommended**: Generally not recommended for production workloads - however, may be OK if writes are relatively infrequent


## Best Practices

- **Avoid Monotonic Keys**: Generally avoid using monotonically increasing values as shard keys
- **Use Hash Sharding**: Consider hashed shard keys for better distribution (but be aware of the impact on range-based searching)
- **Composite Keys**: Use compound shard keys that include non-monotonic fields


## Advantages

- **Sequential Ordering**: Maintains natural sequential order which is important if range searching is a frequent use-case
- **Time-Series Support**: Works well for time-series data patterns
- **Simple Implementation**: Easy to implement with auto-incrementing values

## Limitations

- **Write Hotspots**: Creates bottlenecks on one or few shards
- **Poor Scalability**: Does not scale horizontally effectively in write intensive workloads
- **Uneven Distribution**: Writes concentrate on specific shards
- **Performance Issues**: Hot shard becomes a bottleneck
- **Not Production-Ready**: Generally not suitable for high-volume write-intensive production workloads



