# Public Transport Tracker - Main README

## 🚀 Public Transport Tracker

A modern, multi-container microservices application for tracking bus and train schedules, viewing delays, and managing transport information in real-time.

### 📋 Project Information

- **Course**: IT460 - Multi-Container Application Development
- **Objective**: Design and deploy a multi-container application on OpenShift
- **Status**: Development Phase

### 🏗️ Architecture

The application consists of three main microservices:

1. **Frontend Service** - HTML/CSS/JavaScript UI (Nginx)
   - Port: 80
   - User interface for schedules and delays
   
2. **Backend API Service** - Flask REST API (Python)
   - Port: 5000
   - Manages routes, stations, schedules, and delays
   
3. **Database Service** - PostgreSQL
   - Port: 5432
   - Persistent data storage

### 🛠️ Technology Stack

| Component | Technology | Language |
|-----------|-----------|----------|
| Frontend | Nginx + HTML5/CSS3/JavaScript | JavaScript |
| Backend | Flask | Python 3.9+ |
| Database | PostgreSQL | SQL |
| Container Runtime | Docker/Podman | - |
| Orchestration | OpenShift/Kubernetes | YAML |

### 📁 Project Structure

```
Public Transport Tracker/
├── backend/                    # Flask API service
│   ├── app.py                 # Main Flask application
│   ├── config.py              # Configuration management
│   ├── requirements.txt        # Python dependencies
│   └── Dockerfile             # Docker image definition
├── frontend/                   # Web UI service
│   ├── index.html            # Main HTML file
│   ├── css/
│   │   └── style.css         # Main stylesheet
│   ├── js/
│   │   ├── api.js            # API client
│   │   └── app.js            # Application logic
│   ├── Dockerfile            # Docker image definition
│   └── nginx.conf            # Nginx configuration
├── database/                   # PostgreSQL service
│   ├── init.sql              # Database initialization script
│   └── Dockerfile            # Docker image definition
├── k8s/                       # OpenShift/Kubernetes manifests
│   ├── frontend-dc.yaml      # Frontend DeploymentConfig
│   ├── backend-dc.yaml       # Backend DeploymentConfig
│   ├── postgres-dc.yaml      # Database DeploymentConfig
│   ├── services.yaml         # Kubernetes Services
│   ├── routes.yaml           # OpenShift Routes
│   ├── configmap.yaml        # ConfigMap for config
│   ├── secrets.yaml          # Secrets for credentials
│   ├── pvc.yaml              # PersistentVolumeClaims
│   └── docker-compose.yaml   # Local development compose file
├── docs/                      # Documentation
│   ├── DEPLOYMENT_GUIDE.md   # Deployment instructions
│   ├── API_ENDPOINTS.md      # API documentation
│   └── TROUBLESHOOTING.md    # Troubleshooting guide
├── ARCHITECTURE.md            # System architecture details
├── DATA_MODEL.md              # Database schema documentation
├── API_SPECIFICATION.md       # REST API specification
└── README.md                  # This file
```

### ✨ Features

#### Core Features
- 🚌 Browse available bus and train routes
- 📅 Check schedules with day/time filtering
- ⏰ Real-time delay tracking and reporting
- 🏢 Station and stop information
- 🔍 Search functionality for routes and schedules

#### Scalability Features
- Horizontal scaling for frontend and backend
- Load balancing via OpenShift Routes
- Database persistence across pod restarts
- Multi-replica deployment support

### 📊 Data Model

**Main Tables:**
- `routes` - Bus/train line information
- `stations` - Bus stops and train stations
- `schedules` - Service schedules
- `delays` - Real-time delay tracking
- `users` - User accounts (optional)
- `user_favorites` - User favorite routes (optional)

See [DATA_MODEL.md](DATA_MODEL.md) for complete schema details.

### 🔌 API Endpoints

#### Routes
- `GET /api/routes` - List all routes
- `GET /api/routes/{id}` - Get specific route
- `POST /api/routes` - Create new route

#### Stations
- `GET /api/stations` - List all stations
- `GET /api/stations/{id}` - Get specific station
- `POST /api/stations` - Create new station

#### Schedules
- `GET /api/schedules` - List schedules
- `GET /api/schedules/{id}` - Get schedule details
- `GET /api/routes/{id}/schedules` - Get route schedules
- `POST /api/schedules` - Create new schedule

#### Delays
- `GET /api/delays` - List active delays
- `GET /api/delays/{id}` - Get delay details
- `POST /api/delays` - Report new delay
- `PUT /api/delays/{id}` - Update delay status

#### Other
- `GET /api/search` - Search routes/schedules
- `GET /api/health` - Health check

See [API_SPECIFICATION.md](API_SPECIFICATION.md) for full documentation.

### 🚀 Quick Start

#### Prerequisites
- Docker or Podman
- Docker Compose
- Python 3.9+ (for local development)
- PostgreSQL client (psql)

#### Local Development with Docker Compose

1. **Clone/Navigate to project:**
   ```bash
   cd "Public Transport Tracker"
   ```

2. **Create environment file:**
   ```bash
   cp .env.example .env
   ```

3. **Start services:**
   ```bash
   docker-compose -f k8s/docker-compose.yaml up -d
   ```

4. **Access the application:**
   - Frontend: http://localhost
   - Backend API: http://localhost:5000/api
   - PostgreSQL: localhost:5432

5. **Stop services:**
   ```bash
   docker-compose -f k8s/docker-compose.yaml down
   ```

#### OpenShift Deployment

See [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md) for complete deployment instructions.

### 📝 API Usage Examples

#### Get all routes
```bash
curl http://localhost:5000/api/routes
```

#### Create a new route
```bash
curl -X POST http://localhost:5000/api/routes \
  -H "Content-Type: application/json" \
  -d '{
    "route_name": "BUS 101",
    "route_type": "bus",
    "operator": "CityBus",
    "start_station": "Central Park",
    "end_station": "Airport"
  }'
```

#### Get schedules for a route
```bash
curl "http://localhost:5000/api/routes/1/schedules"
```

#### Report a delay
```bash
curl -X POST http://localhost:5000/api/delays \
  -H "Content-Type: application/json" \
  -d '{
    "schedule_id": 1,
    "delay_minutes": 10,
    "reason": "Traffic congestion"
  }'
```

### 🐛 Troubleshooting

Common issues and solutions:
- **Database connection failed** - Ensure PostgreSQL is running and credentials are correct
- **Port already in use** - Change port mappings in docker-compose.yaml
- **API not responding** - Check backend logs: `docker logs backend-service`

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for more details.

### 📚 Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - System design and architecture
- [DATA_MODEL.md](DATA_MODEL.md) - Database schema details
- [API_SPECIFICATION.md](API_SPECIFICATION.md) - Complete API documentation
- [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md) - OpenShift deployment
- [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) - Project overview

### 🔄 CI/CD & Deployment

The project is designed for:
- Local development with Docker Compose
- Automated testing and building
- OpenShift deployment with DeploymentConfigs
- Horizontal scaling and load balancing

### 📈 Future Enhancements

- User authentication (JWT tokens)
- Real-time notifications (WebSockets)
- Mobile app (React Native/Flutter)
- Analytics dashboard
- Advanced search and filters
- Favorite routes tracking
- Push notifications

### 👥 Contributing

This is an educational project for IT460 course.

### 📄 License

Educational use only - January 2026

### 📞 Support

For issues and questions, refer to the documentation or troubleshooting guide.

---

**Last Updated**: January 4, 2026
**Status**: ✅ Development - Phase 2 Complete
