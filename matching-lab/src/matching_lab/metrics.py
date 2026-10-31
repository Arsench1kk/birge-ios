"""Metrics for one validated synthetic solver result."""
from __future__ import annotations

from math import ceil
from collections import Counter, defaultdict

from matching_lab.model import Scenario, SolverResult


def _nearest_rank(values: list[int], percentile: float) -> float | None:
    if not values:
        return None
    ordered = sorted(values)
    return float(ordered[max(0, ceil(percentile * len(ordered)) - 1)])


def calculate_metrics(scenario: Scenario, result: SolverResult, runtime_seconds: float) -> dict:
    active = [item for item in scenario.request_instances if not item.cancelled]
    assigned_ids = {assignment.request_instance_id for assignment in result.assignments}
    deviations = [assignment.deviation_minutes for assignment in result.assignments]
    capacity_by_driver = {driver.driver_id: driver.capacity for driver in scenario.drivers}
    capacity_seats = sum(capacity_by_driver.get(trip.driver_id, 0) for trip in result.trips)
    assigned_seats = sum(len(trip.passenger_instance_ids) for trip in result.trips)
    assigned_by_id = {item.instance_id: item for item in active}
    active_by_day_corridor = Counter((item.service_date, item.corridor_id) for item in active)
    max_capacity = max((driver.capacity for driver in scenario.drivers), default=0)
    lower_bound = (sum(ceil(count / max_capacity) for count in active_by_day_corridor.values())
                   if max_capacity else (0 if not active else None))
    trip_by_id = {trip.trip_id: trip for trip in result.trips}
    times_by_template = defaultdict(set)
    drivers_by_template = defaultdict(set)
    for assignment in result.assignments:
        request = assigned_by_id[assignment.request_instance_id]
        times_by_template[request.request_id].add(trip_by_id[assignment.trip_id].departure_minute)
        drivers_by_template[request.request_id].add(assignment.driver_id)
    time_counts = [len(values) for values in times_by_template.values()]
    driver_counts = [len(values) for values in drivers_by_template.values()]
    return {
        "active_requests": len(active),
        "cancelled_requests": sum(item.cancelled for item in scenario.request_instances),
        "assigned_requests": len(assigned_ids),
        "assignment_rate": (len(assigned_ids) / len(active)) if active else None,
        "mean_time_deviation_minutes": (sum(deviations) / len(deviations)) if deviations else None,
        "p95_time_deviation_minutes": _nearest_rank(deviations, 0.95),
        "seat_utilization": (assigned_seats / capacity_seats) if capacity_seats else None,
        "assigned_seats": assigned_seats,
        "capacity_seats": capacity_seats,
        "unresolved_requests": len(set(item.instance_id for item in active) - assigned_ids),
        "assigned_no_shows": sum(
            assigned_by_id[request_id].no_show for request_id in assigned_ids if request_id in assigned_by_id
        ),
        "trip_count": len(result.trips),
        "mean_passengers_per_trip": assigned_seats / len(result.trips) if result.trips else None,
        "trip_lower_bound": lower_bound,
        "trips_to_lower_bound": len(result.trips) / lower_bound if lower_bound and len(assigned_ids) == len(active) else None,
        "assigned_templates": len(time_counts),
        "template_stability": {template: {"distinct_departures": len(times), "distinct_drivers": len(drivers_by_template[template])}
                               for template, times in sorted(times_by_template.items())},
        "mean_distinct_departures_per_template": sum(time_counts) / len(time_counts) if time_counts else None,
        "max_distinct_departures_per_template": max(time_counts) if time_counts else None,
        "mean_distinct_drivers_per_template": sum(driver_counts) / len(driver_counts) if driver_counts else None,
        "max_distinct_drivers_per_template": max(driver_counts) if driver_counts else None,
        "runtime_seconds": runtime_seconds,
    }
