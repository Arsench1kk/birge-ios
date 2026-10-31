"""Deterministic, fixed-order greedy baseline described in docs/stand_design.md."""
from __future__ import annotations

from datetime import date

from matching_lab.model import (
    Assignment,
    Driver,
    DriverAvailabilitySlot,
    RequestInstance,
    Scenario,
    SolverResult,
    Trip,
)


def _intersects(start_a: int, end_a: int, start_b: int, end_b: int) -> bool:
    return start_a < end_b and start_b < end_a


def _driver_conflicts(
    driver_id: str,
    service_date: date,
    departure: int,
    duration: int,
    trips: list[Trip],
) -> bool:
    end = departure + duration
    return any(
        trip.driver_id == driver_id
        and trip.service_date == service_date
        and _intersects(departure, end, trip.departure_minute, trip.departure_minute + trip.duration_minutes)
        for trip in trips
    )


def _slot_candidates(
    driver: Driver,
    request: RequestInstance,
    duration: int,
    trips: list[Trip],
) -> list[tuple[tuple, int, DriverAvailabilitySlot]]:
    candidates = []
    weekday = request.service_date.weekday()
    for slot in driver.availability:
        if weekday not in slot.days_of_week or slot.end_minute - slot.start_minute < duration:
            continue
        earliest = max(request.earliest_departure, slot.start_minute)
        latest = min(request.latest_departure, slot.end_minute - duration)
        if earliest > latest:
            continue
        feasible = (minute for minute in range(earliest, latest + 1)
                    if not _driver_conflicts(driver.driver_id, request.service_date, minute, duration, trips))
        departure = min(feasible, key=lambda minute: (abs(minute - request.preferred_departure), minute), default=None)
        if departure is None:
            continue
        rank = (abs(departure - request.preferred_departure), departure, driver.driver_id, slot.start_minute)
        candidates.append((rank, departure, slot))
    return candidates


class GreedyBaseline:
    name = "baseline_greedy"
    version = "0.2.0"

    def solve(self, scenario: Scenario) -> SolverResult:
        active = [instance for instance in scenario.request_instances if not instance.cancelled]
        ordered = sorted(
            active,
            key=lambda request: (
                request.earliest_departure,
                request.preferred_departure,
                request.service_date,
                request.corridor_id,
                request.request_id,
                request.instance_id,
            ),
        )
        drivers = {driver.driver_id: driver for driver in scenario.drivers}
        trips: list[Trip] = []
        assignments: list[Assignment] = []
        unassigned: list[str] = []
        next_trip = 1

        for request in ordered:
            compatible = []
            for trip in trips:
                if trip.service_date != request.service_date or trip.corridor_id != request.corridor_id:
                    continue
                driver = drivers[trip.driver_id]
                if len(trip.passenger_instance_ids) >= driver.capacity:
                    continue
                if not request.earliest_departure <= trip.departure_minute <= request.latest_departure:
                    continue
                compatible.append(
                    (
                        (abs(trip.departure_minute - request.preferred_departure), trip.departure_minute, trip.driver_id, trip.trip_id),
                        trip,
                    )
                )
            if compatible:
                _, chosen = min(compatible, key=lambda candidate: candidate[0])
                replacement = Trip(
                    trip_id=chosen.trip_id,
                    corridor_id=chosen.corridor_id,
                    service_date=chosen.service_date,
                    departure_minute=chosen.departure_minute,
                    duration_minutes=chosen.duration_minutes,
                    driver_id=chosen.driver_id,
                    passenger_instance_ids=chosen.passenger_instance_ids + (request.instance_id,),
                )
                trips[trips.index(chosen)] = replacement
                assignments.append(
                    Assignment(
                        request_instance_id=request.instance_id,
                        trip_id=chosen.trip_id,
                        driver_id=chosen.driver_id,
                        service_date=request.service_date,
                        deviation_minutes=abs(chosen.departure_minute - request.preferred_departure),
                    )
                )
                continue

            candidates = []
            for driver in scenario.drivers:
                if request.corridor_id not in driver.corridor_ids:
                    continue
                candidates.extend(
                    (rank, departure, driver, slot)
                    for rank, departure, slot in _slot_candidates(
                        driver, request, scenario.trip_duration_minutes, trips
                    )
                )
            if not candidates:
                unassigned.append(request.instance_id)
                continue
            _, departure, driver, _slot = min(candidates, key=lambda candidate: candidate[0])
            trip_id = f"trip-{next_trip:05d}"
            next_trip += 1
            trips.append(
                Trip(
                    trip_id=trip_id,
                    corridor_id=request.corridor_id,
                    service_date=request.service_date,
                    departure_minute=departure,
                    duration_minutes=scenario.trip_duration_minutes,
                    driver_id=driver.driver_id,
                    passenger_instance_ids=(request.instance_id,),
                )
            )
            assignments.append(
                Assignment(
                    request_instance_id=request.instance_id,
                    trip_id=trip_id,
                    driver_id=driver.driver_id,
                    service_date=request.service_date,
                    deviation_minutes=abs(departure - request.preferred_departure),
                )
            )

        return SolverResult(
            trips=tuple(trips),
            assignments=tuple(assignments),
            unassigned_request_instance_ids=tuple(sorted(unassigned)),
        )
