module.exports = {
  apps: [
    {
      name: 'traider-api',
      script: './dist/server.js',
      instances: 'max',
      exec_mode: 'cluster',
      env: {
        NODE_ENV: 'production',
      },
      env_development: {
        NODE_ENV: 'development',
      },
      // Logging
      out_file: './logs/pm2-out.log',
      error_file: './logs/pm2-error.log',
      log_file: './logs/pm2.log',
      time: true,
      // Restart and Monitoring
      watch: false,
      max_memory_restart: '1G',
      min_uptime: '10s',
      max_restarts: 10,
      autorestart: true,
      // Graceful shutdown
      wait_ready: true,
      listen_timeout: 3000,
      kill_timeout: 5000,
    },
  ],
};
