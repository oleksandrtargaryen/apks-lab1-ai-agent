---
description: Перевіряє (не змінюючи проєкт) структуру, manifest агента, skills, commands, CMake-складання, ctest, YAML workflow і .gitignore. Видає CHECK PASS/FAIL.
argument-hint: "[без аргументів]"
allowed-tools: Read, Glob, Grep, Bash(test*), Bash(ls*), Bash(grep*), Bash(cat*), Bash(wc*), Bash(cmake*), Bash(ctest*), Bash(./build/hello*), Bash(ruby -ryaml*), Bash(python3*), Bash(git status*), Bash(git diff*), Bash(git ls-files*), Bash(git check-ignore*), Bash(git rev-parse*)
---

# /check — перевірка без змін у проєкті

Дій як агент `build-engineer` (`.claude/agents/build-engineer.md`).

**Ця команда нічого не змінює.** Заборонено використовувати Write/Edit,
`git add`, `git commit`, `chmod`, `rm`, а також виправляти знайдені
проблеми. Єдине, що створюється, — вміст ігнорованого каталогу `build/`
(результат складання). Якщо перевірка не пройшла — повідомити, що саме
зламано і яку команду запустити для виправлення.

## Передумови

- Поточний каталог — git-репозиторій з агентом (`.claude/`).
- Встановлено `cmake`, компілятор C++, парсер YAML (`ruby -ryaml` або PyYAML).

## Дії

Виконай **усі** перевірки (не зупиняйся на першій помилці), для кожної
запиши `PASS` або `FAIL` з доказом (вивід команди). Кожну shell-команду
виконуй окремим викликом Bash (без `&&`, `||`, `;`, `|` і коментарів `#`).

0. **Знімок стану:** збережи вивід `git status --porcelain` (S0).

1. **Структура.** Існують: `.claude/agents/build-engineer.md`,
   `.claude/skills/{project-scaffold,build-and-test,github-actions}/SKILL.md`,
   `.claude/commands/{git-init,create-project,create-build,create-actions,check,lab-init}.md`,
   `src/main.cpp`, `src/math.hpp`, `src/math.cpp`, `tests/test_math.cpp`,
   `CMakeLists.txt`, `ci.sh`, `ci.bat`, `.github/workflows/ci.yml`,
   `.gitignore`, `README.md`, `docs/architecture.md`, `docs/usage.md`.
   `ci.sh` має біт виконання (`test -x ci.sh`).

2. **Manifest агента** (`.claude/agents/build-engineer.md`): frontmatter з
   `name: build-engineer`, `description:`, `tools:`; розділи
   `## 1. Роль`, `## 4. Заборонені дії`, `## 7. Критерії успішного завершення`.

3. **Skills.** Кожен `SKILL.md` має frontmatter `name:` (збігається з назвою
   каталогу) і `description:`, а також розділи: `## Коли застосовувати`,
   `## Вхідні дані`, `## Результат`, `## Перевірка результату`,
   `## Приклад входу`, `## Очікуваний результат`, `## Типовий сценарій помилки`.

4. **Commands.** Кожен з 6 файлів має `description:` у frontmatter і
   розділи `## Передумови`, `## Дії`, `## Команди перевірки`,
   `## Повідомлення про помилку`. У `lab-init.md` розділ
   `## Порядок кроків` перелічує `/git-init`, `/create-project`,
   `/create-build`, `/create-actions`, `/check` саме в цьому порядку
   (порівняй номери рядків через `grep -n`).

5. **Вміст проєкту.**
   - `src/main.cpp` містить `Hello, World!`;
   - `src/math.hpp` оголошує `int add(int a, int b)`;
   - `tests/test_math.cpp` містить `TEST(MathTest, BasicAddition)`;
   - `CMakeLists.txt` містить `CMAKE_CXX_STANDARD 17`, `FetchContent_Declare`
     (рівно 1 раз) з тегом релізу `v1.15.2`, `gtest_force_shared_crt ON`,
     `enable_testing()`, `gtest_discover_tests`, `add_executable(hello`.
   - `ci.sh` і `ci.bat` містять `cmake`, `ctest` і копіювання в `dist`.

