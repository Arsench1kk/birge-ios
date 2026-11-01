# Этап 4: families, синтетические результаты

Все параметры PLACEHOLDER, 2000 парных bootstrap-повторов, seed 451; лексикографическая цель: максимум назначений, минимум рейсов, минимум суммарного отклонения. CI — percentile bootstrap разностей candidate − reference, paired по seed; Wilcoxon — точная двусторонняя знаково-ранговая перестановка без поправки на множественные сравнения. W на основных семействах — сохранённые валидированные запуски этапа 3; его время измерено отдельно и не является парным измерением времени новых решателей.

| Сценарий | Режим | n | R | Совместимость | Назначено | Рейсы | Отклонение | Отклонение/назначение | Пасс./рейс | Время, с | Построение, с | Поиск, с | OPT/FEAS/UNKNOWN | Fallback дат |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| stage3_control | baseline_greedy | 20/20 | 13.847±0.794 | 1.000±0.000 | 159.750±0.550 | 81.850±6.252 | 773.800±102.710 | 4.845±0.650 | 1.962±0.147 | 0.021±0.003 | — | — | 0/0/0 | 0 |
| stage3_control | baseline_v2 | 20/20 | 13.847±0.794 | 1.000±0.000 | 160.000±0.000 | 67.200±5.836 | 1139.800±166.226 | 7.124±1.039 | 2.398±0.206 | 0.007±0.001 | — | — | 0/0/0 | 0 |
| stage3_control | greedy_retiming | 20/20 | 13.847±0.794 | 1.000±0.000 | 160.000±0.000 | 66.450±5.624 | 1002.450±159.474 | 6.265±0.997 | 2.424±0.200 | 0.050±0.014 | — | — | 0/0/0 | 0 |
| stage3_control | ilp_cpsat+warm | 20/20 | 13.847±0.794 | 1.000±0.000 | 160.000±0.000 | 78.550±6.039 | 678.200±89.075 | 4.239±0.557 | 2.048±0.158 | 50.402±0.334 | 0.323±0.239 | 50.028±0.061 | 0/20/0 | 0 |
| stage3_high_few | baseline_greedy | 20/20 | 0.431±0.064 | 0.589±0.128 | 38.900±9.375 | 15.050±2.373 | 332.600±125.371 | 8.475±2.099 | 2.603±0.535 | 0.001±0.000 | — | — | 0/0/0 | 0 |
| stage3_high_few | baseline_v2 | 20/20 | 0.431±0.064 | 0.589±0.128 | 37.600±9.746 | 13.050±2.544 | 313.750±113.309 | 8.252±2.341 | 2.880±0.471 | 0.001±0.000 | — | — | 0/0/0 | 0 |
| stage3_high_few | greedy_retiming | 20/20 | 0.431±0.064 | 0.589±0.128 | 37.950±9.779 | 13.050±2.544 | 316.900±112.340 | 8.262±2.299 | 2.907±0.470 | 0.002±0.000 | — | — | 0/0/0 | 0 |
| stage3_high_few | ilp_cpsat+warm | 20/20 | 0.431±0.064 | 0.589±0.128 | 52.250±10.804 | 18.050±2.012 | 438.050±126.220 | 8.399±2.163 | 2.888±0.453 | 0.249±0.236 | 0.020±0.005 | 0.226±0.231 | 20/0/0 | 0 |
| stage3_high_many | baseline_greedy | 20/20 | 0.431±0.064 | 0.650±0.088 | 50.600±11.038 | 19.550±0.510 | 483.050±182.353 | 9.340±2.164 | 2.586±0.538 | 0.001±0.000 | — | — | 0/0/0 | 0 |
| stage3_high_many | baseline_v2 | 20/20 | 0.431±0.064 | 0.650±0.088 | 54.400±8.593 | 19.600±0.598 | 439.500±105.848 | 8.086±1.546 | 2.770±0.393 | 0.001±0.000 | — | — | 0/0/0 | 0 |
| stage3_high_many | greedy_retiming | 20/20 | 0.431±0.064 | 0.650±0.088 | 54.400±8.593 | 19.600±0.598 | 439.000±105.864 | 8.079±1.554 | 2.770±0.393 | 0.002±0.000 | — | — | 0/0/0 | 0 |
| stage3_high_many | ilp_cpsat+warm | 20/20 | 0.431±0.064 | 0.650±0.088 | 56.900±9.738 | 19.650±0.489 | 411.550±122.104 | 7.197±1.553 | 2.891±0.457 | 0.079±0.034 | 0.011±0.001 | 0.066±0.033 | 20/0/0 | 0 |
| stage3_low_few | baseline_greedy | 20/20 | 1.319±0.076 | 0.675±0.111 | 79.300±13.456 | 33.950±3.859 | 618.350±171.402 | 7.782±1.675 | 2.337±0.303 | 0.003±0.000 | — | — | 0/0/0 | 0 |
| stage3_low_few | baseline_v2 | 20/20 | 1.319±0.076 | 0.675±0.111 | 94.400±13.068 | 35.900±3.243 | 877.850±211.924 | 9.275±1.667 | 2.630±0.279 | 0.002±0.000 | — | — | 0/0/0 | 0 |
| stage3_low_few | greedy_retiming | 20/20 | 1.319±0.076 | 0.675±0.111 | 95.000±13.075 | 35.550±3.300 | 816.250±189.453 | 8.597±1.589 | 2.671±0.267 | 0.014±0.008 | — | — | 0/0/0 | 0 |
| stage3_low_few | ilp_cpsat+warm | 20/20 | 1.319±0.076 | 0.675±0.111 | 101.550±14.870 | 37.000±4.460 | 824.050±171.788 | 8.185±1.536 | 2.741±0.212 | 8.262±8.723 | 0.044±0.008 | 8.212±8.718 | 17/3/0 | 0 |
| stage3_low_many | baseline_greedy | 20/20 | 1.319±0.076 | 0.785±0.118 | 103.900±14.839 | 44.900±4.564 | 813.900±203.597 | 7.820±1.344 | 2.324±0.335 | 0.002±0.000 | — | — | 0/0/0 | 0 |
| stage3_low_many | baseline_v2 | 20/20 | 1.319±0.076 | 0.785±0.118 | 116.150±15.226 | 46.100±5.360 | 1010.500±238.727 | 8.653±1.366 | 2.531±0.273 | 0.002±0.000 | — | — | 0/0/0 | 0 |
| stage3_low_many | greedy_retiming | 20/20 | 1.319±0.076 | 0.785±0.118 | 116.550±15.565 | 45.900±5.310 | 940.000±225.527 | 8.021±1.264 | 2.550±0.279 | 0.018±0.008 | — | — | 0/0/0 | 0 |
| stage3_low_many | ilp_cpsat+warm | 20/20 | 1.319±0.076 | 0.785±0.118 | 119.600±16.366 | 45.250±5.240 | 909.500±204.282 | 7.593±1.220 | 2.652±0.285 | 3.535±4.135 | 0.021±0.003 | 3.509±4.132 | 19/1/0 | 0 |
| stage3_medium_few | baseline_greedy | 20/20 | 0.875±0.091 | 0.621±0.116 | 62.400±12.890 | 25.600±2.873 | 489.350±171.377 | 7.751±1.935 | 2.437±0.434 | 0.002±0.000 | — | — | 0/0/0 | 0 |
| stage3_medium_few | baseline_v2 | 20/20 | 0.875±0.091 | 0.621±0.116 | 68.900±10.662 | 25.150±3.167 | 628.200±187.230 | 9.062±2.116 | 2.753±0.358 | 0.002±0.000 | — | — | 0/0/0 | 0 |
| stage3_medium_few | greedy_retiming | 20/20 | 0.875±0.091 | 0.621±0.116 | 69.650±10.718 | 25.100±3.144 | 620.850±181.970 | 8.883±2.094 | 2.786±0.340 | 0.004±0.002 | — | — | 0/0/0 | 0 |
| stage3_medium_few | ilp_cpsat+warm | 20/20 | 0.875±0.091 | 0.621±0.116 | 81.750±13.333 | 29.850±3.297 | 697.650±171.334 | 8.577±1.825 | 2.738±0.316 | 2.635±6.050 | 0.027±0.006 | 2.603±6.046 | 19/1/0 | 0 |
| stage3_medium_many | baseline_greedy | 20/20 | 0.875±0.091 | 0.706±0.097 | 81.850±14.572 | 33.450±2.911 | 650.200±190.090 | 7.922±1.659 | 2.444±0.354 | 0.001±0.000 | — | — | 0/0/0 | 0 |
| stage3_medium_many | baseline_v2 | 20/20 | 0.875±0.091 | 0.706±0.097 | 89.200±12.668 | 33.800±2.726 | 732.100±199.262 | 8.113±1.357 | 2.649±0.371 | 0.002±0.000 | — | — | 0/0/0 | 0 |
| stage3_medium_many | greedy_retiming | 20/20 | 0.875±0.091 | 0.706±0.097 | 89.400±12.804 | 33.700±2.867 | 703.250±187.420 | 7.782±1.280 | 2.665±0.385 | 0.007±0.004 | — | — | 0/0/0 | 0 |
| stage3_medium_many | ilp_cpsat+warm | 20/20 | 0.875±0.091 | 0.706±0.097 | 93.250±13.333 | 34.300±2.886 | 708.650±186.970 | 7.543±1.329 | 2.725±0.350 | 0.151±0.120 | 0.014±0.002 | 0.134±0.118 | 20/0/0 | 0 |

