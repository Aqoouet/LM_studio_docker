# Llama.cpp Docker (CPU)

Минимальный Docker-стек для запуска двух CPU-only API серверов на базе `llama.cpp` с уже скачанными GGUF-моделями.

## Состав

| Сервис | Образ | Назначение |
|--------|-------|-----------|
| `llama-api-qwen36` | `ghcr.io/ggerganov/llama.cpp:server-b4234` | API для Qwen3.6-35B-A3B |
| `llama-api-qwen34` | `ghcr.io/ggerganov/llama.cpp:server-b4234` | API для Qwen3-4B-Instruct-2507 |

## Требования

- Docker + Docker Compose (plugin)
- CPU-only server (без GPU)
- Primary models root: `/expert_scratch/lmstudio-models`
- Fallback models root: `/filer/users/rymax1e/lmstudio-models`

## Быстрый старт

```bash
git clone git@github.com:Aqoouet/LM_studio_docker.git
cd LM_studio_docker
cp .env.example .env
# При необходимости отредактируй .env
docker compose pull
docker compose up -d
```

По умолчанию автозагружаются 2 модели (через first `.gguf` файл в каталогах):

- `lmstudio-community/Qwen3.6-35B-A3B-GGUF`
- `lmstudio-community/Qwen3-4B-Instruct-2507-GGUF`

Запусти helper script (он проверит swap usage и наличие модели):

```bash
./start.sh
```

Дождитесь, пока оба сервиса станут healthy (~2-3 мин):

```bash
docker compose ps
```
API endpoints:

- `http://<server-ip>:1234/v1/models` (Qwen3.6)
- `http://<server-ip>:1235/v1/models` (Qwen3-4B)

## Переменные окружения (.env)

| Переменная | По умолчанию | Описание |
|-----------|-------------|---------|
| `LLAMA_IMAGE` | `ghcr.io/ggerganov/llama.cpp:server-b4234` | CPU image |
| `LMS_PORT_MODEL1` | `1234` | Порт API для модели #1 |
| `LMS_PORT_MODEL2` | `1235` | Порт API для модели #2 |
| `LMS_MODELS_ROOT_PRIMARY` | `/expert_scratch/lmstudio-models` | Основной путь к GGUF-моделям |
| `LMS_MODELS_ROOT_FALLBACK` | `/filer/users/rymax1e/lmstudio-models` | Альтернативный путь к GGUF-моделям |
| `LMS_MODEL1_SUBDIR` | `lmstudio-community/Qwen3.6-35B-A3B-GGUF` | Подкаталог модели #1 |
| `LMS_MODEL2_SUBDIR` | `lmstudio-community/Qwen3-4B-Instruct-2507-GGUF` | Подкаталог модели #2 |
| `LMS_MAX_CONCURRENT` | `4` | Кол-во параллельных запросов (`--parallel`) |
| `LMS_THREADS` | `16` | Потоки CPU (`--threads`) |
| `LMS_CTX_SIZE` | `4096` | Размер контекста (`--ctx-size`) |
| `LMS_CONTAINER_MAX_RAM` | `120g` | Лимит RAM на каждый контейнер |

> Swap usage блокируется в `start.sh`: если swap используется, скрипт завершится с ошибкой.

## Развёртывание на Rocky Linux

Подробная инструкция: [DEPLOY.md](DEPLOY.md).

## Очистка диска Docker

Команды и безопасный порядок очистки: [DOCKER_CLEANUP.md](DOCKER_CLEANUP.md).

## Структура репозитория

```
.
├── Dockerfile            # Образ lmstudio на Ubuntu 24.04
├── docker-compose.yml    # Оркестрация сервисов
├── start.sh              # Проверки swap/model и запуск stack
├── entrypoint.sh         # Legacy (не используется)
├── .env.example          # Шаблон переменных окружения
└── DEPLOY.md             # Развёртывание на Rocky Linux
```
