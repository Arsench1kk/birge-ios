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
