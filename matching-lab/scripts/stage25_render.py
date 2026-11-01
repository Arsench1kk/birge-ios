"""Render an auditable synthetic report from validated incremental records."""
import argparse
import json
from collections import defaultdict
from pathlib import Path
from stage25_report import METRICS, summarize, write_csv

parser = argparse.ArgumentParser()
parser.add_argument('--families', type=Path, nargs='+', required=True)
parser.add_argument('--scale', type=Path, required=True)
parser.add_argument('--sensitivity', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()

def load(paths):
    return [json.loads(line) for path in paths for line in path.read_text().splitlines() if line.strip()]

def fmt(row, metric):
    a, b = row[metric+'_mean'], row[metric+'_std']
    if a is None: return '—'
    return f'{a:.3f}±{b:.3f}' if b is not None else f'{a:.3f}±— (n={row[metric+"_n"]})'

def summarize_section(title, records):
    rows, comparisons = summarize(records)
    write_csv(args.output / (title+'-summary.csv'), rows)
    write_csv(args.output / (title+'-comparisons.csv'), comparisons)
    lines = [f'## {title}', '', '| Семейство | Бюджет, с | Режим | R | n решений / запусков | Назначено | Доля | Рейсы | Отклонение, мин | Пассажиры/рейс | Время, с | OPT/FEAS/UNKNOWN/INFEAS | Fallback дней |', '|---|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|']
    for r in rows:
        st='/'.join(str(r[s]) for s in ('OPTIMAL','FEASIBLE','UNKNOWN','INFEASIBLE'))
        vals=[fmt(r,m) for m in METRICS]
        lines.append('| '+' | '.join([r['scenario'],str(r['budget']),r['solver'],f"{r['R_mean']:.3f}",f"{r['solutions']}/{r['runs']}",*vals,st,str(r['fallback_days'])])+' |')
    lines += ['', 'Парные исходы относительно baseline: выигрыш по назначениям / выигрыш по рейсам или отклонению при равных назначениях / равенство / проигрыш / нет решения.', '', '| Семейство | Бюджет, с | Режим | Назначения+ | Вторичные+ | Равно | Хуже | Нет решения |', '|---|---:|---|---:|---:|---:|---:|---:|']
    for c in comparisons:
        lines.append('| '+' | '.join(str(c[k]) for k in ('scenario','budget','solver','assigned_better','secondary_better','equal','worse','no_solution'))+' |')
    baselines = [r for r in rows if r['solver']=='baseline_greedy' and r['assignment_rate_mean'] is not None and r['assignment_rate_mean']>=.98]
    lines += ['', 'Контроль без запаса (средняя доля baseline ≥98%): '+(', '.join(sorted({r['scenario'] for r in baselines})) if baselines else 'не наблюдался')+'.','']
    return lines

args.output.mkdir(parents=True, exist_ok=True)
families=load(args.families); scale=load([args.scale]); sensitivity=load([args.sensitivity])
for label, records, expected in (('families', families, 1600), ('scale', scale, 9), ('sensitivity', sensitivity, 24)):
    keys = {(r['scenario'], r['seed'], r['search_budget_seconds'], r['solver']) for r in records}
    if len(records) != expected or len(keys) != expected:
        raise ValueError(f'{label}: expected {expected} unique runs, got {len(records)} records and {len(keys)} unique')
    if any(r['solver'] == 'ilp_cpsat+warm' and r['solver_status'] not in ('OPTIMAL', 'FEASIBLE') for r in records):
        raise ValueError(f'{label}: warm mode returned no valid solution')
text=['# Этап 2.5 — synthetic результаты', '', 'Все параметры PLACEHOLDER; кандидат `ilp_cpsat` [гипотеза] [TBD — решить с руководителем], ADR-006 Proposed. Протоколы и хеши конфигов записаны в сырых данных. Для основных семейств задано по 20 seed, бюджеты поиска 1 и 10 с. Время — wall-clock с построением; модель строится вне лимита поиска. Отдельные экспериментальные процессы выполнялись одновременно на одной машине, поэтому нагрузка влияет на время.', '', 'R — оптимистическая вместимость непересекающихся слотов / активный спрос, не фактическая доля обслуженных заявок; среднее ± выборочное стандартное отклонение. UNKNOWN/INFEASIBLE не включены в метрики качества, но указаны отдельно; время включает все попытки. Дневные исходы и fallback доступны в CSV и сырых данных. Warm может иметь более широкий кандидатный домен и гарантирует план не хуже проверенного baseline. Чистая декомпозиция позволяет отдельно оценить декомпозицию и вклад warm в сравнении с ней.', '',f'Число записей: семейства {len(families)}, масштаб {len(scale)}, чувствительность {len(sensitivity)}. Ожидается 1600 / 9 / 24 соответственно (включая дополнительный режим чистой декомпозиции).', '']
text += summarize_section('families',families)
text += summarize_section('sensitivity',sensitivity)
text += ['## Масштаб', '', '| Сценарий | Режим | Активно | Назначено | Рейсов | Статус | Построение, с | Поиск, с | Полное время, с | Gap |', '|---|---|---:|---:|---:|---|---:|---:|---:|---:|']
for r in scale:
    d=r['diagnostics']; m=r['metrics']; ok=r['solver_status'] in ('BASELINE','OPTIMAL','FEASIBLE')
    f=lambda x: '—' if x is None else f'{x:.3f}'
    text.append('| '+' | '.join([r['scenario'],r['solver'],str(m['active_requests']),str(m['assigned_requests']) if ok else '—',str(m['trip_count']) if ok else '—',r['solver_status'],f(d.get('build_seconds')),f(d.get('search_seconds')),f(m['runtime_seconds']),f(d.get('relative_gap'))])+' |')
text += ['', 'Gap относится к весовой цели на заданном домене, а не к отдельному приоритету. Если глобальный gap декомпозиции не доказан, он не выводится. Итоги характеризуют только данные этой модели. Зависимость от OR-Tools, рост времени построения и резервная эвристика остаются вопросами для обсуждения.']
(args.output/'report.md').write_text('\n'.join(text)+'\n')
