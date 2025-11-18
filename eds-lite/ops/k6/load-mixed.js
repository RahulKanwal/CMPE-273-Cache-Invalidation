// k6 load test: 90% reads, 10% writes
// Zipfian distribution for hot products (IDs 1-1000)
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

export const options = {
    stages: [
        { duration: '2m', target: 200 },  // Ramp up to 200 rps
        { duration: '3m', target: 400 },  // Ramp up to 400 rps
        { duration: '3m', target: 600 },  // Ramp up to 600 rps
        { duration: '2m', target: 0 },    // Ramp down
    ],
    thresholds: {
        http_req_duration: ['p(95)<500'], // 95% of requests should be below 500ms
    },
};

const errorRate = new Rate('errors');

// Zipfian-like distribution: more requests for lower IDs
function getProductId() {
    const rand = Math.random();
    if (rand < 0.5) {
        // 50% of requests for IDs 1-100 (hot)
        return Math.floor(Math.random() * 100) + 1;
    } else if (rand < 0.8) {
        // 30% for IDs 101-500 (warm)
        return Math.floor(Math.random() * 400) + 101;
    } else {
        // 20% for IDs 501-1000 (cold)
        return Math.floor(Math.random() * 500) + 501;
    }
}

export default function () {
    const baseUrl = __ENV.BASE_URL || 'http://localhost:8080';
    const isRead = Math.random() < 0.9; // 90% reads, 10% writes

    if (isRead) {
        // GET product
        const productId = getProductId();
        const url = `${baseUrl}/api/catalog/products/${productId}`;
        const res = http.get(url);
        
        const success = check(res, {
            'status is 200 or 404': (r) => r.status === 200 || r.status === 404,
        });
        errorRate.add(!success);
        
        sleep(0.1); // Small delay between requests
    } else {
        // POST update (random price/stock update)
        const productId = getProductId();
        const url = `${baseUrl}/api/catalog/products/${productId}`;
        const payload = JSON.stringify({
            price: (Math.random() * 1000 + 10).toFixed(2),
            stock: Math.floor(Math.random() * 1000),
        });
        const params = {
            headers: { 'Content-Type': 'application/json' },
        };
        const res = http.post(url, payload, params);
        
        const success = check(res, {
            'status is 200 or 404': (r) => r.status === 200 || r.status === 404,
        });
        errorRate.add(!success);
        
        sleep(0.5); // Longer delay for writes
    }
}

export function handleSummary(data) {
    return {
        'stdout': JSON.stringify(data, null, 2),
    };
}

