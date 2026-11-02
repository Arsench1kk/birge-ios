# Этап 5: результаты

Синтетические данные; все параметры PLACEHOLDER. Оценка seed 1–20; масштаб seed 1–3; 10 с поиска на дату, один поток. W по семействам и эвристики — сохранённые результаты этапа 4, warm2 — новый запуск, времена не являются парными замерами одной сессии. Сохранённый W использовал CP-SAT 0.3.0, warm2 — модель 0.4.0, поэтому изменения результата не изолируют эффект стартовой точки. OPTIMAL относится к конечному кандидатному домену; warm2 может добавлять к нему время hint. Bootstrap 2000 повторов, seed 451; percentile 95%.

warm2 отличается от W стартом: лучшая лексикографически из baseline_v2 и greedy_retiming вместо baseline 0.2.0. Каждая стартовая точка и итог проходят независимый валидатор; fallback гарантирует результат не хуже выбранного старта, но не OPTIMAL. Разбор high_few на dev seed и примеры рейсов: `../../heuristics.md`. Исходные эвристики на оценочных seed отдельно не пересчитывались; внутри warm2 их вычисление необходимо для построения hint.

## Семейства: среднее ± выборочное СО

| Семейство | Режим | n | R | Совместимость | Назначено | Рейсы | Отклонение | Отклонение/пасс. | Пасс./рейс | Время, с | Построение, с | Поиск, с | OPT/FEAS/UNKNOWN | fallback дат |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| stage3_control | baseline_greedy | 20 | 13.847 ± 0.794 | 1.000 ± 0.000 | 159.750 ± 0.550 | 81.850 ± 6.252 | 773.800 ± 102.710 | 4.845 ± 0.650 | 1.962 ± 0.147 | 0.021 ± 0.003 | н/д | н/д | 0/0/0 | 0 |
| stage3_control | baseline_v2 | 20 | 13.847 ± 0.794 | 1.000 ± 0.000 | 160.000 ± 0.000 | 67.200 ± 5.836 | 1139.800 ± 166.226 | 7.124 ± 1.039 | 2.398 ± 0.206 | 0.007 ± 0.001 | н/д | н/д | 0/0/0 | 0 |
| stage3_control | greedy_retiming | 20 | 13.847 ± 0.794 | 1.000 ± 0.000 | 160.000 ± 0.000 | 66.450 ± 5.624 | 1002.450 ± 159.474 | 6.265 ± 0.997 | 2.424 ± 0.200 | 0.050 ± 0.014 | н/д | н/д | 0/0/0 | 0 |
| stage3_control | ilp_cpsat+warm | 20 | 13.847 ± 0.794 | 1.000 ± 0.000 | 160.000 ± 0.000 | 78.550 ± 6.039 | 678.200 ± 89.075 | 4.239 ± 0.557 | 2.048 ± 0.158 | 50.402 ± 0.334 | 0.323 ± 0.239 | 50.028 ± 0.061 | 0/20/0 | 0 |
| stage3_control | ilp_cpsat+warm2 | 20 | 13.847 ± 0.794 | 1.000 ± 0.000 | 160.000 ± 0.000 | 66.200 ± 5.483 | 934.000 ± 160.689 | 5.838 ± 1.004 | 2.432 ± 0.196 | 50.332 ± 0.084 | 0.255 ± 0.082 | 50.007 ± 0.014 | 0/20/0 | 0 |
| stage3_high_few | baseline_greedy | 20 | 0.431 ± 0.064 | 0.589 ± 0.128 | 38.900 ± 9.375 | 15.050 ± 2.373 | 332.600 ± 125.371 | 8.475 ± 2.099 | 2.603 ± 0.535 | 0.001 ± 0.000 | н/д | н/д | 0/0/0 | 0 |
| stage3_high_few | baseline_v2 | 20 | 0.431 ± 0.064 | 0.589 ± 0.128 | 37.600 ± 9.746 | 13.050 ± 2.544 | 313.750 ± 113.309 | 8.252 ± 2.341 | 2.880 ± 0.471 | 0.001 ± 0.000 | н/д | н/д | 0/0/0 | 0 |
| stage3_high_few | greedy_retiming | 20 | 0.431 ± 0.064 | 0.589 ± 0.128 | 37.950 ± 9.779 | 13.050 ± 2.544 | 316.900 ± 112.340 | 8.262 ± 2.299 | 2.907 ± 0.470 | 0.002 ± 0.000 | н/д | н/д | 0/0/0 | 0 |
| stage3_high_few | ilp_cpsat+warm | 20 | 0.431 ± 0.064 | 0.589 ± 0.128 | 52.250 ± 10.804 | 18.050 ± 2.012 | 438.050 ± 126.220 | 8.399 ± 2.163 | 2.888 ± 0.453 | 0.249 ± 0.236 | 0.020 ± 0.005 | 0.226 ± 0.231 | 20/0/0 | 0 |
| stage3_high_few | ilp_cpsat+warm2 | 20 | 0.431 ± 0.064 | 0.589 ± 0.128 | 50.800 ± 11.915 | 17.450 ± 2.982 | 425.800 ± 147.798 | 8.276 ± 2.462 | 2.909 ± 0.402 | 0.288 ± 0.255 | 0.038 ± 0.085 | 0.246 ± 0.237 | 20/0/0 | 0 |
| stage3_high_many | baseline_greedy | 20 | 0.431 ± 0.064 | 0.650 ± 0.088 | 50.600 ± 11.038 | 19.550 ± 0.510 | 483.050 ± 182.353 | 9.340 ± 2.164 | 2.586 ± 0.538 | 0.001 ± 0.000 | н/д | н/д | 0/0/0 | 0 |
| stage3_high_many | baseline_v2 | 20 | 0.431 ± 0.064 | 0.650 ± 0.088 | 54.400 ± 8.593 | 19.600 ± 0.598 | 439.500 ± 105.848 | 8.086 ± 1.546 | 2.770 ± 0.393 | 0.001 ± 0.000 | н/д | н/д | 0/0/0 | 0 |
| stage3_high_many | greedy_retiming | 20 | 0.431 ± 0.064 | 0.650 ± 0.088 | 54.400 ± 8.593 | 19.600 ± 0.598 | 439.000 ± 105.864 | 8.079 ± 1.554 | 2.770 ± 0.393 | 0.002 ± 0.000 | н/д | н/д | 0/0/0 | 0 |
| stage3_high_many | ilp_cpsat+warm | 20 | 0.431 ± 0.064 | 0.650 ± 0.088 | 56.900 ± 9.738 | 19.650 ± 0.489 | 411.550 ± 122.104 | 7.197 ± 1.553 | 2.891 ± 0.457 | 0.079 ± 0.034 | 0.011 ± 0.001 | 0.066 ± 0.033 | 20/0/0 | 0 |
| stage3_high_many | ilp_cpsat+warm2 | 20 | 0.431 ± 0.064 | 0.650 ± 0.088 | 56.900 ± 9.738 | 19.650 ± 0.489 | 411.600 ± 123.093 | 7.199 ± 1.577 | 2.891 ± 0.457 | 0.081 ± 0.043 | 0.011 ± 0.002 | 0.066 ± 0.041 | 20/0/0 | 0 |
| stage3_low_few | baseline_greedy | 20 | 1.319 ± 0.076 | 0.675 ± 0.111 | 79.300 ± 13.456 | 33.950 ± 3.859 | 618.350 ± 171.402 | 7.782 ± 1.675 | 2.337 ± 0.303 | 0.003 ± 0.000 | н/д | н/д | 0/0/0 | 0 |
| stage3_low_few | baseline_v2 | 20 | 1.319 ± 0.076 | 0.675 ± 0.111 | 94.400 ± 13.068 | 35.900 ± 3.243 | 877.850 ± 211.924 | 9.275 ± 1.667 | 2.630 ± 0.279 | 0.002 ± 0.000 | н/д | н/д | 0/0/0 | 0 |
| stage3_low_few | greedy_retiming | 20 | 1.319 ± 0.076 | 0.675 ± 0.111 | 95.000 ± 13.075 | 35.550 ± 3.300 | 816.250 ± 189.453 | 8.597 ± 1.589 | 2.671 ± 0.267 | 0.014 ± 0.008 | н/д | н/д | 0/0/0 | 0 |
| stage3_low_few | ilp_cpsat+warm | 20 | 1.319 ± 0.076 | 0.675 ± 0.111 | 101.550 ± 14.870 | 37.000 ± 4.460 | 824.050 ± 171.788 | 8.185 ± 1.536 | 2.741 ± 0.212 | 8.262 ± 8.723 | 0.044 ± 0.008 | 8.212 ± 8.718 | 17/3/0 | 0 |
| stage3_low_few | ilp_cpsat+warm2 | 20 | 1.319 ± 0.076 | 0.675 ± 0.111 | 101.850 ± 15.006 | 37.100 ± 4.494 | 831.250 ± 173.482 | 8.226 ± 1.499 | 2.742 ± 0.223 | 7.878 ± 8.636 | 0.044 ± 0.009 | 7.814 ± 8.635 | 18/2/0 | 0 |
| stage3_low_many | baseline_greedy | 20 | 1.319 ± 0.076 | 0.785 ± 0.118 | 103.900 ± 14.839 | 44.900 ± 4.564 | 813.900 ± 203.597 | 7.820 ± 1.344 | 2.324 ± 0.335 | 0.002 ± 0.000 | н/д | н/д | 0/0/0 | 0 |
| stage3_low_many | baseline_v2 | 20 | 1.319 ± 0.076 | 0.785 ± 0.118 | 116.150 ± 15.226 | 46.100 ± 5.360 | 1010.500 ± 238.727 | 8.653 ± 1.366 | 2.531 ± 0.273 | 0.002 ± 0.000 | н/д | н/д | 0/0/0 | 0 |
| stage3_low_many | greedy_retiming | 20 | 1.319 ± 0.076 | 0.785 ± 0.118 | 116.550 ± 15.565 | 45.900 ± 5.310 | 940.000 ± 225.527 | 8.021 ± 1.264 | 2.550 ± 0.279 | 0.018 ± 0.008 | н/д | н/д | 0/0/0 | 0 |
| stage3_low_many | ilp_cpsat+warm | 20 | 1.319 ± 0.076 | 0.785 ± 0.118 | 119.600 ± 16.366 | 45.250 ± 5.240 | 909.500 ± 204.282 | 7.593 ± 1.220 | 2.652 ± 0.285 | 3.535 ± 4.135 | 0.021 ± 0.003 | 3.509 ± 4.132 | 19/1/0 | 0 |
| stage3_low_many | ilp_cpsat+warm2 | 20 | 1.319 ± 0.076 | 0.785 ± 0.118 | 119.600 ± 16.366 | 45.250 ± 5.240 | 908.050 ± 202.810 | 7.581 ± 1.204 | 2.652 ± 0.285 | 3.206 ± 3.682 | 0.022 ± 0.006 | 3.161 ± 3.680 | 19/1/0 | 0 |
| stage3_medium_few | baseline_greedy | 20 | 0.875 ± 0.091 | 0.621 ± 0.116 | 62.400 ± 12.890 | 25.600 ± 2.873 | 489.350 ± 171.377 | 7.751 ± 1.935 | 2.437 ± 0.434 | 0.002 ± 0.000 | н/д | н/д | 0/0/0 | 0 |
| stage3_medium_few | baseline_v2 | 20 | 0.875 ± 0.091 | 0.621 ± 0.116 | 68.900 ± 10.662 | 25.150 ± 3.167 | 628.200 ± 187.230 | 9.062 ± 2.116 | 2.753 ± 0.358 | 0.002 ± 0.000 | н/д | н/д | 0/0/0 | 0 |
| stage3_medium_few | greedy_retiming | 20 | 0.875 ± 0.091 | 0.621 ± 0.116 | 69.650 ± 10.718 | 25.100 ± 3.144 | 620.850 ± 181.970 | 8.883 ± 2.094 | 2.786 ± 0.340 | 0.004 ± 0.002 | н/д | н/д | 0/0/0 | 0 |
| stage3_medium_few | ilp_cpsat+warm | 20 | 0.875 ± 0.091 | 0.621 ± 0.116 | 81.750 ± 13.333 | 29.850 ± 3.297 | 697.650 ± 171.334 | 8.577 ± 1.825 | 2.738 ± 0.316 | 2.635 ± 6.050 | 0.027 ± 0.006 | 2.603 ± 6.046 | 19/1/0 | 0 |
| stage3_medium_few | ilp_cpsat+warm2 | 20 | 0.875 ± 0.091 | 0.621 ± 0.116 | 81.550 ± 13.446 | 29.900 ± 3.275 | 689.750 ± 182.423 | 8.494 ± 1.972 | 2.726 ± 0.312 | 2.645 ± 5.412 | 0.028 ± 0.006 | 2.610 ± 5.408 | 20/0/0 | 0 |
| stage3_medium_many | baseline_greedy | 20 | 0.875 ± 0.091 | 0.706 ± 0.097 | 81.850 ± 14.572 | 33.450 ± 2.911 | 650.200 ± 190.090 | 7.922 ± 1.659 | 2.444 ± 0.354 | 0.001 ± 0.000 | н/д | н/д | 0/0/0 | 0 |
| stage3_medium_many | baseline_v2 | 20 | 0.875 ± 0.091 | 0.706 ± 0.097 | 89.200 ± 12.668 | 33.800 ± 2.726 | 732.100 ± 199.262 | 8.113 ± 1.357 | 2.649 ± 0.371 | 0.002 ± 0.000 | н/д | н/д | 0/0/0 | 0 |
| stage3_medium_many | greedy_retiming | 20 | 0.875 ± 0.091 | 0.706 ± 0.097 | 89.400 ± 12.804 | 33.700 ± 2.867 | 703.250 ± 187.420 | 7.782 ± 1.280 | 2.665 ± 0.385 | 0.007 ± 0.004 | н/д | н/д | 0/0/0 | 0 |
| stage3_medium_many | ilp_cpsat+warm | 20 | 0.875 ± 0.091 | 0.706 ± 0.097 | 93.250 ± 13.333 | 34.300 ± 2.886 | 708.650 ± 186.970 | 7.543 ± 1.329 | 2.725 ± 0.350 | 0.151 ± 0.120 | 0.014 ± 0.002 | 0.134 ± 0.118 | 20/0/0 | 0 |
| stage3_medium_many | ilp_cpsat+warm2 | 20 | 0.875 ± 0.091 | 0.706 ± 0.097 | 93.250 ± 13.333 | 34.300 ± 2.886 | 708.650 ± 185.168 | 7.540 ± 1.291 | 2.725 ± 0.350 | 0.175 ± 0.139 | 0.014 ± 0.002 | 0.150 ± 0.135 | 20/0/0 | 0 |

