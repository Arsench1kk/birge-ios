from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path

spec = spec_from_file_location('stage25_report', Path(__file__).resolve().parents[1] / 'scripts/stage25_report.py')
module = module_from_spec(spec)
spec.loader.exec_module(module)


def test_unknown_and_lexicographic_categories_are_separate():
    def row(seed, solver, status, assigned, trips, deviation):
        return {'scenario':'s', 'search_budget_seconds':1, 'seed':seed, 'solver':solver,
                'solver_status':status, 'supply_ratio':0.5, 'metrics':{
                    'assigned_requests':assigned, 'trip_count':trips,
                    'total_time_deviation_minutes':deviation,
                    'mean_passengers_per_trip':1, 'runtime_seconds':1}}
    records=[]
    for seed, candidate in enumerate([(4,3,9), (3,1,9), (3,2,1), (2,1,1), (0,0,0)]):
        records.append(row(seed,'baseline_greedy','BASELINE',3,2,1))
        records.append(row(seed,'ilp_cpsat','UNKNOWN' if seed==4 else 'FEASIBLE',*candidate))
    summary, comparisons=module.summarize(records)
    c=comparisons[0]
    assert [c[k] for k in ('assigned_better','secondary_better','equal','worse','no_solution')] == [1,1,1,1,1]
    assert next(r for r in summary if r['solver']=='ilp_cpsat')['solutions']==4
