import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/maintenance_task.dart';
import '../services/supabase_service.dart';

class MaintenanceProvider extends ChangeNotifier {
  List<MaintenanceTask> _tasks = [];
  bool _isLoading = false;
  String? _error;
  bool _isOnline = true;

  List<MaintenanceTask> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOnline => _isOnline;

  // Filtros
  List<MaintenanceTask> get openTasks =>
      _tasks.where((t) => t.status == TaskStatus.open).toList();

  List<MaintenanceTask> get inProgressTasks =>
      _tasks.where((t) => t.status == TaskStatus.inProgress).toList();

  List<MaintenanceTask> get completedTasks =>
      _tasks.where((t) => t.status == TaskStatus.completed).toList();

  List<MaintenanceTask> get highPriorityTasks =>
      _tasks.where((t) => t.priority == TaskPriority.high).toList();

  List<MaintenanceTask> get overdueTasks =>
      _tasks.where((t) => t.isOverdue).toList();

  // Estadísticas
  int get totalTasks => _tasks.length;
  int get pendingCount => openTasks.length;
  int get inProgressCount => inProgressTasks.length;
  int get urgentCount => highPriorityTasks.where((t) => t.status != TaskStatus.completed).length;
  int get overdueCount => overdueTasks.length;

  // Costos - Todas las tareas del mes actual con costo
  double get monthlyCost {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    
    return _tasks
        .where((t) => 
            t.scheduledDate.isAfter(firstDayOfMonth.subtract(const Duration(days: 1))) &&
            t.scheduledDate.isBefore(lastDayOfMonth.add(const Duration(days: 1))) &&
            t.cost != null)
        .fold(0.0, (sum, task) => sum + task.cost!);
  }

  // Costo semanal (últimas 4 semanas = aproximadamente un mes)
  double get weeklyCost {
    return monthlyCost / 4;
  }

  // Formatear costo para mostrar
  String get monthlyCostFormatted {
    if (monthlyCost >= 1000) {
      return 'RD\$${(monthlyCost / 1000).toStringAsFixed(1)}K';
    }
    return 'RD\$${monthlyCost.toStringAsFixed(0)}';
  }

  String get weeklyCostFormatted {
    if (weeklyCost >= 1000) {
      return 'RD\$${(weeklyCost / 1000).toStringAsFixed(1)}K';
    }
    return 'RD\$${weeklyCost.toStringAsFixed(0)}';
  }

  MaintenanceProvider() {
    print('🔨 MaintenanceProvider: Constructor iniciado');
    loadTasks();
  }

  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Intentar cargar de Supabase primero
      try {
        _tasks = await SupabaseService.getMaintenanceTasks();
        _isOnline = true;
        
        print('✅ MaintenanceProvider: Tareas cargadas desde Supabase: ${_tasks.length}');
        for (var task in _tasks) {
          print('  - ${task.id}: ${task.title} | Status: ${task.status.name} | Priority: ${task.priority.name}');
        }
        
        // Intentar guardar en Hive como caché (opcional, no crítico)
        try {
          final box = await Hive.openBox<MaintenanceTask>('maintenance_tasks');
          await box.clear();
          for (final task in _tasks) {
            await box.put(task.id, task);
          }
          print('💾 MaintenanceProvider: Tareas guardadas en Hive');
        } catch (hiveError) {
          print('⚠️ MaintenanceProvider: No se pudo guardar en Hive: $hiveError');
          // Continuar sin Hive, las tareas ya están en memoria
        }
      } catch (e) {
        print('❌ MaintenanceProvider: Error cargando de Supabase: $e');
        // Si falla Supabase, usar caché de Hive
        _isOnline = false;
        final box = await Hive.openBox<MaintenanceTask>('maintenance_tasks');
        _tasks = box.values.toList();
        
        // Si no hay datos en caché, cargar datos de ejemplo
        if (_tasks.isEmpty) {
          await _loadSampleData();
        }
      }
      
