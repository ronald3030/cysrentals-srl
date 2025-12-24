import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'rental.g.dart';

@HiveType(typeId: 5)
enum RentalStatus {
  @HiveField(0)
  active,
  @HiveField(1)
  completed,
  @HiveField(2)
  cancelled,
}

@HiveType(typeId: 6)
enum RateType {
  @HiveField(0)
  day,
  @HiveField(1)
  hour,
}

@HiveType(typeId: 7)
@JsonSerializable()
class Rental {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String equipmentId;
  
  @HiveField(2)
  final String equipmentName;
  
  @HiveField(3)
  final String customerId;
  
  @HiveField(4)
  final String customerName;
  
  @HiveField(5)
  final DateTime startDate;
  
  @HiveField(6)
  final DateTime endDate;
  
  @HiveField(7)
  final String location;
  
  @HiveField(8)
  final double dailyRate;
  
  @HiveField(9)
  final RateType rateType;
  
  @HiveField(10)
  final double totalCost;
  
  @HiveField(11)
  final RentalStatus status;

  Rental({
    required this.id,
    required this.equipmentId,
    required this.equipmentName,
    required this.customerId,
    required this.customerName,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.dailyRate,
    required this.rateType,
    required this.totalCost,
    this.status = RentalStatus.active,
  });

  factory Rental.fromJson(Map<String, dynamic> json) => _$RentalFromJson(json);
  Map<String, dynamic> toJson() => _$RentalToJson(this);

  Rental copyWith({
    String? id,
    String? equipmentId,
    String? equipmentName,
    String? customerId,
    String? customerName,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    double? dailyRate,
    RateType? rateType,
    double? totalCost,
    RentalStatus? status,
  }) {
    return Rental(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
      equipmentName: equipmentName ?? this.equipmentName,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      dailyRate: dailyRate ?? this.dailyRate,
      rateType: rateType ?? this.rateType,
      totalCost: totalCost ?? this.totalCost,
      status: status ?? this.status,
    );
  }

  int get durationInDays => endDate.difference(startDate).inDays;
  int get durationInHours => endDate.difference(startDate).inHours;
  
  bool get isActive => status == RentalStatus.active;
  bool get isCompleted => status == RentalStatus.completed;
}
