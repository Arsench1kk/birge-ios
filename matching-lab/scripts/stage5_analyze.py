"""Descriptive stage 5 report; never invokes a solver."""
import csv,json,statistics,math
from collections import Counter,defaultdict
from pathlib import Path
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from scipy.stats import rankdata
from matching_lab.generator import generate_scenario,load_config
from matching_lab.paired_stats import bootstrap
root=Path(__file__).resolve().parents[1];out=root/'docs/experiments/stage5'
new=[json.loads(x) for x in (out/'runs.jsonl').read_text().splitlines()]
old=[json.loads(x) for x in (root/'docs/experiments/stage4/families_runs.jsonl').read_text().splitlines()]
by=defaultdict(dict)
for r in old:by[('families',r['scenario'],r['seed'])][r['solver']]=r
for r in new:by[(r['phase'],r['scenario'],r['seed'])][r['solver']]=r
metrics=('assigned_requests','trip_count','total_time_deviation_minutes','mean_time_deviation_minutes','mean_passengers_per_trip','runtime_seconds')
def objective(r):
 m=r['metrics'];return (-m['assigned_requests'],m['trip_count'],m['total_time_deviation_minutes'])
def meanstd(vals):
 vals=[v for v in vals if v is not None]
 return 'н/д' if not vals else f'{statistics.mean(vals):.3f} ± {statistics.stdev(vals):.3f}' if len(vals)>1 else f'{vals[0]:.3f} ± н/д'
lines=['# Этап 5: результаты','', 'Синтетические данные; все параметры PLACEHOLDER. Оценка seed 1–20; масштаб seed 1–3; 10 с поиска на дату, один поток. W по семействам и эвристики — сохранённые результаты этапа 4, warm2 — новый запуск, времена не являются парными замерами одной сессии. Сохранённый W использовал CP-SAT 0.3.0, warm2 — модель 0.4.0, поэтому изменения результата не изолируют эффект стартовой точки. OPTIMAL относится к конечному кандидатному домену; warm2 может добавлять к нему время hint. Bootstrap 2000 повторов, seed 451; percentile 95%.','', 'warm2 отличается от W стартом: лучшая лексикографически из baseline_v2 и greedy_retiming вместо baseline 0.2.0. Каждая стартовая точка и итог проходят независимый валидатор; fallback гарантирует результат не хуже выбранного старта, но не OPTIMAL. Разбор high_few на dev seed и примеры рейсов: `../../heuristics.md`. Исходные эвристики на оценочных seed отдельно не пересчитывались; внутри warm2 их вычисление необходимо для построения hint.','', '## Семейства: среднее ± выборочное СО','', '| Семейство | Режим | n | R | Совместимость | Назначено | Рейсы | Отклонение | Отклонение/пасс. | Пасс./рейс | Время, с | Построение, с | Поиск, с | OPT/FEAS/UNKNOWN | fallback дат |','|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|']
for phase in ('families','scale'):
 if phase=='scale':lines+=['','## Размер одной даты','','| Сценарий | Режим | n | R | Совместимость | Назначено | Рейсы | Отклонение | Отклонение/пасс. | Пасс./рейс | Время, с | Построение, с | Поиск, с | OPT/FEAS/UNKNOWN | fallback дат |','|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|']
 for name in sorted({k[1] for k in by if k[0]==phase}):
  for mode in ('baseline_greedy','baseline_v2','greedy_retiming','ilp_cpsat+warm','ilp_cpsat+warm2'):
   rs=[v[mode] for k,v in by.items() if k[:2]==(phase,name) and mode in v]
   if not rs:continue
   stat=Counter(r['status'] for r in rs)
   vals=[meanstd([r['metrics'].get(m) for r in rs]) for m in metrics]+[meanstd([r['diagnostics'].get(m) for r in rs]) for m in ('build_seconds','search_seconds')]
   lines.append('| '+' | '.join([name,mode,str(len(rs)),meanstd([r['supply_ratio'] for r in rs]),meanstd([r['compatible_fraction'] for r in rs]),*vals,'/'.join(str(stat[x]) for x in ('OPTIMAL','FEASIBLE','UNKNOWN')),str(sum(r['diagnostics'].get('fallback_days',0) for r in rs))])+' |')
