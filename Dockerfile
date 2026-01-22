FROM node:20-alpine

WORKDIR /app

# Install required system libraries
RUN apk add --no-cache openssl openssl-dev bash

# Copy package files
COPY package*.json ./
COPY prisma ./prisma/

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Generate Prisma Client
RUN npx prisma generate

# Build TypeScript
RUN npm run build

# Copy entrypoint script
COPY docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x /app/docker-entrypoint.sh

# Expose port
EXPOSE 3000

# Start the application using entrypoint
ENTRYPOINT ["/app/docker-entrypoint.sh"]
