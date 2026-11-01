"""Profile model construction without solving or modifying the solver."""
import argparse
import cProfile
import json
import pstats
import time
from pathlib import Path

from ortools.sat.python import cp_model
from matching_lab.generator import generate_scenario, load_config
from matching_lab.solvers.ilp_cpsat import ILPCPSAT

root=Path(__file__).resolve().parents[1]
args=argparse.ArgumentParser();args.add_argument('--label',required=True);opts=args.parse_args()
protocol=json.loads((root/'configs/experiments/stage3.json').read_text())
out=root/'results/stage3-profile'/opts.label;out.mkdir(parents=True,exist_ok=True)
class StopAtSolve(Exception): pass
observation={}
def stop(self,model,*args,**kwargs):
    observation['variables']=len(model.Proto().variables)
    observation['constraints']=len(model.Proto().constraints)
    raise StopAtSolve
cp_model.CpSolver.Solve=stop
for config in protocol['scale_configs']:
    path=root/config;scenario=generate_scenario(load_config(path),protocol['profile_seed'])
    prof=cProfile.Profile();start=time.perf_counter()
    try:
        prof.enable();ILPCPSAT(grid_minutes=protocol['grid_minutes'],time_limit_seconds=protocol['profile_time_limit_seconds'],workers=1).solve(scenario)
    except StopAtSolve:
        pass
    finally:
        prof.disable()
    elapsed=time.perf_counter()-start
    name=path.stem;prof.dump_stats(str(out/f'{name}.prof'))
    with (out/f'{name}.txt').open('w') as handle:
        pstats.Stats(prof,stream=handle).strip_dirs().sort_stats('cumtime').print_stats(35)
    record={'scenario':name,'active_requests':sum(not r.cancelled for r in scenario.request_instances),
            'seed':protocol['profile_seed'],'profiled_build_seconds':elapsed,**observation}
    (out/f'{name}.json').write_text(json.dumps(record,indent=2)+'\n')
    print(json.dumps(record),flush=True)
