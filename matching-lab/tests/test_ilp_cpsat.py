from dataclasses import replace
from datetime import date
import random

import pytest

pytest.importorskip("ortools")

from matching_lab.model import Corridor, Driver, DriverAvailabilitySlot, PassengerRequest, RequestInstance
from matching_lab.solvers.baseline_greedy import GreedyBaseline
from matching_lab.solvers.exact_tiny import ExactTiny
from matching_lab.solvers.ilp_cpsat import ILPCPSAT
from matching_lab.validator import validate


def objective(result):
    return (-len(result.assignments), len(result.trips), sum(a.deviation_minutes for a in result.assignments))


def scenario_for_seed(base, seed):
    rng = random.Random(seed)
    day = date(2026, 11, 2)
    templates = []
    for index in range(rng.randint(1, 3)):
        start = rng.randint(480, 487)
        end = start + rng.randint(1, 5)
        preference = rng.randint(start, end)
        corridor = rng.choice(("ab", "ba"))
        templates.append(PassengerRequest(f"p{index}", corridor, frozenset({0}), start, end, preference))
    instances = tuple(RequestInstance(t.request_id, t.request_id, t.corridor_id, day, t.earliest_departure,
                                      t.latest_departure, t.preferred_departure) for t in templates)
    drivers = tuple(Driver(f"d{i}", rng.randint(1, 2), frozenset({"ab", "ba"}),
                           (DriverAvailabilitySlot(frozenset({0}), 475, 500),))
                    for i in range(rng.randint(1, 2)))
    return replace(base, corridors=(*base.corridors, Corridor("ba", "b", "a")), requests=tuple(templates),
                   request_instances=instances, drivers=drivers, trip_duration_minutes=rng.randint(2, 4))


@pytest.mark.parametrize("seed", range(20))
def test_cpsat_matches_exact_on_twenty_random_cases(small_scenario, seed):
    scenario = scenario_for_seed(small_scenario, seed)
    exact = ExactTiny().solve(scenario)
    result = ILPCPSAT(grid_minutes=1, time_limit_seconds=5, workers=1).solve(scenario)
    assert result.diagnostics["status"] == "OPTIMAL"
    assert validate(scenario, result) == []
    assert objective(result) == objective(exact)


def test_cpsat_overlapping_reference(small_scenario):
    day = date(2026, 11, 2)
    templates = (PassengerRequest("p1", "ab", frozenset({0}), 446, 501, 473),
                 PassengerRequest("p2", "ab", frozenset({0}), 498, 551, 524))
    instances = tuple(RequestInstance(t.request_id, t.request_id, "ab", day, t.earliest_departure,
                                      t.latest_departure, t.preferred_departure) for t in templates)
    driver = Driver("d", 2, frozenset({"ab"}), (DriverAvailabilitySlot(frozenset({0}), 400, 600),))
    scenario = replace(small_scenario, requests=templates, request_instances=instances, drivers=(driver,), trip_duration_minutes=20)
    result = ILPCPSAT(grid_minutes=5, time_limit_seconds=5, workers=1).solve(scenario)
    assert validate(scenario, result) == []
    assert result.diagnostics["status"] == "OPTIMAL"
    assert objective(result) == objective(ExactTiny().solve(scenario)) == (-2, 1, 51)
    assert len(GreedyBaseline().solve(scenario).trips) == 2


def test_zero_time_limit_is_unknown_or_feasible_and_valid(small_scenario):
    scenario = scenario_for_seed(small_scenario, 19)
    result = ILPCPSAT(grid_minutes=1, time_limit_seconds=0, workers=1).solve(scenario)
    assert result.diagnostics["status"] in ("UNKNOWN", "FEASIBLE", "OPTIMAL")
    assert validate(scenario, result) == []
    if result.diagnostics["status"] == "UNKNOWN":
        assert not result.assignments
        assert result.diagnostics["relative_gap"] is None


def test_runner_saves_status_and_rejects_invalid_result(tmp_path, monkeypatch):
    import csv
    from pathlib import Path
    from matching_lab.runner import run_experiments
    from matching_lab.model import SolverResult

    config = Path(__file__).resolve().parents[1] / "configs/reference/coincident_windows.yaml"
    options = {"grid_minutes": 5, "time_limit_seconds": 2, "workers": 1}
    rows = run_experiments([config], [17], tmp_path / "valid", ["ilp_cpsat"], cpsat_options=options)
    assert rows[0]["metadata"]["solver_status"] in ("OPTIMAL", "FEASIBLE")
    with (tmp_path / "valid" / "metrics.csv").open() as handle:
        assert next(csv.DictReader(handle))["solver_status"] == rows[0]["metadata"]["solver_status"]
    monkeypatch.setattr(ILPCPSAT, "solve", lambda self, scenario: SolverResult((), (), ()))
    with pytest.raises(RuntimeError, match="produced invalid result"):
        run_experiments([config], [17], tmp_path / "invalid", ["ilp_cpsat"], cpsat_options=options)
    assert not (tmp_path / "invalid" / "results.json").exists()
    assert not (tmp_path / "invalid" / "metrics.csv").exists()


@pytest.mark.parametrize('seed', range(10))
def test_decomposition_matches_whole_model(small_scenario, seed):
    from datetime import timedelta
    from matching_lab.solvers.ilp_decomposed import ILPCPSATDecomposed

    day_one = scenario_for_seed(small_scenario, seed)
    other_day = day_one.start_date + timedelta(days=7)
    extras = tuple(replace(r, instance_id=f'{r.instance_id}-next', service_date=other_day)
                   for r in day_one.request_instances)
    scenario = replace(day_one, horizon_days=8, request_instances=(*day_one.request_instances, *extras))
    whole = ILPCPSAT(grid_minutes=1, time_limit_seconds=5, workers=1).solve(scenario)
    daily = ILPCPSATDecomposed(grid_minutes=1, time_limit_seconds=5, workers=1).solve(scenario)
    assert whole.diagnostics['status'] == daily.diagnostics['status'] == 'OPTIMAL'
    assert validate(scenario, daily) == []
    assert objective(whole) == objective(daily)


def test_warm_returns_baseline_if_search_has_no_time(small_scenario):
    from matching_lab.solvers.ilp_decomposed import ILPCPSATWarm
    scenario = scenario_for_seed(small_scenario, 12)
    baseline = GreedyBaseline().solve(scenario)
    warm = ILPCPSATWarm(grid_minutes=10, time_limit_seconds=0, workers=1).solve(scenario)
    assert validate(scenario, warm) == []
    assert objective(warm) <= objective(baseline)
    assert warm.diagnostics['status'] == 'FEASIBLE'
    assert warm.diagnostics['fallback_days'] > 0
