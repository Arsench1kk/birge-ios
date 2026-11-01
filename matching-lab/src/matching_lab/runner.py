"""Command-line experiment runner with validation before result persistence."""
from __future__ import annotations

import argparse
import csv
import json
import subprocess
import sys
import time
from dataclasses import asdict, is_dataclass
from datetime import date, datetime, timezone
from pathlib import Path
from typing import Any

from matching_lab import __version__
from matching_lab.generator import _canonical_hash, generate_scenario, load_config
from matching_lab.metrics import calculate_metrics
from matching_lab.model import Scenario
from matching_lab.solvers.baseline_greedy import GreedyBaseline
from matching_lab.solvers.exact_tiny import ExactTiny
from matching_lab.solvers.ilp_cpsat import ILPCPSAT
from matching_lab.validator import validate


def _jsonable(value: Any) -> Any:
    if is_dataclass(value):
        return {key: _jsonable(item) for key, item in asdict(value).items()}
    if isinstance(value, (date, datetime)):
        return value.isoformat()
    if isinstance(value, (set, frozenset, tuple, list)):
        values = [_jsonable(item) for item in value]
        return sorted(values) if isinstance(value, (set, frozenset)) else values
    if isinstance(value, dict):
        return {str(key): _jsonable(item) for key, item in value.items()}
    return value


def _git_commit() -> str | None:
    try:
        return subprocess.run(
            ["git", "rev-parse", "HEAD"], cwd=Path(__file__).resolve().parents[2],
            capture_output=True, text=True, check=True
        ).stdout.strip()
    except (OSError, subprocess.CalledProcessError):
        return None


def _git_dirty() -> bool | None:
    try:
        result = subprocess.run(
            ["git", "status", "--porcelain", "--", str(Path(__file__).resolve().parents[2])],
            cwd=Path(__file__).resolve().parents[2], capture_output=True, text=True, check=True,
        )
        return bool(result.stdout.strip())
    except (OSError, subprocess.CalledProcessError):
        return None


def run_experiments(config_paths: list[Path], seeds: list[int], output_dir: Path, solver_names: list[str], exact_max_states: int = 100_000, exact_max_requests_per_day: int = 8, cpsat_options: dict | None = None, experiment_metadata: dict | None = None) -> list[dict]:
    def cpsat_factory():
        if cpsat_options is None:
            raise ValueError("ilp_cpsat requires explicit grid_minutes, time_limit_seconds and workers")
        return ILPCPSAT(**cpsat_options)
    registry = {"baseline_greedy": GreedyBaseline, "exact_tiny": lambda: ExactTiny(max_requests_per_day=exact_max_requests_per_day, max_states=exact_max_states), "ilp_cpsat": cpsat_factory}
    unknown = sorted(set(solver_names) - set(registry))
    if unknown:
        raise ValueError(f"unknown solver(s): {', '.join(unknown)}")
    solvers = [registry[name]() for name in solver_names]
    output_dir.mkdir(parents=True, exist_ok=True)
    records: list[dict] = []
    commit = _git_commit()
    dirty = _git_dirty()

    for config_path in config_paths:
        config = load_config(config_path)
        for seed in seeds:
            scenario = generate_scenario(config, seed)
            for solver in solvers:
                started = time.perf_counter()
                result = solver.solve(scenario)
                runtime = time.perf_counter() - started
                violations = validate(scenario, result)
                if violations:
                    details = "; ".join(f"{v.code}:{v.entity_id or '-'}:{v.message}" for v in violations)
                    raise RuntimeError(f"{solver.name} produced invalid result for {scenario.name}/{seed}: {details}")
                metrics = calculate_metrics(scenario, result, runtime)
                records.append(
                    {
                        "metadata": {
                            "data_kind": "synthetic",
                            "scenario_name": scenario.name,
                            "config_file": config_path.name,
                            "config_sha256": scenario.config_hash,
                            "seed": seed,
                            "generator_version": scenario.generator_version,
                            "matching_lab_version": __version__,
                            "git_commit": commit,
                            "matching_lab_dirty": dirty,
                            "timestamp_utc": datetime.now(timezone.utc).isoformat(),
                            "solver": solver.name,
                            "solver_version": solver.version,
                            "exact_max_states": exact_max_states if solver.name == "exact_tiny" else None,
                            "exact_max_requests_per_day": exact_max_requests_per_day if solver.name == "exact_tiny" else None,
                            "solver_status": result.diagnostics.get("status") if result.diagnostics else None,
                            "solver_relative_gap": result.diagnostics.get("relative_gap") if result.diagnostics else None,
                            "solver_diagnostics": result.diagnostics,
                            "experiment_config": experiment_metadata,
                        },
                        "scenario": _jsonable(scenario),
                        "result": _jsonable(result),
                        "metrics": metrics,
                    }
                )

    json_path = output_dir / "results.json"
    csv_path = output_dir / "metrics.csv"
    json_path.write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding="utf-8")
    metric_names = sorted({key for record in records for key in record["metrics"]})
    metadata_names = sorted({key for record in records for key in record["metadata"]})
    with csv_path.open("w", newline="", encoding="utf-8") as handle:
        fieldnames = metadata_names + metric_names
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        for record in records:
            writer.writerow({key: json.dumps(value, ensure_ascii=False, sort_keys=True) if isinstance(value, dict) else value
                             for key, value in {**record["metadata"], **record["metrics"]}.items()})
    return records


