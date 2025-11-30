# Update (Unsharded)

## Overview

This operation type performs update operations on an **unsharded** MongoDB collection. Updates modify existing documents in a collection that exists on a single shard or replica set.

## How It Works

When using this operation type:

1. The application selects a random order by `orderNumber` where `orderStatus` is not 'delivered'
2. Updates the `orderStatus` to the next status in the sequence:
   - `received` → `reviewed` → `approved` → `picked` → `shipped` → `delivered`
3. Updates the `dateUpdated` field to the current timestamp
4. All updates are processed by the single shard containing the collection

## Update Sequence

The status progression follows this order:

```
received → reviewed → approved → picked → shipped → delivered
```

Once an order reaches 'delivered', it is no longer eligible for updates.

## Performance Characteristics

- **Latency**: Consistent as all updates go to the same shard
- **Throughput**: Limited by the capacity of a single shard
- **Write Conflicts**: Lower chance of conflicts since all writes go to one location
- **Scalability**: Cannot scale horizontally beyond the single shard's capacity

## Use Cases

- Small to medium datasets that fit on a single shard
- Applications with moderate update volumes
- Development and testing environments
- Collections that don't require sharding for updates

## Considerations

- **Single Point of Load**: All update operations are concentrated on one shard
- **Write Capacity**: Limited by the single shard's write capacity
- **No Horizontal Scaling**: Cannot distribute update load across multiple shards
- **Migration Complexity**: Migrating to sharded collection requires careful planning

## Update Operation Details

- **Selection Criteria**: Random `orderNumber` where `orderStatus != 'delivered'`
- **Fields Updated**: 
  - `orderStatus`: Advanced to next status
  - `dateUpdated`: Set to current timestamp
- **Atomicity**: Each update is atomic at the document level

## Best Practices

- Ensure proper indexes on `orderNumber` and `orderStatus` for efficient updates
- Monitor update performance and shard capacity
- Consider sharding if update volume exceeds single shard capacity
- Use appropriate write concern for data durability requirements

