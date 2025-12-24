import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/customer.dart';
import '../services/supabase_service.dart';

class CustomerProvider extends ChangeNotifier {
  List<Customer> _customers = [];
  bool _isLoading = false;
  String? _error;
  bool _isOnline = true;

  List<Customer> get customers => _customers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOnline => _isOnline;

  // Filtros
  List<Customer> get activeCustomers =>
      _customers.where((c) => c.status == CustomerStatus.active).toList();

  List<Customer> get inactiveCustomers =>
      _customers.where((c) => c.status == CustomerStatus.inactive).toList();

  // Estadísticas
  int get totalCustomers => _customers.length;
  int get activeCount => activeCustomers.length;
  int get totalAssignedEquipment => 
      _customers.fold(0, (sum, c) => sum + c.assignedEquipmentCount);

  CustomerProvider() {
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Intentar cargar de Supabase primero
      try {
        _customers = await SupabaseService.getCustomers();
        _isOnline = true;
        
        // Guardar en Hive como caché
        final box = await Hive.openBox<Customer>('customers');
        await box.clear();
        for (final customer in _customers) {
          await box.put(customer.id, customer);
        }
      } catch (e) {
        // Si falla Supabase, usar caché de Hive
        _isOnline = false;
        final box = await Hive.openBox<Customer>('customers');
        _customers = box.values.toList();
        
        // Si no hay datos en caché, cargar datos de ejemplo
        if (_customers.isEmpty) {
          await _loadSampleData();
        }
      }
      
      _error = null;
    } catch (e) {
      _error = 'Error al cargar clientes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCustomer(Customer customer) async {
    try {
      // Intentar guardar en Supabase primero
      try {
        await SupabaseService.createCustomer(customer);
        _isOnline = true;
      } catch (e) {
        _isOnline = false;
      }
      
      final box = await Hive.openBox<Customer>('customers');
      await box.put(customer.id, customer);
      _customers.add(customer);
      notifyListeners();
    } catch (e) {
      _error = 'Error al agregar cliente: $e';
      notifyListeners();
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    try {
      // Intentar actualizar en Supabase primero
      try {
        await SupabaseService.updateCustomer(customer);
        _isOnline = true;
      } catch (e) {
        _isOnline = false;
      }
      
      final box = await Hive.openBox<Customer>('customers');
      await box.put(customer.id, customer);
      
      final index = _customers.indexWhere((c) => c.id == customer.id);
      if (index != -1) {
        _customers[index] = customer;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error al actualizar cliente: $e';
      notifyListeners();
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      // Intentar eliminar de Supabase primero
      try {
        await SupabaseService.deleteCustomer(id);
        _isOnline = true;
      } catch (e) {
        _isOnline = false;
      }
      
      final box = await Hive.openBox<Customer>('customers');
      await box.delete(id);
      _customers.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Error al eliminar cliente: $e';
      notifyListeners();
    }
  }

  Customer? getCustomerById(String id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Customer> searchCustomers(String query) {
    final lowerQuery = query.toLowerCase();
    return _customers.where((c) =>
      c.name.toLowerCase().contains(lowerQuery) ||
      c.id.toLowerCase().contains(lowerQuery) ||
      c.phone.contains(query)
    ).toList();
  }

  List<Customer> filterByStatus(CustomerStatus status) {
    return _customers.where((c) => c.status == status).toList();
  }

  Future<void> _loadSampleData() async {
    final sampleCustomers = [
      Customer(
        id: 'C001',
        name: 'Constructora Caribena SRL',
        phone: '+1 (809) 234-5678',
        address: 'Av. 27 de Febrero #142, Ensanche Naco, Santo Domingo',
        assignedEquipmentCount: 5,
        totalRentals: 24,
        lastRentalDate: DateTime.now().subtract(const Duration(days: 2)),
        status: CustomerStatus.active,
        email: 'contacto@caribena.com.do',
      ),
      Customer(
        id: 'C002',
        name: 'Ingeniería del Cibao',
        phone: '+1 (829) 567-8901',
        address: 'Calle Real #89, Centro Histórico, Santiago de los Caballeros',
        assignedEquipmentCount: 3,
        totalRentals: 18,
        lastRentalDate: DateTime.now().subtract(const Duration(days: 5)),
        status: CustomerStatus.active,
        email: 'info@ingcibao.com',
      ),
      Customer(
        id: 'C003',
        name: 'Paisajismo Tropical RD',
        phone: '+1 (849) 123-4567',
        address: 'Av. Abraham Lincoln #456, Piantini, Santo Domingo',
        assignedEquipmentCount: 0,
        totalRentals: 12,
        lastRentalDate: DateTime.now().subtract(const Duration(days: 30)),
        status: CustomerStatus.inactive,
      ),
      Customer(
        id: 'C004',
        name: 'Obras Públicas del Este',
        phone: '+1 (809) 789-0123',
        address: 'Autopista del Este Km 25, Boca Chica, Santo Domingo Este',
        assignedEquipmentCount: 8,
        totalRentals: 35,
        lastRentalDate: DateTime.now().subtract(const Duration(days: 1)),
        status: CustomerStatus.active,
        email: 'obras@este.gob.do',
      ),
      Customer(
        id: 'C005',
        name: 'Constructora Amanecer',
        phone: '+1 (829) 345-6789',
        address: 'Av. Independencia #78, Gazcue, Santo Domingo',
        assignedEquipmentCount: 2,
        totalRentals: 9,
        lastRentalDate: DateTime.now().subtract(const Duration(days: 7)),
        status: CustomerStatus.active,
      ),
    ];

    final box = await Hive.openBox<Customer>('customers');
    for (final customer in sampleCustomers) {
      await box.put(customer.id, customer);
    }
    _customers = sampleCustomers;
  }

  Future<void> refresh() async {
    await loadCustomers();
  }
}
