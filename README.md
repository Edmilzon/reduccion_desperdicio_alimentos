# Eco Bocado — Reducción de Desperdicio de Alimentos

App Flutter para conectar restaurantes con clientes a través de ofertas de última hora.

## Flujo de Pago: Carrito → QR → Mis Pedidos

```mermaid
flowchart TD
    A[Carrito<br/>RealCartScreen] --> B{"Seleccionar método<br/>de pago"}
    B --> C[Pagar con QR]
    B --> D[Efectivo]

    C --> E["POST /orders (por item)<br/>paymentMethod='online'"]
    D --> F["POST /orders (por item)<br/>paymentMethod='cash'"]

    E --> G[Reserva creada con<br/>código de reserva]
    F --> G

    G --> H[Resumen: productos<br/>exitosos + fallidos]
    H --> I["Botón → Mis Pedidos<br/>MyOrdersScreen"]

    I --> J["Orden con badge<br/>'Pendiente de pago'"]
    J --> K[Botón: Pagar con QR]
    K --> L["Diálogo QR<br/>(código de reserva)"]
    L --> M["Clic: Confirmar pago<br/>POST /orders/:id/pay"]
    M --> N{¿Respuesta 200?}

    N -->|Sí| O[Orden marcada como pagada<br/>badge verde ✓ Pagado]
    N -->|No| P["Re-fetch GET /orders/my-orders<br/>y verifica si ya pagó"]
    P --> O

    O --> Q[¡Solo falta recoger!<br/>QR al llegar al restaurante]
```

### Flujo en efectivo (simplificado)

```mermaid
flowchart LR
    A[Carrito] --> B[Seleccionar Efectivo]
    B --> C[POST /orders por item]
    C --> D[Reserva creada]
    D --> E["Badge: 'Pagarás en efectivo<br/>al recoger'"]
```

## Requisitos

- Flutter SDK `^3.11.3`
- Dart SDK `>=3.11.0`
- Backend: `https://reduccion-desperdicio-backend.vercel.app`

## Comandos

```bash
flutter pub get
flutter run
flutter analyze
flutter test
```

## Comandos Específicos

| Comando | Descripción |
|---|---|
| `flutter pub run flutter_launcher_icons:main` | Generar iconos de lanzador |
| `flutter analyze && flutter test` | Verificación completa (lint + tests) |

## Estructura del Proyecto

```
lib/
├── main.dart                     # Entrypoint
├── core/                         # Infraestructura global
│   ├── theme/                    # Colores, estilos
│   ├── constants/                # API endpoints
│   └── services/                 # Servicios compartidos
├── features/                     # Módulos por funcionalidad
│   ├── auth/                     # Login, registro, perfil
│   ├── home/                     # Menú, tienda, carrito, perfil cliente
│   ├── dashboard/                # Panel del comerciante
│   ├── orders/                   # Pedidos (cliente + comerciante)
│   ├── restaurant_detail/        # Detalle de restaurante
│   └── map/                      # Mapa con filtros
├── shared/                       # Widgets reutilizables
└── routes/                       # Definición de rutas
```

Ultima version de la APK