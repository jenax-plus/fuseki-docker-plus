FROM aksw/fuseki-vanilla:6.2.0-2

# FUSEKI_HOME build arg is assumed to match that of the base image!
ARG FUSEKI_HOME=/fuseki

ARG FUSEKI_BUILTIN_PLUGINS=${FUSEKI_HOME}/builtin-plugins
ENV FUSEKI_BUILTIN_PLUGINS=${FUSEKI_BUILTIN_PLUGINS}

ENV FUSEKI_USER_PLUGINS=${FUSEKI_BASE}/plugins

# Install curl for downloading plugins
RUN apt-get update && apt-get install -y --no-install-recommends curl gettext-base make \
    && rm -rf /var/lib/apt/lists/*

# Create plugin directories
RUN mkdir -p ${FUSEKI_BUILTIN_PLUGINS} /usr/local/bin

# Download pre-bundled plugins (exectracker, graphql4sparql, jenax-arq-plugins, jenax-serviceenhancer)
RUN curl -LJO --create-dirs --output-dir ${FUSEKI_BUILTIN_PLUGINS}/ \
    "https://github.com/jenax-plus/jena-exectracker/releases/download/v0.7.2/jena-exectracker-fuseki-plugin-0.7.2.jar" && \
    curl -LJO --create-dirs --output-dir ${FUSEKI_BUILTIN_PLUGINS}/ \
    "https://github.com/jenax-plus/graphql4sparql/releases/download/v0.7.0/graphql4sparql-fuseki-plugin-0.7.0.jar" && \
    curl -LJO --create-dirs --output-dir ${FUSEKI_BUILTIN_PLUGINS}/ \
    "https://github.com/Scaseco/jenax/releases/download/v6.1.0-1/jenax-arq-plugins-bundle-6.1.0-1.jar" && \
    curl -LJO --create-dirs --output-dir ${FUSEKI_BUILTIN_PLUGINS}/ \
    "https://github.com/Scaseco/jenax/releases/download/v6.1.0-1/jenax-serviceenhancer-preview-plugin-6.1.0-1.jar" && \
    curl -LJO --create-dirs --output-dir ${FUSEKI_BUILTIN_PLUGINS}/ \
    "https://github.com/jenax-plus/jena-proxy/releases/download/v0.7.1/jena-proxy-fuseki-plugin-0.7.1.jar" && \
    curl -LJO --create-dirs --output-dir ${FUSEKI_BUILTIN_PLUGINS}/ \
    "https://github.com/jenax-plus/jena-inf-light/releases/download/v0.9.0-rc1/jena-inf-fuseki-plugin-0.9.0-rc1.jar"

# Copy plugins CLI with executable permission.
# Plugins CLI is thus available at /usr/local/bin/plugins
# `plugins` is a thin wrapper: it chowns the data dir to WANT_UID:WANT_GID and
# drops privileges via the base image's run-as.sh, then execs plugins-mgr.sh.
COPY --chmod=755 plugins plugins-mgr.sh /usr/local/bin/

# Create the init.d directory and install the entrypoint wrapper that runs
# /fuseki/init.d/*.sh (as root, in lexical order) before handing off to the base
# entrypoint. The image ships no default scripts; users mount their own into
# /fuseki/init.d (see example/init.d/).
RUN mkdir -p ${FUSEKI_HOME}/init.d
COPY --chmod=755 plus-entrypoint.sh ${FUSEKI_HOME}/plus-entrypoint.sh

# Inherited from base:
# VOLUME /fuseki/run

# Override the base image's ENTRYPOINT ["/fuseki/entrypoint.sh"] with our wrapper.
# plus-entrypoint.sh runs /fuseki/init.d/*.sh as root, then execs the base
# entrypoint, which chowns /fuseki/run to WANT_UID:WANT_GID and drops privileges
# via run-as.sh before starting the server.
ENTRYPOINT ["/fuseki/plus-entrypoint.sh"]

