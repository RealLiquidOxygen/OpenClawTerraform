# OpenClaw.ai API Health Check & Failover Monitor (Windows PowerShell)
# Runs every 30 minutes to monitor Claude API and switch to Llama 3 if needed
# Version: 2.0

param(
    [switch]$Daemon = $false
)

$LogDir = "$env:APPDATA\OpenClaw\logs"
$ConfigFile = "$env:APPDATA\OpenClaw\config.yml"
$HealthLog = "$LogDir\health_check.log"
$ModelLog = "$LogDir\model_switches.log"

# Ensure log directory exists
if (!(Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

# Log function
function Log-Message {
    param(
        [string]$Level,
        [string]$Message
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to file
    Add-Content -Path $HealthLog -Value $logEntry -Force
    
    # Write to console with colors
    switch ($Level) {
        "ERROR" { Write-Host "[ERROR] $Message" -ForegroundColor Red }
        "SUCCESS" { Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
        "WARNING" { Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
        default { Write-Host "[INFO] $Message" -ForegroundColor Cyan }
    }
}

# Read configuration value
function Get-ConfigValue {
    param([string]$Key)
    
    if (Test-Path $ConfigFile) {
        $value = Select-String -Path $ConfigFile -Pattern "^${Key}:" | ForEach-Object { $_ -replace "^.*:\s*", "" -replace '"', '' }
        return $value
    }
    return $null
}

# Get current model
function Get-CurrentModel {
    $port = Get-ConfigValue "port"
    
    if ($port) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:${port}/model" -TimeoutSec 5 -ErrorAction SilentlyContinue
            $model = $response.Content | ConvertFrom-Json | Select-Object -ExpandProperty model
            return $model
        }
        catch {
            # Fallback: check if Ollama is accessible
            try {
                $null = ollama list
                return "llama3"
            }
            catch {
                return "claude"
            }
        }
    }
    return "claude"
}

# Check Claude API health
function Test-ClaudeAPI {
    $timeout = [TimeSpan]::FromSeconds(10)
    $url = "https://api.anthropic.com/v1/health"
    
    try {
        $response = Invoke-WebRequest -Uri $url -TimeoutSec 10 -ErrorAction SilentlyContinue
        return $response.StatusCode -eq 200 -or $response.StatusCode -eq 204
    }
    catch {
        return $false
    }
}

# Check Ollama/Llama3 availability
function Test-OllamaAvailable {
    try {
        $models = ollama list 2>$null
        return $models -match "llama2"
    }
    catch {
        return $false
    }
}

# Switch model
function Switch-Model {
    param([string]$TargetModel)
    
    Log-Message "ACTION" "Switching to model: $TargetModel"
    
    $port = Get-ConfigValue "port"
    if (!$port) {
        Log-Message "ERROR" "Could not determine port"
        return $false
    }
    
    try {
        $body = @{ model = $TargetModel } | ConvertTo-Json
        $response = Invoke-WebRequest -Uri "http://localhost:${port}/model/switch" `
            -Method POST `
            -ContentType "application/json" `
            -Body $body `
            -TimeoutSec 10 `
            -ErrorAction SilentlyContinue
        
        if ($response.StatusCode -eq 200) {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Add-Content -Path $ModelLog -Value "[$timestamp] Switched to: $TargetModel"
            Log-Message "SUCCESS" "Successfully switched to $TargetModel"
            return $true
        }
    }
    catch {
        Log-Message "WARNING" "Model switch request sent but unable to verify completion"
    }
    
    return $false
}

# Main health check
function Invoke-HealthCheck {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    Log-Message "INFO" "=== Starting Health Check ==="
    
    # Get current model
    $currentModel = Get-CurrentModel
    Log-Message "INFO" "Current model: $currentModel"
    
    # Check Claude API health
    if (Test-ClaudeAPI) {
        Log-Message "SUCCESS" "Claude API is responding"
        
        # If we're on Llama 3, try to switch back to Claude
        if ($currentModel -eq "llama3" -or $currentModel -eq "llama2") {
            Log-Message "INFO" "API recovered, switching back to Claude (primary)"
            Switch-Model "claude"
        }
    }
    else {
        Log-Message "WARNING" "Claude API not responding or timeout"
        
        # Check if Ollama/Llama3 is available
        if (Test-OllamaAvailable) {
            Log-Message "INFO" "Ollama/Llama 3 is available"
            
            # If we're on Claude, switch to Llama 3
            if ($currentModel -eq "claude") {
                Log-Message "WARNING" "Claude down, switching to Llama 3 (fallback)"
                Switch-Model "llama3"
            }
        }
        else {
            Log-Message "ERROR" "Claude API down AND Ollama/Llama 3 not available!"
            Log-Message "ERROR" "Bot may be unable to respond. Manual intervention may be needed."
        }
    }
    
    Log-Message "INFO" "=== Health Check Complete ==="
}

# Main execution
if ($Daemon) {
    Log-Message "INFO" "Starting health check daemon (30-minute interval)"
    
    while ($true) {
        Invoke-HealthCheck
        Log-Message "INFO" "Next health check in 30 minutes..."
        Start-Sleep -Seconds 1800  # 30 minutes
    }
}
else {
    # Single run
    Invoke-HealthCheck
}
