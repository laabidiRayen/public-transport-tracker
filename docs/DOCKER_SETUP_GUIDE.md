# Docker Setup and Testing Guide

## Prerequisites

Before running Docker Compose, ensure:
- Docker Desktop is installed and running
- Docker Compose is available
- At least 4GB of free disk space
- Ports 80, 5000, and 5432 are available

## Installation (if needed)

### Windows
- Download Docker Desktop from: https://www.docker.com/products/docker-desktop
- Install and restart your computer
- Verify installation: `docker --version`

### macOS
- Download Docker Desktop from: https://www.docker.com/products/docker-desktop
- Install and verify: `docker --version`

### Linux
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker $USER
```

## Building Docker Images

### Step 1: Navigate to project directory
```powershell
cd "C:\Users\abidi\OneDrive\Bureau\senior\Cloud\project\Public Transport Tracker"
```

### Step 2: Build images using Docker Compose
```powershell
docker-compose -f k8s/docker-compose.yaml build
```

This will build three images:
- `ptt-postgres:latest` - PostgreSQL database
- `ptt-backend:latest` - Flask API
- `ptt-frontend:latest` - Nginx web server

### Step 3: Start all services
```powershell
docker-compose -f k8s/docker-compose.yaml up -d
```

### Verify services are running
```powershell
docker-compose -f k8s/docker-compose.yaml ps
```

You should see all three services with status "running"

## Testing the Application

### 1. Test Frontend
Open browser: http://localhost

You should see the Public Transport Tracker UI with:
- Header with application title
- Navigation tabs (Routes, Schedules, Delays, Stations)
- Status indicator (bottom right)

### 2. Test Backend API

#### Health check
```powershell
curl http://localhost:5000/api/health
```

Expected response:
```json
{
  "status": "healthy",
  "service": "public-transport-tracker-api",
  "database": "connected"
}
```

#### Get all routes
```powershell
curl http://localhost:5000/api/routes
```

#### Get all stations
```powershell
curl http://localhost:5000/api/stations
```

#### Get schedules
```powershell
curl http://localhost:5000/api/schedules
```

#### Get active delays
```powershell
curl http://localhost:5000/api/delays
```

### 3. Test Database Connection

```powershell
# Install PostgreSQL client (if needed)
# Download from: https://www.postgresql.org/download/

psql -h localhost -U postgres -d transport_db -c "\dt"
```

This should list all tables (routes, stations, schedules, delays, users, user_favorites)

## Viewing Logs

### View all logs
```powershell
docker-compose -f k8s/docker-compose.yaml logs -f
```

### View specific service logs
```powershell
# Backend logs
docker-compose -f k8s/docker-compose.yaml logs -f backend

# Frontend logs
docker-compose -f k8s/docker-compose.yaml logs -f frontend

# Database logs
docker-compose -f k8s/docker-compose.yaml logs -f postgres
```

## Stopping Services

### Stop all services
```powershell
docker-compose -f k8s/docker-compose.yaml down
```

### Stop and remove all data
```powershell
docker-compose -f k8s/docker-compose.yaml down -v
```

## Troubleshooting

### Port already in use
```powershell
# Check what's using the port
netstat -ano | findstr :80
netstat -ano | findstr :5000
netstat -ano | findstr :5432

# Stop the process using the port or use different ports
# Edit docker-compose.yaml and change port mappings
```

### Container not starting
```powershell
# Check logs
docker-compose -f k8s/docker-compose.yaml logs postgres
docker-compose -f k8s/docker-compose.yaml logs backend
docker-compose -f k8s/docker-compose.yaml logs frontend

# Restart a specific service
docker-compose -f k8s/docker-compose.yaml restart backend
```

### Database connection failed
```powershell
# Verify database is running
docker-compose -f k8s/docker-compose.yaml logs postgres

# Wait a few seconds for database to fully initialize
# Then restart backend
docker-compose -f k8s/docker-compose.yaml restart backend
```

### Cannot connect to Docker daemon
- Ensure Docker Desktop is running
- On Windows, check that Hyper-V is enabled
- Try: `docker ps` to verify Docker is accessible

## Environment Variables

The default credentials are set in docker-compose.yaml:
- Database: `transport_db`
- Username: `postgres`
- Password: `postgres`

To change credentials, edit `k8s/docker-compose.yaml` before building:
```yaml
environment:
  POSTGRES_PASSWORD: your_new_password
  DB_PASSWORD: your_new_password
```

## Production Considerations

For production deployments:
1. Change all default passwords
2. Use environment variable files (.env)
3. Configure proper logging
4. Set resource limits
5. Use production-grade web server
6. Enable HTTPS/TLS
7. Use managed databases
8. Implement backup strategies

## Next Steps

Once testing is complete:
1. Push Docker images to a registry (Docker Hub, ECR, etc.)
2. Create OpenShift manifests
3. Deploy to OpenShift cluster
4. Configure routes and networking
5. Set up monitoring and logging

## Useful Docker Commands

```powershell
# List all containers
docker ps -a

# List all images
docker images

# Remove a container
docker rm container_name

# Remove an image
docker rmi image_name

# Clean up unused resources
docker system prune -a

# View container resource usage
docker stats

# Execute command in running container
docker exec -it ptt-backend sh
```

## Resources

- Docker Documentation: https://docs.docker.com
- Docker Compose Reference: https://docs.docker.com/compose/compose-file
- PostgreSQL Documentation: https://www.postgresql.org/docs
- Flask Documentation: https://flask.palletsprojects.com
