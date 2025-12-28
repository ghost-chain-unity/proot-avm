#!/usr/bin/env bash
# proot-avm Web Dashboard Launcher
# Launches a local web interface for VM management

# Check if Node.js is available
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Installing..."
    # Try to install in Termux or system
    if command -v pkg &> /dev/null; then
        pkg install -y nodejs npm
    elif command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y nodejs npm
    else
        echo "❌ Please install Node.js manually"
        exit 1
    fi
fi

# Check if dashboard directory exists
DASHBOARD_DIR="$HOME/.proot-avm-dashboard"
if [ ! -d "$DASHBOARD_DIR" ]; then
    echo "📥 Setting up web dashboard..."
    mkdir -p "$DASHBOARD_DIR"
    cd "$DASHBOARD_DIR"

    # Create package.json
    cat > package.json << 'EOF'
{
  "name": "proot-avm-dashboard",
  "version": "1.0.0",
  "description": "Web dashboard for proot-avm",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "socket.io": "^4.7.2",
    "axios": "^1.6.0"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
EOF

    # Install dependencies
    npm install

    # Create server.js
    cat > server.js << 'EOF'
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const { exec } = require('child_process');
const path = require('path');

const app = express();
const server = http.createServer(app);
const io = socketIo(server);

const PORT = process.env.PORT || 3000;

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));

// API endpoints
app.get('/api/status', (req, res) => {
    exec('avm status', (error, stdout, stderr) => {
        res.json({
            status: error ? 'error' : 'success',
            output: stdout,
            error: stderr
        });
    });
});

app.post('/api/start', (req, res) => {
    exec('avm start headless', (error, stdout, stderr) => {
        res.json({
            status: error ? 'error' : 'success',
            output: stdout,
            error: stderr
        });
    });
});

app.post('/api/stop', (req, res) => {
    exec('avm stop', (error, stdout, stderr) => {
        res.json({
            status: error ? 'error' : 'success',
            output: stdout,
            error: stderr
        });
    });
});

// WebSocket for real-time updates
io.on('connection', (socket) => {
    console.log('Client connected');

    // Send periodic status updates
    const statusInterval = setInterval(() => {
        exec('avm status', (error, stdout, stderr) => {
            socket.emit('status', {
                output: stdout,
                error: stderr,
                timestamp: new Date()
            });
        });
    }, 5000);

    socket.on('disconnect', () => {
        clearInterval(statusInterval);
        console.log('Client disconnected');
    });
});

