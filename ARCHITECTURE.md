# Public Transport Tracker - Architecture Design

## Overview
Public Transport Tracker is a multi-container application that allows users to check bus and train schedules, view real-time delays, and manage transport information efficiently.

## Microservices Architecture

### Service Components

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Browser                             │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Frontend Service                              │
│            (HTML/CSS/JavaScript via Nginx)                      │
│                   Runs on Port 80                                │
└────────────────────────┬────────────────────────────────────────┘
                         │ HTTP/REST (JSON)
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Backend API Service                            │
│              (Flask - Python Application)                        │
│              Runs on Port 5000                                   │
│  - Schedule Management                                          │
│  - Delay Tracking                                               │
│  - Route Information                                            │
└────────────────────────┬────────────────────────────────────────┘
                         │ TCP (PostgreSQL Protocol)
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                 Database Service                                 │
│            (PostgreSQL - Data Persistence)                       │
│              Runs on Port 5432                                   │
│  - Bus/Train Data                                               │
│  - Schedule Information                                         │
│  - Delay Records                                                │
└─────────────────────────────────────────────────────────────────┘
```

## Communication Protocols

### Frontend → Backend
- **Protocol**: HTTP REST with JSON
- **Base URL**: `http://backend-service:5000/api`
- **Content-Type**: `application/json`
- **Authentication**: Simple for now, can be enhanced

### Backend → Database
- **Protocol**: TCP (PostgreSQL native protocol)
- **Host**: `postgres-service`
- **Port**: `5432`
- **Connection String**: `postgresql://user:password@postgres-service:5432/transport_db`

## OpenShift Components

### DeploymentConfigs
- **frontend-dc**: Frontend service (Nginx)
- **backend-dc**: Flask API service
- **postgres-dc**: PostgreSQL database

### Services
- **frontend-service**: Routes traffic to frontend pods (NodePort or LoadBalancer)
- **backend-service**: Routes traffic to backend pods (ClusterIP)
- **postgres-service**: Routes traffic to database pods (ClusterIP)

### Routes
- **frontend-route**: Exposes frontend to external users
- **api-route**: Exposes backend API (optional, for direct API access)

### Persistent Storage
- **postgres-pvc**: PersistentVolumeClaim for database data

## Scaling Strategy

### Horizontal Scaling
- Frontend: Can scale to multiple pods (stateless)
- Backend: Can scale to multiple pods with load balancing
- Database: Single pod (PostgreSQL handles connections)

### Load Balancing
- OpenShift Routes handle automatic load balancing
- Backend API scales horizontally across multiple replicas

## Data Flow

1. **User Action**: User interacts with frontend (check schedule/delays)
2. **API Request**: Frontend sends HTTP REST request to backend
3. **Database Query**: Backend queries PostgreSQL for data
4. **Response**: Backend returns JSON to frontend
5. **Display**: Frontend renders data to user

## Security Considerations

- ConfigMaps for non-sensitive configuration
- Secrets for database credentials
- ClusterIP services for internal communication
- Limited RBAC permissions
- Container images from trusted registries

## Technology Stack Summary

| Component | Technology | Language | Port |
|-----------|-----------|----------|------|
| Frontend | Nginx + HTML/CSS/JS | JavaScript | 80 |
| Backend | Flask | Python | 5000 |
| Database | PostgreSQL | SQL | 5432 |
| Containerization | Docker/Podman | - | - |
| Orchestration | OpenShift | YAML | - |

## Next Steps

1. Define detailed data model
2. Plan API endpoints
3. Design database schema
4. Initialize Git repository
5. Develop microservices
6. Create Docker configurations
7. Build OpenShift manifests
8. Deploy and test
