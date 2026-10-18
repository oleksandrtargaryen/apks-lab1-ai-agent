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
build-*/
cmake-build-*/
out/
dist/
Testing/
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
3. Додати відсутні рядки канонічного `.gitignore` (дописати в кінець, без дублікатів).
4. Створити `.gitattributes`, якщо його немає; якщо є — дописати відсутні рядки.
5. Оновити/додати блок проєкту в `README.md`.

## Перевірка результату

```bash
test -f src/main.cpp && echo "main.cpp: OK"
mkdir -p build/scaffold
c++ -std=c++17 src/main.cpp -o build/scaffold/hello && ./build/scaffold/hello
# очікується рядок: Hello, World!
grep -c '^build/$' .gitignore      # очікується 1
grep -c 'project:start' README.md  # очікується 1
```

Перевірка вважається успішною, якщо програма компілюється, друкує рівно
`Hello, World!`, а маркери та рядки `.gitignore` не задубльовані.

## Приклад входу

```
/create-project language=C++ project_name=hello_world_cpp executable=hello
```

## Очікуваний результат

```
create-project: OK
Створено: src/main.cpp, .gitattributes
Оновлено: README.md (секція проєкту), .gitignore (+0 рядків)
Перевірки: c++ src/main.cpp && ./build/scaffold/hello -> Hello, World!
```

Повторний запуск: `Створено: —`, `Без змін: src/main.cpp, .gitattributes, README.md, .gitignore`.

## Типовий сценарій помилки та обробка

| Ситуація | Ознака | Дія |
|----------|--------|-----|
| Немає компілятора C++ | `c++: command not found` | Зупинитись, повідомити: «Не знайдено компілятор C++ (встановіть clang/gcc/MSVC)». Файли не видаляти. |
| Передано іншу мову (`language=Python`) | параметр ≠ C++ | Зупинитись: «Цей агент підтримує лише варіант 1 (C++)». Нічого не створювати. |
| `src/main.cpp` уже містить інший код | вивід ≠ `Hello, World!` | Показати diff, виправити лише рядок виводу; не перезаписувати весь файл без потреби. |
| README без маркерів містить ручний розділ про проєкт | наявний текст | Не видаляти ручний текст, додати блок з маркерами в кінець. |
