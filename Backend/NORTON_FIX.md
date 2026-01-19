# Norton AntiVirus Fix for AL-Chat Backend

If the backend (`python main.py`) won't start or can't connect to `localhost:5000`, Norton AntiVirus might be blocking it.

## Quick Test

**Temporarily disable Norton Auto-Protect:**
1. Right-click Norton icon in system tray
2. Click **Settings** → **Antivirus**
3. Turn **OFF** "Auto-Protect" temporarily
4. Try starting backend: `python main.py`
5. If it works, Norton is the issue - follow steps below
6. **Turn Auto-Protect back ON** after testing

## Solution: Add Exclusions

### Step 1: Exclude AL-Chat Folder

1. **Open Norton AntiVirus**
   - Right-click Norton icon in system tray
   - Or search "Norton" in Windows Start menu

2. **Navigate to Exclusions**
   - Click **Settings** (gear icon)
   - Go to **Antivirus** → **Scans and Risks**
   - Click **Exclusions / Low Risks** → **Configure**

3. **Add Folder Exclusion**
   - Click **Add** or **+** button
   - Select **Folders and Files**
   - Browse to: `C:\Users\Alberto Portillo\Documents\AL Chat`
   - Click **OK** or **Add**
   - Make sure checkbox is **checked** (enabled)
   - Click **Apply** or **OK**

### Step 2: Exclude Python Executable

1. **In same Exclusions section**
   - Click **Add** again
   - Select **Files and Folders**
   - Browse to Python installation:
     - `C:\Python314\python.exe` (or wherever Python is installed)
     - Or: `C:\Users\Alberto Portillo\AppData\Local\Programs\Python\Python314\python.exe`
   - Click **OK**

### Step 3: Allow Localhost Connections (Firewall)

1. **Open Norton Firewall Settings**
   - Click **Settings** → **Firewall**
   - Go to **Program Control** or **Application Blocking**

2. **Allow Python**
   - Find `python.exe` in the list
   - Set it to **Allow** (not Block)
   - If not listed, click **Add** and browse to Python executable

3. **Allow Port 5000**
   - Look for **Port Rules** or **Advanced Settings**
   - Add rule: Allow **Inbound** and **Outbound** on port **5000**
   - Or allow **localhost** connections

## Alternative: Disable Script Blocking

If exclusions don't work:

1. **Norton Settings** → **Antivirus** → **Scans and Risks**
2. Look for **Script Blocking** or **Behavioral Protection**
3. Temporarily disable for testing
4. If backend works, re-enable and add exclusions instead

## Check Quarantine

1. **Open Norton**
2. Go to **Security** → **History** (or **Quarantine**)
3. Look for any Python files or files from `AL Chat` folder
4. If found, **Restore** them
5. Then add folder to exclusions

## After Making Changes

1. **Close any running Python processes**
2. **Restart your computer** (recommended)
3. **Try starting backend again:**
   ```bash
   cd "C:\Users\Alberto Portillo\Documents\AL Chat\Backend"
   python main.py
   ```

## Verify Backend is Running

After starting, test in another terminal:
```bash
curl http://localhost:5000/api/health
```

Should return:
```json
{
  "status": "healthy",
  "timestamp": "...",
  "openai_configured": true
}
```

## Still Not Working?

If Norton exclusions don't help, also check:
- **Windows Defender** exclusions (add same folder)
- **Windows Firewall** (allow Python and port 5000)
- Other security software running

## Why This Happens

- Norton may flag Python scripts that:
  - Start network servers (Flask on port 5000)
  - Make HTTP requests (httpx to Papita API)
  - Access environment variables (.env files)
  - Create log files (SessionLog folder)

Adding exclusions tells Norton these are safe files you trust.
