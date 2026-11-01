# Этап 4: scale, синтетические результаты

Все параметры PLACEHOLDER, 2000 парных bootstrap-повторов, seed 451; лексикографическая цель: максимум назначений, минимум рейсов, минимум суммарного отклонения. CI — percentile bootstrap разностей candidate − reference, paired по seed; Wilcoxon — точная двусторонняя знаково-ранговая перестановка без поправки на множественные сравнения. W на основных семействах — сохранённые валидированные запуски этапа 3; его время измерено отдельно и не является парным измерением времени новых решателей.

| Сценарий | Режим | n | R | Совместимость | Назначено | Рейсы | Отклонение | Отклонение/назначение | Пасс./рейс | Время, с | Построение, с | Поиск, с | OPT/FEAS/UNKNOWN | Fallback дат |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| stage4_scale_1200 | baseline_greedy | 3/3 | 0.929±0.073 | 0.702±0.125 | 654.333±129.408 | 250.000±38.510 | 6337.000±1506.841 | 9.629±0.647 | 2.605±0.134 | 0.028±0.008 | — | — | 0/0/0 | 0 |
| stage4_scale_1200 | baseline_v2 | 3/3 | 0.929±0.073 | 0.702±0.125 | 690.000±124.708 | 253.000±34.044 | 6520.667±2029.714 | 9.324±1.350 | 2.722±0.229 | 0.025±0.006 | — | — | 0/0/0 | 0 |
| stage4_scale_1200 | greedy_retiming | 3/3 | 0.929±0.073 | 0.702±0.125 | 691.333±127.017 | 253.000±34.044 | 6434.667±2011.671 | 9.181±1.276 | 2.727±0.235 | 0.219±0.144 | — | — | 0/0/0 | 0 |
| stage4_scale_1200 | ilp_cpsat+warm | 3/3 | 0.929±0.073 | 0.702±0.125 | 730.333±144.244 | 255.667±38.214 | 6412.000±2131.314 | 8.632±1.224 | 2.845±0.157 | 1.199±1.004 | 0.270±0.294 | 0.882±0.701 | 3/0/0 | 0 |
| stage4_scale_240 | baseline_greedy | 3/3 | 0.978±0.077 | 0.710±0.125 | 132.333±26.951 | 52.000±8.544 | 1279.000±308.190 | 9.615±0.724 | 2.533±0.119 | 0.002±0.000 | — | — | 0/0/0 | 0 |
| stage4_scale_240 | baseline_v2 | 3/3 | 0.978±0.077 | 0.710±0.125 | 140.000±24.249 | 53.000±7.000 | 1330.667±379.417 | 9.402±1.213 | 2.639±0.228 | 0.003±0.000 | — | — | 0/0/0 | 0 |
| stage4_scale_240 | greedy_retiming | 3/3 | 0.978±0.077 | 0.710±0.125 | 141.000±25.981 | 53.000±7.000 | 1266.667±336.525 | 8.907±0.850 | 2.655±0.247 | 0.022±0.018 | — | — | 0/0/0 | 0 |
| stage4_scale_240 | ilp_cpsat+warm | 3/3 | 0.978±0.077 | 0.710±0.125 | 148.333±27.465 | 53.667±8.021 | 1304.000±386.664 | 8.675±1.047 | 2.756±0.124 | 0.232±0.175 | 0.027±0.010 | 0.199±0.164 | 3/0/0 | 0 |
| stage4_scale_5000 | baseline_greedy | 3/3 | 0.921±0.073 | 0.700±0.125 | 2722.000±534.879 | 1034.667±156.004 | 26355.000±6268.327 | 9.625±0.633 | 2.618±0.139 | 0.405±0.124 | — | — | 0/0/0 | 0 |
| stage4_scale_5000 | baseline_v2 | 3/3 | 0.921±0.073 | 0.700±0.125 | 2867.333±522.793 | 1045.333±141.231 | 27052.000±8576.244 | 9.303±1.376 | 2.738±0.230 | 0.279±0.083 | — | — | 0/0/0 | 0 |
| stage4_scale_5000 | greedy_retiming | 3/3 | 0.921±0.073 | 0.700±0.125 | 2867.333±522.793 | 1045.333±141.231 | 27052.000±8576.244 | 9.303±1.376 | 2.738±0.230 | 0.383±0.107 | — | — | 0/0/0 | 0 |
| stage4_scale_5000 | ilp_cpsat+warm | 3/3 | 0.921±0.073 | 0.700±0.125 | 3033.667±607.694 | 1055.667±157.424 | 26611.667±9054.963 | 8.617±1.260 | 2.861±0.166 | 4.749±3.267 | 0.487±0.109 | 3.737±3.020 | 3/0/0 | 0 |

