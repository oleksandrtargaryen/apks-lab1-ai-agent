---
description: Оркестратор лабораторної — послідовно виконує /git-init, /create-project, /create-build, /create-actions, /check і зупиняється на першій помилці зі звітом.
argument-hint: "[project_name=hello_world_cpp]"
allowed-tools: Read, Write, Edit, Glob, Grep, Skill, Bash(git rev-parse*), Bash(git init*), Bash(git status*), Bash(git branch*), Bash(git add*), Bash(git commit*), Bash(git diff*), Bash(git log*), Bash(git check-ignore*), Bash(git ls-files*), Bash(mkdir*), Bash(ls*), Bash(cat*), Bash(grep*), Bash(test*), Bash(wc*), Bash(chmod*), Bash(c++*), Bash(cmake*), Bash(ctest*), Bash(./build/*), Bash(./ci.sh*), Bash(bash ci.sh*), Bash(ruby -ryaml*), Bash(python3*)
---

# /lab-init — оркестратор повного сценарію

> Назва `lab-init`, а не `init`: у Claude Code `/init` — вбудована команда
> (генерує `CLAUDE.md`), тому оркестратор перейменовано, щоб не
> конфліктувати з нею. Функція відповідає `init.prompt.md` з методички.

Дій як агент `build-engineer`: прочитай `.claude/agents/build-engineer.md`
(якщо сесія вже запущена з `--agent build-engineer`, manifest уже активний)
і дотримуйся його правил, заборон і критеріїв завершення.
Аргументи: `$ARGUMENTS` — передаються відповідним крокам.

## Передумови

- Поточний каталог — корінь репозиторію з каталогом `.claude/`
  (agents, skills, commands).
- Встановлено `git`, `cmake` ≥ 3.16, компілятор C++, парсер YAML (Ruby або PyYAML).
- Є доступ до мережі (FetchContent завантажує GoogleTest).

Перевір передумови до першого кроку (`git --version`, `cmake --version`,
`c++ --version`, `ls .claude/commands`). Якщо чогось бракує — одразу
звіт `LAB-INIT: FAIL (передумови)` без жодних змін.

## Порядок кроків

| Крок | Команда | Skill | Вхід (від попереднього кроку) | Вихід (для наступного) |
|------|---------|-------|-------------------------------|------------------------|
| 1 | `/git-init` | — | шлях репозиторію | гілка, `.gitignore` з `build/`, `dist/` |
| 2 | `/create-project` | `project-scaffold` | `.gitignore` готовий; `project_name`, `executable` | `src/main.cpp`, назва `hello` |
| 3 | `/create-build` | `build-and-test` | `src/main.cpp`, `executable=hello` | `CMakeLists.txt`, тести, `ci.sh`/`ci.bat`, `build/`, результат ctest |
| 4 | `/create-actions` | `github-actions` | шляхи `ci.sh`, `ci.bat`, `dist/` | `.github/workflows/ci.yml` |
| 5 | `/check` | — | усі файли кроків 1–4 | таблиця PASS/FAIL, `CHECK: PASS/FAIL` |

## Дії

1. Перевір передумови (див. вище).
2. Для кожного кроку 1→5 **строго по черзі**:
   1. Виконай команду: виклич її через Skill tool (`git-init`,
      `create-project`, `create-build`, `create-actions`, `check`) або, якщо
      це неможливо, прочитай `.claude/commands/<назва>.md` і виконай його
      розділ «Дії» повністю.
   2. Виконай «Команди перевірки» цього кроку і зафіксуй результат.
   3. Зафіксуй рядок звіту кроку (`<команда>: OK|FAIL`) і дані, потрібні
      наступному кроку (див. таблицю).
   4. Якщо крок завершився `FAIL` або його перевірка не пройшла —
      **зупинись**: наступні кроки не виконуй (позначай `SKIPPED`), нічого
      не відкочуй і не видаляй, переходь до фінального звіту.
3. Не приховуй помилки і не вважай роботу успішною без кроку 5:
   `LAB-INIT: SUCCESS` можна вивести лише якщо `/check` дав `CHECK: PASS`.
4. Не виконуй `git push`, не створюй PR — про це лише нагадай у звіті.

## Очікувані файли

Після успішного виконання: `.gitignore`, `.gitattributes`, `src/main.cpp`,
`src/math.hpp`, `src/math.cpp`, `tests/test_math.cpp`, `CMakeLists.txt`,
`ci.sh`, `ci.bat`, `.github/workflows/ci.yml`, оновлений `README.md`
і до 4 локальних комітів (по одному на крок 1–4, лише якщо були зміни).

## Команди перевірки

```bash
git log --oneline -5
git status --short           # порожньо після успішного запуску
ctest --test-dir build -C Release --output-on-failure
./build/hello                # Hello, World!
```

## Ідемпотентність

Повторний `/lab-init` на вже згенерованому проєкті: кожен крок звіряє
файли зі skills і нічого не змінює, нових комітів немає, `git status`
чистий, `/check` знову дає `CHECK: PASS`.

## Повідомлення про помилку

```
LAB-INIT: FAIL на кроці <N> (<команда>)
Причина: <повідомлення про помилку команди>
Доказ: <ключові рядки виводу>
Виконано: <кроки OK>   Пропущено: <кроки SKIPPED>
Що зробити: <конкретна дія, напр. "перевірте мережу і запустіть /create-build">
```

## Формат фінального звіту

```
| Крок | Команда         | Статус  | Результат |
|------|-----------------|---------|-----------|
| 1    | /git-init       | OK      | .gitignore: … |
| 2    | /create-project | OK      | … |
| 3    | /create-build   | OK      | ctest 1/1 passed |
| 4    | /create-actions | OK      | ci.yml: 3 OS |
| 5    | /check          | OK      | CHECK: PASS |

LAB-INIT: SUCCESS
Наступні дії користувача: git push, перевірка GitHub Actions, PR.
```
