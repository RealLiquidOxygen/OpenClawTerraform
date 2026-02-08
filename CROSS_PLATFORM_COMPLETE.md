# 🔄 CROSS-PLATFORM SUPPORT - COMPLETE

Your OpenClaw.ai setup now works on **macOS, Windows, and Linux**.

---

## Platform Coverage

| Platform | Port Selection | Installation | Firewall | SSH/Auth | Status |
|----------|---|---|---|---|---|
| **macOS** | ✅ Bash/Universal | ✅ Homebrew/curl | ✅ pf/UFW | ✅ OpenSSH | ✅ Full |
| **Linux (Ubuntu)** | ✅ Bash/Universal | ✅ apt/curl | ✅ UFW | ✅ OpenSSH | ✅ Full |
| **Linux (Fedora)** | ✅ Bash/Universal | ✅ dnf/curl | ✅ firewalld | ✅ OpenSSH | ✅ Full |
| **Windows (Native)** | ✅ PowerShell | ✅ Direct/winget | ✅ Defender FW | ✅ OpenSSH | ✅ Full |
| **Windows (WSL2)** | ✅ Bash/Universal | ✅ apt/curl | ✅ UFW | ✅ OpenSSH | ✅ Full |

---

## Scripts & Tools

### Port Selection (3 Options)

#### 1. **select_openclaw_port.sh** (macOS/Linux)
- **Type:** Bash script
- **OS:** macOS, Linux
- **Tool:** `lsof`
- **Size:** 3.2KB
- **Status:** ✅ Executable

```bash
chmod +x select_openclaw_port.sh
./select_openclaw_port.sh
```

#### 2. **select_openclaw_port_universal.sh** (macOS/Linux/WSL2)
- **Type:** Bash script with OS detection
- **OS:** macOS, Linux, Windows (WSL2), Windows (Git Bash)
- **Tools:** lsof → netstat → ss → TCP fallback
- **Size:** 6.4KB
- **Status:** ✅ Executable
- **Recommended:** Yes (auto-handles tool differences)

```bash
chmod +x select_openclaw_port_universal.sh
./select_openclaw_port_universal.sh
```

#### 3. **select_openclaw_port.ps1** (Windows)
- **Type:** PowerShell script
- **OS:** Windows (PowerShell 5.1+)
- **Tools:** `netstat` + `Get-NetTCPConnection`
- **Size:** 4.1KB
- **Status:** ✅ Ready
- **Recommended:** Yes (Windows native)

```powershell
powershell -ExecutionPolicy Bypass -File select_openclaw_port.ps1
```

---

## Installation Methods by Platform

### macOS
```bash
# Install OpenClaw
curl -fsSL https://openclaw.ai/install.sh | bash

# Install Tailscale
brew install tailscale

# Install fail2ban (optional but recommended)
brew install fail2ban
brew services start fail2ban

# Install Ollama (for local Llama 3)
brew install ollama
```

### Linux (Ubuntu/Debian)
```bash
# Install OpenClaw
curl -fsSL https://openclaw.ai/install.sh | bash

# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Install fail2ban
sudo apt-get install fail2ban
sudo systemctl enable --now fail2ban

# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh
```

### Linux (Fedora/RHEL)
```bash
# Install OpenClaw
curl -fsSL https://openclaw.ai/install.sh | bash

# Install Tailscale
sudo dnf install -y tailscale
sudo systemctl enable --now tailscaled

# Install fail2ban
sudo dnf install -y fail2ban
sudo systemctl enable --now fail2ban

# Install Ollama
sudo dnf install -y ollama
sudo systemctl enable --now ollama
```

### Windows (PowerShell as Administrator)
```powershell
# Install OpenClaw
# Option 1: Download installer from https://openclaw.ai/download
# Option 2: Use package manager
winget install openclaw

# Install Tailscale
winget install tailscale.tailscale --source winget
# OR download from https://tailscale.com/download/windows

# Install Ollama
winget install ollama
# OR download from https://ollama.ai/download/windows
```

---

## Firewall Configuration by Platform

### macOS
```bash
# Enable native firewall (pf)
sudo pfctl -e

# Add rules for specific ports
echo "pass in proto tcp from [TAILSCALE_IP] to any port 22" | sudo pfctl -f -
echo "pass in proto tcp from [TAILSCALE_IP] to any port [PORT]" | sudo pfctl -f -
```

### Linux (UFW - Ubuntu/Debian)
```bash
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing

# SSH from Tailscale
sudo ufw allow from [TAILSCALE_IP] to any port 22

# OpenClaw from Tailscale
sudo ufw allow from [TAILSCALE_IP] to any port [PORT]

sudo ufw status
```

