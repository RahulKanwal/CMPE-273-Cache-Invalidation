import React from 'react';
import './PerformanceChart.css';

const PerformanceChart = ({ testResults, currentScenario }) => {
  if (!testResults || testResults.length === 0) {
    return (
      <div className="performance-chart">
        <h3>Performance Chart</h3>
        <div className="no-data">Run a test to see performance metrics</div>
      </div>
    );
  }

  const maxLatency = Math.max(...testResults.map(r => r.latency));
  const scenarios = {
    'none': { name: 'No Cache', color: '#ff6b6b' },
    'ttl': { name: 'TTL-Only Cache', color: '#ffd93d' },
    'ttl_invalidate': { name: 'TTL + Kafka Invalidation', color: '#6bcf7f' }
  };

  return (
    <div className="performance-chart">
      <h3>Performance Analysis - {scenarios[currentScenario]?.name}</h3>
      
      <div className="chart-container">
        <div className="chart-bars">
          {testResults.map((result, index) => (
            <div key={index} className="bar-container">
              <div className="bar-label">{result.test}</div>
              <div className="bar-wrapper">
                <div 
                  className={`bar ${result.type}`}
                  style={{ 
                    height: `${(result.latency / maxLatency) * 100}%`,
                    backgroundColor: getBarColor(result.type)
                  }}
                >
                  <div className="bar-value">{result.latency}ms</div>
                </div>
              </div>
              <div className="bar-type">{getTypeLabel(result.type)}</div>
            </div>
          ))}
        </div>
        
        <div className="chart-axis">
          <div className="axis-label">Response Time (ms)</div>
          <div className="axis-ticks">
            {[0, Math.round(maxLatency * 0.25), Math.round(maxLatency * 0.5), Math.round(maxLatency * 0.75), maxLatency].map(tick => (
              <div key={tick} className="tick">{tick}</div>
            ))}
          </div>
        </div>
      </div>

      <div className="chart-insights">
        <h4>Performance Insights</h4>
        <div className="insights-grid">
          {generateInsights(testResults, currentScenario).map((insight, index) => (
            <div key={index} className={`insight ${insight.type}`}>
              <div className="insight-icon">{insight.icon}</div>
              <div className="insight-text">{insight.text}</div>
            </div>
          ))}
        </div>
      </div>

      <div className="legend">
        <div className="legend-item">
          <div className="legend-color hit"></div>
          <span>Cache Hit</span>
        </div>
        <div className="legend-item">
          <div className="legend-color miss"></div>
          <span>Cache Miss</span>
        </div>
        <div className="legend-item">
          <div className="legend-color update"></div>
          <span>Update</span>
        </div>
        <div className="legend-item">
          <div className="legend-color fresh"></div>
          <span>Fresh Data</span>
        </div>
        <div className="legend-item">
          <div className="legend-color stale"></div>
          <span>Stale Data</span>
        </div>
      </div>
    </div>
  );
};

const getBarColor = (type) => {
  const colors = {
    'hit': '#28a745',
    'miss': '#ffc107',
    'update': '#007bff',
    'fresh': '#28a745',
    'stale': '#dc3545'
  };
  return colors[type] || '#6c757d';
};

const getTypeLabel = (type) => {
  const labels = {
    'hit': '🎯 Hit',
    'miss': '❌ Miss',
    'update': '📝 Update',
    'fresh': '✅ Fresh',
    'stale': '⚠️ Stale'
  };
  return labels[type] || type;
};

const generateInsights = (results, scenario) => {
  const insights = [];
  
  if (results.length < 2) return insights;

  const firstRead = results.find(r => r.test === 'First Read');
  const secondRead = results.find(r => r.test === 'Second Read');
  const postUpdate = results.find(r => r.test === 'Post-Update Read');

  // Cache performance insight
  if (firstRead && secondRead) {
    const speedup = firstRead.latency - secondRead.latency;
    if (speedup > 0) {
      insights.push({
        type: 'success',
        icon: '⚡',
        text: `Cache improved response time by ${speedup}ms (${Math.round((speedup/firstRead.latency)*100)}% faster)`
      });
    } else if (scenario !== 'none') {
      insights.push({
        type: 'warning',
        icon: '⚠️',
        text: 'No significant cache performance improvement detected'
      });
    }
  }

  // Cache invalidation insight
  if (postUpdate) {
    if (postUpdate.type === 'fresh') {
      insights.push({
        type: 'success',
        icon: '✅',
        text: 'Cache invalidation working correctly - fresh data retrieved'
      });
    } else if (postUpdate.type === 'stale') {
      insights.push({
        type: 'error',
        icon: '❌',
        text: 'Cache invalidation issue - stale data detected'
      });
    }
  }

  // Scenario-specific insights
  if (scenario === 'none') {
    insights.push({
      type: 'info',
      icon: '📊',
      text: 'No caching - all requests hit the database directly'
    });
  } else if (scenario === 'ttl') {
    insights.push({
      type: 'warning',
      icon: '⏰',
      text: 'TTL-only cache may serve stale data until expiration'
    });
  } else if (scenario === 'ttl_invalidate') {
    insights.push({
      type: 'success',
      icon: '🚀',
      text: 'Kafka invalidation ensures data consistency across services'
    });
  }

  return insights;
};

export default PerformanceChart;