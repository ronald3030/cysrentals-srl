import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/equipment.dart';
import '../../models/maintenance_task.dart';
import '../../providers/equipment_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../../theme/app_theme.dart';

class MaintenanceTaskFormScreen extends StatefulWidget {
  final MaintenanceTask? task;

  const MaintenanceTaskFormScreen({
    super.key,
    this.task,
  });

  @override
  State<MaintenanceTaskFormScreen> createState() => _MaintenanceTaskFormScreenState();
}

class _MaintenanceTaskFormScreenState extends State<MaintenanceTaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _technicianController = TextEditingController();
  final _costController = TextEditingController();
  
  String? _selectedEquipmentId;
  TaskPriority _selectedPriority = TaskPriority.medium;
  TaskType _selectedTaskType = TaskType.maintenance;
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  DateTime? _deliveryDate;
  DateTime? _finishDate;
  int _estimatedHours = 1;
  int _estimatedMinutes = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _technicianController.text = widget.task!.assignedTechnician;
      _costController.text = widget.task!.cost?.toStringAsFixed(2) ?? '';
      _selectedEquipmentId = widget.task!.equipmentId;
      _selectedPriority = widget.task!.priority;
      _selectedTaskType = widget.task!.taskType;
      _scheduledDate = widget.task!.scheduledDate;
      _scheduledTime = TimeOfDay.fromDateTime(widget.task!.scheduledDate);
      _deliveryDate = widget.task!.deliveryDate;
      _finishDate = widget.task!.finishDate;
      _estimatedHours = widget.task!.estimatedDuration.inHours;
      _estimatedMinutes = widget.task!.estimatedDuration.inMinutes.remainder(60);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _technicianController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _scheduledDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _scheduledTime = picked;
      });
    }
  }

  Future<void> _selectDeliveryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _deliveryDate = picked;
      });
    }
  }

  Future<void> _selectFinishDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _finishDate ?? _deliveryDate ?? DateTime.now(),
      firstDate: _deliveryDate ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _finishDate = picked;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Seleccionar fecha';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Seleccionar hora';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedEquipmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un equipo'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
      return;
    }

    if (_scheduledDate == null || _scheduledTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona fecha y hora'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<MaintenanceProvider>();
      final equipmentProvider = context.read<EquipmentProvider>();
      
      final equipment = equipmentProvider.equipment.firstWhere(
        (e) => e.id == _selectedEquipmentId,
      );

      final scheduledDateTime = DateTime(
        _scheduledDate!.year,
        _scheduledDate!.month,
        _scheduledDate!.day,
        _scheduledTime!.hour,
        _scheduledTime!.minute,
      );

      final estimatedDuration = Duration(
        hours: _estimatedHours,
        minutes: _estimatedMinutes,
      );

      final cost = _costController.text.isNotEmpty 
          ? double.tryParse(_costController.text) 
          : null;

      if (widget.task == null) {
        // Create new task
        final newTask = MaintenanceTask(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          equipmentId: _selectedEquipmentId!,
          equipmentName: equipment.name,
          title: _titleController.text,
          description: _descriptionController.text,
          priority: _selectedPriority,
          status: TaskStatus.open,
          scheduledDate: scheduledDateTime,
          assignedTechnician: _technicianController.text,
          estimatedDuration: estimatedDuration,
          cost: cost,
          taskType: _selectedTaskType,
          deliveryDate: _deliveryDate,
          finishDate: _finishDate,
        );

        await provider.addTask(newTask);
        
        // Cambiar estado del equipo a mantenimiento
        final updatedEquipment = equipment.copyWith(
          status: EquipmentStatus.maintenance,
        );
        await equipmentProvider.updateEquipment(updatedEquipment);
      } else {
        // Update existing task
        final updatedTask = widget.task!.copyWith(
          equipmentId: _selectedEquipmentId,
          equipmentName: equipment.name,
          title: _titleController.text,
          description: _descriptionController.text,
          priority: _selectedPriority,
          scheduledDate: scheduledDateTime,
          assignedTechnician: _technicianController.text,
          estimatedDuration: estimatedDuration,
          cost: cost,
          taskType: _selectedTaskType,
          deliveryDate: _deliveryDate,
          finishDate: _finishDate,
        );

        await provider.updateTask(updatedTask);
        
        // Si se cambia de equipo, actualizar estados
        if (widget.task!.equipmentId != _selectedEquipmentId) {
          // Cambiar nuevo equipo a mantenimiento
          final updatedEquipment = equipment.copyWith(
            status: EquipmentStatus.maintenance,
          );
          await equipmentProvider.updateEquipment(updatedEquipment);
          
          // Restaurar equipo anterior si no tiene más tareas
          final oldEquipment = equipmentProvider.equipment.firstWhere(
            (e) => e.id == widget.task!.equipmentId,
          );
          final otherTasks = provider.tasks.where(
            (t) => t.equipmentId == oldEquipment.id && 
                   t.id != widget.task!.id &&
                   t.status != TaskStatus.completed,
          ).toList();
          
          if (otherTasks.isEmpty) {
            final restoredEquipment = oldEquipment.copyWith(
              status: EquipmentStatus.available,
            );
            await equipmentProvider.updateEquipment(restoredEquipment);
          }
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.task == null 
                ? 'Tarea creada exitosamente' 
                : 'Tarea actualizada exitosamente',
            ),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Nueva Tarea' : 'Editar Tarea'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título',
                prefixIcon: Icon(Icons.title_rounded),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa un título';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                prefixIcon: Icon(Icons.description_rounded),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa una descripción';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Consumer<EquipmentProvider>(
              builder: (context, equipmentProvider, child) {
                final availableEquipment = equipmentProvider.equipment
                    .where((e) => e.status == EquipmentStatus.available || 
                                  e.status == EquipmentStatus.rented ||
                                  e.id == _selectedEquipmentId)
                    .toList();

                return DropdownButtonFormField<String>(
                  value: _selectedEquipmentId,
                  decoration: const InputDecoration(
                    labelText: 'Equipo',
                    prefixIcon: Icon(Icons.inventory_2_rounded),
                  ),
                  items: availableEquipment.map((equipment) {
                    return DropdownMenuItem(
                      value: equipment.id,
                      child: Text(equipment.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedEquipmentId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor selecciona un equipo';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TaskPriority>(
              value: _selectedPriority,
              decoration: const InputDecoration(
                labelText: 'Prioridad',
                prefixIcon: Icon(Icons.priority_high_rounded),
              ),
              items: TaskPriority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 12,
                        color: _getPriorityColor(priority),
                      ),
                      const SizedBox(width: 8),
                      Text(priority.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPriority = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TaskType>(
              value: _selectedTaskType,
              decoration: const InputDecoration(
                labelText: 'Tipo de Tarea',
                prefixIcon: Icon(Icons.category_rounded),
              ),
              items: TaskType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedTaskType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _technicianController,
              decoration: const InputDecoration(
                labelText: 'Técnico Asignado',
                prefixIcon: Icon(Icons.engineering_rounded),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa el técnico asignado';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _costController,
              decoration: const InputDecoration(
                labelText: 'Costo (RD\$)',
                prefixIcon: Icon(Icons.attach_money_rounded),
                hintText: '0.00',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final cost = double.tryParse(value);
                  if (cost == null || cost < 0) {
                    return 'Ingresa un costo válido';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha',
                        prefixIcon: Icon(Icons.calendar_today_rounded),
                      ),
                      child: Text(_formatDate(_scheduledDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Hora',
                        prefixIcon: Icon(Icons.access_time_rounded),
                      ),
                      child: Text(_formatTime(_scheduledTime)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDeliveryDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de Entrega',
                        prefixIcon: Icon(Icons.local_shipping_rounded),
                      ),
                      child: Text(_deliveryDate != null 
                          ? _formatDate(_deliveryDate!)
                          : 'No especificada'),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectFinishDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de Finalización',
                        prefixIcon: Icon(Icons.check_circle_rounded),
                      ),
                      child: Text(_finishDate != null 
                          ? _formatDate(_finishDate!)
                          : 'No especificada'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            /* Comentado - campos de horas/minutos reemplazados por fechas de entrega/finalización
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _estimatedHours,
                    decoration: const InputDecoration(
                      labelText: 'Horas',
                      prefixIcon: Icon(Icons.timer_rounded),
                    ),
                    items: List.generate(24, (index) => index)
                        .map((hour) => DropdownMenuItem(
                              value: hour,
                              child: Text('$hour h'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _estimatedHours = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _estimatedMinutes,
                    decoration: const InputDecoration(
                      labelText: 'Minutos',
                      prefixIcon: Icon(Icons.schedule_rounded),
                    ),
                    items: [0, 15, 30, 45]
                        .map((minute) => DropdownMenuItem(
                              value: minute,
                              child: Text('$minute min'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _estimatedMinutes = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            */
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveTask,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.task == null ? 'Crear Tarea' : 'Actualizar Tarea'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return AppTheme.primaryRed;
      case TaskPriority.medium:
        return AppTheme.warningAmber;
      case TaskPriority.low:
        return AppTheme.successGreen;
    }
  }
}
