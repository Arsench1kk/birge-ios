"""Extend fixed stage-3 weekly demand by dates until an exact active count."""
from dataclasses import replace
from datetime import timedelta
from matching_lab.generator import _canonical_hash, generate_scenario, load_config
from matching_lab.model import RequestInstance


def make_scale(config, seed, root):
    raw=load_config(root / config['base_config'])
    base=generate_scenario(raw,seed)
    target=int(config['active_requests'])
    if target < 1 or not base.requests:raise ValueError('invalid scale target')
    instances=[];offset=0
    while len(instances)<target:
        day=base.start_date+timedelta(days=offset)
        for t in sorted(base.requests,key=lambda r:r.request_id):
            if day.weekday() not in t.days_of_week:continue
            instances.append(RequestInstance(f'{t.request_id}@{day.isoformat()}',t.request_id,t.corridor_id,day,
                                             t.earliest_departure,t.latest_departure,t.preferred_departure))
            if len(instances)==target:break
        offset+=1
    return replace(base,name=f'stage4_scale_{target}',horizon_days=offset,request_instances=tuple(instances),
                   config_hash=_canonical_hash(config),generator_version=base.generator_version+'+stage4scale1',
                   source_config={'scale':config,'base':raw})
