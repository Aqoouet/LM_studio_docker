FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
# LM Studio is NOT installed inside the image. Install it once on the host filer:
#   LMS_INSTALL_DIR=/filer/users/rymax1e/lmstudio bash <(curl -fsSL https://lmstudio.ai/install.sh)
# Then docker-compose bind-mounts that filer path to /root/.lmstudio at runtime.
# This keeps the image ~200 MB and avoids writing ~3 GB of CUDA libs onto the host root fs.
ENV LMS_INSTALL_DIR=/home/user/.lmstudio

RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    bash \
    libatomic1 \
    libgomp1 \
    gcc \
    && rm -rf /var/lib/apt/lists/*

COPY scripts/mlockall_preload.c /tmp/mlockall_preload.c
RUN gcc -shared -fPIC -o /usr/local/lib/mlockall_preload.so /tmp/mlockall_preload.c \
    && rm /tmp/mlockall_preload.c

ENV HOME=/home/user
ENV PATH="${LMS_INSTALL_DIR}/bin:${PATH}"

# lms binary writes $HOME/.lmstudio-home-pointer at startup.
# Create /home/user with open permissions so UID 1266823379 can write there.
RUN mkdir -p /home/user && chmod 777 /home/user

EXPOSE 1234

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
