# Пост-обработка этапа 3

Без новых запусков решателей; параметры bootstrap и Wilcoxon предварительно заданы в `preregistration.md`. Конфигурации восстановлены по seed и проверены по сохранённому config SHA. Совместимость: есть водитель соответствующего коридора с доступным на данную дату слотом, в котором можно завершить рейс длительности сценария и отправиться внутри окна заявки; вместимость и другие заявки не учитываются. Среднее отклонение — среднее по индивидуальным назначениям в каждом запуске, затем среднее ± выборочное СО этих значений по seed. Synthetic, PLACEHOLDER.

| Семейство | Режим | n | Совместимые заявки, доля | Отклонение/назначение, мин | Полное время, с |
|---|---|---:|---:|---:|---:|
| stage3_control | baseline_greedy | 20 | 1.000±0.000 | 4.845±0.650 | 0.021 |
| stage3_control | ilp_cpsat+decomposed | 20 | 1.000±0.000 | 3.789±0.534 | 50.212 |
| stage3_control | ilp_cpsat+warm | 20 | 1.000±0.000 | 4.239±0.557 | 50.402 |
| stage3_high_few | baseline_greedy | 20 | 0.589±0.128 | 8.475±2.099 | 0.001 |
| stage3_high_few | ilp_cpsat+decomposed | 20 | 0.589±0.128 | 7.989±2.910 | 0.286 |
| stage3_high_few | ilp_cpsat+warm | 20 | 0.589±0.128 | 8.399±2.163 | 0.249 |
| stage3_high_many | baseline_greedy | 20 | 0.650±0.088 | 9.340±2.164 | 0.001 |
| stage3_high_many | ilp_cpsat+decomposed | 20 | 0.650±0.088 | 7.320±1.560 | 0.073 |
| stage3_high_many | ilp_cpsat+warm | 20 | 0.650±0.088 | 7.197±1.553 | 0.079 |
| stage3_low_few | baseline_greedy | 20 | 0.675±0.111 | 7.782±1.675 | 0.003 |
| stage3_low_few | ilp_cpsat+decomposed | 20 | 0.675±0.111 | 8.231±1.561 | 8.499 |
| stage3_low_few | ilp_cpsat+warm | 20 | 0.675±0.111 | 8.185±1.536 | 8.262 |
| stage3_low_many | baseline_greedy | 20 | 0.785±0.118 | 7.820±1.344 | 0.002 |
| stage3_low_many | ilp_cpsat+decomposed | 20 | 0.785±0.118 | 7.715±1.183 | 2.538 |
| stage3_low_many | ilp_cpsat+warm | 20 | 0.785±0.118 | 7.593±1.220 | 3.535 |
| stage3_medium_few | baseline_greedy | 20 | 0.621±0.116 | 7.751±1.935 | 0.002 |
| stage3_medium_few | ilp_cpsat+decomposed | 20 | 0.621±0.116 | 8.467±2.078 | 3.372 |
| stage3_medium_few | ilp_cpsat+warm | 20 | 0.621±0.116 | 8.577±1.825 | 2.635 |
| stage3_medium_many | baseline_greedy | 20 | 0.706±0.097 | 7.922±1.659 | 0.001 |
| stage3_medium_many | ilp_cpsat+decomposed | 20 | 0.706±0.097 | 7.706±1.182 | 0.209 |
| stage3_medium_many | ilp_cpsat+warm | 20 | 0.706±0.097 | 7.543±1.329 | 0.151 |

Время построения и поиска baseline отдельно **не записано** в исходных результатах; восстановить его постфактум без нового измерения нельзя. Для baseline в исходных данных есть только полное время.

## Парные исходы и Wilcoxon

Порядок: больше назначений / меньше рейсов при равных назначениях / меньше суммарного отклонения при равных назначениях и рейсах / равно / хуже / нет решения. Точный двусторонний критерий знаковых рангов для разностей по назначениям; p-values описательные, поправка на множественные сравнения не применяется.