def _parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    default_configs = sorted((Path(__file__).resolve().parents[2] / "configs").glob("*.yaml"))
    parser = argparse.ArgumentParser(description="Run synthetic BIRGE matching-lab experiments")
    parser.add_argument("--configs", nargs="+", type=Path, default=default_configs)
    parser.add_argument("--seeds", help="comma-separated seeds; overrides experiment config")
    parser.add_argument("--experiment-config", type=Path, help="PLACEHOLDER experiment config with seed count and CP-SAT parameters")
    parser.add_argument("--solvers", nargs="+", choices=["baseline_greedy", "ilp_cpsat"], default=["baseline_greedy"])
    parser.add_argument("--exact", action="store_true", help="add exact_tiny reference for instances with at most 8 active requests per day")
    parser.add_argument("--exact-max-states", type=int, default=100_000, help="maximum exact solver states per day; failure is not an optimum")
    parser.add_argument("--exact-max-requests-per-day", type=int, default=8, help="maximum active requests across all corridors per day")
    parser.add_argument("--output", type=Path, default=Path("results"))
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(argv)
    try:
        options = None
        experiment = load_config(args.experiment_config) if args.experiment_config else None
        if experiment:
            from matching_lab.generator import _unbox
            values = {key: _unbox(value) for key, value in experiment.items() if key != "placeholder_note"}
            count = int(values["seed_count"])
            if count < 1:
                raise ValueError("seed_count must be positive")
            start = int(values["seed_start"])
            seeds = list(range(start, start + count))
            options = {"grid_minutes": int(values["grid_minutes"]), "time_limit_seconds": float(values["time_limit_seconds"]), "workers": int(values["workers"])}
        else:
            seeds = [1, 2, 3]
        if args.seeds is not None:
            seeds = [int(value.strip()) for value in args.seeds.split(",") if value.strip()]
        if not seeds:
            raise ValueError("at least one seed is required")
        solver_names = [*args.solvers, *(["exact_tiny"] if args.exact else [])]
        experiment_metadata = ({"file": str(args.experiment_config), "sha256": _canonical_hash(experiment),
                                "parameters": values, "actual_seeds": seeds} if experiment else None)
        records = run_experiments(args.configs, seeds, args.output, solver_names, args.exact_max_states, args.exact_max_requests_per_day, options, experiment_metadata)
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2

    print("MODEL DATA: all rows are synthetic; placeholders are not calibrated.")
    print(f"Runs: {len(records)}")
    print(f"Raw JSON: {args.output / 'results.json'}")
    print(f"Metrics CSV: {args.output / 'metrics.csv'}")
    columns = ("scenario_name", "seed", "solver", "solver_status", "solver_relative_gap", "active_requests", "assignment_rate", "trip_count", "mean_passengers_per_trip", "trip_lower_bound", "trips_to_lower_bound", "mean_time_deviation_minutes", "mean_distinct_departures_per_template", "max_distinct_departures_per_template", "mean_distinct_drivers_per_template", "max_distinct_drivers_per_template", "runtime_seconds")
    print("\t".join(columns))
    for record in records:
        values = {**record["metadata"], **record["metrics"]}
        print("\t".join(str(values.get(column)) for column in columns))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
