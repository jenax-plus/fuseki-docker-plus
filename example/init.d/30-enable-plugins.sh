#!/bin/sh
# 30-enable-plugins.sh
#
# Enable the plugins this example's configuration requires, using the image's
# `plugins` CLI. The CLI itself drops privileges to WANT_UID:WANT_GID (via the
# base image's run-as.sh) and copies each jar into ${FUSEKI_BASE}/extra/, which
# is the classpath directory Fuseki loads plugins from.
#
# Edit this list to match the plugins YOUR configuration actually uses. To turn a
# plugin off, remove it from this list (and optionally `docker compose exec fuseki
# plugins disable <file>` for the running instance).
set -eu

plugins enable \
    jena-exectracker-fuseki-plugin-0.7.2.jar \
    graphql4sparql-fuseki-plugin-0.7.0.jar \
    jenax-arq-plugins-bundle-6.1.0-1.jar \
    jenax-serviceenhancer-preview-plugin-6.1.0-1.jar \
    jena-proxy-fuseki-plugin-0.7.1.jar \
    jena-inf-fuseki-plugin-0.9.0-rc1.jar
