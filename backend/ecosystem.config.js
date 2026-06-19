module.exports = {
  apps: [{
    name: 'timehouse-api',
    script: 'src/app.js',
    instances: 1,
    exec_mode: 'fork',
    max_memory_restart: '256M',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: '/var/log/timehouse/err.log',
    out_file: '/var/log/timehouse/out.log',
    merge_logs: true,
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    kill_timeout: 10000,
    listen_timeout: 5000,
    wait_ready: false
  }]
};
