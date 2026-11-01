"""Synthetic optimistic seat supply over disjoint availability slots."""
from datetime import timedelta


def supply_ratio(scenario):
    demand = sum(not r.cancelled for r in scenario.request_instances)
    if not demand:
        return None
    seats = 0
    for offset in range(scenario.horizon_days):
        day = scenario.start_date + timedelta(days=offset)
        for driver in scenario.drivers:
            slots = sorted((s.start_minute, s.end_minute) for s in driver.availability if day.weekday() in s.days_of_week)
            if any(a[1] > b[0] for a, b in zip(slots, slots[1:])):
                raise ValueError('supply ratio requires non-overlapping driver slots')
            seats += driver.capacity * sum((end - start) // scenario.trip_duration_minutes for start, end in slots)
    return seats / demand
