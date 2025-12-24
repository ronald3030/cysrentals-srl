import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../models/equipment.dart';
import '../../models/maintenance_task.dart';
import '../../providers/equipment_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../../widgets/task_card.dart';
import '../../widgets/filter_chip_row.dart';
import 'maintenance_history_screen.dart';
import 'maintenance_task_form_screen.dart';

class MaintenanceScreen extends StatefulWidget {
  final bool reduceMotion;

  const MaintenanceScreen({
    super.key,
    required this.reduceMotion,
  });

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen>
    with TickerProviderStateMixin {
  late AnimationController _searchController;
  late Animation<double> _searchAnimation;
  
  final TextEditingController _searchTextController = TextEditingController();
  bool _isSearching = false;
  String _selectedPriority = 'Todas';
  String _selectedStatus = 'Todas';

  final List<String> _priorityFilters = [
    'Todas',
    'Alta',
    'Media',
    'Baja',
  ];

  final List<String> _statusFilters = [
    'Todas',
    'Abierta',
    'En Progreso',
    'Completada',
  ];

  // Datos de mantenimiento - perspectiva gerencial
  List<MaintenanceTask> _filteredTasks = [];

  @override
  void initState() {
    super.initState();
    _searchController = AnimationController(
      duration: Duration(
        milliseconds: widget.reduceMotion ? 200 : 300,
      ),
      vsync: this,
    );
    _searchAnimation = CurvedAnimation(
      parent: _searchController,
      curve: Curves.easeInOut,
    );
    
    _searchTextController.addListener(_filterTasks);
    
    // Cargar tareas inmediatamente
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('🚀 MaintenanceScreen: Iniciando carga de tareas...');
      await context.read<MaintenanceProvider>().loadTasks();
      print('✅ MaintenanceScreen: Carga completada');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchTextController.dispose();
    super.dispose();
  }

  void _filterTasks() {
    final provider = context.read<MaintenanceProvider>();
    setState(() {
      final query = _searchTextController.text.toLowerCase();
      _filteredTasks = provider.tasks.where((task) {
        final matchesSearch = query.isEmpty ||
            task.title.toLowerCase().contains(query) ||
            task.equipmentName.toLowerCase().contains(query) ||
            task.assignedTechnician.toLowerCase().contains(query) ||
            task.id.toLowerCase().contains(query);
        
        final matchesPriority = _selectedPriority == 'Todas' ||
            task.priority.displayName == _selectedPriority;
        
        final matchesStatus = _selectedStatus == 'Todas' ||
            task.status.displayName == _selectedStatus;
        
        return matchesSearch && matchesPriority && matchesStatus;
      }).toList();
      
      // Sort by priority and scheduled date
      _filteredTasks.sort((a, b) {
        final priorityComparison = a.priority.index.compareTo(b.priority.index);
        if (priorityComparison != 0) return priorityComparison;
        return a.scheduledDate.compareTo(b.scheduledDate);
      });
    });
  }

  Future<void> _refreshTasks() async {
    await context.read<MaintenanceProvider>().loadTasks();
    _filterTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Consumer<MaintenanceProvider>(
        builder: (context, maintenanceProvider, child) {
          print('🔄 MaintenanceScreen: Tareas en provider: ${maintenanceProvider.tasks.length}');
          
          // Aplicar filtros para obtener las tareas filtradas
          final query = _searchTextController.text.toLowerCase();
          List<MaintenanceTask> displayTasks = maintenanceProvider.tasks.where((task) {
            final matchesSearch = query.isEmpty ||
                task.title.toLowerCase().contains(query) ||
                task.equipmentName.toLowerCase().contains(query) ||
                task.assignedTechnician.toLowerCase().contains(query) ||
                task.id.toLowerCase().contains(query);
            
            final matchesPriority = _selectedPriority == 'Todas' ||
                task.priority.displayName == _selectedPriority;
            
            final matchesStatus = _selectedStatus == 'Todas' ||
                task.status.displayName == _selectedStatus;
            
            return matchesSearch && matchesPriority && matchesStatus;
          }).toList();
          
          // Sort by priority and scheduled date
          displayTasks.sort((a, b) {
            final priorityComparison = a.priority.index.compareTo(b.priority.index);
            if (priorityComparison != 0) return priorityComparison;
            return a.scheduledDate.compareTo(b.scheduledDate);
          });

          return RefreshIndicator(
            onRefresh: _refreshTasks,
            child: CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildSearchBar(),
                      const SizedBox(height: 16),
                      _buildStatsRow(maintenanceProvider),
                      const SizedBox(height: 16),
                      _buildFilterChips(),
                      const SizedBox(height: 16),
                    ]),
                  ),
                ),
                if (maintenanceProvider.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  _buildTasksList(displayTasks),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100), // Bottom padding for navigation
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: LayoutBuilder(
          builder: (context, constraints) {
            final isCollapsed = constraints.maxHeight <= 80;
            
            if (isCollapsed) {
              return Text(
                'Mantenimiento y Tareas',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              );
            }
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'C&S Rentals SRL',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Mantenimiento y Tareas',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          },
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      actions: [
        IconButton(
          icon: AnimatedRotation(
            duration: Duration(milliseconds: widget.reduceMotion ? 200 : 300),
            turns: _searchAnimation.value * 0.5,
            child: Icon(_isSearching ? Icons.search_off : Icons.search),
          ),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchTextController.clear();
              }
            });
            
            if (_isSearching) {
              _searchController.forward();
            } else {
              _searchController.reverse();
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.history_rounded),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MaintenanceHistoryScreen(
                  reduceMotion: widget.reduceMotion,
                ),
              ),
            );
          },
          tooltip: 'Historial de Mantenimiento',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: Duration(
        milliseconds: widget.reduceMotion ? 200 : 300,
      ),
      height: _isSearching ? 56 : 0,
      child: AnimatedOpacity(
        opacity: _isSearching ? 1.0 : 0.0,
        duration: Duration(
          milliseconds: widget.reduceMotion ? 200 : 300,
        ),
        child: TextField(
          controller: _searchTextController,
          decoration: InputDecoration(
            hintText: 'Buscar tareas...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchTextController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchTextController.clear();
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(MaintenanceProvider provider) {
    final openTasks = provider.openTasks.length;
    final inProgressTasks = provider.inProgressTasks.length;
    final urgentTasks = provider.highPriorityTasks.length;
    final overdueTasks = provider.overdueTasks.length;

    return Column(
      children: [
        // Primera fila - Métricas operativas
        AnimationConfiguration.synchronized(
          duration: Duration(
            milliseconds: widget.reduceMotion ? 300 : 500,
          ),
          child: SlideAnimation(
            verticalOffset: widget.reduceMotion ? 20 : 30,
            child: FadeInAnimation(
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Pendientes',
                      openTasks.toString(),
                      Icons.pending_actions_rounded,
                      AppTheme.primaryRed,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'En Proceso',
                      inProgressTasks.toString(),
                      Icons.engineering_rounded,
                      AppTheme.warningAmber,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Urgentes',
                      urgentTasks.toString(),
                      Icons.priority_high_rounded,
                      urgentTasks > 0 ? AppTheme.errorRed : AppTheme.successGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Segunda fila - Métricas gerenciales
        AnimationConfiguration.synchronized(
          duration: Duration(
            milliseconds: widget.reduceMotion ? 300 : 500,
          ),
          child: SlideAnimation(
            verticalOffset: widget.reduceMotion ? 20 : 30,
            child: FadeInAnimation(
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Vencidas',
                      overdueTasks.toString(),
                      Icons.warning_amber_rounded,
                      overdueTasks > 0 ? AppTheme.errorRed : AppTheme.successGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Completadas',
                      provider.completedTasks.length.toString(),
                      Icons.check_circle_rounded,
                      AppTheme.successGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Costo Mensual',
                      provider.monthlyCostFormatted,
                      Icons.attach_money_rounded,
                      AppTheme.primaryRed,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: color,
                size: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.mediumGray,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prioridad',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        FilterChipRow(
          options: _priorityFilters,
          selectedOption: _selectedPriority,
          onSelectionChanged: (priority) {
            setState(() {
              _selectedPriority = priority;
            });
            _filterTasks();
          },
          reduceMotion: widget.reduceMotion,
        ),
        const SizedBox(height: 16),
        Text(
          'Estado',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        FilterChipRow(
          options: _statusFilters,
          selectedOption: _selectedStatus,
          onSelectionChanged: (status) {
            setState(() {
              _selectedStatus = status;
            });
            _filterTasks();
          },
          reduceMotion: widget.reduceMotion,
        ),
      ],
    );
  }

  Widget _buildTasksList(List<MaintenanceTask> tasks) {
    if (tasks.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 64,
                color: AppTheme.mediumGray,
              ),
              const SizedBox(height: 16),
              Text(
                'No se encontraron tareas',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.mediumGray,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Intenta ajustar tus filtros',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mediumGray,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final task = tasks[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: Duration(
                milliseconds: widget.reduceMotion ? 300 : 500,
              ),
              child: SlideAnimation(
                verticalOffset: widget.reduceMotion ? 20 : 30,
                child: FadeInAnimation(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TaskCard(
                      task: task,
                      onTap: () => _showTaskDetails(task),
                      onStatusUpdate: (newStatus) => _updateTaskStatus(task, newStatus),
                      reduceMotion: widget.reduceMotion,
                    ),
                  ),
                ),
              ),
            );
          },
          childCount: tasks.length,
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => _showCreateTaskDialog(),
      tooltip: 'Nueva Orden de Mantenimiento',
      child: const Icon(Icons.add_task_rounded),
    );
  }

  void _showTaskDetails(MaintenanceTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TaskDetailsSheet(
        task: task,
        onStatusUpdate: (newStatus) {
          Navigator.of(context).pop();
          _updateTaskStatus(task, newStatus);
        },
        onEdit: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MaintenanceTaskFormScreen(task: task),
            ),
          );
        },
        onDelete: () {
          Navigator.of(context).pop();
          _confirmDeleteTask(task);
        },
        reduceMotion: widget.reduceMotion,
      ),
    );
  }

  Future<void> _confirmDeleteTask(MaintenanceTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Tarea'),
        content: Text('¿Estás seguro de que quieres eliminar la tarea "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryRed,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteTask(task);
    }
  }

  Future<void> _deleteTask(MaintenanceTask task) async {
    try {
      await context.read<MaintenanceProvider>().deleteTask(task.id);
      
      // Verificar si el equipo debe volver a disponible
      final equipmentProvider = context.read<EquipmentProvider>();
      final maintenanceProvider = context.read<MaintenanceProvider>();
      
      // Verificar si hay otras tareas activas para este equipo
      final otherActiveTasks = maintenanceProvider.tasks.where(
        (t) => t.equipmentId == task.equipmentId && 
               t.id != task.id &&
               t.status != TaskStatus.completed,
      ).toList();
      
      // Si no hay más tareas activas, cambiar equipo a disponible
      if (otherActiveTasks.isEmpty) {
        final equipment = equipmentProvider.equipment.firstWhere(
          (e) => e.id == task.equipmentId,
        );
        final updatedEquipment = equipment.copyWith(
          status: EquipmentStatus.available,
        );
        await equipmentProvider.updateEquipment(updatedEquipment);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarea eliminada exitosamente'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    }
  }

  void _updateTaskStatus(MaintenanceTask task, TaskStatus newStatus) async {
    final updatedTask = task.copyWith(
      status: newStatus,
      startedAt: newStatus == TaskStatus.inProgress ? DateTime.now() : task.startedAt,
      completedAt: newStatus == TaskStatus.completed ? DateTime.now() : null,
    );

    await context.read<MaintenanceProvider>().updateTask(updatedTask);
    
    // Si la tarea se completa, verificar si el equipo debe volver a disponible
    if (newStatus == TaskStatus.completed) {
      final equipmentProvider = context.read<EquipmentProvider>();
      final maintenanceProvider = context.read<MaintenanceProvider>();
      
      // Verificar si hay otras tareas activas para este equipo
      final otherActiveTasks = maintenanceProvider.tasks.where(
        (t) => t.equipmentId == task.equipmentId && 
               t.id != task.id &&
               t.status != TaskStatus.completed,
      ).toList();
      
      // Si no hay más tareas activas, cambiar equipo a disponible
      if (otherActiveTasks.isEmpty) {
        final equipment = equipmentProvider.equipment.firstWhere(
          (e) => e.id == task.equipmentId,
        );
        final updatedEquipment = equipment.copyWith(
          status: EquipmentStatus.available,
        );
        await equipmentProvider.updateEquipment(updatedEquipment);
      }
    }
    
    _filterTasks();

    // Show success animation/feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tarea ${newStatus.displayName.toLowerCase()}'),
        backgroundColor: _getStatusColor(newStatus),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCreateTaskDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MaintenanceTaskFormScreen(),
      ),
    );
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.open:
        return AppTheme.primaryRed;
      case TaskStatus.inProgress:
        return AppTheme.warningAmber;
      case TaskStatus.completed:
        return AppTheme.successGreen;
    }
  }
}

