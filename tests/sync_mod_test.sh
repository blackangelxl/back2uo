#!/usr/bin/env bash
set -euo pipefail

SOURCE="$(realpath "$(pwd)/../dist-test/back2uo")"
VOLUME="back2uo_test"

if ! docker volume inspect "$VOLUME" >/dev/null 2>&1; then
    echo "Volume '$VOLUME' existiert nicht. Erstelle es ..."
    docker volume create "$VOLUME"
else
    echo "Volume '$VOLUME' existiert bereits."
fi

echo "Synchronisiere ${SOURCE} -> ${VOLUME}"
MSYS_NO_PATHCONV=1 docker run --rm \
    --mount "type=bind,source=${SOURCE},target=/src,readonly" \
    --mount "type=volume,source=${VOLUME},target=/dest" \
    alpine:3.24 \
    sh -c 'apk add --no-cache rsync >/dev/null && rsync -av --chown=1000:1000 --itemize-changes /src/ /dest/'
echo "Synchronisierung abgeschlossen."