@echo off
SETLOCAL EnableDelayedExpansion

:: --- 1. CONFIGURAÇÃO DE VARIÁVEIS DE AMBIENTE ---
set DB_HOST=db.vjekjywztahphnwtbkgp.supabase.co
set DB_USER=postgres
set DB_PASSWORD=sonar_postgres
set DB_PORT=6543
set DB_NAME=postgres

:: --- 2. CONFIGURAÇÃO DE CAMINHOS ---
set BASE_PATH=C:\Users\PICHAU\Documents\sonar_eng
set HOP_PATH=C:\hop\hop-version-2.15
set DBT_PROJECT_PATH=%BASE_PATH%\Dbt_project
set LOG_DIR=%BASE_PATH%\dq
set CSV_LOG=%LOG_DIR%\pipeline_runs.csv

:: Garantir que a pasta de logs existe
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

:: --- 3. CAPTURA DE INÍCIO (Tempo e Data) ---
set START_TIME=%time%
set START_DATE=%date%
:: Converter tempo para segundos para cálculo de duração (HH:MM:SS)
for /f "tokens=1-3 delims=:," %%a in ("%START_TIME%") do (
    set /a "start_seconds=(%%a*3600)+(%%b*60)+%%c"
)

echo [%START_TIME%] Iniciando Pipeline...

:: --- 4. EXECUÇÃO DA INGESTÃO (APACHE HOP) ---
echo [1/2] Iniciando Ingestao com Apache Hop...
cd /d %HOP_PATH%

call hop-run.bat ^
  -j sonar_eng ^
  -f %BASE_PATH%\hop\workflows\workflow_master.hwf ^
  -r local ^
  -p DB_HOST=%DB_HOST% ^
  -p DB_USER=%DB_USER% ^
  -p DB_PASSWORD=%DB_PASSWORD% ^
  -p DB_PORT=%DB_PORT% ^
  -p DB_NAME=%DB_NAME%

if %errorlevel% neq 0 (
    echo [ERRO] Falha na ingestao do Hop. Abortando dbt.
    goto :mudar_erro
)

:: --- 5. EXECUÇÃO DA TRANSFORMAÇÃO (DBT) ---
echo [2/2] Ingestao concluida. Iniciando dbt...
cd /d %DBT_PROJECT_PATH%

call dbt build --profiles-dir .

if %errorlevel% neq 0 (
    echo [ERRO] Falha na execucao do dbt.
    goto :mudar_erro
)

:: --- 6. CAPTURA DE FIM E CÁLCULOS ---
set END_TIME=%time%
for /f "tokens=1-3 delims=:," %%a in ("%END_TIME%") do (
    set /a "end_seconds=(%%a*3600)+(%%b*60)+%%c"
)
set /a duration_seconds=%end_seconds% - %start_seconds%

:: --- 7. COLETA DE VOLUMETRIA (PSQL) ---
:: Usamos o psql para contar as linhas das tabelas Gold para o log
echo Pipeline falhou. Verifique os logs.
pause
exit /b 1