## Парные исходы

Порядок: выиграл по назначениям / по рейсам при равных назначениях / по отклонению при равных назначениях и рейсах / равен / хуже / нет решения. Wilcoxon — по назначениям.

| Сценарий | Кандидат / эталон | Исходы | Wilcoxon p |
|---|---|---:|---:|
| stage3_control | baseline_v2 / baseline_greedy | 4/16/0/0/0/0 | 0.125000 |
| stage3_control | greedy_retiming / baseline_greedy | 4/16/0/0/0/0 | 0.125000 |
| stage3_control | ilp_cpsat+warm / baseline_greedy | 4/16/0/0/0/0 | 0.125000 |
| stage3_control | ilp_cpsat+warm / baseline_v2 | 0/0/0/0/20/0 | 1.000000 |
| stage3_control | ilp_cpsat+warm / greedy_retiming | 0/0/0/0/20/0 | 1.000000 |
| stage3_high_few | baseline_v2 / baseline_greedy | 8/1/0/0/11/0 | 0.533669 |
| stage3_high_few | greedy_retiming / baseline_greedy | 8/2/0/0/10/0 | 0.723923 |
| stage3_high_few | ilp_cpsat+warm / baseline_greedy | 20/0/0/0/0/0 | 0.000002 |
| stage3_high_few | ilp_cpsat+warm / baseline_v2 | 19/0/1/0/0/0 | 0.000004 |
| stage3_high_few | ilp_cpsat+warm / greedy_retiming | 19/0/1/0/0/0 | 0.000004 |
| stage3_high_many | baseline_v2 / baseline_greedy | 14/0/1/0/5/0 | 0.011238 |
| stage3_high_many | greedy_retiming / baseline_greedy | 14/0/1/0/5/0 | 0.011238 |
| stage3_high_many | ilp_cpsat+warm / baseline_greedy | 19/0/1/0/0/0 | 0.000004 |
| stage3_high_many | ilp_cpsat+warm / baseline_v2 | 17/0/3/0/0/0 | 0.000015 |
| stage3_high_many | ilp_cpsat+warm / greedy_retiming | 17/0/3/0/0/0 | 0.000015 |
| stage3_low_few | baseline_v2 / baseline_greedy | 19/0/0/0/1/0 | 0.000017 |
| stage3_low_few | greedy_retiming / baseline_greedy | 19/0/0/0/1/0 | 0.000015 |
| stage3_low_few | ilp_cpsat+warm / baseline_greedy | 20/0/0/0/0/0 | 0.000002 |
| stage3_low_few | ilp_cpsat+warm / baseline_v2 | 16/3/0/0/1/0 | 0.000046 |
| stage3_low_few | ilp_cpsat+warm / greedy_retiming | 15/4/0/0/1/0 | 0.000092 |
| stage3_low_many | baseline_v2 / baseline_greedy | 20/0/0/0/0/0 | 0.000002 |
| stage3_low_many | greedy_retiming / baseline_greedy | 20/0/0/0/0/0 | 0.000002 |
| stage3_low_many | ilp_cpsat+warm / baseline_greedy | 20/0/0/0/0/0 | 0.000002 |
| stage3_low_many | ilp_cpsat+warm / baseline_v2 | 14/3/3/0/0/0 | 0.000122 |
| stage3_low_many | ilp_cpsat+warm / greedy_retiming | 14/3/3/0/0/0 | 0.000122 |
| stage3_medium_few | baseline_v2 / baseline_greedy | 15/0/0/0/5/0 | 0.009081 |
| stage3_medium_few | greedy_retiming / baseline_greedy | 16/0/0/0/4/0 | 0.001778 |
| stage3_medium_few | ilp_cpsat+warm / baseline_greedy | 20/0/0/0/0/0 | 0.000002 |
| stage3_medium_few | ilp_cpsat+warm / baseline_v2 | 19/0/1/0/0/0 | 0.000004 |
| stage3_medium_few | ilp_cpsat+warm / greedy_retiming | 19/0/1/0/0/0 | 0.000004 |
| stage3_medium_many | baseline_v2 / baseline_greedy | 15/1/0/0/4/0 | 0.001217 |
| stage3_medium_many | greedy_retiming / baseline_greedy | 15/1/0/0/4/0 | 0.001022 |
| stage3_medium_many | ilp_cpsat+warm / baseline_greedy | 19/0/1/0/0/0 | 0.000004 |
| stage3_medium_many | ilp_cpsat+warm / baseline_v2 | 13/1/5/0/1/0 | 0.000244 |
| stage3_medium_many | ilp_cpsat+warm / greedy_retiming | 13/1/4/0/2/0 | 0.000244 |

