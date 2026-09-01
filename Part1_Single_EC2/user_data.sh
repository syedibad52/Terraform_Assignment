#!/bin/bash
set -e

# Update packages and install dependencies
apt-get update -y
apt-get install -y python3 python3-pip nodejs npm curl

# Install Flask and Flask-CORS
pip3 install flask flask-cors

# Setup Flask Backend App (Port 5000)
mkdir -p /opt/flask-app
cat <<'EOF' > /opt/flask-app/app.py
from flask import Flask, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

@app.route('/')
def home():
    return jsonify({
        "service": "Flask Backend API",
        "status": "healthy",
        "port": 5000,
        "message": "Hello from Flask on Single EC2!"
    })

@app.route('/health')
def health():
    return jsonify({"status": "healthy"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

# Setup Express Frontend App (Port 3000)
mkdir -p /opt/express-app
cat <<'EOF' > /opt/express-app/package.json
{
  "name": "express-frontend",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2"
  }
}
EOF

cat <<'EOF' > /opt/express-app/server.js
const express = require('express');
const http = require('http');
const app = express();
const PORT = 3000;
const BACKEND_URL = 'http://localhost:5000';

app.get('/', (req, res) => {
  res.send(`
    <html>
      <head><title>Part 1: Single EC2 App</title></head>
      <body style="font-family: Arial; margin: 40px;">
        <h1>Single EC2 Microservices</h1>
        <p>Frontend: Express (Port 3000)</p>
        <p>Backend URL: ${BACKEND_URL}</p>
        <a href="/api-check">Test Backend Connection</a>
      </body>
    </html>
  `);
});

app.get('/api-check', (req, res) => {
  http.get(BACKEND_URL, (apiRes) => {
    let data = '';
    apiRes.on('data', chunk => data += chunk);
    apiRes.on('end', () => res.send(`<h2>Backend Response:</h2><pre>${data}</pre><a href="/">Back</a>`));
  }).on('error', (err) => {
    res.send(`<h2>Backend Connection Error:</h2><pre>${err.message}</pre><a href="/">Back</a>`);
  });
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', app: 'Express Frontend' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log('Express app listening on port ' + PORT);
});
EOF

cd /opt/express-app && npm install

# Start both applications in background
nohup python3 /opt/flask-app/app.py > /var/log/flask.log 2>&1 &
cd /opt/express-app && nohup node server.js > /var/log/express.log 2>&1 &
