import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import axios from 'axios';
import ProductCard from '../components/ProductCard';
import API_CONFIG from '../config/api';

const Home = () => {
  const [featuredProducts, setFeaturedProducts] = useState([]);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchHomeData();
  }, []);

  const fetchHomeData = async () => {
    try {
      const [featuredRes, categoriesRes] = await Promise.all([
        axios.get(`${API_CONFIG.API_GATEWAY_URL}/api/catalog/products/featured`),
        axios.get(`${API_CONFIG.API_GATEWAY_URL}/api/catalog/products/categories`)
      ]);
      
      setFeaturedProducts(featuredRes.data || []);
      setCategories(categoriesRes.data || []);
    } catch (error) {
      console.error('Error fetching home data:', error);
      // Set empty arrays on error to prevent map errors
      setFeaturedProducts([]);
      setCategories([]);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <div className="loading">Loading...</div>;
  }

  return (
    <div className="container">
      {/* Hero Section */}
      <section style={{ 
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        color: 'white',
        padding: '60px 40px',
        borderRadius: '12px',
        margin: '20px 0',
        textAlign: 'center'
      }}>
        <h1 style={{ fontSize: '3rem', marginBottom: '20px' }}>
          Welcome to EDS Marketplace
        </h1>
        <p style={{ fontSize: '1.2rem', marginBottom: '30px' }}>
          Discover amazing products with lightning-fast performance powered by distributed caching
        </p>
        <Link to="/products" className="btn btn-primary" style={{ fontSize: '1.1rem', padding: '15px 30px' }}>
          Shop Now
        </Link>
      </section>

      {/* Categories */}
      <section style={{ margin: '40px 0' }}>
        <h2 style={{ marginBottom: '20px' }}>Shop by Category</h2>
        <div className="grid grid-4">
          {categories.map(category => (
            <Link 
              key={category}
              to={`/products?category=${encodeURIComponent(category)}`}
              className="card"
              style={{ 
                padding: '30px', 
                textAlign: 'center', 
                textDecoration: 'none',
                color: 'inherit'
              }}
            >
              <div style={{ fontSize: '2rem', marginBottom: '10px' }}>
                {getCategoryIcon(category)}
              </div>
              <h3>{category}</h3>
            </Link>
          ))}
        </div>
      </section>

      {/* Featured Products */}
      <section style={{ margin: '40px 0' }}>
        <h2 style={{ marginBottom: '20px' }}>Featured Products</h2>
        <div className="product-grid">
          {featuredProducts.map(product => (
            <ProductCard key={product.id} product={product} />
          ))}
        </div>
        {featuredProducts.length === 0 && (
          <p style={{ textAlign: 'center', color: '#666' }}>
            No featured products available
          </p>
        )}
      </section>

      {/* Features */}
      <section style={{ margin: '40px 0' }}>
        <h2 style={{ marginBottom: '20px', textAlign: 'center' }}>Why Choose EDS Marketplace?</h2>
        <div className="grid grid-3">
          <div className="card" style={{ padding: '30px', textAlign: 'center' }}>
            <div style={{ marginBottom: '15px' }}>
              <img src="https://img.icons8.com/ios-filled/50/667eea/lightning-bolt.png" alt="Fast" style={{ width: '50px', height: '50px' }} />
            </div>
            <h3>Lightning Fast</h3>
            <p>Powered by Redis caching and Kafka for real-time updates</p>
          </div>
          <div className="card" style={{ padding: '30px', textAlign: 'center' }}>
            <div style={{ marginBottom: '15px' }}>
              <img src="https://img.icons8.com/ios-filled/50/667eea/lock.png" alt="Secure" style={{ width: '50px', height: '50px' }} />
            </div>
            <h3>Secure</h3>
            <p>JWT-based authentication and secure payment processing</p>
          </div>
          <div className="card" style={{ padding: '30px', textAlign: 'center' }}>
            <div style={{ marginBottom: '15px' }}>
              <img src="https://img.icons8.com/ios-filled/50/667eea/smartphone-tablet.png" alt="Responsive" style={{ width: '50px', height: '50px' }} />
            </div>
            <h3>Responsive</h3>
            <p>Perfect experience on desktop, tablet, and mobile devices</p>
          </div>
        </div>
      </section>
    </div>
  );
};

const getCategoryIcon = (category) => {
  const icons = {
    'Electronics': 'https://img.icons8.com/ios-filled/50/667eea/laptop.png',
    'Clothing': 'https://img.icons8.com/ios-filled/50/667eea/clothes.png',
    'Home & Garden': 'https://img.icons8.com/ios-filled/50/667eea/home.png',
    'Books': 'https://img.icons8.com/ios-filled/50/667eea/book.png',
    'Sports & Outdoors': 'https://img.icons8.com/ios-filled/50/667eea/football2.png'
  };
  const iconUrl = icons[category] || 'https://img.icons8.com/ios-filled/50/667eea/shopping-bag.png';
  return <img src={iconUrl} alt={category} style={{ width: '50px', height: '50px' }} />;
};

export default Home;