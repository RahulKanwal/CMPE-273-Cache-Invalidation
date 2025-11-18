#!/usr/bin/env python3
"""
EDS-Lite Current System Metrics Report with File Saving
Shows detailed analysis of the current system state and saves to file
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
        return filename
    except Exception as e:
        print(f"\n⚠️  Could not save report: {e}")
        return None

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

def generate_current_report_with_save():
    """Generate current system metrics report and save to file"""
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    report_lines = []
    
    def add_line(text=""):
        print(text)
        report_lines.append(text)
    
    add_line("=" * 80)
    add_line("EDS-LITE CURRENT SYSTEM METRICS REPORT")
    add_line("=" * 80)
    add_line(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    add_line()
    
    metrics = load_current_metrics()
    
    if not metrics:
        add_line("❌ No current metrics found!")
        add_line("Make sure the catalog service is running and generating metrics.")
        save_report(report_lines, timestamp, "current")
        return
    
    add_line("📊 CURRENT SYSTEM PERFORMANCE")
    add_line("=" * 80)
    add_line()
    
    # Cache metrics
    cache_hits = sum(v['value'] for v in metrics.get('catalog.cache_hits', []))
    cache_misses = sum(v['value'] for v in metrics.get('catalog.cache_misses', []))
    total_requests = cache_hits + cache_misses
    hit_rate = (cache_hits / total_requests * 100) if total_requests > 0 else 0
    
    add_line("🎯 CACHE PERFORMANCE:")
    add_line(f"   Cache Hits:           {cache_hits:,}")
    add_line(f"   Cache Misses:         {cache_misses:,}")
    add_line(f"   Total Requests:       {total_requests:,}")
    add_line(f"   Hit Rate:             {hit_rate:.2f}%")
    add_line()
    
    # Performance assessment
    if hit_rate > 80:
        add_line("   ✅ Cache Performance: EXCELLENT")
    elif hit_rate > 50:
        add_line("   ⚠️  Cache Performance: GOOD")
    elif hit_rate > 0:
        add_line("   ❌ Cache Performance: POOR")
    else:
        add_line("   ❌ Cache Performance: NOT WORKING")
    add_line()
    
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
        add_line("⚡ LATENCY PERFORMANCE:")
        for key, data in latency_metrics.items():
            metric_name = key.split('.')[-1]
            add_line(f"   {metric_name}:")
            add_line(f"     p50:                {data['p50']:.2f} ms")
            add_line(f"     p95:                {data['p95']:.2f} ms")
            add_line(f"     Average:            {data['avg']:.2f} ms")
            add_line(f"     Samples:            {data['count']:,}")
        add_line()
    
    # Data consistency
    stale_reads = sum(v['value'] for v in metrics.get('catalog.stale_reads_detected', []))
    stale_rate = (stale_reads / total_requests * 100) if total_requests > 0 else 0
    
    add_line("🔒 DATA CONSISTENCY:")
    add_line(f"   Stale Reads:          {stale_reads:,}")
    add_line(f"   Stale Rate:           {stale_rate:.3f}%")
    add_line()
    
    if stale_rate < 0.1:
        add_line("   ✅ Data Consistency: EXCELLENT")
    elif stale_rate < 1:
        add_line("   ⚠️  Data Consistency: GOOD")
    else:
        add_line("   ❌ Data Consistency: POOR")
    add_line()
    
    # Invalidation performance
    invalidations_sent = sum(v['value'] for v in metrics.get('catalog.invalidations_sent', []))
    invalidations_received = sum(v['value'] for v in metrics.get('catalog.invalidations_received', []))
    success_rate = (invalidations_received / invalidations_sent * 100) if invalidations_sent > 0 else 0
    
    if invalidations_sent > 0:
        add_line("🔄 INVALIDATION PERFORMANCE:")
        add_line(f"   Invalidations Sent:   {invalidations_sent:,}")
        add_line(f"   Invalidations Rcvd:   {invalidations_received:,}")
        add_line(f"   Success Rate:         {success_rate:.2f}%")
        add_line()
        
        if success_rate > 99:
            add_line("   ✅ Invalidation: EXCELLENT")
        elif success_rate > 95:
            add_line("   ⚠️  Invalidation: GOOD")
        else:
            add_line("   ❌ Invalidation: POOR")
        add_line()
    
    # Inconsistency window
    inconsistency_values = []
    for key, values in metrics.items():
        if 'inconsistency_window' in key.lower():
            inconsistency_values.extend([v['value'] * 1000 for v in values if v['value'] > 0])  # Convert to ms
    
    if inconsistency_values:
        p50, p95 = calculate_percentiles(inconsistency_values)
        add_line("⏱️  INCONSISTENCY WINDOW:")
        add_line(f"   p50:                  {p50:.2f} ms")
        add_line(f"   p95:                  {p95:.2f} ms")
        add_line(f"   Samples:              {len(inconsistency_values):,}")
        add_line()
        
        if p95 < 100:
            add_line("   ✅ Consistency Speed: EXCELLENT")
        elif p95 < 1000:
            add_line("   ⚠️  Consistency Speed: GOOD")
        else:
            add_line("   ❌ Consistency Speed: SLOW")
        add_line()
    
    # Overall system assessment
    add_line("=" * 80)
    add_line("📋 OVERALL SYSTEM ASSESSMENT")
    add_line("=" * 80)
    add_line()
    
    score = 0
    max_score = 0
    
    # Cache performance (40% weight)
    max_score += 40
    if hit_rate > 80:
        score += 40
        add_line("✅ Cache Performance (40%): EXCELLENT")
    elif hit_rate > 50:
        score += 30
        add_line("⚠️  Cache Performance (40%): GOOD")
    elif hit_rate > 0:
        score += 15
        add_line("❌ Cache Performance (40%): POOR")
    else:
        add_line("❌ Cache Performance (40%): FAILED")
    
    # Data consistency (30% weight)
    max_score += 30
    if stale_rate < 0.1:
        score += 30
        add_line("✅ Data Consistency (30%): EXCELLENT")
    elif stale_rate < 1:
        score += 20
        add_line("⚠️  Data Consistency (30%): GOOD")
    else:
        score += 5
        add_line("❌ Data Consistency (30%): POOR")
    
    # Invalidation reliability (20% weight)
    max_score += 20
    if invalidations_sent > 0:
        if success_rate > 99:
            score += 20
            add_line("✅ Invalidation (20%): EXCELLENT")
        elif success_rate > 95:
            score += 15
            add_line("⚠️  Invalidation (20%): GOOD")
        else:
            score += 5
            add_line("❌ Invalidation (20%): POOR")
    else:
        score += 10  # No invalidations needed
        add_line("ℹ️  Invalidation (20%): NOT APPLICABLE")
    
    # System responsiveness (10% weight)
    max_score += 10
    if inconsistency_values and p95 < 100:
        score += 10
        add_line("✅ Responsiveness (10%): EXCELLENT")
    elif inconsistency_values and p95 < 1000:
        score += 7
        add_line("⚠️  Responsiveness (10%): GOOD")
    elif inconsistency_values:
        score += 3
        add_line("❌ Responsiveness (10%): SLOW")
    else:
        score += 5
        add_line("ℹ️  Responsiveness (10%): NOT MEASURED")
    
    add_line()
    add_line("-" * 80)
    
    final_score = (score / max_score * 100) if max_score > 0 else 0
    add_line(f"🏆 OVERALL SYSTEM SCORE: {final_score:.1f}/100")
    
    if final_score >= 90:
        add_line("🎉 VERDICT: PRODUCTION READY - Excellent performance!")
    elif final_score >= 75:
        add_line("✅ VERDICT: PRODUCTION READY - Good performance")
    elif final_score >= 60:
        add_line("⚠️  VERDICT: NEEDS OPTIMIZATION - Acceptable but can improve")
    else:
        add_line("❌ VERDICT: NOT READY - Significant issues need fixing")
    
    add_line()
    add_line("=" * 80)
    add_line("Report complete!")
    add_line("=" * 80)
    
    # Save the report
    filename = save_report(report_lines, timestamp, "current")
    return filename

if __name__ == "__main__":
    generate_current_report_with_save()