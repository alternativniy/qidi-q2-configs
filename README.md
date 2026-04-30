# QIDI Q2 — Кастомные конфиги

Авторы: [@Volvik88](https://t.me/Volvik88), [@MatchenyaSA](https://t.me/MatchenyaSA), [@alternativ_niy](https://t.me/alternativ_niy)

## Оборудование

| Компонент | Описание                                           |
| --------- | -------------------------------------------------- |
| Принтер   | QIDI Q2 (CoreXY, Klipper, директ экструдер)        |
| Бокс      | QIDI Box (до 4 штук, 4 слота каждый: slot0–slot15) |
| Слайсер   | OrcaSlicer 2.3.2                                   |
| Интерфейс | Fluidd + Moonraker                                 |

---

---

## Система проверки филаментов (QIDI Box)

### Как работает

При старте печати макрос `CHECK_FILAMENT_MAP` сравнивает типы филаментов из слайсера с тем, что физически загружено в слоты Box. При несоответствии — печать отменяется.

Проверяются **только слоты, задействованные в текущей печати** (мягкая проверка).

### Переменные состояния (variables.cfg)

```ini
enable_box = 1          # 1 = Box активен
box_count = 1           # Количество боксов (1–4)

slot0 = 1               # Состояние слота: 0=пустой, 1=катушка, 2=загружен
filament_slot0 = 41     # Код филамента из officiall_filas_list.cfg (0 = generic)
value_t0 = 'slot0'      # Маппинг экструдера → физический слот

filament_slot16 = 41    # Код филамента ВНЕШНЕЙ катушки (всегда slot16)
filament_type_map = '1:PLA,2:PLA,...,41:PETG'  # Генерируется автоматически
```

### Карта слотов

| Конфигурация | Слоты Box                   | Внешняя катушка (OrcaSlicer индекс) |
| ------------ | --------------------------- | ----------------------------------- |
| 1 бокс       | slot0–slot3 (индексы 0–3)   | индекс 4                            |
| 2 бокса      | slot0–slot7 (индексы 0–7)   | индекс 8                            |
| 4 бокса      | slot0–slot15 (индексы 0–15) | индекс 16                           |

Внешняя катушка **всегда** хранит код в `filament_slot16`.

---

## Настройка OrcaSlicer

### Start G-code

```gcode
; Инициализация печати с параметрами из слайсера
PRINT_START BED=[bed_temperature_initial_layer_single] HOTEND=[nozzle_temperature_initial_layer] CHAMBER=[chamber_temperature] EXTRUDER=[initial_no_support_extruder] FMAP={filament_type[0]}:{is_extruder_used[0]}|{filament_type[1]}:{is_extruder_used[1]}|{filament_type[2]}:{is_extruder_used[2]}|{filament_type[3]}:{is_extruder_used[3]}|{filament_type[4]}:{is_extruder_used[4]}|{filament_type[5]}:{is_extruder_used[5]}|{filament_type[6]}:{is_extruder_used[6]}|{filament_type[7]}:{is_extruder_used[7]}|{filament_type[8]}:{is_extruder_used[8]}|{filament_type[9]}:{is_extruder_used[9]}|{filament_type[10]}:{is_extruder_used[10]}|{filament_type[11]}:{is_extruder_used[11]}|{filament_type[12]}:{is_extruder_used[12]}|{filament_type[13]}:{is_extruder_used[13]}|{filament_type[14]}:{is_extruder_used[14]}|{filament_type[15]}:{is_extruder_used[15]}|{filament_type[16]}:{is_extruder_used[16]}
; Установка информации о количестве слоев для статистики
SET_PRINT_STATS_INFO TOTAL_LAYER=[total_layer_count]
; Переключение экструдера в относительный режим экструзии
M83
; Установка целевой температуры стола
M140 S[bed_temperature_initial_layer_single]
; Установка целевой температуры сопла
M104 S[nozzle_temperature_initial_layer]
; Установка целевой температуры камеры
M141 S[chamber_temperature]
; Выбор начального инструмента (экструдера)
T[initial_tool]
; Абсолютные координаты
G90
; Перемещение на стартовую точку
G1 X148 Y0 F10000
; Опускание на высоту продувки 0.2 мм
G0 Z0.2 F600
; Продувка - линия длиной 30 мм за 4 секунды
G1 X178 E15 F300
; Плавное завершение без экструзии для стабилизации давления
G1 X183 F1200
; Ожидание завершения движений
M400
```

**Почему такой формат:**

- `[filament_type]` содержит `;` как разделитель → Klipper обрезает строку на первом `;`
- Решение: использовать `{filament_type[N]}` для каждого слота с `|` как разделителем
- `{is_extruder_used[N]}` — OrcaSlicer выдаёт `true`/`false` для каждого экструдера
- Оба значения объединены в один параметр: `тип:used` через `|`

### Формат параметра FMAP

```
PETG:true|PETG:false|PLA:false|ABS:false|PETG:false|...
```

Индексы за пределами `box_count * 4` пропускаются. OrcaSlicer заполняет их первым типом филамента как заглушкой — это нормально.

---

## Макросы

### `CHECK_FILAMENT_MAP FMAP="..."`

Проверяет соответствие типов. Вызывается из `PRINT_START` автоматически.

- Пропускает слоты с `is_used=false`
- Пропускает слоты с `filament_slot{N}=0` (generic/без кода)
- При несоответствии → `CANCEL_PRINT`
- Внешняя катушка → проверяется против `filament_slot16`

### `CHECK_SLOTS_INTEGRITY`

Проверяет форвардинг слотов (`value_t0`–`value_t15`). При сломанном форвардинге — восстанавливает.

### `GENERATE_FILAMENT_MAP`

Запускает `generate_filament_map.sh`, который парсит `officiall_filas_list.cfg` и сохраняет `filament_type_map` в переменные. Вызывается автоматически при каждом старте принтера.

---

## Отладка из консоли Fluidd

```gcode
; Тест проверки (все слоты совпадают)
CHECK_FILAMENT_MAP FMAP="PETG:true|PLA:false|ABS:false|PETG:false"

; Тест несоответствия (slot0 имеет PETG, запрашивается PLA)
CHECK_FILAMENT_MAP FMAP="PLA:true|PLA:false|ABS:false|PETG:false"

; Пересгенерировать карту филаментов вручную
GENERATE_FILAMENT_MAP

; Проверить карту
{ printer.save_variables.variables.filament_type_map }

; Проверить маппинг слотов
{ printer.save_variables.variables.value_t0 }
{ printer.save_variables.variables.filament_slot0 }
{ printer.save_variables.variables.filament_slot16 }
```
