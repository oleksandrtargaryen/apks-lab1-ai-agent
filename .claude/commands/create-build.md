---
description: Викликає skill build-and-test — створює CMakeLists.txt, функцію add(), тест GoogleTest MathTest.BasicAddition, ci.sh/ci.bat і перевіряє локальне складання та ctest.
argument-hint: "[gtest_tag=v1.15.2] [build_dir=build]"
allowed-tools: Read, Write, Edit, Glob, Grep, Skill, Bash(mkdir*), Bash(ls*), Bash(chmod*), Bash(cmake*), Bash(ctest*), Bash(./build/hello*), Bash(./ci.sh*), Bash(bash ci.sh*), Bash(grep*), Bash(test*), Bash(git status*), Bash(git add*), Bash(git commit*), Bash(git diff*), Bash(git check-ignore*), Bash(git ls-files*)
---

# /create-build — система складання і тести

Дій як агент `build-engineer` (`.claude/agents/build-engineer.md`).
Аргументи: `$ARGUMENTS` (якщо порожньо — значення за замовчуванням зі skill).

## Передумови

- Існує `src/main.cpp` (виконано `/create-project`).
- Встановлено `cmake` ≥ 3.16 і компілятор C++; є доступ до мережі для
  завантаження GoogleTest (FetchContent).
- `build/` і `dist/` ігноруються Git.

## Дії

1. Застосуй skill **`build-and-test`** (Skill tool або
   `.claude/skills/build-and-test/SKILL.md`, розділ «Порядок дій»), підзадачі по черзі:
   build-system → test-function → unit-test → build-scripts.
2. Створи відсутні файли з точним вмістом зі skill; існуючі — звір і виправ
   лише відмінності, не дублюючи блоки CMake.
3. `chmod +x ci.sh`.
4. Виконай перевірку skill: configure → build → ctest → запуск `./build/hello`.
5. Переконайся, що `git ls-files build dist` порожній.
6. Якщо є зміни — `git add CMakeLists.txt src/math.hpp src/math.cpp tests/test_math.cpp ci.sh ci.bat`
   і `git commit -m "feat(build): CMake + GoogleTest/CTest, функція add(), скрипти ci.sh/ci.bat"`.
   Якщо змін немає — коміт не робити.

## Очікувані файли

- `CMakeLists.txt`
- `src/math.hpp`, `src/math.cpp`
- `tests/test_math.cpp`
- `ci.sh` (виконуваний), `ci.bat`

## Команди перевірки

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
ctest --test-dir build -C Release --output-on-failure
./build/hello                       # Hello, World!
git ls-files build dist | wc -l     # 0
```

## Ідемпотентність

Повторний запуск використовує той самий `build/` (інкрементальне
складання), не змінює файли, які вже відповідають специфікації, і не
створює порожній коміт.

## Повідомлення про помилку

- `create-build: FAIL — немає src/main.cpp, спочатку виконайте /create-project.`
- `create-build: FAIL — cmake не знайдено (потрібна версія ≥ 3.16).`
- `create-build: FAIL — конфігурація CMake: <перші рядки помилки>.`
- `create-build: FAIL — складання: <помилка компілятора/лінкера>.`
- `create-build: FAIL — тести: <назва тесту> — <вивід ctest>.`
