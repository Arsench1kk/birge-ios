"""Summarize completed or explicitly labelled partial stage 2.5 JSONL runs."""
import argparse
import csv
import json
import statistics
from collections import Counter, defaultdict
from pathlib import Path

METRICS = ('assigned_requests', 'assignment_rate', 'trip_count', 'total_time_deviation_minutes', 'mean_passengers_per_trip', 'runtime_seconds')


def summarize(records):
    groups, pairs = defaultdict(list), defaultdict(dict)
    for record in records:
        key = (record['scenario'], record['search_budget_seconds'], record['solver'])
        groups[key].append(record)
        pairs[(record['scenario'], record['search_budget_seconds'], record['seed'])][record['solver']] = record
    summary = []
    for (name, budget, solver), group in sorted(groups.items()):
        status = Counter(r['solver_status'] for r in group)
        feasible = [r for r in group if r['solver_status'] in ('BASELINE', 'OPTIMAL', 'FEASIBLE')]
        row = {'scenario': name, 'budget': budget, 'solver': solver, 'runs': len(group), 'solutions': len(feasible),
               'no_solution': len(group)-len(feasible), 'R_mean': statistics.mean(r['supply_ratio'] for r in group),
               **{s: status[s] for s in ('OPTIMAL', 'FEASIBLE', 'UNKNOWN', 'INFEASIBLE')}}
        daily = Counter(d['status'] for r in group for d in (r.get('diagnostics') or {}).get('days', []))
        row.update({f'day_{s}': daily[s] for s in ('OPTIMAL', 'FEASIBLE', 'UNKNOWN', 'INFEASIBLE')})
        row['fallback_days'] = sum((r.get('diagnostics') or {}).get('fallback_days', 0) for r in group)
        for metric in METRICS:
            source = group if metric == 'runtime_seconds' else feasible
            values = [r['metrics'][metric] for r in source if r['metrics'].get(metric) is not None]
            row[f'{metric}_n'] = len(values)
            row[f'{metric}_mean'] = statistics.mean(values) if values else None
            row[f'{metric}_std'] = statistics.stdev(values) if len(values)>1 else None
        summary.append(row)
    comparison = defaultdict(Counter)
    for (name, budget, seed), runs in pairs.items():
        baseline = runs.get('baseline_greedy')
        if not baseline:
            continue
        b = baseline['metrics']
        for mode in ('ilp_cpsat', 'ilp_cpsat+warm'):
            candidate = runs.get(mode)
            if not candidate:
                continue
            bucket = comparison[(name, budget, mode)]
            if candidate['solver_status'] not in ('OPTIMAL', 'FEASIBLE'):
                bucket['no_solution'] += 1
                continue
            m = candidate['metrics']
            left = (-m['assigned_requests'], m['trip_count'], m['total_time_deviation_minutes'])
            right = (-b['assigned_requests'], b['trip_count'], b['total_time_deviation_minutes'])
            category = ('assigned_better' if left[0]<right[0] else 'secondary_better' if left<right
                        else 'equal' if left==right else 'worse')
            bucket[category] += 1
    comparisons = [{'scenario':name,'budget':budget,'solver':mode,
                    **{k:counts[k] for k in ('assigned_better','secondary_better','equal','worse','no_solution')}}
                   for (name,budget,mode),counts in sorted(comparison.items())]
    return summary, comparisons


def write_csv(path, data):
    if data:
        with path.open('w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=list(data[0])); writer.writeheader(); writer.writerows(data)


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('source',type=Path); parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args(); args.output.mkdir(parents=True,exist_ok=True)
    records=[json.loads(line) for line in args.source.read_text().splitlines() if line.strip()]
    summary, comparisons=summarize(records)
    write_csv(args.output/'summary.csv',summary); write_csv(args.output/'comparisons.csv',comparisons)
    print(f'{len(records)} runs; {len(summary)} groups; {len(comparisons)} paired comparisons')

if __name__=='__main__': main()
