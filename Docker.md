# Docker Configuration for AL-Chat

This document describes how to run AL-Chat using Docker containers for isolated deployment and easy integration with the main website project.

## Overview

AL-Chat is containerized to allow:
- Independent updates without affecting other parts of the project
- Consistent deployment across environments
- Easy integration with the main website's Docker setup

## Structure

- `Backend/Dockerfile` - Backend Flask API container
- `docker-compose.yml` - Local development orchestration (backend only)
- `docker-compose.staging.yml` - Staging environment configuration
- `docker-compose.production.yml` - Production environment configuration
- `.dockerignore` - Files excluded from Docker builds

**Note:** Frontend is handled by the main website project. This is a backend-only service.

## Quick Start

### Local Development with Docker Compose

1. **Create `.env` file** (optional, for local testing):
   ```bash
   # In project root
   echo "OPENAI_API_KEY=sk-your-key-here" > .env
   echo "OPENAI_MODEL=gpt-3.5-turbo" >> .env
   ```

2. **Build and start containers**:
   ```bash
   docker-compose up --build
   ```

3. **Access the backend**:
   - API: `http://localhost:5000`
   - Health check: `http://localhost:5000/api/health`

4. **Stop containers**:
   ```bash
   docker-compose down
   ```

### Building Backend Container Only

```bash
cd Backend
docker build -t al-chat-backend .
docker run -p 5000:5000 -e OPENAI_API_KEY=sk-your-key-here al-chat-backend
```

## Integration with Main Website

### Option 1: Add to Main Website's docker-compose.yml

Add AL-Chat as a service in your main website's `docker-compose.yml`:

```yaml
services:
  # ... your existing services ...
  
  al-chat-backend:
    build:
      context: ./path/to/AL-Chat/Backend
      dockerfile: Dockerfile
    container_name: al-chat-backend
    ports:
      - "5000:5000"  # Or use internal network only
    environment:
      - FLASK_ENV=production
      - OPENAI_API_KEY=${OPENAI_API_KEY}  # From main site's .env
      # Or omit this - main site will pass via flask.g
    volumes:
      - ./al-chat-logs:/app/SessionLog
    networks:
      - main-website-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/api/health"]
      interval: 30s
      timeout: 10s
```

### Option 2: Use Pre-built Image

Build and push to a registry, then reference from main site:

```bash
# Build and tag
docker build -t al-chat-backend:latest ./Backend

# Push to registry (example with Docker Hub)
docker tag al-chat-backend:latest yourregistry/al-chat-backend:latest
docker push yourregistry/al-chat-backend:latest
```

Then in main website's docker-compose:
```yaml
al-chat-backend:
  image: yourregistry/al-chat-backend:latest
  # ... rest of config
```

## Environment Variables

### Backend Container

- `OPENAI_API_KEY` - OpenAI API key (for local testing, optional in production)
- `OPENAI_MODEL` - Model to use (default: `gpt-3.5-turbo`)
- `FLASK_ENV` - Flask environment (`development` or `production`)
- `PORT` - Port to listen on (default: `5000`)
- `AL_CHAT_LOG_DIR` - Directory for session logs (default: `/app/SessionLog`)

### Production Configuration

In production with the main website:
- **Local Testing**: Set `OPENAI_API_KEY` in `.env` or docker-compose
- **Production**: Main website passes user's API key via `flask.g.openai_api_key`

## Volumes

### Session Logs

Session logs can be persisted using volumes:

```yaml
volumes:
  - ./SessionLog:/app/SessionLog
```

This allows logs to survive container restarts.

## Health Checks

The backend includes a health check endpoint:
- **Endpoint**: `GET /api/health`
- **Docker**: Configured in docker-compose with 30s interval

## Networking

### Standalone (Local Development)
- Backend accessible on `localhost:5000`
- Frontend connects to backend via `localhost:5000`

### Integrated (Main Website)
- Backend accessible on internal Docker network
- Main website reverse proxy routes `/api/al-chat/*` to backend
- No external port exposure needed

## Updating AL-Chat Container

To update AL-Chat without affecting other containers:

```bash
# Rebuild just the AL-Chat service
docker-compose build al-chat-backend
docker-compose up -d al-chat-backend

# Or if using main website's compose
docker-compose build al-chat-backend
docker-compose restart al-chat-backend
```

## Troubleshooting

### Container won't start
- Check logs: `docker-compose logs al-chat-backend`
- Verify environment variables are set
- Ensure port 5000 is not in use: `docker ps`

### Health check failing
- Check if backend is responding: `curl http://localhost:5000/api/health`
- Review container logs for errors
- Verify OpenAI API key is valid (for local testing)

### Session logs not persisting
- Verify volume mount is configured correctly
- Check directory permissions on host: `ls -la SessionLog/`

## Development Tips

1. **Use docker-compose for local testing**: Keeps environment consistent
2. **Mount source code as volume** (development only):
   ```yaml
   volumes:
     - ./Backend:/app
   ```
   This allows code changes without rebuilding.

3. **Separate staging/production configs**: Use `docker-compose.prod.yml` for production overrides.
