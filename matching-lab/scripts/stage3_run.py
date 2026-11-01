"""Run the preregistered study serially, one validated solver at a time."""
import json
import argparse
import hashlib
import re
import os
import resource
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path

from matching_lab.generator import _canonical_hash, generate_scenario, load_config
from matching_lab.metrics import calculate_metrics
from matching_lab.solvers.baseline_greedy import GreedyBaseline
from matching_lab.solvers.ilp_decomposed import ILPCPSATDecomposed, ILPCPSATWarm
from matching_lab.supply import supply_ratio
from matching_lab.validator import validate

root=Path(__file__).resolve().parents[1]
protocol=json.loads((root/'configs/experiments/stage3.json').read_text())
parser=argparse.ArgumentParser(); parser.add_argument('--resume',action='store_true'); args=parser.parse_args()
registration=(root/'docs/experiments/stage3/preregistration_2026-11-02.md').read_text()
hashes=re.findall(r'\| `([^`]+)` \| `([0-9a-f]{64})` \|',registration)
if len(hashes) != 11:
    raise RuntimeError(f'expected 11 preregistered config hashes, got {len(hashes)}')
registered_hashes=dict(hashes)
for file, expected in hashes:
    actual=hashlib.sha256((root/file).read_bytes()).hexdigest()
    if actual != expected:
        raise RuntimeError(f'preregistered config changed: {file}')
output=root/'results/stage3/runs.jsonl'; output.parent.mkdir(parents=True,exist_ok=True)
completed=set()
if args.resume:
    if not output.exists(): raise RuntimeError('nothing to resume')
    for line in output.read_text().splitlines():
        item=json.loads(line)
        if item['protocol_sha256'] != _canonical_hash(protocol): raise RuntimeError('protocol changed since previous run')
        key=(item['phase'],item['scenario'],item['seed'],item['budget_per_date_seconds'],item['solver'])
        if key in completed: raise RuntimeError(f'duplicate saved result {key}')
        completed.add(key)
commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()

def load_sample():
    # 1/5/15 minute run-queue averages and approximate summed per-process CPU %.
    proc=subprocess.run(['ps','-A','-o','pcpu='],capture_output=True,text=True,check=True)
    return {'loadavg':os.getloadavg(), 'logical_cpus':os.cpu_count(),
            'process_cpu_percent_sum':sum(float(v) for v in proc.stdout.split() if v.replace('.','',1).isdigit())}

def jobs():
    families=sorted((root/'configs/stage3').glob('*.yaml'))
    for path in families:
        for seed in protocol['family_seeds']:
            yield 'families',path,seed,protocol['budget_per_date_seconds'],protocol['family_modes']
    for value in protocol['scale_configs']:
        for seed in protocol['scale_seeds']:
            yield 'scale',root/value,seed,protocol['budget_per_date_seconds'],protocol['family_modes']
    for path in families:
        for seed in protocol['sensitivity_seeds']:
            for budget in protocol['sensitivity_budgets_per_date_seconds']:
                yield 'sensitivity',path,seed,budget,protocol['sensitivity_modes']

with output.open('a' if args.resume else 'x',encoding='utf-8') as handle:
    for phase,path,seed,budget,modes in jobs():
        relative=str(path.relative_to(root))
        if hashlib.sha256(path.read_bytes()).hexdigest() != registered_hashes[relative]:
            raise RuntimeError(f'preregistered config changed during study: {relative}')
        if hashlib.sha256((root/'configs/experiments/stage3.json').read_bytes()).hexdigest() != registered_hashes['configs/experiments/stage3.json']:
            raise RuntimeError('preregistered protocol changed during study')
        scenario=generate_scenario(load_config(path),seed)
        days=len({r.service_date for r in scenario.request_instances if not r.cancelled})
        for mode in modes:
            key=(phase,scenario.name,seed,budget,mode)
            if key in completed:
                continue
            params={'grid_minutes':protocol['grid_minutes'],'workers':protocol['workers'],
                    'time_limit_seconds':budget*days}
            solver=(GreedyBaseline() if mode=='baseline_greedy' else
                    ILPCPSATWarm(**params) if mode=='ilp_cpsat+warm' else ILPCPSATDecomposed(**params))
            before=load_sample(); cpu0=time.process_time(); start=time.perf_counter()
            result=solver.solve(scenario)
            elapsed=time.perf_counter()-start; cpu_seconds=time.process_time()-cpu0
            after=load_sample()
            violations=validate(scenario,result)
            if violations:
                raise RuntimeError(f'{path} seed={seed} mode={mode}: {violations}')
            diag=result.diagnostics or {}
            record={'phase':phase,'scenario':scenario.name,'config':str(path.relative_to(root)),
                    'config_sha256':scenario.config_hash,'protocol_sha256':_canonical_hash(protocol),
                    'git_commit':commit,'timestamp_utc':datetime.now(timezone.utc).isoformat(),
                    'seed':seed,'budget_per_date_seconds':budget,'active_dates':days,'solver':mode,
                    'solver_version':solver.version,'supply_ratio':supply_ratio(scenario),
                    'solver_status':diag.get('status','BASELINE'),'diagnostics':diag,
                    'metrics':calculate_metrics(scenario,result,elapsed),'process_cpu_seconds':cpu_seconds,
                    'machine_before':before,'machine_after':after,
                    'process_max_rss':resource.getrusage(resource.RUSAGE_SELF).ru_maxrss}
            handle.write(json.dumps(record,ensure_ascii=False)+'\n');handle.flush()
            print(phase,scenario.name,seed,budget,mode,record['solver_status'],round(elapsed,3),flush=True)
