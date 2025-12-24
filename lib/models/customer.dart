import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'customer.g.dart';

@HiveType(typeId: 0)
enum CustomerStatus {
  @HiveField(0)
  active,
  @HiveField(1)
  inactive,
  @HiveField(2)
  suspended,
}

extension CustomerStatusExtension on CustomerStatus {
  String get displayName {
    switch (this) {
      case CustomerStatus.active:
        return 'Activo';
      case CustomerStatus.inactive:
        return 'Inactivo';
      case CustomerStatus.suspended:
        return 'Suspendido';
    }
  }
}

@HiveType(typeId: 1)
@JsonSerializable()
class Customer {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String phone;
  @HiveField(3)
  final String address;
  @HiveField(4)
  final int assignedEquipmentCount;
  @HiveField(5)
  final int totalRentals;
  @HiveField(6)
  final DateTime lastRentalDate;
  @HiveField(7)
  final CustomerStatus status;
  @HiveField(8)
  final String? email;
  @HiveField(9)
  final String? contactPerson;
  @HiveField(10)
  final List<String>? equipmentIds;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.assignedEquipmentCount,
    required this.totalRentals,
    required this.lastRentalDate,
    required this.status,
    this.email,
    this.contactPerson,
    this.equipmentIds,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => _$CustomerFromJson(json);
  Map<String, dynamic> toJson() => _$CustomerToJson(this);

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    int? assignedEquipmentCount,
    int? totalRentals,
    DateTime? lastRentalDate,
    CustomerStatus? status,
    String? email,
    String? contactPerson,
    List<String>? equipmentIds,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      assignedEquipmentCount: assignedEquipmentCount ?? this.assignedEquipmentCount,
      totalRentals: totalRentals ?? this.totalRentals,
      lastRentalDate: lastRentalDate ?? this.lastRentalDate,
      status: status ?? this.status,
      email: email ?? this.email,
      contactPerson: contactPerson ?? this.contactPerson,
      equipmentIds: equipmentIds ?? this.equipmentIds,
    );
  }
}
