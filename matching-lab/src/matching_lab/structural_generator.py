"""Stage 3 synthetic assumptions; no calibration to real commute observations."""
from __future__ import annotations

import random
from datetime import date, timedelta

from matching_lab import GENERATOR_VERSION
from matching_lab.generator import _canonical_hash, _time_to_minute
from matching_lab.model import Corridor, Driver, DriverAvailabilitySlot, Hub, PassengerRequest, RequestInstance, Scenario


def generate_structural(config, params, seed):
    rng = random.Random(seed)
    start = date.fromisoformat(str(params['start_date']))
    horizon = int(params['horizon_days'])
    duration = int(params['trip_duration_minutes'])
    spec = params['structural']
    people = int(spec['passenger_count'])
    weekdays = list(map(int, spec['weekday_pool']))
    repeats = int(spec['days_per_template'])
    sigma = float(spec['preferred_sigma_minutes'])
    widths = list(map(int, spec['window_width_choices_minutes']))
    shifts = list(map(int, spec['driver_jitter_minutes']))
    if horizon <= 0 or duration <= 0 or people <= 0 or not 1 <= repeats <= len(weekdays) or sigma <= 0 or not widths or min(widths) <= 0:
        raise ValueError('invalid structural scenario parameters')
    if len(set(weekdays)) != len(weekdays) or any(d not in range(7) for d in weekdays) or not shifts:
        raise ValueError('invalid weekday pool or jitter')
    corridors = tuple(Corridor(str(c['id']), str(c['origin']), str(c['destination'])) for c in params['corridors'])
    hubs = tuple(Hub(str(h['id']), str(h['name'])) for h in params['hubs'])
    if len(corridors) != 2:
        raise ValueError('structural scenario needs two corridors')
    templates = []
    for i in range(people):
        outbound = rng.randrange(2)
        for period, center, corridor in (('morning', spec['morning_peak'], corridors[outbound]),
                                          ('evening', spec['evening_peak'], corridors[1-outbound])):
            pref = max(0, min(1439, round(rng.gauss(_time_to_minute(center), sigma))))
            width = rng.choice(widths)
            days = frozenset(rng.sample(weekdays, repeats))
            templates.append(PassengerRequest(f'passenger-{i+1:04d}-{period}', corridor.corridor_id, days,
                                              max(0, pref-width//2), min(1439, pref+width-width//2), pref,
                                              passenger_id=f'passenger-{i+1:04d}'))
    instances=[]
    for template in templates:
        for offset in range(horizon):
            day=start+timedelta(days=offset)
            if day.weekday() in template.days_of_week:
                instances.append(RequestInstance(f'{template.request_id}@{day.isoformat()}', template.request_id,
                                                 template.corridor_id, day, template.earliest_departure,
                                                 template.latest_departure, template.preferred_departure))
    driver_cfg=params['drivers']; count=int(driver_cfg['count']); caps=list(map(int,driver_cfg['capacity_choices']))
    if count < 1 or not caps or min(caps)<1:
        raise ValueError('invalid structural driver configuration')
    all_ids=frozenset(c.corridor_id for c in corridors)
    drivers=[]
    for i in range(count):
        jitter=rng.choice(shifts)
        slots=[]
        for slot in driver_cfg['daily_slots']:
            lo=_time_to_minute(slot['start'])+jitter; hi=_time_to_minute(slot['end'])+jitter
            if not 0 <= lo < hi <= 1440:
                raise ValueError('driver slot outside day')
            slots.append(DriverAvailabilitySlot(frozenset(weekdays),lo,hi))
        ordered=sorted(slots,key=lambda s:s.start_minute)
        if any(a.end_minute>b.start_minute for a,b in zip(ordered,ordered[1:])):
            raise ValueError('driver slots overlap')
        served=all_ids if i < (count+1)//2 else frozenset({corridors[i%2].corridor_id})
        drivers.append(Driver(f'driver-{i+1:04d}',rng.choice(caps),served,tuple(slots)))
    return Scenario(str(params['name']),seed,_canonical_hash(config),GENERATOR_VERSION+'+structural1',start,horizon,
                    duration,hubs,corridors,tuple(templates),tuple(instances),tuple(drivers),0.0,0.0,config)
