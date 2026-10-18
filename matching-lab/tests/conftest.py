from datetime import date

import pytest

from matching_lab.model import (
    Corridor,
    Driver,
    DriverAvailabilitySlot,
    Hub,
    PassengerRequest,
    RequestInstance,
    Scenario,
)


@pytest.fixture
def small_scenario():
    service_date = date(2026, 11, 2)  # Monday; dates are synthetic fixtures.
    request = PassengerRequest("request-1", "ab", frozenset({0}), 450, 600, 480)
    instance = RequestInstance("request-1@2026-11-02", "request-1", "ab", service_date, 450, 600, 480)
    return Scenario(
        name="test",
        seed=7,
        config_hash="test-hash",
        generator_version="test",
        start_date=service_date,
        horizon_days=1,
        trip_duration_minutes=45,
        hubs=(Hub("a", "A"), Hub("b", "B")),
        corridors=(Corridor("ab", "a", "b"),),
        requests=(request,),
        request_instances=(instance,),
        drivers=(Driver("d1", 2, frozenset({"ab"}), (DriverAvailabilitySlot(frozenset(range(7)), 400, 700),)),),
        cancellation_probability=0.0,
        no_show_probability=0.0,
        source_config={},
    )
