"""Aggregate the preregistered serial stage 3 study; refuses incomplete data."""
import csv
import json
import statistics
from collections import Counter,defaultdict
from pathlib import Path
from matching_lab.generator import _canonical_hash

root=Path(__file__).resolve().parents[1]
protocol=json.loads((root/'configs/experiments/stage3.json').read_text())
records=[json.loads(x) for x in (root/'results/stage3/runs.jsonl').read_text().splitlines() if x.strip()]
if any(r['protocol_sha256'] != _canonical_hash(protocol) for r in records):
    raise ValueError('records contain a different protocol')
config_hashes=defaultdict(set)
for r in records: config_hashes[r['scenario']].add(r['config_sha256'])
if any(len(values)!=1 for values in config_hashes.values()):
    raise ValueError('scenario config changed during the study')
groups=defaultdict(list);pairs=defaultdict(dict)
for r in records:
    group=(r['phase'],r['scenario'],r['budget_per_date_seconds'],r['solver'])
    groups[group].append(r)
    pairs[(r['phase'],r['scenario'],r['seed'],r['budget_per_date_seconds'])][r['solver']]=r
expected={'families':7*20*3,'scale':3*3*3,'sensitivity':7*5*4}
for phase,n in expected.items():
    subset=[r for r in records if r['phase']==phase]
    keys={(r['scenario'],r['seed'],r['budget_per_date_seconds'],r['solver']) for r in subset}
    if len(subset)!=n or len(keys)!=n:
        raise ValueError(f'{phase}: expected {n} unique records, got {len(subset)} records and {len(keys)} unique')
metrics=['assigned_requests','trip_count','total_time_deviation_minutes','mean_passengers_per_trip','runtime_seconds','build_seconds','search_seconds']
rows=[]
for (phase,name,budget,mode),group in sorted(groups.items()):
    status=Counter(r['solver_status'] for r in group)
    feasible=[r for r in group if r['solver_status'] in ('BASELINE','OPTIMAL','FEASIBLE')]
    row={'phase':phase,'scenario':name,'budget_per_date':budget,'solver':mode,'runs':len(group),'solutions':len(feasible),'no_solution':len(group)-len(feasible),
         'R_mean':statistics.mean(r['supply_ratio'] for r in group),'R_std':statistics.stdev(r['supply_ratio'] for r in group) if len(group)>1 else None,
         'fallback_dates':sum(r['diagnostics'].get('fallback_days',0) for r in group),
         'load1_mean':statistics.mean(r['machine_before']['loadavg'][0] for r in group),
         'host_cpu_percent_sum_mean':statistics.mean(r['machine_before']['process_cpu_percent_sum'] for r in group),
         **{s:status[s] for s in ('OPTIMAL','FEASIBLE','UNKNOWN','INFEASIBLE')}}
    for name_metric in metrics:
        source=group if name_metric in ('runtime_seconds','build_seconds','search_seconds') else feasible
        values=[(r['diagnostics'].get(name_metric) if name_metric in ('build_seconds','search_seconds') else r['metrics'].get(name_metric)) for r in source]
        values=[v for v in values if v is not None]
        row[name_metric+'_n']=len(values);row[name_metric+'_mean']=statistics.mean(values) if values else None
        row[name_metric+'_std']=statistics.stdev(values) if len(values)>1 else None
    row['assignment_rate_mean']=statistics.mean(r['metrics']['assignment_rate'] for r in feasible if r['metrics']['assignment_rate'] is not None) if feasible else None
    rows.append(row)
baseline_by_seed={(r['scenario'],r['seed']):r for r in records if r['phase']=='families' and r['solver']=='baseline_greedy'}
comparison=defaultdict(lambda: {'categories':Counter(),'assigned':[],'trips':[],'deviation':[],'assigned_base':[],'trips_base':[],'deviation_base':[]})
for (phase,scenario,seed,budget),p in pairs.items():
    baseline=p.get('baseline_greedy') or (baseline_by_seed.get((scenario,seed)) if phase=='sensitivity' else None)
    if baseline is None: continue
    b=baseline['metrics']
    for mode in ('ilp_cpsat+warm','ilp_cpsat+decomposed'):
        if mode not in p: continue
        x=p[mode];t=comparison[(phase,scenario,budget,mode)]
        if x['solver_status'] not in ('OPTIMAL','FEASIBLE'):
            t['categories']['no_solution']+=1;continue
        m=x['metrics'];a=(-m['assigned_requests'],m['trip_count'],m['total_time_deviation_minutes']);z=(-b['assigned_requests'],b['trip_count'],b['total_time_deviation_minutes'])
        key='assigned_better' if a[0]<z[0] else 'secondary_better' if a<z else 'equal' if a==z else 'worse'
        t['categories'][key]+=1;t['assigned'].append(m['assigned_requests']-b['assigned_requests']);t['assigned_base'].append(b['assigned_requests'])
        if m['assigned_requests']==b['assigned_requests']:
            t['trips'].append(b['trip_count']-m['trip_count']);t['trips_base'].append(b['trip_count'])
            t['deviation'].append(b['total_time_deviation_minutes']-m['total_time_deviation_minutes']);t['deviation_base'].append(b['total_time_deviation_minutes'])
