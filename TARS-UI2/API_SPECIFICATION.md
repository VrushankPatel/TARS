# TARS REST API Specification

## Base URL
All endpoints are relative to your server's base URL (e.g., `http://localhost:8080`)

## Authentication
Currently no authentication required. Add Bearer token or API key authentication as needed.

## Endpoints

### 1. System Information

#### Get System Info
```
GET /api/system/info
```

**Response:**
```json
{
  "hostname": "tars-mac-mini-1",
  "os": "Debian GNU/Linux 12 (bookworm)",
  "uptime_seconds": 432156,
  "cpu_count": 8,
  "total_memory_bytes": 17179869184,
  "kernel": "6.1.0"
}
```

#### Get System Metrics
```
GET /api/system/metrics
```

**Response:**
```json
{
  "cpu_percent": 15.7,
  "memory": {
    "total": 17179869184,
    "used": 4923456789
  },
  "disk": {
    "total": 500107862016,
    "used": 142345678912
  }
}
```

### 2. Process Management

#### List Processes
```
GET /api/processes
```

**Response:**
```json
[
  {
    "pid": 1234,
    "user": "root",
    "cmd": "nginx: master process /etc/nginx/nginx.conf",
    "cpu_percent": 2.3,
    "mem_bytes": 45123456
  },
  {
    "pid": 5678,
    "user": "postgres",
    "cmd": "postgres: main process",
    "cpu_percent": 5.7,
    "mem_bytes": 123456789
  }
]
```

#### Kill Process
```
POST /api/processes/{pid}/kill
```

**Request Body:** None required

**Response:**
```json
{
  "status": "ok",
  "message": "Process 1234 terminated"
}
```

**Error Response:**
```json
{
  "status": "error",
  "message": "Process not found or permission denied"
}
```

### 3. Docker Container Management

#### List Containers
```
GET /api/containers
```

**Response:**
```json
[
  {
    "id": "a87ec4d5f2b1",
    "name": "tars-db",
    "image": "postgres:15",
    "status": "running"
  },
  {
    "id": "b23fd1c8e9a4",
    "name": "tars-redis",
    "image": "redis:7-alpine",
    "status": "running"
  }
]
```

#### Get Container Stats
```
GET /api/containers/{container_id}/stats
```

**Response:**
```json
{
  "cpu_percent": 3.5,
  "memory_bytes": 123456789
}
```

### 4. System Power Management

#### Power Actions
```
POST /api/system/power
```

**Request Body:**
```json
{
  "action": "reboot"
}
```
*Valid actions: "reboot", "shutdown"*

**Response:**
```json
{
  "status": "ok",
  "message": "System rebooting in 10 seconds"
}
```

**Error Response:**
```json
{
  "status": "error",
  "message": "Insufficient permissions for power action"
}
```

## Implementation Notes

### Error Handling
All endpoints should return appropriate HTTP status codes:
- `200` - Success
- `400` - Bad Request (invalid parameters)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found (process/container not found)
- `500` - Internal Server Error

### CORS Headers
Since the frontend will be making AJAX requests, ensure your backend includes proper CORS headers:
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
```

### Rate Limiting
Consider implementing rate limiting, especially for:
- Process kill operations
- Power management actions
- Frequent metric requests

### Security Considerations
- Validate all input parameters
- Implement proper authentication for production use
- Log all power management and process kill actions
- Consider IP whitelisting for sensitive operations

## Frontend Integration

To switch from mock data to real API calls, uncomment the fetch calls in the React components and remove the mock data calls. The UI is already structured to handle the exact response formats specified above.

Example implementation for system info:
```typescript
const fetchSystemInfo = async () => {
  try {
    const response = await fetch('/api/system/info');
    const data = await response.json();
    setSystemInfo(data);
  } catch (error) {
    toast({
      title: "Error",
      description: "Failed to fetch system info",
      variant: "destructive"
    });
  }
};
```