      _error = null;
    } catch (e) {
      _error = 'Error al cargar tareas: $e';
      print('❌ MaintenanceProvider: Error general: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTask(MaintenanceTask task) async {
    try {
      // Intentar guardar en Supabase primero
      try {
        await SupabaseService.createMaintenanceTask(task);
        _isOnline = true;
        // Recargar todas las tareas para obtener la versión actualizada desde Supabase
        await loadTasks();
      } catch (e) {
        _isOnline = false;
        // Si falla Supabase, guardar solo en Hive
        final box = await Hive.openBox<MaintenanceTask>('maintenance_tasks');
        await box.put(task.id, task);
        _tasks.add(task);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error al agregar tarea: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTask(MaintenanceTask task) async {
    try {
      // Intentar actualizar en Supabase primero
      try {
        await SupabaseService.updateMaintenanceTask(task);
        _isOnline = true;
        // Recargar todas las tareas para obtener la versión actualizada desde Supabase
        await loadTasks();
      } catch (e) {
        _isOnline = false;
        // Si falla Supabase, actualizar solo en Hive
        final box = await Hive.openBox<MaintenanceTask>('maintenance_tasks');
        await box.put(task.id, task);
        
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = task;
          notifyListeners();
        }
      }
    } catch (e) {
      _error = 'Error al actualizar tarea: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      // Intentar eliminar de Supabase primero
      try {
        await SupabaseService.deleteMaintenanceTask(id);
        _isOnline = true;
      } catch (e) {
        _isOnline = false;
      }
      
      final box = await Hive.openBox<MaintenanceTask>('maintenance_tasks');
      await box.delete(id);
      _tasks.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Error al eliminar tarea: $e';
      notifyListeners();
    }
  }

  MaintenanceTask? getTaskById(String id) {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  List<MaintenanceTask> getTasksByEquipment(String equipmentId) {
    return _tasks.where((t) => t.equipmentId == equipmentId).toList();
  }

  List<MaintenanceTask> filterByStatus(TaskStatus status) {
    return _tasks.where((t) => t.status == status).toList();
  }

  List<MaintenanceTask> filterByPriority(TaskPriority priority) {
    return _tasks.where((t) => t.priority == priority).toList();
  }

  Future<void> _loadSampleData() async {
    final sampleTasks = [
      MaintenanceTask(
        id: 'M001',
        title: 'Inspección de 500 horas - Excavadora CAT',
        description: 'Mantenimiento preventivo programado: cambio de aceite, filtros y revisión general del sistema hidráulico',
        equipmentId: 'E001',
        equipmentName: 'Excavadora CAT 320DL',
        priority: TaskPriority.high,
        status: TaskStatus.open,
        scheduledDate: DateTime.now().add(const Duration(days: 2)),
        assignedTechnician: 'Juan Pérez',
        estimatedDuration: const Duration(hours: 4),
      ),
      MaintenanceTask(
        id: 'M002',
        title: 'Reparación motor mezcladora',
        description: 'El motor presenta sobrecalentamiento. Requiere diagnóstico y posible cambio de componentes',
        equipmentId: 'E002',
        equipmentName: 'Mezcladora de Concreto 350L',
        priority: TaskPriority.medium,
        status: TaskStatus.inProgress,
        scheduledDate: DateTime.now().subtract(const Duration(days: 1)),
        assignedTechnician: 'Carlos Martínez',
        estimatedDuration: const Duration(hours: 3),
        startedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      MaintenanceTask(
        id: 'M003',
        title: 'Afilado de cadena motosierra',
        description: 'Mantenimiento rutinario: afilar cadena, limpiar filtro de aire y revisar sistema de lubricación',
        equipmentId: 'E003',
        equipmentName: 'Motosierra STIHL MS 381',
        priority: TaskPriority.high,
        status: TaskStatus.open,
        scheduledDate: DateTime.now(),
        assignedTechnician: 'Luis Rodríguez',
        estimatedDuration: const Duration(hours: 1),
      ),
      MaintenanceTask(
        id: 'M004',
        title: 'Revisión general taladro',
        description: 'Inspección de baterías, mandril y sistemas de percusión',
        equipmentId: 'E004',
        equipmentName: 'Taladro de Impacto DeWalt 20V',
        priority: TaskPriority.low,
        status: TaskStatus.completed,
        scheduledDate: DateTime.now().subtract(const Duration(days: 7)),
        assignedTechnician: 'Miguel Ángel',
        estimatedDuration: const Duration(minutes: 30),
        startedAt: DateTime.now().subtract(const Duration(days: 7, hours: 2)),
        completedAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];

    final box = await Hive.openBox<MaintenanceTask>('maintenance_tasks');
    for (final task in sampleTasks) {
      await box.put(task.id, task);
    }
    _tasks = sampleTasks;
  }

  Future<void> refresh() async {
    await loadTasks();
  }
}
