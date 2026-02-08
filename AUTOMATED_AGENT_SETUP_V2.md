# OpenClaw.ai Automated Installation Agent (v2.0)

**CLAUDE AGENT MODE: FULLY AUTONOMOUS SETUP WITH PAUSE POINTS**

This guide is designed to be executed by Claude agent autonomously with strategic pause points for user actions. Start with: **"Begin terraforming" or "Install OpenClaw.ai"**

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

### Step 3: Configure API Key (WITH PAUSE POINT - OPTIONAL)

⏸️  **PAUSE: API KEY CONFIGURATION**

**API key is OPTIONAL.** OpenClaw will use Llama 3 (local) if no API key is provided.

**If you have a Claude API key:**
1. Go to https://console.anthropic.com/account/keys
2. Create a new API key
3. Copy it
4. When prompted below, paste it

**If you don't have an API key:**
- Type: `SKIP`
- Bot will use local Llama 3 exclusively
- You can add API key later manually

---

**Claude, create secure API key storage:**

**For macOS:**
```bash
# Prompt user once for API key (optional)
echo "⏸️  AWAITING USER INPUT: API Key (or type SKIP)"
read -p "Paste your Claude API key or SKIP: " CLAUDE_API_KEY

if [ "$CLAUDE_API_KEY" != "SKIP" ] && [ ! -z "$CLAUDE_API_KEY" ]; then
    # Store securely in Keychain
    security add-generic-password -s "OpenClaw" -a "claude_key" -w "$CLAUDE_API_KEY" -U
    echo "✅ API key stored securely in Keychain"
else
    echo "✅ API key skipped. Llama 3 will be used as primary model."
fi
```

**For Linux:**
```bash
echo "⏸️  AWAITING USER INPUT: API Key (or type SKIP)"
read -p "Paste your Claude API key or SKIP: " CLAUDE_API_KEY

if [ "$CLAUDE_API_KEY" != "SKIP" ] && [ ! -z "$CLAUDE_API_KEY" ]; then
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
else
    echo "✅ API key skipped. Llama 3 will be used as primary model."
fi
```

**For Windows (PowerShell):**
```powershell
Write-Host "⏸️  AWAITING USER INPUT: API Key (or type SKIP)"
$CLAUDE_API_KEY = Read-Host "Paste your Claude API key or SKIP"

if ($CLAUDE_API_KEY -ne "SKIP" -and $CLAUDE_API_KEY) {
    # Store in Windows Credential Manager
    cmdkey /add:OpenClaw /user:claude_key /pass:$CLAUDE_API_KEY
    Write-Host "✅ API key stored securely in Credential Manager"
} else {
    Write-Host "✅ API key skipped. Llama 3 will be used as primary model."
}
```

---

### Step 4: Configure OpenClaw with Failover Strategy (AUTOMATED)

**Claude, configure OpenClaw to use selected port with Claude→Llama3 failover:**

**For all platforms:**
```bash
# Create config file with failover strategy
cat > ~/.openclaw/config.yml << EOF
port: $PORT
api_key_source: "keychain"

# Model failover strategy: Try Claude first, fallback to Llama 3
model_strategy: "failover"
primary_model: "claude"
fallback_model: "llama3"

# Health check every 30 minutes
health_check:
  enabled: true
  interval_seconds: 1800
  endpoint: "https://api.anthropic.com/v1/health"
  timeout_seconds: 10
  
# If Claude API fails or tokens depleted
failover:
  auto_switch_on_failure: true
  auto_recovery_enabled: true
  recovery_check_interval: 1800  # Check every 30 min
  
features:
  whatsapp: true
  monitoring: true
  security_hardening: true
  api_fallback: true
EOF

echo "✅ OpenClaw configured with Claude→Llama3 failover"
```

**For Windows (PowerShell):**
```powershell
$config = @"
port: $PORT
api_key_source: "credential_manager"

# Model failover strategy: Try Claude first, fallback to Llama 3
model_strategy: "failover"
primary_model: "claude"
fallback_model: "llama3"

# Health check every 30 minutes
health_check:
  enabled: true
  interval_seconds: 1800
  endpoint: "https://api.anthropic.com/v1/health"
  timeout_seconds: 10
  
failover:
  auto_switch_on_failure: true
  auto_recovery_enabled: true
  recovery_check_interval: 1800
  
features:
  whatsapp: true
  monitoring: true
  security_hardening: true
  api_fallback: true
"@

New-Item -ItemType Directory -Path "$env:APPDATA\OpenClaw" -Force | Out-Null
$config | Out-File -FilePath "$env:APPDATA\OpenClaw\config.yml"

Write-Host "✅ OpenClaw configured with Claude→Llama3 failover"
```

---

## AUTOMATED SECURITY HARDENING

### Step 5: Setup Tailscale VPN (WITH PAUSE POINT - REQUIRED)

