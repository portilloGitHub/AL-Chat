# Norton AntiVirus Setup for AL-Chat

## Step-by-Step Instructions

### Method 1: Add Folder Exclusion (Best Option)

1. **Open Norton AntiVirus**
   - Right-click the Norton icon in your system tray (bottom-right corner)
   - Or search for "Norton" in Windows Start menu

2. **Navigate to Settings**
   - Click the **Settings** icon (gear icon) in the top-right
   - Or go to **Settings** from the main window

3. **Go to Antivirus Settings**
   - Click **Antivirus** in the left sidebar
   - Then click **Scans and Risks**

4. **Add Exclusion**
   - Under **Exclusions / Low Risks**, click **Configure** (or **Add**)
   - Click **Add** or **+** button
   - Select **Folders and Files**
   - Browse to: `C:\Users\Alberto Portillo\Documents\AL Chat`
   - Click **OK** or **Add**
   - Make sure the checkbox is **checked** (enabled)
   - Click **Apply** or **OK**

5. **Also Exclude from Auto-Protect**
   - In the same **Scans and Risks** section
   - Look for **Exclusions** under **Real-Time Protection** or **Auto-Protect**
   - Add the same folder there as well

### Method 2: Disable Script Blocking (If Method 1 doesn't work)

1. **Open Norton Settings** (same as above)

2. **Go to Firewall Settings**
   - Click **Firewall** in the left sidebar
   - Look for **Program Control** or **Application Blocking**

3. **Allow Batch Files**
   - Find `cmd.exe` or `Command Prompt`
   - Set it to **Allow** (not Block)
   - Also check for any entries related to `npm` or `node`

### Method 3: Temporarily Disable Auto-Protect (For Testing Only)

1. **Open Norton**
2. Click **Settings** → **Antivirus**
3. Turn **OFF** "Auto-Protect" or "Real-Time Protection"
4. **Run your batch file** to test
5. **Turn it back ON** after testing

⚠️ **Warning**: Only disable protection temporarily for testing!

### Method 4: Check Quarantine

1. **Open Norton**
2. Go to **Security** → **History** (or **Quarantine**)
3. Look for any files from `AL Chat` folder
4. If found, **Restore** them
5. Then add the folder to exclusions (Method 1)

## What to Look For:

- **Folder Path**: `C:\Users\Alberto Portillo\Documents\AL Chat`
- **File Types to Allow**: `.bat`, `.js`, `.json`, `.exe` (for npm/node)
- **Processes to Allow**: `cmd.exe`, `node.exe`, `npm.cmd`

## After Making Changes:

1. **Close any open command windows**
2. **Restart your computer** (recommended)
3. **Try running `start-al-chat.bat` again**

## Still Not Working?

If Norton settings don't help, the issue might be:
- Windows Defender (also check its exclusions)
- Another security software
- A different batch file syntax issue

Let me know what happens after trying these steps!
