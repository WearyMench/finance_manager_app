@echo off
echo ========================================
echo    COMPILANDO GESTOR DE GASTOS
echo ========================================
echo.

echo Verificando configuración de la API...
echo.

echo ¿Has configurado la URL de la API en lib/config/api_config.dart? (s/n)
set /p configurado=

if /i "%configurado%"=="s" (
    echo.
    echo Selecciona la plataforma:
    echo 1. Android (APK)
    echo 2. Windows (Ejecutable)
    echo 3. Ambas
    echo.
    set /p plataforma=
    
    if "%plataforma%"=="1" goto android
    if "%plataforma%"=="2" goto windows
    if "%plataforma%"=="3" goto ambas
    goto error
) else (
    echo.
    echo Por favor configura la URL de la API primero:
    echo 1. Abre lib/config/api_config.dart
    echo 2. Cambia _prodUrl por tu URL del servidor
    echo 3. Cambia _environment a 'production'
    echo 4. Ejecuta este script nuevamente
    echo.
    pause
    exit
)

:android
echo.
echo Compilando para Android...
flutter build apk --release
if %errorlevel%==0 (
    echo.
    echo ✅ APK compilado exitosamente!
    echo Ubicación: build\app\outputs\flutter-apk\app-release.apk
) else (
    echo.
    echo ❌ Error al compilar para Android
)
goto end

:windows
echo.
echo Compilando para Windows...
flutter build windows --release
if %errorlevel%==0 (
    echo.
    echo ✅ Ejecutable de Windows compilado exitosamente!
    echo Ubicación: build\windows\runner\Release\
) else (
    echo.
    echo ❌ Error al compilar para Windows
)
goto end

:ambas
echo.
echo Compilando para Android...
flutter build apk --release
if %errorlevel%==0 (
    echo ✅ APK compilado exitosamente!
) else (
    echo ❌ Error al compilar para Android
)

echo.
echo Compilando para Windows...
flutter build windows --release
if %errorlevel%==0 (
    echo ✅ Ejecutable de Windows compilado exitosamente!
) else (
    echo ❌ Error al compilar para Windows
)
goto end

:error
echo.
echo Opción inválida. Por favor selecciona 1, 2 o 3.
goto end

:end
echo.
echo ========================================
echo           COMPILACIÓN COMPLETADA
echo ========================================
echo.
pause
