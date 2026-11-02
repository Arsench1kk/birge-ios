# Этап 5: предварительная регистрация — 2026-11-02

Все параметры синтетические PLACEHOLDER. ADR-006 Accepted; выбор решателя открыт. Протокол до новых экспериментальных запусков.

Гипотезы: (1) высокий дефицит может приводить к проигрышу порядка обработки baseline_v2 исходному baseline; (2) hint от лучшей из двух эвристик исключает ухудшение warm2 относительно них, но не гарантирует OPTIMAL; (3) доля OPTIMAL может уменьшаться при росте числа заявок в одну дату. Все исходы публикуются; связи признаков и выигрыша описательные.

Dev seed 1000–1009; оценочные seed 1–20; масштаб 1–3; без перенастройки после оценки. На семи семействах использовать сохранённые W и эвристики этапа 4, запускать только warm2. Эвристики повторно вычисляются только внутри warm2 как необходимая стартовая точка. Диагностика различий рейсов — dev seed; оценочные эвристики отдельно не пересчитываются.

Масштаб: одна дата, medium_few / medium_many, 50/100/200/400/800 заявок; водители пропорциональны числу пассажиров (округление Python round), остальные допущения stage3 сохранены. Спрос полностью размещён на понедельник; фактический R записывается. Три seed. Условия запуска: 10 с на дату, сетка 10 мин, один поток; сборка сверх поискового бюджета; запуск последовательно. Предел: наименьший размер с долей OPTIMAL < 80% среди трёх seed, отдельно для семейства и режима; это наблюдаемый порог при указанном бюджете, не общий предел.

Парный bootstrap: 2000 повторений, seed 451, percentile 95%; Spearman: ранги со средними при связках, bootstrap по независимым экземплярам; константный признак или отсутствие вариации — н/д. Испытания синтетические; зависимости не причинные.

| Файл | SHA-256 |
|---|---|
| `configs/stage5/few_100.yaml` | `ef1e12cb7bf96b5e69bdf03fbaa7b4fa5964678dc72643c7391bbe2903c0a64e` |
| `configs/stage5/few_200.yaml` | `cc5a965857a387ba80f29ec1cff8fc2c8f08d2289eefe090b79f4ee8097b5c92` |
| `configs/stage5/few_400.yaml` | `ea66424e4f249015ff4cbcba8959889c6f3eb5c5e8cd339bc3ad20b996fc006f` |
| `configs/stage5/few_50.yaml` | `8efe9784ffb5d7e231c855c31ed23fc54eaf6cd149656b9d4e8032bfa1c4d772` |
| `configs/stage5/few_800.yaml` | `eec05fee92c41e948b50f8e5d962487faed77431a495e32c97edcc5a6fa92833` |
| `configs/stage5/many_100.yaml` | `27b71c699352f8c2626ecd9bfa0e9ef4e2f215c0fceeb7a9797475e00cc4e10d` |
| `configs/stage5/many_200.yaml` | `b108fbf9b0d469f3af120a96f436764a0778b31b51dbac4f89cd566e5f4e9f36` |
| `configs/stage5/many_400.yaml` | `aa8490973f47a1a3b921283bfd7b6f4ee3f9a88b91f380f14f987f4cbe0a05c7` |
| `configs/stage5/many_50.yaml` | `d76868f322eb2ed28e4199170caeacfeec561d284142ed79d1384bc2aaedf49a` |
| `configs/stage5/many_800.yaml` | `41b864028ab054b8bc05c00d798ae7e28acb6d9fdd4ee8b8a161d8d638c696ac` |
| `configs/stage5/protocol.json` | `06a9db5dd84e1501d2ecbb95852973906284acfa7f9cdab518fd2887fac9ea7c` |
| `configs/stage3/stage3_control.yaml` | `dc2935bf5f078c12ae0225e77a008301ce30e2af434f42a59a71c1d0647a01b2` |
| `configs/stage3/stage3_high_few.yaml` | `4b177d866ea1971e63a905b0aebf003b86272f46769230cfa4eff1f5e13b15d5` |
| `configs/stage3/stage3_high_many.yaml` | `bec5b52cff2336f402f8e97a0d17adec3ca61471a462aac34eeef7b9036dcc69` |
| `configs/stage3/stage3_low_few.yaml` | `9e8ee3cbf92286fd58f09a0d389421841633f5f50923a8c3b0bfa7869be3b76c` |
| `configs/stage3/stage3_low_many.yaml` | `fd43c9d7b33b1d4f9593bf31bb41cd199509dc4aae25dad8f89dd58f05444081` |
| `configs/stage3/stage3_medium_few.yaml` | `7c79952442d70da70fce2f18bee75074c4b5c38a29c6b366d390dbe58ac24e9d` |
| `configs/stage3/stage3_medium_many.yaml` | `8730a8aaf09d921f7638ca8182ab6c5d2bb6f3208ffb0b06a9353af7d24dd4c8` |
| `configs/experiments/stage3.json` | `503bb8126ade2e563362a5ec6d97126be7904327a082249c432b2247855bcb16` |
