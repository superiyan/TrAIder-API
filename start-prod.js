#!/usr/bin/env node

/**
 * Production startup script
 * Loads .env.production and starts the server
 * Usage: node start-prod.js
 */

const fs = require('fs');
const path = require('path');

// Determine which env file to load
const envFile = process.argv[2] || '.env.production';
const envPath = path.join(__dirname, envFile);

// Check if env file exists
if (!fs.existsSync(envPath)) {
  console.error(`❌ ERROR: ${envFile} not found at ${envPath}`);
  process.exit(1);
}

// Load environment variables from file
require('dotenv').config({ path: envPath });

console.log(`✅ Loaded environment from: ${envPath}`);
console.log(`📋 NODE_ENV: ${process.env.NODE_ENV}`);
console.log(`📋 PORT: ${process.env.PORT}`);

// Start the server
require('./dist/server.js');
