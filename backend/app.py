"""
Public Transport Tracker - Flask Backend Application
Main entry point for the REST API
SQLite Version for Local Development
"""

import os
from flask import Flask, jsonify, request
from flask_cors import CORS
from datetime import datetime, date, time
import sqlite3
import logging
from json import JSONEncoder

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# -----------------------
# Custom JSON encoder
# -----------------------
class CustomJSONEncoder(JSONEncoder):
    """Convert datetime, date, and time objects to ISO strings"""
    def default(self, obj):
        if isinstance(obj, (datetime, date, time)):
            return obj.isoformat()
        return super().default(obj)

app.json_encoder = CustomJSONEncoder

# -----------------------
# Database configuration (SQLite)
# -----------------------
# Use /app/database for containerized environment, otherwise use relative path
if os.path.exists('/app/database'):
    DB_PATH = '/app/database/transport_db.sqlite'
else:
    DB_PATH = os.path.join(os.path.dirname(__file__), '..', 'database', 'transport_db.sqlite')

# Initialize database if it doesn't exist
def init_database():
    """Initialize database with schema if it doesn't exist"""
    if not os.path.exists(DB_PATH):
        logger.info(f"Initializing database at {DB_PATH}")
        os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        
        # Execute schema directly
        schema = """
        -- SQLite Database Schema
        DROP TABLE IF EXISTS user_favorites;
        DROP TABLE IF EXISTS users;
        DROP TABLE IF EXISTS delays;
        DROP TABLE IF EXISTS schedules;
        DROP TABLE IF EXISTS stations;
        DROP TABLE IF EXISTS routes;

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

        CREATE TABLE user_favorites (
            favorite_id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
            route_id INT NOT NULL REFERENCES routes(route_id) ON DELETE CASCADE,
            added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(user_id, route_id)
        );
        CREATE INDEX idx_user_favorites_user ON user_favorites(user_id);
        CREATE INDEX idx_user_favorites_route ON user_favorites(route_id);
        """
        
        cursor.executescript(schema)
        conn.commit()
        logger.info("Database initialized successfully")
        conn.close()
    else:
        logger.info(f"Using existing database at {DB_PATH}")

# Database connection helper
def get_db_connection():
    """Establish connection to SQLite database"""
    try:
        conn = sqlite3.connect(DB_PATH)
        conn.row_factory = sqlite3.Row  # Return rows as dictionaries
        return conn
    except sqlite3.Error as e:
        logger.error(f"Database connection error: {e}")
        raise

def dict_from_row(row):
    """Convert sqlite3.Row to dict"""
    if row is None:
        return None
    return dict(row)

# Initialize database on startup
init_database()

# -----------------------
# Error helper
# -----------------------
def error_response(message, status_code):
    return jsonify({'status': 'error', 'message': message}), status_code

@app.errorhandler(404)
def not_found(e):
    return error_response('Endpoint not found', 404)

@app.errorhandler(500)
def internal_error(e):
    return error_response('Internal server error', 500)

# ============================================================================
# HEALTH CHECK ENDPOINTS
# ============================================================================

@app.route('/', methods=['GET'])
def root():
    """Root endpoint - OpenShift health check"""
    return jsonify({
        'status': 'ok',
        'service': 'Public Transport Tracker API',
        'message': 'Service is running. Use /api endpoints for data.'
    }), 200

@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    try:
        conn = get_db_connection()
        conn.close()
        return jsonify({
            'status': 'healthy',
            'service': 'public-transport-tracker-api',
            'timestamp': datetime.utcnow().isoformat() + 'Z',
            'database': 'connected'
        }), 200
    except Exception as e:
        return jsonify({
            'status': 'unhealthy',
            'service': 'public-transport-tracker-api',
            'timestamp': datetime.utcnow().isoformat() + 'Z',
            'error': str(e)
        }), 500

@app.route('/api', methods=['GET'])
def api_info():
    """API information endpoint"""
    return jsonify({
        'service': 'Public Transport Tracker API',
        'version': '1.0.0',
        'database': 'SQLite (Local Development)',
        'endpoints': {
            'routes': '/api/routes',
            'stations': '/api/stations',
            'schedules': '/api/schedules',
            'delays': '/api/delays',
            'health': '/api/health'
        }
    }), 200

# ============================================================================
# ROUTES ENDPOINTS
# ============================================================================

