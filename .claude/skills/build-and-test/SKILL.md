---
name: build-and-test
description: >-
  Налаштовує систему складання CMake (C++17), тестову функцію int add(int,int),
  юніт-тест GoogleTest MathTest.BasicAddition з CTest та кросплатформні скрипти
  збірки ci.sh / ci.bat, що складають Release, запускають ctest і копіюють
  виконуваний файл hello у dist/. Використовуй у команді /create-build.
---

# Skill: build-and-test

## Коли застосовувати

- Після `project-scaffold`, коли існує `src/main.cpp`, але немає `CMakeLists.txt`
  або тестів.
- Команда `/create-build` (або `/lab-init`, крок 3).
- Повторно — для звірки файлів зі специфікацією (ідемпотентно).

Підзадачі skill (можна виконувати окремо):

1. **build-system** — `CMakeLists.txt`;
2. **test-function** — `src/math.hpp`, `src/math.cpp`;
3. **unit-test** — `tests/test_math.cpp`;
4. **build-scripts** — `ci.sh`, `ci.bat`.

## Вхідні дані

| Параметр | За замовчуванням | Опис |
|----------|------------------|------|
| `project_name` | `hello_world_cpp` | назва в `project()` |
| `executable` | `hello` | ціль виконуваного файлу |
| `cxx_standard` | `17` | стандарт C++ |
| `gtest_tag` | `v1.15.2` | **зафіксований** реліз GoogleTest |
| `build_dir` | `build` | каталог складання (ігнорується Git) |
| `dist_dir` | `dist` | каталог артефактів (ігнорується Git) |

Передумова: існує `src/main.cpp` (інакше — помилка «спочатку виконайте /create-project»).

## Результат (файли)

### `CMakeLists.txt` (точний вміст)

```cmake
cmake_minimum_required(VERSION 3.16)
project(hello_world_cpp VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Бібліотека з тестованою функцією add()
add_library(mathlib STATIC src/math.cpp)
target_include_directories(mathlib PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/src)

# Виконуваний файл hello
add_executable(hello src/main.cpp)
target_link_libraries(hello PRIVATE mathlib)

# GoogleTest: зафіксований реліз, завантажується під час конфігурації
include(FetchContent)
FetchContent_Declare(
  googletest
  URL https://github.com/google/googletest/archive/refs/tags/v1.15.2.tar.gz
  DOWNLOAD_EXTRACT_TIMESTAMP TRUE
)
# Windows/MSVC: використовувати той самий CRT, що й основний проєкт
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
set(INSTALL_GTEST OFF CACHE BOOL "" FORCE)
set(BUILD_GMOCK OFF CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)

# Тести
enable_testing()
add_executable(test_math tests/test_math.cpp)
target_link_libraries(test_math PRIVATE mathlib GTest::gtest_main)
include(GoogleTest)
gtest_discover_tests(test_math)
```

### `src/math.hpp`

```cpp
#pragma once

int add(int a, int b);
```

### `src/math.cpp`

```cpp
#include "math.hpp"

int add(int a, int b) { return a + b; }
```

### `tests/test_math.cpp`

```cpp
#include <gtest/gtest.h>

#include "math.hpp"

TEST(MathTest, BasicAddition) {
    EXPECT_EQ(add(2, 3), 5);
}
```

### `ci.sh` (Linux / macOS, LF, виконуваний: `chmod +x ci.sh`)

```bash
#!/usr/bin/env bash
# Збірка, тестування та пакування hello (Linux / macOS).
set -euo pipefail
cd "$(dirname "$0")"

BUILD_DIR=build
DIST_DIR=dist

echo "==> Configure"
cmake -S . -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release

echo "==> Build (Release)"
cmake --build "$BUILD_DIR" --config Release

echo "==> Test"
ctest --test-dir "$BUILD_DIR" -C Release --output-on-failure

echo "==> Package"
mkdir -p "$DIST_DIR"
if [ -f "$BUILD_DIR/hello" ]; then
  BIN="$BUILD_DIR/hello"
else
  BIN="$BUILD_DIR/Release/hello"
fi
cp "$BIN" "$DIST_DIR/hello"

echo "==> Run"
"./$DIST_DIR/hello"
```

### `ci.bat` (Windows, CRLF)

```bat
@echo off
rem Build, test and package hello.exe (Windows).
setlocal
cd /d "%~dp0"

echo ==^> Configure
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release || exit /b 1

echo ==^> Build (Release)
cmake --build build --config Release || exit /b 1

echo ==^> Test
ctest --test-dir build -C Release --output-on-failure || exit /b 1

echo ==^> Package
if not exist dist mkdir dist
copy /Y build\Release\hello.exe dist\hello.exe || exit /b 1

echo ==^> Run
dist\hello.exe || exit /b 1
exit /b 0
```

> `ci.bat` містить лише ASCII-символи: cmd на Windows-runner за замовчуванням
> використовує не UTF-8 кодову сторінку, тому кирилиця в `.bat` може зламати вивід.

## Порядок дій

1. Перевірити передумову (`src/main.cpp`).
2. Для кожного файлу вище: якщо відсутній — створити з точним вмістом; якщо
   існує — порівняти і виправити лише відмінності (без дублювання
   `FetchContent_Declare`, `enable_testing`, `add_executable`).
3. `chmod +x ci.sh`.
4. Виконати перевірку (нижче). Каталоги `build/` та `dist/` вже в `.gitignore`.

## Перевірка результату

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
ctest --test-dir build -C Release --output-on-failure -R BasicAddition
./build/hello                       # -> Hello, World!
grep -c 'FetchContent_Declare' CMakeLists.txt   # очікується 1
git check-ignore -q build && echo "build/ ignored"
```

Успіх: конфігурація і складання без помилок, `100% tests passed`, у списку
тестів є `MathTest.BasicAddition`, `hello` друкує `Hello, World!`.
Повна збірка через скрипт: `./ci.sh` (створює `dist/hello`).

## Приклад входу

```
/create-build gtest_tag=v1.15.2 build_dir=build
```

## Очікуваний результат

```
create-build: OK
Створено: CMakeLists.txt, src/math.hpp, src/math.cpp, tests/test_math.cpp, ci.sh, ci.bat
Перевірки: cmake configure/build -> OK; ctest -> 1/1 passed (MathTest.BasicAddition); ./build/hello -> Hello, World!
```

## Типовий сценарій помилки та обробка

| Ситуація | Ознака | Дія |
|----------|--------|-----|
| Немає мережі під час FetchContent | `Failed to download ... googletest` | Зупинитись, повідомити «GoogleTest не завантажено: перевірте мережу/проксі». Не замінювати FetchContent на системний пакет без згоди користувача. |
| Тест падає | `0% tests passed`, `Expected equality` | Показати вивід ctest, перевірити `add()` у `src/math.cpp`; **не** змінювати очікуване значення в тесті, щоб «пройти». |
| Конфлікт із застарілим кешем | `CMakeCache.txt ... different source/generator` | Повідомити користувачу; не видаляти `build/` самостійно — запропонувати `cmake --fresh -S . -B build`. |
| `ci.sh: Permission denied` | біт виконання відсутній | `chmod +x ci.sh`, повторити. |
| Windows: `LNK2038 RuntimeLibrary mismatch` | помилка лінкування gtest | Перевірити, що є `set(gtest_force_shared_crt ON ...)` до `FetchContent_MakeAvailable`. |
