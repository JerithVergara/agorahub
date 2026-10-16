# Plan de implementación — TutoresOn-Line · ÁgoraHub

## Alcance

Construir una entrega **100% frontend y sin JavaScript** de la plataforma de tutorías en línea descrita en el PDF de Diseño UI/UX y en el documento de requisitos. La entrega será un conjunto de páginas HTML estáticas conectadas mediante enlaces y una hoja CSS compartida. No se implementan backend, API REST, base de datos, autenticación real, videoconferencia ni integraciones de correo/SMS/WhatsApp. Las cuentas demo y los formularios son solo de navegación: el estudiante y el tutor comienzan sin tutorías, clases, ingresos, reseñas ni solicitudes creadas.

Se cubrirán las 21 interfaces web documentadas: landing pública, login, registro/rol, dashboard estudiante, búsqueda de tutores, perfil de tutor, reserva, negociación, confirmación, mis tutorías, detalle de tutoría, reseña, Asistente IA, dashboard tutor, perfil profesional, disponibilidad, radar, detalle de solicitud, clases impartidas, detalle de clase y aula virtual.

Las vistas móviles se resolverán con CSS responsive para el ancho de referencia de 390 px, conservando identidad visual, componentes, colores e iconografía. En móvil el sidebar se convierte visualmente en una navegación inferior, las grillas pasan a una columna y los paneles complejos se apilan o permiten desplazamiento horizontal con CSS.

## Enfoque de implementación

- **Stack:** HTML5 semántico y CSS3; sin JavaScript, frameworks ni dependencias de frontend.
- **Arquitectura:** una página HTML por pantalla dentro de `pages/`, con `index.html` como landing pública y `styles.css` como sistema visual compartido.
- **Navegación:** enlaces HTML entre las pantallas para demostrar los flujos de estudiante y tutor.
- **Datos:** contenido demostrativo escrito en HTML; formularios con validaciones nativas, sin persistencia; el registro termina en un aviso de frontend no conectado y el login ofrece dos cuentas demo.
- **Componentes reutilizables por clases CSS:** shell, navegación, encabezado, breadcrumbs, botones, badges, tarjetas, métricas, tablas, formularios, calendario, modal estático con `:target`, toast estático y aula.
- **Accesibilidad:** etiquetas de formulario, foco visible, botones/enlaces descriptivos, tablas con encabezados y tamaños táctiles adecuados.
- **Rutas declaradas:** `public/manus-routes.json` mantendrá el inventario completo de páginas.

## Estructura

```text
/home/ubuntu/tutoreshub/
├── index.html
├── styles.css
├── pages/
│   ├── login.html
│   ├── registro.html
│   ├── dashboard-estudiante.html
│   ├── buscar-tutores.html
│   ├── perfil-tutor.html
│   ├── reserva.html
│   ├── negociacion.html
│   ├── confirmacion.html
│   ├── mis-tutorias.html
│   ├── detalle-tutoria.html
│   ├── resena.html
│   ├── asistente-ia.html
│   ├── dashboard-tutor.html
│   ├── perfil-profesional.html
│   ├── disponibilidad.html
│   ├── radar-solicitudes.html
│   ├── detalle-solicitud.html
│   ├── clases-impartidas.html
│   ├── detalle-clase.html
│   └── aula-virtual.html
├── public/manus-routes.json
├── plan.md
└── TODO.md
```

## Dirección visual

### Movimiento de diseño

**SaaS editorial luminoso con precisión de dashboard**: base blanca y aireada, jerarquía tipográfica clara y superficies legibles, enriquecida con acentos azules y lavanda que comunican aprendizaje, confianza y tecnología.

### Principios

1. Claridad antes que decoración: cada pantalla muestra una acción principal inequívoca.
2. Confianza progresiva: reputación, disponibilidad y estados aparecen junto a cada decisión.
3. Ritmo por capas: canvas, superficies y detalles pequeños evitan interfaces planas.
4. Responsive por prioridad: en móvil se conserva el CTA, el estado y la información crítica.

### Color y tipografía

El blanco cálido y el gris azulado forman un entorno sereno para estudiar. El azul eléctrico es la firma de ÁgoraHub; lavanda y celeste apoyan IA y estados informativos. Verde, ámbar y rojo son estados semánticos.

Paleta: `#2563EB` azul firma, `#0F172A` tinta, `#F6F8FC` canvas, `#FFFFFF` superficie, `#E7ECF5` bordes, `#EEF4FF` azul suave, `#F2F0FF` lavanda, `#16A37A` éxito, `#F59E0B` alerta, `#E25555` error. Tipografía: `Inter`, pesos 400/500/600/700.

### Layout e interacción

En escritorio se usa un rail lateral persistente y un área de trabajo con encabezado contextual, hero/acción y módulos en columnas asimétricas. En móvil el rail se convierte en navegación inferior fija y el contenido fluye en tarjetas apiladas. Los estados visuales se resuelven con `:hover`, `:focus`, `:checked` y `:target`; no hay animaciones ni comportamiento dependiente de JavaScript.

### Marca

El logotipo combina el wordmark ÁgoraHub con un isotipo circular de tres nodos conectados, representando estudiante, tutor y conocimiento. El azul `#2563EB` es el color propio de la marca.

## Flujo de navegación

- La landing enlaza a login, registro y búsqueda pública.
- Login ofrece dos cuentas demo para explorar los dashboards. Registro muestra un aviso de frontend no conectado y no crea cuentas.
- El dashboard del estudiante conecta búsqueda, perfil, reserva, negociación, confirmación, tutorías, detalle, reseña, IA y aula.
- El dashboard del tutor conecta perfil profesional, disponibilidad, radar, solicitud, clases, detalle y aula.

## Build y validación

- Servir el sitio estático en el puerto 3000 y en `0.0.0.0`.
- Verificar `/manus-routes.json` con HTTP 200.
- Validar sintaxis HTML/CSS e inspeccionar enlaces internos.
- Comprobar desktop y móvil, especialmente navegación, formularios, tablas, calendario y aula.
