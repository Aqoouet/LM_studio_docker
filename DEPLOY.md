# Deploy on Rocky Linux Server

## Requirements
- 30+ CPU cores, 400+ GB RAM, no GPU
- Rocky Linux 8/9

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
docker compose up -d --build
```

Wait until lmstudio is healthy (~2-3 min):

```bash
docker compose ps
```

## 3. Download model

```bash
./scripts/download-model.sh "https://huggingface.co/Qwen/Qwen2.5-72B-Instruct-GGUF@q4_k_m"
```

~45 GB download. For higher quality (77 GB): replace `q4_k_m` with `q8_0`.

## 4. Open chat UI

```
http://<server-ip>:3000
```

---

## Firewall (if needed)

```bash
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --reload
```
