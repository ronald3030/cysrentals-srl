import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/equipment.dart';
import '../../models/maintenance_task.dart';
import '../../providers/maintenance_provider.dart';

class MaintenanceHistoryScreen extends StatefulWidget {
  final bool reduceMotion;

  const MaintenanceHistoryScreen({
    super.key,
    required this.reduceMotion,
  });

  @override
  State<MaintenanceHistoryScreen> createState() => _MaintenanceHistoryScreenState();
}

class _MaintenanceHistoryScreenState extends State<MaintenanceHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<MaintenanceRecord> _filteredRecords = [];
  String _selectedFilter = 'Todos';

  final List<String> _filterOptions = [
    'Todos',
    'Rutina',
    'Reparación',
    'Inspección',
    'Actualización',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterRecords);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterRecords() {
    setState(() {});
  }

  List<MaintenanceRecord> _getAllRecordsFromTasks(MaintenanceProvider provider) {
    // Convertir tareas completadas a registros de mantenimiento
    final completedTasks = provider.tasks.where((t) => t.status == TaskStatus.completed).toList();
    
    return completedTasks.map((task) {
      MaintenanceType type;
      switch (task.priority) {
        case TaskPriority.low:
          type = MaintenanceType.routine;
          break;
        case TaskPriority.medium:
          type = MaintenanceType.inspection;
          break;
        case TaskPriority.high:
          type = MaintenanceType.repair;
          break;
      }
      
      return MaintenanceRecord(
        id: task.id,
        date: task.scheduledDate,
        description: task.description,
        technician: task.assignedTechnician,
        cost: task.cost ?? 0.0,
        type: type,
      );
    }).toList();
  }

  List<MaintenanceRecord> _getFilteredRecords(List<MaintenanceRecord> allRecords) {
    final query = _searchController.text.toLowerCase();
    
    var filtered = allRecords.where((record) {
      final matchesSearch = query.isEmpty ||
          record.description.toLowerCase().contains(query) ||
          record.technician.toLowerCase().contains(query) ||
          record.id.toLowerCase().contains(query);
      
      final matchesFilter = _selectedFilter == 'Todos' ||
          record.type.displayName == _selectedFilter;
      
      return matchesSearch && matchesFilter;
    }).toList();
    
    // Sort by date (newest first)
    filtered.sort((a, b) => b.date.compareTo(a.date));
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MaintenanceProvider>(
      builder: (context, provider, child) {
        final allRecords = _getAllRecordsFromTasks(provider);
        final filteredRecords = _getFilteredRecords(allRecords);
        
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSearchBar(),
                    const SizedBox(height: 16),
                    _buildFilterChips(),
                    const SizedBox(height: 16),
                    _buildSummaryStats(filteredRecords),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
              _buildRecordsList(filteredRecords),
              const SliverPadding(
                padding: EdgeInsets.only(bottom: 100),
              ),
            ],
          ),
        );
      },
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
                'Historial de Mantenimiento',
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
                  'Historial de Mantenimiento',
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
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Buscar en historial...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () {
                  _searchController.clear();
                  _filterRecords();
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: AppTheme.lightGray,
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = _filterOptions[index];
          final isSelected = _selectedFilter == option;
          
          return FilterChip(
            label: Text(option),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedFilter = option;
                _filterRecords();
              });
            },
            backgroundColor: AppTheme.lightGray,
            selectedColor: AppTheme.primaryRed.withOpacity(0.2),
            checkmarkColor: AppTheme.primaryRed,
            labelStyle: TextStyle(
              color: isSelected ? AppTheme.primaryRed : AppTheme.darkGray,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryStats(List<MaintenanceRecord> filteredRecords) {
    // Totales del mes actual
    final now = DateTime.now();
    final monthRecords = filteredRecords.where((r) =>
      r.date.year == now.year && r.date.month == now.month
    ).toList();

    final totalCost = monthRecords.fold<double>(
      0, (sum, record) => sum + (record.cost ?? 0)
    );
    final avgCost = monthRecords.isNotEmpty ? totalCost / monthRecords.length : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatColumn(
                'Registros (mes)',
                monthRecords.length.toString(),
                Icons.history_rounded,
                AppTheme.primaryRed,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatColumn(
                'Costo Total (mes)',
                'RD\$${totalCost.toStringAsFixed(0)}',
                Icons.attach_money_rounded,
                AppTheme.warningAmber,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatColumn(
                'Promedio (mes)',
                'RD\$${avgCost.toStringAsFixed(0)}',
                Icons.analytics_rounded,
                AppTheme.successGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryBlack,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.mediumGray,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecordsList(List<MaintenanceRecord> filteredRecords) {
    if (filteredRecords.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history_rounded,
                size: 64,
                color: AppTheme.mediumGray,
              ),
              const SizedBox(height: 16),
              Text(
                'No se encontraron registros',
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
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: Duration(
                milliseconds: widget.reduceMotion ? 200 : 400,
              ),
              child: SlideAnimation(
                verticalOffset: widget.reduceMotion ? 0 : 50,
                child: FadeInAnimation(
                  child: _buildRecordCard(filteredRecords[index]),
                ),
              ),
            );
          },
          childCount: filteredRecords.length,
        ),
      ),
    );
  }

  Widget _buildRecordCard(MaintenanceRecord record) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getTypeColor(record.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getTypeIcon(record.type),
                    color: _getTypeColor(record.type),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.type.displayName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: _getTypeColor(record.type),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        record.id,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (record.cost != null)
                      Text(
                        '\$${record.cost!.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlack,
                        ),
                      ),
                    Text(
                      _formatDate(record.date),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mediumGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              record.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.person_rounded,
                  size: 16,
                  color: AppTheme.mediumGray,
                ),
                const SizedBox(width: 8),
                Text(
                  record.technician,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mediumGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.routine:
        return AppTheme.successGreen;
      case MaintenanceType.repair:
        return AppTheme.primaryRed;
      case MaintenanceType.inspection:
        return AppTheme.warningAmber;
      case MaintenanceType.upgrade:
        return Colors.blue;
    }
  }

  IconData _getTypeIcon(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.routine:
        return Icons.schedule_rounded;
      case MaintenanceType.repair:
        return Icons.build_rounded;
      case MaintenanceType.inspection:
        return Icons.search_rounded;
      case MaintenanceType.upgrade:
        return Icons.upgrade_rounded;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
