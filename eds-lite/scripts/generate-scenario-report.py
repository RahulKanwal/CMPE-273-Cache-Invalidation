#!/usr/bin/env python3
"""
EDS-Lite Scenario Comparison Report Generator
Analyzes and compares performance across all three caching scenarios
"""

import json
import os
import sys
from collections import defaultdict
from pathlib import Path
from statistics import median, quantiles
from datetime import datetime
import glob

def load_metrics_from_file(file_path):
    """Load metrics from a JSONL file"""
    metrics = defaultdict(list)
    
    try:
        with open(file_path, 'r') as f:
            for line in f:
                if line.strip():
                    try:
                        data = json.loads(line)
                        metric_name = data.get('metric', '')
                        value = data.get('value', 0)
                        tags = data.get('tags', '')
                        
                        # Store with service prefix
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
    p50_val = quantiles(sorted_values, n=100)[49] if p50 and len(sorted_values) > 1 else sorted_values[0]
    p95_val = quantiles(sorted_values, n=100)[94] if p95 and len(sorted_values) > 1 else sorted_values[-1]
    return p50_val, p95_val

def analyze_scenario_metrics(metrics):
    """Analyze metrics for a single scenario"""
    results = {}
    
    # Latency metrics (convert from seconds to milliseconds)
    latency_metrics = {}
    for key, values in metrics.items():
        if 'latency' in key.lower() or 'duration' in key.lower():
            latency_values = [v['value'] * 1000 for v in values if v['value'] > 0]
            if latency_values:
                p50, p95 = calculate_percentiles(latency_values)
                latency_metrics[key] = {
                    'p50': p50,
                    'p95': p95,
                    'count': len(latency_values),
                    'avg': sum(latency_values) / len(latency_values)
                }
    
    results['latency'] = latency_metrics
    
    # Cache metrics
    cache_hits = sum(v['value'] for v in metrics.get('catalog.cache_hits', []))
    cache_misses = sum(v['value'] for v in metrics.get('catalog.cache_misses', []))
    total_requests = cache_hits + cache_misses
    
    results['cache'] = {
        'hits': cache_hits,
        'misses': cache_misses,
        'total': total_requests,
        'hit_rate': (cache_hits / total_requests * 100) if total_requests > 0 else 0
    }
    
    # Stale reads
    stale_reads = sum(v['value'] for v in metrics.get('catalog.stale_reads_detected', []))
    stale_rate = (stale_reads / total_requests * 100) if total_requests > 0 else 0
    
    results['stale_reads'] = {
        'count': stale_reads,
        'rate': stale_rate
    }
    
    # Invalidation metrics
    invalidations_sent = sum(v['value'] for v in metrics.get('catalog.invalidations_sent', []))
    invalidations_received = sum(v['value'] for v in metrics.get('catalog.invalidations_received', []))
    
    results['invalidations'] = {
        'sent': invalidations_sent,
        'received': invalidations_received,
        'success_rate': (invalidations_received / invalidations_sent * 100) if invalidations_sent > 0 else 0
    }
    
    # Inconsistency window (convert from seconds to milliseconds)
    inconsistency_values = []
    for key, values in metrics.items():
        if 'inconsistency_window' in key.lower():
            inconsistency_values.extend([v['value'] * 1000 for v in values if v['value'] > 0])
    
    if inconsistency_values:
        p50, p95 = calculate_percentiles(inconsistency_values)
        results['inconsistency'] = {
            'p50': p50,
            'p95': p95,
            'samples': len(inconsistency_values)
        }
    else:
        results['inconsistency'] = {'p50': 0, 'p95': 0, 'samples': 0}
    
    return results

def find_scenario_results():
    """Find all scenario result directories"""
    results_dirs = []
    
    # Look for backed up results in /tmp/eds-results
    if os.path.exists('/tmp/eds-results'):
        for timestamp_dir in glob.glob('/tmp/eds-results/*'):
            if os.path.isdir(timestamp_dir):
                scenario_dirs = glob.glob(f"{timestamp_dir}/scenario-*-metrics")
                for scenario_dir in scenario_dirs:
                    scenario_name = os.path.basename(scenario_dir).replace('scenario-', '').replace('-metrics', '')
                    metrics_file = os.path.join(scenario_dir, 'catalog.jsonl')
                    if os.path.exists(metrics_file):
                        results_dirs.append({
                            'scenario': scenario_name.upper(),
                            'path': metrics_file,
                            'timestamp': os.path.basename(timestamp_dir)
                        })
    
    # If no backed up results, use current metrics
    if not results_dirs and os.path.exists('/tmp/metrics/catalog.jsonl'):
        results_dirs.append({
            'scenario': 'CURRENT',
            'path': '/tmp/metrics/catalog.jsonl',
            'timestamp': 'current'
        })
    
    return results_dirs

