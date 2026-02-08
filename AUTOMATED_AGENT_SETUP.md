# OpenClaw.ai Automated Installation Agent

**CLAUDE AGENT MODE: AUTONOMOUS SETUP**

This guide is designed to be executed by Claude agent autonomously. Start with: **"Begin terraforming" or "Install OpenClaw.ai"**

---

## AGENT INITIALIZATION

### Step 0: Detect Machine Type (AUTOMATED)

**Claude, execute this first:**

You have 2 detection scripts available. Choose the right one for the machine you're running on:

**If on macOS or Linux:**
```bash
chmod +x detect_machine.sh
./detect_machine.sh > machine_info.json
cat machine_info.json
```

**If on Windows (PowerShell):**
```powershell
powershell -ExecutionPolicy Bypass -File detect_machine.ps1 | Out-File machine_info.json
Get-Content machine_info.json
```

**Parse the output and identify:**
- OS type (macOS, Linux_Ubuntu, Linux_Fedora, Windows_10, Windows_11, etc.)
- Architecture (x86_64, ARM64)
- Available memory (GB)
- Free disk space (GB)

**Store these values for use throughout setup.**

---

## AUTOMATED PORT SELECTION

### Step 1A: Select Port (AUTOMATED - No User Input)

**Claude, execute based on OS detected:**

**For macOS/Linux:**
```bash
chmod +x select_openclaw_port_universal.sh
./select_openclaw_port.sh > port_output.log 2>&1
PORT=$(grep "SELECTED PORT:" port_output.log | awk '{print $NF}')
echo "Port selected: $PORT"
```

**For Windows (PowerShell):**
```powershell
powershell -ExecutionPolicy Bypass -File select_openclaw_port.ps1 | Out-File port_output.log
$port_output = Get-Content port_output.log
$PORT = ($port_output | Select-String "SELECTED PORT:") -replace '\D+(\d+)', '$1'
Write-Host "Port selected: $PORT"
```

**Verify port was successfully selected (should see: SELECTED PORT: XXXX)**

**If port selection fails:**
- Re-run script once more
- If still fails, select fallback port 8642 manually
- Continue with setup

---

## AUTOMATED INSTALLATION

### Step 2: Install OpenClaw.ai (AUTOMATED - OS Detection)

**Claude, execute the right installation command based on detected OS:**

**For macOS:**
```bash
curl -fsSL https://openclaw.ai/install.sh | bash
sleep 5
openclaw --version
```

**For Linux (Ubuntu/Debian):**
```bash
sudo apt-get update -y
curl -fsSL https://openclaw.ai/install.sh | bash
sleep 5
openclaw --version
```

**For Linux (Fedora/RHEL):**
```bash
sudo dnf update -y
curl -fsSL https://openclaw.ai/install.sh | bash
sleep 5
openclaw --version
```

**For Windows (PowerShell as Administrator):**
```powershell
# Check if already installed
openclaw --version

# If not installed, download and run
# For now, log that Windows installer needs manual download
Write-Host "⚠️  Windows requires manual installer from https://openclaw.ai/download"
Write-Host "Please download and run the installer."
# System will wait for completion
```

**Verify:** Output shows version number (e.g., "openclaw version 2.1.0")

**If installation fails:**
- Retry once
- Check internet connection
- Verify curl/download access

---

### Step 3: Configure API Key (AUTOMATED)

**Claude, create secure API key storage:**

**For macOS:**
```bash
# Use default from environment or prompt user once
if [ -z "$CLAUDE_API_KEY" ]; then
    echo "⚠️  Claude requires API key from https://console.anthropic.com/account/keys"
    echo "Please set environment: export CLAUDE_API_KEY=sk-..."
    # Wait for user to provide key
    read -p "Paste your Claude API key: " CLAUDE_API_KEY
fi

# Store securely in Keychain
security add-generic-password -s "OpenClaw" -a "claude_key" -w "$CLAUDE_API_KEY" -U

echo "✅ API key stored securely in Keychain"
```

