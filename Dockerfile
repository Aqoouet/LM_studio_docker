FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LMS_INSTALL_DIR=/root/.lmstudio

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

RUN curl -fsSL https://lmstudio.ai/install.sh | bash

ENV PATH="${LMS_INSTALL_DIR}/bin:${PATH}"

VOLUME ["/root/.lmstudio/models"]

EXPOSE 1234

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