## Размер одной даты

| Сценарий | Режим | n | R | Совместимость | Назначено | Рейсы | Отклонение | Отклонение/пасс. | Пасс./рейс | Время, с | Построение, с | Поиск, с | OPT/FEAS/UNKNOWN | fallback дат |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| stage5_medium_few_100 | baseline_v2 | 3 | 0.640 ± 0.000 | 0.740 ± 0.040 | 47.333 ± 5.033 | 16.000 ± 2.000 | 432.667 ± 161.810 | 8.977 ± 2.464 | 2.963 ± 0.064 | 0.002 ± 0.000 | 0.002 ± 0.000 | 0.000 ± 0.000 | 0/0/0 | 0 |
| stage5_medium_few_100 | greedy_retiming | 3 | 0.640 ± 0.000 | 0.740 ± 0.040 | 48.333 ± 5.508 | 16.000 ± 2.000 | 429.333 ± 162.263 | 8.713 ± 2.301 | 3.024 ± 0.041 | 0.004 ± 0.001 | 0.002 ± 0.000 | 0.002 ± 0.001 | 0/0/0 | 0 |
| stage5_medium_few_100 | ilp_cpsat+warm | 3 | 0.640 ± 0.000 | 0.740 ± 0.040 | 48.000 ± 3.000 | 15.333 ± 0.577 | 305.333 ± 139.500 | 6.270 ± 2.484 | 3.129 ± 0.112 | 10.052 ± 0.008 | 0.047 ± 0.008 | 10.001 ± 0.000 | 0/3/0 | 0 |
| stage5_medium_few_100 | ilp_cpsat+warm2 | 3 | 0.640 ± 0.000 | 0.740 ± 0.040 | 51.000 ± 4.359 | 17.000 ± 1.732 | 392.000 ± 200.651 | 7.512 ± 3.152 | 3.003 ± 0.058 | 10.084 ± 0.053 | 0.051 ± 0.010 | 10.026 ± 0.046 | 0/3/0 | 0 |
| stage5_medium_few_200 | baseline_v2 | 3 | 0.693 ± 0.042 | 0.775 ± 0.018 | 109.667 ± 5.686 | 33.000 ± 1.000 | 1061.333 ± 145.180 | 9.677 ± 1.233 | 3.324 ± 0.173 | 0.006 ± 0.000 | 0.006 ± 0.000 | 0.000 ± 0.000 | 0/0/0 | 0 |
| stage5_medium_few_200 | greedy_retiming | 3 | 0.693 ± 0.042 | 0.775 ± 0.018 | 110.000 ± 5.568 | 33.000 ± 1.000 | 1053.000 ± 132.593 | 9.575 ± 1.134 | 3.334 ± 0.161 | 0.008 ± 0.001 | 0.006 ± 0.000 | 0.002 ± 0.001 | 0/0/0 | 0 |
| stage5_medium_few_200 | ilp_cpsat+warm | 3 | 0.693 ± 0.042 | 0.775 ± 0.018 | 92.667 ± 1.528 | 28.667 ± 2.082 | 565.333 ± 110.817 | 6.089 ± 1.100 | 3.242 ± 0.206 | 10.234 ± 0.042 | 0.218 ± 0.040 | 10.002 ± 0.002 | 0/3/0 | 0 |
| stage5_medium_few_200 | ilp_cpsat+warm2 | 3 | 0.693 ± 0.042 | 0.775 ± 0.018 | 110.000 ± 5.568 | 33.000 ± 1.000 | 1047.333 ± 137.318 | 9.523 ± 1.173 | 3.334 ± 0.161 | 10.232 ± 0.020 | 0.208 ± 0.017 | 10.003 ± 0.003 | 0/3/0 | 0 |
| stage5_medium_few_400 | baseline_v2 | 3 | 0.703 ± 0.006 | 0.773 ± 0.017 | 229.667 ± 10.263 | 66.667 ± 3.055 | 2218.000 ± 201.174 | 9.645 ± 0.453 | 3.445 ± 0.007 | 0.023 ± 0.002 | 0.023 ± 0.002 | 0.000 ± 0.000 | 0/0/0 | 0 |
| stage5_medium_few_400 | greedy_retiming | 3 | 0.703 ± 0.006 | 0.773 ± 0.017 | 229.667 ± 10.263 | 66.667 ± 3.055 | 2218.000 ± 201.174 | 9.645 ± 0.453 | 3.445 ± 0.007 | 0.025 ± 0.002 | 0.023 ± 0.002 | 0.002 ± 0.000 | 0/0/0 | 0 |
| stage5_medium_few_400 | ilp_cpsat+warm | 3 | 0.703 ± 0.006 | 0.773 ± 0.017 | 177.333 ± 17.010 | 50.667 ± 4.933 | 1180.333 ± 58.654 | 6.686 ± 0.537 | 3.500 ± 0.025 | 10.897 ± 0.055 | 0.822 ± 0.053 | 10.015 ± 0.002 | 0/3/0 | 0 |
| stage5_medium_few_400 | ilp_cpsat+warm2 | 3 | 0.703 ± 0.006 | 0.773 ± 0.017 | 229.667 ± 10.263 | 66.667 ± 3.055 | 2218.000 ± 201.174 | 9.645 ± 0.453 | 3.445 ± 0.007 | 11.025 ± 0.166 | 0.939 ± 0.166 | 10.014 ± 0.001 | 0/3/0 | 0 |
| stage5_medium_few_50 | baseline_v2 | 3 | 0.560 ± 0.080 | 0.687 ± 0.023 | 18.667 ± 6.658 | 6.000 ± 1.000 | 151.333 ± 57.882 | 8.054 ± 1.224 | 3.049 ± 0.588 | 0.001 ± 0.000 | 0.001 ± 0.000 | 0.000 ± 0.000 | 0/0/0 | 0 |
| stage5_medium_few_50 | greedy_retiming | 3 | 0.560 ± 0.080 | 0.687 ± 0.023 | 18.667 ± 6.658 | 6.000 ± 1.000 | 151.333 ± 57.882 | 8.054 ± 1.224 | 3.049 ± 0.588 | 0.001 ± 0.000 | 0.001 ± 0.000 | 0.000 ± 0.000 | 0/0/0 | 0 |
| stage5_medium_few_50 | ilp_cpsat+warm | 3 | 0.560 ± 0.080 | 0.687 ± 0.023 | 22.333 ± 4.509 | 7.000 ± 1.000 | 175.667 ± 51.209 | 7.767 ± 0.857 | 3.202 ± 0.581 | 1.654 ± 0.743 | 0.009 ± 0.001 | 1.643 ± 0.741 | 3/0/0 | 0 |
| stage5_medium_few_50 | ilp_cpsat+warm2 | 3 | 0.560 ± 0.080 | 0.687 ± 0.023 | 22.333 ± 4.509 | 7.000 ± 1.000 | 172.333 ± 51.013 | 7.616 ± 0.771 | 3.202 ± 0.581 | 1.521 ± 0.949 | 0.009 ± 0.001 | 1.510 ± 0.948 | 3/0/0 | 0 |
| stage5_medium_few_800 | baseline_v2 | 3 | 0.712 ± 0.010 | 0.767 ± 0.014 | 475.667 ± 20.599 | 136.333 ± 4.509 | 5087.000 ± 206.640 | 10.695 ± 0.031 | 3.488 ± 0.042 | 0.094 ± 0.011 | 0.094 ± 0.011 | 0.000 ± 0.000 | 0/0/0 | 0 |
| stage5_medium_few_800 | greedy_retiming | 3 | 0.712 ± 0.010 | 0.767 ± 0.014 | 475.667 ± 20.599 | 136.333 ± 4.509 | 5087.000 ± 206.640 | 10.695 ± 0.031 | 3.488 ± 0.042 | 0.096 ± 0.009 | 0.093 ± 0.009 | 0.003 ± 0.000 | 0/0/0 | 0 |
| stage5_medium_few_800 | ilp_cpsat+warm | 3 | 0.712 ± 0.010 | 0.767 ± 0.014 | 344.667 ± 16.197 | 97.333 ± 4.726 | 2201.333 ± 44.636 | 6.393 ± 0.185 | 3.541 ± 0.045 | 13.478 ± 0.378 | 3.274 ± 0.197 | 9.893 ± 0.354 | 0/3/0 | 3 |
| stage5_medium_few_800 | ilp_cpsat+warm2 | 3 | 0.712 ± 0.010 | 0.767 ± 0.014 | 475.667 ± 20.599 | 136.333 ± 4.509 | 5087.000 ± 206.640 | 10.695 ± 0.031 | 3.488 ± 0.042 | 13.620 ± 0.183 | 3.310 ± 0.152 | 9.993 ± 0.304 | 0/3/0 | 3 |
| stage5_medium_many_100 | baseline_v2 | 3 | 0.640 ± 0.000 | 0.837 ± 0.023 | 57.000 ± 4.359 | 19.333 ± 0.577 | 473.667 ± 139.030 | 8.276 ± 2.133 | 2.948 ± 0.211 | 0.002 ± 0.000 | 0.002 ± 0.000 | 0.000 ± 0.000 | 0/0/0 | 0 |
| stage5_medium_many_100 | greedy_retiming | 3 | 0.640 ± 0.000 | 0.837 ± 0.023 | 57.000 ± 4.359 | 19.333 ± 0.577 | 455.667 ± 118.492 | 7.963 ± 1.767 | 2.948 ± 0.211 | 0.004 ± 0.001 | 0.002 ± 0.000 | 0.002 ± 0.001 | 0/0/0 | 0 |
| stage5_medium_many_100 | ilp_cpsat+warm | 3 | 0.640 ± 0.000 | 0.837 ± 0.023 | 58.333 ± 3.786 | 19.667 ± 0.577 | 306.000 ± 77.949 | 5.222 ± 1.142 | 2.964 ± 0.109 | 10.025 ± 0.001 | 0.021 ± 0.001 | 10.001 ± 0.000 | 0/3/0 | 0 |
| stage5_medium_many_100 | ilp_cpsat+warm2 | 3 | 0.640 ± 0.000 | 0.837 ± 0.023 | 58.333 ± 3.786 | 19.667 ± 0.577 | 304.667 ± 76.068 | 5.198 ± 1.100 | 2.964 ± 0.109 | 10.028 ± 0.002 | 0.020 ± 0.001 | 10.001 ± 0.000 | 0/3/0 | 0 |
| stage5_medium_many_200 | baseline_v2 | 3 | 0.693 ± 0.042 | 0.885 ± 0.009 | 125.000 ± 6.083 | 37.667 ± 0.577 | 1082.333 ± 20.306 | 8.669 ± 0.363 | 3.321 ± 0.214 | 0.005 ± 0.000 | 0.005 ± 0.000 | 0.000 ± 0.000 | 0/0/0 | 0 |
| stage5_medium_many_200 | greedy_retiming | 3 | 0.693 ± 0.042 | 0.885 ± 0.009 | 125.667 ± 7.234 | 37.667 ± 0.577 | 1098.333 ± 40.550 | 8.748 ± 0.238 | 3.339 ± 0.245 | 0.008 ± 0.002 | 0.006 ± 0.000 | 0.002 ± 0.002 | 0/0/0 | 0 |
| stage5_medium_many_200 | ilp_cpsat+warm | 3 | 0.693 ± 0.042 | 0.885 ± 0.009 | 128.667 ± 6.351 | 37.667 ± 1.155 | 750.667 ± 52.880 | 5.838 ± 0.406 | 3.420 ± 0.238 | 10.087 ± 0.009 | 0.081 ± 0.002 | 9.998 ± 0.006 | 0/3/0 | 0 |
| stage5_medium_many_200 | ilp_cpsat+warm2 | 3 | 0.693 ± 0.042 | 0.885 ± 0.009 | 128.667 ± 6.351 | 37.667 ± 1.155 | 763.333 ± 35.076 | 5.935 ± 0.169 | 3.420 ± 0.238 | 10.098 ± 0.003 | 0.080 ± 0.001 | 10.000 ± 0.001 | 0/3/0 | 0 |
| stage5_medium_many_400 | baseline_v2 | 3 | 0.703 ± 0.006 | 0.884 ± 0.014 | 254.333 ± 5.508 | 74.333 ± 0.577 | 2135.667 ± 122.173 | 8.407 ± 0.657 | 3.421 ± 0.052 | 0.022 ± 0.000 | 0.022 ± 0.000 | 0.000 ± 0.000 | 0/0/0 | 0 |
| stage5_medium_many_400 | greedy_retiming | 3 | 0.703 ± 0.006 | 0.884 ± 0.014 | 254.333 ± 5.508 | 74.333 ± 0.577 | 2135.667 ± 122.173 | 8.407 ± 0.657 | 3.421 ± 0.052 | 0.024 ± 0.000 | 0.022 ± 0.000 | 0.002 ± 0.000 | 0/0/0 | 0 |
| stage5_medium_many_400 | ilp_cpsat+warm | 3 | 0.703 ± 0.006 | 0.884 ± 0.014 | 258.000 ± 7.211 | 76.000 ± 1.000 | 2151.333 ± 32.517 | 8.343 ± 0.261 | 3.396 ± 0.138 | 10.341 ± 0.019 | 0.305 ± 0.019 | 10.003 ± 0.002 | 0/3/0 | 0 |
| stage5_medium_many_400 | ilp_cpsat+warm2 | 3 | 0.703 ± 0.006 | 0.884 ± 0.014 | 262.333 ± 2.082 | 75.000 ± 0.000 | 2241.333 ± 22.480 | 8.544 ± 0.111 | 3.498 ± 0.028 | 10.353 ± 0.010 | 0.293 ± 0.008 | 10.003 ± 0.001 | 0/3/0 | 0 |
| stage5_medium_many_50 | baseline_v2 | 3 | 0.560 ± 0.080 | 0.773 ± 0.064 | 24.000 ± 3.000 | 7.333 ± 0.577 | 195.000 ± 37.269 | 8.095 ± 0.930 | 3.286 ± 0.495 | 0.001 ± 0.000 | 0.001 ± 0.000 | 0.000 ± 0.000 | 0/0/0 | 0 |
| stage5_medium_many_50 | greedy_retiming | 3 | 0.560 ± 0.080 | 0.773 ± 0.064 | 24.000 ± 3.000 | 7.333 ± 0.577 | 195.000 ± 37.269 | 8.095 ± 0.930 | 3.286 ± 0.495 | 0.001 ± 0.000 | 0.001 ± 0.000 | 0.000 ± 0.000 | 0/0/0 | 0 |
| stage5_medium_many_50 | ilp_cpsat+warm | 3 | 0.560 ± 0.080 | 0.773 ± 0.064 | 24.333 ± 3.512 | 7.667 ± 0.577 | 163.667 ± 44.970 | 6.657 ± 1.211 | 3.167 ± 0.289 | 0.055 ± 0.036 | 0.005 ± 0.000 | 0.050 ± 0.036 | 3/0/0 | 0 |
| stage5_medium_many_50 | ilp_cpsat+warm2 | 3 | 0.560 ± 0.080 | 0.773 ± 0.064 | 24.333 ± 3.512 | 7.667 ± 0.577 | 163.667 ± 44.970 | 6.657 ± 1.211 | 3.167 ± 0.289 | 0.059 ± 0.047 | 0.005 ± 0.000 | 0.053 ± 0.047 | 3/0/0 | 0 |
| stage5_medium_many_800 | baseline_v2 | 3 | 0.712 ± 0.010 | 0.880 ± 0.014 | 521.667 ± 1.528 | 149.000 ± 2.000 | 4600.667 ± 204.295 | 8.819 ± 0.390 | 3.501 ± 0.041 | 0.098 ± 0.001 | 0.098 ± 0.001 | 0.000 ± 0.000 | 0/0/0 | 0 |
| stage5_medium_many_800 | greedy_retiming | 3 | 0.712 ± 0.010 | 0.880 ± 0.014 | 521.667 ± 1.528 | 149.000 ± 2.000 | 4600.667 ± 204.295 | 8.819 ± 0.390 | 3.501 ± 0.041 | 0.100 ± 0.001 | 0.096 ± 0.001 | 0.003 ± 0.000 | 0/0/0 | 0 |
| stage5_medium_many_800 | ilp_cpsat+warm | 3 | 0.712 ± 0.010 | 0.880 ± 0.014 | 466.000 ± 9.000 | 132.000 ± 4.359 | 3065.333 ± 93.045 | 6.581 ± 0.291 | 3.532 ± 0.074 | 11.360 ± 0.060 | 1.181 ± 0.049 | 10.019 ± 0.002 | 0/3/0 | 0 |
| stage5_medium_many_800 | ilp_cpsat+warm2 | 3 | 0.712 ± 0.010 | 0.880 ± 0.014 | 521.667 ± 1.528 | 149.000 ± 2.000 | 4600.667 ± 204.295 | 8.819 ± 0.390 | 3.501 ± 0.041 | 11.449 ± 0.040 | 1.195 ± 0.040 | 10.013 ± 0.009 | 0/3/0 | 0 |

