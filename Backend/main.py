"""
AL-Chat Backend
Main entry point for the Python backend server
"""
import os
from flask import Flask, request, jsonify
from flask_cors import CORS
from datetime import datetime
import json
from session_logger import SessionLogger
from service.openai_service import OpenAIService
from credentials.credential_manager import CredentialManager

app = Flask(__name__)
CORS(app)

# Initialize session logger
session_logger = SessionLogger()

# Log initial project organization criteria
project_criteria = {
    "backend": "Python",
    "frontend": "Node.js / React",
    "project_type": "monoproject",
    "github_repo": "https://github.com/portilloGitHub/AL-Chat",
    "folder_structure": [
        "Backend",
        "Frontend",
        "CodeReview",
        "SessionLog",
        "Docs"
    ],
    "documentation_rules": {
        "all_md_files_in_docs": True,
        "exception": "session logs are not stored in Docs"
    },
    "session_log_rules": {
        "log_timestamp_start_stop": True,
        "single_session_log": True,
        "append_mode": True,
        "add_metrics_to_session": True,
        "new_log_per_day": True,
        "log_reference_for_new_sessions": True
    }
}

# Log project initialization criteria
session_logger.log_project_init(project_criteria)

# Initialize credential manager
credential_manager = CredentialManager()

# Initialize OpenAI service
openai_service = None
openai_service_info = None
try:
    openai_service = OpenAIService(credential_manager)
    openai_service_info = openai_service.get_service_info()
    print("✓ OpenAI service initialized successfully")
except ValueError as e:
    print(f"⚠ Warning: {e}. OpenAI features will not be available.")
    openai_service_info = {
        "error": str(e),
        "credentials_info": credential_manager.get_credentials_info()
    }

@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "openai_configured": openai_service is not None
    })

@app.route('/api/openai/test', methods=['GET'])
def test_openai_connection():
    """Test OpenAI connection"""
    if not openai_service:
        return jsonify({
            "status": "error",
            "message": "OpenAI service not configured",
            "info": openai_service_info
        }), 500
    
    try:
        test_result = openai_service.test_connection()
        return jsonify(test_result)
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500

@app.route('/api/openai/info', methods=['GET'])
def get_openai_info():
    """Get OpenAI service configuration info"""
    return jsonify(openai_service_info if openai_service_info else {
        "status": "not_configured",
        "message": "OpenAI service not initialized"
    })

@app.route('/api/chat', methods=['POST'])
def chat():
    """Handle chat requests to OpenAI"""
    try:
        data = request.json
        message = data.get('message', '')
        conversation_history = data.get('history', [])
        
        if not message:
            return jsonify({"error": "Message is required"}), 400
        
        if not openai_service:
            return jsonify({
                "error": "OpenAI service not configured. Please set OPENAI_API_KEY in .env file."
            }), 500
        
        # Get response from OpenAI using the service
        ai_response = openai_service.send_message(message, conversation_history)
        
        response = {
            "message": ai_response,
            "timestamp": datetime.now().isoformat()
        }
        
        return jsonify(response)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/session/start', methods=['POST'])
def start_session():
    """Start a new session"""
    try:
        session_id = session_logger.start_session()
        return jsonify({
            "session_id": session_id,
            "timestamp": datetime.now().isoformat()
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/session/stop', methods=['POST'])
def stop_session():
    """Stop the current session"""
    try:
        data = request.json
        session_id = data.get('session_id')
        metrics = data.get('metrics', {})
        
        session_logger.stop_session(session_id, metrics)
        return jsonify({
            "status": "stopped",
            "timestamp": datetime.now().isoformat()
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=True)
