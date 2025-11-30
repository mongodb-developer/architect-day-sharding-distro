# Read (Sharded / Directed)

## Overview

This operation type performs read queries on a **sharded** MongoDB collection using **directed** queries. Directed queries include the shard key in the filter, allowing MongoDB to route queries directly to the specific shard(s) containing the data.

## How It Works

When using this operation type:

1. The application executes read queries **with** the shard key included in the filter
2. MongoDB's query router (mongos) uses the shard key to determine which shard(s) contain the data
3. The query is sent **only** to the relevant shard(s)
4. Results are returned directly from the targeted shard(s) without querying other shards

## Query Types

The application performs queries that include shard key filters:

- **Shard Key Targeted Queries**: Queries that include the shard key value in the filter
- **Range Queries**: Queries with shard key ranges that target specific shards
- **Equality Queries**: Queries with exact shard key matches

## Performance Characteristics

- **Latency**: Lower than undirected queries because only relevant shards are queried
- **Throughput**: High, as queries are targeted and efficient
- **Network Overhead**: Minimal, as queries are only sent to necessary shards
- **Resource Usage**: Only relevant shards process queries

## Use Cases

- Queries where the shard key value is known
- High-performance read operations
- Applications with predictable query patterns
- Production workloads requiring optimal performance

## Considerations

- **Shard Key Required**: Queries must include the shard key in the filter
- **Shard Key Design**: Effective shard key design is critical for performance
- **Query Patterns**: Application must be designed to include shard key in queries
- **Data Locality**: Queries benefit from data being located on specific shards

## Best Practices

- Design shard keys that match common query patterns
- Always include shard key in query filters when possible
- Use compound shard keys if single-field keys don't support all queries
- Monitor query performance to ensure shard key effectiveness

## Advantages

- **Targeted Routing**: Queries go directly to the right shard(s)
- **Reduced Network Traffic**: No broadcasting to all shards
- **Lower Latency**: Faster response times
- **Better Scalability**: Performance improves as you add shards

