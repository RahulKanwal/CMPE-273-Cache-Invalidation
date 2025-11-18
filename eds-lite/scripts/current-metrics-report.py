#!/usr/bin/env python3
"""
EDS-Lite Current System Metrics Report
Shows detailed analysis of the current system state
"""

import json
import os
from collections import defaultdict
from statistics import median, quantiles
from datetime import datetime

def save_report(report_lines, timestamp, report_type):
    """Save report to file"""
    reports_dir = "/tmp/eds-reports"
    os.makedirs(reports_dir, exist_ok=True)
    
    filename = f"{reports_dir}/{report_type}-report-{timestamp}.txt"
    
    try:
        with open(filename, 'w') as f:
            f.write('\n'.join(report_lines))
        print(f"\n📄 Report saved to: {filename}")
    except Exception as e:
        print(f"\n⚠️  Could not save report: {e}")

def load_current_metrics():
    """Load metrics from current metrics file"""
    metrics = defaultdict(list)
    metrics_file = "/tmp/metrics/catalog.jsonl"
    
    if not os.path.exists(metrics_file):
        return metrics
    
    try:
        with open(metrics_file, 'r') as f:
            for line in f:
                if line.strip():
                    try:
                        data = json.loads(line)
                        metric_name = data.get('metric', '')
                        value = data.get('value', 0)
                        tags = data.get('tags', '')
                        
                        service = data.get('service', 'unknown')
                        key = f"{service}.{metric_name}"
                        metrics[key].append({
                            'value': value,
                            'tags': tags,
                            'timestamp': data.get('timestamp', '')
                        })
                    except json.JSONDecodeError:
                        continue
    except FileNotFoundError:
        pass
    
    return metrics

def calculate_percentiles(values, p50=True, p95=True):
    """Calculate percentiles"""
    if not values:
        return None, None
    
    sorted_values = sorted(values)
    if len(sorted_values) == 1:
        return sorted_values[0], sorted_values[0]
    
    p50_val = quantiles(sorted_values, n=100)[49] if p50 else None
    p95_val = quantiles(sorted_values, n=100)[94] if p95 else None
    return p50_val, p95_val

