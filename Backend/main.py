"""
AL-Chat Backend
Main entry point for the Python backend server
"""
import os
from flask import Flask, request, jsonify
from flask_cors import CORS
from datetime import datetime
import json
import requests
from session_logger import SessionLogger
from service.openai_service import OpenAIService
from credentials.credential_manager import CredentialManager

app = Flask(__name__)
# Allow CORS from all origins (for local development and integration)
CORS(app, resources={r"/api/*": {"origins": "*"}})

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
    print("[OK] OpenAI service initialized successfully")
except ValueError as e:
    print(f"[WARNING] {e}. OpenAI features will not be available.")
    openai_service_info = {
        "error": str(e),
        "credentials_info": credential_manager.get_credentials_info()
    }

# Track cumulative OpenAI usage statistics
usage_stats = {
    "total_prompt_tokens": 0,
    "total_completion_tokens": 0,
    "total_tokens": 0,
    "request_count": 0,
    "model": openai_service_info.get("model", "unknown") if openai_service_info else "unknown"
}

# Papita API URL for logging usage
PAPITA_API_URL = os.environ.get('PAPITA_API_URL', 'http://localhost:3000')

def log_usage_to_papita(username, is_guest, session_id, model, input_tokens, output_tokens, total_tokens):
    """
    Log usage to Papita API
    
    Args:
        username: Username (or 'guest' for guests)
        is_guest: Whether this is a guest user
        session_id: Session ID for tracking
        model: OpenAI model used
        input_tokens: Input tokens
        output_tokens: Output tokens
        total_tokens: Total tokens
    """
    try:
        # Get user ID if not a guest (would need to query Papita API)
        user_id = None
        
        log_data = {
            'userId': user_id,
            'username': username or 'guest',
            'isGuest': is_guest,
            'sessionId': session_id,
            'projectId': 'al-chat',
            'model': model,
            'inputTokens': input_tokens,
            'outputTokens': output_tokens,
            'totalTokens': total_tokens
        }
        
        response = requests.post(
            f'{PAPITA_API_URL}/api/usage/log',
            json=log_data,
            timeout=5  # 5 second timeout
        )
        
        if response.status_code == 200:
            print(f"[OK] Usage logged to Papita API: {total_tokens} tokens")
        else:
            print(f"[WARNING] Failed to log usage to Papita API: {response.status_code}")
    except Exception as e:
        # Don't fail the request if logging fails
        print(f"[WARNING] Error logging usage to Papita API: {str(e)}")

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
        model = data.get('model')  # Get model from request (sent by frontend)
        attached_files = data.get('attached_files') or []
        if not attached_files and data.get('attached_content'):
            attached_files = [{'name': data.get('attached_filename') or 'file', 'content': data.get('attached_content')}]

        if not message and not attached_files:
            return jsonify({"error": "Message or attachment is required"}), 400

        if attached_files:
            parts = [f"[Attached file {i+1}: {f.get('name', 'file')}]\n\n{f.get('content', '')}" for i, f in enumerate(attached_files)]
            default_msg = 'Please compare and analyze the attached files.' if len(attached_files) > 1 else 'Please analyze the attached file.'
            effective_message = "\n\n---\n\n".join(parts) + "\n\n---\n\n" + (message or default_msg)
        else:
            effective_message = message

        if not openai_service:
            return jsonify({
                "error": "OpenAI service not configured. Please set OPENAI_API_KEY in .env file or ensure Papita API is running."
            }), 500
        
        # Get user information from request
        username = data.get('username', 'guest')
        is_guest = data.get('isGuest', True)
        
        # Get session ID from request headers or body
        session_id = request.headers.get('X-Session-ID') or data.get('sessionId')
        if not session_id:
            # Try to get from session logger if available
            if hasattr(session_logger, 'current_session_id') and session_logger.current_session_id:
                session_id = session_logger.current_session_id
        
        # If username is not provided or is 'guest', treat as guest
        if not username or username == 'guest':
            is_guest = True
            username = 'guest'
        
        # Get response from OpenAI using the service (now returns dict with message and usage)
        try:
            # Use model from request if provided, otherwise use default
            model_to_use = model or openai_service.model
            ai_response_data = openai_service.send_message(effective_message, conversation_history, model=model_to_use)
        except Exception as openai_error:
            # Check if it's an API key error
            error_msg = str(openai_error)
            if "401" in error_msg or "invalid_api_key" in error_msg or "Incorrect API key" in error_msg:
                return jsonify({
                    "error": "Invalid OpenAI API key. Please check your credentials in Papita API or .env file.",
                    "details": "The OpenAI API key is invalid or expired. If using Papita API, ensure it's running and has valid credentials."
                }), 401
            # Re-raise other errors
            raise
        
        # Update cumulative usage statistics
        if "usage" in ai_response_data:
            usage = ai_response_data["usage"]
            usage_stats["total_prompt_tokens"] += usage.get("prompt_tokens", 0)
            usage_stats["total_completion_tokens"] += usage.get("completion_tokens", 0)
            usage_stats["total_tokens"] += usage.get("total_tokens", 0)
            usage_stats["request_count"] += 1
            if usage.get("model"):
                usage_stats["model"] = usage["model"]
            
            # Log usage to Papita API
            model_used = model or usage.get("model") or openai_service.model
            log_usage_to_papita(
                username=username,
                is_guest=is_guest,
                session_id=session_id,
                model=model_used,
                input_tokens=usage.get("prompt_tokens", 0),
                output_tokens=usage.get("completion_tokens", 0),
                total_tokens=usage.get("total_tokens", 0)
            )
        
        response = {
            "message": ai_response_data["message"],
            "usage": ai_response_data.get("usage", {}),
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

@app.route('/api/openai/usage', methods=['GET'])
def get_usage_stats():
    """Get cumulative OpenAI usage statistics"""
    # Calculate estimated cost based on model pricing
    # Pricing as of 2024 (approximate, may vary)
    cost_per_1k_tokens = {
        "gpt-4": {"prompt": 0.03, "completion": 0.06},
        "gpt-4-turbo": {"prompt": 0.01, "completion": 0.03},
        "gpt-4-turbo-preview": {"prompt": 0.01, "completion": 0.03},
        "gpt-4-0125-preview": {"prompt": 0.01, "completion": 0.03},
        "gpt-3.5-turbo": {"prompt": 0.0015, "completion": 0.002},
        "gpt-3.5-turbo-16k": {"prompt": 0.003, "completion": 0.004},
    }
    
    model = usage_stats.get("model", "gpt-3.5-turbo")
    # Handle model name variations
    model_key = model
    if "gpt-4" in model and "turbo" in model:
        model_key = "gpt-4-turbo"
    elif "gpt-3.5" in model and "16k" in model:
        model_key = "gpt-3.5-turbo-16k"
    elif "gpt-3.5" in model:
        model_key = "gpt-3.5-turbo"
    elif "gpt-4" in model:
        model_key = "gpt-4"
    
    pricing = cost_per_1k_tokens.get(model_key, cost_per_1k_tokens["gpt-3.5-turbo"])
    
    prompt_cost = (usage_stats["total_prompt_tokens"] / 1000) * pricing["prompt"]
    completion_cost = (usage_stats["total_completion_tokens"] / 1000) * pricing["completion"]
    total_cost = prompt_cost + completion_cost
    
    # Get account info if available
    account_info = {}
    billing_credit_balance = None
    if openai_service:
        try:
            account_info = openai_service.get_account_info()
            # Note: OpenAI API doesn't provide billing credit balance directly
            # This would need to be fetched from the billing API or set manually
            # For now, we'll return None to indicate it's not available via API
            # Users can check their balance on the OpenAI dashboard
            billing_credit_balance = None  # Set to None - not available via API
        except:
            pass
    
    return jsonify({
        **usage_stats,
        "estimated_cost_usd": round(total_cost, 4),
        "prompt_cost_usd": round(prompt_cost, 4),
        "completion_cost_usd": round(completion_cost, 4),
        "account_info": account_info,
        "billing_credit_balance": billing_credit_balance,  # None = not available via API
        "usage_dashboard_url": "https://platform.openai.com/account/usage",
        "billing_dashboard_url": "https://platform.openai.com/account/billing",
        "note": "For full account usage and billing credit balance, visit the OpenAI Billing Dashboard"
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    # Only enable debug mode in development
    debug_mode = os.environ.get('FLASK_ENV', 'production') == 'development'
    app.run(host='0.0.0.0', port=port, debug=debug_mode)
