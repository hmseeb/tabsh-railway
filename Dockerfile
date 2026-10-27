# tabsh for Railway: the upstream release binary (web UI embedded) behind Caddy.
# Caddy adds the password and rewrites Host, because tabsh refuses any DNS Host
# header (its DNS-rebinding guard) and has no switch to allow one.
FROM caddy:2.10 AS caddy

FROM node:22-trixie-slim
ARG TARGETARCH
ARG TABSH_VERSION=1.5.1
ARG SHA_AMD64=664a5a2d8ef65c590e90ab67f6e22b15b644ea0deb5be9a6530189ba77ae3d56
ARG SHA_ARM64=c8c1d3d36a46fa6c093c9dff4c2c2e8640a8b8e875f73441fbc0c5bd0fd2886b
LABEL org.opencontainers.image.source="https://github.com/hmseeb/tabsh-railway"
LABEL org.opencontainers.image.version="${TABSH_VERSION}"

# A usable dev box: agents need git, a shell, and sudo to install their own tools.
RUN apt-get update \
    && apt-get install -y --no-install-recommends bash ca-certificates curl git less openssh-client procps sudo vim-tiny \
    && rm -rf /var/lib/apt/lists/* \
    && echo 'node ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/node && chmod 440 /etc/sudoers.d/node

RUN set -eu; \
    case "$TARGETARCH" in amd64) a=x86_64 s=$SHA_AMD64 ;; arm64) a=aarch64 s=$SHA_ARM64 ;; *) exit 1 ;; esac; \
    f=tabsh-v${TABSH_VERSION}-$a-unknown-linux-gnu; \
    curl -fsSLo /tmp/t.tgz https://github.com/Blaise1030/tabsh/releases/download/v${TABSH_VERSION}/$f.tar.gz; \
    echo "$s  /tmp/t.tgz" | sha256sum -c -; \
    tar -xzf /tmp/t.tgz -C /tmp; install -m 755 /tmp/$f/tabsh /usr/local/bin/tabsh; rm -rf /tmp/t.tgz /tmp/$f

# Agents ready on first boot (tabsh's default new-card command is `claude {prompt}`).
# Installed to /usr/local, outside the volume; `npm i -g` from a shell installs to
# /data/home/.npm-global, which is earlier on PATH, so upgrades win and persist.
RUN npm i -g --prefix /usr/local @anthropic-ai/claude-code @openai/codex && npm cache clean --force

# tabsh starts login shells, and Debian's /etc/profile resets PATH: put the
# volume's npm and ~/.local bins back so installed agents are found.
RUN echo 'export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"' > /etc/profile.d/tabsh-path.sh

COPY --from=caddy /usr/bin/caddy /usr/local/bin/caddy
COPY Caddyfile /etc/caddy/Caddyfile
COPY boot.sh /usr/local/bin/boot.sh
RUN chmod 755 /usr/local/bin/boot.sh

ENV PORT=8080 TABSH_USER=admin TABSH_NO_BROWSER=1 SHELL=/bin/bash \
    HOME=/data/home NPM_CONFIG_PREFIX=/data/home/.npm-global \
    PATH=/data/home/.npm-global/bin:/data/home/.local/bin:$PATH
EXPOSE 8080
CMD ["/usr/local/bin/boot.sh"]
