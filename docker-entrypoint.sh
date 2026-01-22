#!/bin/sh

# Docker entrypoint script for production
# Ensures environment variables are loaded and migrations run

set -e

echo "🚀 Starting TrAIder API in Docker..."

# Check required environment variables
required_vars="NODE_ENV DATABASE_URL JWT_SECRET PORT"

for var in $required_vars; do
  if [ -z "$(eval echo \$$var)" ]; then
    echo "❌ ERROR: Required environment variable $var is not set"
    exit 1
  fi
done

echo "✅ All required environment variables are set"

# Run database migrations
echo "📦 Running database migrations..."
npx prisma migrate deploy

# Generate Prisma Client (in case it's missing)
echo "🔧 Generating Prisma Client..."
npx prisma generate

# Start the application
echo "🚀 Starting application on port $PORT..."
exec node dist/server.js