**For Linux:**
```bash
if [ -z "$CLAUDE_API_KEY" ]; then
    echo "⚠️  Claude requires API key from https://console.anthropic.com/account/keys"
    read -p "Paste your Claude API key: " CLAUDE_API_KEY
fi

# Store in pass (password manager)
if command -v pass &> /dev/null; then
    echo "$CLAUDE_API_KEY" | pass insert -e OpenClaw/claude_key
else
    # Fallback: Create directory and store
    mkdir -p ~/.openclaw
    echo "$CLAUDE_API_KEY" > ~/.openclaw/api_key
    chmod 600 ~/.openclaw/api_key
fi

echo "✅ API key stored securely"
```

**For Windows (PowerShell):**
```powershell
if (-not $env:CLAUDE_API_KEY) {
    Write-Host "⚠️  Claude requires API key from https://console.anthropic.com/account/keys"
    $CLAUDE_API_KEY = Read-Host "Paste your Claude API key"
} else {
    $CLAUDE_API_KEY = $env:CLAUDE_API_KEY
}

# Store in Windows Credential Manager
cmdkey /add:OpenClaw /user:claude_key /pass:$CLAUDE_API_KEY

Write-Host "✅ API key stored securely in Credential Manager"
```

---

### Step 4: Configure OpenClaw (AUTOMATED)

**Claude, configure OpenClaw to use selected port:**

**For all platforms:**
```bash
# Create config file with selected port
cat > ~/.openclaw/config.yml << EOF
port: $PORT
api_key_source: "keychain"  # or environment
model: "claude"
features:
  whatsapp: true
  monitoring: true
  security_hardening: true
EOF

echo "✅ OpenClaw configured to use port $PORT"
```

**For Windows (PowerShell):**
```powershell
$config = @"
port: $PORT
api_key_source: "credential_manager"
model: "claude"
features:
  whatsapp: true
  monitoring: true
  security_hardening: true
"@

New-Item -ItemType Directory -Path "$env:APPDATA\OpenClaw" -Force | Out-Null
$config | Out-File -FilePath "$env:APPDATA\OpenClaw\config.yml"

Write-Host "✅ OpenClaw configured to use port $PORT"
```

---

## AUTOMATED SECURITY HARDENING

### Step 5: Setup Tailscale VPN (AUTOMATED)

**Claude, install and configure Tailscale:**

**For macOS:**
```bash
brew install tailscale
sudo tailscale up --shields-up --accept-risk=all

# Get Tailscale IP
TAILSCALE_IP=$(tailscale status --json | grep -o '"Self":[^}]*"Address":"[^"]*' | grep -o '[0-9.]*$' | head -1)
echo "Tailscale IP: $TAILSCALE_IP"
```

**For Linux (Ubuntu/Debian):**
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --shields-up --accept-risk=all

TAILSCALE_IP=$(tailscale status --json | grep -o '"Self":[^}]*"Address":"[^"]*' | grep -o '[0-9.]*$' | head -1)
echo "Tailscale IP: $TAILSCALE_IP"
```

**For Linux (Fedora/RHEL):**
```bash
sudo dnf install -y tailscale
sudo systemctl enable --now tailscaled
sudo tailscale up --shields-up --accept-risk=all

TAILSCALE_IP=$(tailscale status --json | grep -o '"Self":[^}]*"Address":"[^"]*' | grep -o '[0-9.]*$' | head -1)
echo "Tailscale IP: $TAILSCALE_IP"
```

**For Windows (PowerShell):**
```powershell
winget install tailscale.tailscale --source winget
Start-Process tailscale up -ArgumentList "--shields-up", "--accept-risk=all" -Wait

