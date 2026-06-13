# Veomio

Veomio es una aplicación de streaming multiplataforma desarrollada en **Flutter**, diseñada para ofrecer una experiencia premium tanto en dispositivos móviles (smartphones) como en **Android TV / Fire TV**. 

La aplicación permite la exploración y reproducción de películas, series y canales de televisión en vivo, consolidando múltiples fuentes de transmisión mediante un sistema de Complementos (Addons).

## Características Principales

*   **Soporte Híbrido (TV & Mobile):** Interfaz totalmente responsiva. En pantallas móviles presenta un clásico `BottomNavigationBar`, mientras que en Smart TVs despliega una barra lateral animada optimizada para el uso con control remoto.
*   **Optimizada para D-Pad:** Soporte nativo para mandos a distancia. Implementa navegación por hardware, auto-enfoque y efectos visuales fluidos al cambiar de elemento (usando el motor `FocusTraversalGroup` y atajos de teclado lógicos).
*   **Motor de Reproducción Avanzado:** Utiliza `media_kit` (sustituyendo a VLC) para garantizar una reproducción de video de alta calidad, con soporte para resoluciones modernas, decodificación por hardware y subtítulos.
*   **Sistema de Complementos (Addons):** Permite agregar configuraciones de proveedores externos de contenido en formato JSON para extender el catálogo de películas y series sin actualizar la aplicación base.
*   **TV en Vivo (Live TV):** Incluye un módulo dedicado para la reproducción de canales IPTV mediante listas y resolutores de streaming dinámicos (Stream Resolvers).
*   **Búsqueda Rápida:** Buscador en tiempo real de todo el catálogo unificado.

## Arquitectura y Tecnologías

El proyecto sigue estándares de arquitectura limpia y manejo de estados predecible:

*   **Framework:** [Flutter](https://flutter.dev/) (Dart)
*   **Gestión de Estado:** [BLoC / Cubit](https://pub.dev/packages/flutter_bloc)
*   **Red / HTTP:** [Dio](https://pub.dev/packages/dio) para conexiones al backend de addons y catálogos.
*   **Almacenamiento Local:** [SharedPreferences](https://pub.dev/packages/shared_preferences) para guardar configuraciones del reproductor y complementos activos.
*   **Reproductor:** [MediaKit](https://pub.dev/packages/media_kit) (Motor libmpv nativo para renderizado eficiente).

## Capturas de Pantalla y Comportamiento

1.  **Vista de Móvil (< 600px):** Uso de áreas seguras (`SafeArea`) y barra de navegación inferior. Elementos en cuadrícula adaptables al tacto.
2.  **Vista de Televisor (>= 600px):** Oculta la barra de navegación inferior y activa el *Sidebar Navigation Drawer*. Los pósters crecen al enfocar con el mando de la TV y la tarjeta de contenido heroico ocupa la parte superior.

## Instalación y Compilación

### Requisitos Previos
*   Flutter SDK (Última versión estable)
*   Android Studio / Xcode
*   Para compilación en Windows/Linux, asegurarse de tener instaladas las dependencias de MediaKit.

### Compilar para Android TV o Móvil (APK)
La aplicación comparte el mismo `AndroidManifest.xml` para ambos entornos (usando la declaración `LEANBACK`). Un solo APK sirve para ambos.

```bash
# Descargar dependencias
flutter pub get

# Compilar APK de producción
flutter build apk --release
```
El archivo resultante se ubicará en: `build\app\outputs\flutter-apk\app-release.apk`

### Distribución con Downloader (AFTVnews)
Para instalar en Fire Stick o Android TV fácilmente:
1. Sube el `app-release.apk` a un host (ej. GitHub Releases).
2. Usa [create.aftvnews.com](https://create.aftvnews.com/) para generar un código de 5 dígitos.
3. Abre Downloader en tu TV e introduce el código.

---
*Desarrollado para los amantes del buen diseño y el código limpio.*