server.listen(PORT, () => {
    console.log(`🚀 proot-avm Dashboard running at http://localhost:${PORT}`);
    console.log(`📱 Open in browser or use curl for API access`);
});
EOF

    # Create public directory and HTML
    mkdir -p public
    cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>proot-avm Dashboard</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #333;
            min-height: 100vh;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }

        .header {
            text-align: center;
            color: white;
            margin-bottom: 30px;
        }

        .header h1 {
            font-size: 3rem;
            margin-bottom: 10px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }

        .header p {
            font-size: 1.2rem;
            opacity: 0.9;
        }

        .dashboard {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }

        .card {
            background: rgba(255, 255, 255, 0.95);
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.18);
        }

        .card h3 {
            color: #667eea;
            margin-bottom: 15px;
            font-size: 1.5rem;
        }

        .status-indicator {
            display: inline-block;
            width: 12px;
            height: 12px;
            border-radius: 50%;
            margin-right: 8px;
        }

        .status-running {
            background: #4CAF50;
            box-shadow: 0 0 10px rgba(76, 175, 80, 0.5);
        }

        .status-stopped {
            background: #f44336;
            box-shadow: 0 0 10px rgba(244, 67, 54, 0.5);
        }

        .btn {
            background: linear-gradient(45deg, #667eea, #764ba2);
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 25px;
            cursor: pointer;
            font-size: 1rem;
            font-weight: 600;
            transition: all 0.3s ease;
            margin: 5px;
            min-width: 100px;
        }

        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
        }

        .btn:active {
            transform: translateY(0);
        }

        .btn-danger {
            background: linear-gradient(45deg, #f44336, #c62828);
        }

        .btn-danger:hover {
            box-shadow: 0 4px 15px rgba(244, 67, 54, 0.4);
        }

        .logs {
            background: #1e1e1e;
            color: #d4d4d4;
            font-family: 'Courier New', monospace;
            padding: 15px;
            border-radius: 8px;
            max-height: 300px;
            overflow-y: auto;
            white-space: pre-wrap;
            word-wrap: break-word;
        }

        .logs h4 {
            color: #667eea;
            margin-bottom: 10px;
        }

        .footer {
            text-align: center;
            color: white;
            margin-top: 30px;
            opacity: 0.8;
        }

        @media (max-width: 768px) {
            .header h1 {
                font-size: 2rem;
            }

            .dashboard {
                grid-template-columns: 1fr;
            }

            .card {
                padding: 20px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 proot-avm Dashboard</h1>
            <p>Modern Alpine VM Management for Termux</p>
        </div>

        <div class="dashboard">
            <div class="card">
                <h3>VM Status</h3>
                <div id="status">
                    <span class="status-indicator status-stopped"></span>
                    Checking status...
                </div>
                <br>
                <button class="btn" onclick="startVM()">Start VM</button>
                <button class="btn btn-danger" onclick="stopVM()">Stop VM</button>
                <button class="btn" onclick="checkStatus()">Refresh</button>
            </div>

            <div class="card">
                <h3>Quick Actions</h3>
                <button class="btn" onclick="runCommand('avm ssh')">SSH to VM</button>
                <button class="btn" onclick="runCommand('avm first-boot')">First Boot Setup</button>
                <button class="btn" onclick="runCommand('avm help')">Show Help</button>
            </div>

            <div class="card">
                <h3>Real-time Logs</h3>
                <div id="logs" class="logs">
                    <h4>VM Status Logs</h4>
                    Connecting to real-time updates...
                </div>
            </div>
        </div>

        <div class="footer">
            <p>Built with ❤️ for mobile developers | <a href="https://github.com/ghost-chain-unity/proot-avm" style="color: white;">GitHub</a></p>
        </div>
    </div>

    <script src="/socket.io/socket.io.js"></script>
    <script>
        const socket = io();
        const statusDiv = document.getElementById('status');
        const logsDiv = document.getElementById('logs');

        // Update status display
        function updateStatus(output, error) {
            const isRunning = output.includes('RUNNING');
            const indicator = statusDiv.querySelector('.status-indicator');

            if (isRunning) {
                indicator.className = 'status-indicator status-running';
                statusDiv.innerHTML = '<span class="status-indicator status-running"></span>VM is RUNNING ✅';
            } else {
                indicator.className = 'status-indicator status-stopped';
                statusDiv.innerHTML = '<span class="status-indicator status-stopped"></span>VM is STOPPED ❌';
            }
        }

        // Socket.io real-time updates
        socket.on('status', (data) => {
            updateStatus(data.output, data.error);
            logsDiv.innerHTML = `<h4>VM Status Logs</h4>${data.output || data.error}`;
        });

        // Button actions
        async function startVM() {
            try {
                const response = await fetch('/api/start', { method: 'POST' });
                const result = await response.json();
                alert(result.status === 'success' ? 'VM started!' : 'Error: ' + result.error);
                checkStatus();
            } catch (error) {
                alert('Error starting VM: ' + error);
            }
        }

        async function stopVM() {
            try {
                const response = await fetch('/api/stop', { method: 'POST' });
                const result = await response.json();
                alert(result.status === 'success' ? 'VM stopped!' : 'Error: ' + result.error);
                checkStatus();
            } catch (error) {
                alert('Error stopping VM: ' + error);
            }
        }

        async function checkStatus() {
            try {
                const response = await fetch('/api/status');
                const result = await response.json();
                updateStatus(result.output, result.error);
            } catch (error) {
                console.error('Error checking status:', error);
            }
        }

        function runCommand(cmd) {
            // For now, just show the command
            alert(`Run this command in terminal:\n${cmd}`);
        }

        // Initial status check
        checkStatus();
    </script>
</body>
</html>
EOF

    echo "✅ Web dashboard setup complete!"
fi

# Launch the dashboard
cd "$DASHBOARD_DIR"
echo "🚀 Starting proot-avm Web Dashboard..."
echo "📱 Open http://localhost:3000 in your browser"
npm start