### Linux (firewalld - Fedora/RHEL)
```bash
sudo systemctl enable --now firewalld
sudo firewall-cmd --set-default-zone=public

# SSH and OpenClaw from Tailscale
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="[TAILSCALE_IP]" port protocol="tcp" port="22" accept'
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="[TAILSCALE_IP]" port protocol="tcp" port="[PORT]" accept'

sudo firewall-cmd --reload
```

### Windows (Defender Firewall via PowerShell)
```powershell
# Run as Administrator
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

# SSH from Tailscale
New-NetFirewallRule -DisplayName "SSH from Tailscale" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 22 -RemoteAddress "[TAILSCALE_IP]"

# OpenClaw from Tailscale
New-NetFirewallRule -DisplayName "OpenClaw Port" -Direction Inbound -Action Allow -Protocol TCP -LocalPort [PORT] -RemoteAddress "[TAILSCALE_IP]"
```

---

## SSH & Authentication by Platform

### macOS/Linux (OpenSSH)
```bash
# Generate SSH key
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""

# Start SSH service
# macOS (native):
sudo launchctl start com.openssh.sshd

# Linux:
sudo systemctl enable --now ssh
```

### Windows (OpenSSH - Windows 10 1809+)
```powershell
# Install OpenSSH (if not already installed)
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Generate SSH key
ssh-keygen -t ed25519 -f $env:USERPROFILE\.ssh\id_ed25519

# Start SSH service
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic
```

---

## Brute Force Protection by Platform

### macOS/Linux (fail2ban)
```bash
# Installation (varies by platform)
# See Installation section above

# Configure
sudo nano /etc/fail2ban/jail.local
# Add:
# [DEFAULT]
# maxretry = 3
# findtime = 600
# bantime = 86400

sudo systemctl restart fail2ban
```

### Windows (Account Lockout Policy)
```powershell
# Run as Administrator
# Set account lockout to 3 wrong attempts, 30 minute lock
net accounts /lockoutduration:30 /lockoutthreshold:3 /lockoutwindow:10
```

---

## Local Model Support (Ollama)

### All Platforms (Same Commands)
```bash
# macOS/Linux
ollama pull llama3:8b
ollama run llama3:8b "Test prompt"

# Windows (cmd or PowerShell)
ollama pull llama3:8b
ollama run llama3:8b "Test prompt"
```

---

## API Key Storage by Platform

### macOS (Keychain)
```bash
security add-generic-password -s "OpenClaw" -a "claude_key" -w "YOUR_API_KEY"
```

### Linux (pass - Password Manager)
```bash
sudo apt-get install pass  # Ubuntu/Debian
sudo dnf install pass       # Fedora/RHEL

pass insert OpenClaw/claude_key
```

### Windows (Credential Manager)
```powershell
# Built-in Windows Credential Manager
cmdkey /add:OpenClaw /user:claude_key /pass:YOUR_API_KEY

# Or via PowerShell SecureString
$key = ConvertTo-SecureString "YOUR_API_KEY" -AsPlainText -Force
$key | Export-Clixml -Path "$env:APPDATA\OpenClaw\key.xml"
```

---

## Quick Start by Platform

### macOS Users
```bash
# 1. Port selection
./select_openclaw_port_universal.sh
PORT=$(grep "SELECTED PORT:" output.log | awk '{print $NF}')

# 2. Install OpenClaw
curl -fsSL https://openclaw.ai/install.sh | bash

# 3. Install security tools
brew install tailscale fail2ban

# 4. Continue with Claude guide (PART 1 onwards)
```

### Linux Users
```bash
# 1. Port selection
./select_openclaw_port_universal.sh
PORT=$(grep "SELECTED PORT:" output.log | awk '{print $NF}')

# 2. Install OpenClaw
curl -fsSL https://openclaw.ai/install.sh | bash

# 3. Install security tools
sudo apt-get install tailscale fail2ban  # Ubuntu/Debian
# or
sudo dnf install tailscale fail2ban      # Fedora/RHEL

# 4. Continue with Claude guide (PART 1 onwards)
```

### Windows Users
```powershell
# 1. Port selection
powershell -ExecutionPolicy Bypass -File select_openclaw_port.ps1
# Read port from output.log manually

# 2. Install OpenClaw
# Download from https://openclaw.ai/download or use winget

# 3. Install Tailscale
winget install tailscale.tailscale --source winget

# 4. Continue with Claude guide (PART 1 onwards)
```

---

## Troubleshooting by Platform

### macOS Issues
- **Script permission denied:** `chmod +x select_openclaw_port*.sh`
- **lsof not found:** `brew install lsof`
- **Tailscale install fails:** Use `brew tap tailscale/tap && brew install tailscale`
- **fail2ban won't start:** `brew services restart fail2ban`

