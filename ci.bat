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