lines+=['','## Парные сравнения','','Режим warm2 минус сравниваемый режим; Δ назначений: среднее [95% CI]; далее лексикографические исходы выигрыш / равенство / проигрыш. Неполные пары не включены, n указано.','', '| Фаза | Сценарий | Сравнение | n | Δ назначений [95% CI] | выигрыш/равен/хуже |','|---|---|---|---:|---:|---:|']
for phase in ('families','scale'):
 for name in sorted({k[1] for k in by if k[0]==phase}):
  for other in ('baseline_greedy','baseline_v2','greedy_retiming','ilp_cpsat+warm'):
   pairs=[(v['ilp_cpsat+warm2'],v[other]) for k,v in by.items() if k[:2]==(phase,name) and 'ilp_cpsat+warm2' in v and other in v]
   if not pairs:continue
   ds=[a['metrics']['assigned_requests']-b['metrics']['assigned_requests'] for a,b in pairs]
   low,high=bootstrap(ds, f'stage5|{phase}|{name}|{other}',seed=451,resamples=2000)
   cnt=Counter('win' if objective(a)<objective(b) else 'equal' if objective(a)==objective(b) else 'lose' for a,b in pairs)
   lines.append(f'| {phase} | {name} | warm2 − {other} | {len(ds)} | {statistics.mean(ds):+.3f} [{low:+.3f}; {high:+.3f}] | {cnt["win"]}/{cnt["equal"]}/{cnt["lose"]} |')
lines+=['','## Парные разности остальных метрик и 95% CI','','Разность warm2 − соперник; метрики рассчитаны по одним и тем же seed.','', '| Фаза | Сценарий | Соперник | Метрика | n | Δ [95% CI] |','|---|---|---|---|---:|---:|']
for phase in ('families','scale'):
 for name in sorted({k[1] for k in by if k[0]==phase}):
  for other in ('baseline_greedy','baseline_v2','greedy_retiming','ilp_cpsat+warm'):
   pairs=[(v['ilp_cpsat+warm2'],v[other]) for k,v in by.items() if k[:2]==(phase,name) and 'ilp_cpsat+warm2' in v and other in v]
   if not pairs:continue
   for metric in metrics[1:]:
    ds=[a['metrics'][metric]-b['metrics'][metric] for a,b in pairs if a['metrics'].get(metric) is not None and b['metrics'].get(metric) is not None]
    if not ds:continue
    low,high=bootstrap(ds,f'stage5|{phase}|{name}|{other}|{metric}',seed=451,resamples=2000)
    lines.append(f'| {phase} | {name} | {other} | {metric} | {len(ds)} | {statistics.mean(ds):+.3f} [{low:+.3f}; {high:+.3f}] |')
lines+=['','## Размер модели и доля разрыва на одной дате','','Переменные = x + y + переменные неназначения; число ограничений берётся из диагностики модели. Доля разрыва для назначений `(retiming − v2)/(W − v2)`, нулевой знаменатель исключён; результаты вне 0–100% не обрезаются.','', '| Сценарий | Режим | x | y | Все переменные | Ограничения | Доля OPTIMAL | Разрыв retiming относительно v2, n |','|---|---|---:|---:|---:|---:|---:|---:|']
for name in sorted({k[1] for k in by if k[0]=='scale'}):
 entries=[v for k,v in by.items() if k[:2]==('scale',name)]
 ratios=[]
 for v in entries:
  if not all(x in v for x in ('baseline_v2','greedy_retiming','ilp_cpsat+warm')):continue
  base=v['baseline_v2']['metrics']['assigned_requests'];heur=v['greedy_retiming']['metrics']['assigned_requests'];w=v['ilp_cpsat+warm']['metrics']['assigned_requests']
  if w!=base:ratios.append((heur-base)/(w-base))
 for mode in ('ilp_cpsat+warm','ilp_cpsat+warm2'):
  rs=[v[mode] for v in entries if mode in v]
  if not rs:continue
  days=[d for r in rs for d in r['diagnostics'].get('days',[])]
  get=lambda key:meanstd([d.get(key) for d in days])
  lines.append(f'| {name} | {mode} | {get("assignment_variables")} | {get("candidate_trips")} | {get("variables_total")} | {get("constraints_total")} | {sum(r["status"]=="OPTIMAL" for r in rs)}/{len(rs)} | {meanstd([100*x for x in ratios])}% (n={len(ratios)}) |')
lines+=['','### Порог по предварительному критерию','']
for variety in ('few','many'):
 for mode in ('ilp_cpsat+warm','ilp_cpsat+warm2'):
  levels=[]
  for n in (50,100,200,400,800):
   rs=[v[mode] for k,v in by.items() if k[0]=='scale' and k[1]==f'stage5_medium_{variety}_{n}' and mode in v]
   if len(rs)==3 and sum(r['status']=='OPTIMAL' for r in rs)/3 < .8:levels.append(n)
  lines.append(f'- medium_{variety}, {mode}: '+(f'первый размер {min(levels)} заявок/дату' if levels else 'не определён по имеющимся полным тройкам seed')+'.')
