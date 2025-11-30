# Update (Sharded / Undirected)

## Overview

This operation type performs update operations on a **sharded** MongoDB collection using **undirected** updates. Undirected updates don't include the shard key in the filter, causing MongoDB to broadcast the update to all shards.

## How It Works

When using this operation type:

1. The application selects a random order by `orderNumber` where `orderStatus` is not 'delivered'
2. The update query **does not include** the shard key in the filter
3. MongoDB's query router (mongos) broadcasts the update to **all shards** in the cluster
4. Each shard checks if it contains matching documents and performs updates
5. The mongos aggregates results from all shards

## Update Sequence

The status progression follows this order:

```
received → reviewed → approved → picked → shipped → delivered
```

## Performance Characteristics

- **Latency**: Higher than directed updates because all shards must be checked
- **Throughput**: Can utilize all shards, but with significant overhead
- **Network Overhead**: High network traffic as updates are sent to all shards
- **Resource Usage**: All shards process updates, even if they don't contain matching documents
- **Write Conflicts**: Lower chance of conflicts due to broadcasting

## Use Cases

- Updates where the shard key value is unknown
- Bulk updates that affect documents across multiple shards
- Status updates that don't include shard key in the filter
- Administrative operations that need to update documents regardless of shard

## Considerations

- **Scatter-Gather Pattern**: This is an expensive scatter-gather operation
- **Performance Impact**: Broadcasting to all shards significantly increases latency
- **Shard Key Design**: Poor shard key design makes undirected updates very slow
- **Inefficiency**: Most shards will process the update but find no matching documents

## Update Operation Details

- **Selection Criteria**: Random `orderNumber` where `orderStatus != 'delivered'` (no shard key filter)
- **Fields Updated**: 
  - `orderStatus`: Advanced to next status
  - `dateUpdated`: Set to current timestamp
- **Broadcast**: Update is sent to all shards in the cluster

## Best Practices

- **Avoid When Possible**: Undirected updates should be avoided in production when possible
- **Shard Key in Filter**: Include shard key in update filters whenever possible
- **Index Optimization**: Ensure proper indexes on fields used in update filters
- **Monitor Performance**: Track update latency and optimize shard key design
- **Consider Alternatives**: Use directed updates or redesign queries to include shard key

## Performance Warning

⚠️ **Warning**: Undirected updates on sharded collections can be very slow and resource-intensive. Always prefer directed updates (with shard key) when possible.

