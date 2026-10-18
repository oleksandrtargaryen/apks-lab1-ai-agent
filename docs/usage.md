# Використання агента `build-engineer`

## 1. Передумови

| Інструмент | Перевірка | Примітка |
|------------|-----------|----------|
| Claude Code | `claude --version` | авторизований акаунт |
| Git | `git --version` | |
| CMake ≥ 3.16 | `cmake --version` | |
| Компілятор C++17 | `c++ --version` | clang / gcc / MSVC |
| Парсер YAML | `ruby -ryaml -e 'puts 1'` або `python3 -c 'import yaml'` | для `/check` |
| Мережа | — | FetchContent завантажує GoogleTest `v1.15.2` |

## 2. Запуск агента

### 2.1. Підготовка гілки

```bash
git clone https://github.com/oleksandrtargaryen/apks-lab1-ai-agent.git
cd apks-lab1-ai-agent
git checkout develop
git checkout -b feature/hello-world-cpp
```

### 2.2. Інтерактивний режим

```bash
claude --agent build-engineer
```

У сесії Claude Code:

```
/lab-init
```

Окремі кроки можна викликати вручну в тому ж порядку:

```
/git-init
/create-project
/create-build
/create-actions
/check
```

Без `--agent build-engineer` команди теж працюють: кожна першим кроком
читає manifest `.claude/agents/build-engineer.md`.

### 2.3. Headless-режим (точна команда, якою згенеровано гілку feature)

```bash
claude --agent build-engineer -p "/lab-init" \
  --permission-mode acceptEdits \
  --allowedTools "Bash(git status*)" "Bash(git add*)" "Bash(git commit*)" \
                 "Bash(git diff*)" "Bash(git log*)" "Bash(git rev-parse*)" \
                 "Bash(git branch*)" "Bash(git check-ignore*)" "Bash(git ls-files*)" \
                 "Bash(cmake*)" "Bash(ctest*)" "Bash(./ci.sh*)" "Bash(bash ci.sh*)" \
                 "Bash(./build/*)" "Bash(c++*)" "Bash(chmod*)" "Bash(mkdir*)" \
                 "Bash(ls*)" "Bash(cat*)" "Bash(grep*)" "Bash(test*)" "Bash(wc*)" \
                 "Bash(ruby -ryaml*)" "Bash(python3*)" \
                 Read Write Edit Glob Grep Skill \
  --output-format stream-json --verbose > lab-init.log
```

- `--permission-mode acceptEdits` — агент може створювати/редагувати файли без
  підтвердження;
- `--allowedTools` — явний перелік дозволених shell-команд; `git push`, `rm`,
  `git reset` тощо **не дозволені** і будуть відхилені;
- `lab-init.log` зберігайте **поза репозиторієм** або не комітьте його
  (журнал взаємодії оформлено в `docs/ai-log.md`).

Очікуваний фінал звіту: таблиця 5 кроків зі статусом `OK` і рядок
`LAB-INIT: SUCCESS`.

### 2.4. Повторний запуск (ідемпотентність)

```bash
claude --agent build-engineer -p "/lab-init" --permission-mode acceptEdits --allowedTools ...   # ті самі параметри
git status --short       # порожньо
git log --oneline -5     # нових комітів немає
```

### 2.5. Тільки перевірка

```bash
claude --agent build-engineer -p "/check" --allowedTools "Bash(cmake*)" "Bash(ctest*)" \
  "Bash(./build/*)" "Bash(git status*)" "Bash(git ls-files*)" "Bash(git check-ignore*)" \
  "Bash(ruby -ryaml*)" "Bash(grep*)" "Bash(test*)" "Bash(ls*)" Read Glob Grep
```

`/check` не має дозволу на `Write`/`Edit` і нічого не змінює у проєкті.

## 3. Локальна перевірка без AI

### Linux / macOS

```bash
./ci.sh                                   # configure → build Release → ctest → dist/hello
./dist/hello                              # Hello, World!
ctest --test-dir build -C Release --output-on-failure -R BasicAddition
git check-ignore -v build/ dist/          # обидва ігноруються
git ls-files build dist                   # порожньо
```

### Windows (cmd)

```bat
ci.bat
dist\hello.exe
```

### Вручну, без скриптів

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
ctest --test-dir build -C Release --output-on-failure
./build/hello            # Windows: build\Release\hello.exe
```

## 4. GitHub Actions

Workflow `.github/workflows/ci.yml` запускається на `push` і `pull_request` до
`develop` та `master`. Одна job `build-and-test` з matrix `ubuntu-latest`,
`windows-latest`, `macos-latest` виконує checkout → `ci.sh`/`ci.bat` →
upload артефакту `hello-<os>` (каталог `dist/`).

```bash
git push -u origin feature/hello-world-cpp
gh run list --branch feature/hello-world-cpp
gh run watch                        # стежити за останнім запуском
gh run view <run-id> --json jobs --jq '.jobs[] | "\(.name): \(.conclusion)"'
```

## 5. Демонстрація для відео: навмисно зламана перевірка

Мета — показати, що `/check` (і оркестратор) не вважають роботу успішною,
якщо результат неправильний.

### Сценарій A — зламаний тест

```bash
# 1. Зламати очікуване значення в тесті
sed -i.bak 's/EXPECT_EQ(add(2, 3), 5);/EXPECT_EQ(add(2, 3), 6);/' tests/test_math.cpp && rm tests/test_math.cpp.bak
# 2. Запустити перевірку
claude --agent build-engineer
> /check
```

Очікуваний звіт `/check`:

- перевірка **6. Складання і тести — FAIL**: `ctest` показує
  `0% tests passed, 1 tests failed`, `MathTest.BasicAddition (Failed)`,
  `Expected equality of these values: add(2, 3) Which is: 5, 6`;
- перевірка **9. Проєкт не змінено — PASS**: `git status` до і після
  однаковий (`M tests/test_math.cpp` з'явився до запуску, агент нічого не змінив);
- підсумок `CHECK: FAIL — 1 перевірок не пройдено: 6`, рекомендація
  перевірити `add()` / тест (агент **не** виправляє тест сам).

Відновлення:

```bash
git checkout -- tests/test_math.cpp
claude --agent build-engineer -p "/check" ...   # знову CHECK: PASS
```

### Сценарій B — прибрати ОС з matrix

```bash
sed -i.bak 's/os: \[ubuntu-latest, windows-latest, macos-latest\]/os: [ubuntu-latest, windows-latest]/' .github/workflows/ci.yml && rm .github/workflows/ci.yml.bak
claude --agent build-engineer
> /check
```

Очікувано: **7. Workflow — FAIL** «matrix не містить `macos-latest`»,
`CHECK: FAIL`. Якщо запустити `/lab-init`, крок `/create-actions` звірить
`ci.yml` із шаблоном і поверне `macos-latest` (ідемпотентне виправлення),
а `/check` знову дасть `PASS`.

Відновлення без AI:

```bash
git checkout -- .github/workflows/ci.yml
```
