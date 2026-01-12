import React, { useState, useEffect } from 'react';
import { getUsageStats } from '../services/apiService';
import './OpenAIStats.css';

function OpenAIStats() {
  const [stats, setStats] = useState(null);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(true);

  const fetchStats = async () => {
    try {
      setError(null);
      const data = await getUsageStats();
      setStats(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchStats();
    // Refresh stats every 5 seconds
    const interval = setInterval(fetchStats, 5000);
    return () => clearInterval(interval);
  }, []);

  const formatNumber = (num) => {
    return new Intl.NumberFormat('en-US').format(num);
  };

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 4,
      maximumFractionDigits: 4
    }).format(amount);
  };

  if (loading) {
    return (
      <div className="openai-stats">
        <div className="stats-header">
          <h2>OpenAI Usage</h2>
        </div>
        <div className="stats-content">
          <div className="stats-loading">Loading...</div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="openai-stats">
        <div className="stats-header">
          <h2>OpenAI Usage</h2>
        </div>
        <div className="stats-content">
          <div className="stats-error">Error: {error}</div>
        </div>
      </div>
    );
  }

  if (!stats) {
    return (
      <div className="openai-stats">
        <div className="stats-header">
          <h2>OpenAI Usage</h2>
        </div>
        <div className="stats-content">
          <div className="stats-empty">No usage data available</div>
        </div>
      </div>
    );
  }

  return (
    <div className="openai-stats">
      <div className="stats-header">
        <h2>OpenAI Usage</h2>
        <button className="refresh-btn" onClick={fetchStats} title="Refresh stats">
          ↻
        </button>
      </div>
      <div className="stats-content">
        {stats.account_info && stats.account_info.api_key_prefix && (
          <div className="stat-section account-info">
            <div className="stat-label">Account</div>
            <div className="stat-value account-key">
              {stats.account_info.api_key_prefix}
            </div>
            {stats.account_info.status && (
              <div className="account-status">
                <span className={`status-badge ${stats.account_info.status}`}>
                  {stats.account_info.status}
                </span>
              </div>
            )}
          </div>
        )}

        <div className="stat-section">
          <div className="stat-label">Model</div>
          <div className="stat-value model">{stats.model || 'N/A'}</div>
        </div>

        <div className="stat-section">
          <div className="stat-label">Session Requests</div>
          <div className="stat-value">{formatNumber(stats.request_count || 0)}</div>
          <div className="stat-note">This session only</div>
        </div>

        <div className="stat-section">
          <div className="stat-label">Session Tokens</div>
          <div className="stat-value highlight">{formatNumber(stats.total_tokens || 0)}</div>
          <div className="stat-note">This session only</div>
        </div>

        <div className="stat-section">
          <div className="stat-label">Prompt Tokens</div>
          <div className="stat-value">{formatNumber(stats.total_prompt_tokens || 0)}</div>
        </div>

        <div className="stat-section">
          <div className="stat-label">Completion Tokens</div>
          <div className="stat-value">{formatNumber(stats.total_completion_tokens || 0)}</div>
        </div>

        <div className="stat-divider"></div>

        <div className="stat-divider"></div>

        <div className="stat-section cost">
          <div className="stat-label">Session Cost</div>
          <div className="stat-value cost-value">
            {formatCurrency(stats.estimated_cost_usd || 0)}
          </div>
          <div className="stat-note">This session only</div>
        </div>

        <div className="stat-section">
          <div className="stat-label">Prompt Cost</div>
          <div className="stat-value cost-small">
            {formatCurrency(stats.prompt_cost_usd || 0)}
          </div>
        </div>

        <div className="stat-section">
          <div className="stat-label">Completion Cost</div>
          <div className="stat-value cost-small">
            {formatCurrency(stats.completion_cost_usd || 0)}
          </div>
        </div>

        {stats.usage_dashboard_url && (
          <div className="stat-section dashboard-link">
            <a 
              href={stats.usage_dashboard_url} 
              target="_blank" 
              rel="noopener noreferrer"
              className="dashboard-button"
            >
              View Full Account Usage →
            </a>
            <div className="stat-note">
              See all usage across all applications
            </div>
          </div>
        )}

        <div className="stat-footer">
          <small>Session stats update every 5 seconds</small>
          {stats.note && (
            <div className="stat-footer-note">
              <small>{stats.note}</small>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default OpenAIStats;
