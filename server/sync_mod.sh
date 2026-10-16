#!/usr/bin/env bash
set -euo pipefail

SOURCE="$(pwd)/../dist/back2uo"
VOLUME="back2uo"

echo "Synchronisiere ${SOURCE} -> ${VOLUME}"

docker run --rm \
  -v "${SOURCE}:/src:ro" \
  -v "${VOLUME}:/dest" \
  alpine:3.24 sh -c '
    apk add --no-cache rsync >/dev/null
    rsync -av --chown=1000:1000 --itemize-changes /src/ /dest/
  '

echo "Synchronisierung abgeschlossen."