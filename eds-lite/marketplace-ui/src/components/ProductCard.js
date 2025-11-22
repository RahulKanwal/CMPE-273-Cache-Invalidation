import React from 'react';
import { useNavigate } from 'react-router-dom';
import { useCart } from '../context/CartContext';

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
      <img 
        src={product.images?.[0] || 'https://via.placeholder.com/300x200'} 
        alt={product.name}
        className="product-image"
      />
      <div className="product-info">
        <h3 className="product-name">{product.name}</h3>
        <div className="product-price">{formatPrice(product.price)}</div>
        
        {product.rating && (
          <div className="product-rating">
            <span>{renderStars(product.rating)}</span>
            <span>({product.reviewCount || 0})</span>
          </div>
        )}
        
        <div className="product-category">{product.category}</div>
        
        <button 
          className="btn btn-primary"
          onClick={handleAddToCart}
          style={{ marginTop: '10px', width: '100%' }}
        >
          Add to Cart
        </button>
      </div>
    </div>
  );
};

export default ProductCard;