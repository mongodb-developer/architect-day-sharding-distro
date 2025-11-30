# MongoDB Sharding Performance Monitor

A real-time performance monitoring tool for MongoDB sharded clusters. This application generates configurable load on your MongoDB cluster and provides a web-based dashboard to visualize operations per shard in real-time.

## Features

- **Real-time Monitoring**: Live WebSocket-based metrics visualization with Chart.js
- **Configurable Load Generation**: Adjustable connections, goroutines, batch sizes, and operation types
- **Multiple Operation Types**: Support for various read, write, and update patterns:
  - Read operations (unsharded, sharded/directed, sharded/undirected)
  - Write operations (unsharded, sharded with equal/hashed/monotonic distribution)
  - Update operations (unsharded, sharded/directed, sharded/undirected)
  - Range queries with different sharding strategies
- **Per-Shard Metrics**: Track operations per shard to understand load distribution
- **Secure Web Interface**: TLS/SSL encrypted web interface with admin password protection
- **Dynamic Configuration**: Update load parameters in real-time through the web interface
- **Documentation**: Built-in documentation for each operation type

## Prerequisites

- Go 1.25.3 or later
- MongoDB sharded cluster (Atlas or self-hosted)
- TLS certificates for HTTPS (place in `certs/` directory)
- MongoDB connection string with appropriate permissions

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd ShardingMonitor
```

2. Install dependencies:
```bash
go mod download
```

3. Build the application:
```bash
go build -o sharding-monitor
```

## Configuration

Create a `.env` file in the project root with the following variables:

### Required Variables

```env
MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/
```

### Optional Variables

```env
# Database and Collection
DATABASE_NAME=architect_day
COLLECTION_NAME=orders

# MongoDB Atlas API (for advanced features)
CLIENT_ID=your_atlas_client_id
CLIENT_SECRET=your_atlas_client_secret
ORG_ID=your_org_id
PROJECT_ID=your_project_id
CLUSTER_NAME=your_cluster_name

# Load Generation Settings
CONNECTIONS=1                    # Number of MongoDB connections
GOROUTINESPERCONN=1             # Goroutines per connection
WRITE_BATCH_SIZE=1              # Batch size for write operations
OPERATION=read-unsharded        # Default operation type
MAX_GOROUTINES=100              # Maximum goroutines limit
INITIAL_DATA_DAYS=1             # Days of initial data to generate
REBUILD_DATA=false              # Set to true to rebuild initial data

# Web Server Settings
WEB_PORT=8080                   # Port for web interface and WebSocket

# Security
ADMIN_PASSWORD=your_admin_password  # Password for metrics section access
```

### Operation Types

The following operation types are supported:

**Read Operations:**
- `read-unsharded` - Read from unsharded collection
- `read-sharded-undirected` - Read from sharded collection (undirected)
- `read-sharded-directed` - Read from sharded collection (directed)
- `read-range-unsharded` - Range query on unsharded collection
- `read-range-sharded-directed` - Range query on sharded collection (directed)
- `read-range-sharded-undirected` - Range query on sharded collection (undirected)

**Write Operations:**
- `write-unsharded` - Write to unsharded collection
- `write-sharded-equal` - Write to sharded collection (equal distribution)
- `write-sharded-hashed` - Write to sharded collection (hashed shard key)
- `write-sharded-monotonic` - Write to sharded collection (monotonically increasing)

**Update Operations:**
- `update-unsharded` - Update unsharded collection
- `update-sharded-undirected` - Update sharded collection (undirected)
- `update-sharded-directed` - Update sharded collection (directed)

## TLS Certificates

Place your TLS certificate and key files in the `certs/` directory. The application will automatically detect files with common naming patterns:

**Certificate files:**
- `fullchain.pem`
- `cert.pem`
- `server.crt`
- `certificate.crt`

**Key files:**
- `privkey.pem`
- `key.pem`
- `server.key`
- `private.key`

## Usage

1. Ensure your `.env` file is configured with your MongoDB connection string
2. Place TLS certificates in the `certs/` directory
3. Run the application:
```bash
./sharding-monitor
```

4. Open your browser and navigate to:
```
https://localhost:8080
```

5. Click "Connect" to establish a WebSocket connection
6. Click "Admin" and enter your admin password to access the metrics configuration section
7. Configure your load parameters:
   - MongoDB Connections
   - Threads per Connection
   - Write Batch Size
   - Operation Type

8. Monitor real-time metrics in the chart below

## Web Interface

### Connection Controls
- **Connect**: Establishes WebSocket connection to receive real-time metrics
- **Disconnect**: Closes the WebSocket connection
- **Info**: Displays documentation about the currently selected operation type
- **Admin**: Access the metrics configuration section (password protected)

### Metrics Section (Admin Only)
- **MongoDB Connections**: Number of concurrent MongoDB connections
- **Threads per Connection**: Number of goroutines per connection
- **Write Batch Size**: Batch size for write operations
- **Operation Type**: Select the type of operation to perform

### Real-time Chart
The chart displays operations per second for each shard, updating every second. The chart automatically adjusts the Y-axis label based on the operation type:
- Reads per Second (for read operations)
- Updates per Second (for update operations)
- Inserts per Second (for write operations)

## Architecture

The application consists of several key components:

- **Load Generator** (`load_generator.go`): Generates configurable load on MongoDB cluster
- **Metrics Monitor** (`metrics_monitor.go`): Collects performance metrics from each shard
- **WebSocket Server** (`websocket.go`): Serves the web interface and streams metrics
- **MongoDB Client** (`mongo.go`): Handles MongoDB connections and operations
- **Configuration** (`config.go`): Manages application configuration from environment variables

## Project Structure

```
ShardingMonitor/
├── certs/              # TLS certificates directory
├── static/             # Web interface files
│   ├── docs/          # Operation type documentation
│   └── index.html     # Main web interface
├── config.go          # Configuration management
├── load_generator.go  # Load generation logic
├── main.go           # Application entry point
├── metrics_monitor.go # Metrics collection
├── mongo.go          # MongoDB client operations
├── websocket.go      # WebSocket server
├── go.mod            # Go module dependencies
├── go.sum            # Go module checksums
└── README.md         # This file
```

## Security

- The web interface uses TLS/SSL encryption
- The metrics configuration section is protected by an admin password
- Password is verified server-side via WebSocket
- Default state hides sensitive configuration options

## Troubleshooting

### Connection Issues
- Verify your `MONGO_URI` is correct and accessible
- Ensure your MongoDB cluster allows connections from your IP
- Check that TLS certificates are properly configured

### Metrics Not Showing
- Ensure you've connected via WebSocket (click "Connect")
- Verify admin password is set in `.env` file
- Check that the load generator is running (should start automatically when connected)

### Load Generator Not Starting
- Verify MongoDB connection string is valid
- Check that you have appropriate permissions on the database
- Review application logs for specific error messages

## Development

### Building
```bash
go build -o sharding-monitor
```

### Running Tests
```bash
go test ./...
```

### Dependencies
- `github.com/gorilla/websocket` - WebSocket support
- `github.com/joho/godotenv` - Environment variable management
- `go.mongodb.org/mongo-driver/v2` - MongoDB driver

## License

[Add your license information here]

## Contributing

[Add contribution guidelines here]

## Support

[Add support information here]

