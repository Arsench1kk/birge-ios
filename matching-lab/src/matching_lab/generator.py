"""Deterministic YAML-to-synthetic-scenario generation."""
from __future__ import annotations

import hashlib
import json
import random
from datetime import date, timedelta
from pathlib import Path
from typing import Any

import yaml

from matching_lab import GENERATOR_VERSION
from matching_lab.model import (
    Corridor,
    Driver,
    DriverAvailabilitySlot,
    Hub,
    PassengerRequest,
    RequestInstance,
    Scenario,
)

PLACEHOLDER = "PLACEHOLDER: не откалибровано, согласовать с руководителем"


def _unbox(value: Any) -> Any:
    if isinstance(value, dict) and set(value) >= {"value", "status"}:
        if value["status"] != PLACEHOLDER:
            raise ValueError(f"unsupported parameter status: {value['status']!r}")
        return value["value"]
    return value


def _canonical_hash(raw: dict) -> str:
    normalized = json.dumps(raw, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(normalized.encode("utf-8")).hexdigest()


def _time_to_minute(value: str) -> int:
    try:
        hour, minute = (int(part) for part in value.split(":"))
    except (ValueError, AttributeError) as exc:
        raise ValueError(f"invalid HH:MM time {value!r}") from exc
    if not (0 <= hour < 24 and 0 <= minute < 60):
        raise ValueError(f"invalid HH:MM time {value!r}")
    return hour * 60 + minute


def load_config(path: str | Path) -> dict:
    with Path(path).open(encoding="utf-8") as handle:
        raw = yaml.safe_load(handle)
    if not isinstance(raw, dict) or raw.get("placeholder_note") != PLACEHOLDER:
        raise ValueError(f"{path}: missing placeholder_note {PLACEHOLDER!r}")
    return raw


def generate_scenario(config: dict, seed: int) -> Scenario:
    """Generate a repeatable scenario from config and seed."""
    if config.get("placeholder_note") != PLACEHOLDER:
        raise ValueError(f"config must declare {PLACEHOLDER!r}")
    rng = random.Random(seed)
    params = {key: _unbox(value) for key, value in config.items() if key != "placeholder_note"}
    start_date = date.fromisoformat(str(params["start_date"]))
    horizon_days = int(params["horizon_days"])
    if horizon_days <= 0:
        raise ValueError("horizon_days must be positive")

    hubs = tuple(Hub(str(item["id"]), str(item["name"])) for item in params["hubs"])
    corridors = tuple(
        Corridor(str(item["id"]), str(item["origin"]), str(item["destination"]))
        for item in params["corridors"]
    )
    if not hubs or not corridors:
        raise ValueError("config needs at least one hub and one corridor")

    windows = params["request_windows"]
    pref_start = _time_to_minute(windows["preferred_start"])
    pref_end = _time_to_minute(windows["preferred_end"])
    width_min, width_max = map(int, windows["width_minutes"])
    if width_min <= 0 or width_max < width_min:
        raise ValueError("invalid request window width range")
    def count_range(value, label):
        low, high = map(int, value)
        if low < 0 or high < low:
            raise ValueError(f"invalid {label} range")
        return low, high

    per_corridor = params.get("passenger_templates_per_corridor")
    if per_corridor is not None:
        low, high = count_range(per_corridor, "templates per corridor")
        planned_corridors = [corridor for corridor in corridors for _ in range(rng.randint(low, high))]
    else:
        low, high = count_range(params["passenger_templates_per_week"], "passenger template count")
        planned_corridors = [None] * rng.randint(low, high)

    days_range = params.get("days_per_week")
    if days_range is not None:
        day_min, day_max = count_range(days_range, "days per week")
        if not 1 <= day_min <= day_max <= 7:
            raise ValueError("days per week must be within 1..7")
        weekday_pool = tuple(int(day) for day in params.get("weekday_pool", range(7)))
        if len(set(weekday_pool)) != len(weekday_pool) or any(day < 0 or day > 6 for day in weekday_pool) or day_max > len(weekday_pool):
            raise ValueError("weekday pool must contain enough distinct days in 0..6")
    peak = params.get("demand_peak")
    if peak is not None:
        peak_minute = _time_to_minute(peak["center"])
        peak_radius = int(peak["radius_minutes"])
        peak_probability = float(peak["probability"])
        if peak_radius < 0 or not 0 <= peak_probability <= 1 or not pref_start <= peak_minute <= pref_end:
            raise ValueError("invalid demand peak")
    requests: list[PassengerRequest] = []
    for index, planned_corridor in enumerate(planned_corridors):
        if peak is not None and rng.random() < peak_probability:
            preferred = rng.randint(max(pref_start, peak_minute - peak_radius), min(pref_end, peak_minute + peak_radius))
        else:
            preferred = rng.randint(pref_start, pref_end)
        width = rng.randint(width_min, width_max)
        early_width = width // 2
        earliest = max(0, preferred - early_width)
        latest = min(1439, preferred + (width - early_width))
        corridor = planned_corridor or rng.choice(corridors)
        days = (frozenset(rng.sample(weekday_pool, rng.randint(day_min, day_max)))
                if days_range is not None else frozenset({rng.randrange(7)}))
        requests.append(
            PassengerRequest(
                request_id=f"request-{index + 1:04d}",
                corridor_id=corridor.corridor_id,
                days_of_week=days,
                earliest_departure=earliest,
                latest_departure=latest,
                preferred_departure=preferred,
            )
        )

    cancel_probability = float(params["cancellation_probability"])
    no_show_probability = float(params["no_show_probability"])
    for label, probability in (("cancellation", cancel_probability), ("no-show", no_show_probability)):
        if not 0.0 <= probability <= 1.0:
            raise ValueError(f"{label}_probability must be in [0, 1]")

    instances: list[RequestInstance] = []
    for request in requests:
        for day_offset in range(horizon_days):
            service_date = start_date + timedelta(days=day_offset)
            if service_date.weekday() not in request.days_of_week:
                continue
            cancelled = rng.random() < cancel_probability
            no_show = (not cancelled) and rng.random() < no_show_probability
            instances.append(
                RequestInstance(
                    instance_id=f"{request.request_id}@{service_date.isoformat()}",
                    request_id=request.request_id,
                    corridor_id=request.corridor_id,
                    service_date=service_date,
                    earliest_departure=request.earliest_departure,
                    latest_departure=request.latest_departure,
                    preferred_departure=request.preferred_departure,
                    cancelled=cancelled,
                    no_show=no_show,
                )
            )

    driver_cfg = params["drivers"]
    driver_count = int(driver_cfg["count"])
    capacity_min, capacity_max = map(int, driver_cfg["capacity_range"])
    if driver_count < 0 or capacity_min <= 0 or capacity_max < capacity_min:
        raise ValueError("invalid driver count/capacity configuration")
    slot_values = tuple(
        DriverAvailabilitySlot(
            days_of_week=frozenset(range(7)),
            start_minute=_time_to_minute(slot["start"]),
            end_minute=_time_to_minute(slot["end"]),
        )
        for slot in driver_cfg["daily_slots"]
    )
    corridor_ids = frozenset(c.corridor_id for c in corridors)
    drivers = tuple(
        Driver(
            driver_id=f"driver-{index + 1:04d}",
            capacity=rng.randint(capacity_min, capacity_max),
            corridor_ids=corridor_ids,
            availability=slot_values,
        )
        for index in range(driver_count)
    )

    duration = int(params["trip_duration_minutes"])
    if duration <= 0:
        raise ValueError("trip_duration_minutes must be positive")
    return Scenario(
        name=str(params["name"]),
        seed=seed,
        config_hash=_canonical_hash(config),
        generator_version=GENERATOR_VERSION,
        start_date=start_date,
        horizon_days=horizon_days,
        trip_duration_minutes=duration,
        hubs=hubs,
        corridors=corridors,
        requests=tuple(requests),
        request_instances=tuple(instances),
        drivers=drivers,
        cancellation_probability=cancel_probability,
        no_show_probability=no_show_probability,
        source_config=config,
    )
