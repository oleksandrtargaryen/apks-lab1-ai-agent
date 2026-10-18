# Журнал взаємодії з AI

Інструмент: **Claude Code 2.1.302** (CLI), модель `claude-opus-5-5`, macOS arm64
(Apple clang 16.0.0, CMake 4.4.4, Ruby 2.6.10). Дата: 2026-10-18.

Агент, skills і commands (гілка `develop`) створено за допомогою AI за
вимогами методички. Гілку `feature/hello-world-cpp` згенеровано **запуском
агента** (`/lab-init`) у headless-режимі; ручних правок у згенерованих файлах
проєкту не було. Кожен запуск записано у сирий журнал `stream-json` (зберігається
поза репозиторієм, щоб не комітити локальні артефакти); нижче — витяг із нього.

Команда запуску агента (повністю — у [usage.md](usage.md), розділ 2.3):

```bash
claude --agent build-engineer -p "/lab-init" --permission-mode acceptEdits \
  --allowedTools "Bash(git status*)" "Bash(git add*)" "Bash(git commit*)" ... Read Write Edit Glob Grep Skill \
  --output-format stream-json --verbose > run1-lab-init.jsonl
```

## 1. Хронологія запусків

| № | Час | Запит (prompt) | Сесія | Ходів / інструментів | Результат |
|---|-----|----------------|-------|----------------------|-----------|
| 1 | 19:34–19:39 | `/lab-init` | `3f5767a8` | 94 / 88 | `LAB-INIT: SUCCESS`, 4 коміти; **7 відмов у дозволах**, 1 падіння перевірки тригерів (помилки 1 і 2) |
| 2 | 19:39–19:41 | «Виправ інструкції агента… (2 проблеми)» | `4c676f9c` | 17 / 16 | правки `.claude/` **заблоковано** (помилка 3) |
| 3 | 19:41–19:42 | resume: «дозвіл `Edit(/.claude/**)` надано…» | `4c676f9c` | 12 / 11 | знову заблоковано |
| 4 | 19:43 | resume: правило з абсолютним шляхом `Edit(//…/.claude/**)` | `4c676f9c` | 4 / 3 | знову заблоковано; AI запропонував staging/patch |
| 5 | 19:44–19:49 | resume: «запиши повні оновлені версії у staging-каталог» | `4c676f9c` | 24 / 23 | 9 файлів записано в `agent-fix/claude/…` → застосовано, коміт `6317292` |
| 6 | 19:50–19:52 | `/lab-init` (повторний) | `70cf4ada` | 96 / 90 | `SUCCESS`, **0 помилок, 0 відмов**, нових комітів немає; агент знайшов помилку 4 |
| 7 | 19:52–19:56 | resume: «виправ проблему з `build-*/` через інструкції агента» | `70cf4ada` | 17 / 16 | 3 файли в staging → застосовано, коміт `c30b00a` |
| 8 | 19:56–19:59 | `/lab-init` | `2fb5d7f3` | 110 / 104 | `/git-init` мігрував `.gitignore` (коміт `93880e2`), `CHECK: PASS` |
| 9 | 19:59–20:01 | `/lab-init` (перевірка ідемпотентності) | `5c925b1e` | 103 / 97 | `SUCCESS`, HEAD без змін, `git status` порожній |
| 10 | 20:02–20:03 | `/check` з навмисно зламаним тестом | `3489ebd7` | 38 / 37 | `CHECK: FAIL — 1 перевірку не пройдено: 6` (очікувано) |

## 2. Ключові відповіді агента

**Запуск 1 — фінальний звіт оркестратора** (скорочено):

```
| 1 | /git-init       | OK | створено `.gitignore` з усіма 23 правилами канонічного списку — 89dd157 |
| 2 | /create-project | OK | src/main.cpp, .gitattributes, блок у README; компілюється і друкує Hello, World! — fb269bf |
| 3 | /create-build   | OK | CMake + GoogleTest, тест 1/1 пройшов; повний ./ci.sh створив dist/hello — 4b4940d |
| 4 | /create-actions | OK | ci.yml: одна job на ubuntu / windows / macos — a218e1a |
| 5 | /check          | OK | CHECK: PASS |
LAB-INIT: SUCCESS
```

Агент сам указав на неточність у skill: *«Примітка в skill `github-actions`
неточна. Там сказано, що Ruby читає ключ `on` як рядок "on". Насправді в
цьому Ruby (2.6) він читається як `true`, і моя перша перевірка тригерів
через це впала… Примітку я не змінював, бо це не входить у мої задачі; її
варто виправити.»* — агент дотримався правила manifest-а не змінювати файли
поза своєю відповідальністю.

**Запуск 6 — знахідка при повторному запуску:**

```
git check-ignore -v --no-index .claude/skills/build-and-test/SKILL.md
.gitignore:3:build-*/	.claude/skills/build-and-test/SKILL.md
```

