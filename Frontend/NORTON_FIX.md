# Norton AntiVirus Fix

If `start-al-chat.bat` is closing immediately, Norton AntiVirus might be interfering.

## Quick Fix Options:

### Option 1: Add Folder Exception (Recommended)
1. Open Norton AntiVirus
2. Go to **Settings** → **Antivirus** → **Scans and Risks**
3. Click **Exclusions** → **Configure** → **Add**
4. Add this folder: `C:\Users\Alberto Portillo\Documents\AL Chat`
5. Click **OK** and restart the batch file

### Option 2: Temporarily Disable Real-Time Protection
1. Open Norton AntiVirus
2. Temporarily disable **Auto-Protect** / **Real-Time Protection**
3. Run `start-al-chat.bat`
4. Re-enable protection after testing

### Option 3: Check Quarantine
1. Open Norton AntiVirus
2. Go to **Security** → **History**
3. Check if any files were quarantined
4. If found, restore them and add an exception

## Why This Happens:
- Norton may block batch files that run `npm` commands
- Network calls (like `curl`) can trigger security scans
- Scripts that start processes (like Electron) may be flagged

## Alternative: Use PowerShell Script
If Norton continues to interfere, try using `start-al-chat.ps1` instead:
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\start-al-chat.ps1
```
