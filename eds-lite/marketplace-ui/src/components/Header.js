import React from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { useCart } from '../context/CartContext';

const Header = () => {
  const { user, logout } = useAuth();
  const { getTotalItems } = useCart();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/');
  };

  return (
    <header className="header">
      <div className="container">
        <div className="header-content">
          <Link to="/" className="logo">
            EDS Marketplace
          </Link>
          
          <nav className="nav">
            <Link to="/" className="nav-link">Home</Link>
            <Link to="/products" className="nav-link">Products</Link>
            {user && user.role === 'ADMIN' && (
              <Link to="/admin" className="nav-link">Admin</Link>
            )}
          </nav>

          <div className="user-menu">
            <button 
              className="cart-icon"
              onClick={() => navigate('/cart')}
            >
              🛒
              {getTotalItems() > 0 && (
                <span className="cart-count">{getTotalItems()}</span>
              )}
            </button>

            {user ? (
              <>
                <span>Hello, {user.firstName}</span>
                <Link to="/orders" className="nav-link">Orders</Link>
                <button onClick={handleLogout} className="btn btn-outline">
                  Logout
                </button>
              </>
            ) : (
              <>
                <Link to="/login" className="btn btn-outline">Login</Link>
                <Link to="/register" className="btn btn-primary">Register</Link>
              </>
            )}
          </div>
        </div>
      </div>
    </header>
  );
};

export default Header;