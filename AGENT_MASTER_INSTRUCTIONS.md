# 🚀 BEGIN TERRAFORMING - MASTER AGENT INSTRUCTIONS

## FOR CLAUDE AGENT EYES ONLY

This is the master instruction file. When user says:
- "Begin terraforming"
- "Install OpenClaw.ai"  
- "Terraform this machine"
- "Set up OpenClaw.ai from scratch"

**You follow AUTOMATED_AGENT_SETUP.md and execute everything autonomously.**

---

## YOUR MISSION

Install a fully secure OpenClaw.ai bot on this machine with ZERO additional user input (except WhatsApp QR at the end).

**Start here and don't ask questions. Execute steps automatically.**

---

## DETECTION PHASE

### 1. Detect the machine type

Run the appropriate detection script based on what you can identify:

**If you can run bash commands:**
```bash
chmod +x detect_machine.sh
./detect_machine.sh > machine_info.json
cat machine_info.json
```

**If you're on Windows (PowerShell):**
```powershell
powershell -ExecutionPolicy Bypass -File detect_machine.ps1 | Out-File machine_info.json
Get-Content machine_info.json
```

**If detection fails:** Try both, use whichever works, assume Windows 10+ or Linux Ubuntu if no output.

---

## CORE EXECUTION PHASES

Follow this structure from AUTOMATED_AGENT_SETUP.md:

### Phase 1: Port Selection (Step 1A)
- Run appropriate port selection script
- Extract PORT variable from output.log
- Continue if successful, fallback to 8642 if not

### Phase 2: Installation (Step 2-4)
- Install OpenClaw.ai (OS-specific)
- Configure API key (OS-specific storage)
- Configure OpenClaw with selected port

### Phase 3: Security Hardening (Step 5-9)
- Install Tailscale VPN
- Configure firewall (OS-specific)
- Setup SSH keys
- Install fail2ban (or Windows equivalent)
- Enable monitoring
- [Optional] Install Ollama if disk space > 10GB

### Phase 4: Verification (Step 10)
- Verify each component
- Check ports, services, configuration
- Log any failures

### Phase 5: Startup (Step 11)
- Start OpenClaw service
- Verify it's running on correct port

### Phase 6: Completion (Step 12-13)
- Show user the WhatsApp QR code instruction
- Generate completion report
- Declare victory

---

## CRITICAL RULES

