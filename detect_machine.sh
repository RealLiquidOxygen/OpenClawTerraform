#!/bin/bash
#
# Machine Detection Script
# Automatically detects OS and hardware info
# Works on: macOS, Linux, Windows (WSL2/Git Bash)
#

detect_os() {
    case "$(uname -s)" in
        Darwin*)
            echo "macOS"
            ;;
        Linux*)
            # Detect Linux distribution
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                if [[ "$ID" == "ubuntu" ]]; then
                    echo "Linux_Ubuntu"
                elif [[ "$ID" == "fedora" ]]; then
                    echo "Linux_Fedora"
                elif [[ "$ID" == "debian" ]]; then
                    echo "Linux_Debian"
                elif [[ "$ID" == "rhel" ]] || [[ "$ID" == "centos" ]]; then
                    echo "Linux_RHEL"
                else
                    echo "Linux_Other"
                fi
            else
                echo "Linux_Other"
            fi
            ;;
        CYGWIN*|MINGW*|MSYS*)
            echo "Windows_WSL"
            ;;
        *)
            echo "Unknown"
            ;;
    esac
}

detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64)
            echo "x86_64"
            ;;
        aarch64|arm64)
            echo "ARM64"
            ;;
        *)
            echo "Unknown"
            ;;
    esac
}

detect_memory() {
    case "$(uname -s)" in
        Darwin*)
            sysctl -n hw.memsize | awk '{printf "%.0f", $1 / (1024^3)}'
            ;;
        Linux*)
            grep MemTotal /proc/meminfo | awk '{printf "%.0f", $2 / (1024*1024)}'
            ;;
        *)
            echo "Unknown"
            ;;
    esac
}

detect_disk() {
    case "$(uname -s)" in
        Darwin*)
            diskutil info / | grep "Free Space" | awk '{print $4 " " $5}'
            ;;
        Linux*)
            df -h / | awk 'NR==2 {print $4}'
            ;;
        *)
            echo "Unknown"
            ;;
    esac
}

# Main detection
OS=$(detect_os)
ARCH=$(detect_arch)
MEMORY=$(detect_memory)
DISK=$(detect_disk)

# Output in JSON-like format for easy parsing
cat << EOF
{
  "os": "$OS",
  "architecture": "$ARCH",
  "memory_gb": "$MEMORY",
  "free_disk": "$DISK"
}
EOF
