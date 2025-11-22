import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import { useAuth } from '../context/AuthContext';
import { getProductImage, handleImageError } from '../utils/imageUtils';

const Admin = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [products, setProducts] = useState([]);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [editingProduct, setEditingProduct] = useState(null);
  const [showAddForm, setShowAddForm] = useState(false);
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    price: '',
    stock: '',
    category: '',
    tags: '',
    images: '',
    featured: false
  });

  useEffect(() => {
    if (!user || user.role !== 'ADMIN') {
      navigate('/');
      return;
    }
    fetchProducts();
    fetchCategories();
  }, [user, navigate]);

  const fetchProducts = async () => {
    try {
      const response = await axios.get('/api/catalog/products?size=50');
      setProducts(response.data.products || []);
    } catch (error) {
      console.error('Error fetching products:', error);
    } finally {
      setLoading(false);
    }
  };

  const fetchCategories = async () => {
    try {
      const response = await axios.get('/api/catalog/products/categories');
      setCategories(response.data);
    } catch (error) {
      console.error('Error fetching categories:', error);
    }
  };

  const handleEdit = (product) => {
    setEditingProduct(product.id);
    setFormData({
      name: product.name,
      description: product.description,
      price: product.price.toString(),
      stock: product.stock.toString(),
      category: product.category,
      tags: product.tags ? product.tags.join(', ') : '',
      images: product.images ? product.images.join(', ') : '',
      featured: product.featured || false
    });
  };

  const handleSave = async (productId) => {
    try {
      const imagesArray = formData.images ? formData.images.split(',').map(img => img.trim()).filter(img => img) : [];
      
      await axios.post(`/api/catalog/products/${productId}`, {
        name: formData.name,
        description: formData.description,
        price: parseFloat(formData.price),
        stock: parseInt(formData.stock),
        category: formData.category,
        images: imagesArray
      });
      
      setEditingProduct(null);
      resetForm();
      fetchProducts(); // Refresh the list
    } catch (error) {
      console.error('Error updating product:', error);
      alert('Failed to update product: ' + (error.response?.data || error.message));
    }
  };

  const resetForm = () => {
    setFormData({
      name: '',
      description: '',
      price: '',
      stock: '',
      category: '',
      tags: '',
      images: '',
      featured: false
    });
  };

  const handleCancel = () => {
    setEditingProduct(null);
    setShowAddForm(false);
    resetForm();
  };

  const handleAdd = async () => {
    try {
      const tagsArray = formData.tags ? formData.tags.split(',').map(tag => tag.trim()).filter(tag => tag) : [];
      const imagesArray = formData.images ? formData.images.split(',').map(img => img.trim()).filter(img => img) : [];
      
      await axios.post('/api/catalog/products', {
        name: formData.name,
        description: formData.description,
        price: parseFloat(formData.price),
        stock: parseInt(formData.stock),
        category: formData.category,
        tags: tagsArray,
        images: imagesArray,
        featured: formData.featured
      });
      
      setShowAddForm(false);
      resetForm();
      fetchProducts(); // Refresh the list
      fetchCategories(); // Refresh categories in case a new one was added
    } catch (error) {
      console.error('Error creating product:', error);
      alert('Failed to create product: ' + (error.response?.data || error.message));
    }
  };

  const handleDelete = async (productId, productName) => {
    if (window.confirm(`Are you sure you want to delete "${productName}"? This action cannot be undone.`)) {
      try {
        await axios.delete(`/api/catalog/products/${productId}`);
        fetchProducts(); // Refresh the list
        fetchCategories(); // Refresh categories in case the last product of a category was deleted
      } catch (error) {
        console.error('Error deleting product:', error);
        alert('Failed to delete product: ' + (error.response?.data || error.message));
      }
    }
  };

  const formatPrice = (price) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(price);
  };

  if (!user || user.role !== 'ADMIN') {
    return null;
  }

  if (loading) {
    return <div className="loading">Loading admin panel...</div>;
  }

  return (
    <div className="container">
      <h1>Admin Panel</h1>
      <p style={{ color: '#666', marginBottom: '30px' }}>
        Manage products and view system metrics
      </p>

      {/* Quick Stats */}
      <div className="grid grid-3" style={{ marginBottom: '30px' }}>
        <div className="card" style={{ padding: '20px', textAlign: 'center' }}>
          <h3 style={{ color: '#007bff' }}>{products.length}</h3>
          <p>Total Products</p>
        </div>
        <div className="card" style={{ padding: '20px', textAlign: 'center' }}>
          <h3 style={{ color: '#28a745' }}>
            {products.reduce((sum, p) => sum + p.stock, 0)}
          </h3>
          <p>Total Stock</p>
        </div>
        <div className="card" style={{ padding: '20px', textAlign: 'center' }}>
          <h3 style={{ color: '#dc3545' }}>
            {products.filter(p => p.stock < 10).length}
          </h3>
          <p>Low Stock Items</p>
        </div>
      </div>

      {/* Add Product Form */}
      {showAddForm && (
        <div className="card" style={{ marginBottom: '20px' }}>
          <div style={{ padding: '20px', borderBottom: '1px solid #eee' }}>
            <h3>Add New Product</h3>
          </div>
          <div style={{ padding: '20px' }}>
            <div className="grid grid-2" style={{ gap: '15px' }}>
              <div>
                <label className="form-label">Product Name *</label>
                <input
                  type="text"
                  value={formData.name}
                  onChange={(e) => setFormData({...formData, name: e.target.value})}
                  className="form-input"
                  placeholder="Enter product name"
                />
              </div>
              <div>
                <label className="form-label">Category *</label>
                <input
                  type="text"
                  value={formData.category}
                  onChange={(e) => setFormData({...formData, category: e.target.value})}
                  className="form-input"
                  placeholder="Enter category or select existing"
                  list="categories-list"
                />
                <datalist id="categories-list">
                  {categories.map(cat => (
                    <option key={cat} value={cat} />
                  ))}
                </datalist>
              </div>
              <div>
                <label className="form-label">Price *</label>
                <input
                  type="number"
                  step="0.01"
                  value={formData.price}
                  onChange={(e) => setFormData({...formData, price: e.target.value})}
                  className="form-input"
                  placeholder="0.00"
                />
              </div>
              <div>
                <label className="form-label">Stock *</label>
                <input
                  type="number"
                  value={formData.stock}
                  onChange={(e) => setFormData({...formData, stock: e.target.value})}
                  className="form-input"
                  placeholder="0"
                />
              </div>
              <div style={{ gridColumn: '1 / -1' }}>
                <label className="form-label">Description</label>
                <textarea
                  value={formData.description}
                  onChange={(e) => setFormData({...formData, description: e.target.value})}
                  className="form-input"
                  rows="3"
                  placeholder="Enter product description"
                />
              </div>
              <div>
                <label className="form-label">Tags (comma-separated)</label>
                <input
                  type="text"
                  value={formData.tags}
                  onChange={(e) => setFormData({...formData, tags: e.target.value})}
                  className="form-input"
                  placeholder="tag1, tag2, tag3"
                />
              </div>
              <div>
                <label className="form-label">Images (comma-separated URLs)</label>
                <input
                  type="text"
                  value={formData.images}
                  onChange={(e) => setFormData({...formData, images: e.target.value})}
                  className="form-input"
                  placeholder="https://example.com/image1.jpg, https://example.com/image2.jpg"
                />
              </div>
              <div style={{ gridColumn: '1 / -1' }}>
                <label style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <input
                    type="checkbox"
                    checked={formData.featured}
                    onChange={(e) => setFormData({...formData, featured: e.target.checked})}
                  />
                  Featured Product
                </label>
              </div>
            </div>
            <div style={{ marginTop: '20px', display: 'flex', gap: '10px' }}>
              <button onClick={handleAdd} className="btn btn-primary">
                Add Product
              </button>
              <button onClick={handleCancel} className="btn btn-secondary">
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Products Table */}
      <div className="card">
        <div style={{ padding: '20px', borderBottom: '1px solid #eee', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <h2>Product Management</h2>
            <p style={{ color: '#666', margin: '5px 0' }}>
              Click on any product to edit its details
            </p>
          </div>
          <button 
            onClick={() => setShowAddForm(true)} 
            className="btn btn-primary"
            disabled={showAddForm}
          >
            Add New Product
          </button>
        </div>
        
        <div style={{ overflowX: 'auto' }}>
          <table className="admin-table" style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ background: '#f8f9fa' }}>
                <th className="product-column" style={{ padding: '15px', textAlign: 'left', borderBottom: '1px solid #eee' }}>
                  Product
                </th>
                <th className="images-column" style={{ padding: '15px', textAlign: 'left', borderBottom: '1px solid #eee' }}>
                  Images
                </th>
                <th className="category-column" style={{ padding: '15px', textAlign: 'left', borderBottom: '1px solid #eee' }}>
                  Category
                </th>
                <th className="price-column" style={{ padding: '15px', textAlign: 'left', borderBottom: '1px solid #eee' }}>
                  Price
                </th>
                <th className="stock-column" style={{ padding: '15px', textAlign: 'left', borderBottom: '1px solid #eee' }}>
                  Stock
                </th>
                <th className="actions-column" style={{ padding: '15px', textAlign: 'left', borderBottom: '1px solid #eee' }}>
                  Actions
                </th>
              </tr>
            </thead>
            <tbody>
              {products.map(product => (
                <tr key={product.id} style={{ borderBottom: '1px solid #eee' }}>
                  <td style={{ padding: '15px' }}>
                    {editingProduct === product.id ? (
                      <div>
                        <input
                          type="text"
                          value={formData.name}
                          onChange={(e) => setFormData({...formData, name: e.target.value})}
                          style={{ width: '100%', marginBottom: '5px', padding: '5px' }}
                          placeholder="Product name"
                        />
                        <textarea
                          value={formData.description}
                          onChange={(e) => setFormData({...formData, description: e.target.value})}
                          style={{ width: '100%', height: '60px', padding: '5px' }}
                          placeholder="Product description"
                        />
                      </div>
                    ) : (
                      <div>
                        <div style={{ fontWeight: '500' }}>{product.name}</div>
                        <div style={{ fontSize: '14px', color: '#666' }}>
                          {product.description?.substring(0, 100)}...
                        </div>
                      </div>
                    )}
                  </td>
                  <td className="images-column" style={{ padding: '15px' }}>
                    {editingProduct === product.id ? (
                      <div>
                        <textarea
                          value={formData.images}
                          onChange={(e) => setFormData({...formData, images: e.target.value})}
                          style={{ width: '100%', height: '80px', padding: '5px', fontSize: '12px' }}
                          placeholder="Enter image URLs separated by commas"
                        />
                        <div style={{ fontSize: '11px', color: '#666', marginTop: '2px' }}>
                          Separate multiple URLs with commas
                        </div>
                        {formData.images && formData.images.trim() && (
                          <div style={{ marginTop: '5px' }}>
                            <div style={{ fontSize: '11px', color: '#007bff' }}>
                              Preview: {formData.images.split(',').filter(img => img.trim()).length} image(s)
                            </div>
                          </div>
                        )}
                      </div>
                    ) : (
                      <div>
                        {product.images && product.images.length > 0 ? (
                          <div>
                            <img 
                              src={getProductImage(product.images, 0, '50x50', product.category)} 
                              alt={product.name}
                              style={{ 
                                width: '50px', 
                                height: '50px', 
                                objectFit: 'cover', 
                                borderRadius: '4px',
                                marginBottom: '5px'
                              }}
                              onError={(e) => handleImageError(e, product.category, '50x50')}
                            />
                            <div style={{ fontSize: '11px', color: '#666' }}>
                              {product.images.length} image{product.images.length !== 1 ? 's' : ''}
                            </div>
                          </div>
                        ) : (
                          <div style={{ 
                            fontSize: '12px', 
                            color: '#999',
                            padding: '10px',
                            border: '1px dashed #ddd',
                            borderRadius: '4px',
                            textAlign: 'center'
                          }}>
                            No images
                          </div>
                        )}
                      </div>
                    )}
                  </td>
                  <td style={{ padding: '15px' }}>
                    {editingProduct === product.id ? (
                      <select
                        value={formData.category}
                        onChange={(e) => setFormData({...formData, category: e.target.value})}
                        style={{ width: '100%', padding: '5px' }}
                      >
                        {categories.map(cat => (
                          <option key={cat} value={cat}>{cat}</option>
                        ))}
                      </select>
                    ) : (
                      <span className="product-category">{product.category}</span>
                    )}
                  </td>
                  <td style={{ padding: '15px' }}>
                    {editingProduct === product.id ? (
                      <input
                        type="number"
                        step="0.01"
                        value={formData.price}
                        onChange={(e) => setFormData({...formData, price: e.target.value})}
                        style={{ width: '80px', padding: '5px' }}
                      />
                    ) : (
                      formatPrice(product.price)
                    )}
                  </td>
                  <td style={{ padding: '15px' }}>
                    {editingProduct === product.id ? (
                      <input
                        type="number"
                        value={formData.stock}
                        onChange={(e) => setFormData({...formData, stock: e.target.value})}
                        style={{ width: '60px', padding: '5px' }}
                      />
                    ) : (
                      <span style={{ 
                        color: product.stock < 10 ? '#dc3545' : '#28a745',
                        fontWeight: '500'
                      }}>
                        {product.stock}
                      </span>
                    )}
                  </td>
                  <td style={{ padding: '15px' }}>
                    {editingProduct === product.id ? (
                      <div style={{ display: 'flex', gap: '5px', flexWrap: 'wrap' }}>
                        <button 
                          onClick={() => handleSave(product.id)}
                          className="btn btn-primary"
                          style={{ fontSize: '12px', padding: '5px 10px' }}
                        >
                          Save
                        </button>
                        <button 
                          onClick={handleCancel}
                          className="btn btn-secondary"
                          style={{ fontSize: '12px', padding: '5px 10px' }}
                        >
                          Cancel
                        </button>
                      </div>
                    ) : (
                      <div style={{ display: 'flex', gap: '5px', flexWrap: 'wrap' }}>
                        <button 
                          onClick={() => handleEdit(product)}
                          className="btn btn-primary"
                          style={{ fontSize: '12px', padding: '5px 10px' }}
                        >
                          Edit
                        </button>
                        <button 
                          onClick={() => handleDelete(product.id, product.name)}
                          className="btn"
                          style={{ 
                            fontSize: '12px', 
                            padding: '5px 10px',
                            background: '#dc3545',
                            color: 'white'
                          }}
                        >
                          Delete
                        </button>
                      </div>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* System Info */}
      <div style={{ marginTop: '30px' }}>
        <div className="card" style={{ padding: '20px' }}>
          <h3>System Information</h3>
          <div style={{ marginTop: '15px', fontSize: '14px', color: '#666' }}>
            <p>• Cache invalidation via Kafka messaging</p>
            <p>• Redis caching for improved performance</p>
            <p>• MongoDB for persistent storage</p>
            <p>• Real-time inventory updates</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Admin;