#!/usr/bin/env sh
set -eu

php -r '
$env = is_file(".env") ? parse_ini_file(".env", false, INI_SCANNER_RAW) : [];
$value = static fn (string $key, ?string $default = null): ?string => getenv($key) ?: ($env[$key] ?? $default);
$expand = static function (?string $value) use (&$env): ?string {
    if ($value === null) {
        return null;
    }

    return preg_replace_callback("/\\$\\{([A-Z0-9_]+)\\}/", static fn (array $matches): string => $env[$matches[1]] ?? "", $value);
};
$host = $value("DB_HOST", "postgres");
$port = $value("DB_PORT", "5432");
$db = $expand($value("POSTGRES_DB")) ?: $value("DB_DATABASE", "laravel");
$testDb = $value("POSTGRES_TEST_DB", "laravel_test");
$user = $expand($value("POSTGRES_USER")) ?: $value("DB_USERNAME", "laravel");
$pass = $expand($value("POSTGRES_PASSWORD")) ?: $value("DB_PASSWORD", "");
$pdo = new PDO("pgsql:host={$host};port={$port};dbname={$db}", $user, $pass);
$stmt = $pdo->prepare("SELECT 1 FROM pg_database WHERE datname = :name");
$stmt->execute(["name" => $testDb]);
if (! $stmt->fetchColumn()) {
    $quoted = str_replace("\"", "\"\"", $testDb);
    $pdo->exec("CREATE DATABASE \"{$quoted}\"");
}
'
