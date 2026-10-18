---
description: Викликає skill github-actions і створює .github/workflows/ci.yml (одна job, matrix ubuntu/windows/macos, лише виклик ci.sh/ci.bat, upload dist/).
argument-hint: "[branches=develop,master]"
allowed-tools: Read, Write, Edit, Glob, Grep, Skill, Bash(mkdir*), Bash(ls*), Bash(grep*), Bash(test*), Bash(ruby -ryaml*), Bash(python3*), Bash(git status*), Bash(git add*), Bash(git commit*), Bash(git diff*)
---

# /create-actions — GitHub Actions workflow

Дій як агент `build-engineer` (`.claude/agents/build-engineer.md`).
Аргументи: `$ARGUMENTS` (якщо порожньо — значення за замовчуванням зі skill).

## Передумови

- Існують `ci.sh` і `ci.bat` (виконано `/create-build`).

## Дії

1. Застосуй skill **`github-actions`** (Skill tool або
   `.claude/skills/github-actions/SKILL.md`, розділ «Порядок дій»).
2. `mkdir -p .github/workflows`; створи або звір `.github/workflows/ci.yml`
   з точним шаблоном зі skill. Інших workflow-файлів не створюй.
3. Виконай усі 6 перевірок зі skill (YAML, 3 ОС, немає логіки збірки,
   виклик скриптів, одна job, тригери).
4. Якщо є зміни — `git add .github/workflows/ci.yml` і
   `git commit -m "ci: GitHub Actions matrix ubuntu/windows/macos через ci.sh/ci.bat"`.
   Якщо змін немає — коміт не робити.

## Очікувані файли

- `.github/workflows/ci.yml`

## Команди перевірки

Кожна команда — окремий виклик Bash; очікуваний результат після стрілки.

1. `ruby -ryaml -e 'YAML.load_file(".github/workflows/ci.yml"); puts "YAML OK"'` → `YAML OK`.
2. `grep -E 'ubuntu-latest' .github/workflows/ci.yml` → знайдено рядок.
3. `grep -E 'windows-latest' .github/workflows/ci.yml` → знайдено рядок.
4. `grep -E 'macos-latest' .github/workflows/ci.yml` → знайдено рядок.
5. `grep -En '\b(cmake|ctest|make|g\+\+|clang|cl\.exe)\b' .github/workflows/ci.yml`
   → порожній вивід і код виходу 1 = OK (немає логіки збірки).
6. `grep -E 'ci\.sh' .github/workflows/ci.yml` → знайдено рядок.
7. `grep -E 'ci\.bat' .github/workflows/ci.yml` → знайдено рядок.
8. `ruby -ryaml -e 'y=YAML.load_file(".github/workflows/ci.yml"); t=y["on"] || y[true]; puts "triggers=#{t.keys.sort.join(",")}"; puts "push=#{t["push"]["branches"].join(",")}"; puts "pull_request=#{t["pull_request"]["branches"].join(",")}"'`
   → `triggers=pull_request,push`, `push=develop,master`, `pull_request=develop,master`
   (ключ `on:` парсер YAML 1.1 читає як `true`, тому `y["on"] || y[true]`).

Push і перевірку запуску в GitHub Actions виконує користувач (агенту push заборонено).

## Ідемпотентність

Повторний запуск не створює другий workflow і не дублює job/кроки; якщо
`ci.yml` відповідає шаблону — файл не змінюється, коміту немає.

## Повідомлення про помилку

- `create-actions: FAIL — немає ci.sh/ci.bat, спочатку виконайте /create-build.`
- `create-actions: FAIL — невалідний YAML: <повідомлення парсера, рядок>.`
- `create-actions: FAIL — у matrix відсутня ОС: <os>.`
- `create-actions: FAIL — ci.yml містить логіку збірки (<рядок>); перенесіть її в ci.sh/ci.bat.`
