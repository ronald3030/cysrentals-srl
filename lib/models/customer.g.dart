// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomerAdapter extends TypeAdapter<Customer> {
  @override
  final int typeId = 1;

  @override
  Customer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Customer(
      id: fields[0] as String,
      name: fields[1] as String,
      phone: fields[2] as String,
      address: fields[3] as String,
      assignedEquipmentCount: fields[4] as int,
      totalRentals: fields[5] as int,
      lastRentalDate: fields[6] as DateTime,
      status: fields[7] as CustomerStatus,
      email: fields[8] as String?,
      contactPerson: fields[9] as String?,
      equipmentIds: (fields[10] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Customer obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.address)
      ..writeByte(4)
      ..write(obj.assignedEquipmentCount)
      ..writeByte(5)
      ..write(obj.totalRentals)
      ..writeByte(6)
      ..write(obj.lastRentalDate)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.email)
      ..writeByte(9)
      ..write(obj.contactPerson)
      ..writeByte(10)
      ..write(obj.equipmentIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CustomerStatusAdapter extends TypeAdapter<CustomerStatus> {
  @override
  final int typeId = 0;

  @override
  CustomerStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CustomerStatus.active;
      case 1:
        return CustomerStatus.inactive;
      case 2:
        return CustomerStatus.suspended;
      default:
        return CustomerStatus.active;
    }
  }

  @override
  void write(BinaryWriter writer, CustomerStatus obj) {
    switch (obj) {
      case CustomerStatus.active:
        writer.writeByte(0);
        break;
      case CustomerStatus.inactive:
        writer.writeByte(1);
        break;
      case CustomerStatus.suspended:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Customer _$CustomerFromJson(Map<String, dynamic> json) => Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
      assignedEquipmentCount: (json['assignedEquipmentCount'] as num).toInt(),
      totalRentals: (json['totalRentals'] as num).toInt(),
      lastRentalDate: DateTime.parse(json['lastRentalDate'] as String),
      status: $enumDecode(_$CustomerStatusEnumMap, json['status']),
      email: json['email'] as String?,
      contactPerson: json['contactPerson'] as String?,
      equipmentIds: (json['equipmentIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$CustomerToJson(Customer instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phone': instance.phone,
      'address': instance.address,
      'assignedEquipmentCount': instance.assignedEquipmentCount,
      'totalRentals': instance.totalRentals,
      'lastRentalDate': instance.lastRentalDate.toIso8601String(),
      'status': _$CustomerStatusEnumMap[instance.status]!,
      'email': instance.email,
      'contactPerson': instance.contactPerson,
      'equipmentIds': instance.equipmentIds,
    };

const _$CustomerStatusEnumMap = {
  CustomerStatus.active: 'active',
  CustomerStatus.inactive: 'inactive',
  CustomerStatus.suspended: 'suspended',
};
