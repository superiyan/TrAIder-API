const http = require('http');

const PORT = 8080;

console.log('=== Starting simple test server ===');
console.log('Process ID:', process.pid);
console.log('Node version:', process.version);
console.log('Platform:', process.platform);

process.on('uncaughtException', (err) => {
  console.error('❌ Uncaught Exception:', err);
  process.exit(1);
});

process.on('unhandledRejection', (err) => {
  console.error('❌ Unhandled Rejection:', err);
  process.exit(1);
});

const server = http.createServer((req, res) => {
  console.log(`Request: ${req.method} ${req.url}`);
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ status: 'OK', message: 'Server is working!' }));
});

server.on('error', (err) => {
  console.error('❌ Server error:', err);
  console.error('Error code:', err.code);
  console.error('Error message:', err.message);
  process.exit(1);
});

server.on('listening', () => {
  const address = server.address();
  console.log('✅ Server is listening!');
  console.log('Address:', address);
  console.log('Port:', address.port);
  console.log(`Test with: http://localhost:${address.port}`);
});

console.log('Attempting to listen on port', PORT, '...');
server.listen(PORT, '127.0.0.1');

// Keep process alive
console.log('Server.listen() called successfully');
console.log('Waiting for server to start...');

setTimeout(() => {
  console.log('Timeout reached after 5 seconds');
  console.log('Server address:', server.address());
}, 5000);