comps=[]
for (phase,name,budget,mode),d in sorted(comparison.items()):
    row={'phase':phase,'scenario':name,'budget_per_date':budget,'solver':mode,
         **{k:d['categories'][k] for k in ('assigned_better','secondary_better','equal','worse','no_solution')}}
    for key in ('assigned','trips','deviation'):
        values=d[key];base=d[key+'_base'];row[key+'_n']=len(values)
        row[key+'_delta_mean']=statistics.mean(values) if values else None
        row[key+'_delta_pct']=100*sum(values)/sum(base) if sum(base) else None
    comps.append(row)
out=root/'docs/experiments/stage3';out.mkdir(exist_ok=True)
def save(name,data):
    with (out/name).open('w',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(data[0]));w.writeheader();w.writerows(data)
save('summary.csv',rows);save('comparisons.csv',comps)
def fmt(row,metric):
    a=row[metric+'_mean'];b=row[metric+'_std'];return '—' if a is None else f'{a:.3f}±{b:.3f}' if b is not None else f'{a:.3f}±—'
lines=['# Этап 3: предварительно зарегистрированный synthetic эксперимент','','Все параметры — PLACEHOLDER; основной решатель [гипотеза] [TBD — решить с руководителем], ADR-006 Proposed. Семейства и протокол, включая хеши, зафиксированы до запусков в `preregistration_2026-11-02.md`. Запуски выполнены последовательно одним процессом; нагрузка системы записана до и после каждой попытки. R — оптимистическая вместимость слотов / активные экземпляры. Среднее ± выборочное стандартное отклонение; UNKNOWN исключён из качества и указан как нет решения.', '', '| Фаза / семейство | Слоты | Бюджет на дату, с | Режим | R | n решений / запусков | Назначено | Рейсов | Отклонение | Пасс./рейс | Полное время, с | Построение, с | Поиск, с | OPT/FEAS/UNKNOWN | Fallback дат |', '|---|---|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|']
for r in rows:
    status='/'.join(str(r[k]) for k in ('OPTIMAL','FEASIBLE','UNKNOWN'))
    diversity='few' if r['scenario'].endswith('_few') else 'many' if r['scenario'].endswith('_many') else 'control' if r['scenario']=='stage3_control' else 'scale'
    lines.append('| '+' | '.join([r['phase']+' / '+r['scenario'],diversity,str(r['budget_per_date']),r['solver'],fmt(r,'R'),f"{r['solutions']}/{r['runs']}",*[fmt(r,m) for m in metrics],status,str(r['fallback_dates'])])+' |')
lines += ['', '## Парные исходы', '', 'Порядок: выиграл по назначениям / выиграл по вторичным критериям при равных назначениях / равен / проиграл / нет решения. Δ назначений — candidate − baseline. Δ рейсов и минут — baseline − candidate при равных назначениях; минуты при разном числе рейсов не являются отдельным приоритетом. Проценты — отношение суммы разниц к сумме базовых значений.', '', '| Фаза / семейство | Бюджет | Режим | Исходы | Δ назначений, среднее / % | Δ рейсов, среднее / % (n) | Δ минут, среднее / % (n) |', '|---|---:|---|---:|---:|---:|---:|']
def delta(r,key):
    a=r[key+'_delta_mean']; b=r[key+'_delta_pct'];return '—' if a is None else f'{a:+.3f} / {b:+.2f}%' if b is not None else f'{a:+.3f} / н/д'
for r in comps:
    count='/'.join(str(r[k]) for k in ('assigned_better','secondary_better','equal','worse','no_solution'))
    lines.append('| '+' | '.join([r['phase']+' / '+r['scenario'],str(r['budget_per_date']),r['solver'],count,delta(r,'assigned'),delta(r,'trips')+f" ({r['trips_n']})",delta(r,'deviation')+f" ({r['deviation_n']})"])+' |')
control=[r['scenario'] for r in rows if r['phase']=='families' and r['solver']=='baseline_greedy' and r['assignment_rate_mean'] is not None and r['assignment_rate_mean']>=.98]
lines+=['', 'Контроль без запаса (baseline ≥98%): '+(', '.join(sorted(set(control))) if control else 'не наблюдался')+'.', '', 'Нагрузка машины: `summary.csv` содержит среднее load average за 1 минуту и сумму доступных `ps %CPU` перед запуском; полные снимки до/после — в сырых JSONL. Метрики времени зависят от машины и нагрузки. Профили и ограничения построения — `profiling.md`. Если наблюдаемого запаса в структурных семействах нет, это результат модели; значимость и формулировку темы следует обсудить с руководителем, а не объявлять доказанным эффектом в реальной среде.']
(out/'report.md').write_text('\n'.join(lines)+'\n')
