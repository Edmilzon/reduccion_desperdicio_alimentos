# reduccion_desperdicio_alimentos

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Estructura del Proyecto 

mi_app_alquileres/
├── android/                # Configuración nativa de Android (permisos de GPS, cámara)
├── ios/                    # Configuración nativa de iOS
├── assets/                 # RECURSOS EXTERNOS (Debes crearla tú)
│   ├── images/             # Fotos, logos, backgrounds
│   ├── icons/              # Iconos personalizados (SVG/PNG)
│   └── fonts/              # Tipografías (.ttf, .otf)
├── lib/                    # AQUÍ VIVE TU CÓDIGO (Tu "src")
│   ├── main.dart           # Punto de entrada y configuración global
│   ├── core/               # TODO LO GLOBAL Y TRANSVERSAL
│   │   ├── theme/          # estilos.dart, colores.dart, temas_dark_light.dart
│   │   ├── constants/      # api_endpoints.dart, textos_estaticos.dart
│   │   └── errors/         # Manejo de excepciones personalizadas
│   ├── features/           # FUNCIONALIDADES POR MÓDULO (Arquitectura por capas)
│   │   ├── auth/           # Módulo de Login/Registro
│   │   ├── home/           # Módulo principal
│   │   └── properties/     # Módulo de alquileres (basado en tus epics)
│   │       ├── data/       # Modelos (JSON to Dart) y llamadas a la API
│   │       ├── domain/     # Lógica de negocio pura (Entidades)
│   │       └── presentation/ # LA UI: Screens y Widgets específicos del módulo
│   ├── shared/             # WIDGETS REUTILIZABLES (Botones, Inputs, Cards globales)
│   └── routes/             # app_routes.dart (Navegación tipo React Router)
├── test/                   # Unit tests y Widget tests
├── pubspec.yaml            # TU "PACKAGE.JSON" (Dependencias y Assets)
└── .gitignore              # Archivos que Git debe ignorar (build/, .dart_tool/, etc.)