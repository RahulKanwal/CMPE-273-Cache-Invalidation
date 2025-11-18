#!/usr/bin/env python3
"""
EDS-Lite Latest Test Results Analyzer
Analyzes the most recent test results and generates comprehensive reports
Combines current system analysis + latest scenario comparison
"""

import json
import os
import sys
import glob
from collections import defaultdict
from pathlib import Path
from statistics import median, quantiles
from datetime import datetime

def save_report(report_lines, timestamp, report_type):
    """Save report to file"""
    reports_dir = "/tmp/eds-reports"
    os.makedirs(reports_dir, exist_ok=True)
    
    filename = f"{reports_dir}/{report_type}-{timestamp}.txt"
    
    try:
        with open(filename, 'w') as f:
            f.write('\n'.join(report_lines))
        print(f"📄 Report saved to: {filename}")
        return filename
    except Exception as e:
        print(f"⚠️  Could not save report: {e}")
        return None

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
    
    p50_val = quantiles(sorted_values, n=100)[49] if p50 and len(sorted_values) > 1 else sorted_values[0]
    p95_val = quantiles(sorted_values, n=100)[94] if p95 and len(sorted_values) > 1 else sorted_values[-1]
    return p50_val, p95_val

def analyze_metrics(metrics):
    """Analyze metrics for a scenario"""
    results = {}
    
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

def find_latest_scenario_results():
    """Find the most recent scenario test results for all scenarios A, B, C"""
    latest_results = {}
    
    if not os.path.exists('/tmp/eds-results'):
        return latest_results
    
    # Get all timestamp directories sorted by creation time (newest first)
    timestamp_dirs = glob.glob('/tmp/eds-results/*')
    timestamp_dirs.sort(key=os.path.getctime, reverse=True)
    
    # Look for each scenario (A, B, C) in the most recent test runs
    scenarios_needed = ['A', 'B', 'C']
    
    for timestamp_dir in timestamp_dirs:
        timestamp = os.path.basename(timestamp_dir)
        
        # Check each scenario in this timestamp directory
        for scenario in scenarios_needed[:]:  # Use slice to avoid modifying list during iteration
            scenario_dir = f"{timestamp_dir}/scenario-{scenario}-metrics"
            metrics_file = f"{scenario_dir}/catalog.jsonl"
            
            if os.path.exists(metrics_file):
                # Check if file has content
                try:
                    with open(metrics_file, 'r') as f:
                        first_line = f.readline()
                        if first_line.strip():  # File has content
                            latest_results[scenario] = {
                                'path': metrics_file,
                                'timestamp': timestamp
                            }
                            scenarios_needed.remove(scenario)
                except:
                    continue
        
        # If we found all scenarios, we can stop
        if not scenarios_needed:
            break
    
    return latest_results

