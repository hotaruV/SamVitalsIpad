# SamVitals iPad - Drawer Menu dinámico

## Objetivo

Crear un menú lateral deslizable nativo en SwiftUI que consuma la navegación generada por Laravel desde:

`/mobile/navigation`

El menú debe reutilizar una sola instancia lógica de `SamVitalsWebView`. Al seleccionar una opción únicamente debe cambiar la URL actual.

## Restricción actual

- [ ] En esta etapa solo se documenta el plan.
- [ ] No generar todavía el código Swift del drawer.

## Archivos previstos

- `Views/Web/WebShellView.swift`
- `Views/Web/Components/DrawerMenuView.swift`
- `Views/Web/Models/NavigationItem.swift`

## Fase 0 - Confirmar contrato con Laravel

- [x] Confirmar que `GET /mobile/navigation` usa la sesión web autenticada.
- [x] Confirmar que la ruta ejecuta los middleware `tenant-web` y `auth`.
- [x] Confirmar que la respuesta usa las mismas cookies de sesión que el WebView.
- [x] Definir el formato exacto de la respuesta JSON.
- [x] Definir `route` como path relativo navegable, por ejemplo `/dashboard`.
- [x] Conservar en `current` el nombre interno de Laravel, por ejemplo `tenant.dashboard`.
- [x] Normalizar todos los items para que incluyan `subitems`, aunque sea un arreglo vacío.
- [x] Confirmar que Laravel excluye únicamente “Planes y Módulos”.
- [x] Confirmar que los grupos sin `route` conservan sus `subitems` navegables.
- [x] Excluir hojas que no tengan `route` ni `subitems` navegables.
- [x] Confirmar que el backend oculta el sidebar cuando recibe `X-SamVitals-App` o la cookie `samvitals_app=app`.
- [x] Confirmar que el header web permanece visible en modo app.
- [x] Añadir pruebas automatizadas para paths, grupos y exclusión de planes.

Resultado:

- Ruta: `GET /mobile/navigation`.
- Autenticación: sesión web mediante cookies.
- `route`: path relativo navegable.
- `current`: nombre de ruta Laravel para estado activo futuro.
- Sidebar web: controlado mediante `samvitals_app=app`.
- Tests: `6 passed (50 assertions)` en `TenantSidebarMenuPermissionsTest.php`.

Respuesta mínima esperada:

```json
{
  "items": [
    {
      "label": "Inicio",
      "icon": "home",
      "route": "/dashboard",
      "current": "tenant.dashboard",
      "subitems": []
    }
  ]
}
```

## Fase 1 - Modelo de navegación

Archivo: `Views/Web/Models/NavigationItem.swift`

- [x] Crear `NavigationItem`.
- [x] Implementar `Identifiable`.
- [x] Implementar `Decodable`.
- [x] Incluir `label`.
- [x] Incluir `icon`.
- [x] Incluir `route` opcional.
- [x] Incluir `current` opcional.
- [x] Incluir `subitems`.
- [x] Soportar recursivamente grupos y subgrupos.
- [x] Generar una identidad estable para cada item.
- [x] Tratar un item con `route` como enlace navegable.
- [x] Tratar un item sin `route` y con `subitems` como grupo expandible.
- [x] Añadir pruebas de decodificación para items simples y grupos.

Resultado:

- Identidad estable basada en `current`, `route` o la composición del grupo.
- `subitems` ausente se decodifica como arreglo vacío.
- Pruebas recursivas con tres niveles de navegación aprobadas.

## Fase 2 - Mapeo de iconos

- [x] Crear el mapeo de Heroicons a SF Symbols.
- [x] Definir un icono de respaldo cuando Laravel envíe un nombre desconocido.
- [x] Verificar los siguientes casos:

| Heroicon | SF Symbol |
| --- | --- |
| `home` | `house` |
| `calendar-days` | `calendar` |
| `user-group` | `person.3` |
| `credit-card` | `creditcard` |
| `clipboard-document-list` | `doc.text` |
| `video-camera` | `video` |
| `cog-6-tooth` | `gearshape` |

Resultado:

- Mapper normalizado para mayúsculas, espacios y guiones bajos.
- Cobertura de todos los Heroicons emitidos actualmente por `TenantNavigationService`.
- Fallback: `square.grid.2x2`.
- Pruebas de contrato: `NavigationItem contract tests passed`.

## Fase 3 - DrawerMenuView

Archivo: `Views/Web/Components/DrawerMenuView.swift`

- [x] Crear `DrawerMenuView`.
- [x] Recibir `[NavigationItem]`.
- [x] Recibir `onSelect: (NavigationItem) -> Void`.
- [x] Mostrar items navegables como botones.
- [x] Mostrar icono y label de cada item.
- [x] Mostrar grupos como secciones expandibles.
- [x] Mantener el estado de grupos abiertos y cerrados.
- [x] Mostrar una flecha que indique el estado del grupo.
- [x] Al tocar un grupo, expandir o colapsar sin navegar.
- [x] Mostrar los `subitems` indentados debajo de su grupo.
- [x] Permitir scroll cuando el menú exceda la altura disponible.
- [x] Verificar accesibilidad de botones, labels e iconos.
- [x] Mostrar el logo `LogoSam` desde `Assets.xcassets`.

Resultado:

- Drawer recursivo con animación de grupos.
- Ancho adaptable para los distintos tamaños de iPad.
- Header nativo con logo, nombre de producto y botón de cierre.
- Preview con item normal y grupo expandible.

Ejemplo visual:

```text
Configuración
  Servicios
  Usuarios
```

