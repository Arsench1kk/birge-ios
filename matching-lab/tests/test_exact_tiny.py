from dataclasses import replace
from datetime import date

import pytest
from pathlib import Path

from matching_lab.model import Driver, DriverAvailabilitySlot, PassengerRequest, RequestInstance
from matching_lab.solvers.baseline_greedy import GreedyBaseline
from matching_lab.solvers.exact_tiny import ExactTiny
from matching_lab.validator import validate


def overlapping_windows(scenario):
    day = date(2026, 11, 2)
    templates = (
        PassengerRequest("p1", "ab", frozenset({0}), 446, 501, 473),
        PassengerRequest("p2", "ab", frozenset({0}), 498, 551, 524),
    )
    instances = tuple(RequestInstance(p.request_id, p.request_id, "ab", day, p.earliest_departure, p.latest_departure, p.preferred_departure) for p in templates)
    driver = Driver("d1", 2, frozenset({"ab"}), (DriverAvailabilitySlot(frozenset({0}), 400, 600),))
    return replace(scenario, requests=templates, request_instances=instances, drivers=(driver,), trip_duration_minutes=20)


def test_reference_two_overlapping_windows(small_scenario):
    scenario = overlapping_windows(small_scenario)
    baseline = GreedyBaseline().solve(scenario)
    exact = ExactTiny().solve(scenario)
    assert validate(scenario, baseline) == []
    assert validate(scenario, exact) == []
    assert len(baseline.assignments) == len(exact.assignments) == 2
    assert len(baseline.trips) == 2
    assert len(exact.trips) == 1
    assert 498 <= exact.trips[0].departure_minute <= 501
    assert sum(a.deviation_minutes for a in exact.assignments) == 51


def test_exact_handles_insufficient_capacity_and_day_limit(small_scenario):
    scenario = overlapping_windows(small_scenario)
    assert len(ExactTiny().solve(replace(scenario, drivers=())).assignments) == 0
    with pytest.raises(ValueError, match="maximum 1 per day"):
        ExactTiny(max_requests_per_day=1).solve(scenario)
    with pytest.raises(RuntimeError, match="no optimum claimed"):
        ExactTiny(max_states=1).solve(scenario)


def test_exact_matches_independent_minute_enumeration(small_scenario):
    from itertools import product

    for first_window, second_window in [((480, 482, 480), (481, 483, 483)),
                                         ((480, 481, 480), (483, 484, 484)),
                                         ((480, 480, 480), (481, 481, 481))]:
        scenario = overlapping_windows(small_scenario)
        templates = tuple(replace(item, earliest_departure=values[0], latest_departure=values[1], preferred_departure=values[2])
                          for item, values in zip(scenario.requests, (first_window, second_window)))
        instances = tuple(replace(item, earliest_departure=values[0], latest_departure=values[1], preferred_departure=values[2])
                          for item, values in zip(scenario.request_instances, (first_window, second_window)))
        scenario = replace(scenario, requests=templates, request_instances=instances, trip_duration_minutes=2)
        options = [[None, *range(r.earliest_departure, r.latest_departure + 1)] for r in instances]
        scores = []
        for a, b in product(*options):
            if a is not None and b is not None and a != b and abs(a - b) < 2:
                continue  # one driver cannot run overlapping separate trips
            assigned = sum(value is not None for value in (a, b))
            runs = len({value for value in (a, b) if value is not None})
            deviation = sum(abs(value - request.preferred_departure) for value, request in zip((a, b), instances) if value is not None)
            scores.append((-assigned, runs, deviation))
        result = ExactTiny().solve(scenario)
        assert validate(scenario, result) == []
        assert (-len(result.assignments), len(result.trips), sum(a.deviation_minutes for a in result.assignments)) == min(scores)


def test_reference_runner_matches_baseline_and_exact(tmp_path):
    from matching_lab.runner import run_experiments

    config = Path(__file__).resolve().parents[1] / "configs/reference/coincident_windows.yaml"
    rows = run_experiments([config], [17], tmp_path, ["baseline_greedy", "exact_tiny"])
    assert [row["metrics"]["trip_count"] for row in rows] == [1, 1]
    assert [row["metrics"]["trip_lower_bound"] for row in rows] == [1, 1]
    assert [row["metrics"]["assignment_rate"] for row in rows] == [1, 1]
    assert (tmp_path / "results.json").exists()
