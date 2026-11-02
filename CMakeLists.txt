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
