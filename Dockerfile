FROM codercom/code-server:4.109.2-39

USER root

ARG TTYD_VERSION=1.7.7

RUN dnf install -y --setopt=install_weak_deps=False \
        supervisor \
        git \
        curl \
        ca-certificates \
        bash \
        openssh-clients \
        python3-pip \
        nodejs \
        npm \
    && dnf clean all \
    && rm -rf /var/cache/dnf /var/cache/yum;
RUN python3 -m pip install --no-cache-dir aider-chat \
    && npm install -g @openai/codex @qwen-code/qwen-code \
    && if command -v qwen >/dev/null 2>&1; then ln -sf "$(command -v qwen)" /usr/local/bin/qwen-code; fi \
    && arch="$(uname -m)" \
    && case "${arch}" in \
      x86_64|amd64) ttyd_asset="ttyd.x86_64" ;; \
      aarch64|arm64) ttyd_asset="ttyd.aarch64" ;; \
      *) echo "Unsupported arch for ttyd: ${arch}" >&2; exit 1 ;; \
    esac \
    && curl -fsSL -o /usr/local/bin/ttyd "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/${ttyd_asset}" \
    && chmod 0755 /usr/local/bin/ttyd

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY agent-shell.sh /usr/local/bin/agent-shell
COPY stack-relaunch.sh /usr/local/bin/stack-relaunch
COPY config/code-server/config.yaml /home/coder/.config/code-server/config.yaml
COPY config/code-server/config.yaml /opt/devbox-defaults/code-server/config.yaml
COPY config/code-server/User/settings.json /home/coder/.local/share/code-server/User/settings.json
COPY config/code-server/User/settings.json /opt/devbox-defaults/code-server/User/settings.json
COPY config/agent /opt/devbox-defaults/agent

RUN chmod 0755 /usr/local/bin/agent-shell \
    && chmod 0755 /usr/local/bin/stack-relaunch \
    && mkdir -p \
      /workspace \
      /home/coder/.config/code-server \
      /home/coder/.config/agent \
      /home/coder/.local \
      /home/coder/.local/share/code-server/User \
      /home/coder/.codex \
      /home/coder/.qwen \
      /opt/devbox-defaults/code-server/User \
    && ln -sf /home/coder/.config/agent/codex/config.toml /home/coder/.codex/config.toml \
    && ln -sf /home/coder/.config/agent/qwen/settings.json /home/coder/.qwen/settings.json \
    && ln -sf /home/coder/.config/agent/qwen/.env /home/coder/.qwen/.env \
    && ln -sf /home/coder/.config/agent/aider/.aider.conf.yml /home/coder/.aider.conf.yml \
    && chown -R coder:coder /workspace /home/coder/.config /home/coder/.local /home/coder/.codex /home/coder/.qwen /usr/local/bin/agent-shell /usr/local/bin/stack-relaunch

USER coder
WORKDIR /workspace

ENTRYPOINT []
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
