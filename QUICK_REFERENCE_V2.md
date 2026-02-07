# ⚡ QUICK START - V2.0 WITH FAILOVER

## What You Asked For
- ✅ Agent should WAIT for me to create Tailscale accounts (pause point added)
- ✅ Llama 3 download is MANDATORY (made mandatory in Step 6)
- ✅ If Claude API fails → switch to Llama 3 (failover configured)
- ✅ Every 30 minutes → check if Claude is back (health check script added)
- ✅ If Claude recovers → switch back automatically (auto-recovery enabled)

## What I Built

| Item | File | Purpose |
|------|------|---------|
| **Setup Guide** | AUTOMATED_AGENT_SETUP_V2.md | 13-step autonomous installation with 4 pause points |
| **Health Monitor** | health_check_monitor.sh | Bash script: checks Claude API every 30 min, auto-switches model |
| **Health Monitor** | health_check_monitor.ps1 | PowerShell: same as above but for Windows |
| **Config Template** | config_template.yml | Complete failover config (fully documented) |
| **Master Instructions** | AGENT_MASTER_INSTRUCTIONS.md | Tells Claude how to execute (updated with pause points) |

## 4 Pause Points (User Action Required)

| # | Step | What | Time | Your Action |
|---|------|------|------|-------------|
| 1 | 3 | API Key (optional) | 1 min | Paste key OR type `SKIP` |
| 2 | 5 | Tailscale Account | 30 sec | Go to login.tailscale.com, sign up free, authorize |
| 3 | 6 | Llama 3 Download | 10-15 min | Wait (or Windows: install Ollama first) |
| 4 | 12 | WhatsApp QR | 5-10 min | Scan QR code on phone, send test message |

**Everything else:** Fully automated ✅

## Failover Strategy (Automatic - No User Input)

```
Bot starts → Uses Claude API (primary)
           ↓
           ↓ (30-min health check)
           ↓
Claude down? → YES → Switch to Llama 3 automatically
            → NO  → Continue with Claude
           ↓
           ↓ (next 30-min check)
           ↓
Claude back up? → YES → Switch back to Claude automatically
               → NO  → Continue with Llama 3
```

## How to Use

### Tell Claude to Start
```
"Begin terraforming"
or
"Install OpenClaw.ai from scratch"
```

### Claude Will:
1. Read AGENT_MASTER_INSTRUCTIONS.md
2. Run AUTOMATED_AGENT_SETUP_V2.md steps 0-13
3. Auto-detect your OS (no asking needed)
4. Pause when it needs you:
   - API key (Step 3)
   - Tailscale account (Step 5)
   - Llama 3 download (Step 6)
   - WhatsApp QR (Step 12)
5. Generate INSTALLATION_REPORT.md
6. Set up health_check_monitor for ongoing monitoring

### What Happens After Installation
1. health_check_monitor runs every 30 minutes
2. Checks if Claude API is available
3. Automatically switches models if needed
4. Logs all switches to: `~/.openclaw/logs/model_switches.log`
5. Bot continues responding (user won't notice the switch)

## Key Differences from V1

| Aspect | V1 | V2 |
|--------|----|----|
| API Key | Required | Optional (Llama 3 fallback) |
| Llama 3 | Optional | **MANDATORY** |
| Failover | Manual | **Automatic every 30 min** |
| Health Checks | Not implemented | health_check_monitor.sh/ps1 |
| Pause Points | 2 (API key, WhatsApp) | 4 (API key, Tailscale, Llama 3, WhatsApp) |
| Configuration | Basic | Comprehensive (with failover strategy) |

## Execution Timeline

| Phase | Time | What's Happening |
|-------|------|------------------|
| Setup Phase 0 (Detect) | 10 sec | Auto-detect OS |
| Setup Phases 1-2 (Install) | 2 min | Port selection, OpenClaw install |
| Setup Phase 3 (API Key) | ⏸️  1 min | **USER PAUSES** - paste key or SKIP |
| Setup Phase 4 (Config) | 30 sec | Auto-configure with failover strategy |
| Setup Phase 5 (Tailscale) | ⏸️  2 min | **USER PAUSES** - create account & authorize |
| Setup Phase 6 (Llama 3) | ⏸️  15 min | **USER WAITS** - download and install model |
| Setup Phase 7-11 (Security) | 5 min | Firewall, SSH, fail2ban, monitoring |
| Setup Phase 12 (Verify) | 2 min | Test all components |
| Setup Phase 13 (WhatsApp) | ⏸️  10 min | **USER PAUSES** - scan QR and test |
| **Total** | **~50 min** | 30 min user time + 20 min auto |

## File Locations

### Configuration
- macOS/Linux: `~/.openclaw/config.yml`
- Windows: `%APPDATA%\OpenClaw\config.yml`

### Logs
- Model switches: `~/.openclaw/logs/model_switches.log`
- Health checks: `~/.openclaw/logs/health_check.log`
- Startup: `~/.openclaw/logs/startup.log`
- Errors: `~/.openclaw/logs/errors.log`

### Installation Report
- `INSTALLATION_REPORT.md` (in setup folder)
- `INSTALLATION_ERRORS.log` (if any errors occurred)

## Testing

**Verify health check script works:**
```bash
# macOS/Linux
./health_check_monitor.sh

# Windows (PowerShell as Administrator)
powershell -ExecutionPolicy Bypass -File health_check_monitor.ps1
```

**Check logs after running:**
```bash
# See health check output
tail -f ~/.openclaw/logs/health_check.log

# See model switches
tail -f ~/.openclaw/logs/model_switches.log
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Script not found" | Make sure you're in the OpenClawAiManagement folder |
| "Permission denied" | Run: `chmod +x health_check_monitor.sh` |
| "Claude API down" | Health check will switch to Llama 3 automatically. Check logs. |
| "Llama 3 not found" | Download may have failed. Retry: `ollama pull llama2` |
| "Bot is slow" | It's using Llama 3 (Claude down). Check `model_switches.log` |
| "Can't find WhatsApp QR" | Check `~/.openclaw/logs/startup.log` for QR code location |

## Success Criteria

✅ OS auto-detected (user never tells Claude their OS)  
✅ Installation runs start-to-finish without permission prompts  
✅ Only 4 pause points for user action (API, Tailscale, Llama 3, WhatsApp)  
✅ Llama 3 is downloaded and ready  
✅ Failover config in place (Claude → Llama 3)  
✅ Health check script running (every 30 min)  
✅ INSTALLATION_REPORT.md generated  
✅ Bot is running and responding on WhatsApp  

## Next Steps

1. **Review:** Open AUTOMATED_AGENT_SETUP_V2.md and skim it
2. **Understand:** Review the 4 pause points and failover strategy
3. **Test:** (Optional) Run manually or read through with Claude
4. **Execute:** Tell Claude: `"Begin terraforming"`
5. **Pause when asked:** Provide API key, create Tailscale account, wait for downloads, scan WhatsApp QR
6. **Done:** Bot is running with automatic failover protection

---

**Version:** 2.0 - Autonomous with Graceful Degradation  
**Status:** ✅ Complete and Ready  
**Next Command:** "Begin terraforming"
