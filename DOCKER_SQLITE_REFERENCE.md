# Docker SQLite Deployment - Quick Reference

## Current Status ✅

The application is now running with **SQLite database** instead of PostgreSQL.

### Running Containers

| Container | Status | Port | Description |
|-----------|--------|------|-------------|
| `ptt-backend` | ✅ Healthy | 5000 | Flask API with SQLite |
| `ptt-frontend` | ✅ Running | 80 | Nginx serving static files |
| `ptt-postgres` | ⚪ Orphaned | 5432 | PostgreSQL (not in use, can be removed) |

### Database Information

- **Type**: SQLite
- **Location**: `/app/database/transport_db.sqlite` (inside container)
- **Size**: 116KB
- **Volume**: `k8s_sqlite_data` (Docker volume for persistence)

### Current Data

- **Routes**: 3 (2 bus, 1 train)
- **Stations**: 4 (2 bus stops, 2 train stations)
- **Schedules**: 3
- **Delays**: 1

## Access URLs

- **Frontend**: http://localhost
- **Backend API**: http://localhost:5000/api
- **Health Check**: http://localhost:5000/api/health

## Common Commands

### Check Container Status
```powershell
docker ps --filter "name=ptt"
```

### View Logs
```powershell
# Backend logs
docker logs ptt-backend

# Frontend logs
docker logs ptt-frontend

# Follow logs in real-time
docker logs -f ptt-backend
```

### Restart Containers
```powershell
cd "C:\Users\HP\OneDrive - Ministere de l'Enseignement Superieur et de la Recherche Scientifique\Desktop\Cloud-Transport-Tracker\public-transport-tracker"

# Restart all services
docker-compose -f k8s/docker-compose.yaml restart

# Restart specific service
docker restart ptt-backend
docker restart ptt-frontend
```

### Rebuild and Restart
```powershell
# Stop containers
docker-compose -f k8s/docker-compose.yaml down

# Rebuild and start
docker-compose -f k8s/docker-compose.yaml up -d --build
```

### Database Management

#### Access SQLite database
```powershell
# Enter backend container
docker exec -it ptt-backend bash

# Inside container, access SQLite
sqlite3 /app/database/transport_db.sqlite

# SQLite commands
.tables                    # List all tables
.schema routes             # Show table schema
SELECT * FROM routes;      # Query data
.quit                      # Exit SQLite
```

#### Backup Database
```powershell
docker cp ptt-backend:/app/database/transport_db.sqlite ./backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').sqlite
```

#### Restore Database
```powershell
docker cp ./backup.sqlite ptt-backend:/app/database/transport_db.sqlite
docker restart ptt-backend
```

### Test API
```powershell
# Run the test script
.\test_api.ps1

# Manual API tests
Invoke-WebRequest -Uri http://localhost:5000/api/health -UseBasicParsing
Invoke-WebRequest -Uri http://localhost:5000/api/routes -UseBasicParsing
Invoke-WebRequest -Uri http://localhost:5000/api/stations -UseBasicParsing
```

### Add Sample Data

#### Add a Route
```powershell
Invoke-WebRequest -Uri http://localhost:5000/api/routes -Method POST -ContentType "application/json" -Body '{"route_name":"Bus Line 5","route_type":"bus","operator":"STPT","start_station":"Station A","end_station":"Station B"}' -UseBasicParsing
```

#### Add a Station
```powershell
Invoke-WebRequest -Uri http://localhost:5000/api/stations -Method POST -ContentType "application/json" -Body '{"station_name":"Station Name","station_type":"bus_stop","latitude":36.8065,"longitude":10.1815,"address":"Address"}' -UseBasicParsing
```

#### Add a Schedule
```powershell
Invoke-WebRequest -Uri http://localhost:5000/api/schedules -Method POST -ContentType "application/json" -Body '{"route_id":1,"departure_station_id":1,"arrival_station_id":2,"departure_time":"08:00:00","arrival_time":"09:00:00","day_of_week":"Monday","frequency":30}' -UseBasicParsing
```

#### Add a Delay
```powershell
Invoke-WebRequest -Uri http://localhost:5000/api/delays -Method POST -ContentType "application/json" -Body '{"schedule_id":1,"delay_minutes":10,"reason":"Technical issue"}' -UseBasicParsing
```

## Volume Management

### List Volumes
```powershell
docker volume ls
```

### Inspect SQLite Volume
```powershell
docker volume inspect k8s_sqlite_data
```

### Remove Old PostgreSQL Volume (if not needed)
```powershell
# Stop postgres container first
docker stop ptt-postgres
docker rm ptt-postgres

# Remove volume
docker volume rm k8s_postgres_data
```

## Troubleshooting

### Backend won't start
```powershell
# Check logs
docker logs ptt-backend

# Rebuild container
docker-compose -f k8s/docker-compose.yaml up -d --build backend
```

### Database connection errors
```powershell
# Check database file exists and has correct permissions
docker exec ptt-backend ls -lh /app/database/

# Check database file size
docker exec ptt-backend stat /app/database/transport_db.sqlite
```

### Frontend not loading data
1. Check backend is healthy: http://localhost:5000/api/health
2. Check browser console for errors (F12)
3. Verify CORS is working: API should return `Access-Control-Allow-Origin: *`
4. Test API directly: `Invoke-WebRequest -Uri http://localhost:5000/api/routes -UseBasicParsing`

### Reset Everything
```powershell
# Stop and remove containers with volumes
docker-compose -f k8s/docker-compose.yaml down -v

# Rebuild and start fresh
docker-compose -f k8s/docker-compose.yaml up -d --build
```

## File Locations

### Configuration Files
- `backend/app.py` - Backend application code
- `backend/Dockerfile` - Backend container configuration
- `frontend/nginx.conf` - Nginx configuration
- `k8s/docker-compose.yaml` - Docker Compose configuration

### Database
- Container path: `/app/database/transport_db.sqlite`
- Volume: `k8s_sqlite_data`

## Notes

- PostgreSQL service is commented out in docker-compose.yaml but kept for future use
- SQLite is suitable for development and small deployments
- Data persists in Docker volume `k8s_sqlite_data`
- Backend automatically creates database schema on first run
- For production, consider switching back to PostgreSQL for better concurrency

## Next Steps

1. ✅ Application is running with SQLite
2. ✅ Sample data has been added
3. ✅ Frontend and Backend are communicating
4. 🔄 You can now test the application at http://localhost
5. 📝 Add more data as needed using the API endpoints
6. 🚀 For production, switch back to PostgreSQL by uncommenting the postgres service in docker-compose.yaml
