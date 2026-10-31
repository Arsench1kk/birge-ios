from dataclasses import replace
from pathlib import Path

from matching_lab.generator import generate_scenario, load_config
from matching_lab.metrics import calculate_metrics
from matching_lab.model import Assignment, Driver, DriverAvailabilitySlot, RequestInstance, SolverResult, Trip
from matching_lab.solvers.baseline_greedy import GreedyBaseline, _slot_candidates
from matching_lab.validator import validate

ROOT = Path(__file__).resolve().parents[1]

def test_baseline_finds_free_time_when_preferred_conflicts():
    from datetime import date
    day = date(2026, 10, 19)
    driver = Driver("d", 1, frozenset({"a", "b"}), (DriverAvailabilitySlot(frozenset({0}), 480, 600),))
    request = RequestInstance("r", "r", "b", day, 510, 570, 510)
    existing = Trip("t", "a", day, 510, 30, "d", ("other",))
    assert _slot_candidates(driver, request, 30, [existing])[0][1] == 540


def test_baseline_is_valid_on_twenty_generated_scenarios():
    solver = GreedyBaseline()
    for config_path in sorted((ROOT / "configs").glob("*.yaml")):
        config = load_config(config_path)
        for seed in range(20):
            scenario = generate_scenario(config, seed)
            result = solver.solve(scenario)
            assert validate(scenario, result) == [], (config_path.name, seed)


def test_metrics_on_manual_example(small_scenario):
    instances = list(small_scenario.request_instances)
    first = instances[0]
    second = replace(first, instance_id="r2", request_id="request-2", preferred_departure=500)
    third = replace(first, instance_id="r3", request_id="request-3")
    cancelled = replace(first, instance_id="r4", request_id="request-4", cancelled=True)
    scenario = replace(small_scenario, request_instances=(first, second, third, cancelled), drivers=(replace(small_scenario.drivers[0], capacity=4),))
    trip = Trip("t1", "ab", first.service_date, 490, 45, "d1", (first.instance_id, second.instance_id))
    assignments = (
        Assignment(first.instance_id, "t1", "d1", first.service_date, 10),
        Assignment(second.instance_id, "t1", "d1", first.service_date, 10),
    )
    result = SolverResult((trip,), assignments, (third.instance_id,))
    metrics = calculate_metrics(scenario, result, 0.25)
    assert metrics["assignment_rate"] == 2 / 3
    assert metrics["mean_time_deviation_minutes"] == 10
    assert metrics["p95_time_deviation_minutes"] == 10
    assert metrics["seat_utilization"] == 0.5
    assert metrics["unresolved_requests"] == 1
    assert metrics["cancelled_requests"] == 1
    assert metrics["runtime_seconds"] == 0.25


def test_invalid_stub_solver_result_is_rejected_by_validator(small_scenario):
    class BadStubSolver:
        name = "bad_stub"
        version = "test"

        def solve(self, scenario):
            request = scenario.request_instances[0]
            trip = Trip("bad", request.corridor_id, request.service_date, 700, 45, "d1", (request.instance_id,))
            assignment = Assignment(request.instance_id, "bad", "d1", request.service_date, abs(700-request.preferred_departure))
            return SolverResult((trip,), (assignment,), ())

    result = BadStubSolver().solve(small_scenario)
    assert "time_window" in {item.code for item in validate(small_scenario, result)}
