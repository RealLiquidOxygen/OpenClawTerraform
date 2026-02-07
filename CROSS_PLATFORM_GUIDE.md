# OpenClaw.ai Cross-Platform Setup Guide

## Platform Support

✅ **macOS** - Full support (Intel/Apple Silicon)  
✅ **Linux** - Full support (Ubuntu, Debian, Fedora, etc.)  
✅ **Windows** - Full support (native PowerShell or WSL2)

---

## Port Selection by Platform

### macOS and Linux (Bash)

**Option 1: Universal Bash Script (Recommended)**
```bash
chmod +x select_openclaw_port_universal.sh
./select_openclaw_port_universal.sh
```

**Option 2: macOS-specific Bash Script**
```bash
chmod +x select_openclaw_port.sh
./select_openclaw_port.sh
```

### Windows (PowerShell)

**Option 1: Using PowerShell (Recommended)**
```powershell
powershell -ExecutionPolicy Bypass -File select_openclaw_port.ps1
```

**Option 2: If execution policy allows direct execution**
```powershell
.\select_openclaw_port.ps1
```

**Option 3: Windows Subsystem for Linux 2 (WSL2)**
```bash
# Inside WSL2 bash terminal
./select_openclaw_port_universal.sh
```

---

## Platform-Specific Installation Notes

### macOS
```bash
# Ensure Homebrew is installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install OpenClaw via Homebrew (or official method)
brew install openclaw
# or
curl -fsSL https://openclaw.ai/install.sh | bash
```

### Linux (Ubuntu/Debian)
```bash
# Update package manager
sudo apt-get update && sudo apt-get upgrade -y

# Install required tools (optional, for enhanced compatibility)
sudo apt-get install net-tools lsof -y

# Install OpenClaw
curl -fsSL https://openclaw.ai/install.sh | bash
```

### Linux (Fedora/RHEL)
```bash
# Update package manager
sudo dnf update -y

# Install required tools (optional)
sudo dnf install net-tools lsof -y

# Install OpenClaw
curl -fsSL https://openclaw.ai/install.sh | bash
```

### Windows (PowerShell)
```powershell
# Run PowerShell as Administrator

# Install OpenClaw (check openclaw.ai for Windows installer)
# Or use Windows Package Manager if available
winget install openclaw

# Or download and install from openclaw.ai
```

### Windows (WSL2)
```bash
# Install WSL2 (run in PowerShell as Administrator on Windows)
wsl --install

# Inside WSL2 terminal (Linux)
curl -fsSL https://openclaw.ai/install.sh | bash
```

---

## Port Selection Scripts Explained

### select_openclaw_port.sh (macOS/Linux original)
- **Uses:** `lsof` command
- **Platforms:** macOS, Linux (if lsof installed)
- **Advantages:** Reliable, straightforward
- **Disadvantages:** Requires lsof, Windows incompatible

### select_openclaw_port_universal.sh (All platforms)
- **Uses:** OS detection + fallback tools (lsof → netstat → ss → TCP test)
- **Platforms:** macOS, Linux, Windows (Git Bash/MSYS), WSL2
- **Advantages:** Works everywhere, automatic tool detection, OS-specific firewall rules
- **Disadvantages:** More complex logic

### select_openclaw_port.ps1 (Windows native)
- **Uses:** `netstat` and `Get-NetTCPConnection` (Windows native)
- **Platforms:** Windows PowerShell, PowerShell Core (7+)
- **Advantages:** No dependencies, uses Windows native tools
- **Disadvantages:** Windows only

---

## Which Script Should I Use?

### Decision Tree

```
Are you on Windows?
├─ Yes (native Windows)
│  └─ Use: select_openclaw_port.ps1 (PowerShell)
│
├─ Yes (WSL2)
│  └─ Use: select_openclaw_port_universal.sh (bash in WSL2)
│
├─ No (macOS)
│  └─ Use: select_openclaw_port_universal.sh (recommended)
│     OR: select_openclaw_port.sh (simpler)
│
└─ No (Linux)
   └─ Use: select_openclaw_port_universal.sh (recommended)
      OR: select_openclaw_port.sh (if lsof available)
```

### Recommended Approach

| Platform | Script | Command |
|----------|--------|---------|
| **macOS** | `select_openclaw_port_universal.sh` | `./select_openclaw_port_universal.sh` |
| **Linux** | `select_openclaw_port_universal.sh` | `./select_openclaw_port_universal.sh` |
| **Windows (PowerShell)** | `select_openclaw_port.ps1` | `powershell -ExecutionPolicy Bypass -File select_openclaw_port.ps1` |
| **Windows (WSL2)** | `select_openclaw_port_universal.sh` | `./select_openclaw_port_universal.sh` |

---

## Platform-Specific Firewall Configuration

### macOS Firewall

**Option 1: UFW (if installed)**
```bash
sudo ufw allow 8642/tcp
```

**Option 2: pf (native macOS)**
```bash
echo "pass in proto tcp from any to any port 8642" | sudo pfctl -f -
```

### Linux Firewall (Ubuntu/Debian)

**Option 1: UFW (recommended)**
```bash
sudo ufw allow 8642/tcp
sudo ufw enable
```

**Option 2: iptables**
```bash
sudo iptables -A INPUT -p tcp --dport 8642 -j ACCEPT
# Save rules
sudo iptables-save > /etc/iptables/rules.v4
```

