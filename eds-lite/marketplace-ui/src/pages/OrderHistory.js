import React, { useState, useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import axios from 'axios';
import { useAuth } from '../context/AuthContext';

const OrderHistory = () => {
  const { user } = useAuth();
  const location = useLocation();
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState('');

  useEffect(() => {
    if (location.state?.message) {
      setMessage(location.state.message);
      // Clear the message after 5 seconds
      setTimeout(() => setMessage(''), 5000);
    }
    
    if (user) {
      fetchOrders();
    }
  }, [user, location.state]);

  const fetchOrders = async () => {
    try {
      const API_BASE_URL = process.env.REACT_APP_API_URL || 'https://api-gateway-lpnh.onrender.com';
      const response = await axios.get(`${API_BASE_URL}/api/orders/customer/${user.email}`);
      setOrders(response.data || []);
    } catch (error) {
      console.error('Error fetching orders:', error);
      setOrders([]);
    } finally {
      setLoading(false);
    }
  };

  const formatPrice = (price) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(price);
  };

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  if (!user) {
    return (
      <div className="container">
        <div style={{ textAlign: 'center', padding: '60px 20px' }}>
          <h2>Please Login</h2>
          <p>You need to be logged in to view your order history.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="container">
      <h1>Order History</h1>
      
      {message && (
        <div className="success" style={{ marginBottom: '20px' }}>
          {message}
        </div>
      )}

      {loading ? (
        <div className="loading">Loading orders...</div>
      ) : orders.length === 0 ? (
        <div style={{ 
          textAlign: 'center', 
          padding: '60px 20px',
          background: 'white',
          borderRadius: '8px',
          marginTop: '20px'
        }}>
          <h3>No Orders Yet</h3>
          <p style={{ color: '#666', marginBottom: '20px' }}>
            {location.state?.orderId ? 
              `Your order #${location.state.orderId} has been placed successfully!` :
              "You haven't placed any orders yet."
            }
          </p>
          <a href="/products" className="btn btn-primary">
            Start Shopping
          </a>
        </div>
      ) : (
        <div style={{ marginTop: '20px' }}>
          {orders.map(order => (
            <div key={order.id} className="card" style={{ marginBottom: '20px', padding: '20px' }}>
              <div style={{ 
                display: 'flex', 
                justifyContent: 'space-between', 
                alignItems: 'center',
                marginBottom: '15px',
                paddingBottom: '15px',
                borderBottom: '1px solid #eee'
              }}>
                <div>
                  <h3>Order #{order.id}</h3>
                  <p style={{ color: '#666', margin: '5px 0' }}>
                    Placed on {formatDate(order.createdAt)}
                  </p>
                </div>
                <div style={{ textAlign: 'right' }}>
                  <div style={{ fontSize: '18px', fontWeight: 'bold' }}>
                    {formatPrice(order.total)}
                  </div>
                  <div style={{ 
                    color: order.status === 'CREATED' ? '#28a745' : '#6c757d',
                    fontWeight: '500'
                  }}>
                    {order.status}
                  </div>
                </div>
              </div>

              <div>
                <h4 style={{ marginBottom: '10px' }}>Items:</h4>
                {order.items.map((item, index) => (
                  <div key={index} style={{ 
                    display: 'flex', 
                    justifyContent: 'space-between',
                    padding: '10px 0',
                    borderBottom: index < order.items.length - 1 ? '1px solid #f0f0f0' : 'none'
                  }}>
                    <div>
                      <span style={{ fontWeight: '500' }}>Product ID: {item.productId}</span>
                      <span style={{ color: '#666', marginLeft: '10px' }}>
                        Qty: {item.quantity}
                      </span>
                    </div>
                    <div>
                      {formatPrice(item.price * item.quantity)}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default OrderHistory;