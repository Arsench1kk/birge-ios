from dataclasses import replace
from datetime import timedelta

from matching_lab.model import Assignment, Corridor, Driver, PassengerRequest, RequestInstance, SolverResult, Trip
from matching_lab.validator import validate


def result_for(scenario, *, trip_changes=None, request_ids=None, assignment_changes=None, extra_trips=(), extra_assignments=()):
    instance = scenario.request_instances[0]
    driver = scenario.drivers[0]
    trip = Trip(
        "t1", instance.corridor_id, instance.service_date, 480, scenario.trip_duration_minutes,
        driver.driver_id, tuple([instance.instance_id] if request_ids is None else request_ids),
    )
    if trip_changes:
        trip = replace(trip, **trip_changes)
    trips = (trip, *extra_trips)
    assignments = []
    for index, request_id in enumerate(trip.passenger_instance_ids):
        request = next((r for r in scenario.request_instances if r.instance_id == request_id), None)
        pref = request.preferred_departure if request else 480
        assignment = Assignment(request_id, trip.trip_id, trip.driver_id, trip.service_date, abs(trip.departure_minute-pref))
        if assignment_changes and index == 0:
            assignment = replace(assignment, **assignment_changes)
        assignments.append(assignment)
    return SolverResult(tuple(trips), tuple([*assignments, *extra_assignments]), ())


def codes(scenario, result):
    return {violation.code for violation in validate(scenario, result)}


def test_valid_result_has_no_violations(small_scenario):
    assert validate(small_scenario, result_for(small_scenario)) == []


def test_validator_catches_departure_outside_request_window(small_scenario):
    request = replace(small_scenario.request_instances[0], earliest_departure=500, preferred_departure=510)
    scenario = replace(small_scenario, request_instances=(request,))
    result = result_for(scenario)
    assert "time_window" in codes(scenario, result)


def test_validator_catches_capacity_overflow(small_scenario):
    request2 = replace(small_scenario.request_instances[0], instance_id="r2", request_id="request-2")
    scenario = replace(small_scenario, request_instances=(*small_scenario.request_instances, request2), drivers=(replace(small_scenario.drivers[0], capacity=1),))
    result = result_for(scenario, request_ids=[scenario.request_instances[0].instance_id, "r2"])
    assert "capacity" in codes(scenario, result)


def test_validator_catches_overlapping_driver_trips(small_scenario):
    instance2 = replace(small_scenario.request_instances[0], instance_id="r2", request_id="request-2", earliest_departure=490, preferred_departure=500)
    scenario = replace(small_scenario, request_instances=(*small_scenario.request_instances, instance2))
    second_trip = Trip("t2", "ab", instance2.service_date, 500, 45, "d1", ("r2",))
    second_assignment = Assignment("r2", "t2", "d1", instance2.service_date, 0)
    result = result_for(scenario, extra_trips=(second_trip,), extra_assignments=(second_assignment,))
    assert "driver_overlap" in codes(scenario, result)


def test_validator_catches_trip_outside_driver_slot(small_scenario):
    scenario = replace(small_scenario, drivers=(replace(small_scenario.drivers[0], availability=(replace(small_scenario.drivers[0].availability[0], end_minute=500),)),))
    assert "driver_availability" in codes(scenario, result_for(scenario))


def test_validator_catches_driver_without_corridor(small_scenario):
    scenario = replace(small_scenario, drivers=(replace(small_scenario.drivers[0], corridor_ids=frozenset()),))
    assert "driver_corridor" in codes(scenario, result_for(scenario))


def test_validator_catches_request_trip_corridor_mismatch(small_scenario):
    reverse = Corridor("ba", "b", "a")
    driver = replace(small_scenario.drivers[0], corridor_ids=frozenset({"ab", "ba"}))
    scenario = replace(small_scenario, corridors=(*small_scenario.corridors, reverse), drivers=(driver,))
    assert "request_corridor" in codes(scenario, result_for(scenario, trip_changes={"corridor_id": "ba"}))


def test_validator_catches_request_trip_date_mismatch(small_scenario):
    next_week = small_scenario.request_instances[0].service_date + timedelta(days=7)
    result = result_for(small_scenario, trip_changes={"service_date": next_week})
    assert "request_date" in codes(small_scenario, result)


def test_validator_catches_cancelled_request_assignment(small_scenario):
    instance = replace(small_scenario.request_instances[0], cancelled=True)
    scenario = replace(small_scenario, request_instances=(instance,))
    assert "cancelled_request" in codes(scenario, result_for(scenario))


