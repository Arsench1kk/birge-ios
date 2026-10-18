"""Typed data model shared by generators, solvers, validator, and runner."""
from __future__ import annotations

from dataclasses import dataclass
from datetime import date
from typing import Protocol


@dataclass(frozen=True)
class Hub:
    hub_id: str
    name: str


@dataclass(frozen=True)
class Corridor:
    corridor_id: str
    origin_hub_id: str
    destination_hub_id: str


@dataclass(frozen=True)
class PassengerRequest:
    """A weekly recurring request template; weekday values use ISO Monday=0."""

    request_id: str
    corridor_id: str
    days_of_week: frozenset[int]
    earliest_departure: int
    latest_departure: int
    preferred_departure: int


@dataclass(frozen=True)
class RequestInstance:
    """One date-specific occurrence of a recurring passenger request."""

    instance_id: str
    request_id: str
    corridor_id: str
    service_date: date
    earliest_departure: int
    latest_departure: int
    preferred_departure: int
    cancelled: bool = False
    no_show: bool = False


@dataclass(frozen=True)
class DriverAvailabilitySlot:
    days_of_week: frozenset[int]
    start_minute: int
    end_minute: int


@dataclass(frozen=True)
class Driver:
    driver_id: str
    capacity: int
    corridor_ids: frozenset[str]
    availability: tuple[DriverAvailabilitySlot, ...]


@dataclass(frozen=True)
class Scenario:
    name: str
    seed: int
    config_hash: str
    generator_version: str
    start_date: date
    horizon_days: int
    trip_duration_minutes: int
    hubs: tuple[Hub, ...]
    corridors: tuple[Corridor, ...]
    requests: tuple[PassengerRequest, ...]
    request_instances: tuple[RequestInstance, ...]
    drivers: tuple[Driver, ...]
    cancellation_probability: float
    no_show_probability: float
    source_config: dict


@dataclass(frozen=True)
class Trip:
    trip_id: str
    corridor_id: str
    service_date: date
    departure_minute: int
    duration_minutes: int
    driver_id: str
    passenger_instance_ids: tuple[str, ...]


@dataclass(frozen=True)
class Assignment:
    request_instance_id: str
    trip_id: str
    driver_id: str
    service_date: date
    deviation_minutes: int


@dataclass(frozen=True)
class SolverResult:
    trips: tuple[Trip, ...]
    assignments: tuple[Assignment, ...]
    unassigned_request_instance_ids: tuple[str, ...]


class Solver(Protocol):
    name: str
    version: str

    def solve(self, scenario: Scenario) -> SolverResult: ...
