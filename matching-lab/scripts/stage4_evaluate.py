"""Fixed evaluation seeds; heuristics are verified against dev-freeze hashes."""
import argparse,hashlib,json,os,re,subprocess,time
from collections import Counter
from pathlib import Path
from matching_lab.generator import _canonical_hash, generate_scenario,load_config
from matching_lab.metrics import calculate_metrics,compatible_request_fraction
from matching_lab.solvers.baseline_greedy import GreedyBaseline
from matching_lab.solvers.baseline_v2 import BaselineV2
from matching_lab.solvers.greedy_retiming import GreedyRetiming
from matching_lab.solvers.ilp_decomposed import ILPCPSATWarm
from matching_lab.stage4_scale import make_scale
from matching_lab.supply import supply_ratio
from matching_lab.validator import validate
root=Path(__file__).resolve().parents[1]
p=json.loads((root/'configs/experiments/stage4.json').read_text())
ap=argparse.ArgumentParser();ap.add_argument('--phase',choices=['families','scale'],required=True);ap.add_argument('--resume',action='store_true');args=ap.parse_args()
registration=(root/'docs/experiments/stage4/preregistration.md').read_text()
registered=dict(re.findall(r'\| `([^`]+)` \| `([0-9a-f]{64})` \|',registration))
freeze=(root/'docs/experiments/stage4/dev_freeze.md').read_text()
frozen=dict(re.findall(r'\| `([^`]+)` \| `([0-9a-f]{64})` \|',freeze))
for path,expected in {**registered,**frozen}.items():
 if hashlib.sha256((root/path).read_bytes()).hexdigest()!=expected:raise RuntimeError(f'preregistered or frozen file changed: {path}')
if set(p['dev_seeds']) & set(p['evaluation_seeds']):raise ValueError('dev/evaluation seed overlap')
if args.phase=='families':
 configs=sorted((root/'configs/stage3').glob('*.yaml'));seeds=p['evaluation_seeds']
 stage3=[json.loads(line) for line in (root/'results/stage3/runs.jsonl').read_text().splitlines()]
 cached={(r['scenario'],r['seed']):r for r in stage3 if r['phase']=='families' and r['solver']=='ilp_cpsat+warm'}
else:
 configs=sorted((root/'configs/stage4').glob('*.json'));seeds=p['scale_seeds'];cached={}
out=root/f'results/stage4/{args.phase}.jsonl';out.parent.mkdir(parents=True,exist_ok=True)
completed=set()
if args.resume:
 for line in out.read_text().splitlines():
  r=json.loads(line);key=(r['scenario'],r['seed'],r['solver'])
  if key in completed or r['protocol_sha256']!=_canonical_hash(p):raise ValueError('invalid prior results')
  completed.add(key)
commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
with out.open('a' if args.resume else 'x') as f:
 for path in configs:
  for seed in seeds:
   if args.phase=='families':s=generate_scenario(load_config(path),seed)
   else:s=make_scale(json.loads(path.read_text()),seed,root)
   common={'phase':args.phase,'scenario':s.name,'seed':seed,'config_file':str(path.relative_to(root)),
           'config_sha256':s.config_hash,'protocol_sha256':_canonical_hash(p),'git_commit':commit,
           'supply_ratio':supply_ratio(s),'compatible_fraction':compatible_request_fraction(s),
           'daily_corridor_demand':{f'{d.isoformat()}|{c}':n for (d,c),n in Counter((r.service_date,r.corridor_id) for r in s.request_instances if not r.cancelled).items()}}
   for mode in ('baseline_greedy','baseline_v2','greedy_retiming','ilp_cpsat+warm'):
    if (s.name,seed,mode) in completed:continue
    if mode=='ilp_cpsat+warm' and args.phase=='families':
     prior=cached[(s.name,seed)]
     if prior['config_sha256']!=s.config_hash:raise RuntimeError('stage3 configuration differs')
     row={**common,'solver':mode,'solver_version':prior['solver_version'],'status':prior['solver_status'],
          'metrics':prior['metrics'],'diagnostics':prior['diagnostics'],'source':'validated stage3 saved run',
          'source_git_commit':prior['git_commit']}
    else:
     if mode=='baseline_greedy':solver=GreedyBaseline()
     elif mode=='baseline_v2':solver=BaselineV2()
     elif mode=='greedy_retiming':solver=GreedyRetiming(max_iterations=p['heuristic_max_iterations'],max_neighbor_checks_per_iteration=p['heuristic_max_neighbor_checks_per_iteration'])
     else:
      days=len({r.service_date for r in s.request_instances if not r.cancelled})
      solver=ILPCPSATWarm(grid_minutes=p['ilp_grid_minutes'],workers=p['ilp_workers'],time_limit_seconds=days*p['ilp_budget_per_date_seconds'])
     start=time.perf_counter();result=solver.solve(s);elapsed=time.perf_counter()-start
     errors=validate(s,result)
     if errors:raise RuntimeError(f'{mode} {s.name}/{seed}: {errors}')
     diag=result.diagnostics or {}
     row={**common,'solver':mode,'solver_version':solver.version,'status':diag.get('status','BASELINE' if mode=='baseline_greedy' else 'HEURISTIC'),
          'metrics':calculate_metrics(s,result,elapsed),'diagnostics':diag,'source':'stage4'}
    f.write(json.dumps(row,ensure_ascii=False)+'\n');f.flush()
    print(args.phase,s.name,seed,mode,row['status'],flush=True)
