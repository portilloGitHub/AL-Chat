import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

export const startSession = async () => {
  const response = await api.post('/session/start');
  return response.data.session_id;
};

export const stopSession = async (sessionId, metrics = {}) => {
  const response = await api.post('/session/stop', {
    session_id: sessionId,
    metrics,
  });
  return response.data;
};