def save_report(report_lines, timestamp):
    """Save report to file"""
    reports_dir = "/tmp/eds-reports"
    os.makedirs(reports_dir, exist_ok=True)
    
    filename = f"{reports_dir}/scenario-comparison-{timestamp}.txt"
    
    try:
        with open(filename, 'w') as f:
            f.write('\n'.join(report_lines))
        print(f"\n📄 Report saved to: {filename}")
        return filename
    except Exception as e:
        print(f"\n⚠️  Could not save report: {e}")
        return None

def generate_report():
    """Generate comprehensive scenario comparison report"""
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    report_lines = []
    
    def add_line(text=""):
        print(text)
        report_lines.append(text)
    
    add_line("=" * 80)
    add_line("EDS-LITE CACHE INVALIDATION SYSTEM - SCENARIO COMPARISON REPORT")
    add_line("=" * 80)
    add_line(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    add_line()
    
    # Find scenario results
    scenario_results = find_scenario_results()
    
    if not scenario_results:
        print("❌ No scenario results found!")
        print()
        print("To generate scenario results:")
        print("1. Run: ./run-scenarios-manual.sh")
        print("2. Or check /tmp/eds-results/ for backed up results")
        return
    
    print(f"📊 Found {len(scenario_results)} scenario result(s)")
    print()
    
    # Analyze each scenario
    scenarios = {}
    for result in scenario_results:
        print(f"📈 Analyzing Scenario {result['scenario']} ({result['timestamp']})...")
        metrics = load_metrics_from_file(result['path'])
        analysis = analyze_scenario_metrics(metrics)
        scenarios[result['scenario']] = analysis
    
    print()
    
    # Generate comparison report
    print("=" * 80)
    print("SCENARIO COMPARISON SUMMARY")
    print("=" * 80)
    print()
    
    # Scenario descriptions
    scenario_descriptions = {
        'A': 'No Cache (CACHE_MODE=none) - Direct DB calls',
        'B': 'TTL Only (CACHE_MODE=ttl) - Cache without invalidation',
        'C': 'TTL + Invalidation (CACHE_MODE=ttl_invalidate) - Full system',
        'CURRENT': 'Current System State'
    }
    
    for scenario in sorted(scenarios.keys()):
        desc = scenario_descriptions.get(scenario, f'Scenario {scenario}')
        print(f"🎯 Scenario {scenario}: {desc}")
    print()
    
    # Performance comparison table
    print("PERFORMANCE COMPARISON")
    print("-" * 80)
    print(f"{'Metric':<25} {'Unit':<10} " + " ".join([f"Scenario {s:>8}" for s in sorted(scenarios.keys())]))
    print("-" * 80)
    
    # Cache hit rate
    cache_rates = []
    for scenario in sorted(scenarios.keys()):
        rate = scenarios[scenario]['cache']['hit_rate']
        cache_rates.append(f"{rate:>8.1f}%")
    print(f"{'Cache Hit Rate':<25} {'%':<10} " + " ".join(cache_rates))
    
    # Cache requests
    cache_totals = []
    for scenario in sorted(scenarios.keys()):
        total = scenarios[scenario]['cache']['total']
        cache_totals.append(f"{total:>8,}")
    print(f"{'Total Requests':<25} {'count':<10} " + " ".join(cache_totals))
    
    # Stale read rate
    stale_rates = []
    for scenario in sorted(scenarios.keys()):
        rate = scenarios[scenario]['stale_reads']['rate']
        stale_rates.append(f"{rate:>8.2f}%")
    print(f"{'Stale Read Rate':<25} {'%':<10} " + " ".join(stale_rates))
    
    # Latency p95
    latency_p95s = []
    for scenario in sorted(scenarios.keys()):
        latency_data = scenarios[scenario]['latency']
        if latency_data:
            # Get the main latency metric
            main_latency = None
            for key, data in latency_data.items():
                if 'get_product_latency' in key:
                    main_latency = data['p95']
                    break
            if main_latency is None and latency_data:
                main_latency = list(latency_data.values())[0]['p95']
            latency_p95s.append(f"{main_latency:>8.1f}" if main_latency else f"{'N/A':>8}")
        else:
            latency_p95s.append(f"{'N/A':>8}")
    print(f"{'Latency p95':<25} {'ms':<10} " + " ".join(latency_p95s))
    
    # Inconsistency window p95
    inconsistency_p95s = []
    for scenario in sorted(scenarios.keys()):
        p95 = scenarios[scenario]['inconsistency']['p95']
        inconsistency_p95s.append(f"{p95:>8.1f}" if p95 > 0 else f"{'N/A':>8}")
    print(f"{'Inconsistency p95':<25} {'ms':<10} " + " ".join(inconsistency_p95s))
    
    print()
    
    # Detailed scenario analysis
    for scenario in sorted(scenarios.keys()):
        data = scenarios[scenario]
        desc = scenario_descriptions.get(scenario, f'Scenario {scenario}')
        
        print("=" * 80)
        print(f"DETAILED ANALYSIS - SCENARIO {scenario}")
        print(f"{desc}")
        print("=" * 80)
        print()
        
        # Cache performance
        cache = data['cache']
        print("CACHE PERFORMANCE:")
        print(f"  Cache Hits:           {cache['hits']:,}")
        print(f"  Cache Misses:         {cache['misses']:,}")
        print(f"  Total Requests:       {cache['total']:,}")
        print(f"  Hit Rate:             {cache['hit_rate']:.2f}%")
        print()
        
        # Latency metrics
        if data['latency']:
            print("LATENCY METRICS:")
            for key, latency in data['latency'].items():
                metric_name = key.split('.')[-1]
                print(f"  {metric_name}:")
                print(f"    p50:                {latency['p50']:.2f} ms")
                print(f"    p95:                {latency['p95']:.2f} ms")
                print(f"    Average:            {latency['avg']:.2f} ms")
                print(f"    Samples:            {latency['count']:,}")
            print()
        
        # Data consistency
        stale = data['stale_reads']
        print("DATA CONSISTENCY:")
        print(f"  Stale Reads:          {stale['count']:,}")
        print(f"  Stale Rate:           {stale['rate']:.3f}%")
        print()
        
        # Invalidation performance
        inv = data['invalidations']
        if inv['sent'] > 0 or inv['received'] > 0:
            print("INVALIDATION PERFORMANCE:")
            print(f"  Invalidations Sent:   {inv['sent']:,}")
            print(f"  Invalidations Rcvd:   {inv['received']:,}")
            print(f"  Success Rate:         {inv['success_rate']:.2f}%")
            print()
        
        # Inconsistency window
        inc = data['inconsistency']
        if inc['samples'] > 0:
            print("INCONSISTENCY WINDOW:")
            print(f"  p50:                  {inc['p50']:.2f} ms")
            print(f"  p95:                  {inc['p95']:.2f} ms")
            print(f"  Samples:              {inc['samples']:,}")
            print()
    
    # Performance insights
    print("=" * 80)
    print("PERFORMANCE INSIGHTS & RECOMMENDATIONS")
    print("=" * 80)
    print()
    
    if len(scenarios) > 1:
        # Compare scenarios
        scenario_keys = sorted(scenarios.keys())
        
        # Find best cache hit rate
        best_cache_scenario = max(scenario_keys, key=lambda s: scenarios[s]['cache']['hit_rate'])
        best_cache_rate = scenarios[best_cache_scenario]['cache']['hit_rate']
        
        print(f"🏆 BEST CACHE PERFORMANCE: Scenario {best_cache_scenario}")
        print(f"   Hit Rate: {best_cache_rate:.2f}%")
        print()
        
        # Find lowest stale rate
        best_consistency_scenario = min(scenario_keys, key=lambda s: scenarios[s]['stale_reads']['rate'])
        best_consistency_rate = scenarios[best_consistency_scenario]['stale_reads']['rate']
        
        print(f"🎯 BEST CONSISTENCY: Scenario {best_consistency_scenario}")
        print(f"   Stale Rate: {best_consistency_rate:.3f}%")
        print()
        
        # Overall recommendation
        if 'C' in scenarios:
            c_data = scenarios['C']
            print("📋 OVERALL ASSESSMENT:")
            print(f"   Scenario C (TTL + Invalidation) provides:")
            print(f"   • Cache Hit Rate: {c_data['cache']['hit_rate']:.2f}%")
            print(f"   • Stale Read Rate: {c_data['stale_reads']['rate']:.3f}%")
            print(f"   • Invalidation Success: {c_data['invalidations']['success_rate']:.2f}%")
            print()
            
            if c_data['cache']['hit_rate'] > 80 and c_data['stale_reads']['rate'] < 1:
                print("✅ RECOMMENDATION: System is performing excellently!")
                print("   Ready for production deployment.")
            elif c_data['cache']['hit_rate'] > 50:
                print("⚠️  RECOMMENDATION: Good performance, consider optimization.")
                print("   Monitor cache hit rates and invalidation latency.")
            else:
                print("❌ RECOMMENDATION: Performance needs improvement.")
                print("   Check cache configuration and invalidation system.")
    else:
        # Single scenario analysis
        scenario = list(scenarios.keys())[0]
        data = scenarios[scenario]
        
        print(f"📊 SINGLE SCENARIO ANALYSIS: {scenario}")
        print()
        
        if data['cache']['hit_rate'] > 80:
            print("✅ Cache Performance: Excellent")
        elif data['cache']['hit_rate'] > 50:
            print("⚠️  Cache Performance: Good")
        else:
            print("❌ Cache Performance: Needs Improvement")
        
        if data['stale_reads']['rate'] < 1:
            print("✅ Data Consistency: Excellent")
        elif data['stale_reads']['rate'] < 5:
            print("⚠️  Data Consistency: Acceptable")
        else:
            print("❌ Data Consistency: Poor")
    
    add_line()
    add_line("=" * 80)
    add_line("Report generation complete!")
    add_line("=" * 80)
    
    # Save the report
    save_report(report_lines, timestamp)

if __name__ == "__main__":
    generate_report()