"""Constraint-first synthetic greedy baseline with feasible trip retiming."""
from __future__ import annotations
from dataclasses import replace
from matching_lab.model import Assignment, SolverResult, Trip
from matching_lab.validator import validate


def _intersects(a,b,c,d):
    return a < d and c < b


def feasible_departure(scenario, driver, day, requests, trips, excluded_trip=None):
    """Best absolute-deviation minute within every window and a driver slot."""
    lo=max(r.earliest_departure for r in requests); hi=min(r.latest_departure for r in requests)
    if lo>hi:return None
    duration=scenario.trip_duration_minutes
    busy=[t for t in trips if t.trip_id != excluded_trip and t.driver_id==driver.driver_id and t.service_date==day]
    best=None
    for slot in driver.availability:
        if day.weekday() not in slot.days_of_week:continue
        first=max(lo,slot.start_minute);last=min(hi,slot.end_minute-duration)
        for minute in range(first,last+1):
            if any(_intersects(minute,minute+duration,t.departure_minute,t.departure_minute+t.duration_minutes) for t in busy):continue
            score=(sum(abs(minute-r.preferred_departure) for r in requests),abs(2*minute-lo-hi),minute)
            if best is None or score<best:best=score
    return None if best is None else best[-1]


def build_result(scenario,trips):
    by_id={r.instance_id:r for r in scenario.request_instances if not r.cancelled}
    assignments=[];assigned=set()
    for trip in trips:
        for rid in trip.passenger_instance_ids:
            request=by_id[rid];assigned.add(rid)
            assignments.append(Assignment(rid,trip.trip_id,trip.driver_id,trip.service_date,
                                          abs(trip.departure_minute-request.preferred_departure)))
    result=SolverResult(tuple(trips),tuple(assignments),tuple(sorted(set(by_id)-assigned)))
    violations=validate(scenario,result)
    if violations:raise RuntimeError(f'heuristic produced invalid result: {violations}')
    return result


def trip_score(trips,requests):
    return (-sum(len(t.passenger_instance_ids) for t in trips),len(trips),
            sum(abs(t.departure_minute-requests[r].preferred_departure) for t in trips for r in t.passenger_instance_ids))


class BaselineV2:
    name='baseline_v2'
    version='0.1.0'

    def solve(self,scenario):
        requests={r.instance_id:r for r in scenario.request_instances if not r.cancelled}
        drivers={d.driver_id:d for d in scenario.drivers}
        def slot_count(r):
            return sum(r.service_date.weekday() in sl.days_of_week and
                       max(r.earliest_departure,sl.start_minute)<=min(r.latest_departure,sl.end_minute-scenario.trip_duration_minutes)
                       for d in scenario.drivers if r.corridor_id in d.corridor_ids for sl in d.availability)
        ordered=sorted(requests.values(),key=lambda r:(slot_count(r),r.latest_departure-r.earliest_departure,r.service_date,r.instance_id))
        trips=[];used_template=set()
        for req in ordered:
            key=(req.request_id,req.service_date,req.corridor_id)
            if key in used_template:continue
            options=[]
            for index,trip in enumerate(trips):
                if trip.service_date!=req.service_date or trip.corridor_id!=req.corridor_id:continue
                driver=drivers[trip.driver_id]
                if len(trip.passenger_instance_ids)>=driver.capacity:continue
                members=[requests[r] for r in trip.passenger_instance_ids]+[req]
                minute=feasible_departure(scenario,driver,trip.service_date,members,trips,trip.trip_id)
                if minute is not None:
                    deviation=sum(abs(minute-r.preferred_departure) for r in members)
                    options.append(((driver.capacity-len(members),deviation,minute,trip.driver_id,trip.trip_id),index,minute))
            if options:
                _,index,minute=min(options);old=trips[index]
                trips[index]=replace(old,departure_minute=minute,passenger_instance_ids=old.passenger_instance_ids+(req.instance_id,))
                used_template.add(key);continue
            choices=[]
            for driver in scenario.drivers:
                if req.corridor_id not in driver.corridor_ids:continue
                minute=feasible_departure(scenario,driver,req.service_date,[req],trips)
                if minute is not None:choices.append(((driver.capacity-1,abs(minute-req.preferred_departure),minute,driver.driver_id),driver,minute))
            if choices:
                _,driver,minute=min(choices,key=lambda x:x[0]);trip_id=f'v2-{len(trips)+1:06d}'
                trips.append(Trip(trip_id,req.corridor_id,req.service_date,minute,scenario.trip_duration_minutes,driver.driver_id,(req.instance_id,)))
                used_template.add(key)
        return build_result(scenario,trips)
