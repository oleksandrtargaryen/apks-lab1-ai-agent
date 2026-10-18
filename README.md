# АПКС — Лабораторна робота № 1

**Проєктування AI-агента для автоматизації розробки та CI/CD**

| Поле | Значення |
|------|----------|
| Студент | Бартошко Олександр Ігорович |
| Група | КІ-408 |
| Варіант | 1 — C++ / CMake / GoogleTest + CTest |
| AI-інструмент | Claude Code (CLI) |

## Опис

Репозиторій містить AI-агента `build-engineer` у форматі **Claude Code**
(manifest, 3 skills, 6 commands, з них одна — оркестратор `/lab-init`).
Агент генерує мінімальний кросплатформний C++ проєкт `Hello World`
(виконуваний файл `hello`, функція `add()` з юніт-тестом GoogleTest
`MathTest.BasicAddition`), систему складання CMake, скрипти збірки
`ci.sh`/`ci.bat`, GitHub Actions workflow для Windows, Linux та macOS і
перевіряє результат командою `/check`.

| Гілка | Вміст |
|-------|-------|
| `master` | стабільна гілка |
| `develop` | лише агент з інструкціями та документація |
| `feature/hello-world-cpp` | результат запуску агента: код, тести, CI, журнал AI |

## Структура агента

```
.claude/
├── agents/build-engineer.md          # manifest агента
├── skills/
│   ├── project-scaffold/SKILL.md     # створення проєкту
│   ├── build-and-test/SKILL.md       # CMake + GoogleTest/CTest + ci.sh/ci.bat
│   └── github-actions/SKILL.md       # .github/workflows/ci.yml
└── commands/
    ├── git-init.md                   # /git-init
    ├── create-project.md             # /create-project
    ├── create-build.md               # /create-build
    ├── create-actions.md             # /create-actions
    ├── check.md                      # /check (нічого не змінює)
    └── lab-init.md                   # /lab-init — оркестратор
docs/
├── architecture.md                   # архітектура, відповідність методичці
└── usage.md                          # точні команди запуску
```

## Як запустити агента

Передумови: [Claude Code](https://docs.claude.com/en/docs/claude-code) (`claude`),
`git`, `cmake` ≥ 3.16, компілятор C++ (clang/gcc/MSVC), Ruby або Python+PyYAML
(для перевірки YAML), доступ до мережі.

Інтерактивно:

```bash
git clone https://github.com/oleksandrtargaryen/apks-lab1-ai-agent.git
cd apks-lab1-ai-agent
git checkout develop
git checkout -b feature/my-run
claude --agent build-engineer     # або просто: claude
> /lab-init
```

Без інтерактиву (headless):

```bash
claude --agent build-engineer -p "/lab-init" --permission-mode acceptEdits
```

Окремі операції: `/git-init`, `/create-project`, `/create-build`,
`/create-actions`, `/check`. Детально — у [docs/usage.md](docs/usage.md),
архітектура — у [docs/architecture.md](docs/architecture.md).
