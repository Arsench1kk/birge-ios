"""Summarize held-out synthetic outcomes without filtering unfavorable pairs."""
from __future__ import annotations
import argparse,csv,json,statistics
from collections import Counter,defaultdict
from pathlib import Path
from matching_lab.paired_stats import bootstrap,wilcoxon

root=Path(__file__).resolve().parents[1]
p=json.loads((root/'configs/experiments/stage4.json').read_text())
ap=argparse.ArgumentParser();ap.add_argument('--phase',choices=['families','scale'],required=True);a=ap.parse_args()
records=[json.loads(line) for line in (root/f'results/stage4/{a.phase}.jsonl').read_text().splitlines()]
expected=7*20*4 if a.phase=='families' else 3*3*4
keys={(r['scenario'],r['seed'],r['solver']) for r in records}
if len(records)!=expected or len(keys)!=expected:raise ValueError(f'expected {expected} unique records; got {len(records)}/{len(keys)}')
if len({r['protocol_sha256'] for r in records})!=1:raise ValueError('mixed protocol hashes')
groups=defaultdict(list);pairs=defaultdict(dict)
for r in records:groups[(r['scenario'],r['solver'])].append(r);pairs[(r['scenario'],r['seed'])][r['solver']]=r
metrics=('assigned_requests','trip_count','total_time_deviation_minutes','mean_time_deviation_minutes','mean_passengers_per_trip','runtime_seconds')
summary=[]
for (name,mode),rs in sorted(groups.items()):
 valid=[r for r in rs if r['status'] in ('BASELINE','HEURISTIC','OPTIMAL','FEASIBLE')]
 status=Counter(r['status'] for r in rs)
 row={'scenario':name,'solver':mode,'runs':len(rs),'valid':len(valid),'compatible_mean':statistics.mean(r['compatible_fraction'] for r in rs),
      'compatible_std':statistics.stdev(r['compatible_fraction'] for r in rs) if len(rs)>1 else None,
      'R_mean':statistics.mean(r['supply_ratio'] for r in rs),'R_std':statistics.stdev(r['supply_ratio'] for r in rs) if len(rs)>1 else None,
      'OPTIMAL':status['OPTIMAL'],'FEASIBLE':status['FEASIBLE'],'UNKNOWN':status['UNKNOWN'],'INFEASIBLE':status['INFEASIBLE'],
      'fallback_days':sum(r['diagnostics'].get('fallback_days',0) for r in rs)}
 for metric in metrics:
  source=rs if metric=='runtime_seconds' else valid
  vals=[r['metrics'][metric] for r in source if r['metrics'].get(metric) is not None]
  row[metric+'_n']=len(vals);row[metric+'_mean']=statistics.mean(vals) if vals else None;row[metric+'_std']=statistics.stdev(vals) if len(vals)>1 else None
 for metric in ('build_seconds','search_seconds'):
  vals=[r['diagnostics'][metric] for r in rs if r['diagnostics'].get(metric) is not None]
  row[metric+'_n']=len(vals);row[metric+'_mean']=statistics.mean(vals) if vals else None;row[metric+'_std']=statistics.stdev(vals) if len(vals)>1 else None
 summary.append(row)
comparisons=[];intervals=[];closures=[]
for scenario in sorted({k[0] for k in pairs}):
 paired=[pairs[k] for k in sorted(pairs) if k[0]==scenario]
 for candidate,reference in (('baseline_v2','baseline_greedy'),('greedy_retiming','baseline_greedy'),('ilp_cpsat+warm','baseline_greedy'),('ilp_cpsat+warm','baseline_v2'),('ilp_cpsat+warm','greedy_retiming')):
  cnt=Counter();deltas=defaultdict(list)
  for q in paired:
   x=q[candidate];b=q[reference]
   if x['status'] not in ('BASELINE','HEURISTIC','OPTIMAL','FEASIBLE') or b['status'] not in ('BASELINE','HEURISTIC','OPTIMAL','FEASIBLE'):
    cnt['no_solution']+=1;continue
   m=x['metrics'];n=b['metrics'];left=(-m['assigned_requests'],m['trip_count'],m['total_time_deviation_minutes']);right=(-n['assigned_requests'],n['trip_count'],n['total_time_deviation_minutes'])
   if left[0]<right[0]:cnt['assigned_better']+=1
   elif left[0]==right[0] and left[1]<right[1]:cnt['trip_better']+=1
   elif left[:2]==right[:2] and left[2]<right[2]:cnt['deviation_better']+=1
   elif left==right:cnt['equal']+=1
   else:cnt['worse']+=1
   for metric in metrics:
    if m.get(metric) is not None and n.get(metric) is not None:deltas[metric].append(m[metric]-n[metric])
  comparisons.append({'scenario':scenario,'candidate':candidate,'reference':reference,**{k:cnt[k] for k in ('assigned_better','trip_better','deviation_better','equal','worse','no_solution')},'wilcoxon_assigned_p':wilcoxon(deltas['assigned_requests'])})
  for metric,values in deltas.items():
   low,high=bootstrap(values,f'{a.phase}|{scenario}|{candidate}|{reference}|{metric}',seed=p['bootstrap_seed'],resamples=p['bootstrap_resamples'])
   intervals.append({'scenario':scenario,'candidate':candidate,'reference':reference,'metric':metric,'n':len(values),'difference_mean':statistics.mean(values),'ci95_low':low,'ci95_high':high})
 for mode in ('baseline_v2','greedy_retiming'):
  for metric in ('assigned_requests','trip_count','mean_time_deviation_minutes'):
   ratios=[];numerators=[];denominators=[]
   for q in paired:
    b=q['baseline_greedy'];h=q[mode];w=q['ilp_cpsat+warm']
    if w['status'] not in ('FEASIBLE','OPTIMAL'):continue
    b=b['metrics'];h=h['metrics'];w=w['metrics']
    if metric!='assigned_requests' and not (b['assigned_requests']==h['assigned_requests']==w['assigned_requests']):continue
    x,y,z=b.get(metric),h.get(metric),w.get(metric)
    if x is None or y is None or z is None or z==x:continue
    ratios.append((y-x)/(z-x));numerators.append(y-x);denominators.append(z-x)
   closures.append({'scenario':scenario,'heuristic':mode,'metric':metric,'n':len(ratios),'mean_ratio':statistics.mean(ratios) if ratios else None,
                    'pooled_ratio':sum(numerators)/sum(denominators) if denominators and sum(denominators) else None})
