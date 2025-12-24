// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'equipment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EquipmentAdapter extends TypeAdapter<Equipment> {
  @override
  final int typeId = 3;

  @override
  Equipment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Equipment(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as String,
      status: fields[3] as EquipmentStatus,
      imageUrl: fields[4] as String?,
      description: fields[5] as String,
      customer: fields[6] as String?,
      location: fields[7] as String?,
      rentalStartDate: fields[8] as DateTime?,
      rentalEndDate: fields[9] as DateTime?,
      dailyRate: fields[10] as double?,
      maintenanceHistory: (fields[11] as List?)?.cast<MaintenanceRecord>(),
    );
  }

  @override
  void write(BinaryWriter writer, Equipment obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.imageUrl)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.customer)
      ..writeByte(7)
      ..write(obj.location)
      ..writeByte(8)
      ..write(obj.rentalStartDate)
      ..writeByte(9)
      ..write(obj.rentalEndDate)
      ..writeByte(10)
      ..write(obj.dailyRate)
      ..writeByte(11)
      ..write(obj.maintenanceHistory);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EquipmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MaintenanceRecordAdapter extends TypeAdapter<MaintenanceRecord> {
  @override
  final int typeId = 4;

  @override
  MaintenanceRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MaintenanceRecord(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      description: fields[2] as String,
      technician: fields[3] as String,
      cost: fields[4] as double?,
      type: fields[5] as MaintenanceType,
    );
  }

  @override
  void write(BinaryWriter writer, MaintenanceRecord obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.technician)
      ..writeByte(4)
      ..write(obj.cost)
      ..writeByte(5)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaintenanceRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EquipmentStatusAdapter extends TypeAdapter<EquipmentStatus> {
  @override
  final int typeId = 2;

  @override
  EquipmentStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EquipmentStatus.available;
      case 1:
        return EquipmentStatus.rented;
      case 2:
        return EquipmentStatus.maintenance;
      case 3:
        return EquipmentStatus.outOfService;
      default:
        return EquipmentStatus.available;
    }
  }

  @override
  void write(BinaryWriter writer, EquipmentStatus obj) {
    switch (obj) {
      case EquipmentStatus.available:
        writer.writeByte(0);
        break;
      case EquipmentStatus.rented:
        writer.writeByte(1);
        break;
      case EquipmentStatus.maintenance:
        writer.writeByte(2);
        break;
      case EquipmentStatus.outOfService:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EquipmentStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MaintenanceTypeAdapter extends TypeAdapter<MaintenanceType> {
  @override
  final int typeId = 5;

  @override
  MaintenanceType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MaintenanceType.routine;
      case 1:
        return MaintenanceType.repair;
      case 2:
        return MaintenanceType.inspection;
      case 3:
        return MaintenanceType.upgrade;
      default:
        return MaintenanceType.routine;
    }
  }

  @override
  void write(BinaryWriter writer, MaintenanceType obj) {
    switch (obj) {
      case MaintenanceType.routine:
        writer.writeByte(0);
        break;
      case MaintenanceType.repair:
        writer.writeByte(1);
        break;
      case MaintenanceType.inspection:
        writer.writeByte(2);
        break;
      case MaintenanceType.upgrade:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaintenanceTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Equipment _$EquipmentFromJson(Map<String, dynamic> json) => Equipment(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      status: $enumDecode(_$EquipmentStatusEnumMap, json['status']),
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String,
      customer: json['customer'] as String?,
      location: json['location'] as String?,
      rentalStartDate: json['rentalStartDate'] == null
          ? null
          : DateTime.parse(json['rentalStartDate'] as String),
      rentalEndDate: json['rentalEndDate'] == null
          ? null
          : DateTime.parse(json['rentalEndDate'] as String),
      dailyRate: (json['dailyRate'] as num?)?.toDouble(),
      maintenanceHistory: (json['maintenanceHistory'] as List<dynamic>?)
          ?.map((e) => MaintenanceRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$EquipmentToJson(Equipment instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': instance.category,
      'status': _$EquipmentStatusEnumMap[instance.status]!,
      'imageUrl': instance.imageUrl,
      'description': instance.description,
      'customer': instance.customer,
      'location': instance.location,
      'rentalStartDate': instance.rentalStartDate?.toIso8601String(),
      'rentalEndDate': instance.rentalEndDate?.toIso8601String(),
      'dailyRate': instance.dailyRate,
      'maintenanceHistory': instance.maintenanceHistory,
    };

const _$EquipmentStatusEnumMap = {
  EquipmentStatus.available: 'available',
  EquipmentStatus.rented: 'rented',
  EquipmentStatus.maintenance: 'maintenance',
  EquipmentStatus.outOfService: 'outOfService',
};

MaintenanceRecord _$MaintenanceRecordFromJson(Map<String, dynamic> json) =>
    MaintenanceRecord(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String,
      technician: json['technician'] as String,
      cost: (json['cost'] as num?)?.toDouble(),
      type: $enumDecode(_$MaintenanceTypeEnumMap, json['type']),
    );

Map<String, dynamic> _$MaintenanceRecordToJson(MaintenanceRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'description': instance.description,
      'technician': instance.technician,
      'cost': instance.cost,
      'type': _$MaintenanceTypeEnumMap[instance.type]!,
    };

const _$MaintenanceTypeEnumMap = {
  MaintenanceType.routine: 'routine',
  MaintenanceType.repair: 'repair',
  MaintenanceType.inspection: 'inspection',
  MaintenanceType.upgrade: 'upgrade',
};
