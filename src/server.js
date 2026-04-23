const http = require("http");

const hostname = "127.0.0.1";
const port = process.env.PORT || 3000;
const clients = new Set();

function sendUserCount(response) {
  response.write(`data: ${JSON.stringify({ connectedUsers: clients.size })}\n\n`);
}

function broadcastUserCount() {
  for (const client of clients) {
    sendUserCount(client);
  }
}

const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Live Users</title>
  <style>
    body { font-family: system-ui, sans-serif; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; background: #f0f4f8; color: #1a202c; }
    main { text-align: center; padding: 2rem; }
    h1 { font-size: 3rem; margin-bottom: 0.5rem; }
    p { font-size: 1.2rem; color: #4a5568; }
    strong { font-size: 2rem; color: #2b6cb0; }
  </style>
</head>
<body>
  <main>
    <h1>Connected users</h1>
    <p>Currently online: <strong id="user-count">0</strong></p>
  </main>
  <script>
    const userCountElement = document.getElementById("user-count");
    const eventSource = new EventSource("/events");

    eventSource.addEventListener("message", (event) => {
      const { connectedUsers } = JSON.parse(event.data);
      userCountElement.textContent = connectedUsers;
    });

    eventSource.addEventListener("error", () => {
      userCountElement.textContent = "offline";
    });
  </script>
</body>
</html>`;

const server = http.createServer((req, res) => {
  if (req.url === "/events") {
    res.writeHead(200, {
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache",
      Connection: "keep-alive"
    });

    clients.add(res);
    sendUserCount(res);
    broadcastUserCount();

    req.on("close", () => {
      clients.delete(res);
      broadcastUserCount();
    });

    return;
  }

  res.writeHead(200, { "Content-Type": "text/html" });
  res.end(html);
});

server.listen(port, hostname, () => {
  console.log(`Server running at http://${hostname}:${port}/`);
});

process.on("SIGINT", () => {
  console.log("\nShutting down...");
  for (const client of clients) {
    client.end();
  }
  server.close(() => process.exit(0));
});