## Парные исходы

Порядок: выиграл по назначениям / по рейсам при равных назначениях / по отклонению при равных назначениях и рейсах / равен / хуже / нет решения. Wilcoxon — по назначениям.

| Сценарий | Кандидат / эталон | Исходы | Wilcoxon p |
|---|---|---:|---:|
| stage4_scale_1200 | baseline_v2 / baseline_greedy | 2/0/0/0/1/0 | 0.500000 |
| stage4_scale_1200 | greedy_retiming / baseline_greedy | 2/0/0/0/1/0 | 0.500000 |
| stage4_scale_1200 | ilp_cpsat+warm / baseline_greedy | 3/0/0/0/0/0 | 0.250000 |
| stage4_scale_1200 | ilp_cpsat+warm / baseline_v2 | 2/0/1/0/0/0 | 0.500000 |
| stage4_scale_1200 | ilp_cpsat+warm / greedy_retiming | 2/0/1/0/0/0 | 0.500000 |
| stage4_scale_240 | baseline_v2 / baseline_greedy | 2/0/0/0/1/0 | 0.750000 |
| stage4_scale_240 | greedy_retiming / baseline_greedy | 2/0/0/0/1/0 | 0.500000 |
| stage4_scale_240 | ilp_cpsat+warm / baseline_greedy | 3/0/0/0/0/0 | 0.250000 |
| stage4_scale_240 | ilp_cpsat+warm / baseline_v2 | 2/0/1/0/0/0 | 0.500000 |
| stage4_scale_240 | ilp_cpsat+warm / greedy_retiming | 2/0/1/0/0/0 | 0.500000 |
| stage4_scale_5000 | baseline_v2 / baseline_greedy | 2/0/0/0/1/0 | 0.500000 |
| stage4_scale_5000 | greedy_retiming / baseline_greedy | 2/0/0/0/1/0 | 0.500000 |
| stage4_scale_5000 | ilp_cpsat+warm / baseline_greedy | 3/0/0/0/0/0 | 0.250000 |
| stage4_scale_5000 | ilp_cpsat+warm / baseline_v2 | 2/0/1/0/0/0 | 0.500000 |
| stage4_scale_5000 | ilp_cpsat+warm / greedy_retiming | 2/0/1/0/0/0 | 0.500000 |

## Парные разности и 95% CI

Разность = кандидат − эталон. Отрицательные разности рейсов, отклонения и времени означают уменьшение. CI по отдельным метрикам не означает лексикографического выигрыша.

