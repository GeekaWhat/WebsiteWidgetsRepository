@echo off
setlocal

set "REPO_ROOT=%~dp0"
pushd "%REPO_ROOT%" >nul 2>&1
if errorlevel 1 (
  echo ERROR: Failed to open repo root: "%REPO_ROOT%"
  exit /b 1
)

if "%~1"=="" (
  set /p BUILD_CODE=Enter build code including brackets (example: [DM92]): 
) else (
  set "BUILD_CODE=%~1"
)

if "%BUILD_CODE%"=="" (
  echo ERROR: Build code is required.
  popd >nul
  exit /b 1
)

set "GEN_SCRIPT=PC Build Template Widgets/scripts/generate-build-widgets.sh"
set "AUDIT_FILE=PC Build Template Widgets/builds/%BUILD_CODE%/build-audit.txt"

set "BASH_EXE="
if exist "%ProgramFiles%\Git\bin\bash.exe" set "BASH_EXE=%ProgramFiles%\Git\bin\bash.exe"
if not defined BASH_EXE if exist "%ProgramFiles(x86)%\Git\bin\bash.exe" set "BASH_EXE=%ProgramFiles(x86)%\Git\bin\bash.exe"

if defined BASH_EXE (
  call "%BASH_EXE%" "%GEN_SCRIPT%" "%BUILD_CODE%"
) else (
  bash "%GEN_SCRIPT%" "%BUILD_CODE%"
)

if errorlevel 1 (
  echo ERROR: Widget generation failed.
  popd >nul
  exit /b 1
)

if not exist "%AUDIT_FILE%" (
  echo ERROR: Missing audit file: "%AUDIT_FILE%"
  popd >nul
  exit /b 1
)

findstr /C:"OK: no audit issues found." "%AUDIT_FILE%" >nul
if errorlevel 1 (
  echo ERROR: Audit reported issues.
  type "%AUDIT_FILE%"
  popd >nul
  exit /b 1
)

echo Success: Build widgets generated and audit passed for %BUILD_CODE%.
popd >nul
exit /b 0
