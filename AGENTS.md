# Laravel Blueprint

This repository is a Docker-first Laravel template for new projects and microservices. Keep it infrastructure-focused.

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

## Commands

- Bootstrap: `cp .env.example .env && make init`
- Start: `make up`
- Stop: `make down`
- Restart: `make restart`
- Logs: `make logs`
- Shell: `make shell`
- Composer: `make composer ARGS="install"`
- Artisan: `make artisan ARGS="route:list"`
- Migrate: `make migrate`
- Tests: `make test`
- Unit tests: `make test-unit`
- Feature tests: `make test-feature`
- Style check: `make lint`
- Style fix: `make lint-fix`
- Static analysis: `make analyse`
- Full quality gate: `make quality`
- Local CI equivalent: `make ci`

## Architecture

- `app` runs PHP-FPM on PHP 8.5 from the local `laravel-blueprint-app:development` image and includes Composer plus PostgreSQL extensions.
- The development `app` image includes Xdebug. Step debugging works with Zed running on the host (listen mode on port 9003); Xdebug in the container dials out to `host.docker.internal:9003`. Debugging with Zed running inside the Dev Container is currently blocked by an upstream Zed bug (see README "Xdebug in Zed").
- `web` runs Caddy, serves `public/`, blocks hidden files, and forwards PHP requests to `app:9000`.
- `postgres` runs PostgreSQL 18 and stores data in the `postgres-data` named volume.
- `/up` is Laravel's built-in health endpoint.
- Zed uses `.devcontainer/devcontainer.json`; project tasks in `.zed/tasks.json` run through `make`.

## Database

- PostgreSQL is the default database: `DB_CONNECTION=pgsql`.
- The application DB host inside Docker is `postgres`.
- The default app database is `laravel`.
- The test database is `laravel_test`.
- SQLite is not part of the normal project runtime.
- Database-backed infrastructure tables are expected for sessions, cache, and queues.

## Rules

- Do not require local PHP, Composer, PostgreSQL, or Node.js for normal development.
- Host shell commands and Zed project tasks should use `make ...`; devcontainer lifecycle commands use direct container commands.
- Keep Xdebug limited to the Docker development image; do not require local PHP or Xdebug on the developer machine.
- Do not add domain entities, auth scaffolding, payments, frontend starter kits, repositories, services, or DTO layers unless explicitly requested.
- Keep PostgreSQL as the default database.
- Keep Caddy as the web service unless the user asks to change it.
- Replace default local passwords before production use.
- Run `make quality` before handing off changes.
- Do not commit `.env`, runtime logs, framework cache files, or generated view cache files.

## Laravel Boost

Laravel Boost is installed as a dev dependency. Use it for Laravel-specific guidance when available.

The Codex MCP config is `.codex/config.toml` and runs:

```bash
docker compose exec -T app php artisan boost:mcp
```
