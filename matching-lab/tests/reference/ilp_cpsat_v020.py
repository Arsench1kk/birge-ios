"""CP-SAT candidate over a finite minute grid. [hypothesis; advisor TBD]."""
from __future__ import annotations

from collections import defaultdict
from datetime import date
from math import isfinite
import time

from matching_lab.model import Assignment, Scenario, SolverResult, Trip


class ILPCPSAT:
    name = "ilp_cpsat"
    version = "0.2.0"

    def __init__(self, *, grid_minutes: int, time_limit_seconds: float, workers: int):
        if not isinstance(grid_minutes, int) or not 1 <= grid_minutes <= 1440:
            raise ValueError("grid_minutes must be an integer in 1..1440")
        if not isfinite(time_limit_seconds) or time_limit_seconds < 0:
            raise ValueError("time_limit_seconds must be finite and nonnegative")
        if not isinstance(workers, int) or workers < 1:
            raise ValueError("workers must be a positive integer")
        self.grid_minutes = grid_minutes
        self.time_limit_seconds = time_limit_seconds
        self.workers = workers

    def solve(self, scenario: Scenario, *, hint_result: SolverResult | None = None) -> SolverResult:
        started = time.perf_counter()
        try:
            import ortools
            from ortools.sat.python import cp_model
        except ImportError as exc:
            raise RuntimeError('ilp_cpsat requires the optional dependency: pip install ".[ilp]"') from exc

        active = sorted((r for r in scenario.request_instances if not r.cancelled), key=lambda r: r.instance_id)
        diagnostics = {"status": "OPTIMAL", "relative_gap": 0.0, "objective_value": 0.0,
                       "best_objective_bound": 0.0, "grid_minutes": self.grid_minutes,
                       "time_limit_seconds": self.time_limit_seconds, "workers": self.workers,
                       "ortools_version": ortools.__version__, "candidate_trips": 0, "assignment_variables": 0}
        if len({r.instance_id for r in active}) != len(active):
            raise ValueError("duplicate active request instance IDs")
        if len({d.driver_id for d in scenario.drivers}) != len(scenario.drivers):
            raise ValueError("duplicate driver IDs")
        if scenario.trip_duration_minutes <= 0 or any(d.capacity <= 0 for d in scenario.drivers):
            raise ValueError("trip duration and driver capacity must be positive")
        if any(not (0 <= r.earliest_departure <= r.preferred_departure <= r.latest_departure <= 1439) for r in active):
            raise ValueError("request windows and preferred times must be valid minutes")
        if not active:
            return SolverResult((), (), (), diagnostics)

        count = len(active)
        max_deviation = 1439 * count
        trip_weight = max_deviation + 1
        unassigned_weight = count * trip_weight + max_deviation + 1
        if count * (unassigned_weight + trip_weight + 1439) >= 2**62:
            raise ValueError("scenario exceeds safe CP-SAT integer objective bounds")

        groups: dict[tuple[date, str], list] = defaultdict(list)
        for request in active:
            groups[(request.service_date, request.corridor_id)].append(request)
        model = cp_model.CpModel()
        xs_by_request = defaultdict(list)
        xs_by_template = defaultdict(list)
        intervals = defaultdict(list)
        candidates = []
        edge_count = 0
        duration = scenario.trip_duration_minutes
        for (day, corridor), requests in sorted(groups.items()):
            minutes = set()
            for request in requests:
                lo, hi = request.earliest_departure, request.latest_departure
                minutes.update(range(((lo + self.grid_minutes - 1) // self.grid_minutes) * self.grid_minutes, hi + 1, self.grid_minutes))
                for base in (lo, hi, request.preferred_departure):
                    for offset in (-self.grid_minutes, 0, self.grid_minutes):
                        minute = base + offset
                        if lo <= minute <= hi:
                            minutes.add(minute)
            if hint_result is not None:
                minutes.update(t.departure_minute for t in hint_result.trips if t.service_date == day and t.corridor_id == corridor)
            for driver in sorted(scenario.drivers, key=lambda item: item.driver_id):
                if corridor not in driver.corridor_ids:
                    continue
                for minute in sorted(minutes):
                    if not any(day.weekday() in slot.days_of_week and slot.start_minute <= minute
                               and minute + duration <= slot.end_minute for slot in driver.availability):
                        continue
                    allowed = [r for r in requests if r.earliest_departure <= minute <= r.latest_departure]
                    if not allowed:
                        continue
                    index = len(candidates)
                    y = model.NewBoolVar(f"trip_{index}")
                    edges = []
                    for request in allowed:
                        x = model.NewBoolVar(f"x_{index}_{len(edges)}")
                        edges.append((request, x))
                        xs_by_request[request.instance_id].append(x)
                        xs_by_template[(request.request_id, day, corridor)].append(x)
                    model.Add(sum(x for _, x in edges) <= driver.capacity * y)
                    model.Add(y <= sum(x for _, x in edges))
                    interval = model.NewOptionalFixedSizeIntervalVar(minute, duration, y, f"interval_{index}")
                    intervals[(day, driver.driver_id)].append(interval)
                    candidates.append((day, corridor, driver.driver_id, minute, y, edges))
                    edge_count += len(edges)
        for interval_group in intervals.values():
            model.AddNoOverlap(interval_group)
        for variables in xs_by_template.values():
            model.Add(sum(variables) <= 1)
        unassigned_vars = []
        for index, request in enumerate(active):
            unassigned = model.NewBoolVar(f"unassigned_{index}")
            model.Add(sum(xs_by_request[request.instance_id]) + unassigned == 1)
            unassigned_vars.append(unassigned)
        if count * (unassigned_weight + trip_weight) + edge_count * 1439 >= 2**62:
            raise ValueError("scenario exceeds safe CP-SAT expression bounds")
        # Hints are optional: the clean mode never invokes the baseline.
        if hint_result is not None:
            from matching_lab.validator import validate
            if validate(scenario, hint_result):
                raise ValueError("warm hint is not a valid solution")
            indices = {(day, corridor, driver_id, minute)
                       for day, corridor, driver_id, minute, _, _ in candidates}
            hint_trips = {(t.service_date, t.corridor_id, t.driver_id, t.departure_minute): t
                          for t in hint_result.trips}
            if not set(hint_trips).issubset(indices):
                raise ValueError("valid warm hint is outside candidate domain")
            hint_assigned = {a.request_instance_id for a in hint_result.assignments}
            for day, corridor, driver_id, minute, y, edges in candidates:
                trip = hint_trips.get((day, corridor, driver_id, minute))
                members = set(trip.passenger_instance_ids) if trip else set()
                model.AddHint(y, int(trip is not None))
                for request, x in edges:
                    model.AddHint(x, int(request.instance_id in members))
            for request, unassigned in zip(active, unassigned_vars):
                model.AddHint(unassigned, int(request.instance_id not in hint_assigned))
        diagnostics["hint"] = "baseline" if hint_result is not None else "none"
        model.Minimize(unassigned_weight * sum(unassigned_vars) + trip_weight * sum(c[4] for c in candidates)
                       + sum(abs(minute - request.preferred_departure) * x
                             for _, _, _, minute, _, edges in candidates for request, x in edges))
        diagnostics.update(candidate_trips=len(candidates), assignment_variables=edge_count)
        diagnostics["variables_total"] = len(model.Proto().variables)
        diagnostics["constraints_total"] = len(model.Proto().constraints)
        diagnostics["build_seconds"] = time.perf_counter() - started
        solver = cp_model.CpSolver()
        solver.parameters.max_time_in_seconds = self.time_limit_seconds
        solver.parameters.num_search_workers = self.workers
        solver.parameters.random_seed = 0
        search_started = time.perf_counter()
        status = solver.Solve(model)
        diagnostics["search_seconds"] = time.perf_counter() - search_started
        status_name = solver.StatusName(status)
        diagnostics["status"] = status_name
        if status_name == "MODEL_INVALID":
            raise RuntimeError(f"invalid CP-SAT model: {solver.ResponseStats()}")
        if status_name not in ("OPTIMAL", "FEASIBLE"):
            diagnostics.update(relative_gap=None, objective_value=None, best_objective_bound=None)
            return SolverResult((), (), tuple(sorted(r.instance_id for r in active)), diagnostics)
        objective = solver.ObjectiveValue()
        bound = solver.BestObjectiveBound()
        diagnostics.update(objective_value=objective, best_objective_bound=bound,
                           relative_gap=max(0.0, (objective - bound) / max(1.0, abs(objective))))
        trips, assignments = [], []
        assigned_ids = set()
        for day, corridor, driver_id, minute, y, edges in candidates:
            if not solver.BooleanValue(y):
                continue
            members = [request for request, x in edges if solver.BooleanValue(x)]
            trip_id = f"cpsat-{len(trips) + 1:05d}"
            trips.append(Trip(trip_id, corridor, day, minute, duration, driver_id, tuple(r.instance_id for r in members)))
            for request in members:
                assigned_ids.add(request.instance_id)
                assignments.append(Assignment(request.instance_id, trip_id, driver_id, day, abs(minute - request.preferred_departure)))
        unassigned = tuple(sorted(r.instance_id for r in active if r.instance_id not in assigned_ids))
        return SolverResult(tuple(trips), tuple(assignments), unassigned, diagnostics)
