# AsisGo - Sistema Móvil Corporativo de Control de Asistencia y Geolocalización

AsisGo es una solución móvil de nivel empresarial desarrollada en Flutter para la gestión, control y auditoría de asistencia de personal en tiempo real, respaldada por validación geodésica de alta precisión, Live Activities nativas (Dynamic Island en iOS y Notificaciones en Vivo en Android), modo offline con auto-sincronización y mecanismos de seguridad de hardware contra suplantación de ubicación.

---

## Capturas de Pantalla de la Aplicación

| Inicio de Sesión Corporativo | Mapa Interactivo Midnight | Marcación Rápida & Selfie |
| :---: | :---: | :---: |
| <img src="docs/screenshots/01_login_screen.png" width="260" alt="Inicio de Sesión Corporativo" /> | <img src="docs/screenshots/02_map_midnight.png" width="260" alt="Mapa Interactivo Midnight" /> | <img src="docs/screenshots/03_attendance_modal.png" width="260" alt="Modal de Asistencia Simplificado" /> |

| Jerarquía Multi-Empresa | Calendario & Auditoría | Expiración de Sesión (10 min) |
| :---: | :---: | :---: |
| <img src="docs/screenshots/04_companies_hierarchy.png" width="260" alt="Jerarquía Multi-Empresa y Sedes" /> | <img src="docs/screenshots/05_calendar_history.png" width="260" alt="Calendario e Historial de Marcas" /> | <img src="docs/screenshots/06_session_expired.png" width="260" alt="Diálogo de Sesión Expirada" /> |

| Perfil & Horario Asignado |
| :---: |
| <img src="docs/screenshots/07_user_profile.png" width="260" alt="Perfil del Colaborador y Horario" /> |

---

## Características Principales

### 1. Dynamic Island y Live Activities (iOS)
- Integración nativa con **ActivityKit** y **WidgetKit** mediante extensiones nativas en Swift (`AsisGoWidgets`).
- Modos de presentación adaptativos:
  - **Dynamic Island Compact:** Temporizador en tiempo real a nivel de hardware y estado de turno activo.
  - **Dynamic Island Expanded:** Visualización completa de fase de turno (Turno activo vs. Refrigerio), badge semántico de geocerca (Dentro/Fuera de zona asignada), dirección y sede corporativa.
  - **Lock Screen / StandBy:** Tarjeta Obsidian de alta elegancia visual con cronómetro continuo sincronizado sin consumo excesivo de batería.

### 2. Notificaciones en Vivo en Tiempo Real (Android)
- Implementación nativa con **RemoteViews** y canal de notificación persistente de alta prioridad silenciosa (`IMPORTANCE_HIGH`).
- Uso de componentes nativos `<Chronometer>` de hardware para un conteo fluido de segundos sin necesidad de despertar el procesador periódicamente.
- Badges dinámicos con tonalidades Obsidian y Emerald: estado de permanencia en geocerca (`Dentro de Geocerca` / `Fuera de Geocerca`) y fase de turno (`Turno de Trabajo` / `Refrigerio`).
- Integración con el sistema mediante botón de acción directo (`Abrir AsisGo`) que devuelve al usuario al contexto exacto de su jornada.

### 3. Modo Offline Automático y Sincronización Bidireccional
- **Detección de Conectividad en Tiempo Real:** Monitoreo activo de interfaces de red con capacidad de simulación de desconexión para pruebas de campo.
- **Cola Local Persistente:** Cuando el dispositivo pierde conectividad o ingresa a zonas de baja cobertura (sótanos, plantas industriales), las marcaciones se almacenan localmente con el indicador `isSynced = false`.
- **Auto-Sync:** Al restablecerse la conexión a Internet, el servicio sincroniza automáticamente los registros en cola sin requerir intervención manual del colaborador, emitiendo retroalimentación visual y háptica.

### 4. Módulo de Justificaciones e Incidencias Laborales
- Gestión completa de incidencias y justificaciones vinculadas al historial de asistencia.
- Categorización de solicitudes: Permiso médico, Cita médica, Fallas técnicas/dispositivo, Falta injustificada, Comisión de servicios y Asuntos particulares.
- Selector de fecha, registro detallado de motivos y soporte para adjuntos fotográficos y documentales (JPG, PNG, PDF).
- Visor integrado de documentos adjuntos con interfaz modal y zoom.

### 5. Sistema de Feedback Háptico y Sensorial
- Servicio centralizado de vibraciones táctiles (`HapticFeedbackService`): respuestas hápticas diferenciadas para marcaciones exitosas, transiciones de turno, sincronización en segundo plano y alertas de seguridad.
- Retroalimentación auditiva sutil y configurable desde las preferencias de perfil del colaborador.