# Instance-level features from retained/reconstructed scenarios. No solver execution.
def features(s):
 active=[r for r in s.request_instances if not r.cancelled];days=sorted({r.service_date for r in active});dur=s.trip_duration_minutes
 slots=sum(sum(day.weekday() in sl.days_of_week for sl in d.availability) for day in days for d in s.drivers)/(len(days)*len(s.drivers))
 conflicts=0
 for day in days:
  rs=[r for r in active if r.service_date==day]
  for driver in s.drivers:
   feasible=[]
   for r in rs:
    if r.corridor_id not in driver.corridor_ids:continue
    intervals=[(max(r.earliest_departure,sl.start_minute),min(r.latest_departure,sl.end_minute-dur)) for sl in driver.availability if day.weekday() in sl.days_of_week]
    feasible.append((r,[(a,b) for a,b in intervals if a<=b]))
   for i,(a,ai) in enumerate(feasible):
    for b,bi in feasible[i+1:]:
     if a.corridor_id!=b.corridor_id and any(x< v+dur and u<y+dur for x,y in ai for u,v in bi):conflicts+=1
 return slots,conflicts/len(days),len(active)/len(days)
points=[]
for (phase,name,seed),q in sorted(by.items()):
 if not all(k in q for k in ('baseline_v2','greedy_retiming','ilp_cpsat+warm')):continue
 w=q['ilp_cpsat+warm'];best=min((q['baseline_v2'],q['greedy_retiming']),key=objective)
 # stage4 uses config_file, stage5 uses config.
 config=w.get('config',w.get('config_file'));s=generate_scenario(load_config(root/config),seed)
 slots,conflicts,demand=features(s)
 points.append({'phase':phase,'scenario':name,'seed':seed,'compatibility':w['compatible_fraction'],'slots_per_driver_day':slots,'cross_corridor_potential_conflicts_per_day':conflicts,'R':w['supply_ratio'],'requests_per_day':demand,'W_minus_best_assigned':w['metrics']['assigned_requests']-best['metrics']['assigned_requests']})
if points:
 with (out/'features.csv').open('w',newline='') as f:
  writer=csv.DictWriter(f,fieldnames=list(points[0]));writer.writeheader();writer.writerows(points)
 def rho(x,y):
  a=rankdata(x);b=rankdata(y)
  if np.std(a)==0 or np.std(b)==0:return np.nan
  return float(np.corrcoef(a,b)[0,1])
 rng=np.random.default_rng(451);y=np.array([x['W_minus_best_assigned'] for x in points]);lines+=['','## Признаки и корреляции Спирмена','','Единица наблюдения — сценарий/seed, выигрыш W над лексикографически лучшей эвристикой по назначениям за весь горизонт. Число заявок, слотов и потенциальных межкоридорных конфликтов усреднено по активным датам. Конфликт — пара заявок разных коридоров на одного водителя, для которых существуют совместимые времена отправления с пересечением 30-минутных рейсов; это число потенциальных пар, не число реализованных конфликтов. Совместимость — наличие хотя бы одного слота без учёта конкуренции. CI bootstrap по экземплярам, 2000 повторов; повторные seed и общая структура семейств ограничивают интерпретацию. Причинные выводы не делаются.','', '| Признак | n | Спирмен ρ | 95% CI |','|---|---:|---:|---:|']
 for key in ('compatibility','slots_per_driver_day','cross_corridor_potential_conflicts_per_day','R','requests_per_day'):
  x=np.array([p[key] for p in points]);r=rho(x,y);rs=[]
  for _ in range(2000):
   ix=rng.integers(0,len(x),len(x));v=rho(x[ix],y[ix])
   if math.isfinite(v):rs.append(v)
  lo,hi=np.percentile(rs,[2.5,97.5]) if rs else (float('nan'),float('nan'))
  lines.append(f'| {key} | {len(x)} | {r:.3f} | [{lo:.3f}; {hi:.3f}] |')
  fig,ax=plt.subplots(figsize=(7,5));ax.scatter(x,y,alpha=.5,s=18);ax.set_xlabel(key);ax.set_ylabel('W − best heuristic: assigned');ax.set_title('Synthetic instances; descriptive only');fig.tight_layout();fig.savefig(out/f'scatter_{key}.png',dpi=160);plt.close(fig)
lines+=['','## Ограничения','','В семейных записях этапа 4 время построения/поиска эвристик отдельно не измерялось. В новой серии одна дата: для v2 полное время отнесено к построению, для retiming отдельно измерено начальное построение v2, а остаток включает локальный поиск и валидацию. Системная нагрузка не контролировалась; выполнялись редакторские операции и краткие чтения файлов, временами работали другие процессы. Два несохранённых контрольных запуска прерваны перед публикацией измерительной обвязки и выполнены заново; сохранённые записи не перезаписывались. В записях сохранены коммиты до и после добавления измерения масштабных эвристик; алгоритмы не менялись.','', 'FEASIBLE не доказывает оптимальности. На 800 заявках warm2 равен retiming по цели во всех трёх seed обоих семейств; для few три даты выбрали fallback. В high_few семейный W имеет 52,25 назначений, warm2 50,80, хотя каждый из них имеет 20/20 OPTIMAL: разные hint расширяют разные конечные домены, и данные не устанавливают единственный общий оптимум. Все результаты доступны в runs.jsonl.']
(out/'report.md').write_text('\n'.join(lines)+'\n')