def generate_current_report(save_to_file=True):
    """Generate current system metrics report"""
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    report_lines = []
    
    def print_and_save(text=""):
        print(text)
        report_lines.append(text)
    
    print_and_save("=" * 80)
    print_and_save("EDS-LITE CURRENT SYSTEM METRICS REPORT")
    print_and_save("=" * 80)
    print_and_save(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print_and_save()
    
    metrics = load_current_metrics()
    
    if not metrics:
        print_and_save("❌ No current metrics found!")
        print_and_save("Make sure the catalog service is running and generating metrics.")
        if save_to_file:
            save_report(report_lines, timestamp, "current")
        return
    
    print("📊 CURRENT SYSTEM PERFORMANCE")
    print("=" * 80)
    print()
    
    # Cache metrics
    cache_hits = sum(v['value'] for v in metrics.get('catalog.cache_hits', []))
    cache_misses = sum(v['value'] for v in metrics.get('catalog.cache_misses', []))
    total_requests = cache_hits + cache_misses
    hit_rate = (cache_hits / total_requests * 100) if total_requests > 0 else 0
    
    print("🎯 CACHE PERFORMANCE:")
    print(f"   Cache Hits:           {cache_hits:,}")
    print(f"   Cache Misses:         {cache_misses:,}")
    print(f"   Total Requests:       {total_requests:,}")
    print(f"   Hit Rate:             {hit_rate:.2f}%")
    print()
    
    # Performance assessment
    if hit_rate > 80:
        print("   ✅ Cache Performance: EXCELLENT")
    elif hit_rate > 50:
        print("   ⚠️  Cache Performance: GOOD")
    elif hit_rate > 0:
        print("   ❌ Cache Performance: POOR")
    else:
        print("   ❌ Cache Performance: NOT WORKING")
    print()
    
    # Latency metrics
    latency_metrics = {}
    for key, values in metrics.items():
        if 'latency' in key.lower() or 'duration' in key.lower():
            latency_values = [v['value'] * 1000 for v in values if v['value'] > 0]  # Convert to ms
            if latency_values:
                p50, p95 = calculate_percentiles(latency_values)
                latency_metrics[key] = {
                    'p50': p50,
                    'p95': p95,
                    'count': len(latency_values),
                    'avg': sum(latency_values) / len(latency_values)
                }
    
    if latency_metrics:
        print("⚡ LATENCY PERFORMANCE:")
        for key, data in latency_metrics.items():
            metric_name = key.split('.')[-1]
            print(f"   {metric_name}:")
            print(f"     p50:                {data['p50']:.2f} ms")
            print(f"     p95:                {data['p95']:.2f} ms")
            print(f"     Average:            {data['avg']:.2f} ms")
            print(f"     Samples:            {data['count']:,}")
        print()
    
    # Data consistency
    stale_reads = sum(v['value'] for v in metrics.get('catalog.stale_reads_detected', []))
    stale_rate = (stale_reads / total_requests * 100) if total_requests > 0 else 0
    
    print("🔒 DATA CONSISTENCY:")
    print(f"   Stale Reads:          {stale_reads:,}")
    print(f"   Stale Rate:           {stale_rate:.3f}%")
    print()
    
    if stale_rate < 0.1:
        print("   ✅ Data Consistency: EXCELLENT")
    elif stale_rate < 1:
        print("   ⚠️  Data Consistency: GOOD")
    else:
        print("   ❌ Data Consistency: POOR")
    print()
    
    # Invalidation performance
    invalidations_sent = sum(v['value'] for v in metrics.get('catalog.invalidations_sent', []))
    invalidations_received = sum(v['value'] for v in metrics.get('catalog.invalidations_received', []))
    success_rate = (invalidations_received / invalidations_sent * 100) if invalidations_sent > 0 else 0
    
    if invalidations_sent > 0:
        print("🔄 INVALIDATION PERFORMANCE:")
        print(f"   Invalidations Sent:   {invalidations_sent:,}")
        print(f"   Invalidations Rcvd:   {invalidations_received:,}")
        print(f"   Success Rate:         {success_rate:.2f}%")
        print()
        
        if success_rate > 99:
            print("   ✅ Invalidation: EXCELLENT")
        elif success_rate > 95:
            print("   ⚠️  Invalidation: GOOD")
        else:
            print("   ❌ Invalidation: POOR")
        print()
    
    # Inconsistency window
    inconsistency_values = []
    for key, values in metrics.items():
        if 'inconsistency_window' in key.lower():
            inconsistency_values.extend([v['value'] * 1000 for v in values if v['value'] > 0])  # Convert to ms
    
    if inconsistency_values:
        p50, p95 = calculate_percentiles(inconsistency_values)
        print("⏱️  INCONSISTENCY WINDOW:")
        print(f"   p50:                  {p50:.2f} ms")
        print(f"   p95:                  {p95:.2f} ms")
        print(f"   Samples:              {len(inconsistency_values):,}")
        print()
        
        if p95 < 100:
            print("   ✅ Consistency Speed: EXCELLENT")
        elif p95 < 1000:
            print("   ⚠️  Consistency Speed: GOOD")
        else:
            print("   ❌ Consistency Speed: SLOW")
        print()
    
    # Overall system assessment
    print("=" * 80)
    print("📋 OVERALL SYSTEM ASSESSMENT")
    print("=" * 80)
    print()
    
    score = 0
    max_score = 0
    
    # Cache performance (40% weight)
    max_score += 40
    if hit_rate > 80:
        score += 40
        print("✅ Cache Performance (40%): EXCELLENT")
    elif hit_rate > 50:
        score += 30
        print("⚠️  Cache Performance (40%): GOOD")
    elif hit_rate > 0:
        score += 15
        print("❌ Cache Performance (40%): POOR")
    else:
        print("❌ Cache Performance (40%): FAILED")
    
    # Data consistency (30% weight)
    max_score += 30
    if stale_rate < 0.1:
        score += 30
        print("✅ Data Consistency (30%): EXCELLENT")
    elif stale_rate < 1:
        score += 20
        print("⚠️  Data Consistency (30%): GOOD")
    else:
        score += 5
        print("❌ Data Consistency (30%): POOR")
    
    # Invalidation reliability (20% weight)
    max_score += 20
    if invalidations_sent > 0:
        if success_rate > 99:
            score += 20
            print("✅ Invalidation (20%): EXCELLENT")
        elif success_rate > 95:
            score += 15
            print("⚠️  Invalidation (20%): GOOD")
        else:
            score += 5
            print("❌ Invalidation (20%): POOR")
    else:
        score += 10  # No invalidations needed
        print("ℹ️  Invalidation (20%): NOT APPLICABLE")
    
    # System responsiveness (10% weight)
    max_score += 10
    if inconsistency_values and p95 < 100:
        score += 10
        print("✅ Responsiveness (10%): EXCELLENT")
    elif inconsistency_values and p95 < 1000:
        score += 7
        print("⚠️  Responsiveness (10%): GOOD")
    elif inconsistency_values:
        score += 3
        print("❌ Responsiveness (10%): SLOW")
    else:
        score += 5
        print("ℹ️  Responsiveness (10%): NOT MEASURED")
    
    print()
    print("-" * 80)
    
    final_score = (score / max_score * 100) if max_score > 0 else 0
    print(f"🏆 OVERALL SYSTEM SCORE: {final_score:.1f}/100")
    
    if final_score >= 90:
        print("🎉 VERDICT: PRODUCTION READY - Excellent performance!")
    elif final_score >= 75:
        print("✅ VERDICT: PRODUCTION READY - Good performance")
    elif final_score >= 60:
        print("⚠️  VERDICT: NEEDS OPTIMIZATION - Acceptable but can improve")
    else:
        print("❌ VERDICT: NOT READY - Significant issues need fixing")
    
    print()
    print("=" * 80)
    print("Report complete!")
    print("=" * 80)

if __name__ == "__main__":
    generate_current_report()