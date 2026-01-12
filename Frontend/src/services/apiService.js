import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 30000, // 30 second timeout
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
    if (status === 404) {
      return 'Backend endpoint not found. Is the backend running?';
    }
    if (status === 500) {
      return 'Server Error: The backend encountered an error processing your request.';
    }
    return `Server Error (${status}): ${error.message}`;
  } else if (error.request) {
    // Request was made but no response received
    if (error.code === 'ECONNREFUSED') {
      return 'Connection Refused: Backend server is not running. Please start the backend on port 5000.';
    }
    if (error.code === 'ETIMEDOUT' || error.code === 'ECONNABORTED') {
      return 'Request Timeout: The backend took too long to respond.';
    }
    if (error.message === 'Network Error') {
      return 'Network Error: Cannot connect to backend. Make sure the backend is running on http://localhost:5000';
    }
    return `Network Error: ${error.message || 'Unable to reach the backend server'}`;
  } else {
    // Something else happened
    return `Error: ${error.message || 'An unexpected error occurred'}`;
  }
};

export const sendMessage = async (message, history = []) => {
  try {
    const response = await api.post('/chat', { 
      message,
      history 
    });
    return response.data;
  } catch (error) {
    // Enhance error with better message
    const enhancedError = new Error(getErrorMessage(error));
    enhancedError.originalError = error;
    enhancedError.isNetworkError = !error.response && !!error.request;
    throw enhancedError;
  }
};

export const healthCheck = async () => {
  try {
    const response = await api.get('/health');
    return response.data;
  } catch (error) {
    const enhancedError = new Error(getErrorMessage(error));
    enhancedError.originalError = error;
    throw enhancedError;
  }
};