## Парные сравнения

Режим warm2 минус сравниваемый режим; Δ назначений: среднее [95% CI]; далее лексикографические исходы выигрыш / равенство / проигрыш. Неполные пары не включены, n указано.

| Фаза | Сценарий | Сравнение | n | Δ назначений [95% CI] | выигрыш/равен/хуже |
|---|---|---|---:|---:|---:|
| families | stage3_control | warm2 − baseline_greedy | 20 | +0.250 [+0.050; +0.500] | 20/0/0 |
| families | stage3_control | warm2 − baseline_v2 | 20 | +0.000 [+0.000; +0.000] | 20/0/0 |
| families | stage3_control | warm2 − greedy_retiming | 20 | +0.000 [+0.000; +0.000] | 15/5/0 |
| families | stage3_control | warm2 − ilp_cpsat+warm | 20 | +0.000 [+0.000; +0.000] | 20/0/0 |
| families | stage3_high_few | warm2 − baseline_greedy | 20 | +11.900 [+7.500; +16.500] | 18/0/2 |
| families | stage3_high_few | warm2 − baseline_v2 | 20 | +13.200 [+8.749; +17.950] | 20/0/0 |
| families | stage3_high_few | warm2 − greedy_retiming | 20 | +12.850 [+8.400; +17.500] | 20/0/0 |
| families | stage3_high_few | warm2 − ilp_cpsat+warm | 20 | -1.450 [-3.300; -0.100] | 1/14/5 |
| families | stage3_high_many | warm2 − baseline_greedy | 20 | +6.300 [+4.400; +8.450] | 20/0/0 |
| families | stage3_high_many | warm2 − baseline_v2 | 20 | +2.500 [+1.450; +3.800] | 20/0/0 |
| families | stage3_high_many | warm2 − greedy_retiming | 20 | +2.500 [+1.450; +3.700] | 20/0/0 |
| families | stage3_high_many | warm2 − ilp_cpsat+warm | 20 | +0.000 [+0.000; +0.000] | 6/10/4 |
| families | stage3_low_few | warm2 − baseline_greedy | 20 | +22.550 [+18.600; +26.600] | 20/0/0 |
| families | stage3_low_few | warm2 − baseline_v2 | 20 | +7.450 [+4.950; +9.801] | 20/0/0 |
| families | stage3_low_few | warm2 − greedy_retiming | 20 | +6.850 [+4.550; +9.100] | 20/0/0 |
| families | stage3_low_few | warm2 − ilp_cpsat+warm | 20 | +0.300 [+0.000; +0.700] | 6/12/2 |
| families | stage3_low_many | warm2 − baseline_greedy | 20 | +15.700 [+13.350; +17.851] | 20/0/0 |
| families | stage3_low_many | warm2 − baseline_v2 | 20 | +3.450 [+1.900; +5.250] | 20/0/0 |
| families | stage3_low_many | warm2 − greedy_retiming | 20 | +3.050 [+1.650; +4.800] | 20/0/0 |
| families | stage3_low_many | warm2 − ilp_cpsat+warm | 20 | +0.000 [+0.000; +0.000] | 10/4/6 |
| families | stage3_medium_few | warm2 − baseline_greedy | 20 | +19.150 [+14.650; +23.300] | 19/0/1 |
| families | stage3_medium_few | warm2 − baseline_v2 | 20 | +12.650 [+8.999; +16.750] | 20/0/0 |
| families | stage3_medium_few | warm2 − greedy_retiming | 20 | +11.900 [+8.399; +15.450] | 20/0/0 |
| families | stage3_medium_few | warm2 − ilp_cpsat+warm | 20 | -0.200 [-1.250; +0.650] | 3/14/3 |
| families | stage3_medium_many | warm2 − baseline_greedy | 20 | +11.400 [+8.300; +14.800] | 20/0/0 |
| families | stage3_medium_many | warm2 − baseline_v2 | 20 | +4.050 [+1.900; +6.450] | 19/1/0 |
| families | stage3_medium_many | warm2 − greedy_retiming | 20 | +3.850 [+1.850; +6.551] | 18/2/0 |
| families | stage3_medium_many | warm2 − ilp_cpsat+warm | 20 | +0.000 [+0.000; +0.000] | 11/7/2 |
| scale | stage5_medium_few_100 | warm2 − baseline_v2 | 3 | +3.667 [+0.000; +7.000] | 3/0/0 |
| scale | stage5_medium_few_100 | warm2 − greedy_retiming | 3 | +2.667 [+0.000; +6.000] | 3/0/0 |
| scale | stage5_medium_few_100 | warm2 − ilp_cpsat+warm | 3 | +3.000 [+1.000; +5.000] | 3/0/0 |
| scale | stage5_medium_few_200 | warm2 − baseline_v2 | 3 | +0.333 [+0.000; +1.000] | 3/0/0 |
| scale | stage5_medium_few_200 | warm2 − greedy_retiming | 3 | +0.000 [+0.000; +0.000] | 3/0/0 |
| scale | stage5_medium_few_200 | warm2 − ilp_cpsat+warm | 3 | +17.333 [+11.000; +23.000] | 3/0/0 |
| scale | stage5_medium_few_400 | warm2 − baseline_v2 | 3 | +0.000 [+0.000; +0.000] | 0/3/0 |
| scale | stage5_medium_few_400 | warm2 − greedy_retiming | 3 | +0.000 [+0.000; +0.000] | 0/3/0 |
| scale | stage5_medium_few_400 | warm2 − ilp_cpsat+warm | 3 | +52.333 [+43.000; +63.000] | 3/0/0 |
| scale | stage5_medium_few_50 | warm2 − baseline_v2 | 3 | +3.667 [+1.000; +9.000] | 3/0/0 |
| scale | stage5_medium_few_50 | warm2 − greedy_retiming | 3 | +3.667 [+1.000; +9.000] | 3/0/0 |
| scale | stage5_medium_few_50 | warm2 − ilp_cpsat+warm | 3 | +0.000 [+0.000; +0.000] | 1/2/0 |
| scale | stage5_medium_few_800 | warm2 − baseline_v2 | 3 | +0.000 [+0.000; +0.000] | 0/3/0 |
| scale | stage5_medium_few_800 | warm2 − greedy_retiming | 3 | +0.000 [+0.000; +0.000] | 0/3/0 |
| scale | stage5_medium_few_800 | warm2 − ilp_cpsat+warm | 3 | +131.000 [+101.000; +152.000] | 3/0/0 |
| scale | stage5_medium_many_100 | warm2 − baseline_v2 | 3 | +1.333 [+1.000; +2.000] | 3/0/0 |
| scale | stage5_medium_many_100 | warm2 − greedy_retiming | 3 | +1.333 [+1.000; +2.000] | 3/0/0 |
| scale | stage5_medium_many_100 | warm2 − ilp_cpsat+warm | 3 | +0.000 [+0.000; +0.000] | 2/0/1 |
| scale | stage5_medium_many_200 | warm2 − baseline_v2 | 3 | +3.667 [+3.000; +4.000] | 3/0/0 |
| scale | stage5_medium_many_200 | warm2 − greedy_retiming | 3 | +3.000 [+2.000; +4.000] | 3/0/0 |
| scale | stage5_medium_many_200 | warm2 − ilp_cpsat+warm | 3 | +0.000 [+0.000; +0.000] | 1/0/2 |
| scale | stage5_medium_many_400 | warm2 − baseline_v2 | 3 | +8.000 [+4.000; +11.000] | 3/0/0 |
| scale | stage5_medium_many_400 | warm2 − greedy_retiming | 3 | +8.000 [+4.000; +11.000] | 3/0/0 |
| scale | stage5_medium_many_400 | warm2 − ilp_cpsat+warm | 3 | +4.333 [+0.000; +10.000] | 2/0/1 |
| scale | stage5_medium_many_50 | warm2 − baseline_v2 | 3 | +0.333 [+0.000; +1.000] | 3/0/0 |
| scale | stage5_medium_many_50 | warm2 − greedy_retiming | 3 | +0.333 [+0.000; +1.000] | 3/0/0 |
| scale | stage5_medium_many_50 | warm2 − ilp_cpsat+warm | 3 | +0.000 [+0.000; +0.000] | 0/3/0 |
| scale | stage5_medium_many_800 | warm2 − baseline_v2 | 3 | +0.000 [+0.000; +0.000] | 0/3/0 |
| scale | stage5_medium_many_800 | warm2 − greedy_retiming | 3 | +0.000 [+0.000; +0.000] | 0/3/0 |
| scale | stage5_medium_many_800 | warm2 − ilp_cpsat+warm | 3 | +55.667 [+49.333; +66.000] | 3/0/0 |

