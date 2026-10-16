# TODO — Entrega frontend TutoresOn-Line

## 1. Páginas HTML de los flujos públicos y de estudiante — COMPLETADO

Se crearon las páginas de landing pública, inicio de sesión, registro/selección de rol, dashboard del estudiante, búsqueda de tutores, perfil público, reserva, negociación, confirmación, mis tutorías, detalle, reseña y Asistente IA. Las pantallas están conectadas mediante enlaces HTML visibles y acciones principales.

## 2. Páginas HTML de los flujos del tutor — COMPLETADO

Se crearon dashboard del tutor, gestión de perfil profesional, disponibilidad, radar de solicitudes, detalle de solicitud/contraoferta, clases impartidas, detalle de clase y aula virtual. Se incluyeron formularios, tablas, calendario, estados, métricas y checklist demostrativos.

## 3. Sistema visual compartido — COMPLETADO

`styles.css` implementa la paleta ÁgoraHub, tipografía, botones, tarjetas, badges, tablas, formularios, navegación y estados. Todas las interfaces usan la misma hoja CSS y no contienen etiquetas `<script>` ni dependencia de JavaScript. Los estados visuales usan HTML/CSS, incluyendo hover, focus, selección y navegación por anclas.

## 4. Responsive web/móvil — COMPLETADO

El layout se adapta a desktop, tablet y 390 px. En móvil el sidebar se transforma visualmente en navegación inferior; tarjetas, formularios y métricas se apilan; tablas y calendario permiten desplazamiento horizontal; se conservan jerarquía, botones, colores e iconos.

## 5. Entrega y validación — COMPLETADO

`manus-routes.json` y `public/manus-routes.json` declaran las 21 rutas. El servidor estático responde HTTP 200 para la landing, el manifiesto y las páginas principales. Se verificaron los 21 documentos HTML, se validaron los enlaces internos sin roturas y se inspeccionó la presentación en viewport desktop y móvil.

## Próxima etapa sugerida

Conectar los formularios y enlaces demostrativos con backend, autenticación, base de datos, disponibilidad real, pagos, notificaciones, videoconferencia y el servicio de IA cuando comience la siguiente entrega.


## Ajuste solicitado — COMPLETADO

Se separaron los registros de estudiante y tutor en formularios propios. La landing dirige “Quiero enseñar” al registro de tutor, la pantalla de selección ya no abre dashboards directamente y se añadieron credenciales demo visibles para ambos roles. Los dashboards, tutorías, clases impartidas y radar comienzan con estados vacíos: no se crean clases, tutorías ni solicitudes automáticamente.


## Ajuste solicitado — Tutor único y Asistente IA — COMPLETADO

Se retiró la sección de tutores destacados de la landing. La búsqueda y el dashboard del estudiante muestran únicamente a Andrés García, el perfil tutor principal, y los filtros se ajustaron para no sugerir otros profesores. Todas las referencias del producto de inteligencia artificial se nombran “Asistente IA”; ÁgoraHub se conserva únicamente como marca.

## Ajuste solicitado — Registro frontend y validaciones — COMPLETADO

Los formularios de estudiante y tutor ya no redirigen a cuentas demo ni a dashboards. Después de completar datos válidos muestran `registro-no-disponible.html`, que explica que esta entrega es únicamente frontend y enlaza a Inicio de sesión para explorar las dos cuentas demo predefinidas. Se añadieron validaciones nativas HTML: correo `type=email`, teléfono `type=tel` con teclado numérico y patrón sin letras, nombres con patrón de letras/espacios, contraseñas con longitud mínima/máxima, textos con límites, campos obligatorios, fecha mínima y presupuesto numérico.
