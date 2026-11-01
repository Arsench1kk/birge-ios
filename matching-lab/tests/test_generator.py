from pathlib import Path

from matching_lab.generator import generate_scenario, load_config


ROOT = Path(__file__).resolve().parents[1]


def test_same_seed_and_config_produce_identical_scenario():
    config = load_config(ROOT / "configs" / "medium_density.yaml")
    first = generate_scenario(config, 12345)
    second = generate_scenario(config, 12345)
    assert first == second
    assert first.config_hash == second.config_hash
    assert first.generator_version == second.generator_version


def test_different_seed_changes_generated_scenario():
    config = load_config(ROOT / "configs" / "low_density.yaml")
    assert generate_scenario(config, 1) != generate_scenario(config, 2)


def test_family_scenarios_are_deterministic_and_have_recurring_days():
    from collections import Counter
    from matching_lab.solvers.baseline_greedy import GreedyBaseline
    from matching_lab.validator import validate

    paths = sorted((ROOT / "configs" / "families").glob("*.yaml"))
    assert len(paths) == 8
    for path in paths:
        config = load_config(path)
        scenario = generate_scenario(config, 17)
        assert scenario == generate_scenario(config, 17)
        assert all(2 <= len(request.days_of_week) <= 3 for request in scenario.requests)
        counts = Counter(request.corridor_id for request in scenario.requests)
        assert set(counts.values()) == ({2} if path.name.startswith("low_") else {16})
        assert validate(scenario, GreedyBaseline().solve(scenario)) == []


def test_stage25_supply_levels_are_exact():
    import pytest
    from matching_lab.generator import _unbox
    from matching_lab.supply import supply_ratio
    for path in sorted((ROOT / 'configs/stage25').glob('stage25_*.yaml')):
        config = load_config(path)
        for seed in (1, 19):
            scenario = generate_scenario(config, seed)
            assert supply_ratio(scenario) == pytest.approx(_unbox(config['target_supply_ratio']))
            assert sum(not r.cancelled for r in scenario.request_instances) == 224


def test_structural_multi_corridor_driver_conflicts():
    from collections import Counter
    from matching_lab.validator import validate
    from matching_lab.solvers.baseline_greedy import GreedyBaseline
    from matching_lab.supply import supply_ratio

    for path in sorted((ROOT / 'configs/stage3').glob('*.yaml')):
        scenario = generate_scenario(load_config(path), 7)
        assert scenario == generate_scenario(load_config(path), 7)
        assert len(scenario.requests) == 40
        assert len(scenario.request_instances) == 160
        assert set(Counter(t.passenger_id for t in scenario.requests).values()) == {2}
        assert {r.latest_departure - r.earliest_departure for r in scenario.requests} <= {15, 30, 60}
        assert {d.capacity for d in scenario.drivers} <= {3, 4}
        assert any(len(d.corridor_ids) == 2 for d in scenario.drivers)
        assert supply_ratio(scenario) > 0
        assert validate(scenario, GreedyBaseline().solve(scenario)) == []
        # A single multi-corridor driver's slot has simultaneous eligible demand
        # on both corridors; distinct trips then compete in NoOverlap.
        found = False
        for d in scenario.drivers:
            if len(d.corridor_ids) != 2:
                continue
            for a in scenario.request_instances:
                for b in scenario.request_instances:
                    if a.service_date != b.service_date or a.corridor_id == b.corridor_id:
                        continue
                    for slot in d.availability:
                        lo=max(a.earliest_departure,b.earliest_departure,slot.start_minute)
                        hi=min(a.latest_departure,b.latest_departure,slot.end_minute-scenario.trip_duration_minutes)
                        if a.service_date.weekday() in slot.days_of_week and lo<=hi:
                            found=True; break
                    if found: break
                if found: break
            if found: break
        assert found, path
