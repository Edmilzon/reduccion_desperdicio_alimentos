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
|   |   |__   
│   ├── shared/             # WIDGETS REUTILIZABLES (Botones, Inputs, Cards globales)
│   └── routes/             # app_routes.dart (Navegación tipo React Router)
├── test/                   # Unit tests y Widget tests
├── pubspec.yaml            # TU "PACKAGE.JSON" (Dependencias y Assets)
└── .gitignore              # Archivos que Git debe ignorar (build/, .dart_tool/, etc.)


## Explicacion Breve de la Arquitectura planteada 

##         Arquitectura de Software: Feature-First
Este proyecto utiliza una estructura basada en Feature-First (Funcionalidad Primero) combinada con principios de Clean Architecture. A diferencia de las arquitecturas tradicionales (como MVC), donde los archivos se agrupan por su tipo técnico (todos los modelos juntos, todas las vistas juntas), aquí el código se organiza según el dominio del problema que resuelve.

Estructura de Directorios
1. lib/core/
Es la infraestructura global de la aplicación. Aquí reside el código que no pertenece a una funcionalidad específica, sino que da soporte a toda la app.

    theme/: Definición de estilos globales, colores y tipografías (Design System).

    constants/: Enlaces a APIs, strings estáticos y valores fijos.

    errors/: Manejo centralizado de excepciones y fallos del sistema.

2. lib/features/
Es el corazón de la aplicación. Cada carpeta dentro de features/ representa un módulo independiente (ej. auth, home, rentals).
Cada módulo interno se divide en tres capas de responsabilidad:

    Data: Repositorios, proveedores de datos (APIs/Bases de Datos) y modelos (mapeo de JSON).

    Domain: Lógica de negocio pura, entidades y casos de uso. Es independiente de cualquier framework.

    Presentation: Widgets de Flutter, pantallas (Screens) y gestión de estado (Controllers/BLoCs).

3. lib/shared/
Contiene los componentes reutilizables o "UI Kit" del proyecto. Si un botón o un campo de texto se usa en más de una funcionalidad, vive aquí para evitar la duplicación de código (principio DRY - Don't Repeat Yourself).

4. lib/routes/
Centraliza la lógica de navegación. Define cómo se conectan las diferentes pantallas y qué parámetros requieren para abrirse, facilitando el mantenimiento de los flujos de usuario.

5. assets/
Ubicado en la raíz, este directorio gestiona todos los recursos externos (imágenes, fuentes e iconos) que deben ser declarados en el pubspec.yaml.

Ventajas de este Enfoque
    Escalabilidad: Añadir una nueva funcionalidad es tan simple como crear una nueva carpeta en features/ sin afectar el código existente.

    Mantenibilidad: Si hay un error en el módulo de "Alquileres", el desarrollador sabe exactamente que el problema reside en lib/features/rentals/.

    Desacoplamiento: La lógica de negocio (Domain) está separada de la interfaz (Presentation), permitiendo cambiar el diseño o el backend con un impacto mínimo.

    Trabajo en Equipo: Permite que varios desarrolladores trabajen en diferentes funcionalidades simultáneamente sin generar conflictos de fusión (merge conflicts) constantes.