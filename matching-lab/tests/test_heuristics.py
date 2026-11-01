from pathlib import Path
import pytest
from matching_lab.generator import generate_scenario, load_config
from matching_lab.solvers.baseline_v2 import BaselineV2
from matching_lab.solvers.greedy_retiming import GreedyRetiming
from matching_lab.validator import validate

ROOT=Path(__file__).resolve().parents[1]

def score(r):
    return (-len(r.assignments),len(r.trips),sum(a.deviation_minutes for a in r.assignments))

@pytest.mark.parametrize('path',sorted((ROOT/'configs/stage3').glob('*.yaml')))
def test_heuristics_are_valid_and_retiming_never_worse_on_dev(path):
    scenario=generate_scenario(load_config(path),1000)
    base=BaselineV2().solve(scenario)
    local=GreedyRetiming(max_iterations=20,max_neighbor_checks_per_iteration=2000).solve(scenario)
    assert validate(scenario,base)==[]
    assert validate(scenario,local)==[]
    assert score(local)<=score(base)
    assert base==BaselineV2().solve(scenario)

def test_zero_iterations_equals_baseline_v2(small_scenario):
    assert GreedyRetiming(max_iterations=0,max_neighbor_checks_per_iteration=1).solve(small_scenario)==BaselineV2().solve(small_scenario)


def test_local_search_merges_compatible_trips(small_scenario, monkeypatch):
    from dataclasses import replace
    from matching_lab.model import Driver, DriverAvailabilitySlot, PassengerRequest, RequestInstance, Trip
    from matching_lab.solvers.baseline_v2 import build_result
    day=small_scenario.start_date
    templates=tuple(PassengerRequest(f'p{i}','ab',frozenset({0}),480,510,490) for i in (1,2))
    instances=tuple(RequestInstance(t.request_id,t.request_id,'ab',day,480,510,490) for t in templates)
    driver=Driver('driver',2,frozenset({'ab'}),(DriverAvailabilitySlot(frozenset({0}),470,530),))
    scenario=replace(small_scenario,requests=templates,request_instances=instances,drivers=(driver,),trip_duration_minutes=10)
    trips=(Trip('t1','ab',day,480,10,'driver',('p1',)),Trip('t2','ab',day,490,10,'driver',('p2',)))
    initial=build_result(scenario,trips)
    monkeypatch.setattr(BaselineV2,'solve',lambda self, _:initial)
    result=GreedyRetiming(max_iterations=20,max_neighbor_checks_per_iteration=2000).solve(scenario)
    assert validate(scenario,result)==[]
    assert len(result.trips)==1
    assert len(result.assignments)==2
