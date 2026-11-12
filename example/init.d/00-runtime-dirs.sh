#!/bin/sh
# 00-runtime-dirs.sh
#
# Ensure the standard Fuseki runtime subdirectories exist under the data volume.
# Runs as root during startup; the base image's chown phase fixes ownership to
# WANT_UID:WANT_GID afterwards. This replaces the old `dc` wrapper's host-side
# `mkdir -p run/configuration run/security run/extra`.
set -eu

BASE="${FUSEKI_BASE:-/fuseki/run}"
mkdir -p \
    "${BASE}/configuration" \
    "${BASE}/security" \
    "${BASE}/extra" \
    "${BASE}/logs"
