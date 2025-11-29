import axios from 'axios';

// API Configuration for different environments
const config = {
  development: {
    API_GATEWAY_URL: 'http://localhost:8080',
    USER_SERVICE_URL: 'http://localhost:8083',
    CATALOG_SERVICE_URL: 'http://localhost:8081',
    ORDER_SERVICE_URL: 'http://localhost:8082'
  },
  production: {
    API_GATEWAY_URL: process.env.REACT_APP_API_GATEWAY_URL || 'http://localhost:8080',
    USER_SERVICE_URL: process.env.REACT_APP_USER_SERVICE_URL || 'http://localhost:8083',
    CATALOG_SERVICE_URL: process.env.REACT_APP_CATALOG_SERVICE_URL || 'http://localhost:8081',
    ORDER_SERVICE_URL: process.env.REACT_APP_ORDER_SERVICE_URL || 'http://localhost:8082'
  }
};

const environment = process.env.NODE_ENV || 'development';
const API_CONFIG = config[environment];

// Configure axios defaults to use API Gateway
axios.defaults.baseURL = API_CONFIG.API_GATEWAY_URL;
axios.defaults.headers.common['Content-Type'] = 'application/json';

// Add request interceptor to include auth token
axios.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

export default API_CONFIG;