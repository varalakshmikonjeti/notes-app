# Notes App — DevOps Assessment

## Live Demo
- **App URL**: https://notes-app-fs84.onrender.com
- **Health Check**: https://notes-app-fs84.onrender.com/health

## Architecture Overview

```
Internet
   ↓
SSL (Let's Encrypt via Render)
   ↓
Render Web Service
(Docker Container - Flask App)
   ↓
Render PostgreSQL (Managed Database)
```

## Tech Stack
- **App**: Python Flask
- **Database**: PostgreSQL (Render Managed)
- **Containerization**: Docker + Docker Compose
- **CI/CD**: Jenkins (port 9090)
- **SSL**: Automatic via Render (Let's Encrypt)
- **Hosting**: Render

## Instance Size Justification
Render Free tier used (512MB RAM, 0.1 CPU).
In a production AWS environment, t3.micro would be selected for:
- Low traffic application
- 1GB RAM sufficient for Flask + gunicorn
- Free tier eligible for new accounts

## Port Justification
| Port | Service | Reason |
|------|---------|--------|
| 80 | HTTP | Public web traffic |
| 443 | HTTPS | Secure public web traffic |
| 5000 | Flask App | Internal only, behind reverse proxy |
| 5432 | PostgreSQL | Internal only, app server access only |
| 9090 | Jenkins | Non-default port, restricted to specific IP |

## Security Group Design (AWS Reference)
| Port | Source | Reason |
|------|--------|--------|
| 80 | 0.0.0.0/0 | Public HTTP traffic required |
| 443 | 0.0.0.0/0 | Public HTTPS traffic required |
| 22 | My IP only | SSH restricted, not open to world |
| 9090 | My IP only | Jenkins UI restricted to admin IP |
| 5432 | App server security group only | DB never exposed to public internet |

Note: No port other than 80/443 is open to 0.0.0.0/0.
SSH is restricted to specific IP range only.

## Rollback Logic
- After every deployment, /health endpoint is called
- **Max retries**: 5
- **Wait before first check**: 15 seconds (app startup time)
- **Timeout per attempt**: 10 seconds
- **Wait between retries**: 10 seconds
- **HTTP 200** = healthy → deployment successful
- **Anything else** = unhealthy → automatic rollback to previous image
- Rollback uses previously tagged image (notes-app-prev)
- If no previous image exists, rollback fails with clear error message

## Secrets Handling
- No credentials committed to repository at any point
- All secrets passed via environment variables
- `.env` file is in `.gitignore`
- `.env.example` contains placeholder values only
- **At build time**: no secrets in image layers
- **At deploy time**: secrets injected via `-e` flag
- **At runtime**: app reads from environment variables
- Jenkins credentials stored as pipeline environment variables, not in code

## Local vs Production Database
- **Local**: docker-compose runs PostgreSQL container for development parity
- **Production**: Render managed PostgreSQL used
- **Why managed DB in production**:
  - Automated backups
  - High availability
  - Security patching handled by provider
  - Data persists independent of app container
- **Risk of docker-compose DB in production**:
  - Data lost if container restarts
  - No automated backups
  - No high availability
  - Single point of failure

## Deploy/Rollback Downtime
- **Current strategy**: in-place deployment with container replacement
- **Downtime during deploy**: ~5-10 seconds while old container stops and new one starts
- **Downtime during rollback**: ~5-10 seconds while switching to previous image
- **In-flight requests**: will receive connection reset during this window
- **Future improvement**: blue-green deployment for zero downtime

## IAM Scoping (AWS Reference)
Due to lack of access to a billing-enabled cloud account, IAM configuration is documented below as it would be implemented on AWS:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeSecurityGroups",
        "rds:DescribeDBInstances",
        "logs:GetLogEvents",
        "logs:DescribeLogGroups"
      ],
      "Resource": "*"
    }
  ]
}
```

### Why each permission:
- `ec2:DescribeInstances` → reviewer can verify instance type and config
- `ec2:DescribeSecurityGroups` → reviewer can verify firewall rules
- `rds:DescribeDBInstances` → reviewer can verify managed DB setup
- `logs:GetLogEvents` → reviewer can read application logs
- `logs:DescribeLogGroups` → reviewer can list available log groups

Note: Broad ReadOnlyAccess managed policy was NOT used. Permissions are deliberately scoped to only what is needed for review.

## SSL Certificate Renewal
- SSL provided automatically by Render via Let's Encrypt
- Certificates auto-renew before expiry
- No manual intervention required
- In AWS setup: certbot timer would handle renewal every 12 hours

## Local Setup
1. Clone the repository
2. Copy `.env.example` to `.env` and fill in values
3. Run `docker-compose up --build`
4. App available at `http://localhost:5000`
5. Health check at `http://localhost:5000/health`

## API Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /health | Health check — returns app + DB status |
| POST | /notes | Create a new note |
| GET | /notes | Get all notes |
| GET | /notes/:id | Get single note by ID |
| PUT | /notes/:id | Update a note |
| DELETE | /notes/:id | Delete a note |

## CI/CD Pipeline Stages
1. **Build** — Docker image built from Dockerfile
2. **Test** — Basic app import test inside container
3. **Deploy** — Previous image tagged for rollback, new container started
4. **Health Check** — /health endpoint verified before marking success
5. **Rollback** — Automatically triggered if health check fails

## Jenkins
- Running on non-default port **9090**
- Jenkinsfile committed to repository
- Viewer account created with read-only permissions
- No ability to trigger, edit, or delete jobs

## Key Design Decisions
- **Flask chosen** for simplicity — infrastructure is the focus, not the app
- **Gunicorn** used as production WSGI server instead of Flask dev server
- **PostgreSQL** chosen over MySQL for better Render free tier support
- **Port 9090** chosen for Jenkins to avoid conflict with default 8080
- **External DB URL** used for Jenkins pipeline since internal Render hostname is only resolvable within Render's private network