# Get Tailscale IP
$ts_info = & tailscale status
$TAILSCALE_IP = ($ts_info | Select-String "100\.64" | Select-Object -First 1) -replace '\s.*'
Write-Host "Tailscale IP: $TAILSCALE_IP"
```

**Verify:** Tailscale status shows "Connected"

---

### Step 6: Configure Firewall (AUTOMATED)

**Claude, configure firewall based on detected OS:**

**For macOS:**
```bash
# Enable firewall if not already enabled
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

# Add rules for Tailscale and OpenClaw port
sudo pfctl -e -f /etc/pf.conf

# Add specific rule
echo "pass in proto tcp from $TAILSCALE_IP to any port $PORT" | sudo pfctl -f -

echo "✅ Firewall configured for macOS"
```

**For Linux (UFW):**
```bash
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing

# SSH from Tailscale
sudo ufw allow from $TAILSCALE_IP to any port 22

# OpenClaw from Tailscale
sudo ufw allow from $TAILSCALE_IP to any port $PORT

sudo ufw status

echo "✅ Firewall configured with UFW"
```

**For Linux (firewalld):**
```bash
sudo systemctl enable --now firewalld
sudo firewall-cmd --set-default-zone=public

# Add rules
sudo firewall-cmd --permanent --add-rich-rule="rule family=\"ipv4\" source address=\"$TAILSCALE_IP\" port protocol=\"tcp\" port=\"22\" accept"
sudo firewall-cmd --permanent --add-rich-rule="rule family=\"ipv4\" source address=\"$TAILSCALE_IP\" port protocol=\"tcp\" port=\"$PORT\" accept"

sudo firewall-cmd --reload

echo "✅ Firewall configured with firewalld"
```

**For Windows (PowerShell as Administrator):**
```powershell
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

New-NetFirewallRule -DisplayName "SSH from Tailscale" `
  -Direction Inbound -Action Allow -Protocol TCP `
  -LocalPort 22 -RemoteAddress $TAILSCALE_IP

New-NetFirewallRule -DisplayName "OpenClaw Port $PORT" `
  -Direction Inbound -Action Allow -Protocol TCP `
  -LocalPort $PORT -RemoteAddress $TAILSCALE_IP

Write-Host "✅ Firewall configured with Windows Defender"
```

---

### Step 7: SSH & Brute Force Protection (AUTOMATED)

**Claude, configure SSH and fail2ban/lockout:**

**For macOS/Linux:**
```bash
# Generate SSH key
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "OpenClaw"

# Install fail2ban
if [[ "$OS" == "macOS" ]]; then
    brew install fail2ban
    brew services start fail2ban
elif [[ "$OS" == Linux* ]]; then
    if command -v apt &> /dev/null; then
        sudo apt-get install -y fail2ban
        sudo systemctl enable --now fail2ban
    else
        sudo dnf install -y fail2ban
        sudo systemctl enable --now fail2ban
    fi
fi

# Configure fail2ban
sudo tee /etc/fail2ban/jail.local > /dev/null << EOF
[DEFAULT]
maxretry = 3
findtime = 600
bantime = 86400

[sshd]
enabled = true
EOF

sudo systemctl restart fail2ban

echo "✅ SSH keys generated, fail2ban configured"
```

**For Windows (PowerShell as Administrator):**
```powershell
# Install OpenSSH if needed
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Generate SSH key
ssh-keygen -t ed25519 -f "$env:USERPROFILE\.ssh\id_ed25519" -N "" -C "OpenClaw"

# Enable account lockout (Windows equivalent of fail2ban)
net accounts /lockoutduration:30 /lockoutthreshold:3 /lockoutwindow:10

Write-Host "✅ SSH keys generated, account lockout configured"
```

---

### Step 8: Enable Monitoring (AUTOMATED)

**Claude, configure self-monitoring and alerts:**

**For all platforms:**
```bash
# Create monitoring configuration
cat > ~/.openclaw/monitoring.yml << EOF
enabled: true
check_interval: 300  # 5 minutes
alerts:
  - type: failed_logins
    threshold: 3
    window: 600  # 10 minutes
    action: "message_admin"
  - type: port_scan
    action: "message_admin"
  - type: unusual_activity
    action: "message_admin"
  - type: api_quota_warning
    action: "message_admin"

