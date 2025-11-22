import React, { useState } from 'react';
import { getProductImage, handleImageError } from '../utils/imageUtils';

const ProductImage = ({ 
  product, 
  imageIndex = 0, 
  size = '300x200', 
  className = 'product-image',
  style = {},
  onClick,
  alt
}) => {
  const [imageError, setImageError] = useState(false);

  const handleError = (e) => {
    setImageError(true);
    handleImageError(e, product?.category, size);
  };

  const imageSrc = getProductImage(product?.images, imageIndex, size, product?.category);
  const imageAlt = alt || product?.name || 'Product image';

  return (
    <img
      src={imageSrc}
      alt={imageAlt}
      className={`${className} ${imageError ? 'image-error' : ''}`}
      style={style}
      onClick={onClick}
      onError={handleError}
      loading="lazy"
    />
  );
};

export default ProductImage;