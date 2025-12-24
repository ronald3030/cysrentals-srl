import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'equipment.g.dart';

@HiveType(typeId: 2)
enum EquipmentStatus {
  @HiveField(0)
  available,
  @HiveField(1)
  rented,
  @HiveField(2)
  maintenance,
  @HiveField(3)
  outOfService,
}

extension EquipmentStatusExtension on EquipmentStatus {
  String get displayName {
    switch (this) {
      case EquipmentStatus.available:
        return 'Disponible';
      case EquipmentStatus.rented:
        return 'Alquilado';
      case EquipmentStatus.maintenance:
        return 'Mantenimiento';
      case EquipmentStatus.outOfService:
        return 'Fuera de Servicio';
    }
  }
}

@HiveType(typeId: 3)
@JsonSerializable()
class Equipment {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String category;
  @HiveField(3)
  final EquipmentStatus status;
  @HiveField(4)
  final String? imageUrl;
  @HiveField(5)
  final String description;
  @HiveField(6)
  final String? customer;
  @HiveField(7)
  final String? location;
  @HiveField(8)
  final DateTime? rentalStartDate;
  @HiveField(9)
  final DateTime? rentalEndDate;
  @HiveField(10)
  final double? dailyRate;
  @HiveField(11)
  final List<MaintenanceRecord>? maintenanceHistory;

  Equipment({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    this.imageUrl,
    required this.description,
    this.customer,
    this.location,
    this.rentalStartDate,
    this.rentalEndDate,
    this.dailyRate,
    this.maintenanceHistory,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) => _$EquipmentFromJson(json);
  Map<String, dynamic> toJson() => _$EquipmentToJson(this);

  Equipment copyWith({
    String? id,
    String? name,
    String? category,
    EquipmentStatus? status,
    String? imageUrl,
    String? description,
    String? customer,
    String? location,
    DateTime? rentalStartDate,
    DateTime? rentalEndDate,
    double? dailyRate,
    List<MaintenanceRecord>? maintenanceHistory,
  }) {
    return Equipment(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      customer: customer ?? this.customer,
      location: location ?? this.location,
      rentalStartDate: rentalStartDate ?? this.rentalStartDate,
      rentalEndDate: rentalEndDate ?? this.rentalEndDate,
      dailyRate: dailyRate ?? this.dailyRate,
      maintenanceHistory: maintenanceHistory ?? this.maintenanceHistory,
    );
  }
}

@HiveType(typeId: 4)
@JsonSerializable()
class MaintenanceRecord {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final DateTime date;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final String technician;
  @HiveField(4)
  final double? cost;
  @HiveField(5)
  final MaintenanceType type;

  MaintenanceRecord({
    required this.id,
    required this.date,
    required this.description,
    required this.technician,
    this.cost,
    required this.type,
  });

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) => _$MaintenanceRecordFromJson(json);
  Map<String, dynamic> toJson() => _$MaintenanceRecordToJson(this);
}

@HiveType(typeId: 5)
enum MaintenanceType {
  @HiveField(0)
  routine,
  @HiveField(1)
  repair,
  @HiveField(2)
  inspection,
  @HiveField(3)
  upgrade,
}

extension MaintenanceTypeExtension on MaintenanceType {
  String get displayName {
    switch (this) {
      case MaintenanceType.routine:
        return 'Rutina';
      case MaintenanceType.repair:
        return 'Reparación';
      case MaintenanceType.inspection:
        return 'Inspección';
      case MaintenanceType.upgrade:
        return 'Actualización';
    }
  }
}
