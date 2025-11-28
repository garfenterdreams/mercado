# Garfenter Mercado - Spurt Commerce Marketplace

## Overview

This is **Garfenter Mercado**, a multi-vendor marketplace platform based on Spurt Commerce 5.2.0. It provides a complete e-commerce solution with admin panel, vendor/seller panel, and REST API.

## Architecture

This repository contains a **full-stack application** deployed as a **single Docker container**:

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Container                          │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                    nginx (port 80)                   │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │    │
│  │  │   /admin    │  │   /seller   │  │    /api     │  │    │
│  │  │  (Angular)  │  │  (Angular)  │  │   (proxy)   │  │    │
│  │  └─────────────┘  └─────────────┘  └──────┬──────┘  │    │
│  └───────────────────────────────────────────┼─────────┘    │
│                                              │               │
│  ┌───────────────────────────────────────────▼─────────┐    │
│  │              Node.js API (port 8000)                │    │
│  │              Spurt Commerce Backend                  │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### Components

1. **Backend API** (`src/`)
   - Node.js/TypeScript REST API
   - Spurt Commerce 5.2.0
   - Runs on port 8000 internally
   - MySQL database connection

2. **Admin Panel** (`frontend/admin/`)
   - Pre-built Angular application
   - Served by nginx at `/admin`
   - For marketplace administrators

3. **Vendor/Seller Panel** (`frontend/seller/`)
   - Pre-built Angular application
   - Served by nginx at `/seller` and `/vendor`
   - For vendors/sellers to manage their stores

4. **nginx** (container entrypoint)
   - Serves frontend static files
   - Proxies `/api` requests to Node.js backend
   - Proxies `/socket.io` for real-time features
   - Landing page at `/`

## Key Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Builds the complete image with API + frontend + nginx |
| `nginx.conf` | nginx configuration for routing and proxying |
| `entrypoint.sh` | Container startup script (MySQL wait, nginx, API) |
| `.github/workflows/deploy.yml` | GitHub Actions CI/CD to ECR |
| `frontend/admin/` | Pre-built Admin panel (Angular) |
| `frontend/seller/` | Pre-built Vendor panel (Angular) |
| `src/` | Backend API source code |

## Deployment

### GitHub Actions CI/CD

On push to `master`, GitHub Actions:
1. Builds the Docker image
2. Pushes to ECR: `144656353217.dkr.ecr.us-east-1.amazonaws.com/garfenter/mercado`
3. Tags: `latest` and commit SHA

### Running the Container

```bash
docker run -d --name garfenter-mercado \
  --network garfenter-network \
  -p 8080:80 \
  -e TYPEORM_HOST=garfenter-mysql \
  -e TYPEORM_PORT=3306 \
  -e TYPEORM_USERNAME=garfenter \
  -e TYPEORM_PASSWORD=<mysql-password> \
  -e TYPEORM_DATABASE=garfenter_mercado \
  144656353217.dkr.ecr.us-east-1.amazonaws.com/garfenter/mercado:latest
```

### Environment Variables

Key environment variables (see Dockerfile for full list):

| Variable | Default | Description |
|----------|---------|-------------|
| `TYPEORM_HOST` | mysql-database | MySQL host |
| `TYPEORM_PASSWORD` | - | MySQL password (required) |
| `TYPEORM_DATABASE` | spurtcommerce | Database name |
| `IMAGE_SERVER` | local | Storage: `local` or `s3` |
| `AWS_DEFAULT_REGION` | us-east-1 | AWS region for S3 |
| `JWT_SECRET` | - | JWT signing secret |
| `JWT_EXPIRY_TIME` | 7d | JWT token expiry |

## URLs

| URL | Description |
|-----|-------------|
| `/` | Landing page with links to panels |
| `/admin/` | Admin panel login |
| `/seller/` | Vendor/Seller panel login |
| `/api` | REST API base |
| `/api/swagger` | Swagger API documentation |
| `/health` | Health check endpoint |

## Database

- MySQL 8.0 required
- Schema: `spurtcommerce_v5.2_community.sql`
- Auto-initialized on first container start if database is empty

## Frontend Updates

The frontend panels in `frontend/` are pre-built Angular applications extracted from `spurtcommerce/web-ui:5.1.0`.

To update frontend:
1. Pull new `spurtcommerce/web-ui` image
2. Extract `frontend/admin` and `frontend/seller`
3. Update API URLs from `http://localhost:8000/api` to `/api`
4. Commit and push

## Tests

Playwright E2E tests: `/Users/garfenter/development/products/garfenter-tests/e2e/tests/products/mercado.spec.ts`

```bash
cd /Users/garfenter/development/products/garfenter-tests/e2e
npx playwright test tests/products/mercado.spec.ts
```

## Production URL

- **Live**: https://mercado.garfenter.com
- **Admin**: https://mercado.garfenter.com/admin/
- **Vendor**: https://mercado.garfenter.com/seller/
- **API**: https://mercado.garfenter.com/api

## Default Credentials

Check the database seed data or Spurt Commerce documentation for default admin credentials.