### Linux Firewall (Fedora/RHEL)

**Option 1: firewalld (recommended)**
```bash
sudo firewall-cmd --permanent --add-port=8642/tcp
sudo firewall-cmd --reload
```

**Option 2: iptables**
```bash
sudo iptables -A INPUT -p tcp --dport 8642 -j ACCEPT
```

### Windows Firewall

**Option 1: PowerShell (Administrator)**
```powershell
New-NetFirewallRule -DisplayName "OpenClaw Port 8642" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8642
```

**Option 2: Command Prompt (Administrator)**
```cmd
netsh advfirewall firewall add rule name="OpenClaw Port 8642" dir=in action=allow protocol=tcp localport=8642
```

**Option 3: Windows Defender Firewall GUI**
1. Open Windows Defender Firewall
2. Click "Allow an app through firewall"
3. Add OpenClaw.ai to allowed apps
4. Select your network types

---

## Troubleshooting by Platform

### macOS

**Script won't run:**
```bash
chmod +x select_openclaw_port_universal.sh
./select_openclaw_port_universal.sh
```

**lsof not found:**
- Install via Homebrew: `brew install lsof`
- Or use universal script (auto-fallback)

**Port already in use:**
```bash
# Check what's using port
lsof -i :8642

# Check all listening ports
lsof -i -P -n | grep LISTEN
```

### Linux

**Script won't run:**
```bash
chmod +x select_openclaw_port_universal.sh
./select_openclaw_port_universal.sh
```

**Port checking tools missing:**
```bash
# Ubuntu/Debian
sudo apt-get install lsof net-tools

# Fedora/RHEL
sudo dnf install lsof net-tools
```

**Check port usage:**
```bash
# With lsof
lsof -i :8642

# With netstat
netstat -tuln | grep 8642

# With ss
ss -tuln | grep 8642
```

### Windows (PowerShell)

**Execution policy error:**
```powershell
powershell -ExecutionPolicy Bypass -File select_openclaw_port.ps1
```

**Get-NetTCPConnection not available:**
- Fallback to netstat (built-in)
- Script handles this automatically

**Check port usage:**
```powershell
# Modern Windows (PowerShell 5.1+)
Get-NetTCPConnection -LocalPort 8642

# All Windows versions
netstat -ano | findstr :8642
```

### Windows (WSL2)

**WSL2 not installed:**
```powershell
# In PowerShell as Administrator
wsl --install
```

**Port conflict between Windows and WSL2:**
- Ports are shared between Windows and WSL2
- Script auto-detects and finds available port
- Should work seamlessly

---

## Verification Steps by Platform

### macOS/Linux Bash
```bash
# Test port selection
./select_openclaw_port_universal.sh

# View output
cat output.log

# Verify port is available
lsof -i :8642  # Replace with your port
```

### Windows PowerShell
```powershell
# Test port selection
powershell -ExecutionPolicy Bypass -File select_openclaw_port.ps1

# View output
Get-Content output.log

# Verify port is available
Get-NetTCPConnection -LocalPort 8642  # Replace with your port
```

---

## Cross-Platform Considerations

### Port Range
All platforms use 8200-8999 range (user ports, typically unreserved)

### Output Format
All scripts generate same output.log format for consistency

### Firewall Integration
Each script provides platform-specific firewall commands in output.log

### API Key Storage

**macOS:**
```bash
security add-generic-password -s "OpenClaw" -a "claude_key" -w "YOUR_KEY"
```

**Linux:**
```bash
# Use pass (password manager)
pass insert OpenClaw/claude_key

# Or keyring
secret-tool store --label="OpenClaw" openclaw claudekey
```

**Windows:**
```powershell
# Use Windows Credential Manager (built-in)
cmdkey /add:OpenClaw /user:claude_key /pass:YOUR_KEY

# Or PowerShell SecureString
$key = ConvertTo-SecureString "YOUR_KEY" -AsPlainText -Force
$key | Export-Clixml -Path "$env:APPDATA\OpenClaw\key.xml"
```

---

## Next Steps After Port Selection

1. **Run appropriate script for your platform** (see Decision Tree above)
2. **Copy your port from output.log**
3. **Install OpenClaw.ai** (platform-specific instructions above)
4. **Configure OpenClaw** to use your selected port
5. **Set up firewall rules** (commands in output.log)
6. **Continue with Claude guide** (PART 1: Installation)

---

## FAQ

**Q: Can I use the same scripts across platforms?**  
A: Use `select_openclaw_port_universal.sh` on macOS/Linux/WSL2. Use `select_openclaw_port.ps1` on Windows.

**Q: What if port selection fails?**  
A: Run the script again. Fallback algorithm will scan linear range 8500-8900.

**Q: Do I need administrator privileges?**  
A: Port selection doesn't, but firewall configuration does.

**Q: Will my port work if I switch platforms?**  
A: Yes, port numbers are the same. Just reconfigure firewall for new platform.

**Q: Is there a GUI version?**  
A: No, but scripts are straightforward. Claude will guide you through execution.

---

## Support

- **macOS Issues:** See macOS troubleshooting section above
- **Linux Issues:** See Linux troubleshooting section above  
- **Windows Issues:** See Windows troubleshooting section above
- **General Issues:** Refer to openClawSetup.md (comprehensive reference)
