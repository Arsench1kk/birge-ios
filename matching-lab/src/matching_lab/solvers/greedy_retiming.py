"""Bounded lexicographic local search started from baseline_v2."""
from __future__ import annotations
from dataclasses import replace
from matching_lab.solvers.baseline_v2 import BaselineV2, build_result, feasible_departure, trip_score


class GreedyRetiming:
    name='greedy_retiming'
    version='0.1.0'

    def __init__(self, *, max_iterations, max_neighbor_checks_per_iteration):
        if max_iterations<0 or max_neighbor_checks_per_iteration<1:raise ValueError('invalid local-search limit')
        self.max_iterations=max_iterations;self.max_neighbor_checks_per_iteration=max_neighbor_checks_per_iteration

    def solve(self,scenario):
        initial=BaselineV2().solve(scenario)
        trips=list(initial.trips); req={r.instance_id:r for r in scenario.request_instances if not r.cancelled}
        drivers={d.driver_id:d for d in scenario.drivers}
        for _ in range(self.max_iterations):
            before=trip_score(trips,req);improved=False;checks=0
            # Improve an individual trip's departure without changing its members.
            for i,trip in enumerate(trips):
                minute=feasible_departure(scenario,drivers[trip.driver_id],trip.service_date,[req[x] for x in trip.passenger_instance_ids],trips,trip.trip_id)
                if minute is not None and minute!=trip.departure_minute:
                    candidate=trips.copy();candidate[i]=replace(trip,departure_minute=minute)
                    if trip_score(candidate,req)<before:
                        trips=candidate;improved=True;break
            if improved:continue
            # Reinsert unassigned requests when an existing trip can serve them.
            assigned={x for t in trips for x in t.passenger_instance_ids}
            keys={(req[x].request_id,req[x].service_date,req[x].corridor_id) for x in assigned}
            for rid in sorted(set(req)-assigned):
                r=req[rid]
                if (r.request_id,r.service_date,r.corridor_id) in keys:continue
                for j,dst in enumerate(trips):
                    if checks>=self.max_neighbor_checks_per_iteration:break
                    if dst.service_date!=r.service_date or dst.corridor_id!=r.corridor_id:continue
                    checks+=1;driver=drivers[dst.driver_id]
                    if len(dst.passenger_instance_ids)>=driver.capacity:continue
                    members=[req[x] for x in dst.passenger_instance_ids]+[r]
                    minute=feasible_departure(scenario,driver,dst.service_date,members,trips,dst.trip_id)
                    if minute is not None:
                        candidate=trips.copy();candidate[j]=replace(dst,departure_minute=minute,passenger_instance_ids=dst.passenger_instance_ids+(rid,))
                        if trip_score(candidate,req)<before:trips=candidate;improved=True;break
                if improved or checks>=self.max_neighbor_checks_per_iteration:break
            if improved:continue
            # Move one passenger between compatible trips; closing a trip can reduce trip count.
            for i,src in enumerate(trips):
                for rid in src.passenger_instance_ids:
                    r=req[rid]
                    for dst in trips:
                        if checks>=self.max_neighbor_checks_per_iteration:break
                        if dst.trip_id==src.trip_id or dst.service_date!=src.service_date or dst.corridor_id!=src.corridor_id:continue
                        checks+=1;driver=drivers[dst.driver_id]
                        if len(dst.passenger_instance_ids)>=driver.capacity:continue
                        remain=tuple(x for x in src.passenger_instance_ids if x!=rid)
                        candidate=[replace(t,passenger_instance_ids=remain) if t.trip_id==src.trip_id else t for t in trips if t.trip_id!=src.trip_id or remain]
                        minute=feasible_departure(scenario,driver,dst.service_date,[req[x] for x in dst.passenger_instance_ids]+[r],candidate,dst.trip_id)
                        if minute is None:continue
                        candidate=[replace(t,departure_minute=minute,passenger_instance_ids=t.passenger_instance_ids+(rid,)) if t.trip_id==dst.trip_id else t for t in candidate]
                        if trip_score(candidate,req)<before:trips=candidate;improved=True;break
                    if improved or checks>=self.max_neighbor_checks_per_iteration:break
                if improved or checks>=self.max_neighbor_checks_per_iteration:break
            if not improved:break
        return build_result(scenario,trips)
