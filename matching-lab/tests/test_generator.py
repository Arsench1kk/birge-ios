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
