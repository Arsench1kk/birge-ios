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

Эталон ограничен 8 активными заявками на день суммарно и 100 000 состояниями на день (`--exact-max-states` меняет второй лимит). Превышение лимита останавливает запуск без заявления оптимума. Все параметры конфигов — PLACEHOLDER. Отношение к нижней оценке отсутствует при неполном назначении; точную трактовку см. в дизайне.

Команда выводит таблицу по каждому config × seed × solver, `results/results.json` с полным synthetic-сценарием, assignment, metadata и метриками, а также `results/metrics.csv`. Runner проверяет каждый результат независимым validator и прекращает работу при нарушениях. Runtime измеряется отдельно от генерации, валидации и записи файлов.

Метаданные включают `matching_lab_dirty`: при `true` или `null` SHA коммита не описывает гарантированно запущенный код. Для итоговых сравнений используйте чистую зафиксированную версию стенда и сохраняйте конфиги и результаты отдельно.

## Фиксированный baseline

Заявки сортируются по `(earliest window, preferred time, date, corridor, request template ID, instance ID)`. Solver сначала присоединяет заявку к совместимому существующему рейсу с минимальным отклонением, затем открывает новый на лучшем допустимом driver-slot; tie-break использует время и стабильные IDs. Полное правило записано в design document и не должно меняться после сравнительных запусков без версии нового протокола.