## Парные разности остальных метрик и 95% CI

Разность warm2 − соперник; метрики рассчитаны по одним и тем же seed.

| Фаза | Сценарий | Соперник | Метрика | n | Δ [95% CI] |
|---|---|---|---|---:|---:|
| families | stage3_control | baseline_greedy | trip_count | 20 | -15.650 [-17.651; -13.700] |
| families | stage3_control | baseline_greedy | total_time_deviation_minutes | 20 | +160.200 [+102.398; +223.651] |
| families | stage3_control | baseline_greedy | mean_time_deviation_minutes | 20 | +0.993 [+0.627; +1.357] |
| families | stage3_control | baseline_greedy | mean_passengers_per_trip | 20 | +0.470 [+0.407; +0.535] |
| families | stage3_control | baseline_greedy | runtime_seconds | 20 | +50.311 [+50.283; +50.352] |
| families | stage3_control | baseline_v2 | trip_count | 20 | -1.000 [-1.600; -0.500] |
| families | stage3_control | baseline_v2 | total_time_deviation_minutes | 20 | -205.800 [-253.059; -160.393] |
| families | stage3_control | baseline_v2 | mean_time_deviation_minutes | 20 | -1.286 [-1.581; -1.001] |
| families | stage3_control | baseline_v2 | mean_passengers_per_trip | 20 | +0.034 [+0.018; +0.055] |
| families | stage3_control | baseline_v2 | runtime_seconds | 20 | +50.324 [+50.296; +50.366] |
| families | stage3_control | greedy_retiming | trip_count | 20 | -0.250 [-0.600; +0.000] |
| families | stage3_control | greedy_retiming | total_time_deviation_minutes | 20 | -68.450 [-111.851; -33.298] |
| families | stage3_control | greedy_retiming | mean_time_deviation_minutes | 20 | -0.428 [-0.701; -0.214] |
| families | stage3_control | greedy_retiming | mean_passengers_per_trip | 20 | +0.008 [+0.000; +0.022] |
| families | stage3_control | greedy_retiming | runtime_seconds | 20 | +50.282 [+50.253; +50.325] |
| families | stage3_control | ilp_cpsat+warm | trip_count | 20 | -12.350 [-14.400; -10.350] |
| families | stage3_control | ilp_cpsat+warm | total_time_deviation_minutes | 20 | +255.800 [+203.849; +310.154] |
| families | stage3_control | ilp_cpsat+warm | mean_time_deviation_minutes | 20 | +1.599 [+1.280; +1.903] |
| families | stage3_control | ilp_cpsat+warm | mean_passengers_per_trip | 20 | +0.384 [+0.312; +0.454] |
| families | stage3_control | ilp_cpsat+warm | runtime_seconds | 20 | -0.070 [-0.235; +0.052] |
| families | stage3_high_few | baseline_greedy | trip_count | 20 | +2.400 [+0.750; +4.100] |
| families | stage3_high_few | baseline_greedy | total_time_deviation_minutes | 20 | +93.200 [+24.150; +157.502] |
| families | stage3_high_few | baseline_greedy | mean_time_deviation_minutes | 20 | -0.198 [-1.097; +0.685] |
| families | stage3_high_few | baseline_greedy | mean_passengers_per_trip | 20 | +0.305 [+0.184; +0.417] |
| families | stage3_high_few | baseline_greedy | runtime_seconds | 20 | +0.287 [+0.190; +0.398] |
| families | stage3_high_few | baseline_v2 | trip_count | 20 | +4.400 [+2.950; +5.850] |
| families | stage3_high_few | baseline_v2 | total_time_deviation_minutes | 20 | +112.050 [+43.950; +181.601] |
| families | stage3_high_few | baseline_v2 | mean_time_deviation_minutes | 20 | +0.024 [-1.034; +1.179] |
| families | stage3_high_few | baseline_v2 | mean_passengers_per_trip | 20 | +0.028 [-0.102; +0.163] |
| families | stage3_high_few | baseline_v2 | runtime_seconds | 20 | +0.287 [+0.183; +0.408] |
| families | stage3_high_few | greedy_retiming | trip_count | 20 | +4.400 [+3.000; +5.850] |
| families | stage3_high_few | greedy_retiming | total_time_deviation_minutes | 20 | +108.900 [+47.042; +174.201] |
| families | stage3_high_few | greedy_retiming | mean_time_deviation_minutes | 20 | +0.014 [-1.040; +1.216] |
| families | stage3_high_few | greedy_retiming | mean_passengers_per_trip | 20 | +0.001 [-0.123; +0.130] |
| families | stage3_high_few | greedy_retiming | runtime_seconds | 20 | +0.287 [+0.188; +0.402] |
| families | stage3_high_few | ilp_cpsat+warm | trip_count | 20 | -0.600 [-1.250; -0.050] |
| families | stage3_high_few | ilp_cpsat+warm | total_time_deviation_minutes | 20 | -12.250 [-30.706; +1.950] |
| families | stage3_high_few | ilp_cpsat+warm | mean_time_deviation_minutes | 20 | -0.123 [-0.375; +0.088] |
| families | stage3_high_few | ilp_cpsat+warm | mean_passengers_per_trip | 20 | +0.020 [-0.044; +0.090] |
| families | stage3_high_few | ilp_cpsat+warm | runtime_seconds | 20 | +0.040 [-0.002; +0.091] |
| families | stage3_high_many | baseline_greedy | trip_count | 20 | +0.100 [+0.000; +0.250] |
| families | stage3_high_many | baseline_greedy | total_time_deviation_minutes | 20 | -71.450 [-120.051; -25.496] |
| families | stage3_high_many | baseline_greedy | mean_time_deviation_minutes | 20 | -2.141 [-2.814; -1.514] |
| families | stage3_high_many | baseline_greedy | mean_passengers_per_trip | 20 | +0.305 [+0.201; +0.420] |
| families | stage3_high_many | baseline_greedy | runtime_seconds | 20 | +0.081 [+0.063; +0.100] |
| families | stage3_high_many | baseline_v2 | trip_count | 20 | +0.050 [+0.000; +0.150] |
| families | stage3_high_many | baseline_v2 | total_time_deviation_minutes | 20 | -27.900 [-44.602; -10.149] |
| families | stage3_high_many | baseline_v2 | mean_time_deviation_minutes | 20 | -0.887 [-1.169; -0.631] |
| families | stage3_high_many | baseline_v2 | mean_passengers_per_trip | 20 | +0.121 [+0.068; +0.178] |
| families | stage3_high_many | baseline_v2 | runtime_seconds | 20 | +0.080 [+0.064; +0.101] |
| families | stage3_high_many | greedy_retiming | trip_count | 20 | +0.050 [+0.000; +0.150] |
| families | stage3_high_many | greedy_retiming | total_time_deviation_minutes | 20 | -27.400 [-45.001; -9.949] |
| families | stage3_high_many | greedy_retiming | mean_time_deviation_minutes | 20 | -0.880 [-1.178; -0.606] |
| families | stage3_high_many | greedy_retiming | mean_passengers_per_trip | 20 | +0.121 [+0.069; +0.183] |
| families | stage3_high_many | greedy_retiming | runtime_seconds | 20 | +0.080 [+0.062; +0.099] |
| families | stage3_high_many | ilp_cpsat+warm | trip_count | 20 | +0.000 [+0.000; +0.000] |
| families | stage3_high_many | ilp_cpsat+warm | total_time_deviation_minutes | 20 | +0.050 [-1.650; +1.950] |
| families | stage3_high_many | ilp_cpsat+warm | mean_time_deviation_minutes | 20 | +0.002 [-0.026; +0.037] |
| families | stage3_high_many | ilp_cpsat+warm | mean_passengers_per_trip | 20 | +0.000 [+0.000; +0.000] |
| families | stage3_high_many | ilp_cpsat+warm | runtime_seconds | 20 | +0.002 [-0.006; +0.014] |
| families | stage3_low_few | baseline_greedy | trip_count | 20 | +3.150 [+1.200; +5.200] |
| families | stage3_low_few | baseline_greedy | total_time_deviation_minutes | 20 | +212.900 [+139.284; +282.355] |
| families | stage3_low_few | baseline_greedy | mean_time_deviation_minutes | 20 | +0.443 [-0.131; +1.007] |
| families | stage3_low_few | baseline_greedy | mean_passengers_per_trip | 20 | +0.404 [+0.322; +0.488] |
| families | stage3_low_few | baseline_greedy | runtime_seconds | 20 | +7.875 [+4.650; +11.807] |
| families | stage3_low_few | baseline_v2 | trip_count | 20 | +1.200 [-0.351; +2.700] |
| families | stage3_low_few | baseline_v2 | total_time_deviation_minutes | 20 | -46.600 [-96.060; +2.014] |
| families | stage3_low_few | baseline_v2 | mean_time_deviation_minutes | 20 | -1.050 [-1.541; -0.554] |
| families | stage3_low_few | baseline_v2 | mean_passengers_per_trip | 20 | +0.112 [+0.046; +0.180] |
| families | stage3_low_few | baseline_v2 | runtime_seconds | 20 | +7.875 [+4.636; +11.880] |
| families | stage3_low_few | greedy_retiming | trip_count | 20 | +1.550 [+0.249; +2.801] |
| families | stage3_low_few | greedy_retiming | total_time_deviation_minutes | 20 | +15.000 [-20.851; +55.555] |
| families | stage3_low_few | greedy_retiming | mean_time_deviation_minutes | 20 | -0.371 [-0.756; +0.054] |
| families | stage3_low_few | greedy_retiming | mean_passengers_per_trip | 20 | +0.071 [+0.013; +0.125] |
| families | stage3_low_few | greedy_retiming | runtime_seconds | 20 | +7.863 [+4.590; +11.822] |
| families | stage3_low_few | ilp_cpsat+warm | trip_count | 20 | +0.100 [+0.000; +0.250] |
| families | stage3_low_few | ilp_cpsat+warm | total_time_deviation_minutes | 20 | +7.200 [-2.001; +19.004] |
| families | stage3_low_few | ilp_cpsat+warm | mean_time_deviation_minutes | 20 | +0.041 [-0.029; +0.124] |
| families | stage3_low_few | ilp_cpsat+warm | mean_passengers_per_trip | 20 | +0.001 [-0.006; +0.012] |
| families | stage3_low_few | ilp_cpsat+warm | runtime_seconds | 20 | -0.384 [-1.870; +0.928] |
| families | stage3_low_many | baseline_greedy | trip_count | 20 | +0.350 [-1.101; +1.800] |
| families | stage3_low_many | baseline_greedy | total_time_deviation_minutes | 20 | +94.150 [+48.996; +141.714] |
| families | stage3_low_many | baseline_greedy | mean_time_deviation_minutes | 20 | -0.239 [-0.532; +0.088] |
| families | stage3_low_many | baseline_greedy | mean_passengers_per_trip | 20 | +0.328 [+0.241; +0.423] |
| families | stage3_low_many | baseline_greedy | runtime_seconds | 20 | +3.205 [+1.744; +4.883] |
| families | stage3_low_many | baseline_v2 | trip_count | 20 | -0.850 [-1.750; +0.000] |
| families | stage3_low_many | baseline_v2 | total_time_deviation_minutes | 20 | -102.450 [-139.952; -65.699] |
| families | stage3_low_many | baseline_v2 | mean_time_deviation_minutes | 20 | -1.072 [-1.364; -0.793] |
| families | stage3_low_many | baseline_v2 | mean_passengers_per_trip | 20 | +0.121 [+0.069; +0.183] |
| families | stage3_low_many | baseline_v2 | runtime_seconds | 20 | +3.204 [+1.778; +4.800] |
| families | stage3_low_many | greedy_retiming | trip_count | 20 | -0.650 [-1.550; +0.150] |
| families | stage3_low_many | greedy_retiming | total_time_deviation_minutes | 20 | -31.950 [-58.552; -5.100] |
| families | stage3_low_many | greedy_retiming | mean_time_deviation_minutes | 20 | -0.440 [-0.638; -0.236] |
| families | stage3_low_many | greedy_retiming | mean_passengers_per_trip | 20 | +0.102 [+0.057; +0.158] |
| families | stage3_low_many | greedy_retiming | runtime_seconds | 20 | +3.188 [+1.750; +4.942] |
| families | stage3_low_many | ilp_cpsat+warm | trip_count | 20 | +0.000 [+0.000; +0.000] |
| families | stage3_low_many | ilp_cpsat+warm | total_time_deviation_minutes | 20 | -1.450 [-3.850; +1.100] |
| families | stage3_low_many | ilp_cpsat+warm | mean_time_deviation_minutes | 20 | -0.012 [-0.034; +0.009] |
| families | stage3_low_many | ilp_cpsat+warm | mean_passengers_per_trip | 20 | +0.000 [+0.000; +0.000] |
| families | stage3_low_many | ilp_cpsat+warm | runtime_seconds | 20 | -0.328 [-0.998; +0.302] |
| families | stage3_medium_few | baseline_greedy | trip_count | 20 | +4.300 [+2.500; +6.100] |
| families | stage3_medium_few | baseline_greedy | total_time_deviation_minutes | 20 | +200.400 [+128.947; +263.410] |
| families | stage3_medium_few | baseline_greedy | mean_time_deviation_minutes | 20 | +0.743 [+0.008; +1.419] |
| families | stage3_medium_few | baseline_greedy | mean_passengers_per_trip | 20 | +0.289 [+0.188; +0.398] |
| families | stage3_medium_few | baseline_greedy | runtime_seconds | 20 | +2.644 [+0.780; +5.185] |
| families | stage3_medium_few | baseline_v2 | trip_count | 20 | +4.750 [+3.450; +6.150] |
| families | stage3_medium_few | baseline_v2 | total_time_deviation_minutes | 20 | +61.550 [+12.947; +119.707] |
| families | stage3_medium_few | baseline_v2 | mean_time_deviation_minutes | 20 | -0.568 [-1.119; -0.020] |
| families | stage3_medium_few | baseline_v2 | mean_passengers_per_trip | 20 | -0.028 [-0.108; +0.056] |
| families | stage3_medium_few | baseline_v2 | runtime_seconds | 20 | +2.644 [+0.785; +5.243] |
| families | stage3_medium_few | greedy_retiming | trip_count | 20 | +4.800 [+3.500; +6.150] |
| families | stage3_medium_few | greedy_retiming | total_time_deviation_minutes | 20 | +68.900 [+18.999; +128.707] |
| families | stage3_medium_few | greedy_retiming | mean_time_deviation_minutes | 20 | -0.389 [-0.861; +0.205] |
| families | stage3_medium_few | greedy_retiming | mean_passengers_per_trip | 20 | -0.060 [-0.131; +0.013] |
| families | stage3_medium_few | greedy_retiming | runtime_seconds | 20 | +2.641 [+0.804; +5.181] |
| families | stage3_medium_few | ilp_cpsat+warm | trip_count | 20 | +0.050 [-0.550; +0.550] |
| families | stage3_medium_few | ilp_cpsat+warm | total_time_deviation_minutes | 20 | -7.900 [-23.501; +2.902] |
| families | stage3_medium_few | ilp_cpsat+warm | mean_time_deviation_minutes | 20 | -0.084 [-0.244; +0.036] |
| families | stage3_medium_few | ilp_cpsat+warm | mean_passengers_per_trip | 20 | -0.012 [-0.035; +0.010] |
| families | stage3_medium_few | ilp_cpsat+warm | runtime_seconds | 20 | +0.011 [-0.709; +0.746] |
| families | stage3_medium_many | baseline_greedy | trip_count | 20 | +0.850 [+0.000; +1.751] |
| families | stage3_medium_many | baseline_greedy | total_time_deviation_minutes | 20 | +58.450 [+8.046; +106.154] |
| families | stage3_medium_many | baseline_greedy | mean_time_deviation_minutes | 20 | -0.382 [-0.745; +0.037] |
| families | stage3_medium_many | baseline_greedy | mean_passengers_per_trip | 20 | +0.280 [+0.209; +0.355] |
| families | stage3_medium_many | baseline_greedy | runtime_seconds | 20 | +0.174 [+0.122; +0.234] |
| families | stage3_medium_many | baseline_v2 | trip_count | 20 | +0.500 [+0.000; +1.050] |
| families | stage3_medium_many | baseline_v2 | total_time_deviation_minutes | 20 | -23.450 [-55.404; +11.104] |
| families | stage3_medium_many | baseline_v2 | mean_time_deviation_minutes | 20 | -0.573 [-0.828; -0.281] |
| families | stage3_medium_many | baseline_v2 | mean_passengers_per_trip | 20 | +0.076 [+0.028; +0.135] |
| families | stage3_medium_many | baseline_v2 | runtime_seconds | 20 | +0.173 [+0.120; +0.239] |
| families | stage3_medium_many | greedy_retiming | trip_count | 20 | +0.600 [+0.100; +1.200] |
| families | stage3_medium_many | greedy_retiming | total_time_deviation_minutes | 20 | +5.400 [-25.751; +42.000] |
| families | stage3_medium_many | greedy_retiming | mean_time_deviation_minutes | 20 | -0.242 [-0.477; +0.001] |
| families | stage3_medium_many | greedy_retiming | mean_passengers_per_trip | 20 | +0.060 [+0.011; +0.123] |
| families | stage3_medium_many | greedy_retiming | runtime_seconds | 20 | +0.168 [+0.116; +0.229] |
| families | stage3_medium_many | ilp_cpsat+warm | trip_count | 20 | +0.000 [+0.000; +0.000] |
| families | stage3_medium_many | ilp_cpsat+warm | total_time_deviation_minutes | 20 | +0.000 [-3.000; +4.900] |
| families | stage3_medium_many | ilp_cpsat+warm | mean_time_deviation_minutes | 20 | -0.003 [-0.033; +0.041] |
| families | stage3_medium_many | ilp_cpsat+warm | mean_passengers_per_trip | 20 | +0.000 [+0.000; +0.000] |
| families | stage3_medium_many | ilp_cpsat+warm | runtime_seconds | 20 | +0.024 [+0.007; +0.042] |
| scale | stage5_medium_few_100 | baseline_v2 | trip_count | 3 | +1.000 [+0.000; +2.000] |
| scale | stage5_medium_few_100 | baseline_v2 | total_time_deviation_minutes | 3 | -40.667 [-106.000; +14.000] |
| scale | stage5_medium_few_100 | baseline_v2 | mean_time_deviation_minutes | 3 | -1.466 [-2.208; -0.587] |
| scale | stage5_medium_few_100 | baseline_v2 | mean_passengers_per_trip | 3 | +0.040 [+0.000; +0.062] |
| scale | stage5_medium_few_100 | baseline_v2 | runtime_seconds | 3 | +10.083 [+10.043; +10.143] |
| scale | stage5_medium_few_100 | greedy_retiming | trip_count | 3 | +1.000 [+0.000; +2.000] |
| scale | stage5_medium_few_100 | greedy_retiming | total_time_deviation_minutes | 3 | -37.333 [-90.000; +13.000] |
| scale | stage5_medium_few_100 | greedy_retiming | mean_time_deviation_minutes | 3 | -1.201 [-1.875; -0.171] |
| scale | stage5_medium_few_100 | greedy_retiming | mean_passengers_per_trip | 3 | -0.021 [-0.053; +0.000] |
| scale | stage5_medium_few_100 | greedy_retiming | runtime_seconds | 3 | +10.081 [+10.042; +10.142] |
| scale | stage5_medium_few_100 | ilp_cpsat+warm | trip_count | 3 | +1.667 [+1.000; +3.000] |
| scale | stage5_medium_few_100 | ilp_cpsat+warm | total_time_deviation_minutes | 3 | +86.667 [+26.000; +157.000] |
| scale | stage5_medium_few_100 | ilp_cpsat+warm | mean_time_deviation_minutes | 3 | +1.241 [+0.431; +1.988] |
| scale | stage5_medium_few_100 | ilp_cpsat+warm | mean_passengers_per_trip | 3 | -0.126 [-0.240; +0.000] |
| scale | stage5_medium_few_100 | ilp_cpsat+warm | runtime_seconds | 3 | +0.033 [+0.005; +0.085] |
| scale | stage5_medium_few_200 | baseline_v2 | trip_count | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_few_200 | baseline_v2 | total_time_deviation_minutes | 3 | -14.000 [-27.000; -3.000] |
| scale | stage5_medium_few_200 | baseline_v2 | mean_time_deviation_minutes | 3 | -0.155 [-0.257; -0.103] |
| scale | stage5_medium_few_200 | baseline_v2 | mean_passengers_per_trip | 3 | +0.010 [+0.000; +0.029] |
| scale | stage5_medium_few_200 | baseline_v2 | runtime_seconds | 3 | +10.227 [+10.208; +10.248] |
| scale | stage5_medium_few_200 | greedy_retiming | trip_count | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_few_200 | greedy_retiming | total_time_deviation_minutes | 3 | -5.667 [-11.000; -2.000] |
| scale | stage5_medium_few_200 | greedy_retiming | mean_time_deviation_minutes | 3 | -0.052 [-0.101; -0.017] |
| scale | stage5_medium_few_200 | greedy_retiming | mean_passengers_per_trip | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_few_200 | greedy_retiming | runtime_seconds | 3 | +10.224 [+10.205; +10.246] |
| scale | stage5_medium_few_200 | ilp_cpsat+warm | trip_count | 3 | +4.333 [+1.000; +6.000] |
| scale | stage5_medium_few_200 | ilp_cpsat+warm | total_time_deviation_minutes | 3 | +482.000 [+422.000; +581.000] |
| scale | stage5_medium_few_200 | ilp_cpsat+warm | mean_time_deviation_minutes | 3 | +3.434 [+3.248; +3.783] |
| scale | stage5_medium_few_200 | ilp_cpsat+warm | mean_passengers_per_trip | 3 | +0.092 [-0.044; +0.249] |
| scale | stage5_medium_few_200 | ilp_cpsat+warm | runtime_seconds | 3 | -0.002 [-0.030; +0.021] |
| scale | stage5_medium_few_400 | baseline_v2 | trip_count | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_few_400 | baseline_v2 | total_time_deviation_minutes | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_few_400 | baseline_v2 | mean_time_deviation_minutes | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_few_400 | baseline_v2 | mean_passengers_per_trip | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_few_400 | baseline_v2 | runtime_seconds | 3 | +11.002 [+10.834; +11.164] |
| scale | stage5_medium_few_400 | greedy_retiming | trip_count | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_few_400 | greedy_retiming | total_time_deviation_minutes | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_few_400 | greedy_retiming | mean_time_deviation_minutes | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_few_400 | greedy_retiming | mean_passengers_per_trip | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_few_400 | greedy_retiming | runtime_seconds | 3 | +11.000 [+10.833; +11.161] |
| scale | stage5_medium_few_400 | ilp_cpsat+warm | trip_count | 3 | +16.000 [+13.000; +19.000] |
| scale | stage5_medium_few_400 | ilp_cpsat+warm | total_time_deviation_minutes | 3 | +1037.667 [+878.000; +1180.000] |
| scale | stage5_medium_few_400 | ilp_cpsat+warm | mean_time_deviation_minutes | 3 | +2.959 [+1.900; +3.506] |
| scale | stage5_medium_few_400 | ilp_cpsat+warm | mean_passengers_per_trip | 3 | -0.055 [-0.076; -0.032] |
| scale | stage5_medium_few_400 | ilp_cpsat+warm | runtime_seconds | 3 | +0.127 [-0.005; +0.315] |
| scale | stage5_medium_few_50 | baseline_v2 | trip_count | 3 | +1.000 [+0.000; +3.000] |
| scale | stage5_medium_few_50 | baseline_v2 | total_time_deviation_minutes | 3 | +21.000 [-37.000; +81.000] |
| scale | stage5_medium_few_50 | baseline_v2 | mean_time_deviation_minutes | 3 | -0.438 [-2.575; +0.850] |
| scale | stage5_medium_few_50 | baseline_v2 | mean_passengers_per_trip | 3 | +0.153 [+0.143; +0.167] |
| scale | stage5_medium_few_50 | baseline_v2 | runtime_seconds | 3 | +1.520 [+0.559; +2.455] |
| scale | stage5_medium_few_50 | greedy_retiming | trip_count | 3 | +1.000 [+0.000; +3.000] |
| scale | stage5_medium_few_50 | greedy_retiming | total_time_deviation_minutes | 3 | +21.000 [-37.000; +81.000] |
| scale | stage5_medium_few_50 | greedy_retiming | mean_time_deviation_minutes | 3 | -0.438 [-2.575; +0.850] |
| scale | stage5_medium_few_50 | greedy_retiming | mean_passengers_per_trip | 3 | +0.153 [+0.143; +0.167] |
| scale | stage5_medium_few_50 | greedy_retiming | runtime_seconds | 3 | +1.520 [+0.559; +2.455] |
| scale | stage5_medium_few_50 | ilp_cpsat+warm | trip_count | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_few_50 | ilp_cpsat+warm | total_time_deviation_minutes | 3 | -3.333 [-10.000; +0.000] |
| scale | stage5_medium_few_50 | ilp_cpsat+warm | mean_time_deviation_minutes | 3 | -0.152 [-0.455; +0.000] |
| scale | stage5_medium_few_50 | ilp_cpsat+warm | mean_passengers_per_trip | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_few_50 | ilp_cpsat+warm | runtime_seconds | 3 | -0.133 [-1.130; +0.655] |
| scale | stage5_medium_few_800 | baseline_v2 | trip_count | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_few_800 | baseline_v2 | total_time_deviation_minutes | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_few_800 | baseline_v2 | mean_time_deviation_minutes | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_few_800 | baseline_v2 | mean_passengers_per_trip | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_few_800 | baseline_v2 | runtime_seconds | 3 | +13.527 [+13.334; +13.711] |
| scale | stage5_medium_few_800 | greedy_retiming | trip_count | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_few_800 | greedy_retiming | total_time_deviation_minutes | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_few_800 | greedy_retiming | mean_time_deviation_minutes | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_few_800 | greedy_retiming | mean_passengers_per_trip | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_few_800 | greedy_retiming | runtime_seconds | 3 | +13.524 [+13.333; +13.708] |
| scale | stage5_medium_few_800 | ilp_cpsat+warm | trip_count | 3 | +39.000 [+31.000; +44.000] |
| scale | stage5_medium_few_800 | ilp_cpsat+warm | total_time_deviation_minutes | 3 | +2885.667 [+2657.000; +3036.000] |
| scale | stage5_medium_few_800 | ilp_cpsat+warm | mean_time_deviation_minutes | 3 | +4.303 [+4.101; +4.460] |
| scale | stage5_medium_few_800 | ilp_cpsat+warm | mean_passengers_per_trip | 3 | -0.053 [-0.075; -0.029] |
| scale | stage5_medium_few_800 | ilp_cpsat+warm | runtime_seconds | 3 | +0.142 [-0.098; +0.266] |
| scale | stage5_medium_many_100 | baseline_v2 | trip_count | 3 | +0.333 [+0.000; +1.000] |
| scale | stage5_medium_many_100 | baseline_v2 | total_time_deviation_minutes | 3 | -169.000 [-246.000; -121.000] |
| scale | stage5_medium_many_100 | baseline_v2 | mean_time_deviation_minutes | 3 | -3.079 [-4.279; -2.096] |
| scale | stage5_medium_many_100 | baseline_v2 | mean_passengers_per_trip | 3 | +0.016 [-0.108; +0.105] |
| scale | stage5_medium_many_100 | baseline_v2 | runtime_seconds | 3 | +10.026 [+10.025; +10.028] |
| scale | stage5_medium_many_100 | greedy_retiming | trip_count | 3 | +0.333 [+0.000; +1.000] |
| scale | stage5_medium_many_100 | greedy_retiming | total_time_deviation_minutes | 3 | -151.000 [-203.000; -121.000] |
| scale | stage5_medium_many_100 | greedy_retiming | mean_time_deviation_minutes | 3 | -2.765 [-3.550; -2.096] |
| scale | stage5_medium_many_100 | greedy_retiming | mean_passengers_per_trip | 3 | +0.016 [-0.108; +0.105] |
| scale | stage5_medium_many_100 | greedy_retiming | runtime_seconds | 3 | +10.024 [+10.023; +10.025] |
| scale | stage5_medium_many_100 | ilp_cpsat+warm | trip_count | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_many_100 | ilp_cpsat+warm | total_time_deviation_minutes | 3 | -1.333 [-5.000; +4.000] |
| scale | stage5_medium_many_100 | ilp_cpsat+warm | mean_time_deviation_minutes | 3 | -0.024 [-0.083; +0.066] |
| scale | stage5_medium_many_100 | ilp_cpsat+warm | mean_passengers_per_trip | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_many_100 | ilp_cpsat+warm | runtime_seconds | 3 | +0.003 [+0.002; +0.004] |
| scale | stage5_medium_many_200 | baseline_v2 | trip_count | 3 | +0.000 [-1.000; +1.000] |
| scale | stage5_medium_many_200 | baseline_v2 | total_time_deviation_minutes | 3 | -319.000 [-332.000; -295.000] |
| scale | stage5_medium_many_200 | baseline_v2 | mean_time_deviation_minutes | 3 | -2.735 [-2.936; -2.412] |
| scale | stage5_medium_many_200 | baseline_v2 | mean_passengers_per_trip | 3 | +0.099 [+0.021; +0.168] |
| scale | stage5_medium_many_200 | baseline_v2 | runtime_seconds | 3 | +10.092 [+10.090; +10.096] |
| scale | stage5_medium_many_200 | greedy_retiming | trip_count | 3 | +0.000 [-1.000; +1.000] |
| scale | stage5_medium_many_200 | greedy_retiming | total_time_deviation_minutes | 3 | -335.000 [-343.000; -330.000] |
| scale | stage5_medium_many_200 | greedy_retiming | mean_time_deviation_minutes | 3 | -2.813 [-2.936; -2.647] |
| scale | stage5_medium_many_200 | greedy_retiming | mean_passengers_per_trip | 3 | +0.081 [+0.021; +0.168] |
| scale | stage5_medium_many_200 | greedy_retiming | runtime_seconds | 3 | +10.090 [+10.089; +10.091] |
| scale | stage5_medium_many_200 | ilp_cpsat+warm | trip_count | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_many_200 | ilp_cpsat+warm | total_time_deviation_minutes | 3 | +12.667 [-21.000; +37.000] |
| scale | stage5_medium_many_200 | ilp_cpsat+warm | mean_time_deviation_minutes | 3 | +0.097 [-0.168; +0.296] |
| scale | stage5_medium_many_200 | ilp_cpsat+warm | mean_passengers_per_trip | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_many_200 | ilp_cpsat+warm | runtime_seconds | 3 | +0.011 [+0.004; +0.019] |
| scale | stage5_medium_many_400 | baseline_v2 | trip_count | 3 | +0.667 [+0.000; +1.000] |
| scale | stage5_medium_many_400 | baseline_v2 | total_time_deviation_minutes | 3 | +105.667 [-1.000; +222.000] |
| scale | stage5_medium_many_400 | baseline_v2 | mean_time_deviation_minutes | 3 | +0.138 [-0.384; +0.724] |
| scale | stage5_medium_many_400 | baseline_v2 | mean_passengers_per_trip | 3 | +0.076 [+0.053; +0.102] |
| scale | stage5_medium_many_400 | baseline_v2 | runtime_seconds | 3 | +10.331 [+10.320; +10.338] |
| scale | stage5_medium_many_400 | greedy_retiming | trip_count | 3 | +0.667 [+0.000; +1.000] |
| scale | stage5_medium_many_400 | greedy_retiming | total_time_deviation_minutes | 3 | +105.667 [-1.000; +222.000] |
| scale | stage5_medium_many_400 | greedy_retiming | mean_time_deviation_minutes | 3 | +0.138 [-0.384; +0.724] |
| scale | stage5_medium_many_400 | greedy_retiming | mean_passengers_per_trip | 3 | +0.076 [+0.053; +0.102] |
| scale | stage5_medium_many_400 | greedy_retiming | runtime_seconds | 3 | +10.329 [+10.318; +10.337] |
| scale | stage5_medium_many_400 | ilp_cpsat+warm | trip_count | 3 | -1.000 [-2.000; +0.000] |
| scale | stage5_medium_many_400 | ilp_cpsat+warm | total_time_deviation_minutes | 3 | +90.000 [+78.000; +96.000] |
| scale | stage5_medium_many_400 | ilp_cpsat+warm | mean_time_deviation_minutes | 3 | +0.201 [+0.040; +0.364] |
| scale | stage5_medium_many_400 | ilp_cpsat+warm | mean_passengers_per_trip | 3 | +0.102 [+0.000; +0.220] |
| scale | stage5_medium_many_400 | ilp_cpsat+warm | runtime_seconds | 3 | +0.012 [-0.006; +0.027] |
| scale | stage5_medium_many_50 | baseline_v2 | trip_count | 3 | +0.333 [+0.000; +1.000] |
| scale | stage5_medium_many_50 | baseline_v2 | total_time_deviation_minutes | 3 | -31.333 [-40.000; -21.000] |
| scale | stage5_medium_many_50 | baseline_v2 | mean_time_deviation_minutes | 3 | -1.438 [-1.905; -1.034] |
| scale | stage5_medium_many_50 | baseline_v2 | mean_passengers_per_trip | 3 | -0.119 [-0.357; +0.000] |
| scale | stage5_medium_many_50 | baseline_v2 | runtime_seconds | 3 | +0.058 [+0.026; +0.113] |
| scale | stage5_medium_many_50 | greedy_retiming | trip_count | 3 | +0.333 [+0.000; +1.000] |
| scale | stage5_medium_many_50 | greedy_retiming | total_time_deviation_minutes | 3 | -31.333 [-40.000; -21.000] |
| scale | stage5_medium_many_50 | greedy_retiming | mean_time_deviation_minutes | 3 | -1.438 [-1.905; -1.034] |
| scale | stage5_medium_many_50 | greedy_retiming | mean_passengers_per_trip | 3 | -0.119 [-0.357; +0.000] |
| scale | stage5_medium_many_50 | greedy_retiming | runtime_seconds | 3 | +0.058 [+0.025; +0.113] |
| scale | stage5_medium_many_50 | ilp_cpsat+warm | trip_count | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_many_50 | ilp_cpsat+warm | total_time_deviation_minutes | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_many_50 | ilp_cpsat+warm | mean_time_deviation_minutes | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_many_50 | ilp_cpsat+warm | mean_passengers_per_trip | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_many_50 | ilp_cpsat+warm | runtime_seconds | 3 | +0.004 [-0.005; +0.017] |
| scale | stage5_medium_many_800 | baseline_v2 | trip_count | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_many_800 | baseline_v2 | total_time_deviation_minutes | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_many_800 | baseline_v2 | mean_time_deviation_minutes | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_many_800 | baseline_v2 | mean_passengers_per_trip | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_many_800 | baseline_v2 | runtime_seconds | 3 | +11.351 [+11.310; +11.390] |
| scale | stage5_medium_many_800 | greedy_retiming | trip_count | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_many_800 | greedy_retiming | total_time_deviation_minutes | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_many_800 | greedy_retiming | mean_time_deviation_minutes | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_many_800 | greedy_retiming | mean_passengers_per_trip | 3 | +0.000 [+0.000; +0.000] |
| scale | stage5_medium_many_800 | greedy_retiming | runtime_seconds | 3 | +11.349 [+11.307; +11.388] |
| scale | stage5_medium_many_800 | ilp_cpsat+warm | trip_count | 3 | +17.000 [+14.000; +19.000] |
| scale | stage5_medium_many_800 | ilp_cpsat+warm | total_time_deviation_minutes | 3 | +1535.333 [+1311.000; +1687.000] |
| scale | stage5_medium_many_800 | ilp_cpsat+warm | mean_time_deviation_minutes | 3 | +2.238 [+1.931; +2.581] |
| scale | stage5_medium_many_800 | ilp_cpsat+warm | mean_passengers_per_trip | 3 | -0.030 [-0.075; -0.005] |
| scale | stage5_medium_many_800 | ilp_cpsat+warm | runtime_seconds | 3 | +0.089 [+0.037; +0.192] |

