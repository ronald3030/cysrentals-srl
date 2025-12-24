import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/equipment.dart';
import '../models/customer.dart';
import '../models/maintenance_task.dart';
import '../models/rental.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // ===========================================
  // EQUIPMENT METHODS
  // ===========================================

  /// Obtener todos los equipos
  static Future<List<Equipment>> getEquipment() async {
    try {
      final response = await _client
          .from('equipment')
          .select()
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => _equipmentFromSupabase(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener equipos: $e');
    }
  }

  /// Obtener equipo por ID
  static Future<Equipment?> getEquipmentById(String id) async {
    try {
      final response = await _client
          .from('equipment')
          .select()
          .eq('id', id)
          .single();
      
      return _equipmentFromSupabase(response);
    } catch (e) {
      return null;
    }
  }

  /// Crear nuevo equipo
  static Future<Equipment> createEquipment(Equipment equipment) async {
    try {
      final data = _equipmentToSupabase(equipment);
      final response = await _client
          .from('equipment')
          .insert(data)
          .select()
          .single();
      
      return _equipmentFromSupabase(response);
    } catch (e) {
      throw Exception('Error al crear equipo: $e');
    }
  }

  /// Actualizar equipo
  static Future<Equipment> updateEquipment(Equipment equipment) async {
    try {
      final data = _equipmentToSupabase(equipment);
      final response = await _client
          .from('equipment')
          .update(data)
          .eq('id', equipment.id)
          .select()
          .single();
      
      return _equipmentFromSupabase(response);
    } catch (e) {
      throw Exception('Error al actualizar equipo: $e');
    }
  }

  /// Eliminar equipo
  static Future<void> deleteEquipment(String id) async {
    try {
      await _client.from('equipment').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar equipo: $e');
    }
  }

  // ===========================================
  // CUSTOMER METHODS
  // ===========================================

  /// Obtener todos los clientes
  static Future<List<Customer>> getCustomers() async {
    try {
      final response = await _client
          .from('customers')
          .select()
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => _customerFromSupabase(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener clientes: $e');
    }
  }

  /// Obtener cliente por ID
  static Future<Customer?> getCustomerById(String id) async {
    try {
      final response = await _client
          .from('customers')
          .select()
          .eq('id', id)
          .single();
      
      return _customerFromSupabase(response);
    } catch (e) {
      return null;
    }
  }

  /// Crear nuevo cliente
  static Future<Customer> createCustomer(Customer customer) async {
    try {
      final data = _customerToSupabase(customer);
      final response = await _client
          .from('customers')
          .insert(data)
          .select()
          .single();
      
      return _customerFromSupabase(response);
    } catch (e) {
      throw Exception('Error al crear cliente: $e');
    }
  }

  /// Actualizar cliente
  static Future<Customer> updateCustomer(Customer customer) async {
    try {
      final data = _customerToSupabase(customer);
      final response = await _client
          .from('customers')
          .update(data)
          .eq('id', customer.id)
          .select()
          .single();
      
      return _customerFromSupabase(response);
    } catch (e) {
      throw Exception('Error al actualizar cliente: $e');
    }
  }

  /// Eliminar cliente
  static Future<void> deleteCustomer(String id) async {
    try {
      await _client.from('customers').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar cliente: $e');
    }
  }

  // ===========================================
  // MAINTENANCE TASK METHODS
  // ===========================================

  /// Obtener todas las tareas
  static Future<List<MaintenanceTask>> getMaintenanceTasks() async {
    try {
      final response = await _client
          .from('maintenance_tasks')
          .select()
          .order('scheduled_date', ascending: true);
      
      return (response as List)
          .map((json) => _maintenanceTaskFromSupabase(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener tareas: $e');
    }
  }

  /// Obtener tarea por ID
  static Future<MaintenanceTask?> getMaintenanceTaskById(String id) async {
    try {
      final response = await _client
          .from('maintenance_tasks')
          .select()
          .eq('id', id)
          .single();
      
      return _maintenanceTaskFromSupabase(response);
    } catch (e) {
      return null;
    }
  }

  /// Crear nueva tarea
  static Future<MaintenanceTask> createMaintenanceTask(MaintenanceTask task) async {
    try {
      final data = _maintenanceTaskToSupabase(task);
      final response = await _client
          .from('maintenance_tasks')
          .insert(data)
          .select()
          .single();
      
      return _maintenanceTaskFromSupabase(response);
    } catch (e) {
      throw Exception('Error al crear tarea: $e');
    }
  }

  /// Actualizar tarea
  static Future<MaintenanceTask> updateMaintenanceTask(MaintenanceTask task) async {
    try {
      final data = _maintenanceTaskToSupabase(task);
      final response = await _client
          .from('maintenance_tasks')
          .update(data)
          .eq('id', task.id)
          .select()
          .single();
      
      return _maintenanceTaskFromSupabase(response);
    } catch (e) {
      throw Exception('Error al actualizar tarea: $e');
    }
  }

  /// Eliminar tarea
  static Future<void> deleteMaintenanceTask(String id) async {
    try {
      await _client.from('maintenance_tasks').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar tarea: $e');
    }
  }

  // ===========================================
  // CONVERSIÓN EQUIPMENT
  // ===========================================

  static Equipment _equipmentFromSupabase(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      status: _parseEquipmentStatus(json['status'] as String),
      description: json['description'] as String,
      customer: json['customer'] as String?,
      location: json['location'] as String?,
      rentalStartDate: json['rental_start_date'] != null
          ? DateTime.parse(json['rental_start_date'] as String)
          : null,
      rentalEndDate: json['rental_end_date'] != null
          ? DateTime.parse(json['rental_end_date'] as String)
          : null,
      dailyRate: json['daily_rate'] != null
          ? (json['daily_rate'] as num).toDouble()
          : null,
      imageUrl: json['image_url'] as String?,
    );
  }

  static Map<String, dynamic> _equipmentToSupabase(Equipment equipment) {
    return {
      'id': equipment.id,
      'name': equipment.name,
      'category': equipment.category,
      'status': equipment.status.name,
      'description': equipment.description,
      'customer': equipment.customer,
      'location': equipment.location,
      'rental_start_date': equipment.rentalStartDate?.toIso8601String(),
      'rental_end_date': equipment.rentalEndDate?.toIso8601String(),
      'daily_rate': equipment.dailyRate,
      'image_url': equipment.imageUrl,
    };
  }

  static EquipmentStatus _parseEquipmentStatus(String status) {
    switch (status) {
      case 'available':
        return EquipmentStatus.available;
      case 'rented':
        return EquipmentStatus.rented;
      case 'maintenance':
        return EquipmentStatus.maintenance;
      case 'outOfService':
        return EquipmentStatus.outOfService;
      default:
        return EquipmentStatus.available;
    }
  }

  // ===========================================
  // CONVERSIÓN CUSTOMER
  // ===========================================

  static Customer _customerFromSupabase(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
      assignedEquipmentCount: json['assigned_equipment_count'] as int? ?? 0,
      totalRentals: json['total_rentals'] as int? ?? 0,
      lastRentalDate: DateTime.parse(json['last_rental_date'] as String),
      status: _parseCustomerStatus(json['status'] as String),
      email: json['email'] as String?,
      contactPerson: json['contact_person'] as String?,
    );
  }

  static Map<String, dynamic> _customerToSupabase(Customer customer) {
    return {
      'id': customer.id,
      'name': customer.name,
      'phone': customer.phone,
      'address': customer.address,
      'assigned_equipment_count': customer.assignedEquipmentCount,
      'total_rentals': customer.totalRentals,
      'last_rental_date': customer.lastRentalDate.toIso8601String(),
      'status': customer.status.name,
      'email': customer.email,
      'contact_person': customer.contactPerson,
    };
  }

  static CustomerStatus _parseCustomerStatus(String status) {
    switch (status) {
      case 'active':
        return CustomerStatus.active;
      case 'inactive':
        return CustomerStatus.inactive;
      case 'suspended':
        return CustomerStatus.suspended;
      default:
        return CustomerStatus.active;
    }
  }

  // ===========================================
  // CONVERSIÓN MAINTENANCE TASK
  // ===========================================

  static MaintenanceTask _maintenanceTaskFromSupabase(Map<String, dynamic> json) {
    return MaintenanceTask(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      equipmentId: json['equipment_id'] as String,
      equipmentName: json['equipment_name'] as String,
      priority: _parseTaskPriority(json['priority'] as String),
      status: _parseTaskStatus(json['status'] as String),
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      assignedTechnician: json['assigned_technician'] as String,
      estimatedDuration: Duration(minutes: (json['estimated_duration'] as num).toInt()),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      notes: json['notes'] as String?,
      cost: json['cost'] != null ? (json['cost'] as num).toDouble() : null,
      taskType: _parseTaskType(json['task_type'] as String? ?? 'maintenance'),
      deliveryDate: json['delivery_date'] != null
          ? DateTime.parse(json['delivery_date'] as String)
          : null,
      finishDate: json['finish_date'] != null
          ? DateTime.parse(json['finish_date'] as String)
          : null,
    );
  }

  static Map<String, dynamic> _maintenanceTaskToSupabase(MaintenanceTask task) {
    return {
      'id': task.id,
      'title': task.title,
      'description': task.description,
      'equipment_id': task.equipmentId,
      'equipment_name': task.equipmentName,
      'priority': task.priority.name,
      'status': task.status.name,
      'scheduled_date': task.scheduledDate.toIso8601String(),
      'assigned_technician': task.assignedTechnician,
      'estimated_duration': task.estimatedDuration.inMinutes,
      'started_at': task.startedAt?.toIso8601String(),
      'completed_at': task.completedAt?.toIso8601String(),
      'notes': task.notes,
      'cost': task.cost,
      'task_type': task.taskType.name,
      'delivery_date': task.deliveryDate?.toIso8601String(),
      'finish_date': task.finishDate?.toIso8601String(),
    };
  }

  static TaskPriority _parseTaskPriority(String priority) {
    switch (priority) {
      case 'high':
        return TaskPriority.high;
      case 'medium':
        return TaskPriority.medium;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }

  static TaskStatus _parseTaskStatus(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return TaskStatus.open;
      case 'inprogress':
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      default:
        return TaskStatus.open;
    }
  }

  static TaskType _parseTaskType(String type) {
    switch (type.toLowerCase()) {
      case 'maintenance':
        return TaskType.maintenance;
      case 'routine':
        return TaskType.routine;
      case 'repair':
        return TaskType.repair;
      case 'inspection':
        return TaskType.inspection;
      case 'upgrade':
        return TaskType.upgrade;
      default:
        return TaskType.maintenance;
    }
  }

  // ===========================================
  // RENTAL METHODS
  // ===========================================
  
  /// Obtener todos los alquileres
  static Future<List<Rental>> getRentals() async {
    try {
      final response = await _client
          .from('rentals')
          .select()
          .order('created_at', ascending: false);
      return (response as List)
          .map((json) => _rentalFromSupabase(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener alquileres: $e');
    }
  }

  /// Obtener alquileres de un cliente
  static Future<List<Rental>> getRentalsByCustomer(String customerId) async {
    try {
      final response = await _client
          .from('rentals')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((json) => _rentalFromSupabase(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener alquileres del cliente: $e');
    }
  }

  /// Obtener alquileres de un equipo
  static Future<List<Rental>> getRentalsByEquipment(String equipmentId) async {
    try {
      final response = await _client
          .from('rentals')
          .select()
          .eq('equipment_id', equipmentId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((json) => _rentalFromSupabase(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener alquileres del equipo: $e');
    }
  }

  /// Crear nuevo alquiler
  static Future<Rental> createRental(Rental rental) async {
    try {
      final data = _rentalToSupabase(rental);
      final response = await _client
          .from('rentals')
          .insert(data)
          .select()
          .single();
      return _rentalFromSupabase(response);
    } catch (e) {
      throw Exception('Error al crear alquiler: $e');
    }
  }

  /// Actualizar alquiler
  static Future<Rental> updateRental(Rental rental) async {
    try {
      final data = _rentalToSupabase(rental);
      final response = await _client
          .from('rentals')
          .update(data)
          .eq('id', rental.id)
          .select()
          .single();
      return _rentalFromSupabase(response);
    } catch (e) {
      throw Exception('Error al actualizar alquiler: $e');
    }
  }

  /// Completar alquiler (marcar como completado)
  static Future<Rental> completeRental(String rentalId) async {
    try {
      final response = await _client
          .from('rentals')
          .update({'status': 'completed'})
          .eq('id', rentalId)
          .select()
          .single();
      return _rentalFromSupabase(response);
    } catch (e) {
      throw Exception('Error al completar alquiler: $e');
    }
  }

  // ===========================================
  // CONVERSIÓN RENTAL
  // ===========================================
  
  static Rental _rentalFromSupabase(Map<String, dynamic> json) {
    return Rental(
      id: json['id'] as String,
      equipmentId: json['equipment_id'] as String,
      equipmentName: json['equipment_name'] as String,
      customerId: json['customer_id'] as String,
      customerName: json['customer_name'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      location: json['location'] as String,
      dailyRate: (json['daily_rate'] as num).toDouble(),
      rateType: _parseRateType(json['rate_type'] as String),
      totalCost: (json['total_cost'] as num).toDouble(),
      status: _parseRentalStatus(json['status'] as String),
    );
  }

  static Map<String, dynamic> _rentalToSupabase(Rental rental) {
    return {
      'id': rental.id,
      'equipment_id': rental.equipmentId,
      'equipment_name': rental.equipmentName,
      'customer_id': rental.customerId,
      'customer_name': rental.customerName,
      'start_date': rental.startDate.toIso8601String(),
      'end_date': rental.endDate.toIso8601String(),
      'location': rental.location,
      'daily_rate': rental.dailyRate,
      'rate_type': rental.rateType.name,
      'total_cost': rental.totalCost,
      'status': rental.status.name,
    };
  }

  static RentalStatus _parseRentalStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return RentalStatus.active;
      case 'completed':
        return RentalStatus.completed;
      case 'cancelled':
        return RentalStatus.cancelled;
      default:
        return RentalStatus.active;
    }
  }

  static RateType _parseRateType(String type) {
    switch (type.toLowerCase()) {
      case 'day':
        return RateType.day;
      case 'hour':
        return RateType.hour;
      default:
        return RateType.day;
    }
  }
}
