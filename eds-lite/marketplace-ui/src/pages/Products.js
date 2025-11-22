import React, { useState, useEffect } from 'react';
import { useSearchParams } from 'react-router-dom';
import axios from 'axios';
import ProductCard from '../components/ProductCard';

const Products = () => {
  const [searchParams, setSearchParams] = useSearchParams();
  const [products, setProducts] = useState([]);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [totalPages, setTotalPages] = useState(0);
  const [currentPage, setCurrentPage] = useState(0);
  const [totalElements, setTotalElements] = useState(0);

  // Search and filter state
  const [search, setSearch] = useState(searchParams.get('search') || '');
  const [category, setCategory] = useState(searchParams.get('category') || '');
  const [minPrice, setMinPrice] = useState(searchParams.get('minPrice') || '');
  const [maxPrice, setMaxPrice] = useState(searchParams.get('maxPrice') || '');
  const [sortBy, setSortBy] = useState(searchParams.get('sortBy') || 'name');
  const [sortDirection, setSortDirection] = useState(searchParams.get('sortDirection') || 'asc');

  useEffect(() => {
    fetchCategories();
  }, []);

  useEffect(() => {
    const page = parseInt(searchParams.get('page')) || 0;
    setCurrentPage(page);
    fetchProducts(page);
  }, [searchParams]);

  const fetchCategories = async () => {
    try {
      const response = await axios.get('/api/catalog/products/categories');
      setCategories(response.data);
    } catch (error) {
      console.error('Error fetching categories:', error);
    }
  };

  const fetchProducts = async (page = 0) => {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      if (search) params.append('search', search);
      if (category) params.append('category', category);
      if (minPrice) params.append('minPrice', minPrice);
      if (maxPrice) params.append('maxPrice', maxPrice);
      params.append('sortBy', sortBy);
      params.append('sortDirection', sortDirection);
      params.append('page', page.toString());
      params.append('size', '12');

      const response = await axios.get(`/api/catalog/products?${params}`);
      const data = response.data;
      
      setProducts(data.products);
      setTotalPages(data.totalPages);
      setTotalElements(data.totalElements);
    } catch (error) {
      console.error('Error fetching products:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = (e) => {
    e.preventDefault();
    updateSearchParams({ search, page: 0 });
  };

  const handleFilterChange = (filterName, value) => {
    updateSearchParams({ [filterName]: value, page: 0 });
  };

  const updateSearchParams = (updates) => {
    const newParams = new URLSearchParams(searchParams);
    
    Object.entries(updates).forEach(([key, value]) => {
      if (value) {
        newParams.set(key, value);
      } else {
        newParams.delete(key);
      }
    });

    setSearchParams(newParams);
  };

  const handlePageChange = (page) => {
    updateSearchParams({ page: page.toString() });
  };

  const clearFilters = () => {
    setSearch('');
    setCategory('');
    setMinPrice('');
    setMaxPrice('');
    setSortBy('name');
    setSortDirection('asc');
    setSearchParams({});
  };

  return (
    <div className="container">
      <h1>Products</h1>

      {/* Search Bar */}
      <form onSubmit={handleSearch} className="search-bar">
        <input
          type="text"
          placeholder="Search products..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="search-input"
        />
        <button type="submit" className="search-btn">Search</button>
      </form>

      {/* Filters */}
      <div className="filters">
        <div className="filter-group">
          <label>Category</label>
          <select
            value={category}
            onChange={(e) => {
              setCategory(e.target.value);
              handleFilterChange('category', e.target.value);
            }}
            className="filter-select"
          >
            <option value="">All Categories</option>
            {categories.map(cat => (
              <option key={cat} value={cat}>{cat}</option>
            ))}
          </select>
        </div>

        <div className="filter-group">
          <label>Min Price</label>
          <input
            type="number"
            placeholder="0"
            value={minPrice}
            onChange={(e) => {
              setMinPrice(e.target.value);
              handleFilterChange('minPrice', e.target.value);
            }}
            className="filter-select"
          />
        </div>

        <div className="filter-group">
          <label>Max Price</label>
          <input
            type="number"
            placeholder="1000"
            value={maxPrice}
            onChange={(e) => {
              setMaxPrice(e.target.value);
              handleFilterChange('maxPrice', e.target.value);
            }}
            className="filter-select"
          />
        </div>

        <div className="filter-group">
          <label>Sort By</label>
          <select
            value={sortBy}
            onChange={(e) => {
              setSortBy(e.target.value);
              handleFilterChange('sortBy', e.target.value);
            }}
            className="filter-select"
          >
            <option value="name">Name</option>
            <option value="price">Price</option>
            <option value="rating">Rating</option>
          </select>
        </div>

        <div className="filter-group">
          <label>Order</label>
          <select
            value={sortDirection}
            onChange={(e) => {
              setSortDirection(e.target.value);
              handleFilterChange('sortDirection', e.target.value);
            }}
            className="filter-select"
          >
            <option value="asc">Ascending</option>
            <option value="desc">Descending</option>
          </select>
        </div>

        <div className="filter-group">
          <label>&nbsp;</label>
          <button onClick={clearFilters} className="btn btn-secondary">
            Clear Filters
          </button>
        </div>
      </div>

      {/* Results Info */}
      <div style={{ margin: '20px 0', color: '#666' }}>
        {loading ? (
          'Loading...'
        ) : (
          `Showing ${products.length} of ${totalElements} products`
        )}
      </div>

      {/* Products Grid */}
      {loading ? (
        <div className="loading">Loading products...</div>
      ) : (
        <>
          <div className="product-grid">
            {products.map(product => (
              <ProductCard key={product.id} product={product} />
            ))}
          </div>

          {products.length === 0 && (
            <div style={{ textAlign: 'center', padding: '40px', color: '#666' }}>
              No products found. Try adjusting your search or filters.
            </div>
          )}

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="pagination">
              <button
                onClick={() => handlePageChange(currentPage - 1)}
                disabled={currentPage === 0}
                className="page-btn"
              >
                Previous
              </button>

              {Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
                const page = Math.max(0, Math.min(totalPages - 5, currentPage - 2)) + i;
                return (
                  <button
                    key={page}
                    onClick={() => handlePageChange(page)}
                    className={`page-btn ${currentPage === page ? 'active' : ''}`}
                  >
                    {page + 1}
                  </button>
                );
              })}

              <button
                onClick={() => handlePageChange(currentPage + 1)}
                disabled={currentPage >= totalPages - 1}
                className="page-btn"
              >
                Next
              </button>
            </div>
          )}
        </>
      )}
    </div>
  );
};

export default Products;