# Dark Factory — подготовка к хакатону

**WeAreDevelopers x BAND: AI Dark Factory** · онлайн · 26 сент – 5 окт 2026 · $6,000 (2 трека: 🥇$1,500 · 🥈$1,000 · 🥉$500 в каждом)
Kickoff: **сб, 26 сентября, 09:00 PDT** (= 16:00 UTC). В этот момент выкладывают оба пакета задач, 4 спецификации, 4 тест-сьюта и харнесс.

Суть: за неделю собрать в **BAND Desktop** «фабрику» — команду агентов, которая сама планирует работу, пишет код и проверяет результат.
Оценка **автоматическая и буквальная**: точные имена полей, статус-коды, ID из тестов. Побеждает тот, чья фабрика не пропускает ничего, что не соответствует спеке.

## ✅ Чек-лист до kickoff (сегодня)

- [ ] Активировать кредиты Featherless ($25) промокодом **`WEAREDEVS26`** (лимит 1000 активаций — не тянуть)
- [ ] ⚠️ При регистрации нужна карта → **поставить напоминание отменить подписку** до следующего списания, если не планируешь пользоваться дальше
- [ ] Получить API-ключ Featherless → `cp .env.example .env` → вписать ключ → `python3 scripts/featherless_smoke.py` (см. ниже)
- [ ] Создать бесплатный аккаунт BAND и скачать **BAND Desktop** (карта не нужна)
- [ ] Вступить в Discord BAND и Discord lablab.ai
- [ ] Команда: 1–6 человек или соло — зарегистрировать на lablab.ai
- [ ] Перечитать правила мандатов: **только generic-мандаты** — самый быстрый способ дисквалификации (см. [`roles/README.md`](roles/README.md))
- [ ] Посмотреть видео Featherless (Hermes, Open WebUI, OpenClaw) — ~10 минут
- [ ] Прогнать [`PLAYBOOK.md`](PLAYBOOK.md) — план первых часов после kickoff

## Featherless API

OpenAI-совместимый API, 30k+ open-weight моделей (DeepSeek, Qwen, Llama, Mistral, Kimi…), контекст до 256K.

```
base_url = https://api.featherless.ai/v1
api_key  = $FEATHERLESS_API_KEY
```

Проверка ключа и выбор моделей (только стандартная библиотека Python, без зависимостей):

```bash
cp .env.example .env            # вписать FEATHERLESS_API_KEY
python3 scripts/featherless_smoke.py                 # пинг модели по умолчанию
python3 scripts/featherless_smoke.py --list qwen     # поиск моделей по подстроке
python3 scripts/featherless_smoke.py --model deepseek-ai/DeepSeek-V3-0324 --prompt "Say hi"
```

Для любого OpenAI-клиента (агенты, BAND SDK) достаточно указать `base_url` и ключ выше.

## Структура

| Путь | Что там |
|---|---|
| `PLAYBOOK.md` | План действий: kickoff → первые часы → неделя → сдача |
| `roles/` | Шаблоны **generic**-мандатов для агентов фабрики |
| `scripts/featherless_smoke.py` | Проверка ключа, список моделей, тестовый запрос |
| `.env.example` | Шаблон переменных окружения (`.env` в `.gitignore`) |
