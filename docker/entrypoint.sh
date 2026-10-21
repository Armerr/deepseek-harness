#!/bin/sh
# Start the DSH Web UI when the container receives no command arguments.
# DSH rejects wildcard binds, so the listener uses the container's own address.

set -eu

BIN=/app/apps/cli/lib/bin.js

if [ "$#" -gt 0 ]; then
  exec node "$BIN" "$@"
fi

if [ -z "${DSH_HOST:-}" ]; then
  DSH_HOST="$(node -e 'const os = require("node:os"); for (const list of Object.values(os.networkInterfaces())) for (const addr of list || []) if (addr.family === "IPv4" && !addr.internal) { console.log(addr.address); process.exit(0) }')"
fi
if [ -z "${DSH_HOST:-}" ]; then
  DSH_HOST=127.0.0.1
fi

set -- --profile web --no-open --host "$DSH_HOST"

if [ -n "${DSH_PUBLIC_URL:-}" ]; then
  set -- "$@" --public-url "$DSH_PUBLIC_URL"
fi

if [ -n "${DSH_TRUSTED_HOST:-}" ]; then
  for authority in $DSH_TRUSTED_HOST; do
    set -- "$@" --trusted-host "$authority"
  done
fi

exec node "$BIN" "$@"
