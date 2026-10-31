"""Exact integer-minute reference for tiny daily instances; not the thesis solver."""
from __future__ import annotations

from functools import lru_cache
from itertools import combinations

from matching_lab.model import Assignment, Scenario, SolverResult, Trip


class ExactTiny:
    name = "exact_tiny"
    version = "0.1.0"

    def __init__(self, max_requests_per_day: int = 8, max_states: int = 100_000):
        if max_requests_per_day < 1 or max_states < 1:
            raise ValueError("exact solver limits must be positive")
        self.max_requests_per_day = max_requests_per_day
        self.max_states = max_states

    def solve(self, scenario: Scenario) -> SolverResult:
        active = [r for r in scenario.request_instances if not r.cancelled]
        by_day = {}
        for request in active:
            by_day.setdefault(request.service_date, []).append(request)
        trips, assignments, unassigned = [], [], []
        duration = scenario.trip_duration_minutes
        next_id = 1
        for day, requests in sorted(by_day.items()):
            requests.sort(key=lambda r: r.instance_id)
            if len(requests) > self.max_requests_per_day:
                raise ValueError(f"exact_tiny limit exceeded: {day} has {len(requests)} active requests, maximum {self.max_requests_per_day} per day")
            states = 0

            @lru_cache(maxsize=None)
            def search(mask: int, schedule: tuple):
                nonlocal states
                states += 1
                if states > self.max_states:
                    raise RuntimeError(f"exact_tiny state limit exceeded on {day}: {self.max_states}; no optimum claimed")
                if not mask:
                    return (0, 0, 0, ())
                first = (mask & -mask).bit_length() - 1
                rest = mask & ~(1 << first)
                assigned, runs, deviation, selected = search(rest, schedule)
                best = (assigned, runs, deviation, selected)
                first_req = requests[first]
                compatible = [i for i, r in enumerate(requests) if i != first and mask & (1 << i) and r.corridor_id == first_req.corridor_id]
                for size in range(len(compatible), -1, -1):
                    for others in combinations(compatible, size):
                        group = (first, *others)
                        earliest = max(requests[i].earliest_departure for i in group)
                        latest = min(requests[i].latest_departure for i in group)
                        if earliest > latest:
                            continue
                        group_mask = sum(1 << i for i in group)
                        remaining = mask & ~group_mask
                        for driver in sorted(scenario.drivers, key=lambda d: d.driver_id):
                            if driver.capacity < len(group) or first_req.corridor_id not in driver.corridor_ids:
                                continue
                            minutes = set()
                            for slot in driver.availability:
                                if day.weekday() not in slot.days_of_week:
                                    continue
                                start = max(earliest, slot.start_minute, 0)
                                end = min(latest, slot.end_minute - duration, 1439)
                                minutes.update(range(start, end + 1))
                            minutes = [minute for minute in minutes if all(
                                driver.driver_id != driver_id or minute + duration <= start or end <= minute
                                for driver_id, start, end in schedule
                            )]
                            minutes.sort(key=lambda minute: (sum(abs(minute - requests[i].preferred_departure) for i in group), minute))
                            # With no remaining requests, only the least-cost departure can matter.
                            if not remaining:
                                minutes = minutes[:1]
                            for minute in minutes:
                                new_schedule = tuple(sorted((*schedule, (driver.driver_id, minute, minute + duration))))
                                sub = search(remaining, new_schedule)
                                candidate = (sub[0] + len(group), sub[1] + 1,
                                             sub[2] + sum(abs(minute - requests[i].preferred_departure) for i in group),
                                             ((group, driver.driver_id, minute), *sub[3]))
                                if (-candidate[0], candidate[1], candidate[2]) < (-best[0], best[1], best[2]):
                                    best = candidate
                return best

            result = search((1 << len(requests)) - 1, ())
            assigned_ids = set()
            for group, driver_id, minute in result[3]:
                trip_id = f"exact-{next_id:05d}"
                next_id += 1
                members = tuple(requests[i].instance_id for i in group)
                trips.append(Trip(trip_id, requests[group[0]].corridor_id, day, minute, duration, driver_id, members))
                for i in group:
                    request = requests[i]
                    assigned_ids.add(request.instance_id)
                    assignments.append(Assignment(request.instance_id, trip_id, driver_id, day, abs(minute - request.preferred_departure)))
            unassigned.extend(r.instance_id for r in requests if r.instance_id not in assigned_ids)
        return SolverResult(tuple(trips), tuple(assignments), tuple(sorted(unassigned)))
