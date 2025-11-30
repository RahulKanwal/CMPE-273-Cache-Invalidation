import React, { useState, useEffect, useRef } from 'react';
import CacheArchitecture from '../components/CacheArchitecture';
import PerformanceChart from '../components/PerformanceChart';
import './CacheDemo.css';

const CacheDemo = () => {
  const [currentScenario, setCurrentScenario] = useState('ttl_invalidate');
  const [isRunning, setIsRunning] = useState(false);
  const [testResults, setTestResults] = useState([]);
  const [cacheStatus, setCacheStatus] = useState({
    hits: 0,
    misses: 0,
    invalidations: 0,
    currentData: null,
    lastUpdate: null
  });
  const [logs, setLogs] = useState([]);
  const [metrics, setMetrics] = useState({
    avgLatency: 0,
    cacheHitRate: 0,
    staleDataDetected: false
  });
  const [cacheEvents, setCacheEvents] = useState([]);

  const logRef = useRef(null);
  const [testProduct, setTestProduct] = useState(null);

  const scenarios = {
    'none': {
      name: 'No Cache',
      description: 'All requests go directly to database',
      color: '#ff6b6b',
      expected: 'High latency, no cache benefits'
    },
    'ttl': {
      name: 'TTL-Only Cache',
      description: 'Cache with TTL, no invalidation',
      color: '#ffd93d',
      expected: 'Low latency, possible stale data'
    },
    'ttl_invalidate': {
      name: 'TTL + Kafka Invalidation',
      description: 'Cache with Kafka-based invalidation',
      color: '#6bcf7f',
      expected: 'Low latency, fresh data guaranteed'
    }
  };

  const addLog = (message, type = 'info') => {
    const timestamp = new Date().toLocaleTimeString();
    const newLog = { timestamp, message, type, id: Date.now() };
    setLogs(prev => [...prev.slice(-19), newLog]); // Keep last 20 logs
  };

  const addCacheEvent = (type, description) => {
    const timestamp = new Date().toLocaleTimeString();
    const newEvent = { type, description, timestamp, id: Date.now() };
    setCacheEvents(prev => [...prev.slice(-9), newEvent]); // Keep last 10 events
  };

  const updateCacheStatus = (type, data = null) => {
    setCacheStatus(prev => ({
      ...prev,
      [type]: prev[type] + 1,
      currentData: data || prev.currentData,
      lastUpdate: new Date().toLocaleTimeString()
    }));
  };

  // Simulate API call with timing
  const makeApiCall = async (endpoint, method = 'GET', body = null) => {
    const startTime = performance.now();
    
    try {
      const API_BASE_URL = process.env.REACT_APP_API_URL || 'https://api-gateway-lpnh.onrender.com';
      const options = {
        method,
        headers: { 'Content-Type': 'application/json' }
      };
      
      if (body) {
        options.body = JSON.stringify(body);
      }

      const response = await fetch(`${API_BASE_URL}/api/catalog${endpoint}`, options);
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      const data = await response.json();
      const latency = Math.round(performance.now() - startTime);
      
      return { data, latency, success: true };
    } catch (error) {
      const latency = Math.round(performance.now() - startTime);
      return { error: error.message, latency, success: false };
    }
  };

  // Fetch a test product on component mount
  useEffect(() => {
    const fetchTestProduct = async () => {
      try {
        const API_BASE_URL = process.env.REACT_APP_API_URL || 'https://api-gateway-lpnh.onrender.com';
        const response = await fetch(`${API_BASE_URL}/api/catalog/products?size=1`);
        const data = await response.json();
        if (data.products && data.products.length > 0) {
          setTestProduct(data.products[0]);
        }
      } catch (error) {
        console.error('Failed to fetch test product:', error);
      }
    };
    fetchTestProduct();
  }, []);

  // Test cache behavior
  const runCacheTest = async () => {
    if (isRunning) return;
    
    if (!testProduct) {
      addLog('❌ No test product available. Please ensure products exist in the catalog.', 'error');
      return;
    }
    
    setIsRunning(true);
    setTestResults([]);
    setLogs([]);
    setCacheStatus({ hits: 0, misses: 0, invalidations: 0, currentData: null, lastUpdate: null });
    setMetrics({ avgLatency: 0, cacheHitRate: 0, staleDataDetected: false });
    
    addLog(`🚀 Starting cache test for scenario: ${scenarios[currentScenario].name}`, 'info');
    addLog(`📦 Using test product: ${testProduct.name} (ID: ${testProduct.id})`, 'info');
    
    try {
      // Test 1: First read (cache miss expected)
      addLog('📖 Test 1: First read (cache miss expected)', 'test');
      const result1 = await makeApiCall(`/products/${testProduct.id}`);
      
      if (result1.success) {
        updateCacheStatus('misses', result1.data);
        addCacheEvent('miss', 'First read - cache miss');
        addLog(`✅ First read: ${result1.latency}ms - Price: $${result1.data.price}`, 'success');
        setTestResults(prev => [...prev, { 
          test: 'First Read', 
          latency: result1.latency, 
          type: 'miss',
          data: result1.data 
        }]);
      } else {
        addLog(`❌ First read failed: ${result1.error}`, 'error');
        setIsRunning(false);
        return;
      }

      await new Promise(resolve => setTimeout(resolve, 1000));

      // Test 2: Second read (cache hit expected for cached scenarios)
      addLog('📖 Test 2: Second read (cache hit expected)', 'test');
      const result2 = await makeApiCall(`/products/${testProduct.id}`);
      
      if (result2.success) {
        const isCacheHit = result2.latency < result1.latency * 0.8; // Assume cache hit if significantly faster
        updateCacheStatus(isCacheHit ? 'hits' : 'misses', result2.data);
        addCacheEvent(isCacheHit ? 'hit' : 'miss', `Second read - cache ${isCacheHit ? 'hit' : 'miss'}`);
        
        const hitStatus = isCacheHit ? '🎯 Cache HIT' : '📀 Cache MISS';
        addLog(`✅ Second read: ${result2.latency}ms - ${hitStatus}`, isCacheHit ? 'success' : 'warning');
        
        setTestResults(prev => [...prev, { 
          test: 'Second Read', 
          latency: result2.latency, 
          type: isCacheHit ? 'hit' : 'miss',
          data: result2.data 
        }]);
      }

      await new Promise(resolve => setTimeout(resolve, 1000));

      // Test 3: Update product
      const newPrice = (parseFloat(result1.data.price) + 10).toFixed(2);
      const newStock = result1.data.stock + 5;
      
      addLog(`📝 Test 3: Updating product (Price: $${newPrice}, Stock: ${newStock})`, 'test');
      const updateResult = await makeApiCall(`/products/${testProduct.id}`, 'POST', {
        price: newPrice,
        stock: newStock
      });
      
      if (updateResult.success) {
        addLog(`✅ Update successful: Version ${result1.data.version} → ${updateResult.data.version}`, 'success');
        addCacheEvent('update', `Product updated - price changed to $${newPrice}`);
        
        if (currentScenario === 'ttl_invalidate') {
          updateCacheStatus('invalidations');
          addCacheEvent('invalidation', 'Kafka invalidation event sent');
          addLog('🔄 Kafka invalidation triggered', 'info');
        }
        
        setTestResults(prev => [...prev, { 
          test: 'Update', 
          latency: updateResult.latency, 
          type: 'update',
          data: updateResult.data 
        }]);
      }

      // Wait for invalidation to propagate
      const waitTime = currentScenario === 'ttl_invalidate' ? 3000 : 1000;
      addLog(`⏳ Waiting ${waitTime/1000}s for cache invalidation...`, 'info');
      await new Promise(resolve => setTimeout(resolve, waitTime));

      // Test 4: Read after update
      addLog('📖 Test 4: Read after update (checking for fresh data)', 'test');
      const result4 = await makeApiCall(`/products/${testProduct.id}`);
      
      if (result4.success) {
        const isStale = result4.data.version === result1.data.version;
        const isFresh = result4.data.price === newPrice && result4.data.version === updateResult.data.version;
        
        if (isFresh) {
          addLog(`✅ Fresh data retrieved: $${result4.data.price} (v${result4.data.version})`, 'success');
        } else if (isStale) {
          addLog(`⚠️ STALE DATA detected: Still showing v${result4.data.version}`, 'warning');
          setMetrics(prev => ({ ...prev, staleDataDetected: true }));
        }
        
        updateCacheStatus(result4.latency < result1.latency * 0.8 ? 'hits' : 'misses', result4.data);
        
        setTestResults(prev => [...prev, { 
          test: 'Post-Update Read', 
          latency: result4.latency, 
          type: isFresh ? 'fresh' : (isStale ? 'stale' : 'miss'),
          data: result4.data 
        }]);
      }

      // Calculate final metrics
      const allLatencies = [result1.latency, result2.latency, result4.latency];
      const avgLatency = Math.round(allLatencies.reduce((a, b) => a + b, 0) / allLatencies.length);
      const hitRate = Math.round((cacheStatus.hits / (cacheStatus.hits + cacheStatus.misses)) * 100) || 0;
      
      setMetrics({
        avgLatency,
        cacheHitRate: hitRate,
        staleDataDetected: result4.data?.version === result1.data?.version
      });

      addLog('🎉 Cache test completed!', 'success');
      
    } catch (error) {
      addLog(`❌ Test failed: ${error.message}`, 'error');
    } finally {
      setIsRunning(false);
    }
  };

  // Auto-scroll logs
  useEffect(() => {
    if (logRef.current) {
      logRef.current.scrollTop = logRef.current.scrollHeight;
    }
  }, [logs]);

  return (
    <div className="cache-demo">
      <div className="demo-header">
        <h1>🚀 EDS Cache Invalidation Demo</h1>
        <p>Interactive demonstration of distributed cache invalidation across microservices</p>
      </div>

      <div className="demo-content">
        {/* Scenario Selection */}
        <div className="scenario-selector">
          <h2>Cache Scenarios</h2>
          <div className="scenarios">
            {Object.entries(scenarios).map(([key, scenario]) => (
              <div 
                key={key}
                className={`scenario-card ${currentScenario === key ? 'active' : ''}`}
                onClick={() => setCurrentScenario(key)}
                style={{ borderColor: scenario.color }}
              >
                <div className="scenario-header">
                  <div 
                    className="scenario-indicator"
                    style={{ backgroundColor: scenario.color }}
                  ></div>
                  <h3>{scenario.name}</h3>
                </div>
                <p className="scenario-description">{scenario.description}</p>
                <p className="scenario-expected">Expected: {scenario.expected}</p>
              </div>
            ))}
          </div>
        </div>

        {/* Cache Architecture Visualization */}
        <CacheArchitecture 
          currentScenario={currentScenario} 
          cacheEvents={cacheEvents}
        />

        {/* Control Panel */}
        <div className="control-panel">
          <button 
            className={`test-button ${isRunning ? 'running' : ''}`}
            onClick={runCacheTest}
            disabled={isRunning || !testProduct}
          >
            {isRunning ? '🔄 Running Test...' : !testProduct ? '⏳ Loading...' : '▶️ Run Cache Test'}
          </button>
          
          <div className="current-scenario">
            <strong>Current Scenario:</strong> {scenarios[currentScenario].name}
            {testProduct && <div style={{ fontSize: '12px', marginTop: '5px', color: '#666' }}>
              Test Product: {testProduct.name}
            </div>}
          </div>
        </div>

        {/* Real-time Metrics */}
        <div className="metrics-dashboard">
          <div className="metric-card">
            <div className="metric-value">{cacheStatus.hits}</div>
            <div className="metric-label">Cache Hits</div>
          </div>
          <div className="metric-card">
            <div className="metric-value">{cacheStatus.misses}</div>
            <div className="metric-label">Cache Misses</div>
          </div>
          <div className="metric-card">
            <div className="metric-value">{cacheStatus.invalidations}</div>
            <div className="metric-label">Invalidations</div>
          </div>
          <div className="metric-card">
            <div className="metric-value">{metrics.avgLatency}ms</div>
            <div className="metric-label">Avg Latency</div>
          </div>
          <div className="metric-card">
            <div className="metric-value">{metrics.cacheHitRate}%</div>
            <div className="metric-label">Hit Rate</div>
          </div>
        </div>

        {/* Performance Chart */}
        <PerformanceChart 
          testResults={testResults} 
          currentScenario={currentScenario}
        />

        {/* Test Results Visualization */}
        {testResults.length > 0 && (
          <div className="results-visualization">
            <h3>Test Results Timeline</h3>
            <div className="results-timeline">
              {testResults.map((result, index) => (
                <div key={index} className={`result-item ${result.type}`}>
                  <div className="result-header">
                    <span className="result-test">{result.test}</span>
                    <span className="result-latency">{result.latency}ms</span>
                  </div>
                  <div className="result-type">
                    {result.type === 'hit' && '🎯 Cache Hit'}
                    {result.type === 'miss' && '📀 Cache Miss'}
                    {result.type === 'update' && '📝 Update'}
                    {result.type === 'fresh' && '✅ Fresh Data'}
                    {result.type === 'stale' && '⚠️ Stale Data'}
                  </div>
                  {result.data && (
                    <div className="result-data">
                      Price: ${result.data.price} | Version: {result.data.version}
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Live Logs */}
        <div className="logs-section">
          <h3>Live Test Logs</h3>
          <div className="logs-container" ref={logRef}>
            {logs.length === 0 ? (
              <div className="no-logs">Click "Run Cache Test" to start testing...</div>
            ) : (
              logs.map(log => (
                <div key={log.id} className={`log-entry ${log.type}`}>
                  <span className="log-timestamp">{log.timestamp}</span>
                  <span className="log-message">{log.message}</span>
                </div>
              ))
            )}
          </div>
        </div>

        {/* Cache Status Indicator */}
        {cacheStatus.currentData && (
          <div className="cache-status">
            <h3>Current Cache State</h3>
            <div className="cache-data">
              <div className="data-item">
                <strong>Product:</strong> {cacheStatus.currentData.name}
              </div>
              <div className="data-item">
                <strong>Price:</strong> ${cacheStatus.currentData.price}
              </div>
              <div className="data-item">
                <strong>Stock:</strong> {cacheStatus.currentData.stock}
              </div>
              <div className="data-item">
                <strong>Version:</strong> {cacheStatus.currentData.version}
              </div>
              <div className="data-item">
                <strong>Last Updated:</strong> {cacheStatus.lastUpdate}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default CacheDemo;