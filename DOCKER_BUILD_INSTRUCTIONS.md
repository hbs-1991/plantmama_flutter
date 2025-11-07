# Docker Build Instructions for PlantMana Flutter App

This document provides step-by-step instructions for building and running your Flutter app in Docker containers.

## Prerequisites

- Docker installed on your system
- Docker Compose installed (optional, for easier management)

## Quick Start

### Method 1: Using Docker Compose (Recommended)

1. **Build and run the application:**
   ```bash
   docker-compose up --build
   ```

2. **Access the application:**
   - Open your browser and go to `http://localhost:8080`

3. **Stop the application:**
   ```bash
   docker-compose down
   ```

### Method 2: Using Docker directly

1. **Build the Docker image:**
   ```bash
   docker build -t plantmana-app .
   ```

2. **Run the container:**
   ```bash
   docker run -p 8080:80 --name plantmana-container plantmana-app
   ```

3. **Access the application:**
   - Open your browser and go to `http://localhost:8080`

4. **Stop and remove the container:**
   ```bash
   docker stop plantmana-container
   docker rm plantmana-container
   ```

## Production Deployment

### Using Docker Compose with Nginx Proxy

1. **Run with production profile:**
   ```bash
   docker-compose --profile production up --build -d
   ```

2. **Access the application:**
   - Main app: `http://localhost:8080`
   - Through proxy: `http://localhost:80`

### Environment Variables

You can customize the deployment using environment variables:

```bash
# Create a .env file
echo "PORT=8080" > .env
echo "NODE_ENV=production" >> .env

# Run with environment file
docker-compose --env-file .env up --build
```

## Docker Commands Reference

### Building
```bash
# Build without cache
docker build --no-cache -t plantmana-app .

# Build with specific tag
docker build -t plantmana-app:v1.0.0 .
```

### Running
```bash
# Run in background
docker run -d -p 8080:80 --name plantmana-container plantmana-app

# Run with environment variables
docker run -p 8080:80 -e NODE_ENV=production plantmana-app

# Run with volume mounting (for development)
docker run -p 8080:80 -v $(pwd)/build/web:/usr/share/nginx/html plantmana-app
```

### Management
```bash
# View running containers
docker ps

# View logs
docker logs plantmana-container

# Execute commands in container
docker exec -it plantmana-container sh

# Stop container
docker stop plantmana-container

# Remove container
docker rm plantmana-container

# Remove image
docker rmi plantmana-app
```

### Docker Compose Commands
```bash
# Start services
docker-compose up

# Start in background
docker-compose up -d

# Rebuild and start
docker-compose up --build

# Stop services
docker-compose down

# View logs
docker-compose logs

# Scale services
docker-compose up --scale plantmana-app=3
```

## Troubleshooting

### Common Issues

1. **Port already in use:**
   ```bash
   # Change port in docker-compose.yml or use different port
   docker run -p 8081:80 plantmana-app
   ```

2. **Build fails:**
   ```bash
   # Clean Docker cache
   docker system prune -a
   
   # Rebuild without cache
   docker build --no-cache -t plantmana-app .
   ```

3. **App not accessible:**
   - Check if container is running: `docker ps`
   - Check logs: `docker logs plantmana-container`
   - Verify port mapping: `docker port plantmana-container`

4. **Permission issues (Linux/Mac):**
   ```bash
   # Add user to docker group
   sudo usermod -aG docker $USER
   # Log out and back in
   ```

### Health Check

The application includes a health check endpoint:
- URL: `http://localhost:8080/health`
- Expected response: `healthy`

### Monitoring

```bash
# View container stats
docker stats plantmana-container

# View resource usage
docker system df

# View detailed container info
docker inspect plantmana-container
```

## Customization

### Modifying Nginx Configuration

1. Edit `nginx.conf` for the app container
2. Edit `nginx-proxy.conf` for the reverse proxy
3. Rebuild the containers

### Adding Environment Variables

1. Create a `.env` file in the project root
2. Add your variables:
   ```
   API_URL=https://api.plantmana.com
   DEBUG=false
   ```
3. Update `docker-compose.yml` to use the variables

### Multi-stage Build Optimization

The Dockerfile uses a multi-stage build:
1. **Build stage**: Compiles the Flutter web app
2. **Production stage**: Serves the app with nginx

This keeps the final image small and secure.

## Security Considerations

- The nginx configuration includes security headers
- The app runs as a non-root user in the container
- Static assets are properly cached
- Health checks are implemented for monitoring

## Performance Tips

- Use `docker-compose up --build` for development
- Use `docker-compose up -d` for production (detached mode)
- Consider using Docker volumes for persistent data
- Monitor resource usage with `docker stats`
