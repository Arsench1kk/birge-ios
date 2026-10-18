"""Metrics for one validated synthetic solver result."""
from __future__ import annotations

from math import ceil

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
        "runtime_seconds": runtime_seconds,
    }