@app.route('/api/routes', methods=['GET'])
def get_routes():
    """Get all routes"""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('SELECT * FROM routes ORDER BY route_id')
        routes = [dict(row) for row in cur.fetchall()]
        conn.close()
        return jsonify({'status': 'success', 'data': routes}), 200
    except Exception as e:
        return error_response(str(e), 500)

@app.route('/api/routes/<int:route_id>', methods=['GET'])
def get_route(route_id):
    """Get specific route"""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('SELECT * FROM routes WHERE route_id = ?', (route_id,))
        route = dict_from_row(cur.fetchone())
        conn.close()
        if not route:
            return error_response(f'Route {route_id} not found', 404)
        return jsonify({'status': 'success', 'data': route}), 200
    except Exception as e:
        return error_response(str(e), 500)

@app.route('/api/routes', methods=['POST'])
def create_route():
    """Create new route"""
    try:
        data = request.get_json()
        required = ['route_name', 'route_type', 'start_station', 'end_station']
        if not all(field in data for field in required):
            return error_response('Missing required fields', 400)

        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute(
            '''INSERT INTO routes (route_name, route_type, operator, start_station, end_station)
               VALUES (?, ?, ?, ?, ?)''',
            (data['route_name'], data['route_type'], data.get('operator'),
             data['start_station'], data['end_station'])
        )
        route_id = cur.lastrowid
        conn.commit()
        conn.close()
        return jsonify({'status': 'success', 'data': {'route_id': route_id, 'message': 'Route created successfully'}}), 201
    except Exception as e:
        return error_response(str(e), 500)

# ============================================================================
# STATIONS ENDPOINTS
# ============================================================================

@app.route('/api/stations', methods=['GET'])
def get_stations():
    """Get all stations"""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('SELECT * FROM stations ORDER BY station_id')
        stations = [dict(row) for row in cur.fetchall()]
        conn.close()
        return jsonify({'status': 'success', 'data': stations}), 200
    except Exception as e:
        return error_response(str(e), 500)

@app.route('/api/stations/<int:station_id>', methods=['GET'])
def get_station(station_id):
    """Get specific station"""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('SELECT * FROM stations WHERE station_id = ?', (station_id,))
        station = dict_from_row(cur.fetchone())
        conn.close()
        if not station:
            return error_response(f'Station {station_id} not found', 404)
        return jsonify({'status': 'success', 'data': station}), 200
    except Exception as e:
        return error_response(str(e), 500)

@app.route('/api/stations', methods=['POST'])
def create_station():
    """Create new station"""
    try:
        data = request.get_json()
        if 'station_name' not in data:
            return error_response('Missing required field: station_name', 400)
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute(
            '''INSERT INTO stations (station_name, station_type, latitude, longitude, address)
               VALUES (?, ?, ?, ?, ?)''',
            (data['station_name'], data.get('station_type'), data.get('latitude'),
             data.get('longitude'), data.get('address'))
        )
        station_id = cur.lastrowid
        conn.commit()
        conn.close()
        return jsonify({'status': 'success', 'data': {'station_id': station_id, 'message': 'Station created successfully'}}), 201
    except Exception as e:
        return error_response(str(e), 500)

# ============================================================================
# SCHEDULES ENDPOINTS
# ============================================================================

@app.route('/api/schedules', methods=['GET'])
def get_schedules():
    """Get all schedules with optional filters"""
    try:
        route_id = request.args.get('route_id')
        day_of_week = request.args.get('day_of_week')
        conn = get_db_connection()
        cur = conn.cursor()

        query = '''SELECT s.schedule_id, s.route_id, r.route_name,
                          ds.station_name as departure_station,
                          asst.station_name as arrival_station,
                          s.departure_time, s.arrival_time, s.day_of_week, s.frequency
                   FROM schedules s
                   JOIN routes r ON s.route_id = r.route_id
                   JOIN stations ds ON s.departure_station_id = ds.station_id
                   JOIN stations asst ON s.arrival_station_id = asst.station_id'''

        params = []
        if route_id:
            query += ' WHERE s.route_id = ?'
            params.append(route_id)
        if day_of_week:
            query += ' AND' if params else ' WHERE'
            query += ' s.day_of_week = ?'
            params.append(day_of_week)

        query += ' ORDER BY s.schedule_id'
        cur.execute(query, params)
        schedules = [dict(row) for row in cur.fetchall()]
        conn.close()

        return jsonify({'status': 'success', 'data': schedules}), 200
    except Exception as e:
        return error_response(str(e), 500)

