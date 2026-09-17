# Codabench Local Development Guide

This guide describes how to run and develop Codabench with maximum productivity. It covers:
1. **Hybrid Development Workflow (Recommended)**: Running background infrastructure (RabbitMQ, Redis, PostgreSQL) in Docker, while running the fast/iterative components (Django web server, Celery site worker, and frontend asset compiler) directly on your host machine with `uv` and `npm`.
2. **Pure Native Development**: Running all services directly on the host without Docker.
3. **Environment & Configuration Reference**: Modern S3 (Cloudflare R2, MinIO, AWS) with SigV4, and OIDC / Authentik Single Sign-On.
4. **User & Superuser Management**: Passwordless superusers and granting/demoting administrative privileges.

---

## 1. Architecture Overview

Codabench consists of several cooperating services:

* **Django Web Server (`src`)**: The main web application (REST API, web views, WebSockets via Django Channels).
* **Site Worker (`site-worker`)**: Celery worker handling site background tasks, submission uploads, unzipping bundles, sending notifications, and running Celery beat periodic jobs.
* **Compute Worker (`compute-worker`)**: Dedicated Celery worker responsible for executing user code and benchmarks inside isolated Docker containers (connects via the Docker socket).
* **RabbitMQ**: The message broker used by Celery for dispatching tasks between Django and workers.
* **Redis**: Used for Django Channels WebSocket layer and caching.
* **PostgreSQL**: The primary relational database.
* **Object Storage**: S3-compatible object storage (e.g., Cloudflare R2, AWS S3, MinIO) configured with **SigV4** presigned URLs for datasets, submissions, and bundle storage.
* **Frontend Asset Builder**: Compiles Stylus stylesheets and Riot.js tags into static bundles (`src/static/generated/`).

---

## 2. Prerequisites

