# Quick Start Guide

## For Local Development (5 minutes)

### Prerequisites
- Docker Desktop installed and running
- Git installed

### Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/public-transport-tracker.git
   cd "public-transport-tracker"
   ```

2. **Start all services**
   ```bash
   docker-compose -f k8s/docker-compose.yaml up -d
   ```

3. **Wait for services to start** (about 30 seconds)
   ```bash
   docker-compose -f k8s/docker-compose.yaml ps
   ```

4. **Access the application**
   - Frontend: http://localhost
   - API: http://localhost:5000/api
   - API Health: http://localhost:5000/api/health

5. **Test the application**
   ```bash
   # Get all routes
   curl http://localhost:5000/api/routes
   
   # Get schedules
   curl http://localhost:5000/api/schedules
   ```

6. **Stop services**
   ```bash
   docker-compose -f k8s/docker-compose.yaml down
   ```

---

## For OpenShift Deployment (30 minutes)

### Prerequisites
- OpenShift cluster access (oc command-line tool)
- Docker images pushed to a registry

### Steps

1. **Prepare images**
   ```bash
   docker build -t your-registry/ptt-backend:latest ./backend
   docker build -t your-registry/ptt-frontend:latest ./frontend
   docker build -t your-registry/ptt-postgres:latest ./database
   docker push your-registry/ptt-backend:latest
   docker push your-registry/ptt-frontend:latest
   docker push your-registry/ptt-postgres:latest
   ```

2. **Update manifest files**
   - Edit `k8s/00-namespace-config-secret.yaml`
   - Change image references to your registry
   - Update database passwords
   - Change route hostnames

3. **Login to OpenShift**
   ```bash
   oc login https://your-cluster:6443
   ```

4. **Deploy**
   ```bash
   oc apply -f k8s/00-namespace-config-secret.yaml
   oc apply -f k8s/01-routes.yaml
   oc apply -f k8s/02-autoscaling.yaml
   ```

5. **Verify deployment**
   ```bash
   oc get pods -n transport-tracker
   oc get routes -n transport-tracker
   ```

6. **Access the application**
   ```bash
   # Get URLs
   oc get route -n transport-tracker
   ```

---

## Project Files Structure

```
Public Transport Tracker/
├── backend/              # Flask API
│   ├── app.py           # Main application (900+ lines)
│   ├── config.py        # Configuration
│   ├── requirements.txt  # Python dependencies
│   └── Dockerfile       # Docker image
├── frontend/            # Nginx + UI
│   ├── index.html       # Main page
│   ├── css/style.css    # Styling (600+ lines)
│   ├── js/
│   │   ├── api.js       # API client (400+ lines)
│   │   └── app.js       # Logic (700+ lines)
│   ├── Dockerfile       # Docker image
│   └── nginx.conf       # Web server config
├── database/            # PostgreSQL
│   ├── init.sql         # Schema (400+ lines)
│   └── Dockerfile       # Docker image
├── k8s/                 # OpenShift manifests
│   ├── 00-*.yaml        # Namespace, config, services
│   ├── 01-*.yaml        # Routes for external access
│   ├── 02-*.yaml        # Autoscaling
│   └── docker-compose.yaml # Local development
├── docs/                # Documentation
│   ├── DEPLOYMENT_GUIDE.md
│   ├── DOCKER_SETUP_GUIDE.md
│   ├── OPENSHIFT_DEPLOYMENT_GUIDE.md
│   └── DOCKER_INSTRUCTIONS.md
├── ARCHITECTURE.md      # System design
├── DATA_MODEL.md        # Database schema
├── API_SPECIFICATION.md # REST API docs
├── PROJECT_REPORT.md    # This project report
├── README.md            # Project overview
└── .gitignore          # Git ignore rules
```

---

## Key Documentation Files

| File | Purpose | Read Time |
|------|---------|-----------|
| README.md | Project overview | 10 min |
| ARCHITECTURE.md | System design | 10 min |
| API_SPECIFICATION.md | API endpoints | 15 min |
| DOCKER_SETUP_GUIDE.md | Local testing | 20 min |
| OPENSHIFT_DEPLOYMENT_GUIDE.md | Production deploy | 30 min |
| PROJECT_REPORT.md | Complete report | 20 min |

---

## Common Tasks

### Add a new route
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

### Report a delay
```bash
curl -X POST http://localhost:5000/api/delays \
  -H "Content-Type: application/json" \
  -d '{
    "schedule_id": 1,
    "delay_minutes": 10,
    "reason": "Traffic congestion"
  }'
```

### Check API health
```bash
curl http://localhost:5000/api/health
```

### View database
```bash
psql -h localhost -U postgres -d transport_db
```

---

## Troubleshooting

### Services won't start
```bash
# Check if ports are in use
netstat -ano | findstr :80
netstat -ano | findstr :5000
netstat -ano | findstr :5432

# View logs
docker-compose -f k8s/docker-compose.yaml logs
```

### Database connection error
```bash
# Wait for database to initialize
docker-compose -f k8s/docker-compose.yaml logs postgres

# Restart backend service
docker-compose -f k8s/docker-compose.yaml restart backend
```

### Frontend can't connect to API
- Ensure backend is running: curl http://localhost:5000/api/health
- Check firewall settings
- Verify API endpoint in browser console (F12)

---

## Performance Tips

### Local Testing
- Use Docker Compose with default settings
- Allocate 4GB RAM for Docker
- Use SSD for database volume

### OpenShift Deployment
- Start with 2 replicas for frontend/backend
- Monitor CPU and memory usage
- HPA will automatically scale based on demand
- Use resource quotas to limit namespace usage

---

## Security Checklist

- [ ] Change default database password
- [ ] Update SECRET_KEY in production
- [ ] Enable HTTPS on routes
- [ ] Implement network policies
- [ ] Set resource limits
- [ ] Regular security updates
- [ ] Monitor and log access
- [ ] Backup database regularly

---

## Next Steps

1. **Test Locally**: Follow "For Local Development" section
2. **Review Code**: Check API and frontend implementations
3. **Deploy to Dev**: Use "For OpenShift Deployment" section
4. **Load Testing**: Test with multiple concurrent users
5. **Production**: Deploy with proper backups and monitoring

---

## Support

- Check README.md for overview
- See ARCHITECTURE.md for design details
- Review API_SPECIFICATION.md for endpoint docs
- Consult OPENSHIFT_DEPLOYMENT_GUIDE.md for deployment
- Check Docker logs for runtime issues

---

**Ready to deploy?** Start with local testing, then move to OpenShift! 🚀
