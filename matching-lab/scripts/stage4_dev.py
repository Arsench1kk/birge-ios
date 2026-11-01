"""Pre-registered development seeds only; no evaluation seeds or W runs."""
import json,time
from pathlib import Path
from matching_lab.generator import generate_scenario,load_config
from matching_lab.solvers.baseline_v2 import BaselineV2
from matching_lab.solvers.greedy_retiming import GreedyRetiming
from matching_lab.validator import validate
root=Path(__file__).resolve().parents[1]
p=json.loads((root/'configs/experiments/stage4.json').read_text())
out=root/'results/stage4/dev.jsonl';out.parent.mkdir(parents=True,exist_ok=True)
with out.open('x') as f:
 for path in sorted((root/'configs/stage3').glob('*.yaml')):
  for seed in p['dev_seeds']:
   s=generate_scenario(load_config(path),seed)
   for solver in (BaselineV2(),GreedyRetiming(max_iterations=p['heuristic_max_iterations'],max_neighbor_checks_per_iteration=p['heuristic_max_neighbor_checks_per_iteration'])):
    start=time.perf_counter();result=solver.solve(s);elapsed=time.perf_counter()-start
    if validate(s,result):raise RuntimeError('invalid dev result')
    row={'scenario':s.name,'seed':seed,'solver':solver.name,'assigned':len(result.assignments),'trips':len(result.trips),'deviation':sum(a.deviation_minutes for a in result.assignments),'runtime_seconds':elapsed}
    f.write(json.dumps(row)+'\n');f.flush();print(s.name,seed,solver.name,round(elapsed,3),flush=True)
