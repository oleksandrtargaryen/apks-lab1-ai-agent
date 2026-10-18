---
description: Викликає skill project-scaffold і створює початковий C++ проєкт Hello World (src/main.cpp, структура каталогів, секція README).
argument-hint: "[language=C++] [project_name=hello_world_cpp] [executable=hello]"
allowed-tools: Read, Write, Edit, Glob, Grep, Skill, Bash(mkdir*), Bash(ls*), Bash(c++*), Bash(./build/scaffold/hello*), Bash(grep*), Bash(test*), Bash(git status*), Bash(git add*), Bash(git commit*), Bash(git diff*)
---

# /create-project — початковий проєкт

Дій як агент `build-engineer` (`.claude/agents/build-engineer.md`).
Аргументи: `$ARGUMENTS` (якщо порожньо — значення за замовчуванням зі skill).

## Передумови

- Виконано `/git-init`: поточний каталог — git-репозиторій, `.gitignore` містить `build/`.
- Доступний компілятор C++ (`c++ --version`).

## Дії

1. Застосуй skill **`project-scaffold`** (виклич його через Skill tool або
   прочитай `.claude/skills/project-scaffold/SKILL.md` і виконай розділ
   «Порядок дій») з параметрами з `$ARGUMENTS`.
2. Створи відсутні каталоги `src/`, `tests/`, `docs/`; файли `src/main.cpp`,
   `.gitattributes`; блок проєкту в `README.md`; допиши відсутні рядки `.gitignore`.
3. Існуючі файли, що вже відповідають специфікації, не змінюй.
4. Виконай перевірку skill (компіляція і запуск `main.cpp`).
5. Якщо є зміни — `git add src/main.cpp .gitattributes README.md .gitignore`
   і `git commit -m "feat(project): Hello World на C++ (src/main.cpp, README, .gitattributes)"`.
   Якщо змін немає — коміт не робити.

## Очікувані файли

- `src/main.cpp`
- `.gitattributes`
- `README.md` з одним блоком `<!-- project:start --> … <!-- project:end -->`
- каталоги `src/`, `tests/`, `docs/`

## Команди перевірки

Кожна команда — окремий виклик Bash; очікуваний результат після стрілки.

1. `test -f src/main.cpp` → код виходу 0.
2. `mkdir -p build/scaffold` → код виходу 0.
3. `c++ -std=c++17 src/main.cpp -o build/scaffold/hello` → код виходу 0.
4. `./build/scaffold/hello` → `Hello, World!`.
5. `grep -c 'project:start' README.md` → `1`.
6. `git status --short` → лише очікувані зміни (або порожньо після коміту).

## Ідемпотентність

Повторний запуск: файли не перезаписуються, блок README не дублюється,
новий коміт не створюється.

## Повідомлення про помилку

- `create-project: FAIL — не git-репозиторій, спочатку виконайте /git-init.`
- `create-project: FAIL — не знайдено компілятор C++.`
- `create-project: FAIL — підтримується лише language=C++ (варіант 1).`
- `create-project: FAIL — програма надрукувала "<вивід>" замість "Hello, World!".`