out=root/'docs/experiments/stage4';out.mkdir(exist_ok=True)
def save(name,rows):
 with (out/f'{a.phase}_{name}.csv').open('w',newline='') as f:
  w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
for name,rows in [('summary',summary),('pairs',comparisons),('ci',intervals),('closure',closures)]:save(name,rows)
def fmt(row,key):
 x=row[key+'_mean'];y=row[key+'_std'];return '—' if x is None else f'{x:.3f}±{y:.3f}' if y is not None else f'{x:.3f}±н/д'
lines=[f'# Этап 4: {a.phase}, синтетические результаты','', 'Все параметры PLACEHOLDER, 2000 парных bootstrap-повторов, seed 451; лексикографическая цель: максимум назначений, минимум рейсов, минимум суммарного отклонения. CI — percentile bootstrap разностей candidate − reference, paired по seed; Wilcoxon — точная двусторонняя знаково-ранговая перестановка без поправки на множественные сравнения. W на основных семействах — сохранённые валидированные запуски этапа 3; его время измерено отдельно и не является парным измерением времени новых решателей.','', '| Сценарий | Режим | n | R | Совместимость | Назначено | Рейсы | Отклонение | Отклонение/назначение | Пасс./рейс | Время, с | Построение, с | Поиск, с | OPT/FEAS/UNKNOWN | Fallback дат |','|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|']
for r in summary:
 status='/'.join(str(r[k]) for k in ('OPTIMAL','FEASIBLE','UNKNOWN'))
 vals=[fmt(r,k) for k in metrics]+[fmt(r,'build_seconds'),fmt(r,'search_seconds')]
 lines.append('| '+' | '.join([r['scenario'],r['solver'],f"{r['valid']}/{r['runs']}",fmt(r,'R'),fmt(r,'compatible'),*vals,status,str(r['fallback_days'])])+' |')
lines+=['','## Парные исходы','','Порядок: выиграл по назначениям / по рейсам при равных назначениях / по отклонению при равных назначениях и рейсах / равен / хуже / нет решения. Wilcoxon — по назначениям.','', '| Сценарий | Кандидат / эталон | Исходы | Wilcoxon p |','|---|---|---:|---:|']
for r in comparisons:
 outcome='/'.join(str(r[k]) for k in ('assigned_better','trip_better','deviation_better','equal','worse','no_solution'))
 lines.append(f"| {r['scenario']} | {r['candidate']} / {r['reference']} | {outcome} | {r['wilcoxon_assigned_p']:.6f} |")
lines+=['','## Парные разности и 95% CI','','Разность = кандидат − эталон. Отрицательные разности рейсов, отклонения и времени означают уменьшение. CI по отдельным метрикам не означает лексикографического выигрыша.','', '| Сценарий | Кандидат / эталон | Метрика | n | Δ среднее | 95% CI |','|---|---|---|---:|---:|---:|']
for r in intervals:lines.append(f"| {r['scenario']} | {r['candidate']} / {r['reference']} | {r['metric']} | {r['n']} | {r['difference_mean']:+.3f} | [{r['ci95_low']:+.3f}; {r['ci95_high']:+.3f}] |")
lines+=['','## Закрытая доля разрыва','','Среднее по парам `(эвристика − baseline)/(W − baseline)`; n включает только ненулевой знаменатель. Для рейсов и среднего отклонения на назначение дополнительно требуется одинаковое число назначений у всех трёх алгоритмов. Значения не ограничены диапазоном 0–1; отрицательные значения и значения больше 1 сохранены. pooled — отношение сумм разностей на тех же парах.','', '| Сценарий | Эвристика | Метрика | n | Средняя доля | pooled |','|---|---|---|---:|---:|---:|']
for r in closures:
 v=lambda x:'н/д' if x is None else f'{100*x:.2f}%'
 lines.append(f"| {r['scenario']} | {r['heuristic']} | {r['metric']} | {r['n']} | {v(r['mean_ratio'])} | {v(r['pooled_ratio'])} |")
if a.phase=='scale':lines+=['','Каждый масштаб воспроизводит еженедельную структуру stage3_medium_many вдоль горизонта; последняя дата может быть неполной. R и спрос каждой даты/коридора сохранены в сырых JSONL; сравнение с полными исходными неделями ограничено этой последней датой.']
(out/f'{a.phase}.md').write_text('\n'.join(lines)+'\n')
print(f'{a.phase}: {len(records)} validated/reused runs; report written')
