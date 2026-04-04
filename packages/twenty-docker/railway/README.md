# Deploying Twenty CRM on Railway

Deploy Twenty CRM on [Railway](https://railway.app) with [Supabase](https://supabase.com) as the PostgreSQL database.

## Architecture

```
Railway:
  ├── twenty-server   (API + frontend + migrations)  → port 3000
  ├── twenty-worker   (background job processor)     → no port
  └── Redis           (Railway managed addon)

External:
  └── Supabase        (PostgreSQL database)
```

## Prerequisites

- Railway account ([railway.app](https://railway.app))
- Supabase project ([supabase.com](https://supabase.com))
- GitHub repo with Twenty (or use the pre-built Docker image `twentycrm/twenty`)

## Step 1: Set Up Supabase Database

1. Open your Supabase project → **SQL Editor**
2. Run [`supabase-setup.sql`](./supabase-setup.sql):

```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "unaccent";
```

3. Go to **Settings → Database** and copy the connection string:
   - Use **Transaction mode** (port `6543`) for connection pooling
   - Format: `postgresql://postgres:[PASSWORD]@db.[REF].supabase.co:6543/postgres`

## Step 2: Create Railway Project

1. Go to [railway.app](https://railway.app) → **New Project** → **Empty Project**
2. Click **New** → **Database** → **Add Redis**
   - Railway provisions Redis and creates `REDIS_URL` automatically

## Step 3: Add Twenty Server Service

1. In your Railway project, click **New** → **GitHub Repo** (or **Docker Image**)

   **If using Docker image:**
   - Image: `twentycrm/twenty:latest`

   **If building from source:**
   - Connect your Twenty GitHub repository
   - Set **Root Directory** to `/`
   - Railway will auto-detect the Dockerfile

2. Rename the service to `twenty-server`

3. **Generate a domain FIRST** (required for env var validation):
   - Go to **Settings → Networking → Generate Domain**
   - Copy your domain (e.g., `https://twenty.up.railway.app`)

4. **Set environment variables** (all URLs must use your actual domain):

   | Variable                        | Value                                                                             |
   | ------------------------------- | --------------------------------------------------------------------------------- |
   | `PG_DATABASE_URL`               | `postgresql://postgres:[PASS]@db.[REF].supabase.co:6543/postgres?sslmode=require` |
   | `APP_SECRET`                    | Generate with `openssl rand -base64 32`                                           |
   | `SERVER_URL`                    | Your Railway domain (e.g., `https://twenty.up.railway.app`)                       |
   | `FRONTEND_URL`                  | Same as SERVER_URL                                                                |
   | `REDIS_URL`                     | `redis://redis:6379`                                                              |
   | `STORAGE_TYPE`                  | `local`                                                                           |
   | `NODE_PORT`                     | `3000`                                                                            |
   | `AUTH_GOOGLE_APIS_CALLBACK_URL` | `https://your-domain.up.railway.app/auth/google/callback`                         |

5. Set the **Docker build arg** (required for frontend to know the API URL):
   - Go to **Settings → Build → Build Args**
   - Add: `REACT_APP_SERVER_BASE_URL` = `https://your-domain.up.railway.app`
   - This is baked into the frontend at build time (not a runtime env var)

## Step 4: Add Twenty Worker Service

1. Click **New** → **Duplicate** on the `twenty-server` service (or add from same source)
2. Rename to `twenty-worker`
3. **Settings → Deploy → Custom Start Command**: `yarn worker:prod`
4. **Do NOT** generate a domain (worker has no HTTP server)
5. Add these worker-specific env vars:
   - `DISABLE_DB_MIGRATIONS=true`
   - `DISABLE_CRON_JOBS_REGISTRATION=true`

## Step 5: Deploy

1. Deploy the **server** service first — watch the build logs
2. On first boot, the entrypoint automatically:
   - Creates the `core` schema
   - Runs all database migrations
   - Registers cron jobs
3. Deploy the **worker** service
4. Access your Twenty instance at the server's Railway domain
5. Create your first account — it becomes the admin

## Environment Variables Reference

See [`.env.railway.example`](./.env.railway.example) for the complete list.

| Variable                        | Required | Notes                                                           |
| ------------------------------- | -------- | --------------------------------------------------------------- |
| `PG_DATABASE_URL`               | Yes      | Supabase connection string (port 6543)                          |
| `APP_SECRET`                    | Yes      | Same value on server + worker                                   |
| `REDIS_URL`                     | Yes      | `redis://redis:6379` (Railway service name defaults to "redis") |
| `SERVER_URL`                    | Yes      | Public URL of server                                            |
| `FRONTEND_URL`                  | Yes      | Public URL of server                                            |
| `STORAGE_TYPE`                  | Yes      | `local` or `s3`                                                 |
| `AUTH_GOOGLE_APIS_CALLBACK_URL` | Yes      | Must be set even if not using Google auth                       |
| `EMAIL_DRIVER`                  | No       | Default: `logger`. Set to `smtp` for real emails                |

## Troubleshooting

| Issue                                            | Fix                                                                           |
| ------------------------------------------------ | ----------------------------------------------------------------------------- |
| `AUTH_GOOGLE_APIS_CALLBACK_URL` validation error | Must be set to a valid URL (https://...), even if not using Google auth       |
| Worker crashes with ECONNREFUSED to Redis        | Use `redis://redis:6379` (hostname format, not `${{Redis.REDIS_URL}}`)        |
| Database migrations fail                         | Use port 6543 (transaction pooler) in `PG_DATABASE_URL`                       |
| Frontend blank page                              | `REACT_APP_SERVER_BASE_URL` must match deployed URL (set as Docker build arg) |
| Storage errors                                   | Local storage is ephemeral on Railway — use S3 for production                 |
| Railway build fails with "Invalid URL"           | Generate a domain FIRST, then set all URL env vars to that domain             |
| Env vars rejected during validation              | Railway validates BEFORE build. Must use real URLs, not placeholder domains   |