## Парные разности и 95% CI

Разность = кандидат − эталон. Отрицательные разности рейсов, отклонения и времени означают уменьшение. CI по отдельным метрикам не означает лексикографического выигрыша.

| Сценарий | Кандидат / эталон | Метрика | n | Δ среднее | 95% CI |
|---|---|---|---:|---:|---:|
| stage3_control | baseline_v2 / baseline_greedy | assigned_requests | 20 | +0.250 | [+0.050; +0.500] |
| stage3_control | baseline_v2 / baseline_greedy | trip_count | 20 | -14.650 | [-16.950; -12.400] |
| stage3_control | baseline_v2 / baseline_greedy | total_time_deviation_minutes | 20 | +366.000 | [+309.145; +427.059] |
| stage3_control | baseline_v2 / baseline_greedy | mean_time_deviation_minutes | 20 | +2.279 | [+1.910; +2.666] |
| stage3_control | baseline_v2 / baseline_greedy | mean_passengers_per_trip | 20 | +0.435 | [+0.363; +0.510] |
| stage3_control | baseline_v2 / baseline_greedy | runtime_seconds | 20 | -0.014 | [-0.015; -0.013] |
| stage3_control | greedy_retiming / baseline_greedy | assigned_requests | 20 | +0.250 | [+0.050; +0.500] |
| stage3_control | greedy_retiming / baseline_greedy | trip_count | 20 | -15.400 | [-17.500; -13.450] |
| stage3_control | greedy_retiming / baseline_greedy | total_time_deviation_minutes | 20 | +228.650 | [+174.395; +286.755] |
| stage3_control | greedy_retiming / baseline_greedy | mean_time_deviation_minutes | 20 | +1.421 | [+1.084; +1.777] |
| stage3_control | greedy_retiming / baseline_greedy | mean_passengers_per_trip | 20 | +0.461 | [+0.398; +0.526] |
| stage3_control | greedy_retiming / baseline_greedy | runtime_seconds | 20 | +0.029 | [+0.023; +0.035] |
| stage3_control | ilp_cpsat+warm / baseline_greedy | assigned_requests | 20 | +0.250 | [+0.050; +0.501] |
| stage3_control | ilp_cpsat+warm / baseline_greedy | trip_count | 20 | -3.300 | [-4.201; -2.200] |
| stage3_control | ilp_cpsat+warm / baseline_greedy | total_time_deviation_minutes | 20 | -95.600 | [-131.251; -61.049] |
| stage3_control | ilp_cpsat+warm / baseline_greedy | mean_time_deviation_minutes | 20 | -0.606 | [-0.834; -0.397] |
| stage3_control | ilp_cpsat+warm / baseline_greedy | mean_passengers_per_trip | 20 | +0.086 | [+0.059; +0.109] |
| stage3_control | ilp_cpsat+warm / baseline_greedy | runtime_seconds | 20 | +50.381 | [+50.271; +50.547] |
| stage3_control | ilp_cpsat+warm / baseline_v2 | assigned_requests | 20 | +0.000 | [+0.000; +0.000] |
| stage3_control | ilp_cpsat+warm / baseline_v2 | trip_count | 20 | +11.350 | [+8.750; +13.750] |
| stage3_control | ilp_cpsat+warm / baseline_v2 | total_time_deviation_minutes | 20 | -461.600 | [-520.303; -405.330] |
| stage3_control | ilp_cpsat+warm / baseline_v2 | mean_time_deviation_minutes | 20 | -2.885 | [-3.231; -2.521] |
| stage3_control | ilp_cpsat+warm / baseline_v2 | mean_passengers_per_trip | 20 | -0.349 | [-0.430; -0.265] |
| stage3_control | ilp_cpsat+warm / baseline_v2 | runtime_seconds | 20 | +50.394 | [+50.283; +50.562] |
| stage3_control | ilp_cpsat+warm / greedy_retiming | assigned_requests | 20 | +0.000 | [+0.000; +0.000] |
| stage3_control | ilp_cpsat+warm / greedy_retiming | trip_count | 20 | +12.100 | [+9.949; +14.300] |
| stage3_control | ilp_cpsat+warm / greedy_retiming | total_time_deviation_minutes | 20 | -324.250 | [-372.314; -272.699] |
| stage3_control | ilp_cpsat+warm / greedy_retiming | mean_time_deviation_minutes | 20 | -2.027 | [-2.341; -1.712] |
| stage3_control | ilp_cpsat+warm / greedy_retiming | mean_passengers_per_trip | 20 | -0.375 | [-0.452; -0.301] |
| stage3_control | ilp_cpsat+warm / greedy_retiming | runtime_seconds | 20 | +50.352 | [+50.243; +50.521] |
| stage3_high_few | baseline_v2 / baseline_greedy | assigned_requests | 20 | -1.300 | [-5.950; +3.001] |
| stage3_high_few | baseline_v2 / baseline_greedy | trip_count | 20 | -2.000 | [-3.500; -0.250] |
| stage3_high_few | baseline_v2 / baseline_greedy | total_time_deviation_minutes | 20 | -18.850 | [-96.206; +53.786] |
| stage3_high_few | baseline_v2 / baseline_greedy | mean_time_deviation_minutes | 20 | -0.222 | [-1.554; +0.972] |
| stage3_high_few | baseline_v2 / baseline_greedy | mean_passengers_per_trip | 20 | +0.277 | [+0.082; +0.480] |
| stage3_high_few | baseline_v2 / baseline_greedy | runtime_seconds | 20 | +0.000 | [-0.000; +0.000] |
| stage3_high_few | greedy_retiming / baseline_greedy | assigned_requests | 20 | -0.950 | [-5.500; +3.501] |
| stage3_high_few | greedy_retiming / baseline_greedy | trip_count | 20 | -2.000 | [-3.501; -0.400] |
| stage3_high_few | greedy_retiming / baseline_greedy | total_time_deviation_minutes | 20 | -15.700 | [-94.364; +53.454] |
| stage3_high_few | greedy_retiming / baseline_greedy | mean_time_deviation_minutes | 20 | -0.213 | [-1.449; +0.994] |
| stage3_high_few | greedy_retiming / baseline_greedy | mean_passengers_per_trip | 20 | +0.304 | [+0.113; +0.493] |
| stage3_high_few | greedy_retiming / baseline_greedy | runtime_seconds | 20 | +0.001 | [+0.000; +0.001] |
| stage3_high_few | ilp_cpsat+warm / baseline_greedy | assigned_requests | 20 | +13.350 | [+9.500; +17.400] |
| stage3_high_few | ilp_cpsat+warm / baseline_greedy | trip_count | 20 | +3.000 | [+1.800; +4.400] |
| stage3_high_few | ilp_cpsat+warm / baseline_greedy | total_time_deviation_minutes | 20 | +105.450 | [+50.198; +164.102] |
| stage3_high_few | ilp_cpsat+warm / baseline_greedy | mean_time_deviation_minutes | 20 | -0.075 | [-0.836; +0.763] |
| stage3_high_few | ilp_cpsat+warm / baseline_greedy | mean_passengers_per_trip | 20 | +0.285 | [+0.199; +0.371] |
| stage3_high_few | ilp_cpsat+warm / baseline_greedy | runtime_seconds | 20 | +0.247 | [+0.160; +0.357] |
| stage3_high_few | ilp_cpsat+warm / baseline_v2 | assigned_requests | 20 | +14.650 | [+10.648; +18.950] |
| stage3_high_few | ilp_cpsat+warm / baseline_v2 | trip_count | 20 | +5.000 | [+3.700; +6.251] |
| stage3_high_few | ilp_cpsat+warm / baseline_v2 | total_time_deviation_minutes | 20 | +124.300 | [+63.688; +193.505] |
| stage3_high_few | ilp_cpsat+warm / baseline_v2 | mean_time_deviation_minutes | 20 | +0.147 | [-0.963; +1.336] |
| stage3_high_few | ilp_cpsat+warm / baseline_v2 | mean_passengers_per_trip | 20 | +0.008 | [-0.138; +0.160] |
| stage3_high_few | ilp_cpsat+warm / baseline_v2 | runtime_seconds | 20 | +0.247 | [+0.156; +0.361] |
| stage3_high_few | ilp_cpsat+warm / greedy_retiming | assigned_requests | 20 | +14.300 | [+10.550; +18.601] |
| stage3_high_few | ilp_cpsat+warm / greedy_retiming | trip_count | 20 | +5.000 | [+3.650; +6.300] |
| stage3_high_few | ilp_cpsat+warm / greedy_retiming | total_time_deviation_minutes | 20 | +121.150 | [+64.094; +189.252] |
| stage3_high_few | ilp_cpsat+warm / greedy_retiming | mean_time_deviation_minutes | 20 | +0.138 | [-0.927; +1.285] |
| stage3_high_few | ilp_cpsat+warm / greedy_retiming | mean_passengers_per_trip | 20 | -0.019 | [-0.160; +0.123] |
| stage3_high_few | ilp_cpsat+warm / greedy_retiming | runtime_seconds | 20 | +0.247 | [+0.160; +0.362] |
| stage3_high_many | baseline_v2 / baseline_greedy | assigned_requests | 20 | +3.800 | [+1.400; +6.400] |
| stage3_high_many | baseline_v2 / baseline_greedy | trip_count | 20 | +0.050 | [-0.100; +0.200] |
| stage3_high_many | baseline_v2 / baseline_greedy | total_time_deviation_minutes | 20 | -43.550 | [-97.106; +4.206] |
| stage3_high_many | baseline_v2 / baseline_greedy | mean_time_deviation_minutes | 20 | -1.254 | [-1.959; -0.592] |
| stage3_high_many | baseline_v2 / baseline_greedy | mean_passengers_per_trip | 20 | +0.185 | [+0.058; +0.312] |
| stage3_high_many | baseline_v2 / baseline_greedy | runtime_seconds | 20 | +0.000 | [+0.000; +0.000] |
| stage3_high_many | greedy_retiming / baseline_greedy | assigned_requests | 20 | +3.800 | [+1.300; +6.550] |
| stage3_high_many | greedy_retiming / baseline_greedy | trip_count | 20 | +0.050 | [-0.100; +0.200] |
| stage3_high_many | greedy_retiming / baseline_greedy | total_time_deviation_minutes | 20 | -44.050 | [-97.756; +6.250] |
| stage3_high_many | greedy_retiming / baseline_greedy | mean_time_deviation_minutes | 20 | -1.261 | [-1.975; -0.595] |
| stage3_high_many | greedy_retiming / baseline_greedy | mean_passengers_per_trip | 20 | +0.185 | [+0.061; +0.317] |
| stage3_high_many | greedy_retiming / baseline_greedy | runtime_seconds | 20 | +0.001 | [+0.001; +0.001] |
| stage3_high_many | ilp_cpsat+warm / baseline_greedy | assigned_requests | 20 | +6.300 | [+4.399; +8.451] |
| stage3_high_many | ilp_cpsat+warm / baseline_greedy | trip_count | 20 | +0.100 | [+0.000; +0.250] |
| stage3_high_many | ilp_cpsat+warm / baseline_greedy | total_time_deviation_minutes | 20 | -71.500 | [-118.004; -26.093] |
| stage3_high_many | ilp_cpsat+warm / baseline_greedy | mean_time_deviation_minutes | 20 | -2.143 | [-2.771; -1.501] |
| stage3_high_many | ilp_cpsat+warm / baseline_greedy | mean_passengers_per_trip | 20 | +0.305 | [+0.201; +0.422] |
| stage3_high_many | ilp_cpsat+warm / baseline_greedy | runtime_seconds | 20 | +0.078 | [+0.064; +0.093] |
| stage3_high_many | ilp_cpsat+warm / baseline_v2 | assigned_requests | 20 | +2.500 | [+1.450; +3.750] |
| stage3_high_many | ilp_cpsat+warm / baseline_v2 | trip_count | 20 | +0.050 | [+0.000; +0.150] |
| stage3_high_many | ilp_cpsat+warm / baseline_v2 | total_time_deviation_minutes | 20 | -27.950 | [-44.450; -11.498] |
| stage3_high_many | ilp_cpsat+warm / baseline_v2 | mean_time_deviation_minutes | 20 | -0.889 | [-1.170; -0.637] |
| stage3_high_many | ilp_cpsat+warm / baseline_v2 | mean_passengers_per_trip | 20 | +0.121 | [+0.066; +0.180] |
| stage3_high_many | ilp_cpsat+warm / baseline_v2 | runtime_seconds | 20 | +0.078 | [+0.064; +0.094] |
| stage3_high_many | ilp_cpsat+warm / greedy_retiming | assigned_requests | 20 | +2.500 | [+1.450; +3.750] |
| stage3_high_many | ilp_cpsat+warm / greedy_retiming | trip_count | 20 | +0.050 | [+0.000; +0.150] |
| stage3_high_many | ilp_cpsat+warm / greedy_retiming | total_time_deviation_minutes | 20 | -27.450 | [-44.703; -10.648] |
| stage3_high_many | ilp_cpsat+warm / greedy_retiming | mean_time_deviation_minutes | 20 | -0.881 | [-1.138; -0.626] |
| stage3_high_many | ilp_cpsat+warm / greedy_retiming | mean_passengers_per_trip | 20 | +0.121 | [+0.068; +0.183] |
| stage3_high_many | ilp_cpsat+warm / greedy_retiming | runtime_seconds | 20 | +0.077 | [+0.063; +0.092] |
| stage3_low_few | baseline_v2 / baseline_greedy | assigned_requests | 20 | +15.100 | [+10.750; +19.100] |
| stage3_low_few | baseline_v2 / baseline_greedy | trip_count | 20 | +1.950 | [+0.449; +3.451] |
| stage3_low_few | baseline_v2 / baseline_greedy | total_time_deviation_minutes | 20 | +259.500 | [+170.549; +351.411] |
| stage3_low_few | baseline_v2 / baseline_greedy | mean_time_deviation_minutes | 20 | +1.493 | [+0.734; +2.300] |
| stage3_low_few | baseline_v2 / baseline_greedy | mean_passengers_per_trip | 20 | +0.293 | [+0.212; +0.386] |
| stage3_low_few | baseline_v2 / baseline_greedy | runtime_seconds | 20 | -0.000 | [-0.001; -0.000] |
| stage3_low_few | greedy_retiming / baseline_greedy | assigned_requests | 20 | +15.700 | [+11.450; +19.650] |
| stage3_low_few | greedy_retiming / baseline_greedy | trip_count | 20 | +1.600 | [+0.049; +3.200] |
| stage3_low_few | greedy_retiming / baseline_greedy | total_time_deviation_minutes | 20 | +197.900 | [+112.099; +280.857] |
| stage3_low_few | greedy_retiming / baseline_greedy | mean_time_deviation_minutes | 20 | +0.814 | [+0.094; +1.516] |
| stage3_low_few | greedy_retiming / baseline_greedy | mean_passengers_per_trip | 20 | +0.334 | [+0.258; +0.413] |
| stage3_low_few | greedy_retiming / baseline_greedy | runtime_seconds | 20 | +0.012 | [+0.008; +0.015] |
| stage3_low_few | ilp_cpsat+warm / baseline_greedy | assigned_requests | 20 | +22.250 | [+18.350; +26.251] |
| stage3_low_few | ilp_cpsat+warm / baseline_greedy | trip_count | 20 | +3.050 | [+1.050; +5.050] |
| stage3_low_few | ilp_cpsat+warm / baseline_greedy | total_time_deviation_minutes | 20 | +205.700 | [+134.989; +273.901] |
| stage3_low_few | ilp_cpsat+warm / baseline_greedy | mean_time_deviation_minutes | 20 | +0.402 | [-0.172; +0.950] |
| stage3_low_few | ilp_cpsat+warm / baseline_greedy | mean_passengers_per_trip | 20 | +0.403 | [+0.326; +0.484] |
| stage3_low_few | ilp_cpsat+warm / baseline_greedy | runtime_seconds | 20 | +8.259 | [+4.765; +12.273] |
| stage3_low_few | ilp_cpsat+warm / baseline_v2 | assigned_requests | 20 | +7.150 | [+4.749; +9.850] |
| stage3_low_few | ilp_cpsat+warm / baseline_v2 | trip_count | 20 | +1.100 | [-0.450; +2.651] |
| stage3_low_few | ilp_cpsat+warm / baseline_v2 | total_time_deviation_minutes | 20 | -53.800 | [-105.006; -1.570] |
| stage3_low_few | ilp_cpsat+warm / baseline_v2 | mean_time_deviation_minutes | 20 | -1.091 | [-1.622; -0.566] |
| stage3_low_few | ilp_cpsat+warm / baseline_v2 | mean_passengers_per_trip | 20 | +0.110 | [+0.049; +0.175] |
| stage3_low_few | ilp_cpsat+warm / baseline_v2 | runtime_seconds | 20 | +8.259 | [+4.931; +12.496] |
| stage3_low_few | ilp_cpsat+warm / greedy_retiming | assigned_requests | 20 | +6.550 | [+4.150; +9.100] |
| stage3_low_few | ilp_cpsat+warm / greedy_retiming | trip_count | 20 | +1.450 | [+0.100; +2.751] |
| stage3_low_few | ilp_cpsat+warm / greedy_retiming | total_time_deviation_minutes | 20 | +7.800 | [-32.152; +54.762] |
| stage3_low_few | ilp_cpsat+warm / greedy_retiming | mean_time_deviation_minutes | 20 | -0.412 | [-0.799; -0.002] |
| stage3_low_few | ilp_cpsat+warm / greedy_retiming | mean_passengers_per_trip | 20 | +0.070 | [+0.017; +0.124] |
| stage3_low_few | ilp_cpsat+warm / greedy_retiming | runtime_seconds | 20 | +8.247 | [+4.918; +12.434] |
| stage3_low_many | baseline_v2 / baseline_greedy | assigned_requests | 20 | +12.250 | [+9.800; +14.851] |
| stage3_low_many | baseline_v2 / baseline_greedy | trip_count | 20 | +1.200 | [-0.150; +2.351] |
| stage3_low_many | baseline_v2 / baseline_greedy | total_time_deviation_minutes | 20 | +196.600 | [+143.946; +254.701] |
| stage3_low_many | baseline_v2 / baseline_greedy | mean_time_deviation_minutes | 20 | +0.833 | [+0.474; +1.201] |
| stage3_low_many | baseline_v2 / baseline_greedy | mean_passengers_per_trip | 20 | +0.206 | [+0.118; +0.309] |
| stage3_low_many | baseline_v2 / baseline_greedy | runtime_seconds | 20 | +0.001 | [+0.001; +0.001] |
| stage3_low_many | greedy_retiming / baseline_greedy | assigned_requests | 20 | +12.650 | [+10.199; +15.350] |
| stage3_low_many | greedy_retiming / baseline_greedy | trip_count | 20 | +1.000 | [-0.300; +2.100] |
| stage3_low_many | greedy_retiming / baseline_greedy | total_time_deviation_minutes | 20 | +126.100 | [+73.094; +178.155] |
| stage3_low_many | greedy_retiming / baseline_greedy | mean_time_deviation_minutes | 20 | +0.200 | [-0.163; +0.550] |
| stage3_low_many | greedy_retiming / baseline_greedy | mean_passengers_per_trip | 20 | +0.226 | [+0.138; +0.322] |
| stage3_low_many | greedy_retiming / baseline_greedy | runtime_seconds | 20 | +0.016 | [+0.013; +0.020] |
| stage3_low_many | ilp_cpsat+warm / baseline_greedy | assigned_requests | 20 | +15.700 | [+13.349; +17.900] |
| stage3_low_many | ilp_cpsat+warm / baseline_greedy | trip_count | 20 | +0.350 | [-1.150; +1.850] |
| stage3_low_many | ilp_cpsat+warm / baseline_greedy | total_time_deviation_minutes | 20 | +95.600 | [+49.250; +144.392] |
| stage3_low_many | ilp_cpsat+warm / baseline_greedy | mean_time_deviation_minutes | 20 | -0.227 | [-0.519; +0.107] |
| stage3_low_many | ilp_cpsat+warm / baseline_greedy | mean_passengers_per_trip | 20 | +0.328 | [+0.243; +0.423] |
| stage3_low_many | ilp_cpsat+warm / baseline_greedy | runtime_seconds | 20 | +3.533 | [+1.921; +5.411] |
| stage3_low_many | ilp_cpsat+warm / baseline_v2 | assigned_requests | 20 | +3.450 | [+1.850; +5.200] |
| stage3_low_many | ilp_cpsat+warm / baseline_v2 | trip_count | 20 | -0.850 | [-1.751; -0.100] |
| stage3_low_many | ilp_cpsat+warm / baseline_v2 | total_time_deviation_minutes | 20 | -101.000 | [-138.709; -64.248] |
| stage3_low_many | ilp_cpsat+warm / baseline_v2 | mean_time_deviation_minutes | 20 | -1.060 | [-1.371; -0.780] |
| stage3_low_many | ilp_cpsat+warm / baseline_v2 | mean_passengers_per_trip | 20 | +0.121 | [+0.069; +0.184] |
| stage3_low_many | ilp_cpsat+warm / baseline_v2 | runtime_seconds | 20 | +3.532 | [+1.851; +5.354] |
| stage3_low_many | ilp_cpsat+warm / greedy_retiming | assigned_requests | 20 | +3.050 | [+1.700; +4.800] |
| stage3_low_many | ilp_cpsat+warm / greedy_retiming | trip_count | 20 | -0.650 | [-1.500; +0.150] |
| stage3_low_many | ilp_cpsat+warm / greedy_retiming | total_time_deviation_minutes | 20 | -30.500 | [-57.802; -3.595] |
| stage3_low_many | ilp_cpsat+warm / greedy_retiming | mean_time_deviation_minutes | 20 | -0.427 | [-0.645; -0.213] |
| stage3_low_many | ilp_cpsat+warm / greedy_retiming | mean_passengers_per_trip | 20 | +0.102 | [+0.054; +0.154] |
| stage3_low_many | ilp_cpsat+warm / greedy_retiming | runtime_seconds | 20 | +3.517 | [+1.892; +5.333] |
| stage3_medium_few | baseline_v2 / baseline_greedy | assigned_requests | 20 | +6.500 | [+2.650; +10.451] |
| stage3_medium_few | baseline_v2 / baseline_greedy | trip_count | 20 | -0.450 | [-1.850; +1.000] |
| stage3_medium_few | baseline_v2 / baseline_greedy | total_time_deviation_minutes | 20 | +138.850 | [+58.297; +212.711] |
| stage3_medium_few | baseline_v2 / baseline_greedy | mean_time_deviation_minutes | 20 | +1.311 | [+0.478; +2.129] |
| stage3_medium_few | baseline_v2 / baseline_greedy | mean_passengers_per_trip | 20 | +0.317 | [+0.168; +0.469] |
| stage3_medium_few | baseline_v2 / baseline_greedy | runtime_seconds | 20 | -0.000 | [-0.000; +0.000] |
| stage3_medium_few | greedy_retiming / baseline_greedy | assigned_requests | 20 | +7.250 | [+3.649; +11.050] |
| stage3_medium_few | greedy_retiming / baseline_greedy | trip_count | 20 | -0.500 | [-1.800; +1.050] |
| stage3_medium_few | greedy_retiming / baseline_greedy | total_time_deviation_minutes | 20 | +131.500 | [+49.699; +205.911] |
| stage3_medium_few | greedy_retiming / baseline_greedy | mean_time_deviation_minutes | 20 | +1.132 | [+0.248; +1.958] |
| stage3_medium_few | greedy_retiming / baseline_greedy | mean_passengers_per_trip | 20 | +0.349 | [+0.209; +0.498] |
| stage3_medium_few | greedy_retiming / baseline_greedy | runtime_seconds | 20 | +0.002 | [+0.002; +0.003] |
| stage3_medium_few | ilp_cpsat+warm / baseline_greedy | assigned_requests | 20 | +19.350 | [+15.250; +23.300] |
| stage3_medium_few | ilp_cpsat+warm / baseline_greedy | trip_count | 20 | +4.250 | [+2.600; +5.801] |
| stage3_medium_few | ilp_cpsat+warm / baseline_greedy | total_time_deviation_minutes | 20 | +208.300 | [+147.347; +266.442] |
| stage3_medium_few | ilp_cpsat+warm / baseline_greedy | mean_time_deviation_minutes | 20 | +0.826 | [+0.182; +1.525] |
| stage3_medium_few | ilp_cpsat+warm / baseline_greedy | mean_passengers_per_trip | 20 | +0.301 | [+0.196; +0.420] |
| stage3_medium_few | ilp_cpsat+warm / baseline_greedy | runtime_seconds | 20 | +2.633 | [+0.840; +5.661] |
| stage3_medium_few | ilp_cpsat+warm / baseline_v2 | assigned_requests | 20 | +12.850 | [+9.499; +16.650] |
| stage3_medium_few | ilp_cpsat+warm / baseline_v2 | trip_count | 20 | +4.700 | [+3.400; +6.150] |
| stage3_medium_few | ilp_cpsat+warm / baseline_v2 | total_time_deviation_minutes | 20 | +69.450 | [+24.617; +126.701] |
| stage3_medium_few | ilp_cpsat+warm / baseline_v2 | mean_time_deviation_minutes | 20 | -0.484 | [-0.996; +0.037] |
| stage3_medium_few | ilp_cpsat+warm / baseline_v2 | mean_passengers_per_trip | 20 | -0.015 | [-0.104; +0.079] |
| stage3_medium_few | ilp_cpsat+warm / baseline_v2 | runtime_seconds | 20 | +2.633 | [+0.831; +5.635] |
| stage3_medium_few | ilp_cpsat+warm / greedy_retiming | assigned_requests | 20 | +12.100 | [+9.050; +15.700] |
| stage3_medium_few | ilp_cpsat+warm / greedy_retiming | trip_count | 20 | +4.750 | [+3.450; +6.050] |
| stage3_medium_few | ilp_cpsat+warm / greedy_retiming | total_time_deviation_minutes | 20 | +76.800 | [+29.295; +134.002] |
| stage3_medium_few | ilp_cpsat+warm / greedy_retiming | mean_time_deviation_minutes | 20 | -0.305 | [-0.768; +0.228] |
| stage3_medium_few | ilp_cpsat+warm / greedy_retiming | mean_passengers_per_trip | 20 | -0.047 | [-0.123; +0.033] |
| stage3_medium_few | ilp_cpsat+warm / greedy_retiming | runtime_seconds | 20 | +2.631 | [+0.797; +5.656] |
| stage3_medium_many | baseline_v2 / baseline_greedy | assigned_requests | 20 | +7.350 | [+3.849; +11.250] |
| stage3_medium_many | baseline_v2 / baseline_greedy | trip_count | 20 | +0.350 | [-0.550; +1.500] |
| stage3_medium_many | baseline_v2 / baseline_greedy | total_time_deviation_minutes | 20 | +81.900 | [+34.495; +130.000] |
| stage3_medium_many | baseline_v2 / baseline_greedy | mean_time_deviation_minutes | 20 | +0.191 | [-0.201; +0.562] |
| stage3_medium_many | baseline_v2 / baseline_greedy | mean_passengers_per_trip | 20 | +0.205 | [+0.124; +0.288] |
| stage3_medium_many | baseline_v2 / baseline_greedy | runtime_seconds | 20 | +0.001 | [+0.001; +0.001] |
| stage3_medium_many | greedy_retiming / baseline_greedy | assigned_requests | 20 | +7.550 | [+3.849; +11.200] |
| stage3_medium_many | greedy_retiming / baseline_greedy | trip_count | 20 | +0.250 | [-0.650; +1.400] |
| stage3_medium_many | greedy_retiming / baseline_greedy | total_time_deviation_minutes | 20 | +53.050 | [+2.445; +99.600] |
| stage3_medium_many | greedy_retiming / baseline_greedy | mean_time_deviation_minutes | 20 | -0.140 | [-0.532; +0.243] |
| stage3_medium_many | greedy_retiming / baseline_greedy | mean_passengers_per_trip | 20 | +0.221 | [+0.136; +0.297] |
| stage3_medium_many | greedy_retiming / baseline_greedy | runtime_seconds | 20 | +0.006 | [+0.004; +0.008] |
| stage3_medium_many | ilp_cpsat+warm / baseline_greedy | assigned_requests | 20 | +11.400 | [+8.299; +14.900] |
| stage3_medium_many | ilp_cpsat+warm / baseline_greedy | trip_count | 20 | +0.850 | [+0.000; +1.800] |
| stage3_medium_many | ilp_cpsat+warm / baseline_greedy | total_time_deviation_minutes | 20 | +58.450 | [+4.748; +107.702] |
| stage3_medium_many | ilp_cpsat+warm / baseline_greedy | mean_time_deviation_minutes | 20 | -0.379 | [-0.766; +0.000] |
| stage3_medium_many | ilp_cpsat+warm / baseline_greedy | mean_passengers_per_trip | 20 | +0.280 | [+0.206; +0.355] |
| stage3_medium_many | ilp_cpsat+warm / baseline_greedy | runtime_seconds | 20 | +0.150 | [+0.110; +0.210] |
| stage3_medium_many | ilp_cpsat+warm / baseline_v2 | assigned_requests | 20 | +4.050 | [+1.950; +6.750] |
| stage3_medium_many | ilp_cpsat+warm / baseline_v2 | trip_count | 20 | +0.500 | [+0.000; +1.051] |
| stage3_medium_many | ilp_cpsat+warm / baseline_v2 | total_time_deviation_minutes | 20 | -23.450 | [-56.255; +15.351] |
| stage3_medium_many | ilp_cpsat+warm / baseline_v2 | mean_time_deviation_minutes | 20 | -0.570 | [-0.854; -0.272] |
| stage3_medium_many | ilp_cpsat+warm / baseline_v2 | mean_passengers_per_trip | 20 | +0.076 | [+0.025; +0.140] |
| stage3_medium_many | ilp_cpsat+warm / baseline_v2 | runtime_seconds | 20 | +0.150 | [+0.106; +0.208] |
| stage3_medium_many | ilp_cpsat+warm / greedy_retiming | assigned_requests | 20 | +3.850 | [+1.850; +6.350] |
| stage3_medium_many | ilp_cpsat+warm / greedy_retiming | trip_count | 20 | +0.600 | [+0.100; +1.200] |
| stage3_medium_many | ilp_cpsat+warm / greedy_retiming | total_time_deviation_minutes | 20 | +5.400 | [-26.651; +41.811] |
| stage3_medium_many | ilp_cpsat+warm / greedy_retiming | mean_time_deviation_minutes | 20 | -0.239 | [-0.485; +0.020] |
| stage3_medium_many | ilp_cpsat+warm / greedy_retiming | mean_passengers_per_trip | 20 | +0.060 | [+0.011; +0.125] |
| stage3_medium_many | ilp_cpsat+warm / greedy_retiming | runtime_seconds | 20 | +0.144 | [+0.101; +0.204] |