@app.route('/api/schedules/<int:schedule_id>', methods=['GET'])
def get_schedule(schedule_id):
    """Get specific schedule"""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('''SELECT s.schedule_id, s.route_id, r.route_name,
                              ds.station_name as departure_station,
                              asst.station_name as arrival_station,
                              s.departure_time, s.arrival_time, s.day_of_week, s.frequency
                       FROM schedules s
                       JOIN routes r ON s.route_id = r.route_id
                       JOIN stations ds ON s.departure_station_id = ds.station_id
                       JOIN stations asst ON s.arrival_station_id = asst.station_id
                       WHERE s.schedule_id = ?''', (schedule_id,))
        schedule = dict_from_row(cur.fetchone())
        conn.close()
        if not schedule:
            return error_response(f'Schedule {schedule_id} not found', 404)
        return jsonify({'status': 'success', 'data': schedule}), 200
    except Exception as e:
        return error_response(str(e), 500)

@app.route('/api/routes/<int:route_id>/schedules', methods=['GET'])
def get_route_schedules(route_id):
    """Get all schedules for a specific route"""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('''SELECT s.schedule_id, s.route_id, r.route_name,
                              ds.station_name as departure_station,
                              asst.station_name as arrival_station,
                              s.departure_time, s.arrival_time, s.day_of_week, s.frequency
                       FROM schedules s
                       JOIN routes r ON s.route_id = r.route_id
                       JOIN stations ds ON s.departure_station_id = ds.station_id
                       JOIN stations asst ON s.arrival_station_id = asst.station_id
                       WHERE s.route_id = ? ORDER BY s.schedule_id''', (route_id,))
        schedules = [dict(row) for row in cur.fetchall()]
        conn.close()
        return jsonify({'status': 'success', 'data': schedules}), 200
    except Exception as e:
        return error_response(str(e), 500)

@app.route('/api/schedules', methods=['POST'])
def create_schedule():
    """Create new schedule"""
    try:
        data = request.get_json()
        required = ['route_id', 'departure_station_id', 'arrival_station_id', 'departure_time', 'arrival_time']
        if not all(field in data for field in required):
            return error_response('Missing required fields', 400)
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute(
            '''INSERT INTO schedules (route_id, departure_station_id, arrival_station_id,
                                     departure_time, arrival_time, day_of_week, frequency)
               VALUES (?, ?, ?, ?, ?, ?, ?)''',
            (data['route_id'], data['departure_station_id'], data['arrival_station_id'],
             data['departure_time'], data['arrival_time'], data.get('day_of_week'), data.get('frequency', 15))
        )
        schedule_id = cur.lastrowid
        conn.commit()
        conn.close()
        return jsonify({'status': 'success', 'data': {'schedule_id': schedule_id, 'message': 'Schedule created successfully'}}), 201
    except Exception as e:
        return error_response(str(e), 500)

# ============================================================================
# DELAYS ENDPOINTS
# ============================================================================

@app.route('/api/delays', methods=['GET'])
def get_delays():
    """Get all delays with optional filters"""
    try:
        is_active = request.args.get('is_active', 'true').lower() == 'true'
        route_id = request.args.get('route_id')
        
        conn = get_db_connection()
        cur = conn.cursor()
        
        query = '''SELECT d.delay_id, d.schedule_id, r.route_name, s.departure_time,
                          d.delay_minutes, d.reason, d.reported_at, d.is_active
                   FROM delays d
                   JOIN schedules s ON d.schedule_id = s.schedule_id
                   JOIN routes r ON s.route_id = r.route_id
                   WHERE d.is_active = ?'''
        
        params = [1 if is_active else 0]
        
        if route_id:
            query += ' AND r.route_id = ?'
            params.append(route_id)
        
        query += ' ORDER BY d.reported_at DESC'
        cur.execute(query, params)
        delays = [dict(row) for row in cur.fetchall()]
        conn.close()
        
        return jsonify({
            'status': 'success',
            'data': delays
        }), 200
    except Exception as e:
        return error_response(str(e), 500)

@app.route('/api/delays/<int:delay_id>', methods=['GET'])
def get_delay(delay_id):
    """Get specific delay by ID"""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        cur.execute('''SELECT d.delay_id, d.schedule_id, r.route_name,
                              d.delay_minutes, d.reason, d.reported_at, d.is_active
                       FROM delays d
                       JOIN schedules s ON d.schedule_id = s.schedule_id
                       JOIN routes r ON s.route_id = r.route_id
                       WHERE d.delay_id = ?''', (delay_id,))
        
        delay = dict_from_row(cur.fetchone())
        conn.close()
        
        if not delay:
            return error_response(f'Delay {delay_id} not found', 404)
        
        return jsonify({
            'status': 'success',
            'data': delay
        }), 200
    except Exception as e:
        return error_response(str(e), 500)

