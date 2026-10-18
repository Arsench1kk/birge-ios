"""Independent constraint validator. It does not import or call a solver."""
from __future__ import annotations

from dataclasses import dataclass

from matching_lab.model import Scenario, SolverResult


@dataclass(frozen=True)
class Violation:
    code: str
    message: str
    entity_id: str | None = None


def _overlap(start_a: int, end_a: int, start_b: int, end_b: int) -> bool:
    return start_a < end_b and start_b < end_a


def validate(scenario: Scenario, result: SolverResult) -> list[Violation]:
    violations: list[Violation] = []
    request_by_id = {item.instance_id: item for item in scenario.request_instances}
    driver_by_id = {item.driver_id: item for item in scenario.drivers}
    corridor_by_id = {item.corridor_id: item for item in scenario.corridors}
    request_template_by_id = {item.request_id: item for item in scenario.requests}
    hub_ids = {item.hub_id for item in scenario.hubs}
    trip_by_id = {item.trip_id: item for item in result.trips}
    assignment_by_request: dict[str, list] = {}
    assignment_by_trip: dict[str, list] = {}

    if len(trip_by_id) != len(result.trips):
        violations.append(Violation("duplicate_trip_id", "Trip IDs must be unique"))
    for corridor in scenario.corridors:
        if corridor.origin_hub_id not in hub_ids or corridor.destination_hub_id not in hub_ids:
            violations.append(Violation("unknown_hub", "Corridor references an unknown hub", corridor.corridor_id))
        if corridor.origin_hub_id == corridor.destination_hub_id:
            violations.append(Violation("same_hub_corridor", "Corridor endpoints must differ", corridor.corridor_id))

    for trip in result.trips:
        corridor = corridor_by_id.get(trip.corridor_id)
        driver = driver_by_id.get(trip.driver_id)
        if corridor is None:
            violations.append(Violation("unknown_corridor", "Trip references an unknown corridor", trip.trip_id))
        if driver is None:
            violations.append(Violation("unknown_driver", "Trip references an unknown driver", trip.trip_id))
        elif trip.corridor_id not in driver.corridor_ids:
            violations.append(Violation("driver_corridor", "Driver does not serve trip corridor", trip.trip_id))
        if trip.duration_minutes != scenario.trip_duration_minutes:
            violations.append(Violation("trip_duration", "Trip duration differs from scenario duration", trip.trip_id))
        if trip.duration_minutes <= 0 or not 0 <= trip.departure_minute < 1440:
            violations.append(Violation("invalid_trip_time", "Trip departure/duration is invalid", trip.trip_id))
        if not trip.passenger_instance_ids:
            violations.append(Violation("empty_trip", "Trip must contain at least one passenger", trip.trip_id))
        if driver is not None:
            if len(trip.passenger_instance_ids) > driver.capacity:
                violations.append(Violation("capacity", "Trip exceeds driver capacity", trip.trip_id))
            fits_slot = any(
                trip.service_date.weekday() in slot.days_of_week
                and slot.start_minute <= trip.departure_minute
                and trip.departure_minute + trip.duration_minutes <= slot.end_minute
                for slot in driver.availability
            )
            if not fits_slot:
                violations.append(Violation("driver_availability", "Trip is outside driver availability", trip.trip_id))
        for instance_id in trip.passenger_instance_ids:
            request = request_by_id.get(instance_id)
            if request is None:
                violations.append(Violation("unknown_request", "Trip references an unknown request instance", instance_id))
                continue
            if request.cancelled:
                violations.append(Violation("cancelled_request", "Cancelled request cannot be assigned", instance_id))
            if request.service_date != trip.service_date:
                violations.append(Violation("request_date", "Request and trip dates differ", instance_id))
            template = request_template_by_id.get(request.request_id)
            if template is None:
                violations.append(Violation("unknown_request_template", "Request instance references an unknown recurring template", instance_id))
            else:
                if request.service_date.weekday() not in template.days_of_week:
                    violations.append(Violation("request_weekday", "Request instance is outside recurring weekdays", instance_id))
                if template.corridor_id != request.corridor_id:
                    violations.append(Violation("instance_template_corridor", "Request instance corridor differs from template", instance_id))
            if request.corridor_id != trip.corridor_id:
                violations.append(Violation("request_corridor", "Request and trip corridors differ", instance_id))
            if not request.earliest_departure <= trip.departure_minute <= request.latest_departure:
                violations.append(Violation("time_window", "Trip departure is outside request window", instance_id))

    for assignment in result.assignments:
        assignment_by_request.setdefault(assignment.request_instance_id, []).append(assignment)
        assignment_by_trip.setdefault(assignment.trip_id, []).append(assignment)
        request = request_by_id.get(assignment.request_instance_id)
        trip = trip_by_id.get(assignment.trip_id)
        if request is None:
            violations.append(Violation("unknown_assignment_request", "Assignment references unknown request", assignment.request_instance_id))
        if trip is None:
            violations.append(Violation("unknown_assignment_trip", "Assignment references unknown trip", assignment.trip_id))
        if request is None or trip is None:
            continue
        if assignment.driver_id != trip.driver_id:
            violations.append(Violation("assignment_driver", "Assignment driver differs from trip driver", assignment.request_instance_id))
        if assignment.service_date != trip.service_date:
            violations.append(Violation("assignment_date", "Assignment date differs from trip date", assignment.request_instance_id))
        expected_deviation = abs(trip.departure_minute - request.preferred_departure)
        if assignment.deviation_minutes != expected_deviation:
            violations.append(Violation("assignment_deviation", "Assignment deviation is inconsistent", assignment.request_instance_id))

    for request_id, assignments in assignment_by_request.items():
        if len(assignments) > 1:
            violations.append(Violation("duplicate_assignment", "Request is assigned more than once", request_id))
    for trip_id, assignments in assignment_by_trip.items():
        trip = trip_by_id.get(trip_id)
        if trip is not None and sorted(a.request_instance_id for a in assignments) != sorted(trip.passenger_instance_ids):
            violations.append(Violation("trip_assignment_mismatch", "Trip passengers and assignments differ", trip_id))
    for trip in result.trips:
        if trip.trip_id not in assignment_by_trip and trip.passenger_instance_ids:
            violations.append(Violation("missing_assignment", "Trip passenger lacks Assignment record", trip.trip_id))

    unassigned_seen: set[str] = set()
    for request_id in result.unassigned_request_instance_ids:
        request = request_by_id.get(request_id)
        if request is None:
            violations.append(Violation("unknown_unassigned_request", "Unassigned list references unknown request", request_id))
            continue
        if request_id in unassigned_seen:
            violations.append(Violation("duplicate_unassigned_request", "Unassigned request is listed more than once", request_id))
        unassigned_seen.add(request_id)
        if request.cancelled:
            violations.append(Violation("cancelled_unassigned_request", "Cancelled request should not be in active unassigned list", request_id))
        if request_id in assignment_by_request:
            violations.append(Violation("assigned_and_unassigned", "Request is both assigned and unassigned", request_id))
    for request in scenario.request_instances:
        if request.cancelled:
            continue
        assigned = request.instance_id in assignment_by_request
        unassigned = request.instance_id in unassigned_seen
        if assigned == unassigned:
            violations.append(Violation("request_result_partition", "Each active request must be either assigned once or unassigned", request.instance_id))

    by_request_day_corridor: set[tuple] = set()
    for request_id in assignment_by_request:
        request = request_by_id.get(request_id)
        if request is None:
            continue
        key = (request.request_id, request.service_date, request.corridor_id)
        if key in by_request_day_corridor:
            violations.append(Violation("request_day_corridor", "Recurring request assigned more than once on date/corridor", request_id))
        by_request_day_corridor.add(key)

    by_driver: dict[str, list] = {}
    for trip in result.trips:
        if trip.driver_id in driver_by_id:
            by_driver.setdefault(trip.driver_id, []).append(trip)
    for driver_id, trips in by_driver.items():
        trips.sort(key=lambda trip: (trip.service_date, trip.departure_minute, trip.trip_id))
        for index, left in enumerate(trips):
            for right in trips[index + 1 :]:
                if left.service_date != right.service_date:
                    continue
                if _overlap(
                    left.departure_minute,
                    left.departure_minute + left.duration_minutes,
                    right.departure_minute,
                    right.departure_minute + right.duration_minutes,
                ):
                    violations.append(Violation("driver_overlap", "Driver has overlapping trips", driver_id))
    return violations
