---
name: github-actions
description: >-
  Створює .github/workflows/ci.yml — GitHub Actions workflow з однією job і
  matrix ubuntu-latest / windows-latest / macos-latest, який лише робить
  checkout, викликає ci.sh або ci.bat і зберігає dist/ як артефакт. Перевіряє
  валідність YAML і відсутність логіки збірки у workflow. Використовуй у
  команді /create-actions.
---

# Skill: github-actions

## Коли застосовувати

- Після `build-and-test`, коли існують `ci.sh` і `ci.bat`.
- Команда `/create-actions` (або `/lab-init`, крок 4).
- Повторно — для звірки `ci.yml` зі специфікацією (ідемпотентно, без другого workflow-файлу).

## Вхідні дані

| Параметр | За замовчуванням | Опис |
|----------|------------------|------|
| `branches` | `develop`, `master` | гілки для тригерів `push` і `pull_request` |
| `os_matrix` | `ubuntu-latest`, `windows-latest`, `macos-latest` | операційні системи |
| `unix_script` | `ci.sh` | скрипт збірки для Linux/macOS |
| `windows_script` | `ci.bat` | скрипт збірки для Windows |
| `artifact_dir` | `dist/` | що завантажувати як артефакт |

Передумови: існують `ci.sh` і `ci.bat` (інакше — «спочатку виконайте /create-build»).

## Принцип

`ci.yml` **не містить логіки збірки** (жодних `cmake`, `ctest`, `make`,
компіляторів). Він лише: checkout → виклик скрипта → upload артефакту.
Уся збірка, тести і генерація виконуваного файлу — у `ci.sh` / `ci.bat`,
тому локальна збірка і CI ідентичні. Секретів у workflow немає
(`permissions: contents: read`).

## Результат: `.github/workflows/ci.yml` (точний вміст)

```yaml
name: CI

on:
  push:
    branches: [develop, master]
  pull_request:
    branches: [develop, master]

permissions:
  contents: read

jobs:
  build-and-test:
    name: build-and-test (${{ matrix.os }})
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Build and test (Linux/macOS)
        if: runner.os != 'Windows'
        shell: bash
        run: bash ./ci.sh

      - name: Build and test (Windows)
        if: runner.os == 'Windows'
        shell: cmd
        run: call ci.bat

      - name: Upload hello binary
        uses: actions/upload-artifact@v4
        with:
          name: hello-${{ matrix.os }}
          path: dist/
          if-no-files-found: error
```

Пояснення рішень:

- `fail-fast: false` — збій на одній ОС не скасовує інші, видно результат кожної.
- `bash ./ci.sh` — не залежить від біта виконання файлу після checkout.
- `if-no-files-found: error` — job падає, якщо скрипт не створив `dist/hello`.
- Артефакт `hello-<os>` містить виконуваний файл для кожної ОС.

## Порядок дій

1. Перевірити передумови.
2. `mkdir -p .github/workflows`.
3. Якщо `ci.yml` відсутній — створити з точним вмістом; якщо існує —
   виправити відмінності (не створювати `ci2.yml`, не дублювати ключі `jobs`).
4. Виконати перевірку.

## Перевірка результату

Кожна команда — окремий виклик Bash (без `&&`, `||`, `;`, `|` поза лапками
і без коментарів `#`); очікуваний результат указано після команди.

1. Валідний YAML (будь-який доступний парсер):
   `ruby -ryaml -e 'YAML.load_file(".github/workflows/ci.yml"); puts "YAML OK"'`
   → `YAML OK`. Якщо Ruby недоступний:
   `python3 -c 'import yaml; yaml.safe_load(open(".github/workflows/ci.yml")); print("YAML OK")'`.
2. Усі три ОС у matrix — три окремі виклики, кожен знаходить рядок:
   `grep -E 'ubuntu-latest' .github/workflows/ci.yml`,
   `grep -E 'windows-latest' .github/workflows/ci.yml`,
   `grep -E 'macos-latest' .github/workflows/ci.yml`.
3. Немає логіки збірки:
   `grep -En '\b(cmake|ctest|make|g\+\+|clang|cl\.exe)\b' .github/workflows/ci.yml`
   → порожній вивід і код виходу 1 (0 збігів) = OK; будь-який збіг = FAIL.
4. Викликаються саме скрипти — два окремі виклики, кожен знаходить рядок:
   `grep -E 'ci\.sh' .github/workflows/ci.yml`,
   `grep -E 'ci\.bat' .github/workflows/ci.yml`.
5. Одна job:
   `ruby -ryaml -e 'y=YAML.load_file(".github/workflows/ci.yml"); puts "jobs=#{y["jobs"].size}"'`
   → `jobs=1`.
6. Тригери `push` і `pull_request` на `develop` і `master`:
   `ruby -ryaml -e 'y=YAML.load_file(".github/workflows/ci.yml"); t=y["on"] || y[true]; puts "triggers=#{t.keys.sort.join(",")}"; puts "push=#{t["push"]["branches"].join(",")}"; puts "pull_request=#{t["pull_request"]["branches"].join(",")}"'`
   → `triggers=pull_request,push`, `push=develop,master`, `pull_request=develop,master`.

Примітка: за правилами YAML 1.1 ключ `on` — булеве значення. Системний
Ruby 2.6 (Psych, YAML 1.1) і PyYAML читають `on:` як `true`/`True`, тому
`y["on"]` повертає `nil` (помилка `undefined method 'keys' for nil:NilClass`).
Деякі інші парсери повертають рядок `"on"`. Тригери завжди читай через
`t = y["on"] || y[true]` (у Python: `y.get("on", y.get(True))`) — це працює
з обома варіантами. Для перевірки лише валідності YAML різниця не має значення.

## Приклад входу

```
/create-actions branches=develop,master os_matrix=ubuntu-latest,windows-latest,macos-latest
```

## Очікуваний результат

```
create-actions: OK
Створено: .github/workflows/ci.yml
Перевірки: YAML OK; matrix: ubuntu-latest, windows-latest, macos-latest; build logic in yml: none; jobs=1; triggers: push, pull_request -> develop, master
```

Після push у `develop`/`master` або PR до них GitHub запускає 3 паралельні
конфігурації `build-and-test (<os>)`, кожна завантажує артефакт `hello-<os>`.

## Типовий сценарій помилки та обробка

| Ситуація | Ознака | Дія |
|----------|--------|-----|
| Невалідний YAML (табуляція, зламаний відступ) | помилка парсера з номером рядка | Показати рядок, виправити відступи пробілами, повторити перевірку. |
| Пропущена ОС у matrix | grep не знаходить `macos-latest` | Додати ОС у `matrix.os`, не створюючи другу job. |
| У workflow з'явилися `cmake`/`ctest` | grep №3 знаходить збіги | Перенести команди в `ci.sh`/`ci.bat`, у yml залишити тільки виклик скрипта. |
| На runner `ci.sh: Permission denied` | лог Actions | Використовувати `bash ./ci.sh` (уже в шаблоні). |
| Артефакт порожній | `No files were found with the provided path: dist/` | Перевірити крок Package у скрипті збірки; не вимикати `if-no-files-found: error`. |
| Немає парсера YAML локально | `cannot load such file -- yaml` і `No module named yaml` | Повідомити користувачу; не встановлювати пакети самостійно. |
| Перевірка тригерів падає на `y["on"]` | `undefined method 'keys' for nil:NilClass` | Парсер YAML 1.1 прочитав `on` як `true`; використати `t = y["on"] \|\| y[true]` (перевірка №6). `ci.yml` не змінювати. |
