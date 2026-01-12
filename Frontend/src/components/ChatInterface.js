import React, { useState, useRef, useEffect } from 'react';
import './ChatInterface.css';
import { sendMessage } from '../services/apiService';

function ChatInterface({ sessionId }) {
  const [responses, setResponses] = useState([]);
  const [prompt, setPrompt] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const responsesEndRef = useRef(null);

  // Auto-scroll to bottom when new responses arrive
  useEffect(() => {
    responsesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [responses]);

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
        timestamp: response.timestamp
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
          <input
            type="text"
            value={prompt}
            onChange={(e) => setPrompt(e.target.value)}
            placeholder="Enter your prompt here..."
            disabled={isLoading}
            className="prompt-input"
          />
          <button
            type="submit"
            disabled={isLoading || !prompt.trim()}
            className="prompt-submit"
          >
            Send
          </button>
        </form>
      </div>
    </div>
  );
}

export default ChatInterface;
