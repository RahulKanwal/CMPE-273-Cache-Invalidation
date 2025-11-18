#!/usr/bin/env python3
"""
Summarize metrics from JSONL files in /tmp/metrics/
Computes: p50/p95 latency, cache hit rate, stale-read rate, inconsistency window p95
"""

import json
import os
import sys
from collections import defaultdict
from pathlib import Path
from statistics import median, quantiles

METRICS_DIR = Path("/tmp/metrics")

def load_metrics():
    """Load all metrics from JSONL files"""
    metrics = defaultdict(list)
    
    for jsonl_file in METRICS_DIR.glob("*.jsonl"):
        service = jsonl_file.stem
        try:
            with open(jsonl_file, 'r') as f:
                for line in f:
                    if line.strip():
                        try:
                            data = json.loads(line)
                            metric_name = data.get('metric', '')
                            value = data.get('value', 0)
                            tags = data.get('tags', '')
                            
                            # Store with service prefix
                            key = f"{service}.{metric_name}"
                            metrics[key].append({
                                'value': value,
                                'tags': tags,
                                'timestamp': data.get('timestamp', '')
                            })
                        except json.JSONDecodeError:
                            continue
        except FileNotFoundError:
            continue
    
    return metrics

def calculate_percentiles(values, p50=True, p95=True):
    """Calculate percentiles"""
    if not values:
        return None, None
    
    sorted_values = sorted(values)
    p50_val = quantiles(sorted_values, n=100)[49] if p50 else None
    p95_val = quantiles(sorted_values, n=100)[94] if p95 else None
    return p50_val, p95_val

def summarize():
    """Summarize all metrics"""
    metrics = load_metrics()
    
    if not metrics:
        print("No metrics found in /tmp/metrics/*.jsonl")
        print("Make sure services are running and generating metrics.")
        return
    
    print("\n" + "="*80)
    print("METRICS SUMMARY")
    print("="*80 + "\n")
    
    # Latency metrics (p50, p95)
    latency_metrics = {}
    for key, values in metrics.items():
        if 'latency' in key.lower() or 'duration' in key.lower():
            # Convert from seconds to milliseconds (Micrometer timers are in seconds)
            latency_values = [v['value'] * 1000 for v in values if v['value'] > 0]
            if latency_values:
                p50, p95 = calculate_percentiles(latency_values)
                latency_metrics[key] = {'p50': p50, 'p95': p95, 'count': len(latency_values)}
    
    if latency_metrics:
        print("LATENCY METRICS (ms):")
        print("-" * 80)
        for key, stats in latency_metrics.items():
            print(f"  {key:50s} p50: {stats['p50']:8.2f} ms  p95: {stats['p95']:8.2f} ms  (n={stats['count']})")
        print()
    
    # Cache metrics
    cache_hits = sum(v['value'] for v in metrics.get('catalog.cache_hits', []))
    cache_misses = sum(v['value'] for v in metrics.get('catalog.cache_misses', []))
    total_requests = cache_hits + cache_misses
    
    if total_requests > 0:
        hit_rate = (cache_hits / total_requests) * 100
        print("CACHE METRICS:")
        print("-" * 80)
        print(f"  Cache Hits:     {cache_hits:10.0f}")
        print(f"  Cache Misses:   {cache_misses:10.0f}")
        print(f"  Total Requests: {total_requests:10.0f}")
        print(f"  Hit Rate:       {hit_rate:10.2f}%")
        print()
    
    # Stale reads
    stale_reads = sum(v['value'] for v in metrics.get('catalog.stale_reads_detected', []))
    stale_rate = (stale_reads / total_requests * 100) if total_requests > 0 else 0
    
    print("STALE READ METRICS:")
    print("-" * 80)
    print(f"  Stale Reads Detected: {stale_reads:10.0f}")
    print(f"  Total Read Requests:  {total_requests:10.0f}")
    print(f"  Stale Rate:           {stale_rate:10.2f}%")
    print()
    
    # Invalidation metrics
    invalidations_sent = sum(v['value'] for v in metrics.get('catalog.invalidations_sent', []))
    invalidations_received = sum(v['value'] for v in metrics.get('catalog.invalidations_received', []))
    
    if invalidations_sent > 0 or invalidations_received > 0:
        print("INVALIDATION METRICS:")
        print("-" * 80)
        print(f"  Invalidations Sent:     {invalidations_sent:10.0f}")
        print(f"  Invalidations Received: {invalidations_received:10.0f}")
        print()
    
    # Inconsistency window (convert from seconds to milliseconds)
    inconsistency_values = []
    for key, values in metrics.items():
        if 'inconsistency_window' in key.lower():
            # Convert from seconds to milliseconds (Micrometer timers are in seconds)
            inconsistency_values.extend([v['value'] * 1000 for v in values if v['value'] > 0])
    
    if inconsistency_values:
        p50, p95 = calculate_percentiles(inconsistency_values)
        print("INCONSISTENCY WINDOW (ms):")
        print("-" * 80)
        print(f"  p50: {p50:8.2f} ms")
        print(f"  p95: {p95:8.2f} ms")
        print(f"  Samples: {len(inconsistency_values)}")
        print()
    
    # Summary table
    print("="*80)
    print("SUMMARY TABLE")
    print("="*80)
    print(f"{'Metric':<30s} {'Value':>20s}")
    print("-"*50)
    
    if latency_metrics:
        for key, stats in latency_metrics.items():
            if 'get_product' in key or 'latency' in key:
                print(f"{'p95 Latency (ms)':<30s} {stats['p95']:>20.2f}")
                break
    
    if total_requests > 0:
        print(f"{'Cache Hit Rate (%)':<30s} {hit_rate:>20.2f}")
    
    if stale_reads > 0:
        print(f"{'Stale Read Rate (%)':<30s} {stale_rate:>20.2f}")
    else:
        print(f"{'Stale Read Rate (%)':<30s} {'0.00':>20s}")
    
    if inconsistency_values:
        _, p95 = calculate_percentiles(inconsistency_values)
        print(f"{'Inconsistency p95 (ms)':<30s} {p95:>20.2f}")
    else:
        print(f"{'Inconsistency p95 (ms)':<30s} {'N/A':>20s}")
    
    print("="*80 + "\n")

if __name__ == "__main__":
    summarize()

