#!/bin/sh
# 10-copy-config.sh
#
# Copy host-supplied configuration into the data volume, overwriting every start.
#
# The read-only staging mount ${FUSEKI_USER_INPUT} (default /fuseki/user-input)
# mirrors the writable-config portion of the data volume (config.ttl, passwd.txt,
# shiro.ini, configuration/*.ttl). Copying it in makes the HOST the source of
# truth:
#   - edits are made on the host and re-applied on every (re)start;
#   - edits made inside the container (e.g. via the admin UI) do NOT propagate
#     back to the host.
#
# Using a staging mount + copy (instead of nested bind mounts of individual files
# into the data volume) is what avoids Docker's root-owned placeholder files.
set -eu

INPUT="${FUSEKI_USER_INPUT:-/fuseki/user-input}"
DEST="${FUSEKI_BASE:-/fuseki/run}"

if [ ! -d "$INPUT" ]; then
    echo "[fuseki-plus] 10-copy-config: $INPUT not mounted; skipping config copy" >&2
    exit 0
fi

# `cp -a INPUT/. DEST/` merges and overwrites files from INPUT into DEST. It does
# NOT delete files in DEST that are absent from INPUT, so runtime-generated state
# (databases/, extra/, logs/, the lucene index, ...) is preserved.
cp -a "${INPUT}/." "${DEST}/"
echo "[fuseki-plus] 10-copy-config: copied ${INPUT} -> ${DEST}" >&2