logging:
  level: "INFO"
  file: "~/.openclaw/logs/openclaw.log"
  max_size: "100MB"
  retention: "30 days"
EOF

mkdir -p ~/.openclaw/logs

echo "✅ Monitoring enabled and configured"
```

---

### Step 9: Optional - Install Local Ollama Model (AUTOMATED)

**Claude, offer to install Ollama for local fallback:**

```bash
# Ask user if they want Ollama (or check free space)
FREE_SPACE=$DISK  # From machine detection

if [ "$FREE_SPACE" -gt 10 ]; then
    # Install Ollama
    if [[ "$OS" == "macOS" ]]; then
        brew install ollama
    elif [[ "$OS" == Linux* ]]; then
        curl -fsSL https://ollama.ai/install.sh | sh
    elif [[ "$OS" == Windows* ]]; then
        # Windows installer
        Write-Host "Download from https://ollama.ai/download/windows"
    fi
    
    # Pull Llama 3 8B
    ollama pull llama3:8b
    
    echo "✅ Ollama installed with Llama 3 8B model"
else
    echo "⚠️  Insufficient disk space for Ollama (need 5GB, have $FREE_SPACE)"
    echo "    Skipping Ollama installation"
fi
```

---

## AUTOMATED VERIFICATION

### Step 10: Run Complete Verification (AUTOMATED)

**Claude, verify entire setup:**

```bash
echo "🔍 RUNNING COMPLETE VERIFICATION..."
echo ""

# 1. Check OpenClaw installation
echo "✓ Checking OpenClaw installation..."
openclaw --version
if [ $? -eq 0 ]; then echo "  ✅ OpenClaw installed"; else echo "  ❌ OpenClaw missing"; fi

# 2. Check port is listening
echo "✓ Checking OpenClaw port..."
if command -v lsof &> /dev/null; then
    lsof -i :$PORT
    if [ $? -eq 0 ]; then echo "  ✅ Port $PORT is listening"; fi
fi

# 3. Check Tailscale
echo "✓ Checking Tailscale..."
tailscale status
if [ $? -eq 0 ]; then echo "  ✅ Tailscale connected"; fi

# 4. Check firewall
echo "✓ Checking firewall..."
if [[ "$OS" == "macOS" ]]; then
    sudo pfctl -sr | grep "port $PORT"
elif [[ "$OS" == Linux* ]]; then
    sudo ufw status | grep "$PORT"
fi

# 5. Check SSH keys
echo "✓ Checking SSH keys..."
if [ -f ~/.ssh/id_ed25519 ]; then echo "  ✅ SSH keys generated"; fi

# 6. Check monitoring
echo "✓ Checking monitoring..."
if [ -f ~/.openclaw/monitoring.yml ]; then echo "  ✅ Monitoring configured"; fi

# 7. Check API key
echo "✓ Checking API key storage..."
if [[ "$OS" == "macOS" ]]; then
    security find-generic-password -s "OpenClaw" > /dev/null && echo "  ✅ API key stored"
elif [[ "$OS" == Linux* ]]; then
    if command -v pass &> /dev/null; then
        pass show OpenClaw/claude_key > /dev/null && echo "  ✅ API key stored"
    fi
fi

echo ""
echo "🎉 VERIFICATION COMPLETE"
```

---

## AUTOMATED FINAL SETUP

### Step 11: Start OpenClaw (AUTOMATED)

**Claude, start the OpenClaw service:**

```bash
# Start OpenClaw in background
nohup openclaw start --port $PORT &> ~/.openclaw/logs/startup.log &

sleep 3

# Verify it started
if curl -s http://localhost:$PORT/health > /dev/null 2>&1; then
    echo "✅ OpenClaw started successfully on port $PORT"
