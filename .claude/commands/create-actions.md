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
3. Виконай усі 5 перевірок зі skill (YAML, 3 ОС, немає логіки збірки,
   виклик скриптів, одна job).
4. Якщо є зміни — `git add .github/workflows/ci.yml` і
   `git commit -m "ci: GitHub Actions matrix ubuntu/windows/macos через ci.sh/ci.bat"`.
   Якщо змін немає — коміт не робити.

## Очікувані файли

- `.github/workflows/ci.yml`

## Команди перевірки

```bash
ruby -ryaml -e 'YAML.load_file(".github/workflows/ci.yml"); puts "YAML OK"'
grep -c -E 'ubuntu-latest|windows-latest|macos-latest' .github/workflows/ci.yml
grep -En '\b(cmake|ctest|make|g\+\+|clang|cl\.exe)\b' .github/workflows/ci.yml || echo "no build logic: OK"
grep -E 'ci\.sh|ci\.bat' .github/workflows/ci.yml
```

Push і перевірку запуску в GitHub Actions виконує користувач (агенту push заборонено).

## Ідемпотентність

Повторний запуск не створює другий workflow і не дублює job/кроки; якщо
`ci.yml` відповідає шаблону — файл не змінюється, коміту немає.

## Повідомлення про помилку

- `create-actions: FAIL — немає ci.sh/ci.bat, спочатку виконайте /create-build.`
- `create-actions: FAIL — невалідний YAML: <повідомлення парсера, рядок>.`
- `create-actions: FAIL — у matrix відсутня ОС: <os>.`
- `create-actions: FAIL — ci.yml містить логіку збірки (<рядок>); перенесіть її в ci.sh/ci.bat.`