### You MUST:
✅ Auto-detect OS (don't ask user which OS they have)  
✅ Auto-select right installation method  
✅ Auto-configure firewall for that OS  
✅ Run all steps without asking permission  
✅ Log all actions to INSTALLATION_REPORT.md  
✅ Log all errors to INSTALLATION_ERRORS.log  
✅ Continue even if non-critical steps fail  
✅ Verify each component after installation  

### You MUST NOT:
❌ Ask "What OS are you on?"  
❌ Ask "Do you want to install X?"  
❌ Ask "Should I configure Y?"  
❌ Stop on first error (retry once, log, continue)  
❌ Require user input except for ONE thing: WhatsApp QR code  
❌ Skip security steps  
❌ Skip verification steps  

---

## API KEY HANDLING (OPTIONAL - Llama 3 IS MANDATORY FALLBACK)

**CRITICAL: Llama 3 is now mandatory.** Bot will ALWAYS have local model fallback.

### Scenario 1: User provides Claude API key
```
"Begin terraforming with API key: sk-ant-..."
```
→ Extract it, use it in Step 3, store it securely
→ Bot uses Claude as PRIMARY model
→ Llama 3 as FALLBACK (if Claude down or tokens depleted)

### Scenario 2: User has API key but doesn't provide upfront
→ In Step 3, you prompt ONCE: "Paste your API key or type SKIP"
→ They paste it (or type SKIP)
→ If SKIP: Bot uses Llama 3 exclusively
→ Continue setup

### Scenario 3: User skips API key
→ Use Llama 3 as PRIMARY model exclusively
→ No failover needed (already using local)
→ They can add API key later via Step 3 re-run

### Scenario 4: Claude API tokens depleted mid-chat
→ Bot automatically switches to Llama 3
→ Conversation continues uninterrupted
→ Every 30 min, bot checks if Claude API recovered
→ If recovered → switches back to Claude

**MANDATORY: Install Llama 3 in Step 6.** This is not optional.

---

## PAUSE POINTS (User Actions Required)

These are the ONLY 3 places where setup pauses for user action:

### Pause 1: API Key (Step 3 - OPTIONAL)
- User prompted to paste Claude API key (or type SKIP)
- Type: `SKIP` if no key, or paste key if they have one
- Bot works either way (Llama 3 fallback handles this)

### Pause 2: Tailscale Account (Step 5 - REQUIRED)
- User goes to https://login.tailscale.com/start
- Signs up (30 seconds, free, email or GitHub)
- When `tailscale up` runs, authorizes device in browser
- When done, presses Enter to continue

### Pause 3: Ollama Installation (Step 6 - REQUIRED)
- Windows only: User downloads OllamaSetup.exe and runs it
- Takes 5-10 minutes
- When done, presses Enter to continue
- Script then downloads Llama 3 8B model (10-15 minutes)

### Pause 4: WhatsApp Connection (Step 12 - REQUIRED)
- User opens WhatsApp phone app
- Scans QR code shown by OpenClaw
- Confirms connection
- Sends test message: "hello"
- Bot responds
- User types: `DONE` and presses Enter

**Everything else is fully automated.**

## FAILOVER STRATEGY (FULLY AUTOMATIC)

This runs without user intervention:

### Model Selection Strategy
1. **Primary Model:** Claude API (lower latency, better quality)
2. **Fallback Model:** Llama 3 8B (local, ~4-5GB, always available)

### Automatic Switching (No User Input Needed)
```
Claude API available
    ↓
    ↓ (working great)
    ↓
⚡ Bot running on Claude API
    ↓
    ↓ (Claude API fails OR tokens depleted)
    ↓
⚡ Bot automatically switches to Llama 3
    ↓
    ↓ (every 30 minutes: health check)
    ↓
Is Claude back? → YES → Switch back to Claude
                → NO  → Continue with Llama 3
```

### Health Check (Every 30 Minutes)
- Automatic: No user action
- Pings Claude API endpoint
- If available: switches to Claude
- If down: continues with Llama 3
- Logged to: `~/.openclaw/logs/model_switches.log`

### Token Depletion Handling
- Bot monitors Claude tokens
- When tokens run low: gracefully switches to Llama 3
- User still gets responses (uninterrupted)
- Next health check will restore Claude if tokens refresh

**User experience:** Seamless. They won't know the switch happened.
## ERROR HANDLING

### When something fails:

1. **Log it:** Add to INSTALLATION_ERRORS.log with timestamp
2. **Retry once:** Re-run the failed step
3. **If still fails:**
   - For critical (OpenClaw, port, Tailscale, Llama 3): Ask user once, get help, continue
   - For optional (fail2ban on some OS): Skip and note in report
   - For security (Firewall, SSH): MUST succeed, ask for help
   - **For Llama 3:** If download fails, pause and ask user to retry manually (mandatory)
4. **Continue:** Don't stop, complete rest of setup
5. **Report:** Flag in INSTALLATION_REPORT.md what partially failed

### Special Case: Ollama/Llama 3 Download
- Download size: 4-5GB
- Time: 10-15 minutes typical
- If it times out or fails:
  - User can pause, check internet, resume
  - Retry the download manually
  - Do NOT skip (Llama 3 is mandatory)

---

## SETUP FILE MAPPING

Use the UPDATED v2.0 files:

- **AUTOMATED_AGENT_SETUP_V2.md** ← PRIMARY GUIDE (read this, execute this)
  - Steps 0-13 with ALL pause points and failover configuration
  - Llama 3 mandatory in Step 6
  - API failover configured in Step 4
  - Health check monitoring explained

- **health_check_monitor.sh** ← Run on macOS/Linux
  - Monitors Claude API every 30 minutes
  - Auto-switches to Llama 3 if Claude down
  - Auto-recovers when Claude comes back
  - Logs to: ~/.openclaw/logs/model_switches.log

- **health_check_monitor.ps1** ← Run on Windows
  - Same functionality as bash version
  - PowerShell syntax
  - Logs to: %APPDATA%\OpenClaw\logs\model_switches.log

- **config_template.yml** ← Reference documentation
  - Complete config with all failover options explained
  - User copies to ~/.openclaw/config.yml
  - Edit config file name in setup if needed

- **AGENT_MASTER_INSTRUCTIONS.md** (this file) ← Updated with pause points & failover

---

## VERIFICATION CHECKLIST (After Step 10)

Critical items to verify before moving to startup:

```
✅ OpenClaw installed (openclaw --version works)
✅ Port selected (output.log has port number)
✅ Port listening (lsof/netstat shows port $PORT)
✅ Tailscale connected (tailscale status shows "Connected")
✅ Firewall active (ufw/firewalld/pf shows rules)
✅ SSH key exists (~/.ssh/id_ed25519 present)
✅ fail2ban running (or Windows lockout policy active)
✅ Monitoring configured (~/.openclaw/monitoring.yml exists)
✅ Llama 3 downloaded (ollama list shows llama2)
✅ Failover config in place (~/.openclaw/config.yml has model_strategy: failover)
✅ Health check script ready (health_check_monitor.sh/ps1 executable)
```

If any fail, try to fix. If can't fix, log and move on (except: Tailscale, Firewall, OpenClaw, Llama 3, Failover config which are critical)

---

## FINAL STEPS

### 13.1 Start Service
```
nohup openclaw start --port $PORT &> ~/.openclaw/logs/startup.log &
sleep 3
curl http://localhost:$PORT/health
```

### 13.2 Show Completion
```
🎉 INSTALLATION COMPLETE

Your OpenClaw.ai bot is:
- ✅ Installed and running
- ✅ Secure (VPN, firewall, SSH)
- ✅ Monitoring itself
- ✅ Listening on port $PORT
- ✅ Protected behind Tailscale

NEXT: Open WhatsApp and scan QR code at https://openclaw.ai/connect

Questions? Check INSTALLATION_REPORT.md or INSTALLATION_ERRORS.log
```

### 13.3 Wait for WhatsApp QR Completion
```
User should:
1. Scan QR code
2. Confirm phone number
3. Send test message
4. Reply with "Done" when connected

You wait, then declare victory.
```

---

## REPORTING

### Create these files:

1. **machine_info.json** - Machine detection output
2. **port_output.log** - Port selection log
3. **INSTALLATION_REPORT.md** - Complete summary with all config
4. **INSTALLATION_ERRORS.log** - Any errors encountered (even if fixed)

### Example INSTALLATION_REPORT.md:
```
# OpenClaw.ai Installation Report

## System
- OS: macOS
- Arch: x86_64
- Memory: 16GB
- Disk: 200GB free

## Installation Status
- OpenClaw: ✅ Installed v2.1.0
- Port: ✅ Selected 8847
- Tailscale: ✅ Connected (100.64.1.2)
- Firewall: ✅ Configured (UFW)
- SSH: ✅ Keys generated
- fail2ban: ✅ Running
- Monitoring: ✅ Enabled
- API Key: ✅ Stored (Keychain)

## Configuration
- Port: 8847
- Tailscale IP: 100.64.1.2
- Firewall: UFW allow from 100.64.1.2:8847
- Monitoring: Check every 5 min
- Logging: ~/.openclaw/logs/openclaw.log

## Status
✅ READY TO USE

Next: Scan WhatsApp QR code at https://openclaw.ai/connect
```

---

## TIMEOUT HANDLING

**For any step that takes > 30 seconds:**
- Add progress indicator (dots, spinning wheel, percentage)
- After 60 seconds, show estimate ("Estimated 5 more minutes...")
- After 5 minutes, ask if user wants to continue or skip

**Example:**
```
Installing OpenClaw (this may take a few minutes)...
⠟ Still installing... (2 min remaining)
⠯ Still installing... (1 min remaining)
⠹ Done!
```

---

## SUCCESS CRITERIA

You've succeeded when:

✅ User says "Begin terraforming"  
✅ You never ask "What OS are you on?"  
✅ Machine is auto-detected  
✅ All steps execute without user permission  
✅ User provides API key once (if at all)  
✅ User scans ONE WhatsApp QR  
✅ Bot is running and secure  
✅ INSTALLATION_REPORT.md is complete  
✅ User sees "Installation Complete ✅"  

---

## FAILURE CRITERIA

You've failed if:

❌ You ask user which OS they're on  
❌ You ask permission for each step  
❌ You prompt for API key multiple times  
❌ You stop on first error  
❌ User has to troubleshoot anything  
❌ Security hardening steps are skipped  
❌ You declare success before WhatsApp QR step  

---

## STARTING COMMAND PHRASES

User might say any of these to start:

- "Begin terraforming"
- "Install OpenClaw.ai"
- "Terraform this machine"
- "Set up my bot"
- "Install the bot"
- "Start the installation"
- "Do the thing"
- "Let's go"

**When you see ANY command asking to install/setup/terraform, execute AUTOMATED_AGENT_SETUP.md immediately. Don't ask for clarification.**

---

## YOUR CHECKLIST

Before you start, you have:

✅ AUTOMATED_AGENT_SETUP.md (main execution guide)  
✅ detect_machine.sh (macOS/Linux detection)  
✅ detect_machine.ps1 (Windows detection)  
✅ select_openclaw_port.sh (bash port selection)  
✅ select_openclaw_port.ps1 (PowerShell port selection)  
✅ select_openclaw_port_universal.sh (universal fallback)  
✅ openClawSetup.md (reference if needed)  
✅ CROSS_PLATFORM_GUIDE.md (platform-specific details)  

**Everything you need is in this project folder.**

---

## EXECUTION BEGINS NOW

**When user says "Begin terraforming":**

```
1. Read this file completely
2. Read AUTOMATED_AGENT_SETUP.md completely
3. Run detect_machine.sh or detect_machine.ps1
4. Follow AUTOMATED_AGENT_SETUP.md Step 0 onwards
5. Execute every step without asking permission
6. Log everything to INSTALLATION_REPORT.md
7. Skip nothing except when explicitly "optional"
8. On error: retry once, log, continue
9. At end: show completion report
10. Wait for WhatsApp QR confirmation
11. Declare victory
```

---

**VERSION:** 2.2 Fully Autonomous Agent  
**MODE:** Auto-execute on "Begin terraforming"  
**USER INPUT REQUIRED:** API key (once) + WhatsApp QR (once)  
**DURATION:** 45-60 minutes  
**COMPLEXITY:** Zero for user, 100% automated by agent  

**READY TO EXECUTE. AWAITING USER COMMAND.**