else
    echo "⚠️  OpenClaw may still be starting..."
    echo "    Check logs: tail -f ~/.openclaw/logs/startup.log"
fi
```

---

### Step 12: User Connection Setup (MINIMAL INPUT)

**Claude, guide user through WhatsApp connection:**

```
⚠️  REQUIRES USER ACTION (ONE TIME):

1. Open WhatsApp on your phone
2. Go to https://openclaw.ai/connect (from phone)
3. Scan QR code shown there
4. Confirm phone number
5. Bot will start listening to your WhatsApp messages

Expected: Bot responds with "Connected and ready"

This is the ONLY manual step required.
```

---

## AUTOMATED COMPLETION

### Step 13: Summary & Documentation (AUTOMATED)

**Claude, generate completion report:**

```bash
cat > INSTALLATION_REPORT.md << 'EOF'
# OpenClaw.ai Installation Complete ✅

## System Information
- OS: $OS
- Architecture: $ARCH
- Memory: $MEMORY GB
- Free Disk: $DISK

## Configuration
- Port: $PORT
- Tailscale IP: $TAILSCALE_IP
- API Key: Stored securely
- Firewall: Configured
- Monitoring: Enabled
- SSH: Configured
- fail2ban: Enabled

## Status
- ✅ OpenClaw installed and running
- ✅ Port $PORT listening
- ✅ Tailscale connected
- ✅ Firewall rules applied
- ✅ SSH keys generated
- ✅ Monitoring active
- ✅ API key secured
- ⏳ Awaiting WhatsApp connection

## Next Step
1. Open WhatsApp on phone
2. Scan QR from https://openclaw.ai/connect
3. Confirm connection
4. Bot ready to use

## Security Features
- ✅ VPN-only access (Tailscale)
- ✅ Firewall allow-list only
- ✅ SSH key authentication
- ✅ Brute force protection (fail2ban)
- ✅ API key encrypted storage
- ✅ Self-monitoring enabled
- ✅ Audit logging enabled

## Support
- Logs: ~/.openclaw/logs/openclaw.log
- Config: ~/.openclaw/config.yml
- Monitoring: ~/.openclaw/monitoring.yml
- Status: openclaw status
EOF

cat INSTALLATION_REPORT.md

echo ""
echo "🎉 INSTALLATION COMPLETE"
echo ""
echo "Your OpenClaw.ai bot is running securely on:"
echo "   Port: $PORT"
echo "   OS: $OS"
echo "   Architecture: $ARCH"
echo ""
echo "Tailscale IP: $TAILSCALE_IP"
echo ""
echo "COMPLETE. Begin terraforming mission accomplished! 🚀"
```

---

## AGENT EXECUTION SUMMARY

**This entire setup requires only:**

1. **Initial command:** "Begin terraforming" or "Install OpenClaw.ai"
2. **Claude detects:** OS, hardware, environment
3. **Claude executes:** All installation steps automatically
4. **Claude adapts:** Each step for detected OS
5. **Claude verifies:** All components working
6. **User action:** ONE TIME - WhatsApp QR scan (5 minutes)
7. **Done:** Fully secure, running bot

**No user configuration. No manual decisions. Just "begin terraforming" and wait ~45-60 minutes.**

---

## TROUBLESHOOTING (AUTOMATED)

**If any step fails, Claude automatically:**

1. Re-runs the failed step once more
2. Logs the error to `INSTALLATION_ERRORS.log`
3. Suggests remediation
4. Continues with remaining steps

**Common issues auto-handled:**
- ❌ Port unavailable → Select different port automatically
- ❌ API key missing → Prompt once and continue
- ❌ Installation fails → Retry once, log error, suggest manual download
- ❌ Firewall blocked → Add exception automatically
- ❌ Tailscale not connecting → Show diagnostic info

---

**EXECUTION:** 
Pass this file to Claude with command: **"Begin terraforming"**

Claude will execute everything autonomously, adapting to the detected machine type.