### Host Tools
* **Python 3.13+** managed via [uv](https://github.com/astral-sh/uv):
  ```bash
  curl -LsSf https://astral.sh/uv/install.sh | sh
  ```
* **Node.js (v18+) & npm**:
  ```bash
  # Check versions
  node -v
  npm -v
  ```
* **Docker & Docker Compose** (for running background services in hybrid mode or running compute workers).

---

## 3. Workflow A: Hybrid Development (Recommended)

In this workflow:
* **Background services** (RabbitMQ, Flower, Redis, and optionally PostgreSQL) run via Docker.
* **Iterative components** (Django main site, Celery site worker, asset builder) run on your host machine.
* Code edits and template changes reload instantly without rebuilding container images.

### Step 1: Clone and install host dependencies

```bash
cd /path/to/codabench

# 1. Install Python dependencies with uv
uv sync

# 2. Install Frontend Node dependencies
npm install

# 3. Build frontend assets once
npm run build-stylus
npm run build-riot
```

### Step 2: Configure `.env`

Copy the sample environment file:
```bash
cp .env_sample .env
```

Edit `.env` to point to `localhost` ports for services running on the host or forwarded from Docker:

```ini
DEBUG=True
DJANGO_SETTINGS_MODULE=settings.develop
DOMAIN_NAME=localhost:8000

# Database (if PostgreSQL is on localhost or port-forwarded from Docker)
DB_HOST=localhost
DB_NAME=postgres
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_PORT=5432

# RabbitMQ
RABBITMQ_HOST=localhost
RABBITMQ_PORT=5672
RABBITMQ_MANAGEMENT_PORT=15672
RABBITMQ_DEFAULT_USER=rabbit-username
RABBITMQ_DEFAULT_PASS=rabbit-password-you-should-change

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# Disable traditional password auth; use OIDC
ENABLE_SIGN_IN=False
ENABLE_SIGN_UP=False

# OIDC Settings (Authentik or your provider)
OIDC_ENABLED=True
OIDC_ORGANIZATION_NAME=Authentik
OIDC_CLIENT_ID=<your-authentik-client-id>
OIDC_CLIENT_SECRET=<your-authentik-client-secret>
OIDC_AUTHORIZATION_URL=https://<your-authentik-domain>/application/o/authorize/
OIDC_TOKEN_URL=https://<your-authentik-domain>/application/o/token/
OIDC_USER_INFO_URL=https://<your-authentik-domain>/application/o/userinfo/
OIDC_REDIRECT_URL=http://localhost:8000/oidc/complete/1/

# S3 / Cloudflare R2 Storage (SigV4)
STORAGE_TYPE=s3
AWS_ACCESS_KEY_ID=<your-access-key-id>
AWS_SECRET_ACCESS_KEY=<your-secret-access-key>
AWS_STORAGE_BUCKET_NAME=<public-bucket-name>
AWS_STORAGE_PRIVATE_BUCKET_NAME=<private-bucket-name>
AWS_S3_ENDPOINT_URL=https://<account-id>.r2.cloudflarestorage.com
AWS_S3_SIGNATURE_VERSION=s3v4
AWS_S3_REGION_NAME=auto
AWS_QUERYSTRING_AUTH=True
```

### Step 3: Start background services in Docker

Start RabbitMQ and Flower (and optionally Redis/Postgres):
```bash
docker compose up -d rabbit flower
```

Check logs:
```bash
docker compose logs -f rabbit
```

### Step 4: Run Database Migrations & Static Files

```bash
# Run database migrations
uv run python src/manage.py migrate

# (Optional) Seed demo competition data
uv run python src/manage.py generate_data

# (Optional) Automatically configure OIDC Organization from your .env
uv run python src/manage.py setup_oidc
```

### Step 5: Start the Development Servers

Open separate terminal tabs or use a process runner (like tmux or Foreman):

#### Terminal 1: Frontend Asset Watcher
Watches Stylus (`src/static/stylus`) and Riot tags (`src/static/riot`) and automatically recompiles on save:
```bash
npm run watch
```

#### Terminal 2: Django Web Application
Run with Django development server:
```bash
uv run python src/manage.py runserver 0.0.0.0:8000
```
*Or* run with auto-reloading Gunicorn (same as production stack):
```bash
cd src
uv run watchmedo auto-restart -p '*.py' --recursive -- python3 ./gunicorn_run.py
```

#### Terminal 3: Celery Site Worker
Runs the site worker for background tasks and periodic schedules (`-B`):
```bash
cd src
uv run celery -A celery_config worker -B -Q site-worker -l info -n site-worker@%n --concurrency=2
```

#### Terminal 4 (Optional): Compute Worker
If you are testing submission evaluations locally:
```bash
cd compute_worker
uv run celery -A compute_worker worker -l info -Q compute-worker -n compute-worker@%n
```
*(Note: Compute worker must have access to the local Docker daemon at `/var/run/docker.sock`)*.

You can now navigate to **http://localhost:8000/** in your browser.

---

## 4. Workflow B: Pure Native Development (No Docker)

If you prefer not to use Docker for any services:

### 1. Install system services (e.g. Ubuntu / Debian)
```bash
sudo apt update
sudo apt install -y postgresql postgresql-contrib rabbitmq-server redis-server
```

### 2. Configure PostgreSQL
```bash
sudo -u postgres psql -c "CREATE USER codabench WITH PASSWORD 'codabench' CREATEDB;"
sudo -u postgres psql -c "CREATE DATABASE codabench OWNER codabench;"
```
In your `.env`:
```ini
DB_HOST=localhost
DB_PORT=5432
DB_NAME=codabench
DB_USERNAME=codabench
DB_PASSWORD=codabench
```

### 3. Configure RabbitMQ
```bash
sudo systemctl enable --now rabbitmq-server
sudo rabbitmq-plugins enable rabbitmq_management
sudo rabbitmqctl add_user rabbit-username rabbit-password-you-should-change
sudo rabbitmqctl set_user_tags rabbit-username administrator
sudo rabbitmqctl set_permissions -p / rabbit-username ".*" ".*" ".*"
```

### 4. Run Django and Site Worker
Follow Steps 4 and 5 from Workflow A.

---

## 5. Storage Configuration: Modern S3 & SigV4

This version of Codabench strictly enforces AWS Signature Version 4 (**SigV4**) for all presigned URLs and object operations, ensuring complete compatibility with:
* **Cloudflare R2**
* **AWS S3**
* **MinIO**
* **Google Cloud Storage (S3-compatible API)**
* **Wasabi / Ceph**

### Configuration Reference:
```ini
# Storage backend
STORAGE_TYPE=s3

# S3 Credentials
AWS_ACCESS_KEY_ID=<your-access-key-id>
AWS_SECRET_ACCESS_KEY=<your-secret-access-key>

# Buckets (Public bucket for static assets/logos, Private bucket for submissions/datasets)
AWS_STORAGE_BUCKET_NAME=my-codabench-public
AWS_STORAGE_PRIVATE_BUCKET_NAME=my-codabench-private

# S3 Endpoint URL (Required for Cloudflare R2 or MinIO; omit for standard AWS)
AWS_S3_ENDPOINT_URL=https://<account_id>.r2.cloudflarestorage.com

# Enforce SigV4 & Region
AWS_S3_SIGNATURE_VERSION=s3v4
AWS_S3_REGION_NAME=auto

# Presigned URLs for private files
AWS_QUERYSTRING_AUTH=True

# Addressing style: 'path' or 'virtual' (defaults to standard client resolution)
AWS_S3_ADDRESSING_STYLE=path
```

---

## 6. Authentication: OIDC & Passwordless Superusers

Traditional username/password authentication is disabled by default (`ENABLE_SIGN_IN=False`, `ENABLE_SIGN_UP=False`). Users authenticate via your OIDC identity provider (e.g. **Authentik**).

### Setting up Authentik OIDC
1. In Authentik Admin:
   - Create a **Provider**: OAuth2/OpenID Provider.
   - Set **Redirect URIs**: `http://localhost:8000/oidc/complete/1/` (or your public domain).
   - Create an **Application** linked to that provider.
2. In Codabench `.env`:
   ```ini
   OIDC_ENABLED=True
   OIDC_ORGANIZATION_NAME=Authentik
   OIDC_CLIENT_ID=<client-id-from-authentik>
   OIDC_CLIENT_SECRET=<client-secret-from-authentik>
   OIDC_AUTHORIZATION_URL=https://<authentik-domain>/application/o/authorize/
   OIDC_TOKEN_URL=https://<authentik-domain>/application/o/token/
   OIDC_USER_INFO_URL=https://<authentik-domain>/application/o/userinfo/
   OIDC_REDIRECT_URL=http://localhost:8000/oidc/complete/1/
   ```
3. Run the sync command:
   ```bash
   uv run python src/manage.py setup_oidc
   ```

### Creating Superusers without Passwords
Because password-based authentication is disabled, superusers must NOT have local passwords.

Run `createsuperuser` interactively:
```bash
uv run python src/manage.py createsuperuser
# Prompts for Username and Email address ONLY (no password prompt)
```

Or non-interactively:
```bash
uv run python src/manage.py createsuperuser --username admin --email admin@example.com --no-input
```

### Granting Superuser Privileges to an OIDC User
When a user logs in via Authentik/OIDC, their account is automatically provisioned. You can promote them to a superuser at any time:

```bash
# Using Django management command (by username or email):
uv run python src/manage.py grant_superuser user@example.com
uv run python src/manage.py grant_superuser my_username

# Or using the wrapper script:
./bin/grant_superuser.sh user@example.com
```

### Demoting a Superuser
To revoke administrative and superuser privileges:

```bash
# Using Django management command:
uv run python src/manage.py demote_superuser user@example.com

# Or using the wrapper script:
./bin/demote_superuser.sh user@example.com
```

---

## 7. Useful Commands & Tips

| Task | Command |
|---|---|
| Run tests | `uv run pytest` |
| Apply migrations | `uv run python src/manage.py migrate` |
| Recompile Riot tags | `npm run build-riot` |
| Recompile Stylus | `npm run build-stylus` |
| Watch & compile frontend | `npm run watch` |
| Create passwordless superuser | `uv run python src/manage.py createsuperuser` |
| Grant superuser privileges | `./bin/grant_superuser.sh <email_or_username>` |
| Demote superuser privileges | `./bin/demote_superuser.sh <email_or_username>` |
| Setup OIDC organization from `.env` | `uv run python src/manage.py setup_oidc` |
| RabbitMQ Management Web UI | `http://localhost:15672` (guest / guest or configured credentials) |
| Celery Flower Monitoring UI | `http://localhost:5555` |
