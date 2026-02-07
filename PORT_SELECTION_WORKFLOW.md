# OpenClaw Port Selection - Automated Workflow

## Overview

The port selection process is now **fully automated**. Users no longer pick ports manually—the system finds an available one randomly and logs it.

## Files Involved

1. **select_openclaw_port.sh** - Bash script that selects and logs port
2. **openClawSetup_ForClaudeAgent.md** - Updated to run script in PART 0
3. **output.log** - Generated log with port details (created at runtime)

## Execution Flow (Claude Agent Perspective)

### PART 0: Port Selection (Automated)

```
USER → Downloads/runs script
     ↓
script scans 8200-8999 range
     ↓
finds first available port
     ↓
creates output.log with port info
     ↓
Claude guides user to read output.log
     ↓
User copies port from log
     ↓
PROCEED TO PART 1
```

## What Happens When Script Runs

```bash
./select_openclaw_port.sh

# Output to console:
# OpenClaw.ai Port Selection Tool
# =================================
# Timestamp: 2026-02-07 12:00:00
# 
# Scanning for available ports...
# Range: 8200-8999 (user ports)
# 
# ✅ PORT SELECTION SUCCESSFUL
# ============================
# SELECTED PORT: 8847
# Status: Available ✓
# Type: TCP (user port)
#
# NEXT STEPS:
# 1. Use port 8847 for OpenClaw gateway
# 2. When CloudBot asks you to change port, tell it: 8847
# 3. In firewall rules, allow port: 8847
#
# CONFIGURATION COMMAND:
# Ask CloudBot: 'Set my gateway port to 8847'
#
# FIREWALL RULES:
# sudo ufw allow from [TAILSCALE_IP] to any port 8847
#
# Log created: output.log
# Generated: 2026-02-07 12:00:00
```

## Port Selection Algorithm

| Step | Details |
|------|---------|
| **Range** | 8200-8999 (user ports, less common conflicts) |
| **Method** | Random selection via `$((8200 + RANDOM % 800))` |
| **Availability Check** | `lsof -Pi :port -sTCP:LISTEN` (checks if port listening) |
| **Retries** | Up to 50 random attempts |
| **Fallback** | Linear scan 8500-8900 if random fails |
| **Output** | Creates `output.log` with structured format |

## Integration Points

### In openClawSetup_ForClaudeAgent.md

**PART 0 (NEW):**
```markdown
## PART 0: PORT SELECTION (RUN FIRST!)

### Step 0: Select Random Available Port

OpenClaw needs a port to run on. We'll automatically select a random available one.

[Script download/execution instructions]

**Claude's role:**
1. Guide user to run script
2. Wait for output.log to be created
3. Have user read the log file
4. Verify it shows: SELECTED PORT: XXXX
5. Save the port number for later steps
```

**PART 2, Security Step 2 (UPDATED):**
```markdown
### Security Step 2: Change Gateway Port (Already Selected!)

Your random port from Part 0 (output.log) is now your gateway port.

[Updated to reference user's specific port from Part 0]
```

**PART 4, Verification (UPDATED):**
```markdown
BASIC FUNCTIONALITY
☐ output.log exists and shows selected port: cat output.log
[Rest of verification items]
```

## User Experience

### Before (Manual)
```
Step 1: Install OpenClaw
Step 2: User picks port manually (which one? default 3000?)
Step 3: Update configuration with manual port
Step 4: Hope it wasn't already in use...
```

### After (Automated)
```
Step 0: Run script → Gets port automatically
Step 1: Install OpenClaw
Step 2: Use port from output.log (guaranteed available)
Step 3: Firewall rules ready to copy from log
✅ No guessing, no conflicts, no manual selection
```

## Copy-Paste Workflow for Users

1. **Run the script:**
   ```bash
   chmod +x select_openclaw_port.sh
   ./select_openclaw_port.sh
   ```

2. **Read the log:**
   ```bash
   cat output.log
   ```

3. **Copy port number** from output (e.g., `8847`)

4. **Copy firewall rule** from output:
   ```bash
   sudo ufw allow from [TAILSCALE_IP] to any port 8847
   ```

5. **Message CloudBot:**
   ```
   "Set my gateway port to 8847"
   ```

## File Locations

| File | Purpose |
|------|---------|
| `select_openclaw_port.sh` | Script (executable) |
| `output.log` | Generated log (created when script runs) |
| `openClawSetup_ForClaudeAgent.md` | Main guide (references Part 0 for port selection) |
| `openClawSetup.md` | Reference guide (technical details) |

## Error Handling

### If script fails to find port:
```bash
ERROR: Could not find available port
Please manually select port between 8000-9999
```

**User action:** Manually pick a port and tell Claude it, then proceed manually with that port.

### If port becomes unavailable during check:
```bash
ERROR: Port [number] became unavailable during selection
Please run script again
```

**User action:** Run script again (rare race condition).

## Security Notes

- **Port range 8200-8999:** User ports (1024-49151), avoids system ports and common conflict zones
- **lsof check:** Verifies actual OS-level listening status (not just TCP connection)
- **Random selection:** Makes port unpredictable (better than fixed ports)
- **Logging:** Output.log provides clear audit trail of which port was selected and when

## Testing the Script

### On current machine:
```bash
chmod +x select_openclaw_port.sh
./select_openclaw_port.sh
cat output.log
```

### Expected result:
```
✅ PORT SELECTION SUCCESSFUL
SELECTED PORT: [8200-8999]
Status: Available ✓
```

## Integration with Claude

When user runs openClawSetup_ForClaudeAgent.md with Claude:

1. Claude sees **PART 0: PORT SELECTION (RUN FIRST!)**
2. Claude instructs user to run the script
3. Claude waits for output.log to be created
4. Claude asks user to share selected port
5. Claude uses that port for all subsequent configuration
6. No manual port selection needed ✓

## Conclusion

The port selection is now:
- ✅ **Automatic** (no user input needed)
- ✅ **Verified** (actually available in OS)
- ✅ **Random** (unpredictable, harder to attack)
- ✅ **Logged** (clear audit trail)
- ✅ **Copy-paste friendly** (all commands ready in output.log)
- ✅ **Idempotent** (can run multiple times, always works)
