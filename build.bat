@echo off
setlocal enabledelayedexpansion
for /F %%i in ('git tag') do (set FRPMGR_VERSION=%%i)
set FRPMGR_VERSION=%FRPMGR_VERSION:~1%
echo Version: %FRPMGR_VERSION%
set BUILDDIR=%~dp0
set PATH=%BUILDDIR%.deps;%PATH%
echo [+] Rendering icons
for %%a in ("icon\*.svg") do convert  -density 1000 -background none "%%~fa" -define icon:auto-resize="256,192,128,96,64,48,32,24,16" "%%~dpna.ico" || exit /b 1
echo [+] Building resources
rsrc -manifest frpmgr.exe.manifest -ico icon/app.ico,icon/dot.ico -o rsrc.syso || exit /b 1
echo [+] Patching files
go mod tidy || exit /b 1
for %%f in (patches\*.patch) do patch -N -r - -d %GOPATH% -p0 < %%f
echo [+] Compiling release version
for /F "tokens=2 delims=@" %%y in ('go mod graph ^| findstr frpmgr ^| findstr frp@') do (set FRP_VERSION=%%y)
go build -ldflags="-H windowsgui -X frpmgr/config.Version=v%FRPMGR_VERSION% -X frpmgr/config.FRPVersion=%FRP_VERSION%" -o bin/frpmgr.exe frpmgr || exit /b 1
echo [+] Building installer
call installer/build.bat %FRPMGR_VERSION% || exit /b 1
echo [+] Success.
exit /b 0