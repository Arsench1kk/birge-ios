"""Observe the unchanged stage-2 solver at its CP-SAT boundary."""
import csv
import json
import time
from pathlib import Path

from ortools.sat.python import cp_model
from matching_lab.generator import generate_scenario, load_config
from matching_lab.solvers.ilp_cpsat import ILPCPSAT
from matching_lab.validator import validate

root = Path(__file__).resolve().parents[1]
config = json.loads((root / 'configs/experiments/stage25_diagnostics.json').read_text())
original_solve = cp_model.CpSolver.Solve
observation = {}

def timed_solve(self, model, *args, **kwargs):
    observation['build_seconds'] = time.perf_counter() - observation['started']
    proto = model.Proto()
    observation['variables_total'] = len(proto.variables)
    observation['constraints_total'] = len(proto.constraints)
    start = time.perf_counter()
    try:
        return original_solve(self, model, *args, **kwargs)
    finally:
        observation['search_seconds'] = time.perf_counter() - start

cp_model.CpSolver.Solve = timed_solve
paths = sorted(p for pattern in config['config_globs'] for p in root.glob(pattern))
output = root / 'results/stage25-diagnostics.csv'
output.parent.mkdir(exist_ok=True)
rows = []
for path in paths:
    scenario = generate_scenario(load_config(path), config['seed'])
    observation.clear()
    observation['started'] = time.perf_counter()
    result = ILPCPSAT(grid_minutes=config['grid_minutes'], time_limit_seconds=config['time_limit_seconds'], workers=config['workers']).solve(scenario)
    elapsed = time.perf_counter() - observation['started']
    violations = validate(scenario, result)
    if violations:
        raise RuntimeError(f'{path}: {violations}')
    diag = result.diagnostics
    row = {'config': str(path.relative_to(root)), 'seed': config['seed'],
           'active_requests': sum(not r.cancelled for r in scenario.request_instances),
           'candidate_trips_y': diag['candidate_trips'], 'assignment_x': diag['assignment_variables'],
           'variables_total': observation.get('variables_total', 0), 'constraints_total': observation.get('constraints_total', 0),
           'build_seconds': observation.get('build_seconds', elapsed), 'search_seconds': observation.get('search_seconds', 0),
           'total_seconds': elapsed, 'status': diag['status'], 'hint': diag.get('hint', 'none')}
    rows.append(row)
    with output.open('w', newline='') as handle:
        writer = csv.DictWriter(handle, fieldnames=row.keys())
        writer.writeheader()
        writer.writerows(rows)
    print(json.dumps(row), flush=True)