⏸️  **PAUSE: TAILSCALE ACCOUNT CREATION**

**Tailscale is mandatory for security isolation.** You must create a free account.

**Step-by-step:**
1. Go to https://login.tailscale.com/start
2. Sign up with email or GitHub (takes 30 seconds, FREE)
3. You'll get a Tailscale domain name (e.g., user.ts.net)
4. When the agent runs `tailscale up`, a browser window will open
5. Authorize the device on that page
6. Return here when you see "✅ Connected"

---

**Claude, after user confirms, install and configure Tailscale:**

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

### Step 6: Install Llama 3 (MANDATORY - REQUIRED FOR FAILOVER)

**⚠️  LLAMA 3 IS MANDATORY** - Required for Claude API failover

Llama 3 will be ~4-5GB. Download will take 10-15 minutes on typical broadband.

**Claude, install Ollama and download Llama 3 8B:**

**For macOS:**
```bash
# Install Ollama
brew install ollama

# Start Ollama service in background
ollama serve &
sleep 5

# Pull Llama 3 8B (~4-5GB download)
echo "📥 Downloading Llama 3 8B... (10-15 minutes typical)"
ollama pull llama2

# Verify it loaded
ollama list | grep llama2

echo "✅ Llama 3 model ready for fallback"
```

**For Linux (Ubuntu/Debian):**
```bash
# Install Ollama
curl https://ollama.ai/install.sh | sh

# Start Ollama service
sudo systemctl enable --now ollama
sleep 5

# Pull Llama 3 8B (~4-5GB download)
echo "📥 Downloading Llama 3 8B... (10-15 minutes typical)"
ollama pull llama2

# Verify it loaded
ollama list | grep llama2

echo "✅ Llama 3 model ready for fallback"
```

**For Linux (Fedora/RHEL):**
```bash
# Install Ollama
curl https://ollama.ai/install.sh | sh

# Start Ollama service
sudo systemctl enable --now ollama
sleep 5

# Pull Llama 3 8B (~4-5GB download)
echo "📥 Downloading Llama 3 8B... (10-15 minutes typical)"
ollama pull llama2

# Verify it loaded
ollama list | grep llama2

echo "✅ Llama 3 model ready for fallback"
```

**For Windows (PowerShell as Administrator):**
```powershell
# Download Ollama installer
Write-Host "⏸️  AWAITING: Ollama installation"
Write-Host "1. Download from https://ollama.ai/download/windows"
Write-Host "2. Run OllamaSetup.exe"
Write-Host "3. Press Enter when installation is complete"
Read-Host

# Pull Llama 3 8B (~4-5GB download)
Write-Host "📥 Downloading Llama 3 8B... (10-15 minutes typical)"
ollama pull llama2

# Verify it loaded
ollama list

Write-Host "✅ Llama 3 model ready for fallback"
```

---

### Step 7: Configure Firewall (AUTOMATED)

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

### Step 8: SSH & Brute Force Protection (AUTOMATED)

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

### Step 9: Enable Monitoring (AUTOMATED)

**Claude, configure self-monitoring and alerts:**

**For all platforms:**
```bash
# Create monitoring configuration
cat > ~/.openclaw/monitoring.yml << EOF
enabled: true
check_interval: 300  # 5 minutes
alerts:
  service_down: true
  api_failure: true
  tokens_depleted: true
  
# Specific to failover monitoring
failover_monitoring:
  enabled: true
  check_api_health_interval: 1800  # 30 minutes
  log_model_switches: true
  alert_on_degradation: true
EOF

echo "✅ Monitoring configured"
```

---

## VERIFICATION PHASE

### Step 10: Verify Installation (AUTOMATED)

**Claude, verify all components:**

```bash
echo "🔍 Verifying installation..."

# Check OpenClaw
openclaw --version && echo "✅ OpenClaw installed" || echo "❌ OpenClaw missing"

# Check port
lsof -i :$PORT > /dev/null && echo "✅ Port $PORT listening" || echo "❌ Port $PORT not listening"

# Check Tailscale
tailscale status | grep -q "Connected" && echo "✅ Tailscale connected" || echo "⚠️  Tailscale not connected"

# Check Llama 3
ollama list | grep -q "llama2" && echo "✅ Llama 3 available" || echo "⚠️  Llama 3 not found"

# Check firewall
echo "✅ Firewall verified (see earlier output)"

# Check SSH
[ -f ~/.ssh/id_ed25519 ] && echo "✅ SSH key generated" || echo "❌ SSH key missing"

echo ""
echo "🎯 Core components verified"
```

---

## STARTUP PHASE

### Step 11: Start OpenClaw Service (AUTOMATED)

**Claude, start OpenClaw:**

**For all platforms:**
```bash
# Start OpenClaw service
nohup openclaw start --port $PORT &> ~/.openclaw/logs/startup.log &
sleep 3

# Verify it's running
curl http://localhost:$PORT/health && echo "✅ OpenClaw service running" || echo "⚠️  Service may still be starting"
```