## Fase 4 - WebShellView

Archivo: `Views/Web/WebShellView.swift`

- [x] Crear `WebShellView(initialURL:)`.
- [x] Inicializar `currentURL` con `initialURL`.
- [x] Mantener `@State private var currentURL`.
- [x] Mantener `@State private var isDrawerOpen = false`.
- [x] Mantener `@State private var navigationItems: [NavigationItem] = []`.
- [x] Mostrar `SamVitalsWebView(url: currentURL)`.
- [x] Mostrar un botón nativo para abrir el menú.
- [x] Superponer el drawer sin crear otro WebView.
- [x] Mostrar y ocultar el drawer según `isDrawerOpen`.
- [x] Mantener visible el header web.
- [x] Mantener oculto el sidebar web.
- [x] Establecer la cookie `samvitals_app=app` antes de cargar la primera página del tenant.

Resultado:

- El WebView permanece montado mientras se abre y cierra el drawer.
- La cookie de modo app se escribe en `HTTPCookieStorage` y `WKWebsiteDataStore`.
- La selección llega a `WebShellView` y cierra el drawer.
- La resolución de la ruta seleccionada permanece reservada para la Fase 6.

## Fase 5 - Carga del menú

- [x] Construir la URL `currentTenantURL + "/mobile/navigation"`.
- [x] Usar siempre el esquema y host del tenant actual.
- [x] Rechazar URLs que cambien a un host no permitido.
- [x] Ejecutar la solicitud cuando aparezca `WebShellView`.
- [x] Compartir las cookies de sesión del `WKWebView` con la solicitud del menú.
- [x] Decodificar la respuesta JSON.
- [x] Guardar el resultado en `navigationItems`.
- [x] Mostrar estado de carga del menú.
- [x] Manejar respuestas `401` y `403` cuando el usuario aún no inició sesión.
- [x] Manejar errores de red y respuestas inválidas.
- [x] Evitar solicitudes duplicadas durante una misma carga.

Resultado:

- `MobileNavigationService` sincroniza cookies de WebKit antes de cada solicitud.
- Solo acepta JSON proveniente del host original del tenant.
- El drawer muestra carga, error y reintento.
- Al abrir un drawer vacío o con error se intenta cargar nuevamente el menú.

## Fase 6 - Navegación dentro del WebView

- [x] Recibir la selección desde `DrawerMenuView`.
- [x] Ignorar navegación cuando el item solo sea un grupo.
- [x] Convertir la ruta seleccionada en una URL absoluta.
- [x] Usar como base el esquema y host del tenant actual.
- [x] Validar que la URL final pertenezca al tenant actual.
- [x] Actualizar únicamente `currentURL`.
- [x] Cerrar el drawer después de seleccionar una ruta.
- [x] Confirmar que `SamVitalsWebView` navega al detectar el cambio de URL.
- [x] Confirmar que no se crea una segunda instancia del WebView.

Resultado:

- `TenantRouteResolver` acepta paths relativos del tenant.
- Rechaza cambio de host, esquema y puerto.
- Pruebas aprobadas para rutas válidas y destinos externos.

## Fase 7 - Integración con ContentView

- [x] Sustituir:

```swift
SamVitalsWebView(url: url)
```

- [x] Por:

```swift
WebShellView(initialURL: url)
```

- [x] Confirmar que la restauración de sesión sigue abriendo el tenant correcto.
- [x] Confirmar que el bloqueo de privacidad ocurre antes de mostrar `WebShellView`.
- [x] Confirmar que las cookies existentes conservan el login web.

Resultado:

- `ContentView` usa `WebShellView(initialURL:)`.
- El bloqueo de privacidad permanece antes del shell.
- `WKWebsiteDataStore.default()` conserva la sesión web existente.

## Fase 8 - Validación funcional

- [ ] La app abre el tenant resuelto.
- [ ] El usuario puede iniciar sesión normalmente en la web.
- [ ] El dashboard carga en el mismo WebView.
- [ ] El botón de menú aparece encima del contenido web.
- [ ] El drawer se abre desde el lado esperado.
- [ ] Agenda navega dentro del WebView actual.
- [ ] Pacientes navega dentro del WebView actual.
- [ ] Configuración expande sus subitems sin navegar.
- [ ] Servicios y Usuarios navegan correctamente.
- [ ] “Planes y Módulos” no aparece.
- [ ] El sidebar web permanece oculto.
- [ ] El header web permanece visible.
- [ ] Los enlaces externos continúan abriéndose fuera de la app.
- [ ] El layout funciona en iPad mini, iPad 11" e iPad 13".
- [ ] El layout funciona en orientación vertical y horizontal.

## Fase 9 - Pruebas técnicas

- [ ] Probar decodificación con `subitems` vacíos.
- [ ] Probar decodificación con `subitems` anidados.
- [ ] Probar iconos desconocidos.
- [ ] Probar respuesta sin `items`.
- [ ] Probar respuesta JSON inválida.
- [ ] Probar sesión expirada.
- [ ] Probar pérdida de conexión.
- [ ] Probar cambio de URL sin recrear el WebView.
- [ ] Probar que una ruta externa no pueda reemplazar `currentURL`.

## Fase 10 - Mejoras posteriores

- [ ] Pull to refresh coordinado desde `WebShellView`.
- [ ] Estado activo del menú.
- [ ] Animación más fina del drawer.
- [ ] Cerrar el drawer al tocar fuera.
- [ ] Recargar el menú después de login.
- [ ] Recargar o limpiar el menú después de logout.
- [ ] Añadir transición y gesto interactivo para abrir el drawer.
