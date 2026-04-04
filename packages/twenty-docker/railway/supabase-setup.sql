-- =============================================================================
-- Twenty CRM — Supabase Database Setup
-- =============================================================================
-- Run this in Supabase SQL Editor before deploying Twenty.
-- =============================================================================

-- 1. Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "unaccent";

-- 2. (Optional) Create a dedicated database for Twenty
--    Skip this if you want Twenty to use the default "postgres" database.
--    If you create this, update PG_DATABASE_URL to point to "twenty" instead of "postgres".
-- CREATE DATABASE twenty WITH OWNER postgres;

-- 3. Verify extensions are available
SELECT extname, extversion FROM pg_extension WHERE extname IN ('uuid-ossp', 'unaccent');

-- Done. Twenty's entrypoint.sh will handle schema creation and migrations on first boot.
