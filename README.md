# laravel-blueprint

Docker-first Laravel template for new projects and microservices.

This repository is intended to be used as a GitHub Template Repository. It contains infrastructure, tooling, and quality gates only. It intentionally does not include business entities, authentication scaffolding, frontend starter kits, payment integrations, or demo domain code.

## Stack

- Laravel 13.x
- PHP 8.5
- PostgreSQL 18
- Caddy 2.10
- Docker Compose
- Composer 2
- PHPUnit
- Laravel Pint
- PHPStan with Larastan
- Laravel Boost
- GitHub Actions

## Requirements

Install only:

- Git
- Docker
- Docker Compose
- GNU Make

Local PHP, Composer, PostgreSQL, and Node.js are not required.

## Quick Start

```bash
cp .env.example .env
make init
```

`make init` is safe to run repeatedly. It will:

- create `.env` from `.env.example` when missing;
- build Docker images;
- start `app`, `web`, and `postgres`;
- install Composer dependencies inside Docker;
- generate `APP_KEY` when missing;
- wait for PostgreSQL;
- run migrations;
- check `GET /up`;
- print the application URL.

Default URL:

```text
http://localhost:8080
```

## Services

| Service | Image / Build | Purpose |
| --- | --- | --- |
| `app` | `laravel-blueprint-app:development` from `docker/app/Dockerfile` | PHP 8.5 FPM runtime with Composer, PostgreSQL extensions, and Xdebug |
| `web` | `caddy:2.10-alpine` | HTTP server, static files, Laravel routing, FastCGI to `app:9000` |
| `postgres` | `postgres:18` | Local PostgreSQL database with a named volume |

PostgreSQL is available only inside the Compose network by default. It is not published to the host unless you explicitly change `compose.yaml`.

## Database

PostgreSQL is the default and only configured application database.

Important defaults:

```dotenv
DB_CONNECTION=pgsql
DB_HOST=postgres
DB_PORT=5432
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=secret
POSTGRES_TEST_DB=laravel_test
```

The template includes infrastructure migrations for:

- `sessions`, because `SESSION_DRIVER=database`;
- `cache` and `cache_locks`, because `CACHE_STORE=database`;
- `jobs`, `job_batches`, and `failed_jobs`, because `QUEUE_CONNECTION=database`.

Replace default local passwords before using this template for production.

## Caddy

Caddy configuration lives in:

```text
docker/caddy/Caddyfile
```

It serves `public/`, blocks hidden files, supports Laravel routing via `try_files`, and forwards PHP requests to PHP-FPM:

```text
php_fastcgi app:9000
```

## Zed and Dev Container

Project-level Zed files are included:

- `.zed/settings.json`
- `.zed/tasks.json`
- `.zed/debug.json`
- `.devcontainer/devcontainer.json`
- `.devcontainer/compose.yaml`

When the project is opened in Zed, Zed can prompt to reopen it inside the dev container. The devcontainer reuses `compose.yaml`, opens the `app` service at `/var/www/html`, and starts `postgres` plus `web` alongside it.

The `app` service uses the explicit local image name `laravel-blueprint-app:development`. The devcontainer `initializeCommand` builds this image before startup. Its Compose override removes the `build` section only from Zed's merged runtime configuration, preventing Zed from generating an unnecessary local `*-features` image. No global Zed setting or local PHP installation is required.

Zed project tasks are written for the host Zed terminal and call `make`, so they do not require local PHP, Composer, PostgreSQL, or Node.js. Common tasks include:

- `Laravel: init`
- `Laravel: quality`
- `Laravel: test`
- `Laravel: lint`
- `Laravel: analyse`
- `Laravel: migrate`
- `Laravel: health`

The devcontainer lifecycle commands still run direct container commands such as `composer install` and `php artisan migrate --force` after Zed reopens the project inside the container.

Use `make ...` from the host shell or from Zed project tasks. When already inside the devcontainer terminal, use direct commands such as `composer`, `php artisan`, and `vendor/bin/pint`.

## Xdebug in Zed

Xdebug is installed only in the Docker development image. Step debugging works with **Zed running on the host** — you still do not need local PHP, Composer, Node.js, Xdebug, or PostgreSQL. Only Zed itself is installed on the host; PHP always runs in Docker.

The development PHP image loads:

```text
docker/app/xdebug.ini
```

Defaults:

- Xdebug mode is `debug,develop`;
- debugging starts only when triggered;
- the debugger port is `9003`;
- the client host is `host.docker.internal`, so Xdebug inside the container dials back OUT to Zed listening on the host.

### How it works

