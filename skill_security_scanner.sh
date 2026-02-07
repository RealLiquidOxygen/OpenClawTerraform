#!/bin/bash

# OpenClaw.ai Skill Security Scanner
# Scans Alexa/Google skills for prompt injection, malicious patterns, and code vulnerabilities
# Version: 1.0

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOG_DIR="${HOME}/.openclaw/logs"
SCAN_REPORT="${LOG_DIR}/skill_security_scan.log"
THREAT_REPORT="${LOG_DIR}/skill_threats_found.log"
QUARANTINE_DIR="${HOME}/.openclaw/quarantine"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Ensure directories exist
mkdir -p "$LOG_DIR" "$QUARANTINE_DIR"

# Logging function
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" >> "$SCAN_REPORT"
    
    if [ "$level" == "CRITICAL" ]; then
        echo -e "${RED}[CRITICAL] ${message}${NC}"
    elif [ "$level" == "WARNING" ]; then
        echo -e "${YELLOW}[WARNING] ${message}${NC}"
    elif [ "$level" == "SUCCESS" ]; then
        echo -e "${GREEN}[SUCCESS] ${message}${NC}"
    else
        echo -e "${BLUE}[INFO] ${message}${NC}"
    fi
}

# Threat detection patterns
declare -a THREAT_PATTERNS=(
    # Prompt injection attempts
    "ignore previous instructions"
    "forget your instructions"
    "you are now"
    "pretend you are"
    "act as if"
    "system prompt"
    "user prompt"
    "execute this command"
    "run this code"
    "eval("
    "exec("
    
    # SQL injection patterns
    "union select"
    "drop table"
    "delete from"
    "insert into.*values"
    
    # Command injection
    "bash -c"
    "sh -c"
    "system("
    "/bin/sh"
    "/bin/bash"
    
    # File system access
    "cat /etc/passwd"
    "/root/"
    "/.ssh/"
    "/etc/shadow"
    
    # Network exfiltration
    "curl.*-F"
    "wget.*post"
    "nc -l"
    "nc -e"
    
    # Privilege escalation
    "sudo"
    "chmod 777"
    "chown"
    
    # Backdoor indicators
    "reverse shell"
    "nc.*nc"
    "bash -i"
    "python.*socket"
)

# Scan skill manifest for suspicious content
scan_skill_manifest() {
    local skill_path=$1
    local skill_name=$(basename "$skill_path")
    local threats_found=0
    
    log "INFO" "Scanning skill: $skill_name"
    
    # Check if manifest exists
    if [ ! -f "$skill_path/manifest.json" ]; then
        log "WARNING" "No manifest.json found in $skill_name"
        return 1
    fi
    
    # Scan manifest content
    local manifest_content=$(cat "$skill_path/manifest.json" 2>/dev/null)
    
    # Check for suspicious endpoints
    if echo "$manifest_content" | grep -q "endpoint.*http://" && ! grep -q "endpoint.*https://"; then
        log "WARNING" "Skill $skill_name uses HTTP endpoint (not HTTPS) - INSECURE"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] THREAT: $skill_name - HTTP endpoint (should be HTTPS)" >> "$THREAT_REPORT"
        ((threats_found++))
    fi
    
    # Check permissions
    if echo "$manifest_content" | grep -q '"permissions"'; then
        local permissions=$(echo "$manifest_content" | grep -o '"permissions":\[[^]]*\]' 2>/dev/null)
        if echo "$permissions" | grep -qi "dangerous\|admin\|root\|system"; then
            log "WARNING" "Skill $skill_name requests excessive permissions"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] THREAT: $skill_name - Excessive permissions requested" >> "$THREAT_REPORT"
            ((threats_found++))
        fi
    fi
    
    return $threats_found
}

