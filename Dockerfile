# syntax=docker/dockerfile:1

# Build stage: compile the workspace natively for the target platform.
FROM node:24-bookworm-slim AS build

ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
    ELECTRON_SKIP_BINARY_DOWNLOAD=1 \
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      git \
      musl-tools \
      python3 \
 && rm -rf /var/lib/apt/lists/*

RUN corepack enable

WORKDIR /app

COPY . .

# The client build embeds a commit hash; .dockerignore excludes .git, so the build receives it here.
ARG DSH_CLIENT_COMMIT_HASH=0000000
ENV DSH_CLIENT_COMMIT_HASH=${DSH_CLIENT_COMMIT_HASH}

RUN pnpm install --frozen-lockfile
RUN pnpm run build:artifacts
RUN pnpm --dir native/system run build:native

# Runtime stage: the built workspace plus the tools DSH expects at runtime.
FROM node:24-bookworm-slim AS runtime

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      bash \
      ca-certificates \
      git \
      procps \
 && rm -rf /var/lib/apt/lists/*

ENV DSH_HOME=/data \
    DSH_PUBLIC_URL=http://localhost:3080/ \
    NODE_ENV=production

WORKDIR /app

COPY --chown=node:node --from=build /app /app
COPY --chmod=755 docker/entrypoint.sh /usr/local/bin/dsh-entrypoint

RUN mkdir -p /data && chown node:node /app /data

USER node

EXPOSE 3080

VOLUME ["/data"]

ENTRYPOINT ["dsh-entrypoint"]
