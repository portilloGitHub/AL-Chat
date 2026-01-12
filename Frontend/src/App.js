import React, { useState, useEffect } from 'react';
import './App.css';
import ChatInterface from './components/ChatInterface';
import OpenAIStatsDashboard from './components/OpenAIStatsDashboard';
import { startSession, stopSession } from './services/sessionService';
import { healthCheck } from './services/apiService';

function App() {
  const [sessionId, setSessionId] = useState(null);
  const [isConnected, setIsConnected] = useState(false);
  const [backendError, setBackendError] = useState(null);
  const [showDashboard, setShowDashboard] = useState(false);

  useEffect(() => {
    // Check backend connection and start session when app loads
    const initializeSession = async () => {
      try {
        // First check if backend is reachable
        await healthCheck();
        
        // Then start session
        const id = await startSession();
        setSessionId(id);
        setIsConnected(true);
        setBackendError(null);
      } catch (error) {
        console.error('Failed to start session:', error);
        setIsConnected(false);
        setBackendError(error.message || 'Cannot connect to backend server');
      }
    };

    initializeSession();

    // Stop session when app unloads
    return () => {
      if (sessionId) {
        stopSession(sessionId, {
          messages_sent: 0,
          messages_received: 0
        }).catch(console.error);
      }
    };
  }, []);

  return (
    <div className="App">
      <header className="App-header">
        <h1>AL-Chat</h1>
        {isConnected ? (
          <div className="status-indicator">
            <span className="status-dot connected"></span>
            <span>Connected</span>
          </div>
        ) : (
          <div className="status-indicator">
            <span className="status-dot disconnected"></span>
            <span>Disconnected</span>
          </div>
        )}
      </header>
      {backendError && (
        <div className="backend-error-banner">
          <strong>Backend Connection Error:</strong> {backendError}
          <br />
          <small>Please make sure the backend is running on http://localhost:5000</small>
        </div>
      )}
      <main className="App-main">
        <div className="App-content">
          <div className="App-chat">
            <ChatInterface sessionId={sessionId} />
          </div>
        </div>
        <button 
          className="dashboard-toggle-btn"
          onClick={() => setShowDashboard(true)}
          title="Open Usage Dashboard"
        >
          📊 Usage Dashboard
        </button>
        <OpenAIStatsDashboard 
          isOpen={showDashboard} 
          onClose={() => setShowDashboard(false)} 
        />
      </main>
    </div>
  );
}

export default App;
