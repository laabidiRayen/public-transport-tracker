-- SQLite version of the database schema
-- Public Transport Tracker Database

-- Drop existing tables if they exist
DROP TABLE IF EXISTS user_favorites;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS delays;
DROP TABLE IF EXISTS schedules;
DROP TABLE IF EXISTS stations;
DROP TABLE IF EXISTS routes;

-- 1. ROUTES Table
CREATE TABLE routes (
    route_id INTEGER PRIMARY KEY AUTOINCREMENT,
    route_name VARCHAR(100) NOT NULL,
    route_type VARCHAR(20) NOT NULL CHECK (route_type IN ('bus', 'train')),
    operator VARCHAR(100),
    start_station VARCHAR(100) NOT NULL,
    end_station VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_routes_type ON routes(route_type);
CREATE INDEX idx_routes_operator ON routes(operator);

-- 2. STATIONS Table
CREATE TABLE stations (
    station_id INTEGER PRIMARY KEY AUTOINCREMENT,
    station_name VARCHAR(100) NOT NULL UNIQUE,
    station_type VARCHAR(20) CHECK (station_type IN ('bus_stop', 'train_station')),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_stations_name ON stations(station_name);
CREATE INDEX idx_stations_type ON stations(station_type);

-- 3. SCHEDULES Table
CREATE TABLE schedules (
    schedule_id INTEGER PRIMARY KEY AUTOINCREMENT,
    route_id INT NOT NULL REFERENCES routes(route_id) ON DELETE CASCADE,
    departure_station_id INT NOT NULL REFERENCES stations(station_id),
    arrival_station_id INT NOT NULL REFERENCES stations(station_id),
    departure_time TIME NOT NULL,
    arrival_time TIME NOT NULL,
    day_of_week VARCHAR(20),
    frequency INT DEFAULT 15,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CHECK (arrival_time > departure_time)
);

CREATE INDEX idx_schedules_route ON schedules(route_id);
CREATE INDEX idx_schedules_day ON schedules(day_of_week);
CREATE INDEX idx_schedules_departure_station ON schedules(departure_station_id);
CREATE INDEX idx_schedules_arrival_station ON schedules(arrival_station_id);

-- 4. DELAYS Table
CREATE TABLE delays (
    delay_id INTEGER PRIMARY KEY AUTOINCREMENT,
    schedule_id INT NOT NULL REFERENCES schedules(schedule_id) ON DELETE CASCADE,
    delay_minutes INT NOT NULL DEFAULT 0,
    reason TEXT,
    reported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    resolved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CHECK (delay_minutes >= 0)
);

CREATE INDEX idx_delays_schedule ON delays(schedule_id);
CREATE INDEX idx_delays_active ON delays(is_active);
CREATE INDEX idx_delays_reported ON delays(reported_at);

-- 5. USERS Table
CREATE TABLE users (
    user_id INTEGER PRIMARY KEY AUTOINCREMENT,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);

-- 6. USER_FAVORITES Table
CREATE TABLE user_favorites (
    favorite_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    route_id INT NOT NULL REFERENCES routes(route_id) ON DELETE CASCADE,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, route_id)
);

CREATE INDEX idx_favorites_user ON user_favorites(user_id);
CREATE INDEX idx_favorites_route ON user_favorites(route_id);

-- ============================================================================
-- SAMPLE DATA INSERTION
-- ============================================================================

INSERT INTO stations (station_name, station_type, latitude, longitude, address)
VALUES
    ('Central Park', 'bus_stop', 40.785091, -73.968285, '123 Park Ave, New York'),
    ('Airport Terminal 1', 'bus_stop', 40.639751, -73.778925, 'JFK Airport, New York'),
    ('Downtown Station', 'train_station', 40.712776, -74.005974, '456 Broadway, New York'),
    ('Suburban Hub', 'train_station', 40.758896, -73.985130, '789 Station Rd, Suburbs'),
    ('Hospital Stop', 'bus_stop', 40.768045, -73.963530, '321 Medical Plaza, New York'),
    ('Shopping Mall', 'bus_stop', 40.772300, -73.980010, '654 Mall Street, New York');

INSERT INTO routes (route_name, route_type, operator, start_station, end_station)
VALUES
    ('BUS 101', 'bus', 'CityBus Inc', 'Central Park', 'Airport Terminal 1'),
    ('BUS 42', 'bus', 'CityBus Inc', 'Hospital Stop', 'Downtown Station'),
    ('EXPRESS 5', 'bus', 'FastTransit LLC', 'Central Park', 'Shopping Mall'),
    ('TRAIN A1', 'train', 'RailCorp', 'Downtown Station', 'Suburban Hub'),
    ('TRAIN B2', 'train', 'RailCorp', 'Downtown Station', 'Airport Terminal 1');

INSERT INTO schedules (route_id, departure_station_id, arrival_station_id, departure_time, arrival_time, day_of_week, frequency)
VALUES
    (1, 1, 2, '08:00:00', '09:30:00', 'Monday', 15),
    (1, 1, 2, '08:15:00', '09:45:00', 'Monday', 15),
    (1, 1, 2, '08:30:00', '10:00:00', 'Monday', 15),
    (1, 1, 2, '14:00:00', '15:30:00', 'Tuesday', 20),
    (1, 1, 2, '14:20:00', '15:50:00', 'Tuesday', 20),
    (2, 5, 3, '07:00:00', '07:45:00', 'Monday', 10),
    (2, 5, 3, '09:00:00', '09:45:00', 'Monday', 10),
    (2, 5, 3, '12:00:00', '12:45:00', 'Wednesday', 15),
    (4, 3, 4, '06:30:00', '07:15:00', 'Monday', 30),
    (4, 3, 4, '09:00:00', '09:45:00', 'Monday', 30),
    (4, 3, 4, '18:00:00', '18:45:00', 'Friday', 45);

INSERT INTO delays (schedule_id, delay_minutes, reason, is_active)
VALUES
    (1, 5, 'Traffic congestion on main route', 1),
    (2, 10, 'Mechanical issue with vehicle', 0),
    (4, 0, 'On schedule', 1),
    (8, 15, 'High passenger volume', 1);

INSERT INTO users (username, email)
VALUES
    ('john_doe', 'john@example.com'),
    ('jane_smith', 'jane@example.com'),
    ('mike_wilson', 'mike@example.com');

INSERT INTO user_favorites (user_id, route_id)
VALUES
    (1, 1),
    (1, 4),
    (2, 2),
    (3, 1),
    (3, 3);
