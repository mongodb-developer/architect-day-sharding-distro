# Read (Sharded / Undirected)

## Overview

This operation type performs read queries on a **sharded** MongoDB collection using **undirected** queries. Undirected queries are queries that don't include the shard key in the filter, causing MongoDB to broadcast the query to all shards.

## How It Works

When using this operation type:

1. The application executes read queries **without** including the shard key in the filter
2. MongoDB's query router (mongos) broadcasts the query to **all shards** in the cluster
3. Each shard processes the query and returns matching documents
4. The mongos merges results from all shards and returns them to the client

## Query Types

The application performs the following types of queries (without shard key filters):

- **Recent Orders**: All orders created in the last 24 hours (no shard key filter)
- **Customer Orders**: All orders for a random customer ID with a specific status (no shard key filter)
- **Product Count**: Count of all orders received for a random product ID within a given date range (no shard key filter)
- **Product Grouping**: Count of all orders, grouped by productID, within a given date range (no shard key filter)

## Performance Characteristics

- **Latency**: Higher than directed queries because all shards must be queried
- **Throughput**: Can utilize all shards, but with overhead from broadcasting
- **Network Overhead**: Significant network traffic as queries are sent to all shards
- **Resource Usage**: All shards process queries, even if they don't contain relevant data

## Use Cases

- Queries that cannot include the shard key (e.g., range queries across shards)
- Analytics queries that need to aggregate data from all shards
- Ad-hoc queries where the shard key value is unknown
- Reporting queries that scan the entire collection

## Considerations

- **Scatter-Gather Pattern**: This is a scatter-gather operation, which can be expensive
- **Performance Impact**: Broadcasting to all shards increases latency and resource usage
- **Shard Key Design**: Poor shard key design can make undirected queries very slow
- **Index Usage**: Ensure proper indexes exist on non-shard-key fields used in queries

## Best Practices

- Minimize the use of undirected queries in production
- Design shard keys to support common query patterns
- Use targeted queries (with shard key) when possible
- Monitor query performance and optimize indexes

