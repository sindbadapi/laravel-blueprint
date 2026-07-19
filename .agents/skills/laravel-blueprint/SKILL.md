---
name: laravel-blueprint
description: Work on this Docker-first Laravel blueprint using Laravel Boost and project quality tools.
---

Use Docker Compose as the runtime boundary. Do not assume local PHP, Composer, Node.js, or PostgreSQL.

The stack is Laravel 13, PHP 8.5, PostgreSQL 18, Caddy 2.10, Composer 2, PHPUnit, Pint, PHPStan/Larastan, and Laravel Boost.
The Docker development image also includes Xdebug. Step debugging targets Zed running on the host (listen mode, port 9003); Xdebug dials out to `host.docker.internal:9003`. Debugging with Zed inside the Dev Container is blocked by an upstream Zed bug (see README "Xdebug in Zed").

Before changing application behavior, inspect the relevant Laravel version guidance through Laravel Boost when available.

Prefer these commands:

- `make init` to bootstrap the project.
- `make artisan ARGS="..."` for Artisan commands.
- `make composer ARGS="..."` for Composer commands.
- `make quality` before finishing changes.

Zed project tasks in `.zed/tasks.json` are host-oriented and should call `make ...`. Devcontainer lifecycle commands may use direct container commands such as `composer` and `php artisan`.

Project rules:

- Keep PostgreSQL as the default database.
- Keep Caddy as the web service.
- Keep the template infrastructure-focused.
- Keep Xdebug in the development image only; do not require local PHP or Xdebug.
- Do not add domain models, authentication scaffolding, payments, example business entities, frontend starter kits, repositories, services, or DTO layers unless explicitly requested.
- Do not commit `.env`, logs, framework cache files, generated views, or secrets.
