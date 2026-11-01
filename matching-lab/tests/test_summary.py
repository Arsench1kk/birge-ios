from matching_lab.summary import summarize


def record(seed, solver, status, assigned, trips, deviation, runtime):
    return {"metadata": {"scenario_name": "synthetic", "seed": seed, "solver": solver, "solver_status": status},
            "metrics": {"assigned_requests": assigned, "trip_count": trips,
                        "total_time_deviation_minutes": deviation, "mean_passengers_per_trip": 2.0,
                        "runtime_seconds": runtime}}


def test_unknown_excluded_and_comparison_is_lexicographic():
    records = [record(1, "baseline_greedy", None, 3, 2, 9, 1),
               record(1, "ilp_cpsat", "OPTIMAL", 3, 1, 20, 2),
               record(2, "baseline_greedy", None, 4, 2, 1, 1),
               record(2, "ilp_cpsat", "UNKNOWN", 0, 0, 0, 4)]
    rows, comparisons = summarize(records)
    ilp = next(row for row in rows if row["solver"] == "ilp_cpsat")
    assert ilp["valid_solutions"] == 1
    assert ilp["assigned_requests_mean"] == 3
    assert ilp["runtime_seconds_mean"] == 3
    assert ilp["runtime_seconds_std"] == 2 ** 0.5
    assert comparisons[0]["ilp_better"] == 1
    assert comparisons[0]["not_comparable"] == 1
