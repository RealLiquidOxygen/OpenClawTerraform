# OpenClaw.ai Skill Security Scanner (PowerShell)
# Scans Alexa/Google skills for prompt injection, malicious patterns, and code vulnerabilities
# Version: 1.0

param(
    [switch]$GenerateReport = $false,
    [switch]$QuarantineThreats = $true
)

$LogDir = "$env:APPDATA\OpenClaw\logs"
$ScanReport = "$LogDir\skill_security_scan.log"
$ThreatReport = "$LogDir\skill_threats_found.log"
$QuarantineDir = "$env:APPDATA\OpenClaw\quarantine"

# Ensure directories exist
if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }
if (!(Test-Path $QuarantineDir)) { New-Item -ItemType Directory -Path $QuarantineDir -Force | Out-Null }

# Logging function
function Log-Message {
    param(
        [string]$Level,
        [string]$Message
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    Add-Content -Path $ScanReport -Value $logEntry -Force
    
    switch ($Level) {
        "CRITICAL" { Write-Host "[CRITICAL] $Message" -ForegroundColor Red }
        "WARNING" { Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
        "SUCCESS" { Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
        default { Write-Host "[INFO] $Message" -ForegroundColor Cyan }
    }
}

# Threat detection patterns
$ThreatPatterns = @(
    # Prompt injection
    "ignore previous instructions",
    "forget your instructions",
    "you are now",
    "pretend you are",
    "system prompt",
    
    # Code execution
    "eval\(",
    "exec\(",
    "system\(",
    "subprocess",
    
    # SQL injection
    "union select",
    "drop table",
    "delete from",
    
    # Command injection
    "bash -c",
    "sh -c",
    
    # File access
    "/etc/passwd",
    "/.ssh/",
    "/root/",
    
    # Backdoors
    "reverse shell",
    "nc -e",
    "bash -i"
)

# Scan skill manifest
function Scan-SkillManifest {
    param([string]$SkillPath)
    
    $skillName = Split-Path -Leaf $SkillPath
    $threatsFound = 0
    
    Log-Message "INFO" "Scanning manifest: $skillName"
    
    $manifestPath = Join-Path $SkillPath "manifest.json"
    
    if (!(Test-Path $manifestPath)) {
        Log-Message "WARNING" "No manifest.json in $skillName"
        return 0
    }
    
    try {
        $manifestContent = Get-Content -Path $manifestPath -Raw
        
        # Check for HTTP (not HTTPS)
        if ($manifestContent -match '"endpoint"\s*:\s*"http://' -and $manifestContent -notmatch '"endpoint"\s*:\s*"https://') {
            Log-Message "WARNING" "Skill uses HTTP endpoint (should be HTTPS): $skillName"
            Add-Content -Path $ThreatReport -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] THREAT: $skillName - HTTP endpoint"
            $threatsFound++
        }
        
        # Check for excessive permissions
        if ($manifestContent -match '"permissions"' -and $manifestContent -match '(dangerous|admin|root|system)') {
            Log-Message "WARNING" "Excessive permissions in $skillName"
            Add-Content -Path $ThreatReport -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] THREAT: $skillName - Excessive permissions"
            $threatsFound++
        }
    }
    catch {
        Log-Message "WARNING" "Error reading manifest: $_"
    }
    
    return $threatsFound
}

# Scan skill code
function Scan-SkillCode {
    param([string]$SkillPath)
    
    $skillName = Split-Path -Leaf $SkillPath
    $threatsFound = 0
    
    # Find code files
    $codeFiles = @(Get-ChildItem -Path $SkillPath -Include "*.js","*.py","*.java","*.ts" -Recurse -ErrorAction SilentlyContinue)
    
    foreach ($file in $codeFiles) {
        try {
            $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
            
            # Check threat patterns
            foreach ($pattern in $ThreatPatterns) {
                if ($content -match $pattern) {
                    Log-Message "CRITICAL" "THREAT in $skillName - pattern '$pattern' found"
                    Add-Content -Path $ThreatReport -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] CRITICAL: $skillName - '$pattern'"
                    $threatsFound += 2
                }
            }
            
            # Check for eval/exec
            if ($content -match 'eval\(|exec\(|system\(|subprocess\.|Runtime\.exec') {
                Log-Message "WARNING" "Dynamic execution in $skillName"
                Add-Content -Path $ThreatReport -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] WARNING: $skillName - Dynamic execution"
                $threatsFound++
            }
            
            # Check for hardcoded credentials
            if ($content -match '(password|api_key|secret|token)\s*=' -and $content -notmatch '(env\.|process\.|import)') {
                Log-Message "CRITICAL" "HARDCODED CREDENTIALS in $skillName"
                Add-Content -Path $ThreatReport -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] CRITICAL: $skillName - Hardcoded credentials"
                $threatsFound += 2
            }
            
            # Check for unvalidated input
            if ($content -match '(input|request|params)\s*=' -and $content -notmatch '(validate|sanitize|escape|check)') {
                Log-Message "WARNING" "Unvalidated input in $skillName"
                $threatsFound++
            }
        }
        catch {
            Log-Message "WARNING" "Error scanning file: $($file.Name)"
        }
    }
    
    return $threatsFound
}

