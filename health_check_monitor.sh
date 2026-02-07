#!/bin/bash

# OpenClaw.ai API Health Check & Failover Monitor
# Runs every 30 minutes to monitor Claude API and switch to Llama 3 if needed
# Version: 2.0

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOG_DIR="${HOME}/.openclaw/logs"
CONFIG_FILE="${HOME}/.openclaw/config.yml"
HEALTH_LOG="${LOG_DIR}/health_check.log"
MODEL_LOG="${LOG_DIR}/model_switches.log"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log function
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" >> "$HEALTH_LOG"
    
    if [ "$level" == "ERROR" ]; then
        echo -e "${RED}[${level}] ${message}${NC}"
    elif [ "$level" == "SUCCESS" ]; then
        echo -e "${GREEN}[${level}] ${message}${NC}"
    elif [ "$level" == "WARNING" ]; then
        echo -e "${YELLOW}[${level}] ${message}${NC}"
    else
        echo -e "${BLUE}[${level}] ${message}${NC}"
    fi
}

# Read configuration
get_config_value() {
    local key=$1
    grep "^${key}:" "$CONFIG_FILE" | cut -d' ' -f2 | tr -d '"'
}

# Get current model from OpenClaw
get_current_model() {
    local port=$(get_config_value "port")
    
    # Try to get model from OpenClaw API
    local model=$(curl -s http://localhost:${port}/model 2>/dev/null | grep -o '"model":"[^"]*' | cut -d'"' -f4)
    
    if [ -z "$model" ]; then
        # Fallback: check if Ollama is accessible
        if command -v ollama &> /dev/null; then
            echo "llama3"
        else
            echo "claude"
        fi
    else
        echo "$model"
    fi
}

# Check Claude API health
check_claude_api() {
    local timeout=10
    local url="https://api.anthropic.com/v1/health"
    
    # Use curl to check API health
    local response=$(curl -s -m "$timeout" -w "\n%{http_code}" "$url" 2>/dev/null)
    local http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" == "200" ] || [ "$http_code" == "204" ]; then
        return 0  # Success
    else
        return 1  # Failure
    fi
}

# Check Ollama/Llama3 availability
check_ollama_available() {
    # Check if Ollama service is running
    if ! command -v ollama &> /dev/null; then
        return 1  # Ollama not installed
    fi
    
    # Try to call Ollama
    local response=$(curl -s -m 5 http://localhost:11434/api/tags 2>/dev/null)
    
    if echo "$response" | grep -q "llama2"; then
        return 0  # Llama 3 available
    else
        return 1  # Not available
    fi
}

# Switch model function
switch_model() {
    local target_model=$1
    local port=$(get_config_value "port")
    
    log_message "ACTION" "Switching to model: $target_model"
    
    # Send switch command to OpenClaw
    local response=$(curl -s -X POST "http://localhost:${port}/model/switch" \
        -H "Content-Type: application/json" \
        -d "{\"model\":\"${target_model}\"}" 2>/dev/null)
    
    if echo "$response" | grep -q "success"; then
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo "[${timestamp}] Switched to: ${target_model}" >> "$MODEL_LOG"
        log_message "SUCCESS" "Successfully switched to $target_model"
        return 0
    else
        log_message "WARNING" "Model switch request sent but unable to verify completion"
        return 1
    fi
}

# Main health check logic
main() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    log_message "INFO" "=== Starting Health Check ==="
    
    # Get current model
    local current_model=$(get_current_model)
    log_message "INFO" "Current model: $current_model"
    
    # Check Claude API health
    if check_claude_api; then
        log_message "SUCCESS" "Claude API is responding"
        
        # If we're on Llama 3, try to switch back to Claude
        if [ "$current_model" == "llama3" ] || [ "$current_model" == "llama2" ]; then
            log_message "INFO" "API recovered, switching back to Claude (primary)"
            switch_model "claude"
        fi
    else
        log_message "WARNING" "Claude API not responding or timeout"
        
        # Check if Ollama/Llama3 is available
        if check_ollama_available; then
            log_message "INFO" "Ollama/Llama 3 is available"
            
            # If we're on Claude, switch to Llama 3
            if [ "$current_model" == "claude" ]; then
                log_message "WARNING" "Claude down, switching to Llama 3 (fallback)"
                switch_model "llama3"
            fi
        else
            log_message "ERROR" "Claude API down AND Ollama/Llama 3 not available!"
            log_message "ERROR" "Bot may be unable to respond. Manual intervention may be needed."
        fi
    fi
    
    log_message "INFO" "=== Health Check Complete ==="
}

# If running as a daemon/cron, run indefinitely with 30-min intervals
if [ "$1" == "--daemon" ]; then
    log_message "INFO" "Starting health check daemon (30-minute interval)"
    
    while true; do
        main
        log_message "INFO" "Next health check in 30 minutes..."
        sleep 1800  # 30 minutes
    done
else
    # Single run
    main
fi
