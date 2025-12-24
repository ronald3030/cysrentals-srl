import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/maintenance_task.dart';
import '../models/rental.dart';
import 'supabase_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Timer? _checkTimer;
  final List<Function(String, String)> _listeners = [];
  
  // Almacena notificaciones ya mostradas para evitar duplicados
  final Set<String> _shownNotifications = Set<String>();

  void addListener(Function(String title, String message) callback) {
    _listeners.add(callback);
  }

  void removeListener(Function(String title, String message) callback) {
    _listeners.remove(callback);
  }

  void _notify(String title, String message) {
    for (var listener in _listeners) {
      listener(title, message);
    }
  }

  Future<bool> _areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  void startMonitoring() {
    // Verificar cada 5 minutos
    _checkTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkForNotifications();
    });
    
    // Primera verificación inmediata
    _checkForNotifications();
  }

  void stopMonitoring() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  Future<void> _checkForNotifications() async {
    if (!await _areNotificationsEnabled()) {
      return;
    }

    try {
      await _checkOverdueTasks();
      await _checkExpiringRentals();
    } catch (e) {
      debugPrint('Error checking notifications: $e');
    }
  }

  Future<void> _checkOverdueTasks() async {
    final tasks = await SupabaseService.getMaintenanceTasks();
    final now = DateTime.now();

    for (final task in tasks) {
      // Tarea vencida: scheduledDate pasó y no está completada
      if (task.status != TaskStatus.completed &&
          task.scheduledDate.isBefore(now)) {
        
        final notificationKey = 'overdue_task_${task.id}';
        
        // Solo notificar una vez por tarea
        if (!_shownNotifications.contains(notificationKey)) {
          final daysOverdue = now.difference(task.scheduledDate).inDays;
          _notify(
            '⚠️ Tarea Vencida',
            '${task.title} está vencida por $daysOverdue ${daysOverdue == 1 ? 'día' : 'días'}',
          );
          _shownNotifications.add(notificationKey);
        }
      }
    }
  }

  Future<void> _checkExpiringRentals() async {
    final rentals = await SupabaseService.getRentals();
    final now = DateTime.now();

    for (final rental in rentals) {
      // Solo verificar alquileres activos
      if (rental.status != RentalStatus.active) {
        continue;
      }

      final daysUntilExpiration = rental.endDate.difference(now).inDays;
      
      // Notificar si faltan 3 días o menos
      if (daysUntilExpiration <= 3 && daysUntilExpiration >= 0) {
        final notificationKey = 'rental_expiring_${rental.id}_$daysUntilExpiration';
        
        if (!_shownNotifications.contains(notificationKey)) {
          if (daysUntilExpiration == 0) {
            _notify(
              '🚨 Alquiler Vence Hoy',
              'El alquiler de ${rental.equipmentName} para ${rental.customerName} vence hoy',
            );
          } else {
            _notify(
              '⏰ Alquiler Próximo a Vencer',
              'El alquiler de ${rental.equipmentName} vence en $daysUntilExpiration ${daysUntilExpiration == 1 ? 'día' : 'días'}',
            );
          }
          _shownNotifications.add(notificationKey);
        }
      }
      
      // Notificar si ya venció
      else if (daysUntilExpiration < 0) {
        final notificationKey = 'rental_overdue_${rental.id}';
        
        if (!_shownNotifications.contains(notificationKey)) {
          final daysOverdue = -daysUntilExpiration;
          _notify(
            '⛔ Alquiler Vencido',
            'El alquiler de ${rental.equipmentName} está vencido por $daysOverdue ${daysOverdue == 1 ? 'día' : 'días'}',
          );
          _shownNotifications.add(notificationKey);
        }
      }
    }
  }

  // Limpiar notificaciones mostradas (llamar periódicamente, ej: cada día)
  void clearShownNotifications() {
    _shownNotifications.clear();
  }

  // Método para verificación manual (útil para testing o botón de actualizar)
  Future<void> checkNow() async {
    await _checkForNotifications();
  }
}
