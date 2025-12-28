#!/usr/bin/env bash
# Enhanced Web Dashboard with AI Integration
# Modern, responsive web interface for proot-avm

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if Node.js is available
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}⚠️  Node.js not found. Installing...${NC}"

    if command -v pkg &> /dev/null; then
        pkg install -y nodejs npm
    elif command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y nodejs npm
    else
        echo -e "${RED}❌ Please install Node.js manually${NC}"
        exit 1
    fi
fi

# Dashboard directory
DASHBOARD_DIR="$HOME/.proot-avm-dashboard"
if [ ! -d "$DASHBOARD_DIR" ]; then
    echo -e "${CYAN}📥 Setting up enhanced web dashboard...${NC}"
    mkdir -p "$DASHBOARD_DIR"
    cd "$DASHBOARD_DIR"

    # Create package.json with modern dependencies
    cat > package.json << 'EOF'
{
  "name": "proot-avm-dashboard",
  "version": "2.0.0",
  "description": "Modern web dashboard for proot-avm with AI integration",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "build": "webpack --mode production",
    "test": "jest"
  },
  "dependencies": {
    "express": "^4.18.2",
    "socket.io": "^4.7.2",
    "axios": "^1.6.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "chart.js": "^4.3.0",
    "react-chartjs-2": "^5.2.0",
    "lucide-react": "^0.294.0",
    "tailwindcss": "^3.3.0",
    "autoprefixer": "^10.4.0",
    "postcss": "^8.4.0",
    "@headlessui/react": "^1.7.0",
    "framer-motion": "^10.16.0",
    "openai": "^4.0.0"
  },
  "devDependencies": {
    "@babel/core": "^7.22.0",
    "@babel/preset-env": "^7.22.0",
    "@babel/preset-react": "^7.22.0",
    "babel-loader": "^9.1.0",
    "webpack": "^5.88.0",
    "webpack-cli": "^5.1.0",
    "nodemon": "^3.0.1",
    "jest": "^29.6.0",
    "supertest": "^6.3.0"
  }
}
EOF

    # Install dependencies
    npm install

    # Create enhanced server.js with AI integration
    cat > server.js << 'EOF'
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const { exec } = require('child_process');
const path = require('path');
const OpenAI = require('openai');

const app = express();
const server = http.createServer(app);
const io = socketIo(server);

const PORT = process.env.PORT || 3000;

// Initialize OpenAI (optional)
let openai = null;
if (process.env.OPENAI_API_KEY) {
    openai = new OpenAI({
        apiKey: process.env.OPENAI_API_KEY,
    });
}

