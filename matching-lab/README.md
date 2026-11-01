# BIRGE matching lab (этап 1)

Изолированный исследовательский стенд для пакетного назначения recurring passenger requests на hub-to-hub trips с водителями. Все результаты помечены `synthetic`; численные параметры YAML — `PLACEHOLDER: не откалибровано, согласовать с руководителем`. Конфиги с названиями low/medium/high — только сценарии smoke-run, не калиброванные классы спроса Алматы.

Этап 1 содержит детерминированный генератор, независимый валидатор, greedy baseline и метрики. ML не используется; основной решатель не выбран. ILP/min-cost assignment — гипотеза этапа 2. Определения, ограничения, tie-break и допущения описаны в [`docs/stand_design.md`](docs/stand_design.md).

Этап 1.5: дизайн v0.3 добавляет метрики наполненности, слабую нижнюю оценку рейсов, стабильность шаблонов и синтетические семейства; baseline остаётся v0.2.0. `exact_tiny` — проверочный перебор для малых случаев, не дипломный решатель.

## Требования

Python 3.11 или новее. Зависимости Python: только PyYAML для работы и pytest для тестов; numpy, pandas и OR-Tools не используются.

## Создать окружение и установить минимум

Из папки `matching-lab/`:

```sh
python3 -m venv .venv
.venv/bin/python -m pip install 'PyYAML>=6.0' 'pytest>=8.0'
```

## Тесты

```sh
PYTHONPATH=src .venv/bin/python -m pytest
```

## Пример эксперимента

Из папки `matching-lab/`:

```sh
PYTHONPATH=src .venv/bin/python -m matching_lab.runner --configs configs/low_density.yaml configs/medium_density.yaml configs/high_density.yaml --seeds 17,29,41 --output results
```

```sh
# Сравнение с точным эталоном только на маленьких данных
PYTHONPATH=src .venv/bin/python -m matching_lab.runner --configs configs/reference/coincident_windows.yaml --seeds 17 --exact --output results-reference
# Заранее заданные 2×2×2 семейства; масштабные сценарии запускаются отдельно
PYTHONPATH=src .venv/bin/python -m matching_lab.runner --configs configs/families/*.yaml --seeds 17,29,41 --output results-families
PYTHONPATH=src .venv/bin/python -m matching_lab.runner --configs configs/scale/*.yaml --seeds 17 --output results-scale
```

Эталон ограничен по умолчанию 8 активными заявками на день суммарно и 100 000 состояниями на день; лимиты настраиваются флагами `--exact-max-requests-per-day` и `--exact-max-states`. Превышение лимита останавливает запуск без заявления оптимума. Все параметры конфигов — PLACEHOLDER. Отношение к нижней оценке отсутствует при неполном назначении; точную трактовку см. в дизайне.

Команда выводит таблицу по каждому config × seed × solver, `results/results.json` с полным synthetic-сценарием, assignment, metadata и метриками, а также `results/metrics.csv`. Runner проверяет каждый результат независимым validator и прекращает работу при нарушениях. Runtime измеряется отдельно от генерации, валидации и записи файлов.

Метаданные включают `matching_lab_dirty`: при `true` или `null` SHA коммита не описывает гарантированно запущенный код. Для итоговых сравнений используйте чистую зафиксированную версию стенда и сохраняйте конфиги и результаты отдельно.

## Фиксированный baseline

Заявки сортируются по `(earliest window, preferred time, date, corridor, request template ID, instance ID)`. Solver сначала присоединяет заявку к совместимому существующему рейсу с минимальным отклонением, затем открывает новый на лучшем допустимом driver-slot; tie-break использует время и стабильные IDs. Полное правило записано в design document и не должно меняться после сравнительных запусков без версии нового протокола.

## CP-SAT: экспериментальный кандидат

`ilp_cpsat` — [гипотеза] [TBD — решить с руководителем], не утверждённый основной решатель; ADR-006 остаётся Proposed. Формальная модель и доказательство приоритетов: `docs/ilp_formulation.md`. Установка в локальное окружение: `.venv/bin/pip install '.[ilp]'`.

Предварительно зафиксированные параметры — PLACEHOLDER: `configs/experiments/stage2.yaml`, 20 seed и 16 семейств в `configs/cpsat_families/`. Уровни 25/50/75/100% означают долю от ориентира в 8 водителей, а не измеренное покрытие спроса. Запуск и статистика:

```sh
PYTHONPATH=src .venv/bin/python -m matching_lab.runner --configs configs/cpsat_families/*.yaml --experiment-config configs/experiments/stage2.yaml --solvers baseline_greedy ilp_cpsat --output results/stage2
PYTHONPATH=src .venv/bin/python -m matching_lab.summary results/stage2/results.json --output results/stage2-summary
```

Каждый результат проверяется валидатором перед сохранением. `UNKNOWN`/`INFEASIBLE` не включаются в метрики качества; `FEASIBLE` не доказывает оптимальность. Сетка ограничивает множество допустимых времён, лимит CP-SAT не включает построение модели; полное время решателя записано отдельно. Все данные synthetic.