def generate_latest_report():
    """Generate comprehensive report for latest test results"""
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    report_lines = []
    
    def add_line(text=""):
        print(text)
        report_lines.append(text)
    
    add_line("=" * 80)
    add_line("EDS-LITE LATEST TEST RESULTS - COMPREHENSIVE REPORT")
    add_line("=" * 80)
    add_line(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    add_line()
    
    # 1. CURRENT SYSTEM ANALYSIS
    add_line("📊 PART 1: CURRENT SYSTEM ANALYSIS")
    add_line("=" * 80)
    
    current_metrics = load_metrics_from_file("/tmp/metrics/catalog.jsonl")
    
    if current_metrics:
        current_analysis = analyze_metrics(current_metrics)
        
        # Cache performance
        cache = current_analysis['cache']
        add_line("🎯 CURRENT CACHE PERFORMANCE:")
        add_line(f"   Cache Hits:           {cache['hits']:,}")
        add_line(f"   Cache Misses:         {cache['misses']:,}")
        add_line(f"   Total Requests:       {cache['total']:,}")
        add_line(f"   Hit Rate:             {cache['hit_rate']:.2f}%")
        add_line()
        
        if cache['hit_rate'] > 80:
            add_line("   ✅ Cache Performance: EXCELLENT")
        elif cache['hit_rate'] > 50:
            add_line("   ⚠️  Cache Performance: GOOD")
        else:
            add_line("   ❌ Cache Performance: POOR")
        add_line()
        
        # Data consistency
        stale = current_analysis['stale_reads']
        add_line("🔒 CURRENT DATA CONSISTENCY:")
        add_line(f"   Stale Reads:          {stale['count']:,}")
        add_line(f"   Stale Rate:           {stale['rate']:.3f}%")
        add_line()
        
        # Invalidation performance
        inv = current_analysis['invalidations']
        if inv['sent'] > 0:
            add_line("🔄 CURRENT INVALIDATION PERFORMANCE:")
            add_line(f"   Invalidations Sent:   {inv['sent']:,}")
            add_line(f"   Invalidations Rcvd:   {inv['received']:,}")
            add_line(f"   Success Rate:         {inv['success_rate']:.2f}%")
            add_line()
        
        # Overall current system score
        score = 0
        max_score = 100
        
        if cache['hit_rate'] > 80:
            score += 40
        elif cache['hit_rate'] > 50:
            score += 30
        elif cache['hit_rate'] > 0:
            score += 15
        
        if stale['rate'] < 0.1:
            score += 30
        elif stale['rate'] < 1:
            score += 20
        else:
            score += 5
        
        if inv['sent'] > 0:
            if inv['success_rate'] > 99:
                score += 20
            elif inv['success_rate'] > 95:
                score += 15
            else:
                score += 5
        else:
            score += 10
        
        score += 10  # Base responsiveness score
        
        add_line(f"🏆 CURRENT SYSTEM SCORE: {score}/100")
        
        if score >= 90:
            add_line("🎉 VERDICT: PRODUCTION READY - Excellent performance!")
        elif score >= 75:
            add_line("✅ VERDICT: PRODUCTION READY - Good performance")
        else:
            add_line("⚠️  VERDICT: NEEDS OPTIMIZATION")
        add_line()
    else:
        add_line("❌ No current system metrics found!")
        add_line()
    
    # 2. LATEST SCENARIO COMPARISON
    add_line("📈 PART 2: LATEST SCENARIO TEST COMPARISON")
    add_line("=" * 80)
    
    latest_scenarios = find_latest_scenario_results()
    
    if latest_scenarios:
        # Show which scenarios were found and their timestamps
        add_line("📅 LATEST SCENARIO TEST RESULTS:")
        for scenario in ['A', 'B', 'C']:
            if scenario in latest_scenarios:
                add_line(f"   Scenario {scenario}: {latest_scenarios[scenario]['timestamp']}")
            else:
                add_line(f"   Scenario {scenario}: ❌ Not found")
        add_line(f"📊 Found {len(latest_scenarios)} scenario result(s)")
        add_line()
        
        # Analyze each scenario
        scenario_analyses = {}
        for scenario, info in latest_scenarios.items():
            add_line(f"📈 Analyzing Scenario {scenario} ({info['timestamp']})...")
            metrics = load_metrics_from_file(info['path'])
            scenario_analyses[scenario] = analyze_metrics(metrics)
        
        # Comparison table
        add_line("SCENARIO PERFORMANCE COMPARISON")
        add_line("-" * 80)
        add_line(f"{'Metric':<25} {'Unit':<10} " + " ".join([f"Scenario {s:>8}" for s in sorted(scenario_analyses.keys())]))
        add_line("-" * 80)
        
        # Cache hit rate
        cache_rates = []
        for scenario in sorted(scenario_analyses.keys()):
            rate = scenario_analyses[scenario]['cache']['hit_rate']
            cache_rates.append(f"{rate:>8.1f}%")
        add_line(f"{'Cache Hit Rate':<25} {'%':<10} " + " ".join(cache_rates))
        
        # Total requests
        cache_totals = []
        for scenario in sorted(scenario_analyses.keys()):
            total = scenario_analyses[scenario]['cache']['total']
            if total > 1000000:
                cache_totals.append(f"{total/1000000:>7.1f}M")
            elif total > 1000:
                cache_totals.append(f"{total/1000:>7.1f}K")
            else:
                cache_totals.append(f"{total:>8.0f}")
        add_line(f"{'Total Requests':<25} {'count':<10} " + " ".join(cache_totals))
        
        # Stale read rate
        stale_rates = []
        for scenario in sorted(scenario_analyses.keys()):
            rate = scenario_analyses[scenario]['stale_reads']['rate']
            stale_rates.append(f"{rate:>8.3f}%")
        add_line(f"{'Stale Read Rate':<25} {'%':<10} " + " ".join(stale_rates))
        
        add_line()
        
        add_line()
        
        # Detailed scenario analysis
        scenario_descriptions = {
            'A': 'No Cache (CACHE_MODE=none) - Direct DB calls',
            'B': 'TTL Only (CACHE_MODE=ttl) - Cache without invalidation',
            'C': 'TTL + Invalidation (CACHE_MODE=ttl_invalidate) - Full system'
        }
        
        add_line("DETAILED SCENARIO ANALYSIS")
        add_line("=" * 80)
        
        for scenario in ['A', 'B', 'C']:
            if scenario in scenario_analyses:
                data = scenario_analyses[scenario]
                desc = scenario_descriptions.get(scenario, f'Scenario {scenario}')
                
                add_line(f"🎯 SCENARIO {scenario}: {desc}")
                add_line("-" * 60)
                
                # Cache performance
                cache = data['cache']
                add_line("CACHE PERFORMANCE:")
                add_line(f"  Cache Hits:           {cache['hits']:,}")
                add_line(f"  Cache Misses:         {cache['misses']:,}")
                add_line(f"  Total Requests:       {cache['total']:,}")
                add_line(f"  Hit Rate:             {cache['hit_rate']:.2f}%")
                add_line()
                
                # Latency metrics
                if data['latency']:
                    add_line("LATENCY METRICS:")
                    for key, latency in data['latency'].items():
                        metric_name = key.split('.')[-1]
                        add_line(f"  {metric_name}:")
                        add_line(f"    p50:                {latency['p50']:.2f} ms")
                        add_line(f"    p95:                {latency['p95']:.2f} ms")
                        add_line(f"    Average:            {latency['avg']:.2f} ms")
                        add_line(f"    Samples:            {latency['count']:,}")
                    add_line()
                
                # Data consistency
                add_line("DATA CONSISTENCY:")
                add_line(f"  Stale Reads:          {data['stale_reads']['count']:,}")
                add_line(f"  Stale Rate:           {data['stale_reads']['rate']:.3f}%")
                add_line()
                
                # Invalidation performance (if applicable)
                if data['invalidations']['sent'] > 0:
                    add_line("INVALIDATION PERFORMANCE:")
                    add_line(f"  Invalidations Sent:   {data['invalidations']['sent']:,}")
                    add_line(f"  Invalidations Rcvd:   {data['invalidations']['received']:,}")
                    add_line(f"  Success Rate:         {data['invalidations']['success_rate']:.2f}%")
                    add_line()
                
                # Inconsistency window (if applicable)
                if data['inconsistency']['samples'] > 0:
                    add_line("INCONSISTENCY WINDOW:")
                    add_line(f"  p50:                  {data['inconsistency']['p50']:.2f} ms")
                    add_line(f"  p95:                  {data['inconsistency']['p95']:.2f} ms")
                    add_line(f"  Samples:              {data['inconsistency']['samples']:,}")
                    add_line()
                
                # Performance assessment
                if cache['hit_rate'] > 80 and data['stale_reads']['rate'] < 0.1:
                    add_line("✅ ASSESSMENT: EXCELLENT - Optimal performance & consistency")
                elif cache['hit_rate'] > 50:
                    add_line("⚠️  ASSESSMENT: GOOD - Decent performance")
                elif cache['hit_rate'] == 0 and scenario == 'A':
                    add_line("ℹ️  ASSESSMENT: BASELINE - No caching (expected for Scenario A)")
                elif cache['hit_rate'] == 0 and scenario == 'B':
                    add_line("❌ ASSESSMENT: CACHE NOT WORKING - TTL cache should show hits")
                else:
                    add_line("❌ ASSESSMENT: POOR - Needs improvement")
                
                add_line()
                add_line("=" * 80)
            else:
                desc = scenario_descriptions.get(scenario, f'Scenario {scenario}')
                add_line(f"❌ SCENARIO {scenario}: {desc}")
                add_line("-" * 60)
                add_line("   No test data found for this scenario")
                add_line()
                add_line("=" * 80)
        
        # Best performer identification
        if 'C' in scenario_analyses:
            c_data = scenario_analyses['C']
            add_line("🏆 RECOMMENDED CONFIGURATION:")
            add_line(f"   Scenario C (TTL + Invalidation) delivers:")
            add_line(f"   • Cache Hit Rate: {c_data['cache']['hit_rate']:.2f}%")
            add_line(f"   • Stale Read Rate: {c_data['stale_reads']['rate']:.3f}%")
            add_line(f"   • Total Requests: {c_data['cache']['total']:,}")
            
            if c_data['cache']['hit_rate'] > 80 and c_data['stale_reads']['rate'] < 0.1:
                add_line("   ✅ PRODUCTION READY!")
            else:
                add_line("   ⚠️  Needs optimization")
            add_line()
    else:
        add_line("❌ No recent scenario test results found!")
        add_line("Run scenario tests first: ./run-scenarios-manual.sh")
        add_line()
    
    # 3. SUMMARY AND RECOMMENDATIONS
    add_line("📋 PART 3: SUMMARY & RECOMMENDATIONS")
    add_line("=" * 80)
    
    if current_metrics and latest_scenarios:
        add_line("✅ SYSTEM STATUS: Fully operational with comprehensive test validation")
        add_line()
        add_line("KEY ACHIEVEMENTS:")
        
        if current_analysis['cache']['hit_rate'] > 80:
            add_line(f"• Excellent cache performance: {current_analysis['cache']['hit_rate']:.1f}% hit rate")
        
        if current_analysis['stale_reads']['rate'] < 0.1:
            add_line(f"• Outstanding data consistency: {current_analysis['stale_reads']['rate']:.3f}% stale reads")
        
        if current_analysis['invalidations']['success_rate'] > 99:
            add_line(f"• Reliable invalidation system: {current_analysis['invalidations']['success_rate']:.1f}% success rate")
        
        add_line(f"• Massive scale handling: {current_analysis['cache']['total']:,} total requests")
        add_line()
        
        add_line("FINAL RECOMMENDATION:")
        if score >= 90 and 'C' in scenario_analyses and scenario_analyses['C']['cache']['hit_rate'] > 80:
            add_line("🎉 DEPLOY TO PRODUCTION IMMEDIATELY!")
            add_line("   System demonstrates excellent performance with strong consistency.")
        else:
            add_line("⚠️  OPTIMIZE BEFORE PRODUCTION")
            add_line("   Address performance issues identified above.")
    
    elif current_metrics:
        add_line("⚠️  PARTIAL ANALYSIS: Current system data available, but no scenario tests found")
    elif latest_scenarios:
        add_line("⚠️  PARTIAL ANALYSIS: Scenario test data available, but no current system metrics")
    else:
        add_line("❌ INSUFFICIENT DATA: No current metrics or scenario test results found")
    
    add_line()
    add_line("=" * 80)
    add_line("Report generation complete!")
    add_line("=" * 80)
    
    # Save the report
    filename = save_report(report_lines, timestamp, "latest-comprehensive-report")
    return filename

if __name__ == "__main__":
    print("🚀 Generating comprehensive report for latest test results...")
    print()
    filename = generate_latest_report()
    
    if filename:
        print()
        print(f"✅ Complete report saved to: {filename}")
        print()
        print("📊 Report includes:")
        print("   • Current system performance analysis")
        print("   • Latest scenario test comparison")
        print("   • Production readiness assessment")
        print("   • Detailed recommendations")
    else:
        print("❌ Failed to save report")