import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/equipment.dart';
import '../services/supabase_service.dart';

class EquipmentProvider extends ChangeNotifier {
  List<Equipment> _equipment = [];
  bool _isLoading = false;
  String? _error;
  bool _isOnline = true;

  List<Equipment> get equipment => _equipment;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOnline => _isOnline;

  // Filtros
  List<Equipment> get availableEquipment =>
      _equipment.where((e) => e.status == EquipmentStatus.available).toList();

  List<Equipment> get rentedEquipment =>
      _equipment.where((e) => e.status == EquipmentStatus.rented).toList();

  List<Equipment> get maintenanceEquipment =>
      _equipment.where((e) => e.status == EquipmentStatus.maintenance).toList();

  // Estadísticas
  int get totalEquipment => _equipment.length;
  int get availableCount => availableEquipment.length;
  int get rentedCount => rentedEquipment.length;
  double get utilizationRate => totalEquipment > 0 
      ? (rentedCount / totalEquipment * 100) 
      : 0.0;

  EquipmentProvider() {
    loadEquipment();
  }

  Future<void> loadEquipment() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Intentar cargar de Supabase primero
      try {
        _equipment = await SupabaseService.getEquipment();
        _isOnline = true;
        
        // Guardar en Hive como caché
        final box = await Hive.openBox<Equipment>('equipment');
        await box.clear();
        for (final equipment in _equipment) {
          await box.put(equipment.id, equipment);
        }
      } catch (e) {
        // Si falla Supabase, usar caché de Hive
        _isOnline = false;
        final box = await Hive.openBox<Equipment>('equipment');
        _equipment = box.values.toList();
        
        // Si no hay datos en caché, cargar datos de ejemplo
        if (_equipment.isEmpty) {
          await _loadSampleData();
        }
      }
      
      _error = null;
    } catch (e) {
      _error = 'Error al cargar equipos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addEquipment(Equipment equipment) async {
    try {
      // Intentar guardar en Supabase primero
      try {
        await SupabaseService.createEquipment(equipment);
        _isOnline = true;
      } catch (e) {
        _isOnline = false;
        // Continuar con Hive si Supabase falla
      }
      
      // Guardar en Hive (caché local)
      final box = await Hive.openBox<Equipment>('equipment');
      await box.put(equipment.id, equipment);
      _equipment.add(equipment);
      notifyListeners();
    } catch (e) {
      _error = 'Error al agregar equipo: $e';
      notifyListeners();
    }
  }

  Future<void> updateEquipment(Equipment equipment) async {
    try {
      // Intentar actualizar en Supabase primero
      try {
        await SupabaseService.updateEquipment(equipment);
        _isOnline = true;
      } catch (e) {
        _isOnline = false;
        // Continuar con Hive si Supabase falla
      }
      
      // Actualizar en Hive (caché local)
      final box = await Hive.openBox<Equipment>('equipment');
      await box.put(equipment.id, equipment);
      
      final index = _equipment.indexWhere((e) => e.id == equipment.id);
      if (index != -1) {
        _equipment[index] = equipment;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error al actualizar equipo: $e';
      notifyListeners();
    }
  }

  Future<void> deleteEquipment(String id) async {
    try {
      // Intentar eliminar de Supabase primero
      try {
        await SupabaseService.deleteEquipment(id);
        _isOnline = true;
      } catch (e) {
        _isOnline = false;
        // Continuar con Hive si Supabase falla
      }
      
      // Eliminar de Hive (caché local)
      final box = await Hive.openBox<Equipment>('equipment');
      await box.delete(id);
      _equipment.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Error al eliminar equipo: $e';
      notifyListeners();
    }
  }

  Equipment? getEquipmentById(String id) {
    try {
      return _equipment.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Equipment> searchEquipment(String query) {
    final lowerQuery = query.toLowerCase();
    return _equipment.where((e) =>
      e.name.toLowerCase().contains(lowerQuery) ||
      e.id.toLowerCase().contains(lowerQuery) ||
      e.category.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  List<Equipment> filterByCategory(String category) {
    if (category == 'Todos') return _equipment;
    return _equipment.where((e) => e.category == category).toList();
  }

  List<Equipment> filterByStatus(String status) {
    if (status == 'Todos') return _equipment;
    
    EquipmentStatus? equipmentStatus;
    switch (status) {
      case 'Disponible':
        equipmentStatus = EquipmentStatus.available;
        break;
      case 'Alquilado':
        equipmentStatus = EquipmentStatus.rented;
        break;
      case 'Mantenimiento':
        equipmentStatus = EquipmentStatus.maintenance;
        break;
      case 'Fuera de Servicio':
        equipmentStatus = EquipmentStatus.outOfService;
        break;
    }
    
    if (equipmentStatus == null) return _equipment;
    return _equipment.where((e) => e.status == equipmentStatus).toList();
  }

  Future<void> _loadSampleData() async {
    final sampleEquipment = [
      Equipment(
        id: 'E001',
        name: 'Excavadora CAT 320DL',
        category: 'Maquinaria Pesada',
        status: EquipmentStatus.available,
        description: 'Excavadora hidráulica de 20 toneladas para proyectos de construcción pesada',
        dailyRate: 5000.0,
      ),
      Equipment(
        id: 'E002',
        name: 'Mezcladora de Concreto 350L',
        category: 'Construcción',
        status: EquipmentStatus.rented,
        description: 'Mezcladora portátil de concreto con capacidad de 350 litros',
        customer: 'Constructora Caribena SRL',
        location: 'Av. 27 de Febrero #142, Santo Domingo',
        dailyRate: 800.0,
        rentalStartDate: DateTime.now().subtract(const Duration(days: 5)),
        rentalEndDate: DateTime.now().add(const Duration(days: 10)),
      ),
      Equipment(
        id: 'E003',
        name: 'Motosierra STIHL MS 381',
        category: 'Jardinería',
        status: EquipmentStatus.maintenance,
        description: 'Motosierra profesional de 5.9 HP para corte de árboles grandes',
        dailyRate: 300.0,
      ),
      Equipment(
        id: 'E004',
        name: 'Taladro de Impacto DeWalt 20V',
        category: 'Herramientas Eléctricas',
        status: EquipmentStatus.available,
        description: 'Taladro percutor inalámbrico de alto rendimiento con batería de litio',
        dailyRate: 150.0,
      ),
      Equipment(
        id: 'E005',
        name: 'Arnés de Seguridad Completo',
        category: 'Equipo de Seguridad',
        status: EquipmentStatus.rented,
        description: 'Kit completo de arnés de seguridad con casco y accesorios',
        customer: 'Ingeniería del Cibao',
        location: 'Santiago de los Caballeros',
        dailyRate: 200.0,
        rentalStartDate: DateTime.now().subtract(const Duration(days: 3)),
        rentalEndDate: DateTime.now().add(const Duration(days: 4)),
      ),
    ];

    final box = await Hive.openBox<Equipment>('equipment');
    for (final equipment in sampleEquipment) {
      await box.put(equipment.id, equipment);
    }
    _equipment = sampleEquipment;
  }

  Future<void> refresh() async {
    await loadEquipment();
  }
}
