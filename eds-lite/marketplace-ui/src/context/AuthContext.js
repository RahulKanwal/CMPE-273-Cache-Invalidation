import React, { createContext, useContext, useState, useEffect } from 'react';
import axios from 'axios';

const AuthContext = createContext();

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const token = localStorage.getItem('token');
    if (token) {
      validateToken(token);
    } else {
      setLoading(false);
    }
  }, []);

  const validateToken = async (token) => {
    try {
      const response = await axios.post('/api/auth/validate', {}, {
        headers: { Authorization: `Bearer ${token}` }
      });
      setUser(response.data);
      axios.defaults.headers.common['Authorization'] = `Bearer ${token}`;
    } catch (error) {
      localStorage.removeItem('token');
      delete axios.defaults.headers.common['Authorization'];
    } finally {
      setLoading(false);
    }
  };

  const login = async (email, password) => {
    try {
      const response = await axios.post('/api/auth/login', { email, password });
      const { token } = response.data;
      
      localStorage.setItem('token', token);
      axios.defaults.headers.common['Authorization'] = `Bearer ${token}`;
      setUser(response.data);
      
      return { success: true };
    } catch (error) {
      const errorMessage = error.response?.data?.message || 
                          error.response?.data?.error || 
                          (typeof error.response?.data === 'string' ? error.response.data : null) ||
                          error.message || 
                          'Login failed';
      return { 
        success: false, 
        error: errorMessage
      };
    }
  };

  const register = async (userData) => {
    try {
      const response = await axios.post('/api/auth/register', userData);
      const { token } = response.data;
      
      localStorage.setItem('token', token);
      axios.defaults.headers.common['Authorization'] = `Bearer ${token}`;
      setUser(response.data);
      
      return { success: true };
    } catch (error) {
      const errorMessage = error.response?.data?.message || 
                          error.response?.data?.error || 
                          (typeof error.response?.data === 'string' ? error.response.data : null) ||
                          error.message || 
                          'Registration failed';
      return { 
        success: false, 
        error: errorMessage
      };
    }
  };

  const logout = () => {
    localStorage.removeItem('token');
    delete axios.defaults.headers.common['Authorization'];
    setUser(null);
  };

  const value = {
    user,
    login,
    register,
    logout,
    loading
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};