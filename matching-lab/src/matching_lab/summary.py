"""Aggregate paired synthetic runs without treating UNKNOWN as a solution."""
from __future__ import annotations

import argparse
import csv
import json
import statistics
from collections import Counter, defaultdict
from pathlib import Path

METRICS = ("assigned_requests", "trip_count", "total_time_deviation_minutes", "mean_passengers_per_trip", "runtime_seconds")


def summarize(records: list[dict]) -> tuple[list[dict], list[dict]]:
    groups = defaultdict(list)
    pairs = defaultdict(dict)
    for record in records:
        meta = record["metadata"]
        groups[(meta["scenario_name"], meta["solver"])].append(record)
        pairs[(meta["scenario_name"], meta["seed"])][meta["solver"]] = record
    rows = []
    for (scenario, solver), group in sorted(groups.items()):
        statuses = Counter((r["metadata"].get("solver_status") or "BASELINE") for r in group)
        feasible = [r for r in group if (r["metadata"].get("solver_status") or "BASELINE") in ("BASELINE", "OPTIMAL", "FEASIBLE")]
        row = {"scenario": scenario, "solver": solver, "attempted": len(group), "valid_solutions": len(feasible),
               **{f"status_{status}": statuses[status] for status in ("OPTIMAL", "FEASIBLE", "UNKNOWN", "INFEASIBLE")}}
        for metric in METRICS:
            source = group if metric == "runtime_seconds" else feasible
            values = [r["metrics"][metric] for r in source if r["metrics"].get(metric) is not None]
            row[f"{metric}_n"] = len(values)
            row[f"{metric}_mean"] = statistics.mean(values) if values else None
            row[f"{metric}_std"] = statistics.stdev(values) if len(values) > 1 else None
        rows.append(row)
    comparisons = defaultdict(Counter)
    for (scenario, seed), pair in pairs.items():
        if "baseline_greedy" not in pair or "ilp_cpsat" not in pair:
            continue
        baseline, ilp = pair["baseline_greedy"], pair["ilp_cpsat"]
        if ilp["metadata"].get("solver_status") not in ("OPTIMAL", "FEASIBLE"):
            comparisons[scenario]["not_comparable"] += 1
            continue
        def score(record):
            m = record["metrics"]
            return (-m["assigned_requests"], m["trip_count"], m["total_time_deviation_minutes"])
        first, second = score(ilp), score(baseline)
        comparisons[scenario]["ilp_better" if first < second else "equal" if first == second else "ilp_worse"] += 1
    comparisons_rows = [{"scenario": name, **{key: counts[key] for key in ("ilp_better", "equal", "ilp_worse", "not_comparable")}}
                        for name, counts in sorted(comparisons.items())]
    return rows, comparisons_rows


def main() -> None:
    parser = argparse.ArgumentParser(description="Summarize synthetic runs with sample standard deviation")
    parser.add_argument("results", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    records = json.loads(args.results.read_text(encoding="utf-8"))
    rows, comparisons = summarize(records)
    args.output.mkdir(parents=True, exist_ok=True)
    (args.output / "summary.json").write_text(json.dumps({"statistics": rows, "comparisons": comparisons}, ensure_ascii=False, indent=2), encoding="utf-8")
    for filename, data in (("summary.csv", rows), ("comparisons.csv", comparisons)):
        if not data:
            continue
        with (args.output / filename).open("w", newline="", encoding="utf-8") as handle:
            writer = csv.DictWriter(handle, fieldnames=list(data[0]))
            writer.writeheader()
            writer.writerows(data)
    print("SYNTHETIC; sample standard deviation; UNKNOWN/INFEASIBLE excluded from solution metrics; runtime includes all attempts")
    print("scenario\tsolver\tvalid/attempted\tassigned mean±std\ttrips mean±std\tdeviation mean±std\toccupancy mean±std\truntime mean±std\tOPT/FEAS/UNKNOWN/INFEAS")
    def fmt(row, metric):
        mean, sd = row[f"{metric}_mean"], row[f"{metric}_std"]
        return f"{mean:.3f}±{sd:.3f}" if mean is not None and sd is not None else (f"{mean:.3f}±n/a" if mean is not None else "n/a")
    for row in rows:
        print("\t".join([row["scenario"], row["solver"], f'{row["valid_solutions"]}/{row["attempted"]}',
                         *[fmt(row, metric) for metric in METRICS],
                         "/".join(str(row[f"status_{s}"]) for s in ("OPTIMAL", "FEASIBLE", "UNKNOWN", "INFEASIBLE"))]))
    print("comparisons: scenario better equal worse not_comparable")
    for row in comparisons:
        print(row["scenario"], row["ilp_better"], row["equal"], row["ilp_worse"], row["not_comparable"])


if __name__ == "__main__":
    main()