## Размер модели и доля разрыва на одной дате

Переменные = x + y + переменные неназначения; число ограничений берётся из диагностики модели. Доля разрыва для назначений `(retiming − v2)/(W − v2)`, нулевой знаменатель исключён; результаты вне 0–100% не обрезаются.

| Сценарий | Режим | x | y | Все переменные | Ограничения | Доля OPTIMAL | Разрыв retiming относительно v2, n |
|---|---|---:|---:|---:|---:|---:|---:|
| stage5_medium_few_100 | ilp_cpsat+warm | 3554.000 ± 715.731 | 392.333 ± 35.360 | 4046.333 ± 749.137 | 1356.000 ± 106.775 | 0/3 | -61.111 ± 120.570% (n=3) |
| stage5_medium_few_100 | ilp_cpsat+warm2 | 3583.000 ± 709.008 | 397.333 ± 32.716 | 4080.333 ± 739.658 | 1371.000 ± 98.838 | 0/3 | -61.111 ± 120.570% (n=3) |
| stage5_medium_few_200 | ilp_cpsat+warm | 15639.000 ± 1113.654 | 885.667 ± 13.614 | 16724.667 ± 1100.255 | 3022.000 ± 39.357 | 0/3 | -1.961 ± 3.396% (n=3) |
| stage5_medium_few_200 | ilp_cpsat+warm2 | 15672.667 ± 1184.612 | 889.333 ± 10.214 | 16762.000 ± 1176.307 | 3033.000 ± 30.512 | 0/3 | -1.961 ± 3.396% (n=3) |
| stage5_medium_few_400 | ilp_cpsat+warm | 66383.667 ± 3282.547 | 1845.333 ± 6.110 | 68629.000 ± 3278.201 | 6265.333 ± 22.279 | 0/3 | 0.000 ± 0.000% (n=3) |
| stage5_medium_few_400 | ilp_cpsat+warm2 | 66383.667 ± 3282.547 | 1845.333 ± 6.110 | 68629.000 ± 3278.201 | 6265.333 ± 22.279 | 0/3 | 0.000 ± 0.000% (n=3) |
| stage5_medium_few_50 | ilp_cpsat+warm | 578.667 ± 109.185 | 112.000 ± 12.288 | 740.667 ± 120.517 | 422.333 ± 37.608 | 3/3 | 0.000 ± 0.000% (n=3) |
| stage5_medium_few_50 | ilp_cpsat+warm2 | 579.000 ± 109.220 | 112.333 ± 12.097 | 741.333 ± 120.542 | 423.333 ± 37.072 | 3/3 | 0.000 ± 0.000% (n=3) |
| stage5_medium_few_800 | ilp_cpsat+warm | 263413.667 ± 14621.424 | 3710.000 ± 10.000 | 267923.667 ± 14631.160 | 12583.667 ± 24.786 | 0/3 | 0.000 ± 0.000% (n=3) |
| stage5_medium_few_800 | ilp_cpsat+warm2 | 263413.667 ± 14621.424 | 3710.000 ± 10.000 | 267923.667 ± 14631.160 | 12583.667 ± 24.786 | 0/3 | 0.000 ± 0.000% (n=3) |
| stage5_medium_many_100 | ilp_cpsat+warm | 1392.667 ± 81.396 | 149.667 ± 8.386 | 1642.333 ± 89.489 | 637.667 ± 23.965 | 0/3 | 0.000 ± 0.000% (n=3) |
| stage5_medium_many_100 | ilp_cpsat+warm2 | 1387.000 ± 91.329 | 148.000 ± 9.849 | 1635.000 ± 101.158 | 632.667 ± 27.970 | 0/3 | 0.000 ± 0.000% (n=3) |
| stage5_medium_many_200 | ilp_cpsat+warm | 5680.000 ± 116.323 | 329.667 ± 6.429 | 6209.667 ± 112.758 | 1376.000 ± 18.735 | 0/3 | 16.667 ± 28.868% (n=3) |
| stage5_medium_many_200 | ilp_cpsat+warm2 | 5712.333 ± 116.843 | 332.333 ± 4.509 | 6244.667 ± 112.647 | 1384.000 ± 13.528 | 0/3 | 16.667 ± 28.868% (n=3) |
| stage5_medium_many_400 | ilp_cpsat+warm | 23425.667 ± 600.080 | 691.667 ± 8.737 | 24517.333 ± 591.446 | 2848.667 ± 31.644 | 0/3 | 0.000 ± 0.000% (n=3) |
| stage5_medium_many_400 | ilp_cpsat+warm2 | 23452.000 ± 571.941 | 692.667 ± 11.846 | 24544.667 ± 560.541 | 2851.667 ± 40.427 | 0/3 | 0.000 ± 0.000% (n=3) |
| stage5_medium_many_50 | ilp_cpsat+warm | 249.667 ± 17.616 | 45.333 ± 2.517 | 345.000 ± 19.975 | 226.667 ± 10.066 | 3/3 | 0.000 ± н/д% (n=1) |
| stage5_medium_many_50 | ilp_cpsat+warm2 | 248.000 ± 19.053 | 44.667 ± 3.055 | 342.667 ± 21.962 | 224.667 ± 11.504 | 3/3 | 0.000 ± н/д% (n=1) |
| stage5_medium_many_800 | ilp_cpsat+warm | 94863.667 ± 1987.812 | 1427.000 ± 11.269 | 97090.667 ± 1993.405 | 5825.000 ± 24.759 | 0/3 | 0.000 ± 0.000% (n=3) |
| stage5_medium_many_800 | ilp_cpsat+warm2 | 94836.333 ± 2003.154 | 1424.667 ± 9.452 | 97061.000 ± 2009.027 | 5818.000 ± 18.193 | 0/3 | 0.000 ± 0.000% (n=3) |

