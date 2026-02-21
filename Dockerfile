FROM codercom/code-server:4.109.2-39

USER root

ARG TTYD_VERSION=1.7.7

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      supervisor \
      git \
      curl \
      ca-certificates \
      bash \
      openssh-client \
      python3 \
      python3-pip \
      nodejs \
      npm \
    && python3 -m pip install --no-cache-dir aider-chat \
    && npm install -g @openai/codex @anthropic-ai/claude-code \
    && arch="$(uname -m)" \
    && case "${arch}" in \
      x86_64|amd64) ttyd_asset="ttyd.x86_64" ;; \
      aarch64|arm64) ttyd_asset="ttyd.aarch64" ;; \
      *) echo "Unsupported arch for ttyd: ${arch}" >&2; exit 1 ;; \
    esac \
    && curl -fsSL -o /usr/local/bin/ttyd "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/${ttyd_asset}" \
    && chmod 0755 /usr/local/bin/ttyd \
    && rm -rf /var/lib/apt/lists/*

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY agent-shell.sh /usr/local/bin/agent-shell
COPY stack-relaunch.sh /usr/local/bin/stack-relaunch
COPY config/code-server/config.yaml /home/coder/.config/code-server/config.yaml

RUN chmod 0755 /usr/local/bin/agent-shell \
    && chmod 0755 /usr/local/bin/stack-relaunch \
    && mkdir -p /workspace /home/coder/.config/code-server /home/coder/.config/agent /home/coder/.local \
    && chown -R coder:coder /workspace /home/coder/.config /home/coder/.local /usr/local/bin/agent-shell /usr/local/bin/stack-relaunch

USER coder
WORKDIR /workspace

CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
