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
    assert metrics["trip_count"] == 1
    assert metrics["mean_passengers_per_trip"] == 2
    assert metrics["trip_lower_bound"] == 1
    assert metrics["trips_to_lower_bound"] is None  # not all requests assigned
    assert metrics["mean_distinct_departures_per_template"] == 1
    assert metrics["max_distinct_drivers_per_template"] == 1


def test_template_stability_across_days_and_empty_inputs(small_scenario):
    from datetime import timedelta
    first = small_scenario.request_instances[0]
    second = replace(first, instance_id="second", service_date=first.service_date + timedelta(days=1))
    scenario = replace(small_scenario, request_instances=(first, second))
    trips = (Trip("t1", "ab", first.service_date, 480, 45, "d1", (first.instance_id,)),
             Trip("t2", "ab", second.service_date, 490, 45, "d2", (second.instance_id,)))
    assignments = (Assignment(first.instance_id, "t1", "d1", first.service_date, 0),
                   Assignment(second.instance_id, "t2", "d2", second.service_date, 10))
    metrics = calculate_metrics(scenario, SolverResult(trips, assignments, ()), 0)
    assert metrics["mean_distinct_departures_per_template"] == 2
    assert metrics["max_distinct_drivers_per_template"] == 2
    assert metrics["trip_lower_bound"] == 2
    assert metrics["trips_to_lower_bound"] == 1
    empty = calculate_metrics(replace(scenario, request_instances=(), drivers=()), SolverResult((), (), ()), 0)
    assert empty["trip_lower_bound"] == 0
    assert empty["trips_to_lower_bound"] is None
    assert empty["template_stability"][first.request_id] == {"distinct_departures": 0, "distinct_drivers": 0}
    assert empty["mean_distinct_departures_per_template"] == 0


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


def test_individual_compatibility_respects_corridor_and_slot(small_scenario):
    from dataclasses import replace
    from matching_lab.metrics import compatible_request_fraction
    assert compatible_request_fraction(small_scenario)==1
    driver=replace(small_scenario.drivers[0],corridor_ids=frozenset())
    assert compatible_request_fraction(replace(small_scenario,drivers=(driver,)))==0
