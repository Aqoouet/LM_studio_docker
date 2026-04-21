# LM Studio Docker

Docker-стек для запуска LM Studio в безголовом режиме (headless) на сервере без GPU + веб-интерфейс [Open WebUI](https://github.com/open-webui/open-webui).

## Состав

| Сервис | Образ | Назначение |
|--------|-------|-----------|
| `lmstudio` | собирается локально (Ubuntu 24.04) | LM Studio daemon + OpenAI-совместимый API |
| `open-webui` | `ghcr.io/open-webui/open-webui:main` | Чат-интерфейс для пользователей |

## Требования

- Docker + Docker Compose (plugin)
- 30+ ядер CPU, 400+ ГБ RAM (для больших моделей)
- Папка с моделями (по умолчанию `/expert_scratch/lmstudio-models`)

## Быстрый старт

```bash
git clone git@github.com:Aqoouet/LM_studio_docker.git
cd LM_studio_docker
cp .env.example .env
# При необходимости отредактируй .env
docker compose up -d --build
```

Дождитесь, пока `lmstudio` станет healthy (~2-3 мин):

```bash
docker compose ps
```

Откройте чат: `http://<server-ip>:3000`

## Переменные окружения (.env)

| Переменная | По умолчанию | Описание |
|-----------|-------------|---------|
| `LMS_PORT` | `1234` | Порт OpenAI-совместимого API |
| `LMS_CONTEXT_LENGTH` | `262144` | Длина контекста при загрузке модели |
| `LMS_AUTOLOAD` | `true` | Автозагрузка модели в память при старте |
| `LMS_GET_MODEL` | `qwen/qwen3-4b-2507` | Модель для скачивания при старте (если не скачана) |
| `LMS_MODEL` | `qwen3-4b` | Ключ модели из `lms ls --llm` для автозагрузки |
| `WEBUI_PORT` | `3000` | Внешний порт Open WebUI |

> Если на диске несколько LLM, **обязательно** задайте `LMS_MODEL` — иначе загрузится первая модель из списка.

## Скачать модель вручную

```bash
./scripts/download-model.sh "lmstudio-community/Qwen3.5-35B-A3B-GGUF"
```

Модели ищите на [lmstudio.ai/models](https://lmstudio.ai/models).

## Развёртывание на Rocky Linux

Подробная инструкция: [DEPLOY.md](DEPLOY.md).

## Структура репозитория

```
.
├── Dockerfile            # Образ lmstudio на Ubuntu 24.04
├── docker-compose.yml    # Оркестрация сервисов
├── entrypoint.sh         # Запуск daemon, скачивание и автозагрузка модели
├── .env.example          # Шаблон переменных окружения
├── scripts/
│   └── download-model.sh # Скачать модель в запущенный контейнер
└── DEPLOY.md             # Развёртывание на Rocky Linux
```
