"""Run a fixed stage 2.5 protocol, writing each independently validated run."""
import argparse
import json
import subprocess
import time
from pathlib import Path

from matching_lab.generator import _canonical_hash, generate_scenario, load_config
from matching_lab.metrics import calculate_metrics
from matching_lab.solvers.baseline_greedy import GreedyBaseline
from matching_lab.solvers.ilp_cpsat import ILPCPSAT
from matching_lab.solvers.ilp_decomposed import ILPCPSATWarm, ILPCPSATDecomposed
from matching_lab.supply import supply_ratio
from matching_lab.validator import validate

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('phase', choices=['families', 'scale', 'sensitivity'])
parser.add_argument('--output', type=Path, required=True)
parser.add_argument('--family-name', help='run one predeclared family, for distributed execution')
parser.add_argument('--protocol', type=Path, default=root / 'configs/experiments/stage25.json')
args = parser.parse_args()
protocol = json.loads(args.protocol.read_text())
if args.phase == 'families':
    paths = sorted(root.glob(protocol['family_glob']))
    if args.family_name:
        paths = [path for path in paths if path.stem == args.family_name]
        if len(paths) != 1:
            raise ValueError('family name must identify exactly one predefined config')
    seeds = range(protocol['seed_start'], protocol['seed_start'] + protocol['seed_count'])
    budgets = protocol['search_budgets_seconds']
elif args.phase == 'scale':
    paths = [root / p for p in protocol['scale_configs']]
    seeds = protocol['scale_seeds']; budgets = [protocol['scale_budget_seconds']]
else:
    paths = [root / p for p in protocol['sensitivity_configs']]
    seeds = protocol['sensitivity_seeds']; budgets = protocol['sensitivity_budgets_seconds']
commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip()
args.output.parent.mkdir(parents=True, exist_ok=True)
with args.output.open('x', encoding='utf-8') as output:
    for path in paths:
        raw = load_config(path)
        for seed in seeds:
            scenario = generate_scenario(raw, seed)
            for budget in budgets:
                modes = protocol['modes'] if args.phase != 'sensitivity' else ['baseline_greedy', 'ilp_cpsat+warm']
                if args.phase == 'scale':
                    modes = ['baseline_greedy', 'ilp_cpsat+warm', 'ilp_cpsat']
                for mode in modes:
                    opts = dict(grid_minutes=protocol['grid_minutes'], workers=protocol['workers'], time_limit_seconds=budget)
                    solver = (GreedyBaseline() if mode == 'baseline_greedy' else ILPCPSAT(**opts) if mode == 'ilp_cpsat' else ILPCPSATDecomposed(**opts) if mode == 'ilp_cpsat+decomposed' else ILPCPSATWarm(**opts))
                    start = time.perf_counter()
                    result = solver.solve(scenario)
                    elapsed = time.perf_counter() - start
                    violations = validate(scenario, result)
                    if violations:
                        raise RuntimeError(f'{path.name} seed={seed} {mode}: {violations}')
                    diagnostics = result.diagnostics or {}
                    record = {'phase': args.phase, 'scenario': scenario.name, 'config': str(path.relative_to(root)),
                              'config_sha256': scenario.config_hash, 'protocol_sha256': _canonical_hash(protocol),
                              'git_commit': commit, 'seed': seed, 'search_budget_seconds': budget,
                              'solver': mode, 'solver_version': solver.version,
                              'supply_ratio': supply_ratio(scenario), 'solver_status': diagnostics.get('status', 'BASELINE'),
                              'diagnostics': diagnostics, 'metrics': calculate_metrics(scenario, result, elapsed)}
                    output.write(json.dumps(record, ensure_ascii=False) + '\n'); output.flush()
                    print(args.phase, scenario.name, seed, budget, mode, record['solver_status'], f'{elapsed:.3f}s', flush=True)