*«Правило `build-*/` також збігається з `.claude/skills/build-and-test/`…
Цей рядок є в обов'язковому списку skill `project-scaffold`, тож змінювати
його я не став… Скажіть, чи робити.»*

## 3. Помилки та їх виправлення

### Помилка 1. Хибна примітка про YAML-ключ `on` у skill `github-actions`

- **Прояв (запуск 1, крок 4):** перевірка тригерів
  `ruby -ryaml -e '… puts "on=#{y["on"].keys.join(",")}"'` завершилась з
  `undefined method 'keys' for nil:NilClass (NoMethodError)`.
- **Причина:** у skill було написано, що Ruby (Psych) читає `on:` як рядок.
  Насправді Ruby 2.6 (YAML 1.1) читає його як булеве `true`, як і PyYAML.
  Сам `ci.yml` був правильний — помилкова була інструкція агента.
- **Виправлення (через AI, запуски 2–5):** у `github-actions/SKILL.md`
  виправлено примітку і додано перевірку №6 з `t = y["on"] || y[true]`;
  таку ж підказку додано в крок 7 `/check`; новий рядок у таблиці помилок skill.
  AI перевірив нову команду на реальному `ci.yml`:
  `triggers=pull_request,push`, `push=develop,master`, `pull_request=develop,master`.

### Помилка 2. Відмови в дозволах при перевірці передумов `/lab-init`

- **Прояв (запуск 1):** 7 викликів Bash відхилено, наприклад:
  - `git --version` → *This command requires approval* (немає в `--allowedTools`);
  - `git rev-parse …; git --version; cmake --version; …; ruby -v` →
    *This Bash command contains multiple operations. The following parts require approval: git --version, ruby -v*;
  - `cd … && git rev-parse … && …` → *This command uses shell operators that require approval for safety*;
  - багаторядковий `ruby -e` з коментарем `# 1` → *Newline followed by # inside a quoted argument can hide arguments from path validation*.
  Агент обійшов це сам (окремими командами), але інструкція провокувала відмови.
- **Причина:** `lab-init.md` і `git-init.md` радили `git --version`, `ruby -v`,
  а блоки перевірок у commands/skills містили складені команди (`&&`, `||`,
  `| wc -l`, коментарі `#`) — дозволи CLI зіставляються з усією командою.
- **Виправлення (через AI, запуски 2–5, коміт `6317292`):**
  - передумови перевіряються лише командами з `allowed-tools`, кожною окремо:
    `git rev-parse --show-toplevel`, `cmake --version`, `c++ --version`,
    `ruby -ryaml -e 'puts RUBY_VERSION'`, `ls .claude/commands`;
  - у manifest додано правило 8: «кожну shell-команду виконуй окремим
    викликом Bash: без `&&`, `||`, `;`, `|`, перенаправлень і `#`»;
  - усі блоки перевірок у 9 файлах переписано як окремі команди з очікуваним
    результатом; `git ls-files | grep …` замінено на pathspec
    `git ls-files -- '.env*' '*/.env*' '*.pem' '*.key'`.
- **Підтвердження:** запуск 6 — 0 помилок інструментів і 0 відмов (було 9 і 7).

### Помилка 3. Захищений каталог `.claude/` у headless-режимі

- **Прояв (запуски 2–4):** кожен Edit файлу в `.claude/` →
  *Claude requested permissions to write to …/.claude/agents/build-engineer.md, but you haven't granted it yet.*
  Не допомогли ні `--allowedTools "Edit(/.claude/**)"`, ні абсолютний
  `Edit(//…/.claude/**)`. Режим `bypassPermissions` свідомо не використано
  (його заблокувала й політика безпеки середовища). Навіть запис у
  staging-шлях із сегментом `.claude/` у `/tmp` відхилено як *sensitive file*.
- **Рішення:** за пропозицією самого AI (варіант «staging/patch» у відповіді
  запуску 4) — AI записує повні нові версії файлів у staging-каталог
  `agent-fix/claude/…` поза репозиторієм, користувач переглядає `diff` і
  копіює їх у `.claude/`, коміт робиться окремо. Вміст змін — повністю
  згенерований AI; людина лише переглянула і застосувала.
- **Висновок:** змінювати інструкції агента в headless-режимі неможливо без
  ручного підтвердження — це корисне обмеження безпеки (агент не може сам
  переписати власні правила). Інтерактивно достатньо підтвердити запит.

### Помилка 4. `.gitignore` ігнорував файли агента (`build-*/`)

- **Прояв (запуск 6):** правило `build-*/` з канонічного списку збігалося з
  `.claude/skills/build-and-test/`. Файл уже відстежувався, тому нічого не
  зламалося, але нові файли в цьому каталозі `git add` пропустив би, а
  Grep/Glob з урахуванням `.gitignore` їх не бачили.
