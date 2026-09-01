const express = require('express');
const http = require('http');
const app = express();

const PORT = process.env.PORT || 3000;
const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:5000';

app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>Part 3: ECS Fargate Microservices</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 40px; background: #f4f6f9; color: #333; }
          .card { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); max-width: 600px; margin: auto; }
          h1 { color: #0066cc; }
          .btn { display: inline-block; padding: 10px 15px; background: #0066cc; color: white; text-decoration: none; border-radius: 4px; margin-top: 15px; }
        </style>
      </head>
      <body>
        <div class="card">
          <h1>Express Frontend (Docker / ECS Fargate)</h1>
          <p>Frontend Running on Port: <strong>${PORT}</strong></p>
          <p>Configured Backend URL: <code>${BACKEND_URL}</code></p>
          <a class="btn" href="/api-check">Test Flask API Endpoint &rarr;</a>
        </div>
      </body>
    </html>
  `);
});

app.get('/api-check', (req, res) => {
  http.get(BACKEND_URL, (apiRes) => {
    let data = '';
    apiRes.on('data', chunk => data += chunk);
    apiRes.on('end', () => {
      res.send(`
        <div style="font-family: Arial; padding: 30px; max-width: 600px; margin: auto;">
          <h2>Response from Flask API (ECS):</h2>
          <pre style="background: #222; color: #00ff00; padding: 15px; border-radius: 5px;">${data}</pre>
          <a href="/">Back to Home</a>
        </div>
      `);
    });
  }).on('error', (err) => {
    res.send(`
      <div style="font-family: Arial; padding: 30px; max-width: 600px; margin: auto;">
        <h2 style="color: red;">Backend Connection Failed:</h2>
        <p>Could not connect to <code>${BACKEND_URL}</code></p>
        <pre>${err.message}</pre>
        <a href="/">Back to Home</a>
      </div>
    `);
  });
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', app: 'Express Frontend Container' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Express frontend running on port ${PORT}`);
});
