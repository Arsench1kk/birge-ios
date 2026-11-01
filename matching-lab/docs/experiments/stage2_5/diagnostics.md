# Диагностика модели этапа 2

Синтетические данные, PLACEHOLDER; неизменённый решатель commit `b4d6d799`; seed 1, шаг 10 минут, 1 поток, лимит CP-SAT 0,5 с. Протокол зафиксирован до запуска в `configs/experiments/stage25_diagnostics.json`. Скрипт перехватывает вызов `CpSolver.Solve`, не меняя решатель. Построение включает подготовку baseline hint и Python-модели; решение — длительность вызова Solve, включая накладные расходы Python/OR-Tools. Счётчик ограничений включает interval и NoOverlap, а переменных — x, y и unassigned. Все результаты проверены валидатором.

| Конфиг | Активно | y | x | Всего переменных | Ограничений | Построение, с | Solve, с | Статус | Hint |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| high_narrow_supply_025 | 164 | 1116 | 2356 | 3636 | 3704 | 0.055 | 0.503 | FEASIBLE | baseline |
| high_narrow_supply_050 | 164 | 2232 | 4712 | 7108 | 7080 | 0.111 | 0.505 | FEASIBLE | baseline |
| high_narrow_supply_075 | 164 | 3348 | 7068 | 10580 | 10456 | 0.161 | 0.449 | UNKNOWN | empty |
| high_narrow_supply_100 | 164 | 4464 | 9424 | 14052 | 13832 | 0.207 | 0.343 | UNKNOWN | baseline |
| high_wide_supply_025 | 164 | 2252 | 10000 | 12416 | 7112 | 0.181 | 0.418 | UNKNOWN | empty |
| high_wide_supply_050 | 164 | 4504 | 20000 | 24668 | 13896 | 0.353 | 0.531 | UNKNOWN | baseline |
| high_wide_supply_075 | 164 | 6756 | 30000 | 36920 | 20680 | 0.537 | 0.544 | UNKNOWN | baseline |
| high_wide_supply_100 | 164 | 9008 | 40000 | 49172 | 27464 | 0.748 | 0.581 | UNKNOWN | baseline |
| low_narrow_supply_025 | 20 | 200 | 200 | 420 | 664 | 0.007 | 0.017 | OPTIMAL | baseline |
| low_narrow_supply_050 | 20 | 400 | 400 | 820 | 1288 | 0.013 | 0.029 | OPTIMAL | baseline |
| low_narrow_supply_075 | 20 | 600 | 600 | 1220 | 1912 | 0.019 | 0.044 | OPTIMAL | baseline |
| low_narrow_supply_100 | 20 | 800 | 800 | 1620 | 2536 | 0.025 | 0.062 | OPTIMAL | baseline |
| low_wide_supply_025 | 20 | 444 | 492 | 956 | 1396 | 0.016 | 0.043 | OPTIMAL | baseline |
| low_wide_supply_050 | 20 | 888 | 984 | 1892 | 2752 | 0.029 | 0.090 | OPTIMAL | baseline |
| low_wide_supply_075 | 20 | 1332 | 1476 | 2828 | 4108 | 0.046 | 0.150 | OPTIMAL | baseline |
| low_wide_supply_100 | 20 | 1776 | 1968 | 3764 | 5464 | 0.061 | 0.233 | OPTIMAL | baseline |
| high_narrow_scarce | 164 | 540 | 1160 | 1864 | 1962 | 0.027 | 0.509 | FEASIBLE | baseline |
| high_narrow_surplus | 164 | 4464 | 9424 | 14052 | 13832 | 0.212 | 0.347 | UNKNOWN | baseline |
| high_wide_scarce | 164 | 944 | 4572 | 5680 | 3174 | 0.086 | 0.506 | FEASIBLE | empty |
| high_wide_surplus | 164 | 9008 | 40000 | 49172 | 27464 | 0.936 | 0.606 | UNKNOWN | baseline |
| low_narrow_scarce | 20 | 100 | 100 | 220 | 352 | 0.004 | 0.010 | OPTIMAL | baseline |
| low_narrow_surplus | 20 | 800 | 800 | 1620 | 2536 | 0.026 | 0.080 | OPTIMAL | baseline |
| low_wide_scarce | 20 | 208 | 232 | 460 | 676 | 0.009 | 0.222 | OPTIMAL | empty |
| low_wide_surplus | 20 | 1776 | 1968 | 3764 | 5464 | 0.207 | 0.286 | OPTIMAL | baseline |
| scale_hundreds | 240 | 16520 | 129120 | 145880 | 50180 | 2.177 | 1.393 | UNKNOWN | baseline |
| scale_thousands | 1200 | 27760 | 723760 | 752720 | 85820 | 11.891 | 1.172 | UNKNOWN | baseline |

В seed 1 широкие окна создают больше времён-кандидатов и больше совместимых пар заявка–рейс, а увеличение числа водителей размножает кандидаты. Например, high_narrow_supply_100: 9 424 x, high_wide_supply_100: 40 000 x при одинаковых 164 активных заявках. В масштабе 240 → 1200 заявок число x растёт 129 120 → 723 760, время построения 2,177 → 11,891 с. Это наблюдения для одного seed, не оценка сложности для всех входов.

Существующая версия уже передавала baseline как hint, если все его отправления попадали в домен; иначе она передавала пустой hint. Hint не гарантировал допустимого результата в лимит. Отдельная чистая версия и проверенная гарантия возврата baseline нужны для корректного сравнения.
