# Example Fuseki Setup with Multiple Custom Plugins

A working example of [fuseki-docker-plus](../README.md) that wires up a
read-only config, static resources, and several plugins entirely through the
image's `init.d` hook — no manual plugin-enabling step required.

## Layout

| Path | Role | In a volume? |
|------|------|--------------|
| `input/` | Host-supplied config (`config.ttl`, `passwd.txt`, `shiro.ini`, `configuration/*.ttl`) | read-only mount |
| `resources/` | Static inputs (ontology, graphql schema, `.ttl`) | read-only mount |
| `run/` | Writable data volume (TDB2 databases, logs, active plugins, copied config) | read-write mount |
| `init.d/` | Startup scripts, run as root before the server starts | read-only mount |

The `input/` folder **mirrors the writable-config portion of `run/`**:
`input/config.ttl` → `run/config.ttl`, `input/configuration/*.ttl` →
`run/configuration/*.ttl`, and so on.

## Quick start

```bash
# 1. Configure the target user (defaults to 1000:1000; set it to your host user)
cp .env.example .env
#    edit .env: WANT_UID=$(id -u)  WANT_GID=$(id -g)

# 2. Start
docker compose up -d

# 3. Check
docker compose logs -f fuseki        # init.d output, then the server
curl 'http://localhost:3030'         # Fuseki UI
```

That's it. `docker compose` reads `WANT_UID`/`WANT_GID` from `.env`
automatically — no wrapper script needed.

## What happens on start

The image's entrypoint runs the scripts in `init.d/` (in lexical order) **as
root**, then chowns the data volume to `WANT_UID:WANT_GID` and drops privileges
before starting the server:

1. `00-runtime-dirs.sh` — creates the standard runtime subdirectories.
2. `10-copy-config.sh` — copies `input/` into `run/`, overwriting every start.
3. `20-link-resources.sh` — links `run/resources -> ../resources` (the read-only
   resources mount), so the config's `/fuseki/run/resources/...` paths resolve.
4. `30-enable-plugins.sh` — enables the plugins this config uses, via the `plugins`
   CLI.

Because config and resources are staged and linked rather than nested-mounting
files *into* the data volume, Docker never leaves root-owned placeholder files
behind in `run/`.

## Config is a source of truth on the host

`input/` is copied **in** on every start. Edits you make on the host are
re-applied on the next restart; edits made *inside* the container (e.g. through
the admin UI) are **not** written back to the host. To change config, edit the
files in `input/` and `docker compose restart fuseki`.

## Using a different set of plugins

Edit `init.d/30-enable-plugins.sh` and list only the plugin jars you need:

```bash
docker compose run --rm fuseki plugins list     # available jars
```

The bundled jars live in `/fuseki/builtin-plugins/` inside the image; enabling
copies them into `run/extra/` (the classpath directory Fuseki loads from).

## LDAP authentication (optional)

The read-only `input/` defaults use basic auth (`config.ttl` + `shiro.ini`).
For LDAP, point `input/` at the LDAP variants and build the truststore:

```bash
cp config-ldap.ttl input/config.ttl
cp shiro-ldap.ini  input/shiro.ini
./build-truststore.sh        # populates run/security/ldap-truststore.jks
docker compose up -d
```

> `./build-truststore.sh` runs `keytool` inside a `docker compose exec`, so it
> needs the server container to exist.

## Plain docker usage

Everything above also works without compose. Instead of the `fuseki` service
name, use the image name, and mount the same paths:

```bash
docker run --rm --entrypoint plugins \
  -v "$PWD/run:/fuseki/run" -v "$PWD/input:/fuseki/user-input:ro" \
  -e WANT_UID="$(id -u)" -e WANT_GID="$(id -g)" \
  aksw/fuseki-plus:6.2.0-3 list
```
