"""Inspect saved daily CP-SAT diagnostics, without rerunning solvers."""
import json,statistics
from collections import Counter,defaultdict
from pathlib import Path
root=Path(__file__).resolve().parents[1]
records=[json.loads(x) for x in (root/'results/stage3/runs.jsonl').read_text().splitlines()]
groups=defaultdict(list)
for r in records:
 if r['phase']=='families' and r['scenario'] in ('stage3_control','stage3_low_few','stage3_low_many') and r['solver'] in ('ilp_cpsat+warm','ilp_cpsat+decomposed'):
  groups[(r['scenario'],r['solver'])].extend(r['diagnostics'].get('days',[]))
def fmt(values):
 if not values:return '—'
 return f'{statistics.mean(values):.1f}±{statistics.stdev(values):.1f}' if len(values)>1 else f'{values[0]:.1f}±н/д'
lines=['# Контроль и избыток водителей: диагностика этапа 3','','Только сохранённые данные этапа 3, без повторного поиска; 20 seed на семейство, построчные статусы относятся к датам. Значения размера модели — среднее ± выборочное СО. W 0.3.0 не включал ограничения симметрии для сохранения полного hint; D применял симметрию идентичных водителей. Данные synthetic и PLACEHOLDER.','', '| Семейство | Режим | Дат | y (рейсы-кандидаты) | x | Переменные | Ограничения | Дневные статусы OPT/FEAS/UNKNOWN | Средний gap FEASIBLE |','|---|---|---:|---:|---:|---:|---:|---:|---:|']
for (name,mode),days in sorted(groups.items()):
 status=Counter(d.get('status') for d in days)
 def f(key):return fmt([d[key] for d in days if d.get(key) is not None])
 gaps=[d['relative_gap'] for d in days if d.get('status')=='FEASIBLE' and d.get('relative_gap') is not None]
 lines.append(f"| {name} | {mode} | {len(days)} | {f('candidate_trips')} | {f('assignment_variables')} | {f('variables_total')} | {f('constraints_total')} | {status['OPTIMAL']}/{status['FEASIBLE']}/{status['UNKNOWN']} | {fmt(gaps)} |")
lines+=['','Control получил 0 глобальных OPTIMAL из 20 для обоих режимов; чистая декомпозиция хуже baseline в 17/20 пар (stage3/report.md). Значительное число бинарных переменных и оставшиеся gap при лимите показывают, что доказательство оптимума не достигнуто, но эти измерения сами по себе не устанавливают единственную причину. Симметрия и построение сетки влияют на размер/поиск; causal-абляции здесь нет.','', 'Для новой версии реализовано дополнительное безопасное сокращение: если водитель на дату индивидуально совместим ровно с одной заявкой, доминируемые минуты для неё удаляются (минута hint сохраняется). Симметрия и фильтр пустых рейсов уже были реализованы; тесты сравнивают цель с замороженной моделью до сокращений на 20 малых случаях и эталонах. Применимость нового правила к записанным моделям и ускорение для control без повторного построения **не измерялись**.']
(root/'docs/experiments/stage4/control_diagnostics.md').write_text('\n'.join(lines)+'\n')
