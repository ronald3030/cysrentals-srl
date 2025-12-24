// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rental.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RentalAdapter extends TypeAdapter<Rental> {
  @override
  final int typeId = 7;

  @override
  Rental read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Rental(
      id: fields[0] as String,
      equipmentId: fields[1] as String,
      equipmentName: fields[2] as String,
      customerId: fields[3] as String,
      customerName: fields[4] as String,
      startDate: fields[5] as DateTime,
      endDate: fields[6] as DateTime,
      location: fields[7] as String,
      dailyRate: fields[8] as double,
      rateType: fields[9] as RateType,
      totalCost: fields[10] as double,
      status: fields[11] as RentalStatus,
    );
  }

  @override
  void write(BinaryWriter writer, Rental obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.equipmentId)
      ..writeByte(2)
      ..write(obj.equipmentName)
      ..writeByte(3)
      ..write(obj.customerId)
      ..writeByte(4)
      ..write(obj.customerName)
      ..writeByte(5)
      ..write(obj.startDate)
      ..writeByte(6)
      ..write(obj.endDate)
      ..writeByte(7)
      ..write(obj.location)
      ..writeByte(8)
      ..write(obj.dailyRate)
      ..writeByte(9)
      ..write(obj.rateType)
      ..writeByte(10)
      ..write(obj.totalCost)
      ..writeByte(11)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RentalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RentalStatusAdapter extends TypeAdapter<RentalStatus> {
  @override
  final int typeId = 5;

  @override
  RentalStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RentalStatus.active;
      case 1:
        return RentalStatus.completed;
      case 2:
        return RentalStatus.cancelled;
      default:
        return RentalStatus.active;
    }
  }

  @override
  void write(BinaryWriter writer, RentalStatus obj) {
    switch (obj) {
      case RentalStatus.active:
        writer.writeByte(0);
        break;
      case RentalStatus.completed:
        writer.writeByte(1);
        break;
      case RentalStatus.cancelled:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RentalStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RateTypeAdapter extends TypeAdapter<RateType> {
  @override
  final int typeId = 6;

  @override
  RateType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RateType.day;
      case 1:
        return RateType.hour;
      default:
        return RateType.day;
    }
  }

  @override
  void write(BinaryWriter writer, RateType obj) {
    switch (obj) {
      case RateType.day:
        writer.writeByte(0);
        break;
      case RateType.hour:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RateTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Rental _$RentalFromJson(Map<String, dynamic> json) => Rental(
      id: json['id'] as String,
      equipmentId: json['equipmentId'] as String,
      equipmentName: json['equipmentName'] as String,
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      location: json['location'] as String,
      dailyRate: (json['dailyRate'] as num).toDouble(),
      rateType: $enumDecode(_$RateTypeEnumMap, json['rateType']),
      totalCost: (json['totalCost'] as num).toDouble(),
      status: $enumDecodeNullable(_$RentalStatusEnumMap, json['status']) ??
          RentalStatus.active,
    );

Map<String, dynamic> _$RentalToJson(Rental instance) => <String, dynamic>{
      'id': instance.id,
      'equipmentId': instance.equipmentId,
      'equipmentName': instance.equipmentName,
      'customerId': instance.customerId,
      'customerName': instance.customerName,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'location': instance.location,
      'dailyRate': instance.dailyRate,
      'rateType': _$RateTypeEnumMap[instance.rateType]!,
      'totalCost': instance.totalCost,
      'status': _$RentalStatusEnumMap[instance.status]!,
    };

const _$RateTypeEnumMap = {
  RateType.day: 'day',
  RateType.hour: 'hour',
};

const _$RentalStatusEnumMap = {
  RentalStatus.active: 'active',
  RentalStatus.completed: 'completed',
  RentalStatus.cancelled: 'cancelled',
};
