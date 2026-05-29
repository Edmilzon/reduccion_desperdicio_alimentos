\# HU-20 Validación de Recogida - Frontend



\## Pantalla implementada



Se implementó la pantalla:



```text

lib/features/orders/presentation/screens/validate\_pickup\_screen.dart

```



\## Acceso



El restaurante puede acceder desde:



```text

Perfil restaurante → Validar entrega

```



\## Funcionalidad



La pantalla permite:



\- Ingresar el código de reserva presentado por el cliente.

\- Enviar el código al backend.

\- Mostrar entrega confirmada.

\- Mostrar código inválido.

\- Mostrar código ya utilizado.

\- Mostrar el detalle del pedido validado.

\- Mostrar la hora de entrega registrada.



\## Endpoint consumido



```http

POST /orders/validate-pickup

```



\## Archivos modificados



```text

lib/features/home/presentation/screens/profile\_screen.dart

lib/features/orders/data/models/order\_model.dart

lib/features/orders/data/models/pickup\_validation\_result.dart

lib/features/orders/data/repositories/order\_repository.dart

lib/features/orders/presentation/screens/validate\_pickup\_screen.dart

```



\## Estados visuales



\- Validando código.

\- Entrega confirmada.

\- Código inválido.

\- Código ya utilizado.

\- Detalle de reserva validada.



\## Nota de integración



La validación real depende de que el backend tenga ejecutado el script SQL:



```text

database/hu20\_validate\_pickup.sql

```