| Семейство | Режим | Исходы | Wilcoxon p |
|---|---|---:|---:|
| stage3_control | ilp_cpsat+decomposed | 3 / 0 / 0 / 0 / 17 / 0 | 1.000000 |
| stage3_control | ilp_cpsat+warm | 4 / 16 / 0 / 0 / 0 / 0 | 0.125000 |
| stage3_high_few | ilp_cpsat+decomposed | 15 / 1 / 0 / 0 / 4 / 0 | 0.002289 |
| stage3_high_few | ilp_cpsat+warm | 20 / 0 / 0 / 0 / 0 / 0 | 0.000002 |
| stage3_high_many | ilp_cpsat+decomposed | 19 / 0 / 1 / 0 / 0 / 0 | 0.000004 |
| stage3_high_many | ilp_cpsat+warm | 19 / 0 / 1 / 0 / 0 / 0 | 0.000004 |
| stage3_low_few | ilp_cpsat+decomposed | 20 / 0 / 0 / 0 / 0 / 0 | 0.000002 |
| stage3_low_few | ilp_cpsat+warm | 20 / 0 / 0 / 0 / 0 / 0 | 0.000002 |
| stage3_low_many | ilp_cpsat+decomposed | 20 / 0 / 0 / 0 / 0 / 0 | 0.000002 |
| stage3_low_many | ilp_cpsat+warm | 20 / 0 / 0 / 0 / 0 / 0 | 0.000002 |
| stage3_medium_few | ilp_cpsat+decomposed | 17 / 1 / 0 / 0 / 2 / 0 | 0.000072 |
| stage3_medium_few | ilp_cpsat+warm | 20 / 0 / 0 / 0 / 0 / 0 | 0.000002 |
| stage3_medium_many | ilp_cpsat+decomposed | 19 / 0 / 1 / 0 / 0 / 0 | 0.000004 |
| stage3_medium_many | ilp_cpsat+warm | 19 / 0 / 1 / 0 / 0 / 0 | 0.000004 |

## Парные разности и bootstrap 95%

Разность = решатель − baseline; при меньшем времени/числе рейсов/отклонении отрицательное значение означает уменьшение. CI — percentile bootstrap по одним и тем же seed, 2000 повторов; это не корректировка множественной проверки. Полные численные таблицы: `post_stage3_summary.csv`, `post_stage3_pairs.csv`, `post_stage3_ci.csv`.

