import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../models/equipment.dart';
import '../../models/maintenance_task.dart';
import '../../models/rental.dart';
import '../../providers/equipment_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/customer_provider.dart';
import '../../services/supabase_service.dart';
import 'equipment_form_screen.dart';
import '../maintenance/equipment_maintenance_history_screen.dart';

class EquipmentDetailScreen extends StatefulWidget {
  final Equipment equipment;
  final bool reduceMotion;

  const EquipmentDetailScreen({
    super.key,
    required this.equipment,
    required this.reduceMotion,
  });

  @override
  State<EquipmentDetailScreen> createState() => _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends State<EquipmentDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  Color get _statusColor {
    switch (widget.equipment.status) {
      case EquipmentStatus.available:
        return AppTheme.successGreen;
      case EquipmentStatus.rented:
        return AppTheme.primaryRed;
      case EquipmentStatus.maintenance:
        return AppTheme.warningAmber;
      case EquipmentStatus.outOfService:
        return AppTheme.darkGray;
    }
  }

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: Duration(
        milliseconds: widget.reduceMotion ? 300 : 600,
      ),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    );

    // Start FAB animation after page loads
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _fabController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildEquipmentInfo(),
                const SizedBox(height: 24),
                _buildStatusSection(),
                const SizedBox(height: 24),
                _buildActionButtons(),
                const SizedBox(height: 24),
                if (widget.equipment.customer != null) ...[
                  _buildCustomerSection()!,
                  const SizedBox(height: 24),
                ],
                _buildMaintenanceSection(),
                SizedBox(height: ResponsiveHelper.getResponsiveValue(
                  context: context,
                  mobile: 120.0,
                  tablet: 100.0,
                  desktop: 80.0,
                )), // Bottom padding
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryWhite.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.primaryBlack,
          ),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'equipment_${widget.equipment.id}',
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.lightGray,
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    _getCategoryIcon(),
                    size: 120,
                    color: AppTheme.mediumGray,
                  ),
                ),
                Positioned(
                  top: 100,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      widget.equipment.status.displayName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEquipmentInfo() {
    return AnimationConfiguration.synchronized(
      duration: Duration(
        milliseconds: widget.reduceMotion ? 300 : 500,
      ),
      child: SlideAnimation(
        verticalOffset: widget.reduceMotion ? 20 : 50,
        child: FadeInAnimation(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.equipment.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.lightGray,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.equipment.id,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getCategoryIcon(),
                          color: AppTheme.primaryRed,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Categoría', widget.equipment.category),
                  const SizedBox(height: 12),
                  _buildInfoRow('Descripción', widget.equipment.description),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.mediumGray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    return AnimationConfiguration.synchronized(
      duration: Duration(
        milliseconds: widget.reduceMotion ? 300 : 600,
      ),
      child: SlideAnimation(
        verticalOffset: widget.reduceMotion ? 20 : 50,
        child: FadeInAnimation(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información de Estado',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _statusColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _statusColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getStatusIcon(),
                            color: AppTheme.primaryWhite,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.equipment.status.displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _statusColor,
                              ),
                            ),
                            Text(
                              _getStatusDescription(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                color: AppTheme.mediumGray,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return AnimationConfiguration.synchronized(
      duration: Duration(
        milliseconds: widget.reduceMotion ? 300 : 700,
      ),
      child: SlideAnimation(
        verticalOffset: widget.reduceMotion ? 20 : 50,
        child: FadeInAnimation(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Acciones',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      _buildActionButton(
                        icon: Icons.location_on_rounded,
                        label: 'Actualizar Dirección Cliente',
                        onTap: () {
                          _showUpdateLocationDialog();
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        icon: Icons.build_rounded,
                        label: 'Crear Tarea de Mantenimiento',
                        onTap: () {
                          _showCreateMaintenanceTaskDialog();
                        },
                      ),
                      if (widget.equipment.status == EquipmentStatus.rented) ...[
                        const SizedBox(height: 12),
                        _buildActionButton(
                          icon: Icons.assignment_return_rounded,
                          label: 'Marcar como Devuelto',
                          onTap: () {
                            _confirmReturnEquipment();
                          },
                          color: AppTheme.successGreen,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final buttonColor = color ?? AppTheme.primaryRed;
    
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: buttonColor),
        label: Text(
          label,
          style: TextStyle(color: buttonColor),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: buttonColor),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget? _buildCustomerSection() {
    if (widget.equipment.customer == null) return null;

    return AnimationConfiguration.synchronized(
      duration: Duration(
        milliseconds: widget.reduceMotion ? 300 : 800,
      ),
      child: SlideAnimation(
        verticalOffset: widget.reduceMotion ? 20 : 50,
        child: FadeInAnimation(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Asignación Actual',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppTheme.primaryRed,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.equipment.customer!,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (widget.equipment.location != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: AppTheme.mediumGray,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      widget.equipment.location!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                        color: AppTheme.mediumGray,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaintenanceSection() {
    return AnimationConfiguration.synchronized(
      duration: Duration(
        milliseconds: widget.reduceMotion ? 300 : 900,
      ),
      child: SlideAnimation(
        verticalOffset: widget.reduceMotion ? 20 : 50,
        child: FadeInAnimation(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historial de Mantenimiento',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EquipmentMaintenanceHistoryScreen(
                              equipment: widget.equipment,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.history_rounded),
                      label: const Text('Ver historial completo'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaintenanceItem(
    String description,
    String technician,
    DateTime date,
    MaintenanceType type,
  ) {
    Color typeColor;
    IconData typeIcon;
    
    switch (type) {
      case MaintenanceType.routine:
        typeColor = AppTheme.successGreen;
        typeIcon = Icons.schedule_rounded;
        break;
      case MaintenanceType.repair:
        typeColor = AppTheme.warningAmber;
        typeIcon = Icons.build_rounded;
        break;
      case MaintenanceType.inspection:
        typeColor = AppTheme.primaryRed;
        typeIcon = Icons.search_rounded;
        break;
      case MaintenanceType.upgrade:
        typeColor = AppTheme.primaryBlack;
        typeIcon = Icons.upgrade_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              typeIcon,
              color: typeColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$technician • ${_formatDate(date)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mediumGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: _fabAnimation,
      child: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EquipmentFormScreen(
                equipment: widget.equipment,
                reduceMotion: widget.reduceMotion,
              ),
            ),
          ).then((_) {
            // Recargar la pantalla al volver del formulario
            Navigator.of(context).pop();
          });
        },
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Editar'),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: AppTheme.primaryWhite,
      ),
    );
  }

  IconData _getCategoryIcon() {
    switch (widget.equipment.category.toLowerCase()) {
      case 'construction':
        return Icons.construction_rounded;
      case 'landscaping':
        return Icons.park_rounded;
      case 'power tools':
        return Icons.build_rounded;
      case 'heavy machinery':
        return Icons.engineering_rounded;
      case 'safety equipment':
        return Icons.security_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.equipment.status) {
      case EquipmentStatus.available:
        return Icons.check_circle_rounded;
      case EquipmentStatus.rented:
        return Icons.assignment_rounded;
      case EquipmentStatus.maintenance:
        return Icons.build_rounded;
      case EquipmentStatus.outOfService:
        return Icons.warning_rounded;
    }
  }

  String _getStatusDescription() {
    switch (widget.equipment.status) {
      case EquipmentStatus.available:
        return 'Listo para alquiler';
      case EquipmentStatus.rented:
        return 'Actualmente con cliente';
      case EquipmentStatus.maintenance:
        return 'En mantenimiento';
      case EquipmentStatus.outOfService:
        return 'Fuera de servicio';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showUpdateLocationDialog() {
    final locationController = TextEditingController(
      text: widget.equipment.location ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Actualizar Dirección'),
        content: TextField(
          controller: locationController,
          decoration: const InputDecoration(
            labelText: 'Nueva dirección',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newLocation = locationController.text.trim();
              if (newLocation.isNotEmpty) {
                final updatedEquipment = Equipment(
                  id: widget.equipment.id,
                  name: widget.equipment.name,
                  category: widget.equipment.category,
                  status: widget.equipment.status,
                  description: widget.equipment.description,
                  imageUrl: widget.equipment.imageUrl,
                  customer: widget.equipment.customer,
                  location: newLocation,
                  dailyRate: widget.equipment.dailyRate,
                  rentalStartDate: widget.equipment.rentalStartDate,
                  rentalEndDate: widget.equipment.rentalEndDate,
                  maintenanceHistory: widget.equipment.maintenanceHistory,
                );

                await context.read<EquipmentProvider>().updateEquipment(updatedEquipment);
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dirección actualizada exitosamente'),
                      backgroundColor: AppTheme.successGreen,
                    ),
                  );
                  Navigator.pop(context); // Volver a la pantalla anterior
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: AppTheme.primaryWhite,
            ),
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  void _showCreateMaintenanceTaskDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final technicianController = TextEditingController();
    String selectedPriority = 'medium';
    DateTime scheduledDate = DateTime.now().add(const Duration(days: 1));
    int estimatedDuration = 60;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nueva Tarea de Mantenimiento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Prioridad',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'high', child: Text('Alta')),
                    DropdownMenuItem(value: 'medium', child: Text('Media')),
                    DropdownMenuItem(value: 'low', child: Text('Baja')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedPriority = value!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: technicianController,
                  decoration: const InputDecoration(
                    labelText: 'Técnico Asignado',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || 
                    descriptionController.text.isEmpty || 
                    technicianController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor completa todos los campos'),
                      backgroundColor: AppTheme.warningAmber,
                    ),
                  );
                  return;
                }

                final taskId = 'M${DateTime.now().millisecondsSinceEpoch}';
                final newTask = MaintenanceTask(
                  id: taskId,
                  title: titleController.text,
                  description: descriptionController.text,
                  equipmentId: widget.equipment.id,
                  equipmentName: widget.equipment.name,
                  priority: selectedPriority == 'high' ? TaskPriority.high : 
                           selectedPriority == 'low' ? TaskPriority.low : TaskPriority.medium,
                  status: TaskStatus.open,
                  scheduledDate: scheduledDate,
                  assignedTechnician: technicianController.text,
                  estimatedDuration: Duration(minutes: estimatedDuration),
                );

                await context.read<MaintenanceProvider>().addTask(newTask);
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tarea de mantenimiento creada'),
                      backgroundColor: AppTheme.successGreen,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: AppTheme.primaryWhite,
              ),
              child: const Text('Crear Tarea'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReturnEquipment() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Devolución'),
        content: Text('¿Marcar "${widget.equipment.name}" como devuelto?\n\nEsto cambiará el estado a disponible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final returnedEquipment = Equipment(
                id: widget.equipment.id,
                name: widget.equipment.name,
                category: widget.equipment.category,
                status: EquipmentStatus.available,
                description: widget.equipment.description,
                imageUrl: widget.equipment.imageUrl,
                customer: null,
                location: null,
                dailyRate: widget.equipment.dailyRate,
                rentalStartDate: null,
                rentalEndDate: null,
                maintenanceHistory: widget.equipment.maintenanceHistory,
              );

              await context.read<EquipmentProvider>().updateEquipment(returnedEquipment);
              
              // Marcar alquiler activo como completado en Supabase
              try {
                final rentals = await SupabaseService.getRentalsByEquipment(widget.equipment.id);
                final activeRental = rentals.firstWhere(
                  (r) => r.status == RentalStatus.active,
                  orElse: () => rentals.first,
                );
                await SupabaseService.completeRental(activeRental.id);
              } catch (e) {
                print('Error completando alquiler en Supabase: $e');
              }
              
              // Actualizar cliente si existe
              if (widget.equipment.customer != null) {
                final customerProvider = context.read<CustomerProvider>();
                final customer = customerProvider.customers.firstWhere(
                  (c) => c.name == widget.equipment.customer,
                  orElse: () => customerProvider.customers.first, // Fallback seguro
                );
                
                // Remover equipo de la lista del cliente
                final updatedEquipmentIds = (customer.equipmentIds ?? [])
                    .where((id) => id != widget.equipment.id)
                    .toList();
                
                final updatedCustomer = customer.copyWith(
                  assignedEquipmentCount: updatedEquipmentIds.length,
                  equipmentIds: updatedEquipmentIds,
                );
                
                await customerProvider.updateCustomer(updatedCustomer);
              }
              
              if (mounted) {
                Navigator.pop(context); // Cerrar diálogo
                Navigator.pop(context); // Volver a inventario
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Equipo marcado como devuelto'),
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
              foregroundColor: AppTheme.primaryWhite,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