### 6. Seguridad Avanzada y Detección Anti-Fake GPS
- Verificación de telemetría de hardware en tiempo de ejecución para identificar proveedores simulados (Mock Providers), aplicaciones de falseo de ubicación y anomalías en la precisión de señal satelital.
- Bloqueo preventivo de marcaciones cuando se detectan discrepancias o herramientas de suplantación activas en el dispositivo.
- Control de modo estricto en producción con bandera configurable a nivel de servicio para pruebas unitarias y entornos de desarrollo controlados.

### 7. Jerarquía Corporativa Multi-Empresa de Tres Niveles
El sistema implementa una estructura de datos normalizada para organizaciones corporativas:
- **Nivel 1: Empresa (Corporativo):** Datos fiscales, identidad visual, RUC y directivas de asistencia.
- **Nivel 2: Sucursales (Sedes):** Establecimientos físicos distribuidos geográficamente en Lima (BCP, BBVA, Interbank, Scotiabank, Entelgy) con códigos de identificación únicos.
- **Nivel 3: Geocercas Autorizadas (Centros):** Coordenadas geodésicas centrales (latitud, longitud), radios de tolerancia métrica (100 m - 150 m) y nombres asignados por área operativa (Oficinas Administrativas, Torre Principal, Plataforma Financiera).

### 8. Aislamiento Visual en Mapa Interactivo
- Renderizado de mapa en modo Midnight Dark optimizado para visualización en exteriores y reducción de fatiga visual.
- Aislamiento estricto de entidades: al seleccionar una empresa o sede específica, el mapa renderiza exclusivamente las geocercas y marcadores de dicha entidad, evitando la saturación de elementos ajenos.
- Controles de recentrado automático, sincronización satelital y exploración directa de sedes asociadas.

### 9. Ciclo de Turno Laboral y Marcación Rápida
- Máquina de estados para el ciclo de jornada:
  1. Entrada inicial (`checkIn`)
  2. Inicio de refrigerio (`lunchStart`)
  3. Fin de refrigerio (`lunchEnd`)
  4. Salida de jornada (`checkOut` o salida anticipada)
- Modal simplificado de asistencia diseñado para registro rápido: cálculo geodésico Haversine de proximidad, verificación facial mediante selfie frontal y campo opcional para notas operativas.

### 10. Temporizador de Seguridad y Expiración de Sesión
- Cierre preventivo de sesión tras 10 minutos de permanencia en el sistema para resguardar la identidad del colaborador.
- Interfaz no intrusiva: despliegue de diálogo modal con fondo difuminado sobre la vista de mapa activa, informando de la expiración sin cierres abruptos.
- Redirección controlada a la pantalla de autenticación para nuevo ingreso manual de credenciales o biometría.

### 11. Historial de Asistencia y Calendario de Auditoría
- Resumen mensual de métricas clave (horas efectivas laboradas, días asistidos y porcentaje global de puntualidad con tolerancia de entrada).
- Vista de pestañas integradas para alternar entre "Historial de Marcas" y "Justificaciones".

---

## Arquitectura de Software

El proyecto sigue una arquitectura desacoplada basada en Clean Architecture y el patrón de gestión de estado BLoC / Cubit:

