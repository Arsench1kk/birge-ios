"""Date decomposition and independently validated warm-start fallback."""
from __future__ import annotations

from dataclasses import replace

from matching_lab.model import SolverResult
from matching_lab.solvers.baseline_greedy import GreedyBaseline
from matching_lab.solvers.ilp_cpsat import ILPCPSAT
from matching_lab.validator import validate


def score(result):
    return (-len(result.assignments), len(result.trips), sum(a.deviation_minutes for a in result.assignments))


class ILPCPSATDecomposed(ILPCPSAT):
    name = 'ilp_cpsat+decomposed'
    warm = False

    def solve(self, scenario):
        active = [r for r in scenario.request_instances if not r.cancelled]
        days = sorted({r.service_date for r in active})
        baseline = GreedyBaseline().solve(scenario) if self.warm else None
        if baseline is not None and validate(scenario, baseline):
            raise RuntimeError('baseline is not valid; cannot provide a warm guarantee')
        trips, assignments, unassigned = [], [], []
        day_diagnostics = []
        fallback_count = 0
        for day in days:
            occurrences = tuple(r for r in scenario.request_instances if r.service_date == day)
            daily = replace(scenario, request_instances=occurrences)
            day_baseline = None
            if baseline is not None:
                ids = {r.instance_id for r in occurrences}
                day_baseline = SolverResult(tuple(t for t in baseline.trips if t.service_date == day),
                                            tuple(a for a in baseline.assignments if a.service_date == day),
                                            tuple(i for i in baseline.unassigned_request_instance_ids if i in ids))
                if validate(daily, day_baseline):
                    raise RuntimeError(f'baseline partition invalid on {day}')
            daily_solver = ILPCPSAT(grid_minutes=self.grid_minutes,
                                    time_limit_seconds=self.time_limit_seconds / len(days), workers=self.workers)
            result = daily_solver.solve(daily, hint_result=day_baseline)
            if validate(daily, result):
                raise RuntimeError(f'CP-SAT partition invalid on {day}')
            diag = dict(result.diagnostics)
            found = diag['status'] in ('OPTIMAL', 'FEASIBLE')
            use_baseline = day_baseline is not None and (not found or score(day_baseline) < score(result))
            if use_baseline:
                result = day_baseline
                fallback_count += 1
            elif not found:
                # A clean unknown daily result means the global result is unknown.
                day_diagnostics.append({'date': day.isoformat(), **diag, 'selected': 'none'})
                return SolverResult((), (), tuple(sorted(r.instance_id for r in active)),
                                    {'status': 'UNKNOWN', 'relative_gap': None, 'days': day_diagnostics,
                                     'build_seconds': sum(d.get('build_seconds', 0) for d in day_diagnostics),
                                     'search_seconds': sum(d.get('search_seconds', 0) for d in day_diagnostics)})
            day_diagnostics.append({'date': day.isoformat(), **diag, 'selected': 'baseline' if use_baseline else 'cpsat'})
            remap = {}
            for trip in result.trips:
                new_id = f'day-{day.isoformat()}-{trip.trip_id}'
                remap[trip.trip_id] = new_id
                trips.append(replace(trip, trip_id=new_id))
            assignments.extend(replace(a, trip_id=remap[a.trip_id]) for a in result.assignments)
            unassigned.extend(result.unassigned_request_instance_ids)
        optimal = all(d['status'] == 'OPTIMAL' and d['selected'] == 'cpsat' for d in day_diagnostics)
        diagnostics = {'status': 'OPTIMAL' if optimal else 'FEASIBLE', 'relative_gap': 0.0 if optimal else None,
                       'days': day_diagnostics, 'fallback_days': fallback_count,
                       'build_seconds': sum(d.get('build_seconds', 0) for d in day_diagnostics),
                       'search_seconds': sum(d.get('search_seconds', 0) for d in day_diagnostics),
                       'time_limit_seconds': self.time_limit_seconds, 'workers': self.workers,
                       'grid_minutes': self.grid_minutes, 'budget_rule': 'equal_per_active_date'}
        output = SolverResult(tuple(trips), tuple(assignments), tuple(sorted(unassigned)), diagnostics)
        if validate(scenario, output):
            raise RuntimeError('merged date solution invalid')
        if baseline is not None and score(output) > score(baseline):
            raise RuntimeError('warm solution worse than independently validated baseline')
        return output


class ILPCPSATWarm(ILPCPSATDecomposed):
    name = 'ilp_cpsat+warm'
    warm = True
