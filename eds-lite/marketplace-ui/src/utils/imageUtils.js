// Utility functions for handling product images and placeholders

/**
 * Get the appropriate image URL with fallback to placeholder
 * @param {Array|string} images - Array of image URLs or single image URL
 * @param {number} index - Index of the image to get (default: 0)
 * @param {string} size - Size specification for placeholder (e.g., '300x200')
 * @param {string} category - Product category for category-specific placeholders
 * @returns {string} Image URL or placeholder URL
 */
export const getProductImage = (images, index = 0, size = '300x200', category = '') => {
  // Handle array of images
  if (Array.isArray(images) && images.length > 0 && images[index] && isValidImageUrl(images[index])) {
    return images[index];
  }
  
  // Handle single image string
  if (typeof images === 'string' && images.trim() && isValidImageUrl(images)) {
    return images;
  }
  
  // Return category-specific placeholder or generic placeholder
  return getPlaceholderImage(size, category);
};

/**
 * Get a placeholder image URL based on category and size
 * @param {string} size - Size specification (e.g., '300x200')
 * @param {string} category - Product category
 * @returns {string} Placeholder image URL
 */
export const getPlaceholderImage = (size = '300x200', category = '') => {
  const categoryConfig = {
    'Electronics': { icon: '📱', bg: 'e3f2fd', color: '1976d2' },
    'Clothing': { icon: '👕', bg: 'fce4ec', color: 'c2185b' },
    'Home & Garden': { icon: '🏠', bg: 'e8f5e8', color: '388e3c' },
    'Books': { icon: '📚', bg: 'fff3e0', color: 'f57c00' },
    'Sports & Outdoors': { icon: '⚽', bg: 'f3e5f5', color: '7b1fa2' },
    'Test': { icon: '🧪', bg: 'e0f2f1', color: '00695c' }
  };
  
  const config = categoryConfig[category] || { icon: '🛍️', bg: 'f8f9fa', color: '6c757d' };
  const text = category ? `${config.icon} ${category}` : `${config.icon} Product`;
  
  // Use category-specific colors for better visual distinction
  return `https://via.placeholder.com/${size}/${config.bg}/${config.color}?text=${encodeURIComponent(text)}`;
};

/**
 * Check if an image URL is valid (basic validation)
 * @param {string} url - Image URL to validate
 * @returns {boolean} True if URL appears valid
 */
export const isValidImageUrl = (url) => {
  if (!url || typeof url !== 'string') return false;
  
  try {
    const urlObj = new URL(url);
    // Accept any valid HTTP/HTTPS URL - let the browser handle if it's actually an image
    return urlObj.protocol === 'http:' || urlObj.protocol === 'https:';
  } catch {
    return false;
  }
};

/**
 * Get all valid images from a product, filtering out invalid URLs
 * @param {Object} product - Product object
 * @returns {Array} Array of valid image URLs
 */
export const getValidProductImages = (product) => {
  if (!product.images || !Array.isArray(product.images)) {
    return [];
  }
  
  return product.images.filter(isValidImageUrl);
};

/**
 * Handle image load error by setting a fallback placeholder
 * @param {Event} event - Image error event
 * @param {string} category - Product category for fallback
 * @param {string} size - Size for fallback placeholder
 */
export const handleImageError = (event, category = '', size = '300x200') => {
  event.target.src = getPlaceholderImage(size, category);
  event.target.onerror = null; // Prevent infinite loop
};