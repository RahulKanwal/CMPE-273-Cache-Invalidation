import React from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useCart } from '../context/CartContext';
import { useAuth } from '../context/AuthContext';

const Cart = () => {
  const { items, updateQuantity, removeFromCart, getTotalPrice } = useCart();
  const { user } = useAuth();
  const navigate = useNavigate();

  const formatPrice = (price) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(price);
  };

  const handleCheckout = () => {
    if (!user) {
      navigate('/login', { state: { from: { pathname: '/checkout' } } });
    } else {
      navigate('/checkout');
    }
  };

  if (items.length === 0) {
    return (
      <div className="container">
        <div style={{ textAlign: 'center', padding: '60px 20px' }}>
          <h2>Your Cart is Empty</h2>
          <p style={{ margin: '20px 0', color: '#666' }}>
            Looks like you haven't added any items to your cart yet.
          </p>
          <Link to="/products" className="btn btn-primary">
            Continue Shopping
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="container">
      <h1>Shopping Cart</h1>
      
      <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '40px', marginTop: '20px' }}>
        {/* Cart Items */}
        <div>
          <div className="card">
            {items.map(item => (
              <div key={item.id} className="cart-item">
                <img 
                  src={item.images?.[0] || 'https://via.placeholder.com/80x80'} 
                  alt={item.name}
                  className="cart-item-image"
                />
                
                <div className="cart-item-info">
                  <div className="cart-item-name">{item.name}</div>
                  <div className="cart-item-price">{formatPrice(item.price)}</div>
                  <div style={{ fontSize: '14px', color: '#666', marginTop: '5px' }}>
                    {item.category}
                  </div>
                </div>

                <div className="quantity-controls">
                  <button 
                    className="quantity-btn"
                    onClick={() => updateQuantity(item.id, item.quantity - 1)}
                  >
                    -
                  </button>
                  <span style={{ minWidth: '40px', textAlign: 'center' }}>
                    {item.quantity}
                  </span>
                  <button 
                    className="quantity-btn"
                    onClick={() => updateQuantity(item.id, item.quantity + 1)}
                  >
                    +
                  </button>
                </div>

                <div style={{ fontWeight: 'bold', minWidth: '80px', textAlign: 'right' }}>
                  {formatPrice(item.price * item.quantity)}
                </div>

                <button 
                  className="remove-btn"
                  onClick={() => removeFromCart(item.id)}
                >
                  Remove
                </button>
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

            <button 
              onClick={handleCheckout}
              className="btn btn-primary"
              style={{ width: '100%', marginBottom: '10px' }}
            >
              {user ? 'Proceed to Checkout' : 'Login to Checkout'}
            </button>

            <Link 
              to="/products" 
              className="btn btn-outline"
              style={{ width: '100%', textAlign: 'center' }}
            >
              Continue Shopping
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Cart;