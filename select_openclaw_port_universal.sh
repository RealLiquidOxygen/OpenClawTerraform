#!/bin/bash
#
# OpenClaw.ai Universal Port Selector
# Cross-platform (macOS, Linux, Windows WSL)
# 
# This script detects the OS and uses the appropriate tool for port checking
# Works on: macOS, Linux, Windows (via WSL2 bash), and Windows native cmd
#

OUTPUT_LOG="output.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin*)
            echo "macos"
            ;;
        Linux*)
            echo "linux"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            echo "windows-git-bash"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

OS_TYPE=$(detect_os)

# Clear previous log
> "$OUTPUT_LOG"

echo "OpenClaw.ai Port Selection Tool" >> "$OUTPUT_LOG"
echo "=================================" >> "$OUTPUT_LOG"
echo "Timestamp: $TIMESTAMP" >> "$OUTPUT_LOG"
echo "OS Detected: $OS_TYPE" >> "$OUTPUT_LOG"
echo "" >> "$OUTPUT_LOG"

# Check port availability based on OS
is_port_available() {
    local port=$1
    
    case "$OS_TYPE" in
        macos|linux)
            # Use lsof on macOS and Linux
            if command -v lsof &> /dev/null; then
                if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
                    return 1  # Port in use
                fi
            # Fallback to netstat
            elif command -v netstat &> /dev/null; then
                if netstat -tuln 2>/dev/null | grep -q ":$port "; then
                    return 1  # Port in use
                fi
            # Fallback to ss (systemd systems)
            elif command -v ss &> /dev/null; then
                if ss -tuln 2>/dev/null | grep -q ":$port "; then
                    return 1  # Port in use
                fi
            else
                echo "Warning: Could not find port checking tool (lsof, netstat, or ss)" >> "$OUTPUT_LOG"
                return 0  # Assume available if can't check
            fi
            ;;
        windows-git-bash)
            # Windows with Git Bash - try to use available tools
            if command -v netstat &> /dev/null; then
                if netstat -ano 2>/dev/null | grep -i "listening" | grep -q ":$port "; then
                    return 1  # Port in use
                fi
            else
                # Fallback: try a connection (crude but works)
                (echo > /dev/tcp/127.0.0.1/$port) >/dev/null 2>&1
                if [ $? -eq 0 ]; then
                    return 1  # Port in use
                fi
            fi
            ;;
        *)
            echo "Unknown OS, attempting generic port check" >> "$OUTPUT_LOG"
            # Generic TCP check (might not work everywhere)
            (echo > /dev/tcp/127.0.0.1/$port) >/dev/null 2>&1
            if [ $? -eq 0 ]; then
                return 1  # Port in use
            fi
            ;;
    esac
    
    return 0  # Port available
}

# Generate random port between 8200-8999
get_random_available_port() {
    local max_attempts=50
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        # Random port between 8200 and 8999
        local port=$((8200 + RANDOM % 800))
        
        if is_port_available $port; then
            echo $port
            return 0
        fi
        
        attempt=$((attempt + 1))
    done
    
    # Fallback: scan range 8500-8900 for first available
    for port in {8500..8900}; do
        if is_port_available $port; then
            echo $port
            return 0
        fi
    done
    
    return 1
}

echo "Scanning for available ports..." >> "$OUTPUT_LOG"
echo "Range: 8200-8999 (user ports)" >> "$OUTPUT_LOG"
echo "" >> "$OUTPUT_LOG"

# Get available port
SELECTED_PORT=$(get_random_available_port)

if [ -z "$SELECTED_PORT" ]; then
    echo "ERROR: Could not find available port" >> "$OUTPUT_LOG"
    echo "Please manually select port between 8000-9999" >> "$OUTPUT_LOG"
    cat "$OUTPUT_LOG"
    exit 1
fi

# Verify port is actually available one more time
if ! is_port_available $SELECTED_PORT; then
    echo "ERROR: Port $SELECTED_PORT became unavailable during selection" >> "$OUTPUT_LOG"
    echo "Please run script again" >> "$OUTPUT_LOG"
    cat "$OUTPUT_LOG"
    exit 1
fi

# Log the result
echo "✅ PORT SELECTION SUCCESSFUL" >> "$OUTPUT_LOG"
echo "============================" >> "$OUTPUT_LOG"
echo "" >> "$OUTPUT_LOG"
echo "SELECTED PORT: $SELECTED_PORT" >> "$OUTPUT_LOG"
echo "" >> "$OUTPUT_LOG"
echo "Status: Available ✓" >> "$OUTPUT_LOG"
echo "Type: TCP (user port)" >> "$OUTPUT_LOG"
echo "" >> "$OUTPUT_LOG"
echo "NEXT STEPS:" >> "$OUTPUT_LOG"
echo "1. Use port $SELECTED_PORT for OpenClaw gateway" >> "$OUTPUT_LOG"
echo "2. When CloudBot asks you to change port, tell it: $SELECTED_PORT" >> "$OUTPUT_LOG"
echo "3. In firewall rules, allow port: $SELECTED_PORT" >> "$OUTPUT_LOG"
echo "" >> "$OUTPUT_LOG"
echo "CONFIGURATION COMMAND:" >> "$OUTPUT_LOG"
echo "Ask CloudBot: 'Set my gateway port to $SELECTED_PORT'" >> "$OUTPUT_LOG"
echo "" >> "$OUTPUT_LOG"

# OS-specific firewall instructions
case "$OS_TYPE" in
    macos)
        echo "FIREWALL RULES (macOS):" >> "$OUTPUT_LOG"
        echo "sudo ufw allow from any to any port $SELECTED_PORT" >> "$OUTPUT_LOG"
        echo "Or via pf:" >> "$OUTPUT_LOG"
        echo "echo 'pass in proto tcp from any to any port $SELECTED_PORT' | sudo pfctl -f -" >> "$OUTPUT_LOG"
        ;;
    linux)
        echo "FIREWALL RULES (Linux/Ubuntu):" >> "$OUTPUT_LOG"
        echo "sudo ufw allow $SELECTED_PORT/tcp" >> "$OUTPUT_LOG"
        echo "Or via iptables:" >> "$OUTPUT_LOG"
        echo "sudo iptables -A INPUT -p tcp --dport $SELECTED_PORT -j ACCEPT" >> "$OUTPUT_LOG"
        ;;
    windows-git-bash)
        echo "FIREWALL RULES (Windows via Git Bash):" >> "$OUTPUT_LOG"
        echo "Run in PowerShell as Administrator:" >> "$OUTPUT_LOG"
        echo "New-NetFirewallRule -DisplayName 'OpenClaw Port $SELECTED_PORT' -Direction Inbound -Action Allow -Protocol TCP -LocalPort $SELECTED_PORT" >> "$OUTPUT_LOG"
        echo "Or use cmd as Administrator:" >> "$OUTPUT_LOG"
        echo "netsh advfirewall firewall add rule name='OpenClaw Port $SELECTED_PORT' dir=in action=allow protocol=tcp localport=$SELECTED_PORT" >> "$OUTPUT_LOG"
        ;;
    *)
        echo "FIREWALL RULES:" >> "$OUTPUT_LOG"
        echo "Allow port $SELECTED_PORT in your system firewall" >> "$OUTPUT_LOG"
        ;;
esac

echo "" >> "$OUTPUT_LOG"
echo "Log created: $OUTPUT_LOG" >> "$OUTPUT_LOG"
echo "Generated: $TIMESTAMP" >> "$OUTPUT_LOG"

# Display to console
cat "$OUTPUT_LOG"

echo ""
echo "Log saved to: $OUTPUT_LOG"
exit 0
