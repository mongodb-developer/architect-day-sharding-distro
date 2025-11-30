# Update (Sharded / Directed)

## Overview

This operation type performs update operations on a **sharded** MongoDB collection using **directed** updates. Directed updates include the shard key in the filter, allowing MongoDB to route updates directly to the specific shard(s) containing the data.

## How It Works

When using this operation type:

1. The application selects a random order by `orderNumber` where `orderStatus` is not 'delivered'
2. The update query **includes** the shard key in the filter
3. MongoDB's query router (mongos) uses the shard key to determine which shard contains the document
4. The update is sent **only** to the relevant shard
5. The targeted shard performs the update and returns the result

## Update Sequence

The status progression follows this order:

```
received → reviewed → approved → picked → shipped → delivered
```

## Performance Characteristics

- **Latency**: Lower than undirected updates because only the relevant shard is updated
- **Throughput**: High, as updates are targeted and efficient
- **Network Overhead**: Minimal, as updates are only sent to necessary shards
- **Resource Usage**: Only the relevant shard processes the update
- **Write Conflicts**: Lower chance of conflicts with targeted updates

## Use Cases

- Updates where the shard key value is known
- High-performance update operations
- Applications with predictable update patterns
- Production workloads requiring optimal update performance

## Considerations

- **Shard Key Required**: Update filters must include the shard key
- **Shard Key Design**: Effective shard key design is critical for update performance
- **Update Patterns**: Application must be designed to include shard key in update filters
- **Data Locality**: Updates benefit from data being located on specific shards

## Update Operation Details

- **Selection Criteria**: Random `orderNumber` where `orderStatus != 'delivered'` (with shard key filter)
- **Fields Updated**: 
  - `orderStatus`: Advanced to next status
  - `dateUpdated`: Set to current timestamp
- **Targeted Routing**: Update is sent only to the shard containing the document

## Best Practices

- **Include Shard Key**: Always include shard key in update filters when possible
- **Shard Key Design**: Design shard keys that match common update patterns
- **Index Optimization**: Ensure proper indexes on shard key and update filter fields
- **Monitor Performance**: Track update latency and optimize shard key effectiveness
- **Compound Shard Keys**: Use compound shard keys if single-field keys don't support all updates

## Advantages

- **Targeted Routing**: Updates go directly to the right shard
- **Reduced Network Traffic**: No broadcasting to all shards
- **Lower Latency**: Faster update response times
- **Better Scalability**: Update performance improves as you add shards
- **Resource Efficiency**: Only relevant shards process updates

## Performance Comparison

Compared to undirected updates:
- **10-100x faster** in typical scenarios
- **Significantly lower** network overhead
- **Better resource utilization** across the cluster

