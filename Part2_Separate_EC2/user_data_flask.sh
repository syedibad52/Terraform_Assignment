#!/bin/bash
set -e

apt-get update -y
apt-get install -y python3 python3-pip curl
pip3 install flask flask-cors

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
        "message": "Hello from Flask Backend EC2 Instance!"
    })

@app.route('/health')
def health():
    return jsonify({"status": "healthy"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

nohup python3 /opt/flask-app/app.py > /var/log/flask.log 2>&1 &
