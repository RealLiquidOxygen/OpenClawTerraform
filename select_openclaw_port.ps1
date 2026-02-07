# OpenClaw.ai Port Selector Script (Windows PowerShell)
# Automatically finds an available random port and logs it
# Usage: powershell -ExecutionPolicy Bypass -File select_openclaw_port.ps1
# Or: .\select_openclaw_port.ps1 (if execution policy allows)

$OUTPUT_LOG = "output.log"
$TIMESTAMP = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Clear previous log
Clear-Content -Path $OUTPUT_LOG -ErrorAction SilentlyContinue

# Initialize log file
$logContent = @()
$logContent += "OpenClaw.ai Port Selection Tool"
$logContent += "================================="
$logContent += "Timestamp: $TIMESTAMP"
$logContent += ""

function Test-PortAvailable {
    param(
        [int]$Port
    )
    
    try {
        # Check if port is listening using netstat
        $netstatOutput = netstat -ano | Select-String ":$Port\s"
        
        if ($netstatOutput) {
            return $false  # Port in use
        }
        
        # Additional check using Get-NetTCPConnection (more reliable on modern Windows)
        try {
            $connection = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
            if ($connection) {
                return $false  # Port in use
            }
        }
        catch {
            # If Get-NetTCPConnection fails, use netstat result
        }
        
        return $true  # Port available
    }
    catch {
        Write-Error "Error checking port $Port : $_"
        return $false
    }
}

function Get-RandomAvailablePort {
    $maxAttempts = 50
    $attempt = 0
    
    while ($attempt -lt $maxAttempts) {
        # Random port between 8200 and 8999
        $port = 8200 + (Get-Random -Minimum 0 -Maximum 800)
        
        if (Test-PortAvailable -Port $port) {
            return $port
        }
        
        $attempt++
    }
    
    # Fallback: scan range 8500-8900 for first available
    for ($port = 8500; $port -le 8900; $port++) {
        if (Test-PortAvailable -Port $port) {
            return $port
        }
    }
    
    return $null
}

$logContent += "Scanning for available ports..."
$logContent += "Range: 8200-8999 (user ports)"
$logContent += ""

# Get available port
$SELECTED_PORT = Get-RandomAvailablePort

if ($null -eq $SELECTED_PORT) {
    $logContent += "ERROR: Could not find available port"
    $logContent += "Please manually select port between 8000-9999"
    
    $logContent | Out-File -FilePath $OUTPUT_LOG -Encoding UTF8
    Get-Content $OUTPUT_LOG
    exit 1
}

# Verify port is still available
if (-not (Test-PortAvailable -Port $SELECTED_PORT)) {
    $logContent += "ERROR: Port $SELECTED_PORT became unavailable during selection"
    $logContent += "Please run script again"
    
    $logContent | Out-File -FilePath $OUTPUT_LOG -Encoding UTF8
    Get-Content $OUTPUT_LOG
    exit 1
}

# Log the result
$logContent += "✅ PORT SELECTION SUCCESSFUL"
$logContent += "============================="
$logContent += ""
$logContent += "SELECTED PORT: $SELECTED_PORT"
$logContent += ""
$logContent += "Status: Available ✓"
$logContent += "Type: TCP (user port)"
$logContent += ""
$logContent += "NEXT STEPS:"
$logContent += "1. Use port $SELECTED_PORT for OpenClaw gateway"
$logContent += "2. When CloudBot asks you to change port, tell it: $SELECTED_PORT"
$logContent += "3. In firewall rules, allow port: $SELECTED_PORT"
$logContent += ""
$logContent += "CONFIGURATION COMMAND:"
$logContent += "Ask CloudBot: 'Set my gateway port to $SELECTED_PORT'"
$logContent += ""
$logContent += "FIREWALL RULES (Windows Defender Firewall):"
$logContent += "netsh advfirewall firewall add rule name='OpenClaw Port $SELECTED_PORT' dir=in action=allow protocol=tcp localport=$SELECTED_PORT"
$logContent += ""
$logContent += "Or using PowerShell (as Administrator):"
$logContent += "New-NetFirewallRule -DisplayName 'OpenClaw Port $SELECTED_PORT' -Direction Inbound -Action Allow -Protocol TCP -LocalPort $SELECTED_PORT"
$logContent += ""
$logContent += "Log created: $OUTPUT_LOG"
$logContent += "Generated: $TIMESTAMP"

# Write to file
$logContent | Out-File -FilePath $OUTPUT_LOG -Encoding UTF8

# Display to console
Get-Content $OUTPUT_LOG

Write-Host ""
Write-Host "Log saved to: $OUTPUT_LOG"
exit 0
