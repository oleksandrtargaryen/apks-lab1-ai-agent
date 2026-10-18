---
description: Перевіряє git-репозиторій, створює або оновлює .gitignore (без дублікатів) і показує стан Git.
argument-hint: "[без аргументів]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git rev-parse*), Bash(git init*), Bash(git status*), Bash(git branch*), Bash(git add*), Bash(git commit*), Bash(git diff*), Bash(git check-ignore*), Bash(git ls-files*), Bash(grep*), Bash(ls*)
---

# /git-init — підготовка Git-репозиторію

Дій як агент `build-engineer` (`.claude/agents/build-engineer.md`): дотримуйся
його правил роботи з файлами та заборонених дій.

## Передумови

- Встановлено `git`.
- Поточний каталог — корінь проєкту (або порожній каталог для нового репозиторію).

Перевір передумови лише командами з `allowed-tools`, окремим викликом Bash
(без `&&`, `;`, `|`): `git rev-parse --show-toplevel`. Вивід шляху — git є і
каталог у репозиторії; `fatal: not a git repository` — git є, репозиторій
треба створити (крок 1); `command not found` — `git-init: FAIL — git не
встановлено або недоступний.` Не використовуй `git --version`: його немає в
`allowed-tools`, і headless-запуск його відхиляє.

## Дії

1. Перевір репозиторій: `git rev-parse --is-inside-work-tree`.
   - Не репозиторій → `git init -b develop` (лише якщо каталог не є
     підкаталогом іншого репозиторію).
   - Репозиторій → нічого не ініціалізувати повторно.
2. Покажи поточну гілку: `git branch --show-current`.
3. Створи або онови `.gitignore` за **канонічним списком** зі skill
   `project-scaffold` (розділ «Канонічний .gitignore»):
   - файлу немає → створи його з повним списком;
   - файл є → для кожного рядка списку перевір `grep -qxF '<рядок>' .gitignore`
     і допиши лише відсутні рядки. Існуючі рядки не змінюй і не видаляй.
4. Перевір, що тимчасові каталоги і секрети ігноруються — три окремі виклики,
   кожен має завершитися з кодом 0:
   `git check-ignore -q build/`, `git check-ignore -q dist/`, `git check-ignore -q .env`.
5. Перевір, що в індексі немає артефактів: `git ls-files build dist .cache`
   повинно повернути порожній результат.
6. Якщо `.gitignore` змінився (`git status --porcelain .gitignore` не порожній) —
   `git add .gitignore` і `git commit -m "chore(git): .gitignore для build/dist, кешів, IDE та секретів"`.
   Якщо змін немає — коміт не робити.
7. Покажи стан: `git status --short --branch`.

## Очікувані файли

- `.gitignore` з усіма рядками канонічного списку (кожен рівно один раз).

## Команди перевірки

Кожна команда — окремий виклик Bash; очікуваний результат після стрілки.

1. `git rev-parse --is-inside-work-tree` → `true`.
2. `git check-ignore -q build/` → код виходу 0.
3. `git check-ignore -q dist/` → код виходу 0.
4. `git ls-files build dist` → порожній вивід.
5. `grep -c -xF 'build/' .gitignore` → `1`.
6. `git status --short --branch` → поточна гілка, без неочікуваних змін.

## Ідемпотентність

Повторний запуск не створює новий репозиторій, не дублює рядки `.gitignore`
і не створює порожній коміт.

## Повідомлення про помилку

- `git-init: FAIL — git не встановлено або недоступний.`
- `git-init: FAIL — каталог є підкаталогом іншого репозиторію (<шлях>); ініціалізація скасована.`
- `git-init: FAIL — у Git відстежуються файли з build/ або dist/: <список>. Видаліть їх з індексу вручну (git rm --cached), агент цього не робить.`

## Формат звіту

```
git-init: OK
Репозиторій: <шлях>, гілка <назва>
.gitignore: створено | додано N рядків | без змін
Перевірки: build/ ignored, dist/ ignored, tracked artifacts: 0
```
