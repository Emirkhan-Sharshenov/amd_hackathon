# Агенты на Featherless — настройка (Windows + WSL)

Все агенты работают **внутри Ubuntu (WSL)**, рядом с кодом и Docker:
OpenCode ходит в Featherless за моделью, `band-sdk` подключает каждого агента к комнате BAND.
Band Desktop на Windows нужен только чтобы видеть комнату и писать в неё.

```
Band (комната) ⇄ run_seats.py (4 агента, band-sdk) ⇄ opencode serve ⇄ Featherless API
                                     │
                                     └─ работают в ~/hack/band-work/toy-result
```

Модели (из строк `Model:` в мандатах; проверены организаторами с OpenCode):

| Агент | Модель |
|---|---|
| coordinator | `moonshotai/Kimi-K2.5` |
| builder | `MiniMaxAI/MiniMax-M2.5` |
| tester | `deepseek-ai/DeepSeek-V3.2` — другое семейство, чем у builder |
| reviewer | `moonshotai/Kimi-K2.5` |

Все команды ниже — в окне **Ubuntu**.

## 1. Ключ Featherless

1. Зарегистрироваться на featherless.ai, активировать промокод `WEAREDEVS26`
   (⏰ поставить напоминание отменить подписку).
2. Создать API-ключ в личном кабинете.
3. Сохранить в Ubuntu (ключ не попадёт ни в один репозиторий):

```sh
echo 'export FEATHERLESS_API_KEY=ВСТАВЬ_КЛЮЧ' >> ~/.bashrc
source ~/.bashrc
curl -s https://api.featherless.ai/v1/models -H "Authorization: Bearer $FEATHERLESS_API_KEY" \
  | grep -o '"id":"[^"]*\(Kimi-K2.5\|MiniMax-M2.5\|DeepSeek-V3.2\)"'
```

Должны найтись все три модели. Если какой-то нет — пришли вывод, заменим.

## 2. OpenCode и band-sdk

```sh
curl -fsSL https://opencode.ai/install | bash
source ~/.bashrc
opencode --version

cd ~/hack
python3.12 -m venv band-venv
band-venv/bin/pip install 'band-sdk[opencode]'
```

## 3. Провайдер Featherless для OpenCode

Конфиг — в домашней папке, **не** в репозитории (иначе ключ попадёт в git):

```sh
mkdir -p ~/.config/opencode
cat > ~/.config/opencode/opencode.json <<'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "featherless": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Featherless AI",
      "options": {
        "baseURL": "https://api.featherless.ai/v1",
        "apiKey": "{env:FEATHERLESS_API_KEY}"
      },
      "models": {
        "MiniMaxAI/MiniMax-M2.5": {},
        "moonshotai/Kimi-K2.5": {},
        "deepseek-ai/DeepSeek-V3.2": {}
      }
    }
  }
}
EOF
opencode models | grep featherless
```

Проверка, что модель реально пишет файлы (так советует руководство):

```sh
mkdir -p /tmp/octest && cd /tmp/octest
opencode run -m featherless/MiniMaxAI/MiniMax-M2.5 \
  "Create hello.txt containing the word banana, then run 'wc -c hello.txt'."
cat hello.txt
```

Должно быть `banana`. Если нет — дальше не идём, присылай вывод.

## 4. Четыре агента в BAND

В Band Desktop / консоли BAND создай 4 агента **с ровно такими именами**:
`coordinator`, `builder`, `tester`, `reviewer` — тип агента, который подключается
через SDK (внешний агент, *не* «New local agent»). Для каждого BAND выдаст
**Agent ID** и **API key**.

Сохрани их в файл **вне репозитория**:

```sh
cat > ~/hack/agent_config.yaml <<'EOF'
coordinator:
  agent_id: "..."
  api_key: "..."
builder:
  agent_id: "..."
  api_key: "..."
tester:
  agent_id: "..."
  api_key: "..."
reviewer:
  agent_id: "..."
  api_key: "..."
EOF
chmod 600 ~/hack/agent_config.yaml
```

Если в интерфейсе не найдёшь, где взять Agent ID / API key для SDK-агента — спроси в
BAND Discord: «how do I create an SDK agent and get its agent_id and api_key for band-sdk».

## 5. Git-имена агентов

Все агенты работают в одной папке, поэтому задаём одно имя репозитория фабрики:

```sh
git -C ~/hack/band-work/toy-result config user.name "factory-band"
git -C ~/hack/band-work/toy-result config user.email "band@factory.local"
```

## 6. Запуск (два окна Ubuntu)

Обнови наш репозиторий и мандаты в toy-result:

```sh
cd ~/hack/amd_hackathon && git pull
cp ~/hack/amd_hackathon/mandates/*.md ~/hack/band-work/toy-result/mandates/
```

**Окно 1** — сервер OpenCode (держать открытым):

```sh
cd ~/hack/band-work/toy-result
opencode serve --hostname=127.0.0.1 --port=4096
```

**Окно 2** — агенты:

```sh
~/hack/band-venv/bin/python ~/hack/amd_hackathon/scripts/run_seats.py \
  --repo ~/hack/band-work/toy-result \
  --config ~/hack/agent_config.yaml
```

Должно вывести 4 строки с моделями и `starting seats`. Остановить — `Ctrl+C`.

Дальше — `TOY-RUN.md`, шаг 4: комната, пинг, задание.

## Если что-то не так

| Симптом | Что делать |
|---|---|
| `429` / `concurrency` от Featherless | тариф ограничивает одновременные запросы; запусти меньше агентов параллельно или замени модель одного агента на меньшую |
| агент «думает» и обрывается по таймауту | `--turn-timeout 1800` |
| `connection refused 127.0.0.1:4096` | не запущен `opencode serve` (окно 1) |
| агенты не видят сообщения | проверь, что они добавлены в комнату и имена совпадают с ключами в `agent_config.yaml` |
