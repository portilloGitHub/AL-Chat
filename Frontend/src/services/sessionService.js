import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 10000, // 10 second timeout for session operations
});

// Helper function to extract meaningful error messages
const getErrorMessage = (error) => {
  if (error.response) {
    // Server responded with error status
    const status = error.response.status;
    const data = error.response.data;
    
    if (data && data.error) {
      return `Server Error (${status}): ${data.error}`;
    }
    return `Server Error (${status}): ${error.message}`;
  } else if (error.request) {
    // Request was made but no response received
    if (error.code === 'ECONNREFUSED') {
      return 'Connection Refused: Backend server is not running.';
    }
    if (error.message === 'Network Error') {
      return 'Network Error: Cannot connect to backend.';
    }
    return `Network Error: ${error.message || 'Unable to reach the backend server'}`;
  } else {
    return `Error: ${error.message || 'An unexpected error occurred'}`;
  }
};

export const startSession = async () => {
  try {
    const response = await api.post('/session/start');
    return response.data.session_id;
  } catch (error) {
    const enhancedError = new Error(getErrorMessage(error));
    enhancedError.originalError = error;
    throw enhancedError;
  }
};

export const stopSession = async (sessionId, metrics = {}) => {
  try {
    const response = await api.post('/session/stop', {
      session_id: sessionId,
      metrics,
    });
    return response.data;
  } catch (error) {
    // Don't throw for stop session errors - just log them
    console.error('Failed to stop session:', getErrorMessage(error));
    return { status: 'error', message: getErrorMessage(error) };
  }
};
