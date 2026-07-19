#!/usr/bin/env sh
set -eu

attempts="${WAIT_FOR_POSTGRES_ATTEMPTS:-60}"
sleep_seconds="${WAIT_FOR_POSTGRES_SLEEP:-2}"

i=1
while [ "$i" -le "$attempts" ]; do
    if php -r '
        require "vendor/autoload.php";
        $app = require "bootstrap/app.php";
        $app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
        Illuminate\Support\Facades\DB::connection()->getPdo();
    ' >/dev/null 2>&1; then
        exit 0
    fi

    printf 'Waiting for PostgreSQL... (%s/%s)\n' "$i" "$attempts"
    i=$((i + 1))
    sleep "$sleep_seconds"
done

printf 'PostgreSQL is not ready after %s attempts.\n' "$attempts" >&2
exit 1