- **Виправлення (через AI, запуск 7, коміт `c30b00a`):**
  - у `project-scaffold/SKILL.md` шаблони `build-*/`, `cmake-build-*/`,
    `out/`, `Testing/` прив'язано до кореня (`/build-*/` …) з поясненням
    (на macOS `core.ignorecase=true`, тому `Testing/` збігся б із `testing/`);
    `build/`, `dist/` і шаблони секретів свідомо лишились без `/`;
  - у `/git-init` додано ідемпотентну **міграцію** застарілих рядків (Edit
    заміною, без дублювання);
  - у `/check` (крок 8) додано перевірки
    `git check-ignore -v --no-index .claude/skills/build-and-test/SKILL.md` (код 1)
    і `git ls-files -c -i --exclude-standard -- .claude` (порожньо).
- **Застосування до результату — через агента** (запуск 8): `/git-init`
  замінив 4 рядки і закомітив `93880e2 fix(git): прив'язати build-*/, cmake-build-*/, out/, Testing/ до кореня репозиторію`.

Усі виправлення інструкцій агента перенесено також у `develop`
(cherry-pick), щоб запуск агента з `develop` відтворював гілку feature.

## 4. Прийняті рішення

| Рішення | Обґрунтування |
|---------|---------------|
| Claude Code замість Copilot; `.claude/agents`, `.claude/skills`, `.claude/commands` | стандартний формат обраного клієнта; відповідність — у [architecture.md](architecture.md) |
| Оркестратор `/lab-init`, а не `/init` | `/init` — вбудована команда Claude Code (генерує `CLAUDE.md`) |
| Точний вміст файлів у skills | детермінований, відтворюваний результат; `/check` може звіряти вміст |
| GoogleTest через FetchContent, тег `v1.15.2` | без системних залежностей на runner-ах, відтворювано |
| `gtest_force_shared_crt ON` | уникнути `LNK2038` (конфлікт CRT) на Windows/MSVC |
| `ci.yml` лише викликає `ci.sh` / `ci.bat` | вимога методички; локальна збірка = CI |
| `bash ./ci.sh`, `call ci.bat`, `fail-fast: false`, `if-no-files-found: error` | незалежність від біта виконання; видно результат кожної ОС; job падає без артефакту |
| `ci.bat` лише ASCII, `.gitattributes`: `*.bat eol=crlf`, `*.sh eol=lf` | кодова сторінка cmd і коректні кінці рядків на Windows |
| Агент комітить локально по одному коміту на крок, ніколи не push-ить | окремі змістовні коміти + заборона push у manifest |
| `--permission-mode acceptEdits` + явний `--allowedTools` | без `rm`, `git push`, `git reset`; небезпечні дії відхиляються |
| Не використовувати `bypassPermissions` для правок `.claude/` | захист від самомодифікації агента — свідомо збережено |

## 5. Докази перевірки

**Локальна збірка** (`./ci.sh` після `rm -rf build dist`, повний вивід — у звіті):

```
==> Test
    Start 1: MathTest.BasicAddition
1/1 Test #1: MathTest.BasicAddition ...........   Passed    0.00 sec

100% tests passed out of 1
==> Package
==> Run
Hello, World!
```

**Тест** (`ctest --test-dir build -C Release --output-on-failure -V -R BasicAddition`):

```
1: [ RUN      ] MathTest.BasicAddition
1: [       OK ] MathTest.BasicAddition (0 ms)
100% tests passed out of 1
```

**Виконуваний файл і Git-гігієна:**

```
$ ./dist/hello
Hello, World!
$ file dist/hello
dist/hello: Mach-O 64-bit executable arm64
$ git check-ignore -v build/ dist/
.gitignore:2:build/	build/
.gitignore:6:dist/	dist/
$ git ls-files build dist
(порожньо — 0 файлів)
```

**Ідемпотентність** (запуск 9, `/lab-init` на готовому проєкті):

```
HEAD before=93880e2f5949ad6f2aa082b9d4c727be9d205aac after=93880e2f5949ad6f2aa082b9d4c727be9d205aac
git status --porcelain | wc -l  ->  0
md5(.gitignore README.md CMakeLists.txt ci.yml) до і після  ->  files identical
```

**Навмисно зламана перевірка** (запуск 10: `EXPECT_EQ(add(2, 3), 6)`):

```
| 6 | Складання і тести | FAIL | ... ctest завершився з кодом 8: `0% tests passed, 1 tests failed out of 1` |
| 9 | Проєкт не змінено | PASS | S0 = S1 = ` M tests/test_math.cpp` |
CHECK: FAIL — 1 перевірку не пройдено: 6
```

Агент не виправив тест сам («Ця команда нічого не змінює, тому файл я не
чіпав») і запропонував відновити файл користувачу. Після
`git checkout -- tests/test_math.cpp` — знову `100% tests passed`.

**GitHub Actions:** результати для ubuntu-latest, windows-latest,
macos-latest — у pull request `lab1/finish` (посилання на запуск у описі PR).
