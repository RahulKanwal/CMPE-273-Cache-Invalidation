import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import { useCart } from '../context/CartContext';
import { useAuth } from '../context/AuthContext';

const Checkout = () => {
  const { items, getTotalPrice, clearCart } = useCart();
  const { user } = useAuth();
  const navigate = useNavigate();
  
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handlePlaceOrder = async () => {
    setLoading(true);
    setError('');

    try {
      const orderItems = items.map(item => ({
        productId: item.id,
        quantity: item.quantity,
        price: item.price
      }));

      const orderData = {
        customerId: user.email,
        items: orderItems
      };

      const response = await axios.post('/api/orders', orderData);
      
      if (response.data) {
        clearCart();
        navigate('/orders', { 
          state: { 
            message: 'Order placed successfully!', 
            orderId: response.data.id 
          } 
        });
      }
    } catch (error) {
      console.error('Error placing order:', error);
      setError('Failed to place order. Please try again.');
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

  if (items.length === 0) {
    return (
      <div className="container">
        <div style={{ textAlign: 'center', padding: '60px 20px' }}>
          <h2>No Items to Checkout</h2>
          <p>Your cart is empty.</p>
          <button onClick={() => navigate('/products')} className="btn btn-primary">
            Continue Shopping
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="container">
      <h1>Checkout</h1>
      
      <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '40px', marginTop: '20px' }}>
        {/* Order Details */}
        <div>
          <div className="card" style={{ padding: '20px', marginBottom: '20px' }}>
            <h3>Customer Information</h3>
            <p><strong>Name:</strong> {user.firstName} {user.lastName}</p>
            <p><strong>Email:</strong> {user.email}</p>
          </div>

          <div className="card" style={{ padding: '20px' }}>
            <h3>Order Items</h3>
            {items.map(item => (
              <div key={item.id} style={{ 
                display: 'flex', 
                justifyContent: 'space-between', 
                alignItems: 'center',
                padding: '15px 0',
                borderBottom: '1px solid #eee'
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '15px' }}>
                  <img 
                    src={item.images?.[0] || 'https://via.placeholder.com/60x60'} 
                    alt={item.name}
                    style={{ width: '60px', height: '60px', objectFit: 'cover', borderRadius: '6px' }}
                  />
                  <div>
                    <div style={{ fontWeight: '500' }}>{item.name}</div>
                    <div style={{ color: '#666', fontSize: '14px' }}>
                      {formatPrice(item.price)} × {item.quantity}
                    </div>
                  </div>
                </div>
                <div style={{ fontWeight: 'bold' }}>
                  {formatPrice(item.price * item.quantity)}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Order Summary */}
        <div>
          <div className="card" style={{ padding: '20px', position: 'sticky', top: '100px' }}>
            <h3 style={{ marginBottom: '20px' }}>Order Summary</h3>
            
            <div style={{ 
              display: 'flex', 
              justifyContent: 'space-between', 
              marginBottom: '10px',
              paddingBottom: '10px',
              borderBottom: '1px solid #eee'
            }}>
              <span>Subtotal ({items.reduce((sum, item) => sum + item.quantity, 0)} items)</span>
              <span>{formatPrice(getTotalPrice())}</span>
            </div>

            <div style={{ 
              display: 'flex', 
              justifyContent: 'space-between', 
              marginBottom: '10px',
              paddingBottom: '10px',
              borderBottom: '1px solid #eee'
            }}>
              <span>Shipping</span>
              <span>FREE</span>
            </div>

            <div style={{ 
              display: 'flex', 
              justifyContent: 'space-between', 
              marginBottom: '20px',
              fontSize: '18px',
              fontWeight: 'bold'
            }}>
              <span>Total</span>
              <span>{formatPrice(getTotalPrice())}</span>
            </div>

            {error && <div className="error">{error}</div>}

            <button 
              onClick={handlePlaceOrder}
              disabled={loading}
              className="btn btn-primary"
              style={{ width: '100%', marginBottom: '10px' }}
            >
              {loading ? 'Placing Order...' : 'Place Order'}
            </button>

            <button 
              onClick={() => navigate('/cart')} 
              className="btn btn-outline"
              style={{ width: '100%' }}
            >
              Back to Cart
            </button>

            <div style={{ 
              marginTop: '20px', 
              padding: '15px', 
              background: '#f8f9fa', 
              borderRadius: '6px',
              fontSize: '14px',
              color: '#666'
            }}>
              <strong>Note:</strong> This is a demo checkout. No actual payment will be processed.
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Checkout;