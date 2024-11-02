@echo off
REM scripts/generate-secrets.bat

setlocal enabledelayedexpansion

REM Check if environment is provided
set ENV=%1
if "%ENV%"=="" set ENV=dev
if not "%ENV%"=="dev" if not "%ENV%"=="prod" (
    echo Usage: %0 [dev^|prod]
    exit /b 1
)

REM Set configurations based on environment
if "%ENV%"=="prod" (
    set INSTANCE_CLASS=db.t3.small
    set ALLOCATED_STORAGE=50
    set MAX_ALLOCATED_STORAGE=200
    set BACKUP_RETENTION=30
) else (
    set INSTANCE_CLASS=db.t3.micro
    set ALLOCATED_STORAGE=20
    set MAX_ALLOCATED_STORAGE=100
    set BACKUP_RETENTION=7
)

REM Create directories
mkdir ..\terraform\environments\%ENV% 2>nul

REM Generate random password
set "CHARS=abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
set "PASSWORD="
for /L %%i in (1,1,16) do call :appendChar

REM Create secrets file
(
echo # Database Credentials
echo db_username = "%ENV%_user"
echo db_password = "%PASSWORD%"
echo.
echo # AWS Credentials (if not using AWS CLI profile^)
echo aws_access_key = ""
echo aws_secret_key = ""
echo.
echo # RDS Configuration
echo db_instance_class = "%INSTANCE_CLASS%"
echo db_allocated_storage = %ALLOCATED_STORAGE%
echo db_max_allocated_storage = %MAX_ALLOCATED_STORAGE%
echo db_backup_retention_period = %BACKUP_RETENTION%
) > ..\terraform\environments\%ENV%\secrets.tfvars

echo Generated secrets file: ..\terraform\environments\%ENV%\secrets.tfvars
echo WARNING: Keep this file secure and never commit it to version control!

echo.
echo Generated configuration:
echo ------------------------
type ..\terraform\environments\%ENV%\secrets.tfvars

exit /b 0

:appendChar
set /a i=%random% %% 62
call set PASSWORD=%%PASSWORD%%%%CHARS:~%i%,1%%
exit /b