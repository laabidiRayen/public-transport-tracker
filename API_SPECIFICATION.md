# Public Transport Tracker - API Specification

## Base URL
```
http://backend-service:5000/api
```

## Authentication
Currently no authentication required. Can be enhanced with JWT tokens later.

## API Endpoints

### 1. ROUTES

#### GET /routes
Retrieve all available routes

**Response:**
```json
{
  "status": "success",
  "data": [
    {
      "route_id": 1,
      "route_name": "BUS 101",
      "route_type": "bus",
      "operator": "CityBus",
      "start_station": "Central Park",
      "end_station": "Airport"
    }
  ]
}
```

#### GET /routes/{route_id}
Get specific route details

**Response:**
```json
{
  "status": "success",
  "data": {
    "route_id": 1,
    "route_name": "BUS 101",
    "route_type": "bus",
    "operator": "CityBus",
    "start_station": "Central Park",
    "end_station": "Airport"
  }
}
```

#### POST /routes
Create a new route

**Request Body:**
```json
{
  "route_name": "BUS 101",
  "route_type": "bus",
  "operator": "CityBus",
  "start_station": "Central Park",
  "end_station": "Airport"
}
```

**Response:**
```json
{
  "status": "success",
  "data": {
    "route_id": 1,
    "message": "Route created successfully"
  }
}
```

---

### 2. STATIONS

#### GET /stations
Retrieve all stations

**Response:**
```json
{
  "status": "success",
  "data": [
    {
      "station_id": 1,
      "station_name": "Central Park",
      "station_type": "bus_stop",
      "latitude": 40.785091,
      "longitude": -73.968285,
      "address": "123 Park Ave, City"
    }
  ]
}
```

#### GET /stations/{station_id}
Get specific station details

**Response:**
```json
{
  "status": "success",
  "data": {
    "station_id": 1,
    "station_name": "Central Park",
    "station_type": "bus_stop",
    "latitude": 40.785091,
    "longitude": -73.968285,
    "address": "123 Park Ave, City"
  }
}
```

#### POST /stations
Create a new station

**Request Body:**
```json
{
  "station_name": "Central Park",
  "station_type": "bus_stop",
  "latitude": 40.785091,
  "longitude": -73.968285,
  "address": "123 Park Ave, City"
}
```

---

### 3. SCHEDULES

#### GET /schedules
Get all schedules (with optional filters)

**Query Parameters:**
- `route_id` (optional): Filter by route
- `day_of_week` (optional): Filter by day (Monday-Sunday)

**Response:**
```json
{
  "status": "success",
  "data": [
    {
      "schedule_id": 1,
      "route_id": 1,
      "route_name": "BUS 101",
      "departure_station": "Central Park",
      "arrival_station": "Airport",
      "departure_time": "08:00",
      "arrival_time": "09:30",
      "day_of_week": "Monday",
      "frequency": 15
    }
  ]
}
```

#### GET /schedules/{schedule_id}
Get specific schedule details

**Response:**
```json
{
  "status": "success",
  "data": {
    "schedule_id": 1,
    "route_id": 1,
    "route_name": "BUS 101",
    "departure_station": "Central Park",
    "arrival_station": "Airport",
    "departure_time": "08:00",
    "arrival_time": "09:30",
    "day_of_week": "Monday",
    "frequency": 15
  }
}
```

#### GET /routes/{route_id}/schedules
Get all schedules for a specific route

**Response:**
```json
{
  "status": "success",
  "data": [
    {
      "schedule_id": 1,
      "departure_station": "Central Park",
      "arrival_station": "Airport",
      "departure_time": "08:00",
      "arrival_time": "09:30",
      "day_of_week": "Monday"
    }
  ]
}
```

#### POST /schedules
Create a new schedule

**Request Body:**
```json
{
  "route_id": 1,
  "departure_station_id": 1,
  "arrival_station_id": 2,
  "departure_time": "08:00",
  "arrival_time": "09:30",
  "day_of_week": "Monday",
  "frequency": 15
}
```

---

### 4. DELAYS

#### GET /delays
Get all active delays

**Query Parameters:**
- `is_active` (optional): Filter by active status (true/false)
- `route_id` (optional): Filter by route

**Response:**
```json
{
  "status": "success",
  "data": [
    {
      "delay_id": 1,
      "schedule_id": 1,
      "route_name": "BUS 101",
      "delay_minutes": 5,
      "reason": "Traffic congestion",
      "reported_at": "2026-01-04T08:30:00Z",
      "is_active": true
    }
  ]
}
```

#### GET /delays/{delay_id}
Get specific delay details

**Response:**
```json
{
  "status": "success",
  "data": {
    "delay_id": 1,
    "schedule_id": 1,
    "route_name": "BUS 101",
    "delay_minutes": 5,
    "reason": "Traffic congestion",
    "reported_at": "2026-01-04T08:30:00Z",
    "is_active": true
  }
}
```

#### GET /schedules/{schedule_id}/delays
Get all delays for a specific schedule

**Response:**
```json
{
  "status": "success",
  "data": [
    {
      "delay_id": 1,
      "delay_minutes": 5,
      "reason": "Traffic congestion",
      "reported_at": "2026-01-04T08:30:00Z"
    }
  ]
}
```

#### POST /delays
Report a new delay

**Request Body:**
```json
{
  "schedule_id": 1,
  "delay_minutes": 5,
  "reason": "Traffic congestion"
}
```

**Response:**
```json
{
  "status": "success",
  "data": {
    "delay_id": 1,
    "message": "Delay reported successfully"
  }
}
```

#### PUT /delays/{delay_id}
Update delay status (mark as resolved)

**Request Body:**
```json
{
  "is_active": false
}
```

---

### 5. SEARCH

#### GET /search
Search for routes and schedules

**Query Parameters:**
- `q` (required): Search query
- `type` (optional): 'route' or 'schedule'

**Response:**
```json
{
  "status": "success",
  "data": {
    "routes": [
      {
        "route_id": 1,
        "route_name": "BUS 101"
      }
    ],
    "schedules": [
      {
        "schedule_id": 1,
        "departure_time": "08:00"
      }
    ]
  }
}
```

---

### 6. HEALTH CHECK

#### GET /health
Check API health status

**Response:**
```json
{
  "status": "healthy",
  "service": "public-transport-tracker-api",
  "timestamp": "2026-01-04T12:00:00Z"
}
```

---

## Error Responses

### 400 Bad Request
```json
{
  "status": "error",
  "message": "Invalid request parameters",
  "details": "Missing required field: route_name"
}
```

### 404 Not Found
```json
{
  "status": "error",
  "message": "Resource not found",
  "details": "Route with ID 999 does not exist"
}
```

### 500 Internal Server Error
```json
{
  "status": "error",
  "message": "Internal server error",
  "details": "Database connection failed"
}
```

---

## Status Codes

| Code | Meaning |
|------|---------|
| 200 | OK - Request succeeded |
| 201 | Created - Resource created successfully |
| 400 | Bad Request - Invalid input |
| 404 | Not Found - Resource does not exist |
| 500 | Internal Server Error - Server error |

---

## Content-Type
All responses are JSON with `Content-Type: application/json`
