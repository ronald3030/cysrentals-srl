# C&S RENTALS SRL – Aplicación Flutter (Gestión de Alquileres)

Aplicación móvil profesional para la gestión integral de alquiler de equipos de C&S Rentals SRL. Incluye tablero gerencial, inventario, clientes, mantenimiento e historial, y perfil; completamente en español y con identidad visual corporativa.

## ✨ Novedades principales

- AppBars estandarizados: “C&S Rentals SRL” arriba y el título de la sección debajo (todas las pantallas)
- Dashboard gerencial con KPIs: Alquileres Activos, Vencidos, Utilización (%), Próximos a Vencer
- Gráficos interactivos (fl_chart):
  - Línea “Alquileres – Semana / Mes” con tooltips (Lun–Dom / Ene–Dic)
  - Pastel “Estado de equipos” con realce al tocar
- Clientes: “Actualizar Dirección”, ficha con pestañas Información / Historial y métricas (alquileres + ingresos RD$)
- Mantenimiento: métricas operativas (Pendientes/En Proceso/Urgentes) y gerenciales (Equipos Fuera, Técnicos, Costo Semanal RD$)
- Perfil 100% en español (se removieron Years/Tasks/Reviews). Acciones: Cambiar Contraseña, Respaldar Datos, Cerrar Sesión
- Barra inferior compacta, alineada y sin overflows
- Inventario: filtros “Categoría” y “Estado”, tarjetas optimizadas y grilla estable
- Datos localizados: moneda RD$, direcciones y teléfonos dominicanos

## 🎛️ Secciones de la app

### 1) Tablero de Control
- KPIs: Activos, Vencidos, Utilización, Próximos a Vencer
- Analíticas interactivas:
  - Línea con selector Semana/Mes y tooltips en español
  - Pastel de estado con realce por toque
- Acciones rápidas: Nuevo Alquiler, Agregar Equipo, Crear Tarea
- Pull-to-Refresh con animación

### 2) Inventario de Equipos
- Vista grilla/lista, tarjetas compactas y responsivas
- Búsqueda por nombre, ID y categoría
- Filtros con chips: “Categoría” y “Estado”
- Chips de estado con color (Disponible, Alquilado, Mantenimiento, Fuera de Servicio)

### 3) Clientes
- Acciones: llamar, ver equipos, actualizar dirección
- Detalle con pestañas:
  - Información: contacto, dirección, equipos, total de alquileres, último alquiler
  - Historial: tarjetas por alquiler (equipo, fechas, ubicación, días, tarifa diaria, costo total RD$)
- Métricas del cliente: número de alquileres e ingresos totales (RD$)

### 4) Mantenimiento y Tareas
- Datos realistas (preventivo/correctivo, certificaciones, técnicos)
- Métricas:
  - Operativas: Pendientes, En Proceso, Urgentes
  - Gerenciales: Equipos Fuera, Técnicos, Costo Semanal (RD$)
- Ordenes con prioridad/estado, técnico asignado y tiempos (programado, inicio, fin)
- FAB: “Nueva Orden de Mantenimiento”

### 5) Perfil
- Datos: nombre, rol, sucursal, correo, teléfono, ID empleado
- Preferencias: Notificaciones, Reducir Movimiento, Modo Oscuro, Idioma
- Cuenta: Cambiar Contraseña, Respaldar Datos, Cerrar Sesión
- Acerca de: versión, build, empresa, Política de Privacidad y Términos de Servicio

## 🧩 Interacción, animaciones y UX
- Animaciones escalonadas (staggered) en listas y tarjetas
- Microinteracciones: presión de botones, elevación de tarjetas, FAB elástico, toggle de búsqueda
- Accesibilidad: “Reducir Movimiento” en Ajustes
- Rendimiento estable (60fps) y correcciones de RenderFlex overflow

## 🛠️ Implementación técnica

### Dependencias principales
```yaml
dependencies:
  flutter: sdk
  flutter_staggered_animations: ^1.1.1
  fl_chart: ^0.69.2
  shared_preferences: ^2.2.2
  google_fonts: ^6.2.1
  lottie: ^3.1.2
```

### Arquitectura
- Estructura por pantallas (screens) con widgets reutilizables
- Tema corporativo centralizado (tipografías, colores, tarjetas)
- Modelos: `equipment.dart`, `customer.dart`, `maintenance_task.dart`
- Estado de preferencias con `SharedPreferences`

## 📁 Estructura del proyecto
```
lib/
├── main.dart
├── theme/app_theme.dart
├── screens/
│   ├── main_screen.dart
│   ├── dashboard/dashboard_screen.dart
│   ├── inventory/{inventory_screen.dart,equipment_detail_screen.dart}
│   ├── customers/customers_screen.dart
│   ├── maintenance/{maintenance_screen.dart,maintenance_history_screen.dart}
│   └── profile/profile_screen.dart
├── widgets/{animated_counter.dart,kpi_card.dart,quick_action_button.dart,
│           equipment_card.dart,filter_chip_row.dart,customer_card.dart,task_card.dart}
└── models/{equipment.dart,customer.dart,maintenance_task.dart}
```

## 🔧 Cómo ejecutar
1) Requisitos: Flutter 3.7+ y Dart; Android Studio o VS Code con extensiones Flutter
2) Instalar dependencias
```bash
flutter pub get
```
3) Ejecutar
```bash
flutter run
```

## 🗺️ Estándares de UI
- AppBar en todas las pantallas:
  - Línea 1: “C&S Rentals SRL” (rojo corporativo)
  - Línea 2: Título de la sección (tamaño mayor)
- Barra inferior: ícono + texto centrados, tamaño compacto
- Textos y diálogos 100% en español

## 📦 Datos de demostración
- Clientes, equipos y tareas con información dominicana (direcciones y teléfonos RD)
- Montos en pesos dominicanos (RD$)
- Historial de alquileres por cliente con ubicaciones y costos

## 🚀 Próximos pasos sugeridos
- Integración API (datos en tiempo real)
- Recordatorios push (vencimientos/mantenimiento)
- Cache/offline para zonas sin cobertura
- Reportería avanzada (ingresos por cliente/equipo/periodo)
- Tema oscuro completo

---

Hecha con ❤️ en Flutter para C&S Rentals SRL

Diseño profesional, moderno y optimizado para la operación diaria de alquileres.