| Сценарий | Кандидат / эталон | Метрика | n | Δ среднее | 95% CI |
|---|---|---|---:|---:|---:|
| stage4_scale_1200 | baseline_v2 / baseline_greedy | assigned_requests | 3 | +35.667 | [-54.000; +101.000] |
| stage4_scale_1200 | baseline_v2 / baseline_greedy | trip_count | 3 | +3.000 | [+0.000; +9.000] |
| stage4_scale_1200 | baseline_v2 / baseline_greedy | total_time_deviation_minutes | 3 | +183.667 | [-973.000; +1294.000] |
| stage4_scale_1200 | baseline_v2 / baseline_greedy | mean_time_deviation_minutes | 3 | -0.305 | [-1.092; +0.855] |
| stage4_scale_1200 | baseline_v2 / baseline_greedy | mean_passengers_per_trip | 3 | +0.117 | [-0.215; +0.359] |
| stage4_scale_1200 | baseline_v2 / baseline_greedy | runtime_seconds | 3 | -0.003 | [-0.006; -0.001] |
| stage4_scale_1200 | greedy_retiming / baseline_greedy | assigned_requests | 3 | +37.000 | [-54.000; +101.000] |
| stage4_scale_1200 | greedy_retiming / baseline_greedy | trip_count | 3 | +3.000 | [+0.000; +9.000] |
| stage4_scale_1200 | greedy_retiming / baseline_greedy | total_time_deviation_minutes | 3 | +97.667 | [-1125.000; +1206.000] |
| stage4_scale_1200 | greedy_retiming / baseline_greedy | mean_time_deviation_minutes | 3 | -0.449 | [-1.121; +0.700] |
| stage4_scale_1200 | greedy_retiming / baseline_greedy | mean_passengers_per_trip | 3 | +0.122 | [-0.215; +0.359] |
| stage4_scale_1200 | greedy_retiming / baseline_greedy | runtime_seconds | 3 | +0.191 | [+0.042; +0.323] |
| stage4_scale_1200 | ilp_cpsat+warm / baseline_greedy | assigned_requests | 3 | +76.000 | [+8.000; +119.000] |
| stage4_scale_1200 | ilp_cpsat+warm / baseline_greedy | trip_count | 3 | +5.667 | [+0.000; +9.000] |
| stage4_scale_1200 | ilp_cpsat+warm / baseline_greedy | total_time_deviation_minutes | 3 | +75.000 | [-920.000; +1240.000] |
| stage4_scale_1200 | ilp_cpsat+warm / baseline_greedy | mean_time_deviation_minutes | 3 | -0.997 | [-1.618; +0.099] |
| stage4_scale_1200 | ilp_cpsat+warm / baseline_greedy | mean_passengers_per_trip | 3 | +0.240 | [+0.032; +0.359] |
| stage4_scale_1200 | ilp_cpsat+warm / baseline_greedy | runtime_seconds | 3 | +1.171 | [+0.440; +2.306] |
| stage4_scale_1200 | ilp_cpsat+warm / baseline_v2 | assigned_requests | 3 | +40.333 | [+0.000; +62.000] |
| stage4_scale_1200 | ilp_cpsat+warm / baseline_v2 | trip_count | 3 | +2.667 | [+0.000; +8.000] |
| stage4_scale_1200 | ilp_cpsat+warm / baseline_v2 | total_time_deviation_minutes | 3 | -108.667 | [-325.000; +53.000] |
| stage4_scale_1200 | ilp_cpsat+warm / baseline_v2 | mean_time_deviation_minutes | 3 | -0.692 | [-0.795; -0.526] |
| stage4_scale_1200 | ilp_cpsat+warm / baseline_v2 | mean_passengers_per_trip | 3 | +0.123 | [+0.000; +0.247] |
| stage4_scale_1200 | ilp_cpsat+warm / baseline_v2 | runtime_seconds | 3 | +1.174 | [+0.444; +2.312] |
| stage4_scale_1200 | ilp_cpsat+warm / greedy_retiming | assigned_requests | 3 | +39.000 | [+0.000; +62.000] |
| stage4_scale_1200 | ilp_cpsat+warm / greedy_retiming | trip_count | 3 | +2.667 | [+0.000; +8.000] |
| stage4_scale_1200 | ilp_cpsat+warm / greedy_retiming | total_time_deviation_minutes | 3 | -22.667 | [-307.000; +205.000] |
| stage4_scale_1200 | ilp_cpsat+warm / greedy_retiming | mean_time_deviation_minutes | 3 | -0.549 | [-0.601; -0.497] |
| stage4_scale_1200 | ilp_cpsat+warm / greedy_retiming | mean_passengers_per_trip | 3 | +0.118 | [+0.000; +0.247] |
| stage4_scale_1200 | ilp_cpsat+warm / greedy_retiming | runtime_seconds | 3 | +0.980 | [+0.398; +2.099] |
| stage4_scale_240 | baseline_v2 / baseline_greedy | assigned_requests | 3 | +7.667 | [-12.000; +23.000] |
| stage4_scale_240 | baseline_v2 / baseline_greedy | trip_count | 3 | +1.000 | [+0.000; +3.000] |
| stage4_scale_240 | baseline_v2 / baseline_greedy | total_time_deviation_minutes | 3 | +51.667 | [-211.000; +274.000] |
| stage4_scale_240 | baseline_v2 / baseline_greedy | mean_time_deviation_minutes | 3 | -0.212 | [-0.907; +0.954] |
| stage4_scale_240 | baseline_v2 / baseline_greedy | mean_passengers_per_trip | 3 | +0.106 | [-0.226; +0.344] |
| stage4_scale_240 | baseline_v2 / baseline_greedy | runtime_seconds | 3 | +0.001 | [+0.001; +0.001] |
| stage4_scale_240 | greedy_retiming / baseline_greedy | assigned_requests | 3 | +8.667 | [-12.000; +23.000] |
| stage4_scale_240 | greedy_retiming / baseline_greedy | trip_count | 3 | +1.000 | [+0.000; +3.000] |
| stage4_scale_240 | greedy_retiming / baseline_greedy | total_time_deviation_minutes | 3 | -12.333 | [-285.000; +168.000] |
| stage4_scale_240 | greedy_retiming / baseline_greedy | mean_time_deviation_minutes | 3 | -0.708 | [-1.272; +0.151] |
| stage4_scale_240 | greedy_retiming / baseline_greedy | mean_passengers_per_trip | 3 | +0.122 | [-0.226; +0.344] |
| stage4_scale_240 | greedy_retiming / baseline_greedy | runtime_seconds | 3 | +0.020 | [+0.005; +0.039] |
| stage4_scale_240 | ilp_cpsat+warm / baseline_greedy | assigned_requests | 3 | +16.000 | [+2.000; +23.000] |
| stage4_scale_240 | ilp_cpsat+warm / baseline_greedy | trip_count | 3 | +1.667 | [+0.000; +3.000] |
| stage4_scale_240 | ilp_cpsat+warm / baseline_greedy | total_time_deviation_minutes | 3 | +25.000 | [-188.000; +238.000] |
| stage4_scale_240 | ilp_cpsat+warm / baseline_greedy | mean_time_deviation_minutes | 3 | -0.939 | [-1.491; +0.112] |
| stage4_scale_240 | ilp_cpsat+warm / baseline_greedy | mean_passengers_per_trip | 3 | +0.223 | [+0.038; +0.344] |
| stage4_scale_240 | ilp_cpsat+warm / baseline_greedy | runtime_seconds | 3 | +0.230 | [+0.094; +0.427] |
| stage4_scale_240 | ilp_cpsat+warm / baseline_v2 | assigned_requests | 3 | +8.333 | [+0.000; +14.000] |
| stage4_scale_240 | ilp_cpsat+warm / baseline_v2 | trip_count | 3 | +0.667 | [+0.000; +2.000] |
| stage4_scale_240 | ilp_cpsat+warm / baseline_v2 | total_time_deviation_minutes | 3 | -26.667 | [-67.000; +23.000] |
| stage4_scale_240 | ilp_cpsat+warm / baseline_v2 | mean_time_deviation_minutes | 3 | -0.727 | [-0.842; -0.532] |
| stage4_scale_240 | ilp_cpsat+warm / baseline_v2 | mean_passengers_per_trip | 3 | +0.117 | [+0.000; +0.264] |
| stage4_scale_240 | ilp_cpsat+warm / baseline_v2 | runtime_seconds | 3 | +0.229 | [+0.093; +0.426] |
| stage4_scale_240 | ilp_cpsat+warm / greedy_retiming | assigned_requests | 3 | +7.333 | [+0.000; +14.000] |
| stage4_scale_240 | ilp_cpsat+warm / greedy_retiming | trip_count | 3 | +0.667 | [+0.000; +2.000] |
| stage4_scale_240 | ilp_cpsat+warm / greedy_retiming | total_time_deviation_minutes | 3 | +37.333 | [-55.000; +97.000] |
| stage4_scale_240 | ilp_cpsat+warm / greedy_retiming | mean_time_deviation_minutes | 3 | -0.232 | [-0.437; -0.039] |
| stage4_scale_240 | ilp_cpsat+warm / greedy_retiming | mean_passengers_per_trip | 3 | +0.100 | [+0.000; +0.264] |
| stage4_scale_240 | ilp_cpsat+warm / greedy_retiming | runtime_seconds | 3 | +0.210 | [+0.089; +0.388] |
| stage4_scale_5000 | baseline_v2 / baseline_greedy | assigned_requests | 3 | +145.333 | [-219.000; +406.000] |
| stage4_scale_5000 | baseline_v2 / baseline_greedy | trip_count | 3 | +10.667 | [+0.000; +31.000] |
| stage4_scale_5000 | baseline_v2 / baseline_greedy | total_time_deviation_minutes | 3 | +697.000 | [-3966.000; +5300.000] |
| stage4_scale_5000 | baseline_v2 / baseline_greedy | mean_time_deviation_minutes | 3 | -0.322 | [-1.122; +0.829] |
| stage4_scale_5000 | baseline_v2 / baseline_greedy | mean_passengers_per_trip | 3 | +0.119 | [-0.211; +0.363] |
| stage4_scale_5000 | baseline_v2 / baseline_greedy | runtime_seconds | 3 | -0.125 | [-0.190; -0.063] |
| stage4_scale_5000 | greedy_retiming / baseline_greedy | assigned_requests | 3 | +145.333 | [-219.000; +406.000] |
| stage4_scale_5000 | greedy_retiming / baseline_greedy | trip_count | 3 | +10.667 | [+0.000; +31.000] |
| stage4_scale_5000 | greedy_retiming / baseline_greedy | total_time_deviation_minutes | 3 | +697.000 | [-3966.000; +5300.000] |
| stage4_scale_5000 | greedy_retiming / baseline_greedy | mean_time_deviation_minutes | 3 | -0.322 | [-1.122; +0.829] |
| stage4_scale_5000 | greedy_retiming / baseline_greedy | mean_passengers_per_trip | 3 | +0.119 | [-0.211; +0.363] |
| stage4_scale_5000 | greedy_retiming / baseline_greedy | runtime_seconds | 3 | -0.021 | [-0.065; +0.045] |
| stage4_scale_5000 | ilp_cpsat+warm / baseline_greedy | assigned_requests | 3 | +311.667 | [+31.000; +498.000] |
| stage4_scale_5000 | ilp_cpsat+warm / baseline_greedy | trip_count | 3 | +21.000 | [+0.000; +32.000] |
| stage4_scale_5000 | ilp_cpsat+warm / baseline_greedy | total_time_deviation_minutes | 3 | +256.667 | [-3808.000; +5172.000] |
| stage4_scale_5000 | ilp_cpsat+warm / baseline_greedy | mean_time_deviation_minutes | 3 | -1.008 | [-1.649; +0.089] |
| stage4_scale_5000 | ilp_cpsat+warm / baseline_greedy | mean_passengers_per_trip | 3 | +0.243 | [+0.030; +0.363] |
| stage4_scale_5000 | ilp_cpsat+warm / baseline_greedy | runtime_seconds | 3 | +4.344 | [+1.891; +7.887] |
| stage4_scale_5000 | ilp_cpsat+warm / baseline_v2 | assigned_requests | 3 | +166.333 | [+0.000; +250.000] |
| stage4_scale_5000 | ilp_cpsat+warm / baseline_v2 | trip_count | 3 | +10.333 | [+0.000; +31.000] |
| stage4_scale_5000 | ilp_cpsat+warm / baseline_v2 | total_time_deviation_minutes | 3 | -440.333 | [-1351.000; +158.000] |
| stage4_scale_5000 | ilp_cpsat+warm / baseline_v2 | mean_time_deviation_minutes | 3 | -0.686 | [-0.790; -0.527] |
| stage4_scale_5000 | ilp_cpsat+warm / baseline_v2 | mean_passengers_per_trip | 3 | +0.124 | [+0.000; +0.241] |
| stage4_scale_5000 | ilp_cpsat+warm / baseline_v2 | runtime_seconds | 3 | +4.469 | [+2.013; +8.077] |
| stage4_scale_5000 | ilp_cpsat+warm / greedy_retiming | assigned_requests | 3 | +166.333 | [+0.000; +250.000] |
| stage4_scale_5000 | ilp_cpsat+warm / greedy_retiming | trip_count | 3 | +10.333 | [+0.000; +31.000] |
| stage4_scale_5000 | ilp_cpsat+warm / greedy_retiming | total_time_deviation_minutes | 3 | -440.333 | [-1351.000; +158.000] |
| stage4_scale_5000 | ilp_cpsat+warm / greedy_retiming | mean_time_deviation_minutes | 3 | -0.686 | [-0.790; -0.527] |
| stage4_scale_5000 | ilp_cpsat+warm / greedy_retiming | mean_passengers_per_trip | 3 | +0.124 | [+0.000; +0.241] |
| stage4_scale_5000 | ilp_cpsat+warm / greedy_retiming | runtime_seconds | 3 | +4.365 | [+1.935; +7.952] |

