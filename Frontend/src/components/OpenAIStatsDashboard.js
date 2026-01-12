import React, { useState, useEffect } from 'react';
import { getUsageStats } from '../services/apiService';
import './OpenAIStatsDashboard.css';

function OpenAIStatsDashboard({ isOpen, onClose }) {
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
    if (isOpen) {
      fetchStats();
      // Refresh stats every 5 seconds when dashboard is open
      const interval = setInterval(fetchStats, 5000);
      return () => clearInterval(interval);
    }
  }, [isOpen]);

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

  if (!isOpen) return null;

  return (
    <div className="dashboard-overlay" onClick={onClose}>
      <div className="dashboard-container" onClick={(e) => e.stopPropagation()}>
        <div className="dashboard-header">
          <h2>OpenAI Usage Dashboard</h2>
          <div className="dashboard-header-actions">
            <button className="refresh-btn" onClick={fetchStats} title="Refresh stats">
              ↻
            </button>
            <button className="close-btn" onClick={onClose} title="Close dashboard">
              ×
            </button>
          </div>
        </div>

        <div className="dashboard-content">
          {loading ? (
            <div className="dashboard-loading">Loading usage statistics...</div>
          ) : error ? (
            <div className="dashboard-error">Error: {error}</div>
          ) : !stats ? (
            <div className="dashboard-empty">No usage data available</div>
          ) : (
            <>
              {/* Account Information Section */}
              <div className="dashboard-section">
                <h3>Account Information</h3>
                <div className="stats-grid">
                  {stats.account_info && stats.account_info.api_key_prefix && (
                    <div className="stat-card account-card">
                      <div className="stat-label">API Key</div>
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

                  <div className="stat-card">
                    <div className="stat-label">Model</div>
                    <div className="stat-value model">{stats.model || 'N/A'}</div>
                  </div>

                  <div className="stat-card credit-card">
                    <div className="stat-label">Billing Credit Balance</div>
                    {stats.billing_credit_balance !== undefined && stats.billing_credit_balance !== null ? (
                      <>
                        <div className="stat-value credit-balance">
                          {formatCurrency(stats.billing_credit_balance)}
                        </div>
                        <div className="stat-note">
                          {stats.billing_credit_balance > 0 
                            ? 'Credits available' 
                            : 'No credits - pay-as-you-go'}
                        </div>
                      </>
                    ) : (
                      <>
                        <div className="stat-value credit-balance unavailable">
                          Not available via API
                        </div>
                        <div className="stat-note">
                          {stats.billing_dashboard_url ? (
                            <a 
                              href={stats.billing_dashboard_url} 
                              target="_blank" 
                              rel="noopener noreferrer"
                              className="billing-link"
                            >
                              Check on Billing Dashboard →
                            </a>
                          ) : (
                            'Check your OpenAI account'
                          )}
                        </div>
                      </>
                    )}
                  </div>
                </div>
              </div>

              {/* Session Usage Section */}
              <div className="dashboard-section">
                <h3>Current Session Usage</h3>
                <div className="stats-grid">
                  <div className="stat-card">
                    <div className="stat-label">Requests</div>
                    <div className="stat-value">{formatNumber(stats.request_count || 0)}</div>
                    <div className="stat-note">This session only</div>
                  </div>

                  <div className="stat-card highlight-card">
                    <div className="stat-label">Total Tokens</div>
                    <div className="stat-value highlight">{formatNumber(stats.total_tokens || 0)}</div>
                    <div className="stat-note">This session only</div>
                  </div>

                  <div className="stat-card">
                    <div className="stat-label">Prompt Tokens</div>
                    <div className="stat-value">{formatNumber(stats.total_prompt_tokens || 0)}</div>
                  </div>

                  <div className="stat-card">
                    <div className="stat-label">Completion Tokens</div>
                    <div className="stat-value">{formatNumber(stats.total_completion_tokens || 0)}</div>
                  </div>
                </div>
              </div>

              {/* Cost Section */}
              <div className="dashboard-section">
                <h3>Session Cost</h3>
                <div className="stats-grid">
                  <div className="stat-card cost-card">
                    <div className="stat-label">Total Cost</div>
                    <div className="stat-value cost-value">
                      {formatCurrency(stats.estimated_cost_usd || 0)}
                    </div>
                    <div className="stat-note">This session only</div>
                  </div>

                  <div className="stat-card">
                    <div className="stat-label">Prompt Cost</div>
                    <div className="stat-value cost-small">
                      {formatCurrency(stats.prompt_cost_usd || 0)}
                    </div>
                  </div>

                  <div className="stat-card">
                    <div className="stat-label">Completion Cost</div>
                    <div className="stat-value cost-small">
                      {formatCurrency(stats.completion_cost_usd || 0)}
                    </div>
                  </div>
                </div>
              </div>

              {/* Dashboard Link */}
              {stats.usage_dashboard_url && (
                <div className="dashboard-section">
                  <div className="dashboard-link-card">
                    <p>View full account usage across all applications</p>
                    <a 
                      href={stats.usage_dashboard_url} 
                      target="_blank" 
                      rel="noopener noreferrer"
                      className="dashboard-button"
                    >
                      Open OpenAI Usage Dashboard →
                    </a>
                    {stats.note && (
                      <div className="dashboard-note">
                        <small>{stats.note}</small>
                      </div>
                    )}
                  </div>
                </div>
              )}

              <div className="dashboard-footer">
                <small>Stats update every 5 seconds • Last updated: {new Date().toLocaleTimeString()}</small>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}

export default OpenAIStatsDashboard;