# Scan skill code for malicious patterns
scan_skill_code() {
    local skill_path=$1
    local skill_name=$(basename "$skill_path")
    local threats_found=0
    
    # Find all code files (js, py, java, etc)
    local code_files=$(find "$skill_path" -type f \( -name "*.js" -o -name "*.py" -o -name "*.java" -o -name "*.java" -o -name "*.ts" \) 2>/dev/null)
    
    if [ -z "$code_files" ]; then
        log "WARNING" "No code files found in skill: $skill_name"
        return 1
    fi
    
    for file in $code_files; do
        local content=$(cat "$file" 2>/dev/null)
        
        # Check each threat pattern
        for pattern in "${THREAT_PATTERNS[@]}"; do
            if echo "$content" | grep -iq "$pattern"; then
                log "CRITICAL" "THREAT DETECTED in $skill_name: Pattern '$pattern' found in $(basename $file)"
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] CRITICAL: $skill_name - Pattern '$pattern' found in $(basename $file)" >> "$THREAT_REPORT"
                ((threats_found++))
            fi
        done
        
        # Check for eval/exec patterns (language-specific)
        if echo "$content" | grep -qE "eval\(|exec\(|system\(|subprocess\.|Runtime\.exec"; then
            log "WARNING" "Dynamic code execution detected in $skill_name"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $skill_name - Dynamic execution capability" >> "$THREAT_REPORT"
            ((threats_found++))
        fi
        
        # Check for hardcoded credentials
        if echo "$content" | grep -qiE "password.*=|api[_-]?key.*=|secret.*=|token.*=" | head -1; then
            log "CRITICAL" "HARDCODED CREDENTIALS in $skill_name"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] CRITICAL: $skill_name - Hardcoded credentials found" >> "$THREAT_REPORT"
            ((threats_found++))
        fi
        
        # Check for unvalidated user input
        if echo "$content" | grep -qiE "input\s*=|request\s*=|params\s*=" && ! grep -qi "validate\|sanitize\|escape\|check"; then
            log "WARNING" "Unvalidated user input in $skill_name"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $skill_name - Unvalidated input handling" >> "$THREAT_REPORT"
            ((threats_found++))
        fi
    done
    
    return $threats_found
}

# Check skill dependencies for known vulnerabilities
scan_skill_dependencies() {
    local skill_path=$1
    local skill_name=$(basename "$skill_path")
    local threats_found=0
    
    # Check package.json (Node.js)
    if [ -f "$skill_path/package.json" ]; then
        log "INFO" "Checking dependencies in $skill_name"
        
        # Look for known vulnerable packages
        local vulnerable_packages=("lodash" "moment" "xmlrpc" "serialize-javascript")
        
        for vuln_pkg in "${vulnerable_packages[@]}"; do
            if grep -q "\"$vuln_pkg\"" "$skill_path/package.json"; then
                log "WARNING" "Potentially vulnerable package '$vuln_pkg' found in $skill_name"
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $skill_name - Uses potentially vulnerable package: $vuln_pkg" >> "$THREAT_REPORT"
                ((threats_found++))
            fi
        done
        
        # Check for old versions (simple heuristic)
        if grep -qE "\"[0-9]+\.[0-9]+\.[0-9]+\"" "$skill_path/package.json"; then
            local old_packages=$(grep -E "\"(.*?)\":\s*\"[0-9].[0-9].[0-9]\"" "$skill_path/package.json" | head -5)
            if [ ! -z "$old_packages" ]; then
                log "INFO" "Some packages in $skill_name may be outdated"
            fi
        fi
    fi
    
    return $threats_found
}

# Quarantine dangerous skill
quarantine_skill() {
    local skill_path=$1
    local skill_name=$(basename "$skill_path")
    
    log "WARNING" "Quarantining dangerous skill: $skill_name"
    
    if [ -d "$skill_path" ]; then
        mv "$skill_path" "$QUARANTINE_DIR/${skill_name}_quarantined_$(date +%s)"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] QUARANTINED: $skill_name" >> "$THREAT_REPORT"
        return 0
    fi
    
    return 1
}

# Main scan function
run_security_scan() {
    log "INFO" "=== Starting OpenClaw Skill Security Scan ==="
    
    # Find skill directories
    local skills_dir="${HOME}/.openclaw/skills"
    local alexa_skills_dir="${HOME}/.openclaw/skills/alexa"
    local google_skills_dir="${HOME}/.openclaw/skills/google"
    
    local total_skills=0
    local clean_skills=0
    local suspicious_skills=0
    local critical_skills=0
    
    # Scan Alexa skills
    if [ -d "$alexa_skills_dir" ]; then
        log "INFO" "Scanning Alexa skills..."
        
        for skill in $(find "$alexa_skills_dir" -maxdepth 1 -type d); do
            [ "$skill" = "$alexa_skills_dir" ] && continue
            
            ((total_skills++))
            local threats=0
            
            scan_skill_manifest "$skill"
            threats=$((threats + $?))
            
            scan_skill_code "$skill"
            threats=$((threats + $?))
            
            scan_skill_dependencies "$skill"
            threats=$((threats + $?))
            
            if [ $threats -gt 0 ]; then
                if [ $threats -ge 3 ]; then
                    log "CRITICAL" "Skill has multiple threats: $(basename $skill)"
                    ((critical_skills++))
                    # Quarantine critical threats
                    quarantine_skill "$skill"
                else
                    log "WARNING" "Skill has minor threats: $(basename $skill)"
                    ((suspicious_skills++))
                fi
            else
                log "SUCCESS" "Skill clean: $(basename $skill)"
                ((clean_skills++))
            fi
        done
    fi
    
    # Scan Google skills
    if [ -d "$google_skills_dir" ]; then
        log "INFO" "Scanning Google Actions..."
        
        for skill in $(find "$google_skills_dir" -maxdepth 1 -type d); do
            [ "$skill" = "$google_skills_dir" ] && continue
            
            ((total_skills++))
            local threats=0
            
            scan_skill_manifest "$skill"
            threats=$((threats + $?))
            
            scan_skill_code "$skill"
            threats=$((threats + $?))
            
            scan_skill_dependencies "$skill"
            threats=$((threats + $?))
            
            if [ $threats -gt 0 ]; then
                if [ $threats -ge 3 ]; then
                    log "CRITICAL" "Action has multiple threats: $(basename $skill)"
                    ((critical_skills++))
                    quarantine_skill "$skill"
                else
                    log "WARNING" "Action has minor threats: $(basename $skill)"
                    ((suspicious_skills++))
                fi
            else
                log "SUCCESS" "Action clean: $(basename $skill)"
                ((clean_skills++))
            fi
        done
    fi
    
    # Summary report
    log "INFO" "=== Security Scan Complete ==="
    log "INFO" "Total skills scanned: $total_skills"
    log "INFO" "Clean skills: $clean_skills"
    log "INFO" "Suspicious skills: $suspicious_skills"
    log "INFO" "Critical skills (quarantined): $critical_skills"
    
    # Return status
    if [ $critical_skills -gt 0 ]; then
        return 2  # Critical threats found
    elif [ $suspicious_skills -gt 0 ]; then
        return 1  # Warnings found
    fi
    
    return 0  # All clean
}

