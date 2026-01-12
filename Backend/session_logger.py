"""
Session Logger Module
Handles session logging with daily rotation and metrics tracking
"""
import os
from datetime import datetime
import json
from pathlib import Path

class SessionLogger:
    """Manages session logging with daily file rotation"""
    
    def __init__(self, log_dir='SessionLog'):
        # Get absolute path relative to project root (parent of Backend directory)
        base_path = Path(__file__).parent.parent
        self.log_dir = base_path / log_dir
        self.log_dir.mkdir(exist_ok=True)
        self.current_session_id = None
        self.session_start_time = None
        
    def _get_log_file_path(self):
        """Get the log file path for today"""
        today = datetime.now().strftime('%Y-%m-%d')
        return self.log_dir / f'session_{today}.log'
    
    def _append_to_log(self, entry):
        """Append an entry to the current day's log file"""
        log_file = self._get_log_file_path()
        with open(log_file, 'a', encoding='utf-8') as f:
            f.write(json.dumps(entry, ensure_ascii=False) + '\n')
    
    def start_session(self):
        """Start a new session and log it"""
        self.session_start_time = datetime.now()
        self.current_session_id = f"session_{self.session_start_time.strftime('%Y%m%d_%H%M%S')}"
        
        entry = {
            "event": "session_start",
            "session_id": self.current_session_id,
            "timestamp": self.session_start_time.isoformat(),
            "date": self.session_start_time.strftime('%Y-%m-%d')
        }
        
        self._append_to_log(entry)
        return self.current_session_id
    
    def stop_session(self, session_id=None, metrics=None):
        """Stop the current session and log it with metrics"""
        if session_id is None:
            session_id = self.current_session_id
        
        stop_time = datetime.now()
        
        # Calculate session duration if start time is available
        duration_seconds = None
        if self.session_start_time:
            duration_seconds = (stop_time - self.session_start_time).total_seconds()
        
        entry = {
            "event": "session_stop",
            "session_id": session_id,
            "timestamp": stop_time.isoformat(),
            "date": stop_time.strftime('%Y-%m-%d'),
            "duration_seconds": duration_seconds,
            "metrics": metrics or {}
        }
        
        self._append_to_log(entry)
        
        # Reset session tracking
        self.current_session_id = None
        self.session_start_time = None
        
        return entry
    
    def log_metric(self, session_id, metric_name, metric_value):
        """Log a metric for the current session"""
        entry = {
            "event": "metric",
            "session_id": session_id,
            "metric_name": metric_name,
            "metric_value": metric_value,
            "timestamp": datetime.now().isoformat(),
            "date": datetime.now().strftime('%Y-%m-%d')
        }
        
        self._append_to_log(entry)
    
    def log_project_init(self, project_criteria):
        """Log initial project organization criteria"""
        entry = {
            "event": "project_init",
            "timestamp": datetime.now().isoformat(),
            "date": datetime.now().strftime('%Y-%m-%d'),
            "project_criteria": project_criteria
        }
        
        self._append_to_log(entry)