### Linux Issues (Ubuntu/Debian)
- **Script permission denied:** `chmod +x select_openclaw_port*.sh`
- **UFW status shows "inactive":** `sudo ufw enable`
- **SSH connection refused:** `sudo systemctl enable --now ssh`
- **Tailscale not connecting:** `sudo systemctl restart tailscaled`

### Linux Issues (Fedora/RHEL)
- **SELinux issues:** Temporarily disable for setup: `sudo setenforce 0`
- **firewalld blocking:** `sudo firewall-cmd --permanent --add-service=openclaw`
- **Ollama permission denied:** `sudo usermod -a -G ollama $USER` (then logout/login)

### Windows Issues
- **PowerShell execution policy:** Use `-ExecutionPolicy Bypass` flag
- **Firewall blocking OpenClaw:** Add exception via Windows Defender Firewall GUI
- **OpenSSH not available:** Update Windows 10 (requires 1809+) or use Windows 11
- **Tailscale VPN issues:** Download latest version from tailscale.com

---

## Testing Across Platforms

```bash
# Same commands work on all platforms:

# 1. Verify port is listening
# macOS/Linux:
lsof -i :8642

# Windows (PowerShell):
Get-NetTCPConnection -LocalPort 8642

# 2. Test Tailscale
# All platforms:
tailscale status

# 3. Check firewall
# macOS: pfctl -sr
# Linux: sudo ufw status
# Windows: Get-NetFirewallRule

# 4. Test SSH
# All platforms:
ssh -i ~/.ssh/id_ed25519 user@localhost
```

---

## Documentation by Platform

| Document | Applies To |
|----------|-----------|
| `openClawSetup_ForClaudeAgent.md` | All platforms ✅ |
| `CROSS_PLATFORM_GUIDE.md` | All platforms ✅ |
| `PORT_SELECTION_WORKFLOW.md` | All (mentions tools) ✅ |
| `openClawSetup.md` | Reference (macOS-focused) |

---

## What Changed from macOS-Only

### Before
- ✅ Port selection script (bash only)
- ✅ Installation (macOS via Homebrew)
- ✅ Firewall (UFW/macOS pf only)
- ❌ Windows support
- ❌ Linux variations (Fedora/RHEL)

### After
- ✅ 3 port selection scripts (bash, universal, PowerShell)
- ✅ Installation instructions for all OS
- ✅ Firewall for all platforms (pf, UFW, firewalld, Defender)
- ✅ Windows support (native + WSL2)
- ✅ Linux variations (Ubuntu, Fedora)
- ✅ SSH/auth for all platforms
- ✅ API key storage for all platforms
- ✅ Ollama on all platforms

---

## File Manifest

### Scripts (3 versions)
- `select_openclaw_port.sh` (3.2KB) - macOS/Linux
- `select_openclaw_port_universal.sh` (6.4KB) - All *nix
- `select_openclaw_port.ps1` (4.1KB) - Windows

### Guides (Updated)
- `openClawSetup_ForClaudeAgent.md` - Now cross-platform
- `CROSS_PLATFORM_GUIDE.md` - Platform-specific details
- `openClawSetup.md` - Reference guide

### Documentation
- `PORT_SELECTION_WORKFLOW.md` - Automation details
- `DEPLOYMENT_CHECKLIST.md` - Deployment steps
- `INDEX.md` - Master index
- `SETUP_COMPLETE.md` - Feature summary

---

## Usage Summary

| User Platform | Command | Next Step |
|---|---|---|
| macOS | `./select_openclaw_port_universal.sh` | Follow Claude guide |
| Linux | `./select_openclaw_port_universal.sh` | Follow Claude guide |
| Windows | `powershell -ExecutionPolicy Bypass -File select_openclaw_port.ps1` | Follow Claude guide |
| WSL2 | `./select_openclaw_port_universal.sh` | Follow Claude guide |

**All users then:** Paste `openClawSetup_ForClaudeAgent.md` into Claude and follow step-by-step.

---

## Status Summary

✅ **macOS Support** - Full  
✅ **Linux Support** - Full (Ubuntu, Fedora, others)  
✅ **Windows Support** - Full (native + WSL2)  
✅ **Port Selection** - 3 versions available  
✅ **Installation** - Platform-specific instructions  
✅ **Firewall** - All platforms covered  
✅ **Security** - SSH, fail2ban/lockout, allow-list  
✅ **Documentation** - Comprehensive cross-platform guide  

**READY FOR DEPLOYMENT ACROSS ALL MAJOR PLATFORMS**

---

*Updated: February 7, 2026*  
*Version: 2.1 with Cross-Platform Support*  
*Platforms: macOS, Windows (native + WSL2), Linux (Ubuntu, Fedora, others)*
