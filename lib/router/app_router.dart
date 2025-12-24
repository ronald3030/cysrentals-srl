import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../screens/main_screen.dart';
import '../providers/equipment_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/maintenance_provider.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) {
          final reduceMotion = state.extra as bool? ?? false;
          return MainScreen(reduceMotion: reduceMotion);
        },
      ),
      GoRoute(
        path: '/equipment/:id',
        name: 'equipment-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final provider = context.read<EquipmentProvider>();
          final equipment = provider.getEquipmentById(id);
          
          if (equipment == null) {
            return const Scaffold(
              body: Center(child: Text('Equipo no encontrado')),
            );
          }
          
          return EquipmentDetailScreen(equipment: equipment);
        },
      ),
      GoRoute(
        path: '/customer/:id',
        name: 'customer-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final provider = context.read<CustomerProvider>();
          final customer = provider.getCustomerById(id);
          
          if (customer == null) {
            return const Scaffold(
              body: Center(child: Text('Cliente no encontrado')),
            );
          }
          
          return CustomerDetailScreen(customer: customer);
        },
      ),
      GoRoute(
        path: '/maintenance/:id',
        name: 'maintenance-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final provider = context.read<MaintenanceProvider>();
          final task = provider.getTaskById(id);
          
          if (task == null) {
            return const Scaffold(
              body: Center(child: Text('Tarea no encontrada')),
            );
          }
          
          return MaintenanceTaskDetailScreen(task: task);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Página no encontrada: ${state.uri.path}'),
      ),
    ),
  );
}

// Pantallas placeholder (crearemos las reales después)
class EquipmentDetailScreen extends StatelessWidget {
  final dynamic equipment;
  
  const EquipmentDetailScreen({super.key, required this.equipment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(equipment.name)),
      body: Center(child: Text('Detalle del equipo')),
    );
  }
}

class CustomerDetailScreen extends StatelessWidget {
  final dynamic customer;
  
  const CustomerDetailScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(customer.name)),
      body: Center(child: Text('Detalle del cliente')),
    );
  }
}

class MaintenanceTaskDetailScreen extends StatelessWidget {
  final dynamic task;
  
  const MaintenanceTaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(task.title)),
      body: Center(child: Text('Detalle de la tarea')),
    );
  }
}