## Закрытая доля разрыва

Среднее по парам `(эвристика − baseline)/(W − baseline)`; n включает только ненулевой знаменатель. Для рейсов и среднего отклонения на назначение дополнительно требуется одинаковое число назначений у всех трёх алгоритмов. Значения не ограничены диапазоном 0–1; отрицательные значения и значения больше 1 сохранены. pooled — отношение сумм разностей на тех же парах.

| Сценарий | Эвристика | Метрика | n | Средняя доля | pooled |
|---|---|---|---:|---:|---:|
| stage3_control | baseline_v2 | assigned_requests | 4 | 100.00% | 100.00% |
| stage3_control | baseline_v2 | trip_count | 16 | 486.67% | 379.31% |
| stage3_control | baseline_v2 | mean_time_deviation_minutes | 16 | -561.32% | -413.71% |
| stage3_control | greedy_retiming | assigned_requests | 4 | 100.00% | 100.00% |
| stage3_control | greedy_retiming | trip_count | 16 | 525.00% | 405.17% |
| stage3_control | greedy_retiming | mean_time_deviation_minutes | 16 | -335.67% | -265.90% |
| stage3_high_few | baseline_v2 | assigned_requests | 20 | -73.82% | -9.74% |
| stage3_high_few | baseline_v2 | trip_count | 0 | н/д | н/д |
| stage3_high_few | baseline_v2 | mean_time_deviation_minutes | 0 | н/д | н/д |
| stage3_high_few | greedy_retiming | assigned_requests | 20 | -72.11% | -7.12% |
| stage3_high_few | greedy_retiming | trip_count | 0 | н/д | н/д |
| stage3_high_few | greedy_retiming | mean_time_deviation_minutes | 0 | н/д | н/д |
| stage3_high_many | baseline_v2 | assigned_requests | 19 | 37.73% | 63.49% |
| stage3_high_many | baseline_v2 | trip_count | 0 | н/д | н/д |
| stage3_high_many | baseline_v2 | mean_time_deviation_minutes | 0 | н/д | н/д |
| stage3_high_many | greedy_retiming | assigned_requests | 19 | 37.73% | 63.49% |
| stage3_high_many | greedy_retiming | trip_count | 0 | н/д | н/д |
| stage3_high_many | greedy_retiming | mean_time_deviation_minutes | 0 | н/д | н/д |
| stage3_low_few | baseline_v2 | assigned_requests | 20 | 64.18% | 67.87% |
| stage3_low_few | baseline_v2 | trip_count | 0 | н/д | н/д |
| stage3_low_few | baseline_v2 | mean_time_deviation_minutes | 0 | н/д | н/д |
| stage3_low_few | greedy_retiming | assigned_requests | 20 | 67.76% | 70.56% |
| stage3_low_few | greedy_retiming | trip_count | 0 | н/д | н/д |
| stage3_low_few | greedy_retiming | mean_time_deviation_minutes | 0 | н/д | н/д |
| stage3_low_many | baseline_v2 | assigned_requests | 20 | 78.47% | 78.03% |
| stage3_low_many | baseline_v2 | trip_count | 0 | н/д | н/д |
| stage3_low_many | baseline_v2 | mean_time_deviation_minutes | 0 | н/д | н/д |
| stage3_low_many | greedy_retiming | assigned_requests | 20 | 81.05% | 80.57% |
| stage3_low_many | greedy_retiming | trip_count | 0 | н/д | н/д |
| stage3_low_many | greedy_retiming | mean_time_deviation_minutes | 0 | н/д | н/д |
| stage3_medium_few | baseline_v2 | assigned_requests | 20 | 12.54% | 33.59% |
| stage3_medium_few | baseline_v2 | trip_count | 0 | н/д | н/д |
| stage3_medium_few | baseline_v2 | mean_time_deviation_minutes | 0 | н/д | н/д |
| stage3_medium_few | greedy_retiming | assigned_requests | 20 | 21.03% | 37.47% |
| stage3_medium_few | greedy_retiming | trip_count | 0 | н/д | н/д |
| stage3_medium_few | greedy_retiming | mean_time_deviation_minutes | 0 | н/д | н/д |
| stage3_medium_many | baseline_v2 | assigned_requests | 19 | 23.64% | 65.35% |
| stage3_medium_many | baseline_v2 | trip_count | 0 | н/д | н/д |
| stage3_medium_many | baseline_v2 | mean_time_deviation_minutes | 0 | н/д | н/д |
| stage3_medium_many | greedy_retiming | assigned_requests | 19 | 25.35% | 67.11% |
| stage3_medium_many | greedy_retiming | trip_count | 0 | н/д | н/д |
| stage3_medium_many | greedy_retiming | mean_time_deviation_minutes | 0 | н/д | н/д |