def test_validator_catches_duplicate_assignment(small_scenario):
    duplicate = Assignment("request-1@2026-11-02", "t1", "d1", small_scenario.start_date, 0)
    result = result_for(small_scenario, extra_assignments=(duplicate,))
    assert "duplicate_assignment" in codes(small_scenario, result)


def test_validator_catches_more_than_one_assignment_per_request_day_corridor(small_scenario):
    original = small_scenario.request_instances[0]
    second = replace(original, instance_id="second-occurrence")
    scenario = replace(small_scenario, request_instances=(original, second))
    trip2 = Trip("t2", "ab", original.service_date, 540, 45, "d1", (second.instance_id,))
    assignment2 = Assignment(second.instance_id, "t2", "d1", original.service_date, 60)
    result = result_for(scenario, extra_trips=(trip2,), extra_assignments=(assignment2,))
    assert "request_day_corridor" in codes(scenario, result)


def test_validator_catches_trip_assignment_mismatch(small_scenario):
    result = result_for(small_scenario, extra_assignments=(Assignment("ghost", "t1", "d1", small_scenario.start_date, 0),))
    assert "unknown_assignment_request" in codes(small_scenario, result)


def test_validator_catches_unknown_trip_and_request(small_scenario):
    result = SolverResult((), (Assignment("ghost", "missing", "d1", small_scenario.start_date, 0),), ())
    found = codes(small_scenario, result)
    assert {"unknown_assignment_request", "unknown_assignment_trip"} <= found


def test_validator_catches_invalid_corridor_hub(small_scenario):
    bad = replace(small_scenario.corridors[0], origin_hub_id="missing")
    scenario = replace(small_scenario, corridors=(bad,))
    assert "unknown_hub" in codes(scenario, result_for(scenario))


def test_validator_catches_empty_trip(small_scenario):
    result = result_for(small_scenario, request_ids=[])
    assert "empty_trip" in codes(small_scenario, result)


def test_validator_catches_unknown_trip_driver(small_scenario):
    assert "unknown_driver" in codes(small_scenario, result_for(small_scenario, trip_changes={"driver_id": "missing"}))


def test_validator_catches_unknown_trip_corridor(small_scenario):
    assert "unknown_corridor" in codes(small_scenario, result_for(small_scenario, trip_changes={"corridor_id": "missing"}))


def test_validator_catches_wrong_trip_duration(small_scenario):
    assert "trip_duration" in codes(small_scenario, result_for(small_scenario, trip_changes={"duration_minutes": 30}))


def test_validator_catches_assignment_driver_mismatch(small_scenario):
    assert "assignment_driver" in codes(small_scenario, result_for(small_scenario, assignment_changes={"driver_id": "other"}))


def test_validator_catches_assignment_date_mismatch(small_scenario):
    next_week = small_scenario.start_date + timedelta(days=7)
    assert "assignment_date" in codes(small_scenario, result_for(small_scenario, assignment_changes={"service_date": next_week}))


def test_validator_catches_trip_and_assignment_records_out_of_sync(small_scenario):
    first = small_scenario.request_instances[0]
    second = replace(first, instance_id="r2", request_id="request-2")
    scenario = replace(small_scenario, request_instances=(first, second))
    result = result_for(scenario, request_ids=(first.instance_id, second.instance_id))
    result = replace(result, assignments=result.assignments[:1])
    assert "trip_assignment_mismatch" in codes(scenario, result)


def test_validator_catches_same_hub_corridor(small_scenario):
    corridor = replace(small_scenario.corridors[0], destination_hub_id="a")
    scenario = replace(small_scenario, corridors=(corridor,))
    assert "same_hub_corridor" in codes(scenario, result_for(scenario))


def test_validator_catches_instance_outside_recurring_weekdays(small_scenario):
    tuesday = small_scenario.start_date + timedelta(days=1)
    instance = replace(small_scenario.request_instances[0], service_date=tuesday)
    scenario = replace(small_scenario, request_instances=(instance,))
    result = result_for(scenario, trip_changes={"service_date": tuesday})
    assert "request_weekday" in codes(scenario, result)


def test_validator_requires_every_active_request_classified(small_scenario):
    result = SolverResult((), (), ())
    assert "request_result_partition" in codes(small_scenario, result)


def test_validator_rejects_request_in_both_assigned_and_unassigned(small_scenario):
    valid = result_for(small_scenario)
    result = replace(valid, unassigned_request_instance_ids=(small_scenario.request_instances[0].instance_id,))
    assert "assigned_and_unassigned" in codes(small_scenario, result)
