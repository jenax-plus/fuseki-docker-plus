#!/bin/sh
# 20-link-resources.sh
#
# Expose the read-only resources mount at ${FUSEKI_BASE}/resources via a relative
# symlink, instead of a nested bind mount.
#
# Convention: resources is mounted at the top level (/fuseki/resources), a sibling
# of the data volume (/fuseki/run). A relative symlink run/resources -> ../resources
# resolves to /fuseki/resources inside the container, and - because run/ is itself
# bind-mounted - to ../resources on the host as well.
#
# Because the mount is top-level (not nested inside the data volume), the kernel
# never creates a root-owned placeholder inside the data volume for resources.
set -eu

BASE="${FUSEKI_BASE:-/fuseki/run}"
RES="/fuseki/resources"
LINK="${BASE}/resources"

if [ ! -d "$RES" ]; then
    echo "[fuseki-plus] 20-link-resources: $RES not mounted; skipping" >&2
    exit 0
fi

if [ -L "$LINK" ]; then
    echo "[fuseki-plus] 20-link-resources: $LINK is already a symlink; ok" >&2
elif [ -e "$LINK" ]; then
    # A leftover real path from the old nested-mount setup. If it's an empty
    # directory, migrate it to the symlink automatically; if it holds data,
    # warn and leave it in place (never clobber real data).
    if [ -d "$LINK" ] && [ -z "$(ls -A "$LINK" 2>/dev/null)" ]; then
        rm -rf "$LINK"
        ln -s ../resources "$LINK"
        echo "[fuseki-plus] 20-link-resources: replaced empty legacy dir $LINK with symlink -> ../resources" >&2
    else
        echo "[fuseki-plus] 20-link-resources: WARN: $LINK exists and is not an empty directory; leaving it in place. To use the symlink, empty/remove it and restart." >&2
    fi
else
    ln -s ../resources "$LINK"
    echo "[fuseki-plus] 20-link-resources: created $LINK -> ../resources" >&2
fi