6. **Складання і тести** (кожна команда — окремий виклик Bash).
   ```bash
   cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
   cmake --build build --config Release
   ctest --test-dir build -C Release --output-on-failure
   ./build/hello
   ```
   PASS, якщо всі команди завершились з кодом 0, ctest показує
   `100% tests passed` і тест `MathTest.BasicAddition` пройдений, а
   `hello` друкує рівно `Hello, World!`.

7. **Workflow** (`.github/workflows/ci.yml`):
   - валідний YAML: `ruby -ryaml -e 'YAML.load_file(".github/workflows/ci.yml")'`
     (або `python3 -c 'import yaml; yaml.safe_load(open(".github/workflows/ci.yml"))'`);
   - тригери `push` і `pull_request` на `develop` і `master`. Ruby 2.6 / PyYAML
     (YAML 1.1) читають ключ `on:` як булеве `true`, тому `y["on"]` дає `nil` —
     читай тригери через `t = y["on"] || y[true]`:
     `ruby -ryaml -e 'y=YAML.load_file(".github/workflows/ci.yml"); t=y["on"] || y[true]; puts "triggers=#{t.keys.sort.join(",")}"; puts "push=#{t["push"]["branches"].join(",")}"; puts "pull_request=#{t["pull_request"]["branches"].join(",")}"'`
     (очікується `triggers=pull_request,push`, `push=develop,master`,
     `pull_request=develop,master`);
   - рівно одна job; matrix містить `ubuntu-latest`, `windows-latest`, `macos-latest`;
   - викликає `ci.sh` і `ci.bat`;
   - **немає логіки збірки**: `grep -En '\b(cmake|ctest|make|g\+\+|clang|cl\.exe)\b' .github/workflows/ci.yml` нічого не знаходить;
   - є `actions/upload-artifact` з `path: dist/`;
   - немає секретів: `grep -n 'secrets\.' .github/workflows/ci.yml` нічого не знаходить.

8. **Git-гігієна** (кожна команда — окремий виклик).
   - `git check-ignore -q build/` і `git check-ignore -q dist/` — успішні;
   - `git ls-files build dist .cache` — порожньо;
   - `git ls-files -- '.env*' '*/.env*' '*.pem' '*.key'` — порожньо
     (pathspec замість `git ls-files | grep`).

9. **Проєкт не змінено:** `git status --porcelain` після перевірок (S1)
   збігається з S0.

## Очікувані файли

Команда не створює файлів у Git; лише оновлює ігнорований `build/`.

## Команди перевірки

Див. «Дії» (кроки 1–9). Мінімальний ручний набір — кожен рядок окремим
викликом Bash:

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
ctest --test-dir build -C Release --output-on-failure
./build/hello
ruby -ryaml -e 'YAML.load_file(".github/workflows/ci.yml"); puts "YAML OK"'
git check-ignore -v build/
git status --porcelain
```

Очікується: усі команди з кодом 0, `100% tests passed`, `Hello, World!`,
`YAML OK`, `git check-ignore -v` показує правило `.gitignore` для `build/`,
`git status --porcelain` збігається з S0.

## Ідемпотентність

Команду можна запускати скільки завгодно разів: вона лише читає файли і
складає проєкт у `build/`.

## Повідомлення про помилку

Для кожної проваленої перевірки:
`check: FAIL [<№>. <назва>] — <що очікувалось> / <що отримано>. Виправлення: <команда, напр. /create-build>`.

## Формат звіту

```
| № | Перевірка            | Результат | Доказ |
|---|----------------------|-----------|-------|
| 1 | Структура            | PASS      | 23/23 файлів |
| … | …                    | …         | … |
| 9 | Проєкт не змінено    | PASS      | git status без змін |

CHECK: PASS          (або: CHECK: FAIL — N перевірок не пройдено: <список №>)
```
