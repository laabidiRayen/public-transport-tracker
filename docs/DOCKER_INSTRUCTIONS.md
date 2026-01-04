# Docker Build and Run Instructions for Public Transport Tracker

## Building Docker Images

### Build all images:
```bash
cd "Public Transport Tracker"

# Backend
docker build -t ptt-backend:latest ./backend

# Frontend
docker build -t ptt-frontend:latest ./frontend

# Database
docker build -t ptt-postgres:latest ./database
```

### Or use Docker Compose (recommended):
```bash
docker-compose -f k8s/docker-compose.yaml build
```

## Running Services

### Using Docker Compose (Recommended):
```bash
# Start all services
docker-compose -f k8s/docker-compose.yaml up -d

# View logs
docker-compose -f k8s/docker-compose.yaml logs -f

# Stop services
docker-compose -f k8s/docker-compose.yaml down

# Stop services and remove volumes
docker-compose -f k8s/docker-compose.yaml down -v
```

### Manual Docker Commands:

1. **Start Database:**
```bash
docker run -d \
  --name ptt-postgres \
  -e POSTGRES_DB=transport_db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  -v postgres_data:/var/lib/postgresql/data \
  ptt-postgres:latest
```

2. **Start Backend:**
```bash
docker run -d \
  --name ptt-backend \
  -e DB_HOST=ptt-postgres \
  -e DB_PORT=5432 \
  -e DB_NAME=transport_db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -p 5000:5000 \
  --link ptt-postgres:postgres \
  ptt-backend:latest
```

3. **Start Frontend:**
```bash
docker run -d \
  --name ptt-frontend \
  -p 80:80 \
  --link ptt-backend:backend \
  ptt-frontend:latest
```

## Accessing the Application

- **Frontend**: http://localhost
- **Backend API**: http://localhost:5000/api
- **Database**: localhost:5432

## Testing Services

### Check service health:
```bash
# Frontend
curl http://localhost

# Backend API
curl http://localhost:5000/api/health

# Database
psql -h localhost -U postgres -d transport_db -c "\dt"
```

### View logs:
```bash
docker logs ptt-frontend
docker logs ptt-backend
docker logs ptt-postgres
```

## Cleanup

```bash
# Stop and remove containers
docker-compose -f k8s/docker-compose.yaml down

# Remove images
docker rmi ptt-frontend:latest ptt-backend:latest ptt-postgres:latest

# Remove all unused resources
docker system prune -a
```
