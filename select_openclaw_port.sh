#!/bin/bash
#
# OpenClaw.ai Port Selector Script
# Automatically finds an available random port and logs it
# Usage: ./select_openclaw_port.sh
#

OUTPUT_LOG="output.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Clear previous log
> "$OUTPUT_LOG"

echo "OpenClaw.ai Port Selection Tool" >> "$OUTPUT_LOG"
echo "=================================" >> "$OUTPUT_LOG"
echo "Timestamp: $TIMESTAMP" >> "$OUTPUT_LOG"
echo "" >> "$OUTPUT_LOG"

# Function to check if port is available
is_port_available() {
    local port=$1
    # Check if port is listening
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 1  # Port in use
    fi
    return 0  # Port available
}

# Generate random port between 8000-9999 (user ports, less likely to conflict)
# Avoid common ports: 8000-8100, 9000-9100
# Focus on 8500-8999 range for better randomization
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
echo "FIREWALL RULES:" >> "$OUTPUT_LOG"
echo "sudo ufw allow from [TAILSCALE_IP] to any port $SELECTED_PORT" >> "$OUTPUT_LOG"
echo "" >> "$OUTPUT_LOG"
echo "Log created: $OUTPUT_LOG" >> "$OUTPUT_LOG"
echo "Generated: $TIMESTAMP" >> "$OUTPUT_LOG"

# Display to console
cat "$OUTPUT_LOG"

echo ""
echo "Log saved to: $OUTPUT_LOG"
exit 0
