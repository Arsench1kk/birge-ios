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
    count_min, count_max = map(int, params["passenger_templates_per_week"])
    if count_min < 0 or count_max < count_min:
        raise ValueError("invalid passenger template count range")

    request_count = rng.randint(count_min, count_max)
    requests: list[PassengerRequest] = []
    for index in range(request_count):
        preferred = rng.randint(pref_start, pref_end)
        width = rng.randint(width_min, width_max)
        early_width = width // 2
        earliest = max(0, preferred - early_width)
        latest = min(1439, preferred + (width - early_width))
        corridor = rng.choice(corridors)
        weekday = rng.randrange(7)
        requests.append(
            PassengerRequest(
                request_id=f"request-{index + 1:04d}",
                corridor_id=corridor.corridor_id,
                days_of_week=frozenset({weekday}),
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