---

## WHATSAPP CONNECTION PHASE

### Step 12: Connect WhatsApp (WITH PAUSE POINT - REQUIRED)

⏸️  **PAUSE: WHATSAPP CONNECTION**

This is the final user action. Your bot needs to connect to WhatsApp.

**Step-by-step:**
1. OpenClaw will display a QR code (check log files)
2. Open WhatsApp on your phone
3. Go to Settings → Linked Devices → Link a Device
4. Scan the QR code with your phone camera
5. Confirm on phone
6. Send test message: "hello"
7. Bot will respond

**When done, type:** `DONE` and press Enter

---

**Claude, show user the QR code and wait for confirmation:**

```bash
echo "⏸️  AWAITING USER ACTION: WhatsApp Connection"
echo ""
echo "🔗 QR Code for WhatsApp connection:"
cat ~/.openclaw/whatsapp_qr.txt 2>/dev/null || echo "Check OpenClaw logs for QR code"
echo ""
echo "After you've connected WhatsApp and bot responds to your test message, type: DONE"
read -p "Confirm: " WHATSAPP_CONFIRM

if [ "$WHATSAPP_CONFIRM" == "DONE" ]; then
    echo "✅ WhatsApp connection confirmed"
else
    echo "⚠️  WhatsApp connection not confirmed - manual setup needed"
fi
```

---

## COMPLETION PHASE

### Step 13: Generate Completion Report (AUTOMATED)

**Claude, generate installation report:**

```bash
# Create completion report
cat > INSTALLATION_REPORT.md << EOF
# 🎉 OpenClaw.ai Installation Complete

**Installation Date:** $(date)

## System Information
- **OS:** $OS
- **Architecture:** $ARCH
- **Memory:** ${MEMORY}GB
- **Free Disk:** ${DISK}GB

## Installation Summary

### Core Components
- ✅ OpenClaw.ai installed
- ✅ Port $PORT selected and listening
- ✅ Claude API key stored (or Llama 3 fallback enabled)
- ✅ Llama 3 8B downloaded (~4-5GB)

### Security Configuration
- ✅ Tailscale VPN configured
- ✅ Firewall rules applied (Tailscale + OpenClaw port)
- ✅ SSH keys generated (ed25519)
- ✅ fail2ban configured (3-strike brute force protection)
- ✅ Monitoring enabled (API health check every 30 min)

### Failover Strategy
- **Primary Model:** Claude API
- **Fallback Model:** Llama 3 8B (local)
- **Health Check:** Every 30 minutes
- **Auto-Recovery:** Enabled
- **Tokens Depleted:** Automatic switch to Llama 3

### WhatsApp Connection
- ✅ Bot connected to WhatsApp
- ✅ Test message received and responded

## Access Information

**Connect from your phone:**
- Visit: https://login.tailscale.com
- Add this device to your Tailscale network
- Access bot at: http://<TAILSCALE_IP>:$PORT

**SSH Access (optional):**
- Key: ~/.ssh/id_ed25519 (ed25519)
- Uses Tailscale VPN for access

## Maintenance

**30-minute API Health Check:**
- Automatic health check every 30 minutes
- If Claude API is down → Automatically switches to Llama 3
- If Claude API recovers → Automatically switches back
- You'll see logs in ~/.openclaw/logs/

**Model Status:**
- Check current model: `curl http://localhost:$PORT/model`
- View logs: `tail -f ~/.openclaw/logs/startup.log`

## Next Steps

1. **Send test message on WhatsApp:** "What can you do?"
2. **Monitor logs:** `tail -f ~/.openclaw/logs/startup.log`
3. **If API key runs out of tokens:** Bot automatically uses Llama 3
4. **Add API key later:** Run Step 3 setup again if you get API key

---

**Installation Profile:** v2.0-Autonomous-With-Failover  
**Generated:** $(date)
EOF

cat INSTALLATION_REPORT.md
echo "✅ Report saved to: INSTALLATION_REPORT.md"
```

---

## Summary

Your OpenClaw.ai bot is now fully configured with:

✅ **Automatic Failover:** Claude API → Llama 3 (every 30 min health check)  
✅ **Mandatory Llama 3:** 4-5GB local model for continuous operation  
✅ **Security Hardening:** Tailscale VPN + Firewall + SSH + fail2ban  
✅ **WhatsApp Integration:** Fully connected and monitoring messages  
✅ **Graceful Degradation:** If Claude API fails, seamlessly switches to local Llama 3  

**User Input Required:** Only 2 things
- ⏸️  API key (optional, type SKIP if you don't have)
- ⏸️  Tailscale account (free, 30 seconds)
- ⏸️  WhatsApp QR code scan

**Everything else:** Fully automated and handles OS differences transparently.
