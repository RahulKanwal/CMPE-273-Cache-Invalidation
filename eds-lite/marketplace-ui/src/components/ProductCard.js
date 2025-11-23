import React from 'react';
import { useNavigate } from 'react-router-dom';
import { useCart } from '../context/CartContext';
import ProductImage from './ProductImage';

const ProductCard = ({ product }) => {
  const navigate = useNavigate();
  const { addToCart } = useCart();

  const handleCardClick = () => {
    navigate(`/products/${product.id}`);
  };

  const handleAddToCart = (e) => {
    e.stopPropagation();
    addToCart(product);
  };

  const formatPrice = (price) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(price);
  };

  const getRatingBadgeClass = (rating) => {
    if (rating >= 4.5) return 'rating-badge excellent';
    if (rating >= 3.5) return 'rating-badge good';
    if (rating >= 2.5) return 'rating-badge average';
    return 'rating-badge poor';
  };

  const renderStars = (rating) => {
    const stars = [];
    const fullStars = Math.floor(rating);
    const hasHalfStar = rating % 1 !== 0;

    for (let i = 0; i < fullStars; i++) {
      stars.push('⭐');
    }
    if (hasHalfStar) {
      stars.push('⭐');
    }
    
    return stars.join('');
  };

  return (
    <div className="product-card" onClick={handleCardClick}>
      <ProductImage 
        product={product}
        size="300x200"
        className="product-image"
      />
      <div className="product-info">
        <div className="product-details">
          <h3 className="product-name">{product.name}</h3>
          <div className="product-price">{formatPrice(product.price)}</div>
          
          <div className="product-rating">
            {product.rating && product.rating > 0 ? (
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <span className={getRatingBadgeClass(product.rating)}>
                  {product.rating.toFixed(1)}
                </span>
                <span style={{ fontSize: '14px', color: '#666' }}>
                  ({product.reviewCount || 0} rating{product.reviewCount !== 1 ? 's' : ''})
                </span>
              </div>
            ) : (
              <span style={{ color: '#999', fontSize: '14px' }}>No ratings yet</span>
            )}
          </div>
          
          <div className="product-category">{product.category}</div>
        </div>
        
        <button 
          className="btn btn-primary product-card-button"
          onClick={handleAddToCart}
        >
          Add to Cart
        </button>
      </div>
    </div>
  );
};

export default ProductCard;