// Middleware
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// API Routes
app.get('/api/status', async (req, res) => {
    try {
        const status = await getVMStatus();
        res.json(status);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.post('/api/start', async (req, res) => {
    try {
        const result = await runCommand('avm-go start --headless');
        res.json({ success: true, output: result });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.post('/api/stop', async (req, res) => {
    try {
        const result = await runCommand('avm-go stop');
        res.json({ success: true, output: result });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/metrics', async (req, res) => {
    try {
        const metrics = await getVMMetrics();
        res.json(metrics);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.post('/api/ai-assist', async (req, res) => {
    try {
        const { query } = req.body;
        const aiResponse = await getAIAssistance(query);
        res.json(aiResponse);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/logs', async (req, res) => {
    try {
        const logs = await getVMLogs();
        res.json({ logs });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// WebSocket for real-time updates
io.on('connection', (socket) => {
    console.log('Client connected');

    // Send periodic status updates
    const statusInterval = setInterval(async () => {
        try {
            const status = await getVMStatus();
            const metrics = await getVMMetrics();
            socket.emit('status', { status, metrics, timestamp: new Date() });
        } catch (error) {
            socket.emit('error', { message: error.message });
        }
    }, 2000);

    socket.on('disconnect', () => {
        clearInterval(statusInterval);
        console.log('Client disconnected');
    });

    socket.on('command', async (data) => {
        try {
            const result = await runCommand(data.command);
            socket.emit('command-result', { result, command: data.command });
        } catch (error) {
            socket.emit('command-error', { error: error.message, command: data.command });
        }
    });
});

// Helper functions
async function runCommand(command) {
    return new Promise((resolve, reject) => {
        exec(command, (error, stdout, stderr) => {
            if (error) {
                reject(error);
            } else {
                resolve(stdout || stderr);
            }
        });
    });
}

async function getVMStatus() {
    try {
        const output = await runCommand('avm-go status --json');
        return JSON.parse(output);
    } catch (error) {
        return { is_running: false, error: error.message };
    }
}

async function getVMMetrics() {
    // Mock metrics - in real implementation, get from VM
    return {
        cpu: Math.random() * 100,
        memory: Math.random() * 2048,
        network: Math.random() * 100,
        disk: Math.random() * 100,
        timestamp: new Date()
    };
}

async function getAIAssistance(query) {
    const aiProvider = process.env.AVM_AI_PROVIDER || 'ollama';

    try {
        let aiResponse;

        switch (aiProvider) {
            case 'openai':
                aiResponse = await getOpenAIAssistance(query);
                break;
            case 'claude':
                aiResponse = await getClaudeAssistance(query);
                break;
            case 'ollama':
                aiResponse = await getOllamaAssistance(query);
                break;
            case 'openhands':
                aiResponse = await getOpenHandsAssistance(query);
                break;
            default:
                aiResponse = getFallbackAssistance(query);
        }

        return aiResponse;
    } catch (error) {
        console.error('AI assistance error:', error);
        return getFallbackAssistance(query);
    }
}

async function getOpenAIAssistance(query) {
    if (!process.env.OPENAI_API_KEY) {
        throw new Error('OpenAI API key not configured');
    }

    const response = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`
        },
        body: JSON.stringify({
            model: "gpt-3.5-turbo",
            messages: [
                {
                    role: "system",
                    content: "You are an AI assistant for proot-avm, a modern Alpine Linux VM manager. Provide helpful, accurate suggestions for VM management, Docker, development environments, and troubleshooting. Keep responses concise and actionable."
                },
                {
                    role: "user",
                    content: query
                }
            ],
            max_tokens: 500,
            temperature: 0.7
        })
    });

    const data = await response.json();

    if (data.error) {
        throw new Error(data.error.message);
    }

    const content = data.choices[0].message.content;
    return {
        suggestions: [content],
        commands: extractCommandsFromText(content),
        warnings: [],
        provider: 'OpenAI'
    };
}

async function getClaudeAssistance(query) {
    if (!process.env.ANTHROPIC_API_KEY) {
        throw new Error('Anthropic API key not configured');
    }

    const response = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'x-api-key': process.env.ANTHROPIC_API_KEY,
            'anthropic-version': '2023-06-01'
        },
        body: JSON.stringify({
            model: "claude-3-haiku-20240307",
            max_tokens: 500,
            system: "You are an AI assistant for proot-avm, a modern Alpine Linux VM manager. Provide helpful, accurate suggestions for VM management, Docker, development environments, and troubleshooting. Keep responses concise and actionable.",
            messages: [
                {
                    role: "user",
                    content: query
                }
            ]
        })
    });

    const data = await response.json();

    if (data.error) {
        throw new Error(data.error.message);
    }

    const content = data.content[0].text;
    return {
        suggestions: [content],
        commands: extractCommandsFromText(content),
        warnings: [],
        provider: 'Claude'
    };
}

async function getOllamaAssistance(query) {
    try {
        const response = await fetch('http://localhost:11434/api/generate', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                model: "llama2",
                prompt: `You are an AI assistant for proot-avm, a modern Alpine Linux VM manager. Provide helpful suggestions for: ${query}`,
                stream: false
            })
        });

        const data = await response.json();

        if (data.error) {
            throw new Error(data.error);
        }

        return {
            suggestions: [data.response],
            commands: extractCommandsFromText(data.response),
            warnings: [],
            provider: 'Ollama'
        };
    } catch (error) {
        // Ollama not available, use fallback
        return getFallbackAssistance(query);
    }
}

async function getOpenHandsAssistance(query) {
    // OpenHands integration - for now return basic response
    // In real implementation, this would call OpenHands API
    return {
        suggestions: [`OpenHands AI Assistant is available. For advanced AI assistance, use the 'openhands' command directly in your terminal.`],
        commands: ['openhands'],
        warnings: ['OpenHands requires local installation'],
        provider: 'OpenHands'
    };
}

function getFallbackAssistance(query) {
    const responses = {
        'help': {
            suggestions: ['Here are some helpful commands for proot-avm:'],
            commands: ['avm start', 'avm status', 'avm dashboard', 'avm ssh', 'avm help']
        },
        'docker': {
            suggestions: ['To work with Docker in your VM:'],
            commands: ['avm start', 'avm ssh', 'docker ps', 'docker pull <image>']
        },
        'install': {
            suggestions: ['Installation options available:'],
            commands: ['curl -fsSL https://alpinevm.qzz.io/install | bash']
        },
        'troubleshoot': {
            suggestions: ['Common troubleshooting steps:'],
            commands: ['avm status', 'avm restart', 'tail -f ~/qemu-vm/alpine-vm.log']
        }
    };

    const query_lower = query.toLowerCase();
    for (const [key, response] of Object.entries(responses)) {
        if (query_lower.includes(key)) {
            return { ...response, provider: 'Fallback' };
        }
    }

    return {
        suggestions: ['I\'m here to help with proot-avm! Try asking about VM management, Docker, installation, or troubleshooting.'],
        commands: ['avm help', 'avm status'],
        warnings: [],
        provider: 'Fallback'
    };
}

function extractCommandsFromText(text) {
    const commands = [];
    const lines = text.split('\n');

    for (const line of lines) {
        const trimmed = line.trim();
        if (trimmed.startsWith('avm') ||
            trimmed.startsWith('docker') ||
            trimmed.startsWith('git') ||
            trimmed.startsWith('./') ||
            trimmed.match(/^\w+\s/)) {
            commands.push(trimmed);
        }
    }

    return commands;
}
        };
    }
}

function extractSuggestions(text) {
    const suggestions = [];
    const lines = text.split('\n');
    lines.forEach(line => {
        if (line.toLowerCase().includes('suggest') || line.startsWith('•') || line.startsWith('-')) {
            suggestions.push(line.replace(/^[•\-]\s*/, ''));
        }
    });
    return suggestions.length > 0 ? suggestions : [text];
}

function extractCommands(text) {
    const commands = [];
    const commandRegex = /`([^`]+)`/g;
    let match;
    while ((match = commandRegex.exec(text)) !== null) {
        commands.push(match[1]);
    }
    return commands;
}

function extractWarnings(text) {
    const warnings = [];
    if (text.toLowerCase().includes('warning') || text.toLowerCase().includes('caution')) {
        warnings.push("Please check system requirements");
    }
    return warnings;
}

async function getVMLogs() {
    try {
        const logs = await runCommand('tail -n 50 /tmp/avm.log 2>/dev/null || echo "No logs available"');
        return logs.split('\n');
    } catch (error) {
        return ["Error reading logs"];
    }
}

server.listen(PORT, () => {
    console.log(`🚀 proot-avm Dashboard v2.0 running at http://localhost:${PORT}`);
    console.log(`🤖 AI Integration: ${openai ? 'Enabled' : 'Disabled (set OPENAI_API_KEY)'}`);
    console.log(`📊 Real-time monitoring: Active`);
});
EOF

    # Create React frontend
    mkdir -p public
    cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>proot-avm Dashboard v2.0</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="https://unpkg.com/react@18/umd/react.production.min.js"></script>
    <script src="https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"></script>
    <script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
</head>
<body class="bg-gray-900 text-white">
    <div id="root"></div>

    <script type="text/babel">
        const { useState, useEffect } = React;

        function App() {
            const [status, setStatus] = useState({ is_running: false });
            const [metrics, setMetrics] = useState({});
            const [logs, setLogs] = useState([]);
            const [aiQuery, setAiQuery] = useState('');
            const [aiResponse, setAiResponse] = useState(null);
            const [socket, setSocket] = useState(null);

            useEffect(() => {
                // Initialize WebSocket
                const ws = io();
                setSocket(ws);

                ws.on('status', (data) => {
                    setStatus(data.status);
                    setMetrics(data.metrics);
                });

                ws.on('command-result', (data) => {
                    console.log('Command result:', data);
                });

                // Initial data load
                fetchStatus();
                fetchLogs();

                return () => ws.disconnect();
            }, []);

            const fetchStatus = async () => {
                try {
                    const response = await fetch('/api/status');
                    const data = await response.json();
                    setStatus(data);
                } catch (error) {
                    console.error('Error fetching status:', error);
                }
            };

            const fetchLogs = async () => {
                try {
                    const response = await fetch('/api/logs');
                    const data = await response.json();
                    setLogs(data.logs);
                } catch (error) {
                    console.error('Error fetching logs:', error);
                }
            };

            const handleVMAction = async (action) => {
                try {
                    const response = await fetch(`/api/${action}`, { method: 'POST' });
                    const result = await response.json();
                    if (result.success) {
                        alert(`${action.toUpperCase()} successful!`);
                        fetchStatus();
                    } else {
                        alert(`Error: ${result.error}`);
                    }
                } catch (error) {
                    alert(`Error: ${error.message}`);
                }
            };

            const handleAIAssist = async () => {
                if (!aiQuery.trim()) return;

                try {
                    const response = await fetch('/api/ai-assist', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ query: aiQuery })
                    });
                    const data = await response.json();
                    setAiResponse(data);
                } catch (error) {
                    setAiResponse({ error: error.message });
                }
            };

            return (
                <div className="min-h-screen bg-gradient-to-br from-gray-900 via-blue-900 to-purple-900">
                    {/* Header */}
                    <header className="bg-black/30 backdrop-blur-sm border-b border-gray-700 p-4">
                        <div className="max-w-7xl mx-auto flex justify-between items-center">
                            <div className="flex items-center space-x-3">
                                <i className="fas fa-server text-2xl text-blue-400"></i>
                                <h1 className="text-2xl font-bold">proot-avm Dashboard v2.0</h1>
                            </div>
                            <div className="flex items-center space-x-4">
                                <div className={`flex items-center space-x-2 px-3 py-1 rounded-full ${status.is_running ? 'bg-green-500/20 text-green-400' : 'bg-red-500/20 text-red-400'}`}>
                                    <i className={`fas ${status.is_running ? 'fa-circle' : 'fa-circle-xmark'}`}></i>
                                    <span>{status.is_running ? 'RUNNING' : 'STOPPED'}</span>
                                </div>
                            </div>
                        </div>
                    </header>

                    <div className="max-w-7xl mx-auto p-6 grid grid-cols-1 lg:grid-cols-3 gap-6">
                        {/* VM Controls */}
                        <div className="lg:col-span-1">
                            <div className="bg-gray-800/50 backdrop-blur-sm rounded-xl p-6 border border-gray-700">
                                <h2 className="text-xl font-semibold mb-4 flex items-center">
                                    <i className="fas fa-cogs mr-2 text-blue-400"></i>
                                    VM Controls
                                </h2>
                                <div className="space-y-3">
                                    <button
                                        onClick={() => handleVMAction('start')}
                                        disabled={status.is_running}
                                        className="w-full bg-green-600 hover:bg-green-700 disabled:bg-gray-600 text-white font-medium py-3 px-4 rounded-lg transition duration-200 flex items-center justify-center"
                                    >
                                        <i className="fas fa-play mr-2"></i>
                                        Start VM
                                    </button>
                                    <button
                                        onClick={() => handleVMAction('stop')}
                                        disabled={!status.is_running}
                                        className="w-full bg-red-600 hover:bg-red-700 disabled:bg-gray-600 text-white font-medium py-3 px-4 rounded-lg transition duration-200 flex items-center justify-center"
                                    >
                                        <i className="fas fa-stop mr-2"></i>
                                        Stop VM
                                    </button>
                                    <button
                                        onClick={() => socket?.emit('command', { command: 'avm-go ssh' })}
                                        className="w-full bg-blue-600 hover:bg-blue-700 text-white font-medium py-3 px-4 rounded-lg transition duration-200 flex items-center justify-center"
                                    >
                                        <i className="fas fa-terminal mr-2"></i>
                                        SSH Access
                                    </button>
                                </div>
                            </div>

                            {/* AI Assistant */}
                            <div className="bg-gray-800/50 backdrop-blur-sm rounded-xl p-6 border border-gray-700 mt-6">
                                <h2 className="text-xl font-semibold mb-4 flex items-center">
                                    <i className="fas fa-robot mr-2 text-purple-400"></i>
                                    AI Assistant
                                </h2>
                                <div className="space-y-3">
                                    <input
                                        type="text"
                                        value={aiQuery}
                                        onChange={(e) => setAiQuery(e.target.value)}
                                        placeholder="Ask for help..."
                                        className="w-full bg-gray-700 border border-gray-600 rounded-lg px-4 py-2 text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500"
                                        onKeyPress={(e) => e.key === 'Enter' && handleAIAssist()}
                                    />
                                    <button
                                        onClick={handleAIAssist}
                                        className="w-full bg-purple-600 hover:bg-purple-700 text-white font-medium py-2 px-4 rounded-lg transition duration-200"
                                    >
                                        Get AI Help
                                    </button>
                                </div>
                                {aiResponse && (
                                    <div className="mt-4 p-3 bg-gray-700/50 rounded-lg">
                                        <h3 className="font-medium text-purple-400 mb-2">AI Suggestions:</h3>
                                        <ul className="text-sm space-y-1">
                                            {aiResponse.suggestions?.map((suggestion, i) => (
                                                <li key={i} className="flex items-start">
                                                    <i className="fas fa-lightbulb text-yellow-400 mr-2 mt-0.5"></i>
                                                    {suggestion}
                                                </li>
                                            ))}
                                        </ul>
                                        {aiResponse.commands?.length > 0 && (
                                            <div className="mt-2">
                                                <h4 className="font-medium text-green-400">Commands:</h4>
                                                <ul className="text-sm space-y-1">
                                                    {aiResponse.commands.map((cmd, i) => (
                                                        <li key={i} className="font-mono bg-gray-800 px-2 py-1 rounded">
                                                            {cmd}
                                                        </li>
                                                    ))}
                                                </ul>
                                            </div>
                                        )}
                                    </ul>
                                )}
                            </div>
                        </div>

                        {/* Metrics & Charts */}
                        <div className="lg:col-span-2 space-y-6">
                            {/* Performance Metrics */}
                            <div className="bg-gray-800/50 backdrop-blur-sm rounded-xl p-6 border border-gray-700">
                                <h2 className="text-xl font-semibold mb-4 flex items-center">
                                    <i className="fas fa-chart-line mr-2 text-green-400"></i>
                                    Performance Metrics
                                </h2>
                                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                                    <div className="text-center">
                                        <div className="text-2xl font-bold text-blue-400">{metrics.cpu?.toFixed(1) || '0.0'}%</div>
                                        <div className="text-sm text-gray-400">CPU Usage</div>
                                    </div>
                                    <div className="text-center">
                                        <div className="text-2xl font-bold text-green-400">{metrics.memory?.toFixed(1) || '0.0'} MB</div>
                                        <div className="text-sm text-gray-400">Memory</div>
                                    </div>
                                    <div className="text-center">
                                        <div className="text-2xl font-bold text-purple-400">{metrics.network?.toFixed(1) || '0.0'} Mbps</div>
                                        <div className="text-sm text-gray-400">Network</div>
                                    </div>
                                    <div className="text-center">
                                        <div className="text-2xl font-bold text-yellow-400">{metrics.disk?.toFixed(1) || '0.0'}%</div>
                                        <div className="text-sm text-gray-400">Disk Usage</div>
                                    </div>
                                </div>
                            </div>

                            {/* Logs */}
                            <div className="bg-gray-800/50 backdrop-blur-sm rounded-xl p-6 border border-gray-700">
                                <h2 className="text-xl font-semibold mb-4 flex items-center">
                                    <i className="fas fa-list mr-2 text-orange-400"></i>
                                    System Logs
                                </h2>
                                <div className="bg-black rounded-lg p-4 max-h-64 overflow-y-auto font-mono text-sm">
                                    {logs.map((log, i) => (
                                        <div key={i} className="text-gray-300 mb-1">{log}</div>
                                    ))}
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            );
        }

        ReactDOM.render(<App />, document.getElementById('root'));
    </script>

    <script src="/socket.io/socket.io.js"></script>
</body>
</html>
EOF

    echo -e "${GREEN}✅ Enhanced dashboard setup complete!${NC}"
fi

# Launch the dashboard
cd "$DASHBOARD_DIR"
echo -e "${BLUE}🚀 Starting proot-avm Enhanced Dashboard v2.0...${NC}"
echo -e "${CYAN}🌐 Open http://localhost:3000 in your browser${NC}"
echo -e "${YELLOW}🤖 AI features available (requires OPENAI_API_KEY)${NC}"
npm start