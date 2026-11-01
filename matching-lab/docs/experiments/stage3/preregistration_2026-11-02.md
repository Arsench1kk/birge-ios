# Этап 3: предварительная регистрация — 2026-11-02

До любого профилирования или сравнительного запуска: все параметры PLACEHOLDER, источник — явные синтетические допущения из `docs/stand_design.md`; выбор основного алгоритма и постановки не утверждён. ADR-006 Proposed. Гипотезы: более разнообразные расписания и многокоридорные конфликты могут создать запас над baseline; если запаса нет, это фиксируется как результат. Высокий R может не давать полной совместимости окон. Различия не подбираются по наблюдаемому результату.

Профилирование: существующие scale-конфиги, seed 1, сбор до входа в CP-SAT Solve; cProfile и метрика времени построения; сравнительные запуски строго последовательно. Эксперименты и бюджеты определены в manifest. SHA-256 ниже — хешы байтов файлов.

| Файл | SHA-256 |
|---|---|
| `configs/stage3/stage3_high_few.yaml` | `4b177d866ea1971e63a905b0aebf003b86272f46769230cfa4eff1f5e13b15d5` |
| `configs/stage3/stage3_high_many.yaml` | `bec5b52cff2336f402f8e97a0d17adec3ca61471a462aac34eeef7b9036dcc69` |
| `configs/stage3/stage3_low_few.yaml` | `9e8ee3cbf92286fd58f09a0d389421841633f5f50923a8c3b0bfa7869be3b76c` |
| `configs/stage3/stage3_low_many.yaml` | `fd43c9d7b33b1d4f9593bf31bb41cd199509dc4aae25dad8f89dd58f05444081` |
| `configs/stage3/stage3_medium_few.yaml` | `7c79952442d70da70fce2f18bee75074c4b5c38a29c6b366d390dbe58ac24e9d` |
| `configs/stage3/stage3_medium_many.yaml` | `8730a8aaf09d921f7638ca8182ab6c5d2bb6f3208ffb0b06a9353af7d24dd4c8` |
| `configs/experiments/stage3.json` | `503bb8126ade2e563362a5ec6d97126be7904327a082249c432b2247855bcb16` |
| `configs/scale/scale_hundreds.yaml` | `ca1b0e78633546b8c992cb26559db53bddcd06de418bb5b4d20988e666591b8a` |
| `configs/scale/scale_thousands.yaml` | `51288bd9a40f4bb0da17a762614755c2350e186efca68ebc2a537e2e47c7e220` |
| `configs/stage25/scale_5000.yaml` | `8936bf255c88bd183c3e39658e5ef1f3dfd3abb0ed0cb118dfc29ec43f277916` |
| `configs/stage3/stage3_control.yaml` | `dc2935bf5f078c12ae0225e77a008301ce30e2af434f42a59a71c1d0647a01b2` |