Xdebug is the client and the IDE is the server: when triggered, Xdebug opens a connection **from the container to the IDE**. Zed runs on the host and listens on port `9003` in pure "listen" mode — that mode uses Zed's bundled Node-based DAP adapter and never spawns PHP, so no local PHP is required. The container reaches the host through `host.docker.internal`, which resolves via Docker Desktop (macOS/Windows) and via the `extra_hosts: host.docker.internal:host-gateway` mapping in `compose.yaml` (Linux).

`.zed/debug.json` maps the container path to your checkout with `"/var/www/html": "$ZED_WORKTREE_ROOT"`, so breakpoints line up regardless of where the project is cloned.

### Recommended workflow (host Zed)

Open the project folder in Zed **on the host** (do not reopen in the Dev Container for debugging), then:

1. Start `docker compose up -d` (or `make up`).
2. Start `PHP: Listen for Xdebug` in Zed's debug panel.
3. Set a breakpoint.
4. Trigger execution:
   - a web request with a trigger, for example `http://localhost:8080/?XDEBUG_TRIGGER=1`; or
   - a test, via the `Xdebug: debug current test (Docker)` task, which runs `vendor/bin/phpunit --filter "$ZED_SYMBOL"` inside the container with `XDEBUG_TRIGGER=1` while Zed listens.

Browser Xdebug helper extensions can also send the `XDEBUG_TRIGGER` cookie/header.

### Zed Dev Container limitation

Running the whole Zed session **inside** the Dev Container and debugging from there is a separate topology (Xdebug would connect to `127.0.0.1` inside the container). Zed 1.11.3 cannot currently wire its PHP Debug Adapter through Docker Dev Containers — it starts the adapter on a dynamic container port, then connects through a different local port and closes the session with `Connection to TCP DAP timeout`. Use the host-Zed workflow above until Zed fixes Dev Container DAP port forwarding; the Dev Container remains fully usable for editing, tasks, and running commands.

This is a known upstream limitation, not a project issue. Tracking:

- [zed-extensions/php#97](https://github.com/zed-extensions/php/issues/97) — debugging into a Dev Container (open, no ETA as of this writing).

When it is fixed, Dev Container step debugging can be re-enabled by setting `xdebug.client_host=127.0.0.1` in `docker/app/xdebug.ini`. No other project change is required.

To check Xdebug from inside the container:

```bash
make shell
php -v
php --ri xdebug
tail -f /tmp/xdebug.log
```

For Zed-side diagnostics, run `dev: open debug adapter logs` from the command palette.

## Environment

Copy and edit:

```bash
cp .env.example .env
```

Common values:

- `APP_URL` controls the displayed local URL.
- `APP_PORT` controls the host HTTP port.
- `WWWUSER` and `WWWGROUP` help avoid root-owned files from bind mounts.
- `DB_*` and `POSTGRES_*` configure Laravel and the PostgreSQL container.

The `.env` file is ignored by Git.

## Make Commands

```bash
make help
make init
make build
make up
make down
make restart
make stop
make logs
make ps
make shell
make composer ARGS="install"
make artisan ARGS="route:list"
make migrate
make migrate-fresh
make test
make test-unit
make test-feature
make lint
make lint-fix
make analyse
make quality
make ci
make clean
```

Commands that delete data, such as `make migrate-fresh` and `make clean`, ask for confirmation.

## Quality Gates

Run the full local check:

```bash
make quality
```

It runs:

- Laravel Pint in check mode;
- PHPStan with Larastan;
- PHPUnit.

`make ci` is an alias for the same local quality gate.

## Laravel Boost

Laravel Boost is installed as a development dependency.

Project files:

- `boost.json`
- `.codex/config.toml`
- `.agents/skills/laravel-blueprint/SKILL.md`
- `AGENTS.md`

The Codex MCP entry runs Boost through Docker Compose:

```bash
docker compose exec -T app php artisan boost:mcp
```

After dependency updates, refresh Boost resources with:

```bash
make artisan ARGS="boost:update --discover"
```

## CI

The CI workflow is in:

```text
.github/workflows/ci.yml
```

It runs on:

- pull requests;
- pushes to `main`;
- manual dispatch.

It performs:

- Composer validation;
- dependency install with cache;
- dependency audit;
- PostgreSQL migrations;
- Laravel Pint;
- PHPStan/Larastan;
- PHPUnit;
- Docker development image build.

## Release Image

The release workflow is in:

```text
.github/workflows/release.yml
```

It runs on tags matching `v*` or manual dispatch, builds the production Docker image, and publishes it to GitHub Container Registry using `GITHUB_TOKEN`.

It does not deploy to an unknown server.

## Notes for Template Users

After creating a new repository from this template:

- update `composer.json` package name and description;
- update `APP_NAME` in `.env.example` if needed;
- replace default database passwords before production;
- add project-specific domain code only when the new application requires it;
- keep `make quality` green before opening pull requests.
