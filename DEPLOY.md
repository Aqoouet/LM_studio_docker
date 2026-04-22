# Deploy on Rocky Linux Server

## Requirements
- 30+ CPU cores, 400+ GB RAM, no GPU
- Rocky Linux 8/9
- Existing GGUF models on host path: `/expert_scratch/lmstudio-models`

---

## 1. Install Docker

```bash
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker $USER && newgrp docker
```

## 2. Clone and start

```bash
git clone git@github.com:Aqoouet/LM_studio_docker.git && cd LM_studio_docker
cp .env.example .env
# start.sh blocks startup if swap is in use and autoloads 2 models:
#   lmstudio-community/Qwen3.6-35B-A3B-GGUF
#   lmstudio-community/Qwen3-4B-Instruct-2507-GGUF
./start.sh
```

Wait until both APIs are healthy (~2-3 min):

```bash
docker compose ps
```

## 3. Verify APIs

```bash
curl -fsS http://127.0.0.1:1234/v1/models
curl -fsS http://127.0.0.1:1235/v1/models
```

## 4. Tuning for concurrency, CPU, and RAM limit

```bash
# example
sed -i 's/^LMS_MAX_CONCURRENT=.*/LMS_MAX_CONCURRENT=8/' .env
sed -i 's/^LMS_THREADS=.*/LMS_THREADS=32/' .env
sed -i 's/^LMS_CONTAINER_MAX_RAM=.*/LMS_CONTAINER_MAX_RAM=180g/' .env
docker compose up -d
```

## 5. Verify loaded model path

```bash
docker logs --tail 100 llama-api
```

---

## Troubleshooting

- Container restarts immediately with health failure:
  - Check logs: `docker logs --tail 200 llama-api`
  - Confirm both model dirs exist under primary or fallback root:
    - `lmstudio-community/Qwen3.6-35B-A3B-GGUF`
    - `lmstudio-community/Qwen3-4B-Instruct-2507-GGUF`
- start blocked due to swap usage:
  - `./start.sh` exits if swap is in use by design.
  - Disable swap usage before start (`sudo swapoff -a`).
- API not reachable:
  - Check `API_PORT` in `.env` and firewall for port 1234.

---

## Firewall (if needed)

```bash
sudo firewall-cmd --permanent --add-port=1234/tcp
sudo firewall-cmd --reload
```
