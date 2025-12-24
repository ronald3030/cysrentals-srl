// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MaintenanceTaskAdapter extends TypeAdapter<MaintenanceTask> {
  @override
  final int typeId = 8;

  @override
  MaintenanceTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MaintenanceTask(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      equipmentId: fields[3] as String,
      equipmentName: fields[4] as String,
      priority: fields[5] as TaskPriority,
      status: fields[6] as TaskStatus,
      scheduledDate: fields[7] as DateTime,
      assignedTechnician: fields[8] as String,
      estimatedDuration: fields[9] as Duration,
      startedAt: fields[10] as DateTime?,
      completedAt: fields[11] as DateTime?,
      attachments: (fields[12] as List?)?.cast<String>(),
      notes: fields[13] as String?,
      cost: fields[14] as double?,
      taskType: fields[15] as TaskType,
      deliveryDate: fields[16] as DateTime?,
      finishDate: fields[17] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, MaintenanceTask obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.equipmentId)
      ..writeByte(4)
      ..write(obj.equipmentName)
      ..writeByte(5)
      ..write(obj.priority)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.scheduledDate)
      ..writeByte(8)
      ..write(obj.assignedTechnician)
      ..writeByte(9)
      ..write(obj.estimatedDuration)
      ..writeByte(10)
      ..write(obj.startedAt)
      ..writeByte(11)
      ..write(obj.completedAt)
      ..writeByte(12)
      ..write(obj.attachments)
      ..writeByte(13)
      ..write(obj.notes)
      ..writeByte(14)
      ..write(obj.cost)
      ..writeByte(15)
      ..write(obj.taskType)
      ..writeByte(16)
      ..write(obj.deliveryDate)
      ..writeByte(17)
      ..write(obj.finishDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaintenanceTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskPriorityAdapter extends TypeAdapter<TaskPriority> {
  @override
  final int typeId = 6;

  @override
  TaskPriority read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskPriority.high;
      case 1:
        return TaskPriority.medium;
      case 2:
        return TaskPriority.low;
      default:
        return TaskPriority.high;
    }
  }

  @override
  void write(BinaryWriter writer, TaskPriority obj) {
    switch (obj) {
      case TaskPriority.high:
        writer.writeByte(0);
        break;
      case TaskPriority.medium:
        writer.writeByte(1);
        break;
      case TaskPriority.low:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskPriorityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskTypeAdapter extends TypeAdapter<TaskType> {
  @override
  final int typeId = 9;

  @override
  TaskType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskType.maintenance;
      case 1:
        return TaskType.routine;
      case 2:
        return TaskType.repair;
      case 3:
        return TaskType.inspection;
      case 4:
        return TaskType.upgrade;
      default:
        return TaskType.maintenance;
    }
  }

  @override
  void write(BinaryWriter writer, TaskType obj) {
    switch (obj) {
      case TaskType.maintenance:
        writer.writeByte(0);
        break;
      case TaskType.routine:
        writer.writeByte(1);
        break;
      case TaskType.repair:
        writer.writeByte(2);
        break;
      case TaskType.inspection:
        writer.writeByte(3);
        break;
      case TaskType.upgrade:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskStatusAdapter extends TypeAdapter<TaskStatus> {
  @override
  final int typeId = 7;

  @override
  TaskStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskStatus.open;
      case 1:
        return TaskStatus.inProgress;
      case 2:
        return TaskStatus.completed;
      default:
        return TaskStatus.open;
    }
  }

  @override
  void write(BinaryWriter writer, TaskStatus obj) {
    switch (obj) {
      case TaskStatus.open:
        writer.writeByte(0);
        break;
      case TaskStatus.inProgress:
        writer.writeByte(1);
        break;
      case TaskStatus.completed:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MaintenanceTask _$MaintenanceTaskFromJson(Map<String, dynamic> json) =>
    MaintenanceTask(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      equipmentId: json['equipmentId'] as String,
      equipmentName: json['equipmentName'] as String,
      priority: $enumDecode(_$TaskPriorityEnumMap, json['priority']),
      status: $enumDecode(_$TaskStatusEnumMap, json['status']),
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      assignedTechnician: json['assignedTechnician'] as String,
      estimatedDuration:
          Duration(microseconds: (json['estimatedDuration'] as num).toInt()),
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      notes: json['notes'] as String?,
      cost: (json['cost'] as num?)?.toDouble(),
      taskType: $enumDecodeNullable(_$TaskTypeEnumMap, json['taskType']) ??
          TaskType.maintenance,
      deliveryDate: json['deliveryDate'] == null
          ? null
          : DateTime.parse(json['deliveryDate'] as String),
      finishDate: json['finishDate'] == null
          ? null
          : DateTime.parse(json['finishDate'] as String),
    );

Map<String, dynamic> _$MaintenanceTaskToJson(MaintenanceTask instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'equipmentId': instance.equipmentId,
      'equipmentName': instance.equipmentName,
      'priority': _$TaskPriorityEnumMap[instance.priority]!,
      'status': _$TaskStatusEnumMap[instance.status]!,
      'scheduledDate': instance.scheduledDate.toIso8601String(),
      'assignedTechnician': instance.assignedTechnician,
      'estimatedDuration': instance.estimatedDuration.inMicroseconds,
      'startedAt': instance.startedAt?.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'attachments': instance.attachments,
      'notes': instance.notes,
      'cost': instance.cost,
      'taskType': _$TaskTypeEnumMap[instance.taskType]!,
      'deliveryDate': instance.deliveryDate?.toIso8601String(),
      'finishDate': instance.finishDate?.toIso8601String(),
    };

const _$TaskPriorityEnumMap = {
  TaskPriority.high: 'high',
  TaskPriority.medium: 'medium',
  TaskPriority.low: 'low',
};

const _$TaskStatusEnumMap = {
  TaskStatus.open: 'open',
  TaskStatus.inProgress: 'inProgress',
  TaskStatus.completed: 'completed',
};

const _$TaskTypeEnumMap = {
  TaskType.maintenance: 'maintenance',
  TaskType.routine: 'routine',
  TaskType.repair: 'repair',
  TaskType.inspection: 'inspection',
  TaskType.upgrade: 'upgrade',
};
