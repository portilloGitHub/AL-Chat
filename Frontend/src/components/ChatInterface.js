import React, { useState, useRef, useEffect } from 'react';
import mammoth from 'mammoth';
import './ChatInterface.css';
import { sendMessage } from '../services/apiService';

function ChatInterface({ sessionId, onSaveSession, onStartNewSession }) {
  const [responses, setResponses] = useState([]);
  const [prompt, setPrompt] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isDragging, setIsDragging] = useState(false);
  const [attachedFiles, setAttachedFiles] = useState([]);
  const [saving, setSaving] = useState(false);
  const MAX_FILES = 10;
  const responsesEndRef = useRef(null);
  const textareaRef = useRef(null);
  const fileInputRef = useRef(null);

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

  // Electron: listen for files from native dialog (works when HTML file input fails)
  useEffect(() => {
    if (typeof window === 'undefined' || !window.electronAPI?.onFilesSelected) return;
    const unsub = window.electronAPI.onFilesSelected((data) => {
      setAttachedFiles(prev => [...prev, ...(data.files || [])].slice(0, MAX_FILES));
    });
    return unsub;
  }, []);

  const handleDragOver = (e) => {
    e.preventDefault();
    e.stopPropagation();
    if (e.dataTransfer) e.dataTransfer.dropEffect = 'copy';
    setIsDragging(true);
  };

  const handleDragLeave = (e) => {
    e.preventDefault();
    e.stopPropagation();
    if (e.currentTarget.contains(e.relatedTarget)) return;
    setIsDragging(false);
  };

  const readSingleFile = (file) => {
    if (file.size > 1024 * 1024) return Promise.reject(new Error('size'));
    const ext = (file.name || '').toLowerCase().split('.').pop();
    if (ext === 'doc') return Promise.reject(new Error('.doc not supported'));
    if (ext === 'docx') {
      return file.arrayBuffer()
        .then(ab => mammoth.extractRawText({ arrayBuffer: ab }))
        .then(r => ({ name: file.name, content: r.value }));
    }
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve({ name: file.name, content: reader.result });
      reader.onerror = () => reject(new Error('read'));
      reader.readAsText(file);
    });
  };

  const addFiles = (files, currentCount) => {
    const slots = MAX_FILES - currentCount;
    if (slots <= 0) {
      alert(`Maximum ${MAX_FILES} files. Remove some to add more.`);
      return;
    }
    const toAdd = Array.from(files).slice(0, slots);
    Promise.allSettled(toAdd.map(readSingleFile)).then((results) => {
      const ok = results.filter(r => r.status === 'fulfilled').map(r => r.value);
      const failed = results.filter(r => r.status === 'rejected').length;
      setAttachedFiles(prev => [...prev, ...ok].slice(0, MAX_FILES));
      if (failed) alert(`${failed} file(s) could not be added (over 1MB or unsupported format).`);
    });
  };

  const handleDrop = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(false);
    const files = e.dataTransfer?.files;
    if (!files || files.length === 0) return;
    addFiles(files, attachedFiles.length);
  };

  const handleFileSelect = (e) => {
    const files = e.target.files;
    if (!files || files.length === 0) return;
    e.target.value = '';
    addFiles(files, attachedFiles.length);
  };

  const handleSaveSession = async () => {
    if (typeof onSaveSession !== 'function' || !sessionId || saving) return;
    setSaving(true);
    try {
      const metrics = {
        messages_sent: responses.filter(r => r.role === 'user').length,
        messages_received: responses.filter(r => r.role === 'assistant').length
      };
      await onSaveSession(metrics);
      alert('Session saved.');
    } catch (e) {
      alert('Failed to save: ' + (e?.message || e));
    } finally {
      setSaving(false);
    }
  };

  const handleStartNew = async () => {
    if (typeof onStartNewSession !== 'function' || saving) return;
    if (responses.length > 0 && !window.confirm('Start a new session? This will clear the current chat.')) return;
    setSaving(true);
    try {
      await onStartNewSession();
    } catch (e) {
      alert('Failed to start new session: ' + (e?.message || e));
    } finally {
      setSaving(false);
    }
  };

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
    let messageToSend = prompt.trim();
    if (!messageToSend && attachedFiles.length) {
      messageToSend = attachedFiles.length > 1 ? 'Please compare and analyze the attached files.' : 'Please analyze the attached file.';
    }
    if (!messageToSend || isLoading) return;

    const attachment = attachedFiles.map(f => ({ name: f.name, content: f.content }));
    setPrompt('');
    setAttachedFiles([]);
    setIsLoading(true);

    try {
      const history = responses
        .filter(resp => resp.role !== 'error')
        .map(resp => ({ role: resp.role, content: resp.content }));

      const response = await sendMessage(messageToSend, history, { attachedFiles: attachment });

      const userBubble = { role: 'user', content: messageToSend };
      const newResponse = {
        role: 'assistant',
        content: response.message,
        timestamp: response.timestamp,
        usage: response.usage
      };
      setResponses(prev => [...prev, userBubble, newResponse]);
    } catch (error) {
      const userMessage = {
        role: 'user',
        content: messageToSend,
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
      <div
        className={`prompt-area ${isDragging ? 'drag-over' : ''}`}
        onDragOver={handleDragOver}
        onDragLeave={handleDragLeave}
        onDrop={handleDrop}
      >
        <input
          type="file"
          id="chat-file-input"
          ref={fileInputRef}
          onChange={handleFileSelect}
          style={{ position: 'absolute', opacity: 0, width: '1px', height: '1px', left: '-9999px', overflow: 'hidden' }}
          accept=".txt,.md,.json,.csv,.log,.py,.js,.html,.css,.xml,.yml,.yaml,.doc,.docx"
          multiple
        />
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
              placeholder="Enter your prompt or drop a file here... (Ctrl+Enter to send)"
              disabled={isLoading}
              className="prompt-input"
              rows={1}
            />
          </div>
          <button
            type="submit"
            disabled={isLoading || (!prompt.trim() && !attachedFiles.length)}
            className="prompt-submit"
          >
            Send
          </button>
        </form>
        {attachedFiles.length > 0 && (
          <div className="attached-files-block">
            <div className="attached-files-heading">Attached files ({attachedFiles.length}/{MAX_FILES})</div>
            <ul className="attached-files-list">
              {attachedFiles.map((f, i) => (
                <li key={`${f.name}-${i}`} className="attached-file-item">
                  <span className="attached-file-name">{f.name}</span>
                  <button type="button" onClick={() => setAttachedFiles(prev => prev.filter((_, j) => j !== i))} className="attached-remove" title="Remove this file">Remove</button>
                </li>
              ))}
            </ul>
          </div>
        )}
        
        {/* Mission Control Bar */}
        <div className="mission-control-bar">
          {window.electronAPI?.openFileDialog ? (
            <button
              type="button"
              onClick={() => { if (!isLoading) window.electronAPI.openFileDialog(MAX_FILES - attachedFiles.length); }}
              disabled={isLoading}
              className="mission-control-btn"
              title="Attach up to 10 files to compare (max 1MB each)"
            >
              Attach file
            </button>
          ) : (
            <label
              htmlFor="chat-file-input"
              className="mission-control-btn"
              style={{ margin: 0, cursor: isLoading ? 'not-allowed' : 'pointer', opacity: isLoading ? 0.5 : 1, pointerEvents: isLoading ? 'none' : 'auto' }}
              title="Attach up to 10 files to compare (max 1MB each)"
            >
              Attach file
            </label>
          )}
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
            onClick={() => window.dispatchEvent(new CustomEvent('open-dashboard'))}
            className="mission-control-btn"
            title="Open Usage Dashboard"
          >
            📊 Usage Dashboard
          </button>
          <button
            type="button"
            onClick={handleSaveSession}
            disabled={isLoading || saving || !sessionId || !onSaveSession}
            className="mission-control-btn"
            title="Save current session to log and continue"
          >
            {saving ? '...' : 'Save session'}
          </button>
          <button
            type="button"
            onClick={handleStartNew}
            disabled={isLoading || saving || !onStartNewSession}
            className="mission-control-btn"
            title="Start a new session (clears chat)"
          >
            Start new
          </button>
        </div>
      </div>
    </div>
  );
}

export default ChatInterface;
