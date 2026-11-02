"""Sequential stage 5 runs; resume only matching preregistration and committed code."""
import hashlib,json,re,subprocess,time
from collections import Counter
from pathlib import Path
from matching_lab.generator import generate_scenario,load_config
from matching_lab.metrics import calculate_metrics,compatible_request_fraction
from matching_lab.solvers.baseline_v2 import BaselineV2
from matching_lab.solvers.greedy_retiming import GreedyRetiming
import matching_lab.solvers.greedy_retiming as retiming_module
from matching_lab.solvers.ilp_decomposed import ILPCPSATWarm,ILPCPSATWarm2
from matching_lab.supply import supply_ratio
from matching_lab.validator import validate
root=Path(__file__).resolve().parents[1]
p=json.loads((root/'configs/stage5/protocol.json').read_text())
registration=(root/'docs/experiments/stage5/preregistration.md').read_text()
for path,expected in re.findall(r'\| `([^`]+)` \| `([0-9a-f]{64})` \|',registration):
 if hashlib.sha256((root/path).read_bytes()).hexdigest()!=expected:raise RuntimeError('changed registered config '+path)
commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
out=root/'docs/experiments/stage5/runs.jsonl'
existing=[json.loads(line) for line in out.read_text().splitlines()] if out.exists() else []
done={(r['phase'],r['config'],r['seed'],r['solver']) for r in existing}
with out.open('a') as f:
 for phase,paths,seeds,modes in [('families',sorted((root/'configs/stage3').glob('*.yaml'),key=lambda x:(x.stem.endswith('control'),x.stem)),p['evaluation_seeds'],['ilp_cpsat+warm2']),('scale',sorted((root/'configs/stage5').glob('*.yaml'),key=lambda x:(int(x.stem.split('_')[1]),x.stem)),p['scale_seeds'],['baseline_v2','greedy_retiming','ilp_cpsat+warm','ilp_cpsat+warm2'])]:
  for path in paths:
   for seed in seeds:
    s=generate_scenario(load_config(path),seed)
    active=[r for r in s.request_instances if not r.cancelled]
    for mode in modes:
     key=(phase,str(path.relative_to(root)),seed,mode)
     if key in done:continue
     if mode=='baseline_v2':solver=BaselineV2()
     elif mode=='greedy_retiming':solver=GreedyRetiming(max_iterations=p['retiming_iterations'],max_neighbor_checks_per_iteration=p['retiming_neighbor_checks'])
     else:
      cls=ILPCPSATWarm2 if mode.endswith('warm2') else ILPCPSATWarm
      solver=cls(grid_minutes=p['grid_minutes'],workers=p['workers'],time_limit_seconds=p['budget_seconds_per_date']*len({r.service_date for r in active}))
     # Measure the v2 construction inside retiming without changing either solver.
     measured=[]
     class TimedV2(BaselineV2):
      def solve(self, scenario):
       started=time.perf_counter(); result=super().solve(scenario)
       measured.append(time.perf_counter()-started); return result
     original=retiming_module.BaselineV2
     if phase=='scale' and mode=='greedy_retiming':retiming_module.BaselineV2=TimedV2
     start=time.perf_counter()
     try:result=solver.solve(s)
     finally:retiming_module.BaselineV2=original
     elapsed=time.perf_counter()-start
     errors=validate(s,result)
     if errors:raise RuntimeError(f'{key}: {errors}')
     diag=dict(result.diagnostics or {})
     if phase=='scale' and mode=='baseline_v2':diag.update(build_seconds=elapsed,search_seconds=0.0,timing_method='whole greedy construction; no local search')
     if phase=='scale' and mode=='greedy_retiming':
      if len(measured)!=1:raise RuntimeError('could not measure heuristic construction')
      diag.update(build_seconds=measured[0],search_seconds=elapsed-measured[0],timing_method='initial v2 construction, then local search and validation')
     row={'phase':phase,'config':key[1],'seed':seed,'scenario':s.name,'solver':mode,'solver_version':solver.version,'git_commit':commit,'config_sha256':s.config_hash,'file_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'supply_ratio':supply_ratio(s),'compatible_fraction':compatible_request_fraction(s),'metrics':calculate_metrics(s,result,elapsed),'status':diag.get('status','HEURISTIC'),'diagnostics':diag}
     f.write(json.dumps(row,ensure_ascii=False)+'\n');f.flush()
     print(phase,s.name,seed,mode,row['status'],round(elapsed,3),flush=True)