# Generate report
generate_report() {
    log "INFO" "Generating security report..."
    
    local report_file="${LOG_DIR}/skill_security_report_$(date +%Y%m%d_%H%M%S).html"
    
    cat > "$report_file" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>OpenClaw Skill Security Scan Report</title>
    <style>
        body { font-family: Arial; margin: 20px; }
        .critical { color: red; font-weight: bold; }
        .warning { color: orange; font-weight: bold; }
        .success { color: green; font-weight: bold; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #ccc; padding: 10px; text-align: left; }
        th { background-color: #f0f0f0; }
        .summary { margin: 20px 0; padding: 10px; background-color: #f9f9f9; border: 1px solid #ddd; }
    </style>
</head>
<body>
    <h1>OpenClaw Skill Security Scan Report</h1>
    <p>Generated: <strong>$(date)</strong></p>
    
    <div class="summary">
        <h2>Summary</h2>
        <p><strong>Scan Duration:</strong> $(grep -c "INFO\|WARNING\|CRITICAL" "$SCAN_REPORT" 2>/dev/null || echo "N/A") entries</p>
        <p><strong>Threats Found:</strong> $(grep -c "CRITICAL\|WARNING" "$THREAT_REPORT" 2>/dev/null || echo "0")</p>
        <p><strong>Quarantined Skills:</strong> $(ls -1 "$QUARANTINE_DIR" 2>/dev/null | wc -l)</p>
    </div>
    
    <h2>Scan Log</h2>
    <pre>
EOF
    
    tail -100 "$SCAN_REPORT" >> "$report_file" 2>/dev/null
    
    cat >> "$report_file" << 'EOF'
    </pre>
    
    <h2>Threats Detected</h2>
    <pre>
EOF
    
    if [ -f "$THREAT_REPORT" ]; then
        cat "$THREAT_REPORT" >> "$report_file"
    else
        echo "No threats detected" >> "$report_file"
    fi
    
    cat >> "$report_file" << 'EOF'
    </pre>
    
    <h2>Recommendations</h2>
    <ul>
        <li>Review quarantined skills for legitimate use cases</li>
        <li>Only enable skills from trusted sources</li>
        <li>Keep skills and dependencies updated</li>
        <li>Monitor skill logs for suspicious activity</li>
        <li>Run this scan before installing any new skill</li>
    </ul>
</body>
</html>
EOF
    
    log "SUCCESS" "Report saved to: $report_file"
    echo "$report_file"
}

# Main execution
main() {
    # Create header
    echo "========================================"
    echo "OpenClaw Skill Security Scanner v1.0"
    echo "========================================"
    echo ""
    
    # Run scan
    run_security_scan
    local scan_status=$?
    
    echo ""
    
    # Generate report
    generate_report
    
    echo ""
    
    # Return appropriate exit code
    case $scan_status in
        0) log "SUCCESS" "All skills passed security scan" ;;
        1) log "WARNING" "Some skills have warnings - review before enabling" ;;
        2) log "CRITICAL" "CRITICAL threats found and quarantined - review immediately" ;;
    esac
    
    return $scan_status
}

# Run main function
main
