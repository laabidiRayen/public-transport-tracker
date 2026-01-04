# Public Transport Tracker - Data Model

## Database Schema

### 1. ROUTES Table
Stores information about transport routes (bus/train lines)

```sql
CREATE TABLE routes (
    route_id SERIAL PRIMARY KEY,
    route_name VARCHAR(100) NOT NULL,
    route_type VARCHAR(20) NOT NULL,  -- 'bus' or 'train'
    operator VARCHAR(100),            -- Bus/Train company name
    start_station VARCHAR(100),       -- Starting point
    end_station VARCHAR(100),         -- Ending point
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 2. STATIONS Table
Stores information about bus stops and train stations

```sql
CREATE TABLE stations (
    station_id SERIAL PRIMARY KEY,
    station_name VARCHAR(100) NOT NULL UNIQUE,
    station_type VARCHAR(20),         -- 'bus_stop' or 'train_station'
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 3. SCHEDULES Table
Stores planned schedules for routes

```sql
CREATE TABLE schedules (
    schedule_id SERIAL PRIMARY KEY,
    route_id INT NOT NULL REFERENCES routes(route_id),
    departure_station_id INT NOT NULL REFERENCES stations(station_id),
    arrival_station_id INT NOT NULL REFERENCES stations(station_id),
    departure_time TIME NOT NULL,
    arrival_time TIME NOT NULL,
    day_of_week VARCHAR(20),          -- 'Monday', 'Tuesday', etc.
    frequency INT,                     -- Minutes between each service
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 4. DELAYS Table
Stores real-time delay information

```sql
CREATE TABLE delays (
    delay_id SERIAL PRIMARY KEY,
    schedule_id INT NOT NULL REFERENCES schedules(schedule_id),
    delay_minutes INT,                -- Minutes delayed
    reason TEXT,                      -- Reason for delay
    reported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    resolved_at TIMESTAMP
);
```

### 5. USERS Table (Optional - for future enhancements)
Stores user information for tracking favorites

```sql
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 6. USER_FAVORITES Table (Optional)
Stores user favorite routes

```sql
CREATE TABLE user_favorites (
    favorite_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(user_id),
    route_id INT NOT NULL REFERENCES routes(route_id),
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Entity Relationship Diagram

```
┌─────────────┐
│   ROUTES    │
├─────────────┤
│ route_id (PK)
│ route_name
│ route_type
│ operator
│ start_station
│ end_station
└──────┬──────┘
       │ 1:N
       ├─────────────────────┐
       │                     │
       ▼                     ▼
┌──────────────┐      ┌──────────────┐
│  SCHEDULES   │      │ USER_FAV...  │
├──────────────┤      └──────┬───────┘
│ schedule_id  │             │
│ route_id (FK)│             │ N:1
│ departure_st │             │
│ arrival_st   │      ┌──────▼───────┐
│ departure_tm │      │     USERS     │
│ arrival_time │      ├───────────────┤
│ day_of_week  │      │ user_id (PK)
│ frequency    │      │ username
└──────┬───────┘      │ email
       │ 1:N          └───────────────┘
       │
       ▼
┌──────────────┐
│    DELAYS    │
├──────────────┤
│ delay_id (PK)
│ schedule_id  │
│ delay_mins   │
│ reason       │
│ reported_at  │
└──────────────┘

┌─────────────┐
│  STATIONS   │
├─────────────┤
│ station_id  │
│ station_name│
│ station_type│
│ latitude    │
│ longitude   │
│ address     │
└─────────────┘
(Referenced by SCHEDULES)
```

## Key Relationships

1. **ROUTES → SCHEDULES**: One route has many schedules (1:N)
2. **SCHEDULES → DELAYS**: One schedule can have multiple delays (1:N)
3. **STATIONS ← SCHEDULES**: Schedules reference departure and arrival stations
4. **USERS → USER_FAVORITES**: One user has many favorite routes (1:N)
5. **ROUTES ← USER_FAVORITES**: One route can be favorited by many users (1:N)

## Sample Data

### Routes
```
route_id | route_name        | route_type | operator | start_station | end_station
1        | BUS 101          | bus        | CityBus  | Central Park  | Airport
2        | TRAIN A1         | train      | RailCo   | Downtown      | Suburbs
3        | BUS 42           | bus        | CityBus  | Hospital      | Station
```

### Stations
```
station_id | station_name | station_type   | latitude   | longitude
1          | Central Park | bus_stop       | 40.785091  | -73.968285
2          | Airport      | bus_stop       | 40.639751  | -73.778925
3          | Downtown     | train_station  | 40.712776  | -74.005974
```

### Schedules
```
schedule_id | route_id | departure_station_id | arrival_station_id | departure_time | arrival_time | day_of_week | frequency
1           | 1        | 1                    | 2                  | 08:00          | 09:30        | Monday      | 15
2           | 1        | 1                    | 2                  | 08:15          | 09:45        | Monday      | 15
```

### Delays
```
delay_id | schedule_id | delay_minutes | reason              | reported_at | is_active
1        | 1           | 5             | Traffic congestion  | 2026-01-04  | TRUE
2        | 2           | 10            | Mechanical issue    | 2026-01-04  | FALSE
```

## Constraints & Validations

- **Primary Keys**: All tables have unique identifiers
- **Foreign Keys**: Enforce referential integrity
- **Not Null**: Critical fields are mandatory
- **Unique Constraints**: Route names, station names, usernames, emails
- **Time Constraints**: Arrival time > Departure time in schedules
- **Delay Constraints**: Delay minutes must be positive
