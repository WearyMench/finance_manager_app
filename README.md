# Gestor de Gastos - Flutter App

Una aplicación móvil para gestionar gastos e ingresos personales, desarrollada en Flutter.

## 🚀 Configuración para Compilar

### 1. Configurar la URL de la API

Antes de compilar, debes configurar la URL de tu servidor backend:

1. Abre el archivo `lib/config/api_config.dart`
2. Cambia la URL en la línea `_prodUrl` por la URL de tu servidor:
   ```dart
   static const String _prodUrl = 'https://tu-servidor.com/api';
   ```
3. Cambia el entorno a 'production' para compilar:
   ```dart
   static const String _environment = 'production';
   ```

### 2. Compilar la Aplicación

#### Para Android (APK):

```bash
flutter build apk --release
```

#### Para Windows (Ejecutable):

```bash
flutter build windows --release
```

#### Para iOS (requiere Mac):

```bash
flutter build ios --release
```

### 3. Archivos Generados

- **Android**: `build/app/outputs/flutter-apk/app-release.apk`
- **Windows**: `build/windows/runner/Release/`
- **iOS**: `build/ios/Release-iphoneos/`

## 🔧 Configuración del Backend

Asegúrate de que tu servidor backend esté configurado con:

1. **CORS habilitado** para permitir conexiones desde la app móvil
2. **URL accesible** desde internet (no localhost)
3. **HTTPS** recomendado para producción

### Ejemplo de configuración CORS en el backend:

```javascript
app.use(
  cors({
    origin: ["http://localhost:3000", "https://tu-dominio.com"],
    credentials: true,
  })
);
```

## 📱 Instalación en Dispositivos

### Android:

1. Transfiere el archivo `.apk` al dispositivo
2. Habilita "Fuentes desconocidas" en configuración
3. Instala el APK

### Windows:

1. Copia toda la carpeta `Release/` al dispositivo
2. Ejecuta `gestor_gastos.exe`

## 🛠️ Desarrollo

### Cambiar entre entornos:

```dart
// En lib/config/api_config.dart
static const String _environment = 'development'; // o 'production'
```

### URLs de ejemplo:

- **Desarrollo**: `http://localhost:5000/api`
- **Producción**: `https://api.tu-dominio.com/api`
- **Staging**: `https://staging-api.tu-dominio.com/api`

## 📋 Requisitos

- Flutter SDK 3.0+
- Dart 3.0+
- Backend funcionando y accesible
- Conexión a internet

## 🔒 Seguridad

- La app usa JWT para autenticación
- Los tokens se almacenan de forma segura
- Todas las comunicaciones van por HTTPS en producción

## 📞 Soporte

Si tienes problemas:

1. Verifica que la URL de la API sea correcta
2. Asegúrate de que el backend esté funcionando
3. Revisa la conexión a internet
4. Verifica los logs de la consola para errores específicos