| Семейство | Режим | Метрика | n | Δ среднее | 95% CI |
|---|---|---|---:|---:|---:|
| stage3_control | ilp_cpsat+decomposed | assigned_requests | 20 | -0.050 | [-0.400; 0.200] |
| stage3_control | ilp_cpsat+decomposed | trip_count | 20 | 6.050 | [4.250; 8.050] |
| stage3_control | ilp_cpsat+decomposed | total_time_deviation_minutes | 20 | -168.750 | [-214.901; -120.049] |
| stage3_control | ilp_cpsat+decomposed | mean_time_deviation_minutes | 20 | -1.056 | [-1.342; -0.756] |
| stage3_control | ilp_cpsat+decomposed | mean_passengers_per_trip | 20 | -0.133 | [-0.178; -0.093] |
| stage3_control | ilp_cpsat+decomposed | runtime_seconds | 20 | 50.191 | [50.174; 50.211] |
| stage3_control | ilp_cpsat+warm | assigned_requests | 20 | 0.250 | [0.050; 0.500] |
| stage3_control | ilp_cpsat+warm | trip_count | 20 | -3.300 | [-4.300; -2.250] |
| stage3_control | ilp_cpsat+warm | total_time_deviation_minutes | 20 | -95.600 | [-129.004; -62.099] |
| stage3_control | ilp_cpsat+warm | mean_time_deviation_minutes | 20 | -0.606 | [-0.822; -0.400] |
| stage3_control | ilp_cpsat+warm | mean_passengers_per_trip | 20 | 0.086 | [0.060; 0.110] |
| stage3_control | ilp_cpsat+warm | runtime_seconds | 20 | 50.380 | [50.272; 50.546] |
| stage3_high_few | ilp_cpsat+decomposed | assigned_requests | 20 | 10.600 | [5.149; 15.950] |
| stage3_high_few | ilp_cpsat+decomposed | trip_count | 20 | 1.800 | [-0.100; 3.750] |
| stage3_high_few | ilp_cpsat+decomposed | total_time_deviation_minutes | 20 | 76.850 | [-5.755; 152.901] |
| stage3_high_few | ilp_cpsat+decomposed | mean_time_deviation_minutes | 20 | -0.486 | [-1.635; 0.590] |
| stage3_high_few | ilp_cpsat+decomposed | mean_passengers_per_trip | 20 | 0.354 | [0.248; 0.464] |
| stage3_high_few | ilp_cpsat+decomposed | runtime_seconds | 20 | 0.285 | [0.180; 0.399] |
| stage3_high_few | ilp_cpsat+warm | assigned_requests | 20 | 13.350 | [9.550; 17.500] |
| stage3_high_few | ilp_cpsat+warm | trip_count | 20 | 3.000 | [1.700; 4.350] |
| stage3_high_few | ilp_cpsat+warm | total_time_deviation_minutes | 20 | 105.450 | [47.786; 164.301] |
| stage3_high_few | ilp_cpsat+warm | mean_time_deviation_minutes | 20 | -0.075 | [-0.830; 0.701] |
| stage3_high_few | ilp_cpsat+warm | mean_passengers_per_trip | 20 | 0.285 | [0.203; 0.373] |
| stage3_high_few | ilp_cpsat+warm | runtime_seconds | 20 | 0.247 | [0.162; 0.355] |
| stage3_high_many | ilp_cpsat+decomposed | assigned_requests | 20 | 6.300 | [4.300; 8.551] |
| stage3_high_many | ilp_cpsat+decomposed | trip_count | 20 | 0.100 | [0.000; 0.250] |
| stage3_high_many | ilp_cpsat+decomposed | total_time_deviation_minutes | 20 | -64.850 | [-110.701; -18.541] |
| stage3_high_many | ilp_cpsat+decomposed | mean_time_deviation_minutes | 20 | -2.020 | [-2.647; -1.379] |
| stage3_high_many | ilp_cpsat+decomposed | mean_passengers_per_trip | 20 | 0.305 | [0.201; 0.422] |
| stage3_high_many | ilp_cpsat+decomposed | runtime_seconds | 20 | 0.072 | [0.056; 0.087] |
| stage3_high_many | ilp_cpsat+warm | assigned_requests | 20 | 6.300 | [4.400; 8.550] |
| stage3_high_many | ilp_cpsat+warm | trip_count | 20 | 0.100 | [0.000; 0.250] |
| stage3_high_many | ilp_cpsat+warm | total_time_deviation_minutes | 20 | -71.500 | [-117.109; -24.849] |
| stage3_high_many | ilp_cpsat+warm | mean_time_deviation_minutes | 20 | -2.143 | [-2.774; -1.485] |
| stage3_high_many | ilp_cpsat+warm | mean_passengers_per_trip | 20 | 0.305 | [0.205; 0.423] |
| stage3_high_many | ilp_cpsat+warm | runtime_seconds | 20 | 0.078 | [0.063; 0.093] |
| stage3_low_few | ilp_cpsat+decomposed | assigned_requests | 20 | 21.900 | [17.650; 26.200] |
| stage3_low_few | ilp_cpsat+decomposed | trip_count | 20 | 2.850 | [0.850; 4.900] |
| stage3_low_few | ilp_cpsat+decomposed | total_time_deviation_minutes | 20 | 207.200 | [135.446; 275.252] |
| stage3_low_few | ilp_cpsat+decomposed | mean_time_deviation_minutes | 20 | 0.448 | [-0.099; 0.981] |
| stage3_low_few | ilp_cpsat+decomposed | mean_passengers_per_trip | 20 | 0.408 | [0.334; 0.492] |
| stage3_low_few | ilp_cpsat+decomposed | runtime_seconds | 20 | 8.496 | [5.067; 12.578] |
| stage3_low_few | ilp_cpsat+warm | assigned_requests | 20 | 22.250 | [18.399; 26.551] |
| stage3_low_few | ilp_cpsat+warm | trip_count | 20 | 3.050 | [1.149; 5.000] |
| stage3_low_few | ilp_cpsat+warm | total_time_deviation_minutes | 20 | 205.700 | [138.136; 273.806] |
| stage3_low_few | ilp_cpsat+warm | mean_time_deviation_minutes | 20 | 0.402 | [-0.165; 0.973] |
| stage3_low_few | ilp_cpsat+warm | mean_passengers_per_trip | 20 | 0.403 | [0.328; 0.489] |
| stage3_low_few | ilp_cpsat+warm | runtime_seconds | 20 | 8.259 | [4.890; 12.177] |
| stage3_low_many | ilp_cpsat+decomposed | assigned_requests | 20 | 15.700 | [13.250; 18.000] |
| stage3_low_many | ilp_cpsat+decomposed | trip_count | 20 | 0.350 | [-1.150; 1.801] |
| stage3_low_many | ilp_cpsat+decomposed | total_time_deviation_minutes | 20 | 109.900 | [66.643; 156.454] |
| stage3_low_many | ilp_cpsat+decomposed | mean_time_deviation_minutes | 20 | -0.105 | [-0.378; 0.226] |
| stage3_low_many | ilp_cpsat+decomposed | mean_passengers_per_trip | 20 | 0.328 | [0.241; 0.420] |
| stage3_low_many | ilp_cpsat+decomposed | runtime_seconds | 20 | 2.536 | [1.389; 3.835] |
| stage3_low_many | ilp_cpsat+warm | assigned_requests | 20 | 15.700 | [13.299; 17.950] |
| stage3_low_many | ilp_cpsat+warm | trip_count | 20 | 0.350 | [-1.150; 1.850] |
| stage3_low_many | ilp_cpsat+warm | total_time_deviation_minutes | 20 | 95.600 | [48.200; 149.201] |
| stage3_low_many | ilp_cpsat+warm | mean_time_deviation_minutes | 20 | -0.227 | [-0.514; 0.100] |
| stage3_low_many | ilp_cpsat+warm | mean_passengers_per_trip | 20 | 0.328 | [0.244; 0.425] |
| stage3_low_many | ilp_cpsat+warm | runtime_seconds | 20 | 3.533 | [1.970; 5.379] |
| stage3_medium_few | ilp_cpsat+decomposed | assigned_requests | 20 | 17.300 | [11.498; 22.651] |
| stage3_medium_few | ilp_cpsat+decomposed | trip_count | 20 | 3.450 | [1.200; 5.550] |
| stage3_medium_few | ilp_cpsat+decomposed | total_time_deviation_minutes | 20 | 187.350 | [94.389; 262.011] |
| stage3_medium_few | ilp_cpsat+decomposed | mean_time_deviation_minutes | 20 | 0.716 | [-0.086; 1.462] |
| stage3_medium_few | ilp_cpsat+decomposed | mean_passengers_per_trip | 20 | 0.311 | [0.205; 0.423] |
| stage3_medium_few | ilp_cpsat+decomposed | runtime_seconds | 20 | 3.371 | [0.991; 6.741] |
| stage3_medium_few | ilp_cpsat+warm | assigned_requests | 20 | 19.350 | [15.200; 23.550] |
| stage3_medium_few | ilp_cpsat+warm | trip_count | 20 | 4.250 | [2.500; 5.950] |
| stage3_medium_few | ilp_cpsat+warm | total_time_deviation_minutes | 20 | 208.300 | [145.850; 266.901] |
| stage3_medium_few | ilp_cpsat+warm | mean_time_deviation_minutes | 20 | 0.826 | [0.204; 1.493] |
| stage3_medium_few | ilp_cpsat+warm | mean_passengers_per_trip | 20 | 0.301 | [0.197; 0.410] |
| stage3_medium_few | ilp_cpsat+warm | runtime_seconds | 20 | 2.633 | [0.822; 5.490] |
| stage3_medium_many | ilp_cpsat+decomposed | assigned_requests | 20 | 11.400 | [8.150; 15.200] |
| stage3_medium_many | ilp_cpsat+decomposed | trip_count | 20 | 0.850 | [0.050; 1.800] |
| stage3_medium_many | ilp_cpsat+decomposed | total_time_deviation_minutes | 20 | 73.050 | [24.647; 118.851] |
| stage3_medium_many | ilp_cpsat+decomposed | mean_time_deviation_minutes | 20 | -0.215 | [-0.582; 0.159] |
| stage3_medium_many | ilp_cpsat+decomposed | mean_passengers_per_trip | 20 | 0.280 | [0.209; 0.352] |
| stage3_medium_many | ilp_cpsat+decomposed | runtime_seconds | 20 | 0.208 | [0.090; 0.383] |
| stage3_medium_many | ilp_cpsat+warm | assigned_requests | 20 | 11.400 | [8.199; 15.050] |
| stage3_medium_many | ilp_cpsat+warm | trip_count | 20 | 0.850 | [0.000; 1.850] |
| stage3_medium_many | ilp_cpsat+warm | total_time_deviation_minutes | 20 | 58.450 | [6.094; 107.105] |
| stage3_medium_many | ilp_cpsat+warm | mean_time_deviation_minutes | 20 | -0.379 | [-0.775; 0.019] |
| stage3_medium_many | ilp_cpsat+warm | mean_passengers_per_trip | 20 | 0.280 | [0.209; 0.355] |
| stage3_medium_many | ilp_cpsat+warm | runtime_seconds | 20 | 0.150 | [0.107; 0.208] |