## Закрытая доля разрыва

Среднее по парам `(эвристика − baseline)/(W − baseline)`; n включает только ненулевой знаменатель. Для рейсов и среднего отклонения на назначение дополнительно требуется одинаковое число назначений у всех трёх алгоритмов. Значения не ограничены диапазоном 0–1; отрицательные значения и значения больше 1 сохранены. pooled — отношение сумм разностей на тех же парах.

| Сценарий | Эвристика | Метрика | n | Средняя доля | pooled |
|---|---|---|---:|---:|---:|
| stage4_scale_1200 | baseline_v2 | assigned_requests | 3 | -174.86% | 46.93% |
| stage4_scale_1200 | baseline_v2 | trip_count | 0 | н/д | н/д |
| stage4_scale_1200 | baseline_v2 | mean_time_deviation_minutes | 0 | н/д | н/д |
| stage4_scale_1200 | greedy_retiming | assigned_requests | 3 | -173.74% | 48.68% |
| stage4_scale_1200 | greedy_retiming | trip_count | 0 | н/д | н/д |
| stage4_scale_1200 | greedy_retiming | mean_time_deviation_minutes | 0 | н/д | н/д |
| stage4_scale_240 | baseline_v2 | assigned_requests | 3 | -149.28% | 47.92% |
| stage4_scale_240 | baseline_v2 | trip_count | 0 | н/д | н/д |
| stage4_scale_240 | baseline_v2 | mean_time_deviation_minutes | 0 | н/д | н/д |
| stage4_scale_240 | greedy_retiming | assigned_requests | 3 | -144.93% | 54.17% |
| stage4_scale_240 | greedy_retiming | trip_count | 0 | н/д | н/д |
| stage4_scale_240 | greedy_retiming | mean_time_deviation_minutes | 0 | н/д | н/д |
| stage4_scale_5000 | baseline_v2 | assigned_requests | 3 | -185.48% | 46.63% |
| stage4_scale_5000 | baseline_v2 | trip_count | 0 | н/д | н/д |
| stage4_scale_5000 | baseline_v2 | mean_time_deviation_minutes | 0 | н/д | н/д |
| stage4_scale_5000 | greedy_retiming | assigned_requests | 3 | -185.48% | 46.63% |
| stage4_scale_5000 | greedy_retiming | trip_count | 0 | н/д | н/д |
| stage4_scale_5000 | greedy_retiming | mean_time_deviation_minutes | 0 | н/д | н/д |

Каждый масштаб воспроизводит еженедельную структуру stage3_medium_many вдоль горизонта; последняя дата может быть неполной. R и спрос каждой даты/коридора сохранены в сырых JSONL; сравнение с полными исходными неделями ограничено этой последней датой.