# Scan dependencies
function Scan-SkillDependencies {
    param([string]$SkillPath)
    
    $skillName = Split-Path -Leaf $SkillPath
    $threatsFound = 0
    
    $packageJsonPath = Join-Path $SkillPath "package.json"
    
    if (Test-Path $packageJsonPath) {
        try {
            $packageContent = Get-Content -Path $packageJsonPath -Raw
            
            $vulnerablePackages = @("lodash", "moment", "xmlrpc", "serialize-javascript")
            
            foreach ($pkg in $vulnerablePackages) {
                if ($packageContent -match [regex]::Escape("`"$pkg`"")) {
                    Log-Message "WARNING" "Vulnerable package '$pkg' in $skillName"
                    Add-Content -Path $ThreatReport -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] WARNING: $skillName - Uses '$pkg'"
                    $threatsFound++
                }
            }
        }
        catch {
            Log-Message "WARNING" "Error scanning package.json"
        }
    }
    
    return $threatsFound
}

# Quarantine skill
function Quarantine-Skill {
    param([string]$SkillPath)
    
    $skillName = Split-Path -Leaf $SkillPath
    
    Log-Message "WARNING" "Quarantining skill: $skillName"
    
    try {
        $timestamp = Get-Date -UFormat %s
        $quarantinePath = Join-Path $QuarantineDir "${skillName}_quarantined_$timestamp"
        Move-Item -Path $SkillPath -Destination $quarantinePath -Force
        Add-Content -Path $ThreatReport -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] QUARANTINED: $skillName"
        return $true
    }
    catch {
        Log-Message "WARNING" "Failed to quarantine: $_"
        return $false
    }
}

# Main scan function
function Run-SecurityScan {
    Log-Message "INFO" "=== Starting Skill Security Scan ==="
    
    $skillsDir = "$env:APPDATA\OpenClaw\skills"
    $alexaSkillsDir = Join-Path $skillsDir "alexa"
    $googleSkillsDir = Join-Path $skillsDir "google"
    
    $totalSkills = 0
    $cleanSkills = 0
    $suspiciousSkills = 0
    $criticalSkills = 0
    
    # Scan Alexa skills
    if (Test-Path $alexaSkillsDir) {
        Log-Message "INFO" "Scanning Alexa skills..."
        
        foreach ($skill in Get-ChildItem -Path $alexaSkillsDir -Directory -ErrorAction SilentlyContinue) {
            $totalSkills++
            $threats = 0
            
            $threats += Scan-SkillManifest $skill.FullName
            $threats += Scan-SkillCode $skill.FullName
            $threats += Scan-SkillDependencies $skill.FullName
            
            if ($threats -gt 0) {
                if ($threats -ge 3) {
                    Log-Message "CRITICAL" "Multiple threats in $($skill.Name)"
                    $criticalSkills++
                    if ($QuarantineThreats) {
                        Quarantine-Skill $skill.FullName
                    }
                }
                else {
                    Log-Message "WARNING" "Threats in $($skill.Name)"
                    $suspiciousSkills++
                }
            }
            else {
                Log-Message "SUCCESS" "Clean: $($skill.Name)"
                $cleanSkills++
            }
        }
    }
    
    # Scan Google skills
    if (Test-Path $googleSkillsDir) {
        Log-Message "INFO" "Scanning Google Actions..."
        
        foreach ($skill in Get-ChildItem -Path $googleSkillsDir -Directory -ErrorAction SilentlyContinue) {
            $totalSkills++
            $threats = 0
            
            $threats += Scan-SkillManifest $skill.FullName
            $threats += Scan-SkillCode $skill.FullName
            $threats += Scan-SkillDependencies $skill.FullName
            
            if ($threats -gt 0) {
                if ($threats -ge 3) {
                    Log-Message "CRITICAL" "Multiple threats in $($skill.Name)"
                    $criticalSkills++
                    if ($QuarantineThreats) {
                        Quarantine-Skill $skill.FullName
                    }
                }
                else {
                    Log-Message "WARNING" "Threats in $($skill.Name)"
                    $suspiciousSkills++
                }
            }
            else {
                Log-Message "SUCCESS" "Clean: $($skill.Name)"
                $cleanSkills++
            }
        }
    }
    
    # Summary
    Log-Message "INFO" "=== Scan Complete ==="
    Log-Message "INFO" "Total: $totalSkills | Clean: $cleanSkills | Suspicious: $suspiciousSkills | Critical: $criticalSkills"
    
    if ($criticalSkills -gt 0) {
        return 2
    }
    elseif ($suspiciousSkills -gt 0) {
        return 1
    }
    
    return 0
}

# Main execution
Write-Host "========================================"
Write-Host "OpenClaw Skill Security Scanner v1.0"
Write-Host "========================================"
Write-Host ""

$status = Run-SecurityScan

if ($GenerateReport) {
    Write-Host "Generating report..." -ForegroundColor Cyan
    # Report generation (simplified for PowerShell)
}

Write-Host ""
switch ($status) {
    0 { Log-Message "SUCCESS" "All skills passed security check" }
    1 { Log-Message "WARNING" "Some skills have warnings" }
    2 { Log-Message "CRITICAL" "Critical threats found - check quarantine" }
}

exit $status
