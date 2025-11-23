import React from 'react';
import './CacheArchitecture.css';

const CacheArchitecture = ({ currentScenario, cacheEvents = [] }) => {
  const scenarios = {
    'none': {
      name: 'No Cache',
      components: ['Client', 'Catalog Service', 'MongoDB'],
      connections: [
        { from: 'Client', to: 'Catalog Service', type: 'request' },
        { from: 'Catalog Service', to: 'MongoDB', type: 'query' }
      ]
    },
    'ttl': {
      name: 'TTL-Only Cache',
      components: ['Client', 'Catalog Service', 'Redis Cache', 'MongoDB'],
      connections: [
        { from: 'Client', to: 'Catalog Service', type: 'request' },
        { from: 'Catalog Service', to: 'Redis Cache', type: 'cache-check' },
        { from: 'Catalog Service', to: 'MongoDB', type: 'query' }
      ]
    },
    'ttl_invalidate': {
      name: 'TTL + Kafka Invalidation',
      components: ['Client', 'Catalog Service', 'Redis Cache', 'MongoDB', 'Kafka'],
      connections: [
        { from: 'Client', to: 'Catalog Service', type: 'request' },
        { from: 'Catalog Service', to: 'Redis Cache', type: 'cache-check' },
        { from: 'Catalog Service', to: 'MongoDB', type: 'query' },
        { from: 'Catalog Service', to: 'Kafka', type: 'invalidation' }
      ]
    }
  };

  const scenario = scenarios[currentScenario];
  const recentEvents = cacheEvents.slice(-5); // Show last 5 events

  return (
    <div className="cache-architecture">
      <h3>Cache Architecture: {scenario.name}</h3>
      
      <div className="architecture-diagram">
        <div className="components">
          {scenario.components.map((component, index) => (
            <div 
              key={component} 
              className={`component ${component.toLowerCase().replace(' ', '-')}`}
              style={{ 
                animationDelay: `${index * 0.2}s`,
                '--component-index': index 
              }}
            >
              <div className="component-icon">
                {getComponentIcon(component)}
              </div>
              <div className="component-name">{component}</div>
              {component === 'Redis Cache' && (
                <div className="cache-status">
                  {recentEvents.length > 0 && (
                    <div className="cache-activity">
                      {recentEvents.map((event, i) => (
                        <div key={i} className={`activity-dot ${event.type}`}></div>
                      ))}
                    </div>
                  )}
                </div>
              )}
            </div>
          ))}
        </div>

        <div className="connections">
          {scenario.connections.map((connection, index) => (
            <div 
              key={index}
              className={`connection ${connection.type}`}
              style={{ animationDelay: `${(index + scenario.components.length) * 0.2}s` }}
            >
              <div className="connection-line"></div>
              <div className="connection-label">{getConnectionLabel(connection.type)}</div>
            </div>
          ))}
        </div>
      </div>

      <div className="data-flow">
        <h4>Data Flow</h4>
        <div className="flow-steps">
          {getDataFlowSteps(currentScenario).map((step, index) => (
            <div key={index} className="flow-step">
              <div className="step-number">{index + 1}</div>
              <div className="step-description">{step}</div>
            </div>
          ))}
        </div>
      </div>

      {recentEvents.length > 0 && (
        <div className="recent-events">
          <h4>Recent Cache Events</h4>
          <div className="events-list">
            {recentEvents.map((event, index) => (
              <div key={index} className={`event ${event.type}`}>
                <div className="event-icon">{getEventIcon(event.type)}</div>
                <div className="event-text">{event.description}</div>
                <div className="event-time">{event.timestamp}</div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

const getComponentIcon = (component) => {
  const icons = {
    'Client': '💻',
    'Catalog Service': '⚙️',
    'Redis Cache': '🗄️',
    'MongoDB': '🍃',
    'Kafka': '📡'
  };
  return icons[component] || '📦';
};

const getConnectionLabel = (type) => {
  const labels = {
    'request': 'HTTP Request',
    'cache-check': 'Cache Lookup',
    'query': 'DB Query',
    'invalidation': 'Cache Invalidation'
  };
  return labels[type] || type;
};

const getDataFlowSteps = (scenario) => {
  const flows = {
    'none': [
      'Client sends request to Catalog Service',
      'Service queries MongoDB directly',
      'Data returned to client'
    ],
    'ttl': [
      'Client sends request to Catalog Service',
      'Service checks Redis cache first',
      'If cache miss, query MongoDB',
      'Store result in cache with TTL',
      'Return data to client'
    ],
    'ttl_invalidate': [
      'Client sends request to Catalog Service',
      'Service checks Redis cache first',
      'If cache miss, query MongoDB',
      'Store result in cache with TTL',
      'On data update, publish invalidation event to Kafka',
      'All service instances receive event and clear cache',
      'Return fresh data to client'
    ]
  };
  return flows[scenario] || [];
};

const getEventIcon = (type) => {
  const icons = {
    'hit': '🎯',
    'miss': '❌',
    'invalidation': '🔄',
    'update': '📝'
  };
  return icons[type] || '📋';
};

export default CacheArchitecture;