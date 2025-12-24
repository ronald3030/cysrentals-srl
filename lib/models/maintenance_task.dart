import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'maintenance_task.g.dart';

@HiveType(typeId: 6)
enum TaskPriority {
  @HiveField(0)
  high,
  @HiveField(1)
  medium,
  @HiveField(2)
  low,
}

extension TaskPriorityExtension on TaskPriority {
  String get displayName {
    switch (this) {
      case TaskPriority.high:
        return 'Alta';
      case TaskPriority.medium:
        return 'Media';
      case TaskPriority.low:
        return 'Baja';
    }
  }
}

@HiveType(typeId: 9)
enum TaskType {
  @HiveField(0)
  maintenance,
  @HiveField(1)
  routine,
  @HiveField(2)
  repair,
  @HiveField(3)
  inspection,
  @HiveField(4)
  upgrade,
}

extension TaskTypeExtension on TaskType {
  String get displayName {
    switch (this) {
      case TaskType.maintenance:
        return 'Mantenimiento';
      case TaskType.routine:
        return 'Rutina';
      case TaskType.repair:
        return 'Reparación';
      case TaskType.inspection:
        return 'Inspección';
      case TaskType.upgrade:
        return 'Actualización';
    }
  }
}

@HiveType(typeId: 7)
enum TaskStatus {
  @HiveField(0)
  open,
  @HiveField(1)
  inProgress,
  @HiveField(2)
  completed,
}

extension TaskStatusExtension on TaskStatus {
  String get displayName {
    switch (this) {
      case TaskStatus.open:
        return 'Abierta';
      case TaskStatus.inProgress:
        return 'En Progreso';
      case TaskStatus.completed:
        return 'Completada';
    }
  }
}

@HiveType(typeId: 8)
@JsonSerializable()
class MaintenanceTask {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final String equipmentId;
  @HiveField(4)
  final String equipmentName;
  @HiveField(5)
  final TaskPriority priority;
  @HiveField(6)
  final TaskStatus status;
  @HiveField(7)
  final DateTime scheduledDate;
  @HiveField(8)
  final String assignedTechnician;
  @HiveField(9)
  final Duration estimatedDuration;
  @HiveField(10)
  final DateTime? startedAt;
  @HiveField(11)
  final DateTime? completedAt;
  @HiveField(12)
  final List<String>? attachments;
  @HiveField(13)
  final String? notes;
  @HiveField(14)
  final double? cost;
  @HiveField(15)
  final TaskType taskType;
  @HiveField(16)
  final DateTime? deliveryDate;
  @HiveField(17)
  final DateTime? finishDate;

  MaintenanceTask({
    required this.id,
    required this.title,
    required this.description,
    required this.equipmentId,
    required this.equipmentName,
    required this.priority,
    required this.status,
    required this.scheduledDate,
    required this.assignedTechnician,
    required this.estimatedDuration,
    this.startedAt,
    this.completedAt,
    this.attachments,
    this.notes,
    this.cost,
    this.taskType = TaskType.maintenance,
    this.deliveryDate,
    this.finishDate,
  });

  factory MaintenanceTask.fromJson(Map<String, dynamic> json) => _$MaintenanceTaskFromJson(json);
  Map<String, dynamic> toJson() => _$MaintenanceTaskToJson(this);

  MaintenanceTask copyWith({
    String? id,
    String? title,
    String? description,
    String? equipmentId,
    String? equipmentName,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? scheduledDate,
    String? assignedTechnician,
    Duration? estimatedDuration,
    DateTime? startedAt,
    DateTime? completedAt,
    List<String>? attachments,
    String? notes,
    double? cost,
    TaskType? taskType,
    DateTime? deliveryDate,
    DateTime? finishDate,
  }) {
    return MaintenanceTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      equipmentId: equipmentId ?? this.equipmentId,
      equipmentName: equipmentName ?? this.equipmentName,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      assignedTechnician: assignedTechnician ?? this.assignedTechnician,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      attachments: attachments ?? this.attachments,
      notes: notes ?? this.notes,
      cost: cost ?? this.cost,
      taskType: taskType ?? this.taskType,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      finishDate: finishDate ?? this.finishDate,
    );
  }

  bool get isOverdue {
    return status != TaskStatus.completed && 
           scheduledDate.isBefore(DateTime.now());
  }

  Duration? get actualDuration {
    if (startedAt != null && completedAt != null) {
      return completedAt!.difference(startedAt!);
    }
    return null;
  }
}
