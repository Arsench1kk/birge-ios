"""Recompute headroom using only saved runs with proven candidate-domain optimum."""
import csv
import json
from collections import defaultdict
from pathlib import Path

root=Path(__file__).resolve().parents[1]
groups=defaultdict(list)
for branch in ('families','original-families'):
    records=json.loads((root/'results/stage2-2026-11-02'/branch/'results.json').read_text())
    pairs=defaultdict(dict)
    for r in records:
        m=r['metadata']; pairs[(m['scenario_name'],m['seed'])][m['solver']]=r
    for (name,seed),p in pairs.items():
        b=p.get('baseline_greedy'); x=p.get('ilp_cpsat')
        if not b or not x: continue
        meta=x['metadata']; diag=meta.get('solver_diagnostics') or {}
        # In 0.1 baseline hint is only used when the entire baseline is in the domain.
        eligible=meta.get('solver_status')=='OPTIMAL' and diag.get('hint')=='baseline'
        groups[('2',name,'0.5')].append((b['metrics'],x['metrics']) if eligible else None)
files=['narrow.jsonl','wide_025.jsonl','wide_050.jsonl','wide_075.jsonl','wide_100.jsonl','wide_150.jsonl']
pairs=defaultdict(dict)
for f in files:
    for line in (root/'results/stage25'/f).read_text().splitlines():
        r=json.loads(line);pairs[(r['scenario'],r['seed'],r['search_budget_seconds'])][r['solver']]=r
for (name,seed,budget),p in pairs.items():
    b=p.get('baseline_greedy'); x=p.get('ilp_cpsat+warm')
    if not b or not x: continue
    groups[('2.5',name,str(budget))].append((b['metrics'],x['metrics']) if x['solver_status']=='OPTIMAL' else None)

rows=[]
def rate(num,den): return 100*num/den if den else None
for (stage,name,budget),values in sorted(groups.items()):
    data=[v for v in values if v is not None]; same=[(b,x) for b,x in data if b['assigned_requests']==x['assigned_requests']]
    same_trips=[(b,x) for b,x in same if b['trip_count']==x['trip_count']]
    def delta(items,key,sign):
        if not items:return None,None
        numerator=sum(sign*(x[key]-b[key]) for b,x in items); denominator=sum(b[key] for b,x in items)
        return numerator/len(items),rate(numerator,denominator)
    assigned=delta(data,'assigned_requests',1); trips=delta(same,'trip_count',-1); dev=delta(same,'total_time_deviation_minutes',-1); dev_equal=delta(same_trips,'total_time_deviation_minutes',-1)
    exact=sum((b['assigned_requests'],b['trip_count'],b['total_time_deviation_minutes'])==(x['assigned_requests'],x['trip_count'],x['total_time_deviation_minutes']) for b,x in data)
    rows.append({'stage':stage,'scenario':name,'budget':budget,'total_pairs':len(values),'proven_pairs':len(data),'equal_assigned_n':len(same),'equal_assigned_trips_n':len(same_trips),'assigned_gain_mean':assigned[0],'assigned_gain_pct':assigned[1], 'trip_reduction_mean':trips[0], 'trip_reduction_pct':trips[1], 'deviation_reduction_mean':dev[0], 'deviation_reduction_pct':dev[1], 'deviation_equal_trips_mean':dev_equal[0], 'deviation_equal_trips_pct':dev_equal[1], 'baseline_optimal_n':exact,'baseline_optimal_pct':rate(exact,len(data))})
out=root/'docs/experiments/stage3';out.mkdir(parents=True,exist_ok=True)
with (out/'headroom.csv').open('w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
def val(a,b):
 return '—' if a is None else f'{a:+.2f} / {b:+.1f}%' if b is not None else f'{a:+.2f} / н/д'
text=['# Запас относительно доказанного оптимума на кандидатном домене','','Расчёт без новых запусков по сохранённым сырым данным этапов 2 и 2.5. Учитываются только пары с `OPTIMAL`: на этапе 2 дополнительно требуется hint=baseline (это подтверждает включение baseline в кандидатный домен); на 2.5 используется warm, который включает времена baseline в домен. Оптимум не распространяется на все целые минуты при сетке 10 мин и не является реальным оптимумом вне модели. Данные synthetic, параметры PLACEHOLDER.','', 'Числа — средняя разница на отобранную пару и отношение суммы разниц к сумме baseline, %. Назначения: ILP − baseline; рейсы и отклонение: baseline − ILP. Вторичные величины считаются только при равных назначениях. Отклонение в этом столбце может быть отрицательным, когда оптимум с меньшим числом рейсов расходует больше минут; отдельно показано отклонение при равных назначениях и рейсах. `н/д` — нулевой знаменатель; `—` — нет наблюдений. Доля точного равенства — три компонента цели совпадают.','', '| Этап / семейство | Бюджет | OPT / всего | Назначения Δ / % | Рейсы Δ / % (n) | Отклонение Δ / % (n) | Отклонение при равных рейсах Δ / % (n) | Baseline равен оптимуму |', '|---|---:|---:|---:|---:|---:|---:|---:|']
for r in rows:
 f=lambda k: r[k]
 text.append('| '+f"{f('stage')} / {f('scenario')} | {f('budget')} | {f('proven_pairs')}/{f('total_pairs')} | {val(f('assigned_gain_mean'),f('assigned_gain_pct'))} | {val(f('trip_reduction_mean'),f('trip_reduction_pct'))} ({f('equal_assigned_n')}) | {val(f('deviation_reduction_mean'),f('deviation_reduction_pct'))} ({f('equal_assigned_n')}) | {val(f('deviation_equal_trips_mean'),f('deviation_equal_trips_pct'))} ({f('equal_assigned_trips_n')}) | {f('baseline_optimal_n')}/{f('proven_pairs')} ({f('baseline_optimal_pct'):.1f}%) |" if f('proven_pairs') else '| '+f"{f('stage')} / {f('scenario')} | {f('budget')} | 0/{f('total_pairs')} | — | — | — | — | — |")
text += ['', 'Для wide R≤0,5 число назначений в этих конфигурациях ограничено вместимостью; при narrow R≥0,75 достигнутый baseline ограничен совместимостью окон с двумя минутами отправления (см. `../stage2_5/report.md`). Утверждение «алгоритм не влияет» относится только к достижению соответствующего потолка числа назначений в данных условиях: на число рейсов и отклонение алгоритм влиять может. Отсутствие OPTIMAL — отсутствие доказанного эталона, а не нулевой запас.']
(out/'headroom.md').write_text('\n'.join(text)+'\n')
