---
name: project-scaffold
description: >-
  Створює мінімальний C++ проєкт Hello World — структуру каталогів src/ tests/
  docs/, src/main.cpp, базовий .gitignore/.gitattributes та секцію проєкту в
  README.md — і перевіряє, що вихідний файл компілюється та запускається.
  Використовуй у команді /create-project або коли в репозиторії немає src/main.cpp.
---

# Skill: project-scaffold

## Коли застосовувати

- Репозиторій порожній або містить лише агента/документацію, а `src/main.cpp` відсутній.
- Команда `/create-project` (або оркестратор `/lab-init`, крок 2).
- Повторно — щоб звірити наявні файли зі специфікацією (ідемпотентно: нічого не дублює).

Не застосовувати для створення системи складання і тестів — це skill `build-and-test`.

## Вхідні дані

| Параметр | Значення за замовчуванням (варіант 1) | Опис |
|----------|----------------------------------------|------|
| `language` | `C++` (стандарт C++17) | мова проєкту |
| `project_name` | `hello_world_cpp` | назва проєкту (використовується в `project()` CMake та README) |
| `executable` | `hello` | назва виконуваного файлу |
| `greeting` | `Hello, World!` | рядок, який друкує програма |

Якщо користувач передав інші значення аргументами команди — використовуй їх;
інакше — значення за замовчуванням. Мова, відмінна від C++, — помилка
(див. «Типовий сценарій помилки»).

## Результат (файли)

| Файл / каталог | Вміст |
|----------------|-------|
| `src/` | каталог вихідного коду |
| `tests/` | каталог тестів (поки може бути порожнім — заповнює `build-and-test`) |
| `docs/` | документація (існуючі файли не змінювати) |
| `src/main.cpp` | програма, яка друкує `Hello, World!` |
| `.gitignore` | містить усі рядки з розділу «Канонічний .gitignore» |
| `.gitattributes` | правила кінців рядків для скриптів |
| `README.md` | блок між маркерами `<!-- project:start -->` / `<!-- project:end -->` |

### `src/main.cpp` (точний вміст)

```cpp
#include <iostream>

int main() {
    std::cout << "Hello, World!" << std::endl;
    return 0;
}
```

### Канонічний `.gitignore`

Кожен рядок має бути у файлі рівно один раз (порядок і коментарі довільні):

```gitignore
# Build outputs
build/
/build-*/
/cmake-build-*/
/out/
dist/
/Testing/
CMakeUserPresets.json

# Caches
.cache/

# IDE / OS
.vscode/
.idea/
*.swp
.DS_Store
Thumbs.db

# Secrets
.env
.env.*
*.pem
*.key
secrets/

# Claude Code local settings
.claude/settings.local.json
```

#### Чому частина шаблонів прив'язана до кореня (`/`)

Шаблон без `/` на початку діє на **будь-якому** рівні вкладеності, тож може
зачепити файли агента в `.claude/`. На macOS і Windows Git за замовчуванням
порівнює шляхи без урахування регістру (`core.ignorecase=true`), тому,
наприклад, `Testing/` збігається з `.claude/skills/testing/`.

| Рядок | Що створює цей каталог | Рішення | Кого з агента зачепив би варіант без `/` |
|-------|------------------------|---------|------------------------------------------|
| `/build-*/` | додаткові каталоги збірки в корені (`build-debug/`) | лише корінь | `.claude/skills/build-and-test/` — **реальний збіг** |
| `/cmake-build-*/` | CLion, у корені проєкту | лише корінь | будь-який skill `cmake-build-…` |
| `/out/` | Visual Studio (`out/build/…`), у корені | лише корінь | skill/команда в каталозі `out/` |
| `/Testing/` | CTest, у каталозі запуску; при `--test-dir build` він уже всередині `build/` | лише корінь | `.claude/skills/testing/` (через `core.ignorecase`) |
| `build/`, `dist/` | каталоги складання й артефактів | **без `/`** | лише каталог з точною назвою `build`/`dist` |
| `secrets/`, `.env*`, `*.pem`, `*.key` | секрети | **без `/`** | — |

`build/` і `dist/` навмисно лишаються без `/`. Ігнорувати вкладені каталоги
`build/` (наприклад, у підпроєктах) — це бажана поведінка, жоден файл агента
не лежить у каталозі з такою назвою, а на точний рядок `build/` спираються
перевірки `/git-init`, `/check` і цього skill. Шаблони секретів теж не
прив'язуються до кореня: тут важливіше ігнорувати їх скрізь. Від можливого
збігу з новими файлами агента захищає перевірка `/check` (крок 8):
`git ls-files -c -i --exclude-standard -- .claude` має повертати порожній вивід.

#### Міграція застарілих рядків

У попередніх версіях цього skill ці шаблони були без `/`. Наявні в
`.gitignore` старі рядки потрібно **замінити**, а не дописувати поруч нові
(деталі — `/git-init`, крок 3):