@app.route('/api/schedules/<int:schedule_id>/delays', methods=['GET'])
def get_schedule_delays(schedule_id):
    """Get all delays for a specific schedule"""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        cur.execute('''SELECT delay_id, delay_minutes, reason, reported_at, is_active
                       FROM delays
                       WHERE schedule_id = ?
                       ORDER BY reported_at DESC''', (schedule_id,))
        
        delays = [dict(row) for row in cur.fetchall()]
        conn.close()
        
        return jsonify({
            'status': 'success',
            'data': delays
        }), 200
    except Exception as e:
        return error_response(str(e), 500)

@app.route('/api/delays', methods=['POST'])
def create_delay():
    """Report a new delay"""
    try:
        data = request.get_json()
        
        # Validate required fields
        if 'schedule_id' not in data or 'delay_minutes' not in data:
            return error_response('Missing required fields: schedule_id, delay_minutes', 400)
        
        conn = get_db_connection()
        cur = conn.cursor()
        
        cur.execute(
            '''INSERT INTO delays (schedule_id, delay_minutes, reason, is_active)
               VALUES (?, ?, ?, ?)''',
            (data['schedule_id'], data['delay_minutes'], data.get('reason'), True)
        )
        
        delay_id = cur.lastrowid
        conn.commit()
        conn.close()
        
        return jsonify({
            'status': 'success',
            'data': {'delay_id': delay_id, 'message': 'Delay reported successfully'}
        }), 201
    except Exception as e:
        return error_response(str(e), 500)

@app.route('/api/delays/<int:delay_id>', methods=['PUT'])
def update_delay(delay_id):
    """Update delay status"""
    try:
        data = request.get_json()
        
        conn = get_db_connection()
        cur = conn.cursor()
        
        if 'is_active' in data:
            if not data['is_active']:
                cur.execute(
                    '''UPDATE delays SET is_active = 0, resolved_at = CURRENT_TIMESTAMP
                       WHERE delay_id = ?''',
                    (delay_id,)
                )
            else:
                cur.execute(
                    '''UPDATE delays SET is_active = 1, resolved_at = NULL
                       WHERE delay_id = ?''',
                    (delay_id,)
                )
            conn.commit()
        
        conn.close()
        
        return jsonify({
            'status': 'success',
            'data': {'message': 'Delay updated successfully'}
        }), 200
    except Exception as e:
        return error_response(str(e), 500)

# ============================================================================
# SEARCH ENDPOINTS
# ============================================================================

@app.route('/api/search', methods=['GET'])
def search():
    """Search for routes and schedules"""
    try:
        query_str = request.args.get('q', '').strip()
        search_type = request.args.get('type', 'all')  # all, route, schedule
        
        if not query_str:
            return error_response('Search query cannot be empty', 400)
        
        conn = get_db_connection()
        cur = conn.cursor()
        
        results = {'routes': [], 'schedules': []}
        search_pattern = f'%{query_str}%'
        
        if search_type in ['all', 'route']:
            cur.execute('''SELECT * FROM routes
                          WHERE route_name LIKE ? OR operator LIKE ?
                          ORDER BY route_id''',
                       (search_pattern, search_pattern))
            results['routes'] = [dict(row) for row in cur.fetchall()]
        
        if search_type in ['all', 'schedule']:
            cur.execute('''SELECT s.schedule_id, s.route_id, r.route_name,
                                  ds.station_name as departure_station,
                                  asst.station_name as arrival_station,
                                  s.departure_time, s.arrival_time
                           FROM schedules s
                           JOIN routes r ON s.route_id = r.route_id
                           JOIN stations ds ON s.departure_station_id = ds.station_id
                           JOIN stations asst ON s.arrival_station_id = asst.station_id
                           WHERE r.route_name LIKE ? OR
                                 ds.station_name LIKE ? OR
                                 asst.station_name LIKE ?
                           ORDER BY s.schedule_id''',
                       (search_pattern, search_pattern, search_pattern))
            results['schedules'] = [dict(row) for row in cur.fetchall()]
        
        conn.close()
        
        return jsonify({
            'status': 'success',
            'data': results
        }), 200
    except Exception as e:
        return error_response(str(e), 500)

# ============================================================================
# APPLICATION ENTRY POINT
# ============================================================================

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
