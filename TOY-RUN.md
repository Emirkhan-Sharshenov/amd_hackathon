# Репетиция на toy — пошагово

Цель: прогнать **нашу** фабрику из 4 агентов через toy от начала до `harness check`.
Проверяем не счётчик, а фабрику: агенты находят друг друга, передают полные задачи,
reviewer сам запускает проверки, в `room.json` есть обмен `@handle` в обе стороны.

Ниже `<WS>` — абсолютный путь к рабочей папке, например `/Users/you/hack` или `/home/you/hack`.
На Windows всё делается внутри WSL2.

## 0. Что нужно установить

- Python **3.12+**, Git, Docker (демон запущен), Band Desktop
- Доступ к модели для агентов (подписка Claude / API-ключ / Featherless через OpenCode)

## 1. Рабочая папка и харнесс

```sh
mkdir -p <WS> && cd <WS>
git clone https://github.com/band-ai/dark-factory-wearedevs.git
git clone https://github.com/Emirkhan-Sharshenov/amd_hackathon.git
cd dark-factory-wearedevs
python3 -m venv .venv && . .venv/bin/activate
python -m pip install -r harness/requirements.txt
python -m playwright install chromium        # на Linux: install --with-deps chromium
python -m harness --help

mkdir -p ../band-work/toy-result/mandates ../band-work/checks
cp ../amd_hackathon/mandates/*.md ../band-work/toy-result/mandates/
git -C ../band-work/toy-result init -b main
(cd ../band-work/toy-result && pwd)          # это абсолютный путь для агентов
```

(Если ветка с мандатами ещё не в `main`, клонируй с `-b claude/brave-knuth-9g2zoo`.)

## 2. Заполнить Harness / Model

В каждом `band-work/toy-result/mandates/*.md` заменить две строки `TODO` на то, на чём
агент реально работает, например:

```text
Harness: Claude Code
Model: <точный id модели>
```

## 3. Четыре агента в Band Desktop

Для каждого из `coordinator`, `builder`, `tester`, `reviewer`:

- имя агента **ровно** такое (от него зависит имя файла мандата и `@handle`);
- harness и модель как в мандате;
- в постоянные инструкции агента вставить текст его мандата целиком;
- рабочая папка = абсолютный путь `band-work/toy-result`;
- разрешения: git, docker, запуск python; у каждого свои `git user.name` / `user.email`
  (например `builder` / `builder@factory.local`).

## 4. Комната

Создать комнату `toy-rehearsal`, добавить всех четырёх. Проверка связи — написать:

```text
@coordinator ping @builder, @tester and @reviewer and ask each to reply to you by @handle. Report who answered.
```

Все трое должны ответить. Если нет — чинить на этом шаге, дальше идти бессмысленно.

## 5. Задание (единственный ввод на этап)

Подставь `<WS>` и отправь **одним сообщением**. Для первой репетиции — только этап 1.

```text
@coordinator Build this service one stage at a time.

Result repository (absolute): <WS>/band-work/toy-result
Specification for this stage: <WS>/dark-factory-wearedevs/toy/spec/stage-1.md
Read it and paste its full text into every handoff.
Stage folder: stage-1; carry forward from: none
Check command (run from <WS>/dark-factory-wearedevs, use a new --out name every run):
  .venv/bin/python -m harness run --track toy --repo <WS>/band-work/toy-result --stage 1 --mode isolated --out <WS>/band-work/checks/toy-s1-<run number>
Expected result line: "claimed stage: 1". A "stage 2: fail" line is expected and correct.
When this stage is accepted, stop and post the final report.
```

## 6. Пока работают — смотреть, не вмешиваться

Записывай (это потом идёт в FACTORY.md и мне для правки мандатов):

- [ ] время старта и финала
- [ ] coordinator сделал реестр требований до раздачи работы?
- [ ] передачи содержат **полный текст** спецификации, а не «см. выше»?
- [ ] builder и tester работали параллельно, tester не читал код?
- [ ] reviewer **сам** собрал и запустил харнесс (а не поверил builder)?
- [ ] было ли отклонение, и изменило ли оно код?
- [ ] кто-то спросил человека или завис в ожидании? (это нарушение)

## 7. После финала

```sh
cd <WS>/dark-factory-wearedevs
.venv/bin/python -m harness run --track toy --repo ../band-work/toy-result --stage 1 --mode isolated --out ../band-work/checks/toy-s1-me
```

Скачать комнату: Band Desktop → комната → `⋮` → **Open in Band** → `⋮` → **Download → Download full session**.

```sh
mv ~/Downloads/<имя комнаты>.json ../band-work/toy-result/room.json
.venv/bin/python -m harness check ../band-work/toy-result --track toy
```

`README.md` и `FACTORY.md` в toy-result harness check потребует — для репетиции можно
скопировать заглушки, это нормально.

## 8. Прислать мне

1. Вывод `harness run` и `harness check`.
2. Заметки из шага 6.
3. `room.json` (или куски, где что-то пошло не так) — по нему поправлю мандаты.

Если этап 1 прошёл чисто — следующая репетиция: все 4 этапа toy одним заданием.
