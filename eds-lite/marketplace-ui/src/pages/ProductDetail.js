import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import axios from 'axios';
import { useCart } from '../context/CartContext';
import { getProductImage, getValidProductImages, handleImageError } from '../utils/imageUtils';

const ProductDetail = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const { addToCart } = useCart();
  const [product, setProduct] = useState(null);
  const [loading, setLoading] = useState(true);
  const [quantity, setQuantity] = useState(1);
  const [selectedImage, setSelectedImage] = useState(0);

  useEffect(() => {
    fetchProduct();
  }, [id]);

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
          
          {product.rating && (
            <div style={{ 
              display: 'flex', 
              alignItems: 'center', 
              gap: '10px', 
              marginBottom: '15px' 
            }}>
              <span style={{ fontSize: '18px' }}>{renderStars(product.rating)}</span>
              <span>({product.reviewCount || 0} reviews)</span>
            </div>
          )}

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
    </div>
  );
};

export default ProductDetail;