```
lib/
├── app/
│   └── main_navigation_shell.dart         # Contenedor de navegación principal y escucha de expiración
├── core/
│   ├── constants/
│   │   ├── app_colors.dart                # Paleta de color corporativa y diseño medianoche
│   │   └── app_constants.dart             # Llaves de almacenamiento y parámetros del sistema
│   ├── contracts/
│   │   ├── i_attendance_repository.dart   # Contrato de repositorio de asistencia
│   │   ├── i_location_service.dart        # Contrato de servicios de localización
│   │   ├── i_security_service.dart        # Contrato de servicios de seguridad anti-mock
│   │   └── i_storage_service.dart         # Contrato para almacenamiento local
│   ├── security/
│   │   ├── security_service.dart          # Lógica de detección de proveedores simulados
│   │   ├── security_check_result.dart     # Modelo de dictamen de integridad
│   │   └── session_timer_manager.dart     # Gestor del temporizador de inactividad
│   ├── services/
│   │   ├── connectivity_service.dart      # Monitoreo de conectividad y simulación offline
│   │   ├── haptic_feedback_service.dart   # Centralización de vibración y sonido háptico
│   │   ├── live_activity_service.dart     # Enlace MethodChannel con iOS ActivityKit
│   │   ├── location_service.dart          # Transmisión GPS y fórmulas geodésicas Haversine
│   │   ├── notification_service.dart      # Notificaciones locales en vivo (Android RemoteViews)
│   │   ├── offline_sync_service.dart      # Gestión de cola y auto-sincronización
│   │   └── storage_service.dart           # Persistencia local mediante SharedPreferences
│   ├── theme/
│   │   └── app_theme.dart                 # Configuración de temas claro y medianoche oscuro
│   ├── utils/
│   │   └── date_formatter.dart            # Utilidades de formato de fechas y horas en español
│   └── widgets/
│       ├── asis_action_button.dart        # Botón con soporte de estados y temas de alto contraste
│       ├── asis_glass_card.dart           # Componente de tarjeta con efecto frosted glass
│       ├── asis_security_dialog.dart      # Diálogo modal de alerta de suplantación GPS
│       └── asis_session_expired_dialog.dart # Diálogo modal de expiración de sesión
└── features/
    ├── attendance_map/
    │   ├── data/
    │   │   ├── attendance_repository.dart # Repositorio de marcas y soporte de cola offline
    │   │   └── branch_repository.dart     # Repositorio multi-empresa y sedes de Lima
    │   ├── domain/
    │   │   ├── attendance_record.dart     # Entidad de registro de asistencia con flag de sincronización
    │   │   ├── branch.dart                # Entidad de sede y geocercas
    │   │   ├── company.dart               # Entidad corporativa
    │   │   └── shift_phase.dart           # Enum de fases de turno y transiciones
    │   └── presentation/
    │       ├── cubit/                     # Cubits de asistencia y localización
    │       ├── views/                     # Pantalla de mapa y explorador de sucursales
    │       └── widgets/                   # Docks, botones flotantes, badges offline y modal de marcación
    ├── auth/
    │   ├── data/auth_repository.dart      # Repositorio de credenciales y usuarios demo
    │   ├── domain/user_model.dart         # Modelo de usuario corporativo
    │   └── presentation/                  # Vistas y cubit de autenticación
    ├── calendar_history/
    │   └── presentation/                  # Cubit y vista de calendario con pestañas de auditoría
    ├── justifications/
    │   ├── data/justification_repository.dart # Persistencia y categorías de incidencias
    │   ├── domain/justification_model.dart    # Modelo de entidad de justificación
    │   └── presentation/
    │       ├── cubit/                         # Cubit de justificaciones
    │       ├── views/                         # Lista de justificaciones y visor de adjuntos
    │       └── widgets/                       # Formulario modal de nueva justificación
    └── profile/
        └── views/profile_view.dart        # Vista de perfil, configuración y simulación de turnos
```

---

## Extensiones Nativas

### iOS (WidgetKit & ActivityKit)
- Ubicación: `ios/AsisGoWidgets/`
- Archivos clave:
  - `AsisGoWidgetsBundle.swift`: Punto de entrada del bundle de widgets.
  - `AsisGoWidgetsLiveActivity.swift`: Definición de vistas para Dynamic Island (compactTrailing, compactLeading, minimal, expanded) y Lock Screen banner.
  - `AsisGoWidgets.swift`: Atributos y estado de contenido de Live Activity (`AsisGoLiveActivityAttributes`).

### Android (RemoteViews & Foreground Service)
- Ubicación: `android/app/src/main/`
- Archivos clave:
  - `res/layout/notification_island_expanded.xml`: Layout personalizado para bandeja desplegada con `<Chronometer>` nativo.
  - `res/layout/notification_island_collapsed.xml`: Layout compacto para vista colapsada en barra de notificaciones.
  - `kotlin/com/asisgo/app/asisgo/MainActivity.kt`: MethodChannel para despachar `RemoteViews`, canal de notificación persistente y enlace con el ciclo de vida.

---

## Requisitos del Entorno

- **Flutter SDK:** >= 3.19.0 (Canal Stable)
- **Dart SDK:** >= 3.3.0
- **Android:** API Nivel 26 (Android 8.0) o superior para Live Notifications
- **iOS:** iOS 15.0+ (iOS 16.1+ para soporte de Dynamic Island / Live Activities)
- **macOS:** Requerido para compilación iOS / Xcode

---

## Instalación y Ejecución

1. Clonar el repositorio:
```bash
git clone https://github.com/VMichael1999/AsisGo.git
cd AsisGo
```

2. Descargar las dependencias del proyecto:
```bash
flutter pub get
```

3. Ejecutar el análisis estático de código:
```bash
dart analyze
```

4. Ejecutar la suite completa de pruebas unitarias:
```bash
flutter test
```

5. Iniciar la aplicación en el dispositivo o simulador activo:
```bash
flutter run
```

---

## Cuentas de Acceso de Demostración

Para fines de prueba y validación rápida, la aplicación incluye credenciales precargadas:

| Correo Electrónico | Contraseña | Cargo Asignado | Empresa |
| :--- | :--- | :--- | :--- |
| `carlos.mendoza@empresa.com` | `123456` | Senior Systems Engineer | Banco de Crédito BCP |
| `ana.torres@empresa.com` | `123456` | Lead Security Architect | BBVA Perú |

---

## Licencia

Este proyecto está bajo licencia de uso corporativo confidencial. Todos los derechos reservados.
