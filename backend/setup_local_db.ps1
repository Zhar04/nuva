# Nuva — инициализация локальной PostgreSQL (запускать один раз после winget install)
# Пароль суперпользователя postgres: nuvadev2026

Set-Location $PSScriptRoot

$env:PGPASSWORD = "nuvadev2026"
$psql = "C:\Program Files\PostgreSQL\17\bin\psql.exe"

if (-not (Test-Path $psql)) {
    Write-Error "psql не найден. Установите PostgreSQL: winget install PostgreSQL.PostgreSQL.17"
    exit 1
}

Write-Host "==> Создаём базу данных nuva..."
& $psql -U postgres -c "CREATE DATABASE nuva;" 2>&1
if ($LASTEXITCODE -ne 0) { Write-Host "(база уже существует — пропускаем)" }

Write-Host "==> Django migrate..."
.\.venv\Scripts\python.exe manage.py migrate
if ($LASTEXITCODE -ne 0) { Write-Error "migrate упал"; exit 1 }

Write-Host "==> Создаём суперпользователя Django (admin@nuva.local / nuvaadmin2026)..."
.\.venv\Scripts\python.exe manage.py ensure_admin

Write-Host "==> Заполняем демо-данными (психолог + клиенты)..."
.\.venv\Scripts\python.exe manage.py shell -c "exec(open('seed_demo.py', encoding='utf-8').read())"

Write-Host ""
Write-Host "Готово!"
Write-Host "  Запуск сервера:  .\.venv\Scripts\python.exe manage.py runserver"
Write-Host "  Django-admin:    http://127.0.0.1:8000/admin/"
Write-Host "  Логин:           admin@nuva.local / nuvaadmin2026"
Write-Host "  Демо-психолог:   demo.psy@nuva.kz / Demo12345"
