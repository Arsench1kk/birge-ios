"""Resume the serial study and finalize only after all preregistered records exist."""
from __future__ import annotations

import csv
import json
import os
import subprocess
from pathlib import Path

lab = Path(__file__).resolve().parents[1]
repo = lab.parent
vault = Path('/Users/arsenabduhalyk/Documents/Dev_ArsensBrain/Projects/Birge Taxi')
python = lab / '.venv/bin/python'
env = {**os.environ, 'PYTHONPATH': str(lab / 'src')}

def run(args, cwd=lab):
    print('+', ' '.join(map(str,args)), flush=True)
    return subprocess.run(list(map(str,args)), cwd=cwd, env=env, check=True, text=True)

def branch(path, expected):
    actual = subprocess.check_output(['git','branch','--show-current'],cwd=path,text=True).strip()
    if actual != expected:
        raise RuntimeError(f'{path}: expected branch {expected}, got {actual}; no commit performed')

branch(repo, 'thesis/matching-lab')
run([python, 'scripts/stage3_run.py', '--resume'])
run([python, 'scripts/stage3_report.py'])  # refuses incomplete or duplicate datasets
rows=list(csv.DictReader((lab/'docs/experiments/stage3/summary.csv').open()))
comparisons=list(csv.DictReader((lab/'docs/experiments/stage3/comparisons.csv').open()))
subset=[r for r in rows if r['phase']=='families' and r['solver']=='ilp_cpsat+warm']
paired=[r for r in comparisons if r['phase']=='families' and r['solver']=='ilp_cpsat+warm']
opt=sum(int(r['OPTIMAL']) for r in subset)
gain_a=sum(int(r['assigned_better']) for r in paired)
gain_secondary=sum(int(r['secondary_better']) for r in paired)
equal=sum(int(r['equal']) for r in paired)
worse=sum(int(r['worse']) for r in paired)
no_solution=sum(int(r['no_solution']) for r in paired)
summary=(f'В семи synthetic-семействах на 140 парных seed warm улучшил назначения в {gain_a}, '
         f'вторичные критерии в {gain_secondary}, был равен baseline в {equal}, хуже в {worse}; '
         f'несравнимых пар {no_solution}. OPTIMAL у warm: {opt}/140. ')
if gain_a+gain_secondary == 0:
    summary += ('Улучшений относительно baseline на этих входах не наблюдалось; '
                'это результат модели и повод обсудить с руководителем вклад дипломной темы. ')
if opt < 140:
    summary += 'При FEASIBLE отсутствие улучшения не доказывает отсутствие запаса до оптимума. '
summary += ('Все параметры PLACEHOLDER, применимость к реальному миру не установлена. '
            '[проверено запуском] [гипотеза] [TBD — решить с руководителем]')
report=lab/'docs/experiments/stage3/report.md'
report.write_text(report.read_text()+'\n## Интерпретация для темы\n\n'+summary+'\n')
run([python, '-m','pytest','-q'])
branch(repo, 'thesis/matching-lab')
run(['git','add','--','matching-lab/docs/experiments/stage3/report.md',
     'matching-lab/docs/experiments/stage3/summary.csv','matching-lab/docs/experiments/stage3/comparisons.csv'],repo)
run(['git','commit','-m','docs(matching): record complete serial stage 3 study'],repo)
run(['git','push','origin','thesis/matching-lab'],repo)

branch(vault,'docs/thesis-notes')
paths=[Path('Thesis/Experiment_Plan.md'),Path('Thesis/Stand_Design.md'),
       Path('Thesis/Matching_Problem_Spec.md'),Path('Thesis/Risks_and_Open_Questions.md')]
# Do not absorb edits made by the user while the long experiment was running.
check=subprocess.run(['git','diff','--quiet','HEAD','--',*[str(p) for p in paths]],cwd=vault)
if check.returncode != 0:
    raise RuntimeError('Thesis notes were modified during the study; report pushed, notes require manual merge')
for path in paths:
    full=vault/path
    with full.open('a',encoding='utf-8') as f:
        f.write('\n## Завершённый последовательный эксперимент этапа 3\n\n'+summary+
                ' Полные таблицы, фактический R, статусы, время и нагрузка: '
                '`BIRGEApp/matching-lab/docs/experiments/stage3/report.md`.\n')
run([python,'-m','pytest','-q'])
run(['git','add','--',*[str(p) for p in paths]],vault)
run(['git','commit','-m','docs(thesis): record complete stage 3 experiment'],vault)
run(['git','push','origin','docs/thesis-notes'],vault)
print('COMPLETED: report and notes pushed',flush=True)
