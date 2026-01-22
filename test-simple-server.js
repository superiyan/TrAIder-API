const http = require('http');

const PORT = 8080;

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ status: 'OK', message: 'Simple server working!' }));
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`✅ Simple server running on http://127.0.0.1:${PORT}`);
  console.log(`Test: http://localhost:${PORT}`);
});

server.on('error', (err) => {
  console.error('❌ Server error:', err.message);
  process.exit(1);
});
