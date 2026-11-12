# fuseki-docker-plus

Customized Apache Jena Fuseki Docker Image with pre-installed plugins and
a simple plugin manager for self-contained plugin JARs.
The plugin JARs bundled with the image must be enabled explicitly with a [one-liner](example).
Otherwise, you just get a [Vanilla Fuseki Setup](https://github.com/AKSW/fuseki-docker-vanilla).

## Features

- Base: [aksw/fuseki-vanilla:6.2.0-2](https://github.com/AKSW/fuseki-docker-vanilla)
- Pre-installed plugins in `/fuseki/builtin-plugins/`:
  - [jena-exectracker](https://github.com/jenax-plus/jena-exectracker) (v0.7.2)
  - [graphql4sparql](https://github.com/jenax-plus/graphql4sparql) (v0.7.0)
  - [jenax-arq-plugins](https://github.com/Scaseco/jenax) (v6.1.0-1)
  - [jenax-serviceenhancer](https://github.com/Scaseco/jenax) (v6.1.0-1)
  - [jena-proxy](https://github.com/jenax-plus/jena-proxy) (v0.7.1)
  - [jena-inf-light](https://github.com/jenax-plus/jena-inf-light) (v0.9.0-rc1)
- Plugin management via CLI: `plugins`
- Dynamic plugin installation from URLs
- Volume-based plugin persistence

## Quick Start

### Build the Image

```bash
make build
```

Versions are defined in `build.vars` (the single source of truth): `VANILLA_VERSION` is synced into the Dockerfile's `FROM` line and `IMAGE_TAG` is used as the image tag. Run `make sync-version` to propagate both into this README, `example/docker-compose.yaml`, and the tests before building or pushing. To bump the version, edit `build.vars` and re-run.

### Run with Docker Compose

```bash
docker compose up -d
```

### Docker Compose Usage (Recommended)

Set the target user in `.env` (create it from `.env.example`):

```bash
cp .env.example .env
# edit .env:  WANT_UID=$(id -u)   WANT_GID=$(id -g)
docker compose up -d
```

`docker compose` picks up `WANT_UID`/`WANT_GID` from `.env` automatically.
`DOCKER_GID` is optional: it is only needed if you use the Qlever Fuseki Plugin,
which binds the life-cycle of a dockerized Qlever instance to that of the Fuseki server.

#### `init.d` startup hooks

The image's entrypoint runs every `*.sh` in `/fuseki/init.d` (in lexical order)
**as root** before it chowns the data volume and drops privileges. Mount your own
scripts into that directory to prepare the runtime — for example: copy host-supplied
config into the data volume, link a read-only resources mount, and pre-enable the
plugins your config needs.

The [`example/`](example/) folder demonstrates this pattern: it stages read-only
config and resources instead of nested bind mounts (so Docker leaves no
root-owned files behind in the data volume) and enables the plugins its config
uses — so the server starts with a working setup out of the box.

## Running as a Non-Root User

The image starts as root, chowns the data volume (`/fuseki/run`) to the requested
UID:GID, then drops privileges via `setpriv` before starting the server. Set the
target user with:

- `WANT_UID` — user ID to run Fuseki as (default: `1000`)
- `WANT_GID` — group ID to run Fuseki as (default: `1000`)

The UID/GID do not need to exist in the image's `/etc/passwd`.

> **Note:** Do not set `user:` in compose (or `--user` with `docker run`). The
> entrypoint needs root privileges for the chown phase; setting `user:` would break it.
>
> Note that read-only mounts (e.g. a `:ro` resources directory) are skipped by the
> chown phase and must stay readable by `WANT_UID` — so `WANT_UID` should be able to
> read those files (matching the host user that owns them is the simplest choice).
> The writable data volume, on the other hand, is chowned to `WANT_UID` for you.

The `example/` folder includes a complete setup driven by the `init.d` hook: it stages read-only config and resources and pre-enables the plugins its config needs.

#### Plugin Management

```
Usage: plugins <command> [options]

Commands:
  list              List available plugins
  status            List all plugins with installation status
  add <url>         Download plugin from URL to /fuseki/run/plugins/
  remove <name>     Remove plugin from /fuseki/run/plugins/ and /fuseki/run/extra/
  enable <names>    Copy plugin(s) to /fuseki/run/extra/ (activate)
  disable <names>   Remove plugin(s) from /fuseki/run/extra/ (deactivate)
```


```bash
docker compose run --rm --entrypoint plugins fuseki list
docker compose run --rm --entrypoint plugins fuseki status
docker compose run --rm --entrypoint plugins fuseki add https://example.com/plugin-1.0.0.jar
docker compose run --rm --entrypoint plugins fuseki enable plugin-1.0.0.jar anotherplugin.jar
docker compose run --rm --entrypoint plugins fuseki disable plugin-1.0.0.jar anotherplugin.jar
docker compose run --rm --entrypoint plugins fuseki remove plugin-1.0.0.jar
```

Replace `fuseki` with your actual service name if different.

### Plain Docker Usage

The usage without compose is similar. Instead of the service name you need to specify the image name:

List available plugins:
```bash
docker run --rm --entrypoint plugins aksw/fuseki-plus:6.2.0-3 list
```

Check plugin status:
```bash
docker run --rm --entrypoint plugins aksw/fuseki-plus:6.2.0-3 status
```

## Directory Structure of a Container

| Path | Purpose | In Volume? |
|------|---------|------------|
| `/fuseki/builtin-plugins/` | Pre-bundled plugins (in image) | No |
| `/fuseki/init.d/` | Startup scripts, run as root before the server starts | No (mount it) |
| `/fuseki/user-input/` | Staging area for host-supplied config (mounted read-only) | No (mount it) |
| `/fuseki/resources/` | Staging area for static resources (mounted read-only) | No (mount it) |
| `/fuseki/run/plugins/` | User-downloaded plugins | Yes |
| `/fuseki/run/extra/` | Active plugins (copied here) | Yes |
| `/fuseki/run/config.ttl` | Fuseki configuration (copied in from `user-input`) | Yes |

## Versioning

Image tag format: `aksw/fuseki-plus:<fuseki-version>-<build>`

Versions are defined in `build.vars` (the single source of truth):

- `VANILLA_VERSION` — base image tag (`aksw/fuseki-vanilla:<tag>`), synced into the Dockerfile
- `IMAGE_TAG` — this image's tag, e.g. `6.2.0-3` (set in `build.vars`, independent of the vanilla version)

`make sync-version` propagates both into the Dockerfile, this README, `example/docker-compose.yaml`, and the tests.

Current image version: **6.2.0-3** (vanilla 6.2.0-2)

Release tag: `aksw/fuseki-plus:6.2.0-3`

| Version   | Changes |
|-----------|---------|
| 6.2.0-3   | Added `init.d` startup hooks: the entrypoint runs `/fuseki/init.d/*.sh` as root before the privilege drop. The example now stages read-only config/resources instead of nested bind mounts (no more root-owned placeholder files or busybox init service) and pre-enables its plugins via `init.d`; `docker compose` reads `WANT_UID`/`WANT_GID` from `.env` (no `dc` wrapper). |
| 6.2.0-2   | Adopted the base image's `WANT_UID`/`WANT_GID` privilege model: compose examples no longer set `user:`; the `plugins` CLI now chowns the data volume and drops to the target user via the base image's `run-as.sh` before running. |
| 6.2.0-1   | Upgrade to jena 6.2.0. Fixed priority issue that caused `jena-exectracker` to not be able to track query executions for a `jena-proxy` dataset. |
| 6.1.0-3   | Added [Proxy Plugin](https://github.com/jenax-plus/jena-proxy) which supports Datasets over HTTP(S) SPARQL endpoints. |
| 6.1.0-2   | Updated [ExecTracker Plugin](https://github.com/jenax-plus/jena-exectracker/releases/tag/v0.7.1) which features a nicer UI. |
| 6.1.0     | Changed `FUSEKI_BASE` from  `/app/fuseki` to `/fuseki`. |
| 6.1.0-rc1 | Initial version. |

## Requirements

- Docker
- [bats](https://github.com/bats-core/bats-core) and [bats-assert](https://github.com/bats-core/bats-assert) (install via `sudo apt install bats bats-assert`)

## License

This project is licensed under the Apache License 2.0. See [LICENSE](LICENSE) for details.

