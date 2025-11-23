import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import axios from 'axios';
import { useCart } from '../context/CartContext';
import { useAuth } from '../context/AuthContext';
import { getProductImage, getValidProductImages, handleImageError } from '../utils/imageUtils';

const ProductDetail = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const { addToCart } = useCart();
  const { user } = useAuth();
  const [product, setProduct] = useState(null);
  const [loading, setLoading] = useState(true);
  const [quantity, setQuantity] = useState(1);
  const [selectedImage, setSelectedImage] = useState(0);
  const [showRatingForm, setShowRatingForm] = useState(false);
  const [hasUserRated, setHasUserRated] = useState(false);
  const [selectedRating, setSelectedRating] = useState(0);
  const [hoverRating, setHoverRating] = useState(0);

  useEffect(() => {
    fetchProduct();
    if (user) {
      checkUserRated();
    }
  }, [id, user]);

  const fetchProduct = async () => {
    try {
      const response = await axios.get(`/api/catalog/products/${id}`);
      setProduct(response.data);
    } catch (error) {
      console.error('Error fetching product:', error);
    } finally {
      setLoading(false);
    }
  };

  const checkUserRated = async () => {
    try {
      const response = await axios.get(`/api/catalog/products/${id}/reviews/user-reviewed`, {
        headers: {
          'X-User-Id': user.email
        }
      });
      setHasUserRated(response.data);
    } catch (error) {
      console.error('Error checking user rating status:', error);
    }
  };

  const validImages = product ? getValidProductImages(product) : [];

  const handleAddToCart = () => {
    addToCart(product, quantity);
    // Show success message or redirect to cart
    navigate('/cart');
  };

  const formatPrice = (price) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(price);
  };

  const renderStars = (rating) => {
    const stars = [];
    const fullStars = Math.floor(rating);
    
    for (let i = 0; i < 5; i++) {
      stars.push(i < fullStars ? '⭐' : '☆');
    }
    
    return stars.join('');
  };

  const renderInteractiveStars = () => {
    const stars = [];
    
    for (let i = 1; i <= 5; i++) {
      const isActive = i <= (hoverRating || selectedRating);
      stars.push(
        <span
          key={i}
          onClick={() => setSelectedRating(i)}
          onMouseEnter={() => setHoverRating(i)}
          onMouseLeave={() => setHoverRating(0)}
          style={{
            cursor: 'pointer',
            fontSize: '28px',
            color: isActive ? '#ffc107' : '#e9ecef',
            marginRight: '5px',
            transition: 'color 0.2s ease, transform 0.1s ease'
          }}
          onMouseDown={(e) => e.target.style.transform = 'scale(0.95)'}
          onMouseUp={(e) => e.target.style.transform = 'scale(1)'}
        >
          ★
        </span>
      );
    }
    
    return stars;
  };

  const handleSubmitRating = async () => {
    if (!user) {
      alert('Please log in to rate this product');
      return;
    }

    if (selectedRating === 0) {
      alert('Please select a rating');
      return;
    }

    try {
      await axios.post(`/api/catalog/products/${id}/reviews`, {
        rating: selectedRating,
        comment: '', // Empty comment for rating-only
        userName: `${user.firstName} ${user.lastName}`
      }, {
        headers: {
          'X-User-Id': user.email
        }
      });

      // Reset form and refresh data
      setSelectedRating(0);
      setHoverRating(0);
      setShowRatingForm(false);
      setHasUserRated(true);
      fetchProduct(); // Refresh to get updated rating
      
    } catch (error) {
      console.error('Error submitting rating:', error);
      alert('Failed to submit rating: ' + (error.response?.data || error.message));
    }
  };

  if (loading) {
    return <div className="loading">Loading product...</div>;
  }

  if (!product) {
    return (
      <div className="container">
        <div style={{ textAlign: 'center', padding: '60px 20px' }}>
          <h2>Product Not Found</h2>
          <p>The product you're looking for doesn't exist.</p>
          <button onClick={() => navigate('/products')} className="btn btn-primary">
            Back to Products
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="container">
      <button 
        onClick={() => navigate(-1)} 
        className="btn btn-outline"
        style={{ marginBottom: '20px' }}
      >
        ← Back
      </button>

      <div style={{ 
        display: 'grid', 
        gridTemplateColumns: '1fr 1fr', 
        gap: '40px',
        '@media (max-width: 768px)': {
          gridTemplateColumns: '1fr'
        }
      }}>
        {/* Product Images */}
        <div>
          <div style={{ marginBottom: '20px' }}>
            <img 
              src={validImages.length > 0 ? validImages[selectedImage] : getProductImage(null, 0, '500x400', product.category)} 
              alt={product.name}
              style={{ 
                width: '100%', 
                height: '400px', 
                objectFit: 'cover', 
                borderRadius: '8px' 
              }}
              onError={(e) => handleImageError(e, product.category, '500x400')}
            />
          </div>
          
          {validImages.length > 1 && (
            <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
              {validImages.map((image, index) => (
                <img
                  key={index}
                  src={image}
                  alt={`${product.name} ${index + 1}`}
                  onClick={() => setSelectedImage(index)}
                  style={{
                    width: '80px',
                    height: '80px',
                    objectFit: 'cover',
                    borderRadius: '6px',
                    cursor: 'pointer',
                    border: selectedImage === index ? '2px solid #007bff' : '2px solid transparent'
                  }}
                  onError={(e) => handleImageError(e, product.category, '80x80')}
                />
              ))}
            </div>
          )}
        </div>

        {/* Product Info */}
        <div>
          <div className="product-category" style={{ marginBottom: '10px' }}>
            {product.category}
          </div>
          
          <h1 style={{ marginBottom: '15px' }}>{product.name}</h1>
          
          <div style={{ 
            display: 'flex', 
            alignItems: 'center', 
            gap: '10px', 
            marginBottom: '15px' 
          }}>
            {product.rating && product.rating > 0 ? (
              <>
                <span style={{ fontSize: '18px' }}>{renderStars(product.rating)}</span>
                <span>({product.reviewCount || 0} review{product.reviewCount !== 1 ? 's' : ''})</span>
              </>
            ) : (
              <span style={{ color: '#999', fontSize: '16px' }}>No reviews yet</span>
            )}
          </div>

          <div style={{ 
            fontSize: '28px', 
            fontWeight: 'bold', 
            color: '#007bff', 
            marginBottom: '20px' 
          }}>
            {formatPrice(product.price)}
          </div>

          <div style={{ marginBottom: '20px' }}>
            <strong>Description:</strong>
            <p style={{ marginTop: '10px', lineHeight: '1.6' }}>
              {product.description}
            </p>
          </div>

          {product.tags && product.tags.length > 0 && (
            <div style={{ marginBottom: '20px' }}>
              <strong>Tags:</strong>
              <div style={{ marginTop: '10px' }}>
                {product.tags.map(tag => (
                  <span 
                    key={tag}
                    style={{
                      display: 'inline-block',
                      background: '#e9ecef',
                      color: '#495057',
                      padding: '4px 8px',
                      borderRadius: '4px',
                      fontSize: '12px',
                      margin: '2px 4px 2px 0'
                    }}
                  >
                    {tag}
                  </span>
                ))}
              </div>
            </div>
          )}

          <div style={{ marginBottom: '20px' }}>
            <strong>Stock:</strong> {product.stock} available
          </div>

          {/* Add to Cart Section */}
          <div style={{ 
            background: '#f8f9fa', 
            padding: '20px', 
            borderRadius: '8px',
            marginBottom: '20px'
          }}>
            <div style={{ marginBottom: '15px' }}>
              <label style={{ display: 'block', marginBottom: '5px', fontWeight: '500' }}>
                Quantity:
              </label>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <button 
                  onClick={() => setQuantity(Math.max(1, quantity - 1))}
                  className="quantity-btn"
                >
                  -
                </button>
                <span style={{ minWidth: '40px', textAlign: 'center', fontSize: '16px' }}>
                  {quantity}
                </span>
                <button 
                  onClick={() => setQuantity(Math.min(product.stock, quantity + 1))}
                  className="quantity-btn"
                >
                  +
                </button>
              </div>
            </div>

            <button 
              onClick={handleAddToCart}
              disabled={product.stock === 0}
              className="btn btn-primary"
              style={{ width: '100%', fontSize: '16px', padding: '15px' }}
            >
              {product.stock === 0 ? 'Out of Stock' : `Add ${quantity} to Cart`}
            </button>
          </div>

          {product.featured && (
            <div style={{ 
              background: '#fff3cd', 
              color: '#856404', 
              padding: '10px', 
              borderRadius: '6px',
              textAlign: 'center'
            }}>
              ⭐ Featured Product
            </div>
          )}
        </div>
      </div>

      {/* Rating Section */}
      <div style={{ marginTop: '40px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
          <h3>Rate this Product</h3>
          {user ? (
            !hasUserRated ? (
              <button 
                onClick={() => setShowRatingForm(!showRatingForm)}
                className="btn btn-primary"
              >
                Rate Product
              </button>
            ) : (
              <span style={{ color: '#28a745', fontSize: '14px' }}>
                ✓ You have rated this product
              </span>
            )
          ) : (
            <span style={{ color: '#666', fontSize: '14px' }}>
              Login to rate this product
            </span>
          )}
        </div>

        {/* Rating Form */}
        {showRatingForm && (
          <div className="card" style={{ padding: '20px', marginBottom: '20px' }}>
            <h4>Rate this Product</h4>
            <div style={{ marginBottom: '20px' }}>
              <label style={{ display: 'block', marginBottom: '10px', fontWeight: '500' }}>
                Select your rating:
              </label>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                {renderInteractiveStars()}
                <span style={{ marginLeft: '10px', fontSize: '16px', color: '#666' }}>
                  {selectedRating > 0 ? `${selectedRating} star${selectedRating !== 1 ? 's' : ''}` : 'Click to rate'}
                </span>
              </div>
            </div>
            
            <div style={{ display: 'flex', gap: '10px' }}>
              <button 
                onClick={handleSubmitRating}
                className="btn btn-primary"
                disabled={selectedRating === 0}
              >
                Submit Rating
              </button>
              <button 
                onClick={() => {
                  setShowRatingForm(false);
                  setSelectedRating(0);
                  setHoverRating(0);
                }}
                className="btn btn-secondary"
              >
                Cancel
              </button>
            </div>
          </div>
        )}

        {/* Current Rating Display */}
        <div className="card" style={{ padding: '20px' }}>
          <h4>Customer Ratings</h4>
          {product.rating && product.rating > 0 ? (
            <div style={{ textAlign: 'center', padding: '20px' }}>
              <div style={{ fontSize: '48px', marginBottom: '10px' }}>
                {product.rating.toFixed(1)}
              </div>
              <div style={{ fontSize: '18px', marginBottom: '10px' }}>
                {renderStars(product.rating)}
              </div>
              <div style={{ color: '#666' }}>
                Based on {product.reviewCount || 0} rating{product.reviewCount !== 1 ? 's' : ''}
              </div>
            </div>
          ) : (
            <div style={{ textAlign: 'center', padding: '40px', color: '#666' }}>
              <p>No ratings yet. Be the first to rate this product!</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default ProductDetail;