class _TaskDetailsSheet extends StatelessWidget {
  final MaintenanceTask task;
  final Function(TaskStatus) onStatusUpdate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool reduceMotion;

  const _TaskDetailsSheet({
    required this.task,
    required this.onStatusUpdate,
    required this.onEdit,
    required this.onDelete,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 50),
      decoration: const BoxDecoration(
        color: AppTheme.primaryWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: AppTheme.mediumGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: onEdit,
                  tooltip: 'Editar',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded),
                  onPressed: onDelete,
                  color: AppTheme.primaryRed,
                  tooltip: 'Eliminar',
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.darkGray,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow(
                    Icons.inventory_2_rounded,
                    'Equipo',
                    task.equipmentName,
                    context,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.person_rounded,
                    'Técnico',
                    task.assignedTechnician,
                    context,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.schedule_rounded,
                    'Programada',
                    _formatDateTime(task.scheduledDate),
                    context,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.timer_rounded,
                    'Duration',
                    '${task.estimatedDuration.inMinutes} min',
                    context,
                  ),
                  const Spacer(),
                  if (task.status != TaskStatus.completed) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final nextStatus = task.status == TaskStatus.open
                              ? TaskStatus.inProgress
                              : TaskStatus.completed;
                          onStatusUpdate(nextStatus);
                        },
                        icon: Icon(
                          task.status == TaskStatus.open
                              ? Icons.play_arrow_rounded
                              : Icons.check_rounded,
                        ),
                        label: Text(
                          task.status == TaskStatus.open
                              ? 'Start Task'
                              : 'Complete Task',
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.successGreen.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.successGreen,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tarea Completada',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppTheme.successGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (task.completedAt != null)
                                  Text(
                                    'Completado el ${_formatDateTime(task.completedAt!)}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.mediumGray,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.lightGray,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppTheme.primaryRed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mediumGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (date == today) {
      return 'Today ${_formatTime(dateTime)}';
    } else if (date == today.add(const Duration(days: 1))) {
      return 'Tomorrow ${_formatTime(dateTime)}';
    } else if (date == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${_formatTime(dateTime)}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
