"""Read-only reconstruction and paired statistics for recorded stage-3 runs."""
from __future__ import annotations
import csv, hashlib, json, math, random, statistics
from collections import Counter, defaultdict
from pathlib import Path
from matching_lab.generator import generate_scenario, load_config
from matching_lab.paired_stats import bootstrap, wilcoxon

ROOT=Path(__file__).resolve().parents[1]
protocol=json.loads((ROOT/'configs/experiments/stage4.json').read_text())
records=[json.loads(x) for x in (ROOT/'results/stage3/runs.jsonl').read_text().splitlines() if x.strip()]
records=[r for r in records if r['phase']=='families']
group=defaultdict(list); pairs=defaultdict(dict); cache={}

def compatible_fraction(s):
    active=[r for r in s.request_instances if not r.cancelled]
    possible=0
    for r in active:
        if any(r.corridor_id in d.corridor_ids and any(r.service_date.weekday() in sl.days_of_week and
               max(r.earliest_departure,sl.start_minute)<=min(r.latest_departure,sl.end_minute-s.trip_duration_minutes)
               for sl in d.availability) for d in s.drivers):
            possible+=1
    return possible/len(active) if active else None


for r in records:
    key=(r['scenario'],r['seed']);
    if key not in cache:
        s=generate_scenario(load_config(ROOT/r['config']),r['seed'])
        if s.config_hash != r['config_sha256']:raise ValueError(f'config mismatch {key}')
        cache[key]=compatible_fraction(s)
    r['compatibility']=cache[key]
    group[(r['scenario'],r['solver'])].append(r);pairs[key][r['solver']]=r

summary=[]
for (name,mode),items in sorted(group.items()):
    feasible=[r for r in items if r['solver_status'] in ('BASELINE','FEASIBLE','OPTIMAL')]
    values=[r['metrics']['mean_time_deviation_minutes'] for r in feasible if r['metrics']['mean_time_deviation_minutes'] is not None]
    comp=[r['compatibility'] for r in items if r['compatibility'] is not None]
    summary.append({'scenario':name,'solver':mode,'valid_n':len(feasible),'compatibility_mean':statistics.mean(comp),
        'compatibility_std':statistics.stdev(comp) if len(comp)>1 else None,'per_assigned_mean':statistics.mean(values) if values else None,
        'per_assigned_std':statistics.stdev(values) if len(values)>1 else None,'baseline_build_seconds':'not recorded',
        'baseline_search_seconds':'not recorded','runtime_mean':statistics.mean(r['metrics']['runtime_seconds'] for r in items)})

pair_groups=defaultdict(list)
for (name,seed),p in sorted(pairs.items()):
    if 'baseline_greedy' not in p:continue
    b=p['baseline_greedy']
    for mode in ('ilp_cpsat+warm','ilp_cpsat+decomposed'):
        if mode in p:pair_groups[(name,mode)].append((b,p[mode]))
comparisons=[]; cirows=[]
for (name,mode),ps in sorted(pair_groups.items()):
    counts=Counter(); diffs=defaultdict(list)
    for b,r in ps:
        if r['solver_status'] not in ('FEASIBLE','OPTIMAL'):
            counts['no_solution']+=1;continue
        bm=b['metrics'];m=r['metrics']
        left=(-m['assigned_requests'],m['trip_count'],m['total_time_deviation_minutes'])
        right=(-bm['assigned_requests'],bm['trip_count'],bm['total_time_deviation_minutes'])
        if left[0]<right[0]:counts['assigned_better']+=1
        elif left[0]==right[0] and left[1]<right[1]:counts['trips_better']+=1
        elif left[:2]==right[:2] and left[2]<right[2]:counts['deviation_better']+=1
        elif left==right:counts['equal']+=1
        else:counts['worse']+=1
        for metric in ('assigned_requests','trip_count','total_time_deviation_minutes','mean_time_deviation_minutes','mean_passengers_per_trip','runtime_seconds'):
            if m.get(metric) is not None and bm.get(metric) is not None:diffs[metric].append(m[metric]-bm[metric])
    comparisons.append({'scenario':name,'solver':mode,**{k:counts[k] for k in ('assigned_better','trips_better','deviation_better','equal','worse','no_solution')},
                        'wilcoxon_p':wilcoxon(diffs['assigned_requests'])})
    for metric,vals in diffs.items():
        low,high=bootstrap(vals,f'{name}|{mode}|{metric}',seed=protocol['bootstrap_seed'],resamples=protocol['bootstrap_resamples'])
        cirows.append({'scenario':name,'solver':mode,'metric':metric,'n':len(vals),'paired_mean':statistics.mean(vals),'ci95_low':low,'ci95_high':high})

