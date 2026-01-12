"""
Script to save the current session
Run this to log session stop with metrics
"""
import sys
from pathlib import Path

# Add Backend to path
backend_path = Path(__file__).parent
sys.path.insert(0, str(backend_path))

from session_logger import SessionLogger
from datetime import datetime

def save_session():
    """Save the current session with metrics"""
    logger = SessionLogger()
    
    # Calculate approximate session duration (we don't have exact start time)
    # Using a reasonable estimate or you can provide the actual start time
    session_metrics = {
        "work_items": [
            "Debugged start-al-chat.bat closing immediately issue",
            "Investigated Norton AntiVirus interference",
            "Simplified batch file syntax (removed nested else clause)",
            "Created Norton troubleshooting guides (NORTON_FIX.md, NORTON_SETUP_STEPS.md)",
            "Created test-norton.bat for diagnostic testing",
            "Identified potential antivirus blocking as root cause",
            "Provided step-by-step Norton exclusion instructions"
        ],
        "files_modified": [
            "Frontend/start-al-chat.bat",
            "Frontend/NORTON_FIX.md",
            "Frontend/NORTON_SETUP_STEPS.md",
            "Frontend/test-norton.bat"
        ],
        "issues_identified": [
            "Batch file syntax error: '... was unexpected at this time'",
            "Potential Norton AntiVirus interference with batch file execution",
            "Windows Defender also active and may need exclusions"
        ],
        "solutions_provided": [
            "Simplified batch file structure",
            "Norton exclusion folder instructions",
            "Windows Defender exclusion instructions",
            "Diagnostic test batch file for troubleshooting"
        ],
        "status": "In progress - awaiting Norton configuration"
    }
    
    # Log session stop with metrics
    # Note: If there's no active session, we'll create a manual entry
    stop_entry = logger.stop_session(metrics=session_metrics)
    
    print("=" * 60)
    print("Session Saved Successfully")
    print("=" * 60)
    print(f"Timestamp: {stop_entry['timestamp']}")
    print(f"Session ID: {stop_entry.get('session_id', 'manual_entry')}")
    print(f"Duration: {stop_entry.get('duration_seconds', 'N/A')} seconds")
    print(f"Metrics logged: {len(session_metrics)} categories")
    print("=" * 60)
    print("\nSession log file:", logger._get_log_file_path())
    print("\nWork completed:")
    for item in session_metrics["work_items"]:
        print(f"  - {item}")

if __name__ == "__main__":
    save_session()
