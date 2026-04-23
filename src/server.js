const http = require("http");

const hostname = "127.0.0.1";
const port = process.env.PORT || 3000;

const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Hello, World!</title>
  <style>
    body { font-family: system-ui, sans-serif; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; background: #f0f4f8; }
    h1 { font-size: 3rem; color: #1a202c; }
  </style>
</head>
<body>
  <h1>Hello, World!</h1>
</body>
</html>`;

const server = http.createServer((req, res) => {
  res.writeHead(200, { "Content-Type": "text/html" });
  res.end(html);
});

server.listen(port, hostname, () => {
  console.log(`Server running at http://${hostname}:${port}/`);
});

process.on("SIGINT", () => {
  console.log("\nShutting down...");
  server.close(() => process.exit(0));
});