### Порог по предварительному критерию

- medium_few, ilp_cpsat+warm: первый размер 100 заявок/дату.
- medium_few, ilp_cpsat+warm2: первый размер 100 заявок/дату.
- medium_many, ilp_cpsat+warm: первый размер 100 заявок/дату.
- medium_many, ilp_cpsat+warm2: первый размер 100 заявок/дату.

## Признаки и корреляции Спирмена

Единица наблюдения — сценарий/seed, выигрыш W над лексикографически лучшей эвристикой по назначениям за весь горизонт. Число заявок, слотов и потенциальных межкоридорных конфликтов усреднено по активным датам. Конфликт — пара заявок разных коридоров на одного водителя, для которых существуют совместимые времена отправления с пересечением 30-минутных рейсов; это число потенциальных пар, не число реализованных конфликтов. Совместимость — наличие хотя бы одного слота без учёта конкуренции. CI bootstrap по экземплярам, 2000 повторов; повторные seed и общая структура семейств ограничивают интерпретацию. Причинные выводы не делаются.

| Признак | n | Спирмен ρ | 95% CI |
|---|---:|---:|---:|
| compatibility | 170 | -0.290 | [-0.410; -0.157] |
| slots_per_driver_day | 170 | -0.151 | [-0.296; 0.004] |
| cross_corridor_potential_conflicts_per_day | 170 | -0.366 | [-0.502; -0.218] |
| R | 170 | -0.205 | [-0.342; -0.068] |
| requests_per_day | 170 | -0.383 | [-0.511; -0.238] |

## Ограничения

В семейных записях этапа 4 время построения/поиска эвристик отдельно не измерялось. В новой серии одна дата: для v2 полное время отнесено к построению, для retiming отдельно измерено начальное построение v2, а остаток включает локальный поиск и валидацию. Системная нагрузка не контролировалась; выполнялись редакторские операции и краткие чтения файлов, временами работали другие процессы. Два несохранённых контрольных запуска прерваны перед публикацией измерительной обвязки и выполнены заново; сохранённые записи не перезаписывались. В записях сохранены коммиты до и после добавления измерения масштабных эвристик; алгоритмы не менялись.

FEASIBLE не доказывает оптимальности. На 800 заявках warm2 равен retiming по цели во всех трёх seed обоих семейств; для few три даты выбрали fallback. В high_few семейный W имеет 52,25 назначений, warm2 50,80, хотя каждый из них имеет 20/20 OPTIMAL: разные hint расширяют разные конечные домены, и данные не устанавливают единственный общий оптимум. Все результаты доступны в runs.jsonl.
