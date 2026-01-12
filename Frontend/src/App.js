import React, { useState, useEffect } from 'react';
import './App.css';
import ChatInterface from './components/ChatInterface';
import { startSession, stopSession } from './services/sessionService';

function App() {
  const [sessionId, setSessionId] = useState(null);
  const [isConnected, setIsConnected] = useState(false);

  useEffect(() => {
    // Start session when app loads
    const initializeSession = async () => {
      try {
        const id = await startSession();
        setSessionId(id);
        setIsConnected(true);
      } catch (error) {
        console.error('Failed to start session:', error);
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
        {isConnected && (
          <div className="status-indicator">
            <span className="status-dot connected"></span>
            <span>Connected</span>
          </div>
        )}
      </header>
      <main className="App-main">
        <ChatInterface sessionId={sessionId} />
      </main>
    </div>
  );
}

export default App;
