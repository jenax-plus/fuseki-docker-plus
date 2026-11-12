#!/bin/sh
# plus-entrypoint.sh
#
# Thin wrapper around the base image's entrypoint that adds an `init.d` hook.
#
# Any *.sh scripts in ${FUSEKI_INIT_D_DIR} (default /fuseki/init.d) are executed,
# in lexical (filename) order, AS ROOT, before the base entrypoint runs. This
# happens before the base image's chown + privilege drop, so init.d scripts can
# freely create/rename/chown files under the data volume.
#
# The base entrypoint (/fuseki/entrypoint.sh) then does its usual chown of the
# data volume to WANT_UID:WANT_GID and drops privileges before starting the
# server.
#
# This is a pure mechanism: the image ships no default init.d scripts. A user
# (or a docker-compose mount) provides the scripts. See example/init.d/.
#
# Fail-fast: a non-zero exit from an init.d script aborts container startup.

set -eu

INIT_D_DIR="${FUSEKI_INIT_D_DIR:-/fuseki/init.d}"

if [ -d "$INIT_D_DIR" ]; then
    for script in "$INIT_D_DIR"/*.sh; do
        # No .sh present -> glob stays literal; guard against that.
        [ -e "$script" ] || continue
        echo "[fuseki-plus] init.d: running $(basename "$script")" >&2
        "$script"
    done
fi

exec /fuseki/entrypoint.sh "$@"