| Застарілий рядок | Канонічний рядок |
|------------------|------------------|
| `build-*/` | `/build-*/` |
| `cmake-build-*/` | `/cmake-build-*/` |
| `out/` | `/out/` |
| `Testing/` | `/Testing/` |

### `.gitattributes` (точний вміст)

```gitattributes
* text=auto
*.sh text eol=lf
*.bat text eol=crlf
```

### Секція README (точний вміст блоку)

Якщо блок з маркерами вже існує — замінити тільки його вміст; якщо немає —
додати в кінець `README.md` (один раз):

~~~markdown
<!-- project:start -->
## Проєкт Hello World (C++17 / CMake / GoogleTest)

| Шлях | Призначення |
|------|-------------|
| `src/main.cpp` | програма `hello`, друкує `Hello, World!` |
| `src/math.hpp`, `src/math.cpp` | функція `int add(int, int)` |
| `tests/test_math.cpp` | юніт-тест `MathTest.BasicAddition` |
| `CMakeLists.txt` | складання, FetchContent GoogleTest, CTest |
| `ci.sh` / `ci.bat` | скрипти збірки для Linux/macOS та Windows |
| `.github/workflows/ci.yml` | GitHub Actions: ubuntu / windows / macos |

Складання і запуск:

```bash
./ci.sh            # Linux / macOS
ci.bat             # Windows (cmd)
./dist/hello       # -> Hello, World!
```
<!-- project:end -->
~~~

## Порядок дій

1. `mkdir -p src tests docs`.
2. Якщо `src/main.cpp` відсутній — створити з точним вмістом; якщо існує і
   друкує інший рядок — виправити (Edit), не створюючи копій.
3. `.gitignore`: спершу мігрувати застарілі рядки за таблицею «Міграція
   застарілих рядків» (за правилом `/git-init`, крок 3), потім дописати в
   кінець відсутні рядки канонічного списку (без дублікатів).
4. Створити `.gitattributes`, якщо його немає; якщо є — дописати відсутні рядки.
5. Оновити/додати блок проєкту в `README.md`.

## Перевірка результату

Кожна команда — окремий виклик Bash (без `&&`, `;`, `|` і коментарів `#`);
очікуваний результат указано після команди.

1. `test -f src/main.cpp` → код виходу 0.
2. `mkdir -p build/scaffold` → код виходу 0.
3. `c++ -std=c++17 src/main.cpp -o build/scaffold/hello` → код виходу 0, без помилок.
4. `./build/scaffold/hello` → рівно `Hello, World!`.
5. `grep -c '^build/$' .gitignore` → `1`.
6. `grep -c -xF '/build-*/' .gitignore` → `1`.
7. `grep -c -xF 'build-*/' .gitignore` → `0` (код виходу 1 — застарілого рядка немає).
8. `git check-ignore -v --no-index .claude/skills/build-and-test/SKILL.md` →
   порожній вивід, код виходу 1 (файли агента не ігноруються).
9. `grep -c 'project:start' README.md` → `1`.

Перевірка вважається успішною, якщо програма компілюється і друкує рівно
`Hello, World!`, маркери та рядки `.gitignore` не задубльовані, а жоден
файл агента не потрапляє під правила `.gitignore`.

## Приклад входу

```
/create-project language=C++ project_name=hello_world_cpp executable=hello
```

## Очікуваний результат

```
create-project: OK
Створено: src/main.cpp, .gitattributes
Оновлено: README.md (секція проєкту), .gitignore (+0 рядків, мігровано 0)
Перевірки: c++ -std=c++17 src/main.cpp -> OK; ./build/scaffold/hello -> Hello, World!; .claude/ not ignored
```

Повторний запуск: `Створено: —`, `Без змін: src/main.cpp, .gitattributes, README.md, .gitignore`.

## Типовий сценарій помилки та обробка

| Ситуація | Ознака | Дія |
|----------|--------|-----|
| Немає компілятора C++ | `c++: command not found` | Зупинитись, повідомити: «Не знайдено компілятор C++ (встановіть clang/gcc/MSVC)». Файли не видаляти. |
| Передано іншу мову (`language=Python`) | параметр ≠ C++ | Зупинитись: «Цей агент підтримує лише варіант 1 (C++)». Нічого не створювати. |
| `src/main.cpp` уже містить інший код | вивід ≠ `Hello, World!` | Показати diff, виправити лише рядок виводу; не перезаписувати весь файл без потреби. |
| README без маркерів містить ручний розділ про проєкт | наявний текст | Не видаляти ручний текст, додати блок з маркерами в кінець. |
| `.gitignore` зі старої версії skill ігнорує файли агента | `git check-ignore -v --no-index .claude/skills/build-and-test/SKILL.md` виводить `.gitignore:N:build-*/` | Мігрувати рядок за таблицею (Edit `build-*/` → `/build-*/`), не дописуючи другий рядок; повторити перевірку 8. |