out=ROOT/'docs/experiments/stage4';out.mkdir(exist_ok=True)
def write(name,rows):
    with (out/name).open('w',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
write('post_stage3_summary.csv',summary);write('post_stage3_pairs.csv',comparisons);write('post_stage3_ci.csv',cirows)
lines=['# Пост-обработка этапа 3','','Без новых запусков решателей; параметры bootstrap и Wilcoxon предварительно заданы в `preregistration.md`. Конфигурации восстановлены по seed и проверены по сохранённому config SHA. Совместимость: есть водитель соответствующего коридора с доступным на данную дату слотом, в котором можно завершить рейс длительности сценария и отправиться внутри окна заявки; вместимость и другие заявки не учитываются. Среднее отклонение — среднее по индивидуальным назначениям в каждом запуске, затем среднее ± выборочное СО этих значений по seed. Synthetic, PLACEHOLDER.','', '| Семейство | Режим | n | Совместимые заявки, доля | Отклонение/назначение, мин | Полное время, с |', '|---|---|---:|---:|---:|---:|']
for r in summary:
    dev='—' if r['per_assigned_mean'] is None else f"{r['per_assigned_mean']:.3f}±{r['per_assigned_std']:.3f}" if r['per_assigned_std'] is not None else f"{r['per_assigned_mean']:.3f}±н/д"
    lines.append(f"| {r['scenario']} | {r['solver']} | {r['valid_n']} | {r['compatibility_mean']:.3f}±{r['compatibility_std']:.3f} | {dev} | {r['runtime_mean']:.3f} |")
lines+=['', 'Время построения и поиска baseline отдельно **не записано** в исходных результатах; восстановить его постфактум без нового измерения нельзя. Для baseline в исходных данных есть только полное время.','', '## Парные исходы и Wilcoxon', '', 'Порядок: больше назначений / меньше рейсов при равных назначениях / меньше суммарного отклонения при равных назначениях и рейсах / равно / хуже / нет решения. Точный двусторонний критерий знаковых рангов для разностей по назначениям; p-values описательные, поправка на множественные сравнения не применяется.','', '| Семейство | Режим | Исходы | Wilcoxon p |','|---|---|---:|---:|']
for r in comparisons:lines.append('| '+r['scenario']+' | '+r['solver']+' | '+' / '.join(str(r[k]) for k in ('assigned_better','trips_better','deviation_better','equal','worse','no_solution'))+f" | {r['wilcoxon_p']:.6f} |")
lines+=['','## Парные разности и bootstrap 95%','', 'Разность = решатель − baseline; при меньшем времени/числе рейсов/отклонении отрицательное значение означает уменьшение. CI — percentile bootstrap по одним и тем же seed, 2000 повторов; это не корректировка множественной проверки. Полные численные таблицы: `post_stage3_summary.csv`, `post_stage3_pairs.csv`, `post_stage3_ci.csv`.','', '| Семейство | Режим | Метрика | n | Δ среднее | 95% CI |','|---|---|---|---:|---:|---:|']
for r in cirows:lines.append(f"| {r['scenario']} | {r['solver']} | {r['metric']} | {r['n']} | {r['paired_mean']:.3f} | [{r['ci95_low']:.3f}; {r['ci95_high']:.3f}] |")
(out/'post_stage3.md').write_text('\n'.join(lines)+'\n')
