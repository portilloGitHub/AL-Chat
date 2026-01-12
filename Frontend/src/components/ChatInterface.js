import React, { useState, useRef, useEffect } from 'react';
import './ChatInterface.css';
import { sendMessage } from '../services/apiService';

function ChatInterface({ sessionId }) {
  const [responses, setResponses] = useState([]);
  const [prompt, setPrompt] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const responsesEndRef = useRef(null);
  const textareaRef = useRef(null);

  // Auto-scroll to bottom when new responses arrive
  useEffect(() => {
    responsesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [responses]);

  // Auto-resize textarea based on content
  useEffect(() => {
    if (textareaRef.current) {
      textareaRef.current.style.height = 'auto';
      const scrollHeight = textareaRef.current.scrollHeight;
      const maxHeight = 300; // Max height in pixels
      textareaRef.current.style.height = Math.min(scrollHeight, maxHeight) + 'px';
    }
  }, [prompt]);

  const handlePaste = async () => {
    try {
      const text = await navigator.clipboard.readText();
      if (text) {
        setPrompt(prev => prev ? prev + '\n\n' + text : text);
        // Focus the textarea after pasting
        setTimeout(() => {
          if (textareaRef.current) {
            textareaRef.current.focus();
            // Move cursor to end
            textareaRef.current.setSelectionRange(textareaRef.current.value.length, textareaRef.current.value.length);
            // Trigger resize
            textareaRef.current.style.height = 'auto';
            const scrollHeight = textareaRef.current.scrollHeight;
            const maxHeight = 300;
            textareaRef.current.style.height = Math.min(scrollHeight, maxHeight) + 'px';
          }
        }, 100);
      }
    } catch (error) {
      console.error('Failed to read clipboard:', error);
      // Fallback: try to paste using execCommand (for older browsers or if clipboard API fails)
      if (textareaRef.current) {
        textareaRef.current.focus();
        document.execCommand('paste');
      }
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!prompt.trim() || isLoading) return;

    const userPrompt = prompt;
    setPrompt('');
    setIsLoading(true);

    try {
      // Build conversation history for context
      const history = responses
        .filter(resp => resp.role !== 'error')
        .map(resp => ({
          role: resp.role,
          content: resp.content
        }));

      const response = await sendMessage(userPrompt, history);
      
      const newResponse = {
        role: 'assistant',
        content: response.message,
        timestamp: response.timestamp,
        usage: response.usage // Include usage stats for potential display
      };
      
      setResponses(prev => [...prev, newResponse]);
    } catch (error) {
      // Add user prompt back to show what they tried to send
      const userMessage = {
        role: 'user',
        content: userPrompt,
        timestamp: new Date().toISOString()
      };
      
      const errorResponse = {
        role: 'error',
        content: error.message || 'An unexpected error occurred',
        timestamp: new Date().toISOString(),
        isNetworkError: error.isNetworkError
      };
      
      setResponses(prev => [...prev, userMessage, errorResponse]);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="chat-interface">
      {/* Top: Responses Area */}
      <div className="responses-area">
        {responses.length === 0 ? (
          <div className="empty-state">
            <p>No responses yet. Enter a prompt below to get started.</p>
          </div>
        ) : (
          responses.map((resp, idx) => (
            <div key={idx} className={`response response-${resp.role}`}>
              <div className="response-content">{resp.content}</div>
            </div>
          ))
        )}
        {isLoading && (
          <div className="response response-loading">
            <div className="loading-indicator">Thinking...</div>
          </div>
        )}
        <div ref={responsesEndRef} />
      </div>

      {/* Bottom: Prompt Input Area */}
      <div className="prompt-area">
        <form onSubmit={handleSubmit} className="prompt-form">
          <div className="prompt-input-container">
            <textarea
              ref={textareaRef}
              value={prompt}
              onChange={(e) => setPrompt(e.target.value)}
              onKeyDown={(e) => {
                // Allow Ctrl+Enter or Cmd+Enter to submit
                if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
                  e.preventDefault();
                  handleSubmit(e);
                }
                // Prevent default Enter behavior (new line) - allow normal Enter for multi-line
                // Only submit on Ctrl+Enter
              }}
              placeholder="Enter your prompt here... (Ctrl+Enter to send)"
              disabled={isLoading}
              className="prompt-input"
              rows={1}
            />
          </div>
          <button
            type="submit"
            disabled={isLoading || !prompt.trim()}
            className="prompt-submit"
          >
            Send
          </button>
        </form>
        
        {/* Mission Control Bar */}
        <div className="mission-control-bar">
          <button
            type="button"
            onClick={handlePaste}
            disabled={isLoading}
            className="mission-control-btn"
            title="Paste from clipboard"
          >
            📋 Paste
          </button>
          <button
            type="button"
            onClick={() => {
              // Trigger dashboard open via window event or prop
              window.dispatchEvent(new CustomEvent('open-dashboard'));
            }}
            className="mission-control-btn"
            title="Open Usage Dashboard"
          >
            📊 Usage Dashboard
          </button>
        </div>
      </div>
    </div>
  );
}

export default ChatInterface;
