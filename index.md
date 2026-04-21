# Документация — LM Studio Docker

Навигация по документации репозитория.

## Документы

| Файл | Содержание |
|------|-----------|
| [README.md](README.md) | Обзор проекта, быстрый старт, переменные окружения |
| [DEPLOY.md](DEPLOY.md) | Развёртывание на Rocky Linux: Docker, клонирование, скачивание моделей |

## Структура проекта

```
.
├── Dockerfile            # Образ lmstudio (Ubuntu 24.04 + lms CLI)
├── docker-compose.yml    # Сервисы: lmstudio + open-webui
├── entrypoint.sh         # Логика старта: daemon → скачать модель → сервер → автозагрузка
├── .env.example          # Все настраиваемые переменные с комментариями
├── scripts/
│   └── download-model.sh # Утилита для скачивания модели в контейнер
├── README.md             # Обзор проекта
├── DEPLOY.md             # Продакшн-деплой
└── index.md              # Этот файл
```

## Ключевые концепции

**LMS daemon** — фоновый процесс LM Studio, управляющий моделями и сервером API.

**OpenAI-совместимый API** — `lmstudio` экспонирует `/v1/models`, `/v1/chat/completions` и др. на порту `LMS_PORT` (по умолчанию 1234). Open WebUI подключается к нему как к OpenAI-бэкенду.

**Автозагрузка** — при `LMS_AUTOLOAD=true` контейнер сам загружает модель в память. Задайте `LMS_MODEL` точным ключом из `lms ls --llm`, иначе загрузится первая модель из списка.

**Постоянное хранилище** — модели монтируются с хоста (`/expert_scratch/lmstudio-models`), данные Open WebUI хранятся в именованном volume `open-webui-data`.

## Быстрые команды

```bash
# Запустить стек
docker compose up -d --build

# Статус и healthcheck
docker compose ps

# Логи lmstudio
docker compose logs -f lmstudio

# Скачать модель
./scripts/download-model.sh "lmstudio-community/Qwen3.5-35B-A3B-GGUF"

# Список загруженных моделей
docker exec lmstudio lms ls --llm

# Остановить стек
docker compose down
```
