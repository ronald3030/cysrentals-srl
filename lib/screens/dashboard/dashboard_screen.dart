import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../models/equipment.dart';
import '../../models/maintenance_task.dart';
import '../../models/rental.dart';
import '../../providers/equipment_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/quick_action_button.dart';
import '../reports/profitability_screen.dart';
import '../invoices/invoice_screen.dart';

class DashboardScreen extends StatefulWidget {
  final bool reduceMotion;
  final Function(int)? onNavigateToPage;

  const DashboardScreen({
    super.key,
    required this.reduceMotion,
    this.onNavigateToPage,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  late Animation<double> _refreshAnimation;
  bool _isRefreshing = false;
  int _touchedPieIndex = -1;
  String _selectedPeriod = 'Semana'; // 'Semana' o 'Mes'

  final Map<String, List<String>> _chartLabels = {
    'Semana': ['L', 'M', 'X', 'J', 'V', 'S', 'D'],
    'Mes': ['E', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'],
  };

  // Calcular datos de alquileres por periodo
  List<FlSpot> _calculateRentalData(EquipmentProvider provider, String period) {
    final now = DateTime.now();
    final rentedEquipment = provider.equipment.where((e) => 
      e.rentalStartDate != null && e.status == EquipmentStatus.rented
    ).toList();

    if (period == 'Semana') {
      // Últimos 7 días
      return List.generate(7, (index) {
        final day = now.subtract(Duration(days: 6 - index));
        final count = rentedEquipment.where((e) {
          final startDate = e.rentalStartDate!;
          return startDate.year == day.year && 
                 startDate.month == day.month && 
                 startDate.day == day.day;
        }).length;
        return FlSpot((index + 1).toDouble(), count.toDouble());
      });
    } else {
      // Últimos 12 meses
      return List.generate(12, (index) {
        final monthOffset = 11 - index;
        final month = now.month - monthOffset;
        final year = now.year + (month <= 0 ? -1 : 0);
        final targetMonth = month <= 0 ? month + 12 : month;
        
        final count = rentedEquipment.where((e) {
          final startDate = e.rentalStartDate!;
          return startDate.year == year && startDate.month == targetMonth;
        }).length;
        return FlSpot((index + 1).toDouble(), count.toDouble());
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _refreshAnimation = CurvedAnimation(
      parent: _refreshController,
      curve: Curves.easeInOut,
    );
    
    // Cargar datos de los providers al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EquipmentProvider>().loadEquipment();
      context.read<CustomerProvider>().loadCustomers();
      context.read<MaintenanceProvider>().loadTasks();
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    _refreshController.forward();
    
    // Cargar datos desde Supabase
    await Future.wait([
      context.read<EquipmentProvider>().loadEquipment(),
      context.read<CustomerProvider>().loadCustomers(),
      context.read<MaintenanceProvider>().loadTasks(),
    ]);
    
    setState(() {
      _isRefreshing = false;
    });
    
    _refreshController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<EquipmentProvider, CustomerProvider, MaintenanceProvider>(
      builder: (context, equipmentProvider, customerProvider, maintenanceProvider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppTheme.primaryRed,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildAppBar(),
                SliverPadding(
                  padding: EdgeInsets.all(
                    ResponsiveHelper.getPadding(context),
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildKPISection(equipmentProvider, customerProvider, maintenanceProvider),
                      SizedBox(height: ResponsiveHelper.getSpacing(context, 24)),
                      _buildChartsSection(equipmentProvider),
                      SizedBox(height: ResponsiveHelper.getSpacing(context, 24)),
                      _buildQuickActionsSection(equipmentProvider, customerProvider, maintenanceProvider),
                      SizedBox(height: ResponsiveHelper.getSpacing(context, 24)),
                      _buildRecentActivitySection(equipmentProvider, maintenanceProvider),
                      SizedBox(height: ResponsiveHelper.getResponsiveValue(
                        context: context,
                        mobile: 120.0,
                        tablet: 100.0,
                        desktop: 80.0,
                      )), // Bottom padding for navigation
                    ]),
                  ),
                ),
              ],
            ),
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
            // Si el espacio es muy pequeño (AppBar colapsado), mostrar solo el título principal
            final isCollapsed = constraints.maxHeight <= 80;
            
            if (isCollapsed) {
              return Text(
                'Tablero de Control',
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
                  'Tablero de Control',
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
        RotationTransition(
          turns: _refreshAnimation,
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isRefreshing ? null : _onRefresh,
            tooltip: 'Actualizar',
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildKPISection(EquipmentProvider equipmentProvider, CustomerProvider customerProvider, MaintenanceProvider maintenanceProvider) {
    final activeRentals = equipmentProvider.rentedEquipment.length;
    final utilizationRate = equipmentProvider.utilizationRate.toInt();
    final urgentTasks = maintenanceProvider.highPriorityTasks.length;
    final overdueTasks = maintenanceProvider.overdueTasks.length;
    final gridColumns = ResponsiveHelper.getGridColumns(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Métricas Clave',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        AnimationLimiter(
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: gridColumns,
            childAspectRatio: ResponsiveHelper.getResponsiveValue(
              context: context,
              mobile: 1.5,
              tablet: 1.7,
              desktop: 2.2,
            ),
            crossAxisSpacing: ResponsiveHelper.getResponsiveValue(
              context: context,
              mobile: 12.0,
              tablet: 16.0,
              desktop: 20.0,
            ),
            mainAxisSpacing: ResponsiveHelper.getResponsiveValue(
              context: context,
              mobile: 12.0,
              tablet: 16.0,
              desktop: 20.0,
            ),
            children: [
              AnimationConfiguration.staggeredGrid(
                position: 0,
                duration: Duration(
                  milliseconds: widget.reduceMotion ? 300 : 600,
                ),
                columnCount: gridColumns,
                child: SlideAnimation(
                  verticalOffset: widget.reduceMotion ? 20 : 50,
                  child: FadeInAnimation(
                    child: KPICard(
                      title: 'Alquileres Activos',
                      value: activeRentals,
                      icon: Icons.trending_up_rounded,
                      color: AppTheme.successGreen,
                      reduceMotion: widget.reduceMotion,
                    ),
                  ),
                ),
              ),
              AnimationConfiguration.staggeredGrid(
                position: 1,
                duration: Duration(
                  milliseconds: widget.reduceMotion ? 300 : 600,
                ),
                columnCount: gridColumns,
                child: SlideAnimation(
                  verticalOffset: widget.reduceMotion ? 20 : 50,
                  child: FadeInAnimation(
                    child: KPICard(
                      title: 'Tareas Vencidas',
                      value: overdueTasks,
                      icon: Icons.warning_rounded,
                      color: AppTheme.errorRed,
                      reduceMotion: widget.reduceMotion,
                    ),
                  ),
                ),
              ),
              AnimationConfiguration.staggeredGrid(
                position: 2,
                duration: Duration(
                  milliseconds: widget.reduceMotion ? 300 : 600,
                ),
                columnCount: gridColumns,
                child: SlideAnimation(
                  verticalOffset: widget.reduceMotion ? 20 : 50,
                  child: FadeInAnimation(
                    child: KPICard(
                      title: 'Utilización',
                      value: utilizationRate,
                      suffix: '%',
                      icon: Icons.analytics_rounded,
                      color: AppTheme.primaryRed,
                      reduceMotion: widget.reduceMotion,
                    ),
                  ),
                ),
              ),
              AnimationConfiguration.staggeredGrid(
                position: 3,
                duration: Duration(
                  milliseconds: widget.reduceMotion ? 300 : 600,
                ),
                columnCount: gridColumns,
                child: SlideAnimation(
                  verticalOffset: widget.reduceMotion ? 20 : 50,
                  child: FadeInAnimation(
                    child: KPICard(
                      title: 'Tareas Urgentes',
                      value: urgentTasks,
                      icon: Icons.schedule_rounded,
                      color: AppTheme.warningAmber,
                      reduceMotion: widget.reduceMotion,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartsSection(EquipmentProvider equipmentProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analíticas',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        AnimationConfiguration.synchronized(
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Alquileres - $_selectedPeriod',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.lightGray),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildPeriodButton('Semana'),
                                _buildPeriodButton('Mes'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 20,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.grey.withOpacity(0.2),
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final labels = _chartLabels[_selectedPeriod]!;
                                    final index = value.toInt() - 1;
                                    if (index >= 0 && index < labels.length) {
                                      return Text(
                                        labels[index],
                                        style: Theme.of(context).textTheme.bodySmall,
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _calculateRentalData(equipmentProvider, _selectedPeriod),
                                isCurved: true,
                                color: AppTheme.primaryRed,
                                barWidth: 3,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, barData, index) {
                                    return FlDotCirclePainter(
                                      radius: 4,
                                      color: AppTheme.primaryRed,
                                      strokeWidth: 2,
                                      strokeColor: AppTheme.primaryWhite,
                                    );
                                  },
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: AppTheme.primaryRed.withOpacity(0.1),
                                ),
                              ),
                            ],
                            lineTouchData: LineTouchData(
                              enabled: true,
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((LineBarSpot touchedSpot) {
                                    final tooltipLabels = _selectedPeriod == 'Semana' 
                                        ? ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom']
                                        : ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
                                    final index = touchedSpot.x.toInt() - 1;
                                    final label = index >= 0 && index < tooltipLabels.length 
                                        ? tooltipLabels[index] 
                                        : '';
                                    return LineTooltipItem(
                                      '$label\n${touchedSpot.y.toInt()} alquileres',
                                      const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                              touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                                // Aquí puedes agregar feedback háptico si lo deseas
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        AnimationConfiguration.synchronized(
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
                        'Estado de Equipos',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: _buildPieChartSections(equipmentProvider),
                            centerSpaceRadius: 40,
                            sectionsSpace: 2,
                            pieTouchData: PieTouchData(
                              enabled: true,
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    _touchedPieIndex = -1;
                                    return;
                                  }
                                  _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(EquipmentProvider equipmentProvider, CustomerProvider customerProvider, MaintenanceProvider maintenanceProvider) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    
    // Determinar cuántos botones por fila según el tamaño de pantalla
    final buttonsPerRow = isDesktop ? 4 : (isTablet ? 3 : 3);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Acciones Rápidas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'Total: ${equipmentProvider.equipment.length} equipos',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.mediumGray,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AnimationConfiguration.synchronized(
          duration: Duration(
            milliseconds: widget.reduceMotion ? 300 : 700,
          ),
          child: SlideAnimation(
            verticalOffset: widget.reduceMotion ? 20 : 50,
            child: FadeInAnimation(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Wrap(
                    spacing: ResponsiveHelper.getSpacing(context, 12),
                    runSpacing: ResponsiveHelper.getSpacing(context, 12),
                    children: [
                      SizedBox(
                        width: (constraints.maxWidth - ResponsiveHelper.getSpacing(context, 12) * (buttonsPerRow - 1)) / buttonsPerRow,
                        child: QuickActionButton(
                          icon: Icons.add_circle_outline_rounded,
                          label: 'Nuevo Alquiler',
                          onTap: () {
                            _showNewRentalDialog(context, equipmentProvider, customerProvider);
                          },
                          reduceMotion: widget.reduceMotion,
                        ),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - ResponsiveHelper.getSpacing(context, 12) * (buttonsPerRow - 1)) / buttonsPerRow,
                        child: QuickActionButton(
                          icon: Icons.inventory_rounded,
                          label: 'Ver Inventario',
                          onTap: () {
                            widget.onNavigateToPage?.call(1);
                          },
                          reduceMotion: widget.reduceMotion,
                        ),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - ResponsiveHelper.getSpacing(context, 12) * (buttonsPerRow - 1)) / buttonsPerRow,
                        child: QuickActionButton(
                          icon: Icons.assignment_rounded,
                          label: 'Tareas',
                          onTap: () {
                            widget.onNavigateToPage?.call(3);
                          },
                          reduceMotion: widget.reduceMotion,
                        ),
                      ),
                      if (isDesktop)
                        SizedBox(
                          width: (constraints.maxWidth - ResponsiveHelper.getSpacing(context, 12) * (buttonsPerRow - 1)) / buttonsPerRow,
                          child: QuickActionButton(
                            icon: Icons.people_rounded,
                            label: 'Ver Clientes',
                            onTap: () {
                              widget.onNavigateToPage?.call(2);
                            },
                            reduceMotion: widget.reduceMotion,
                          ),
                        ),
                      if (!isDesktop)
                        SizedBox(
                          width: (constraints.maxWidth - ResponsiveHelper.getSpacing(context, 12) * (buttonsPerRow - 1)) / buttonsPerRow,
                          child: QuickActionButton(
                            icon: Icons.people_rounded,
                            label: 'Ver Clientes',
                            onTap: () {
                              widget.onNavigateToPage?.call(2);
                            },
                            reduceMotion: widget.reduceMotion,
                          ),
                        ),
                      SizedBox(
                        width: (constraints.maxWidth - ResponsiveHelper.getSpacing(context, 12) * (buttonsPerRow - 1)) / buttonsPerRow,
                        child: QuickActionButton(
                          icon: Icons.build_rounded,
                          label: 'Mantenimiento',
                          onTap: () {
                            _showNewMaintenanceDialog(context, maintenanceProvider, equipmentProvider);
                          },
                          reduceMotion: widget.reduceMotion,
                        ),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - ResponsiveHelper.getSpacing(context, 12) * (buttonsPerRow - 1)) / buttonsPerRow,
                        child: QuickActionButton(
                          icon: Icons.analytics_rounded,
                          label: 'Rentabilidad',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfitabilityScreen(),
                              ),
                            );
                          },
                          reduceMotion: widget.reduceMotion,
                        ),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - ResponsiveHelper.getSpacing(context, 12) * (buttonsPerRow - 1)) / buttonsPerRow,
                        child: QuickActionButton(
                          icon: Icons.receipt_long_rounded,
                          label: 'Generar Factura',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const InvoiceScreen(),
                              ),
                            );
                          },
                          reduceMotion: widget.reduceMotion,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection(EquipmentProvider equipmentProvider, MaintenanceProvider maintenanceProvider) {
    final recentEquipment = equipmentProvider.equipment.take(3).toList();
    final recentTasks = maintenanceProvider.completedTasks.take(2).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actividad Reciente',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        AnimationLimiter(
          child: Column(
            children: AnimationConfiguration.toStaggeredList(
              duration: Duration(
                milliseconds: widget.reduceMotion ? 300 : 500,
              ),
              childAnimationBuilder: (widget) => SlideAnimation(
                verticalOffset: this.widget.reduceMotion ? 20 : 30,
                child: FadeInAnimation(child: widget),
              ),
              children: [
                if (recentEquipment.isNotEmpty)
                  ...recentEquipment.map((equipment) => _buildActivityItem(
                    'Equipo: ${equipment.name}',
                    'Estado: ${equipment.status.displayName} - ${equipment.category}',
                    'ID: ${equipment.id}',
                    Icons.inventory_rounded,
                    equipment.status == EquipmentStatus.rented ? AppTheme.successGreen : AppTheme.primaryRed,
                  )),
                if (recentTasks.isNotEmpty)
                  ...recentTasks.map((task) => _buildActivityItem(
                    'Tarea: ${task.title}',
                    'Equipo: ${task.equipmentName}',
                    'Técnico: ${task.assignedTechnician}',
                    Icons.build_circle_rounded,
                    AppTheme.warningAmber,
                  )),
                if (recentEquipment.isEmpty && recentTasks.isEmpty)
                  _buildActivityItem(
                    'Sin actividad reciente',
                    'No hay datos disponibles',
                    'Actualiza para ver actividad',
                    Icons.info_rounded,
                    AppTheme.mediumGray,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    String title,
    String subtitle,
    String time,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Text(
          time,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.mediumGray,
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(EquipmentProvider provider) {
    final total = provider.equipment.length;
    if (total == 0) {
      return [
        PieChartSectionData(
          value: 1,
          title: 'Sin datos',
          color: AppTheme.mediumGray,
          radius: 60,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ];
    }
    
    final rented = provider.rentedEquipment.length;
    final available = provider.availableEquipment.length;
    final maintenance = provider.equipment.where((e) => e.status == EquipmentStatus.maintenance).length;
    final outOfService = provider.equipment.where((e) => e.status == EquipmentStatus.outOfService).length;
    
    final rentedPercent = (rented / total * 100).round();
    final availablePercent = (available / total * 100).round();
    final maintenancePercent = (maintenance / total * 100).round();
    final outPercent = (outOfService / total * 100).round();
    
    return [
      if (rented > 0)
        PieChartSectionData(
          value: rented.toDouble(),
          title: 'Alquilados\n$rentedPercent%',
          color: AppTheme.primaryRed,
          radius: _touchedPieIndex == 0 ? 70 : 60,
          titleStyle: TextStyle(
            color: AppTheme.primaryWhite,
            fontWeight: FontWeight.bold,
            fontSize: _touchedPieIndex == 0 ? 14 : 12,
          ),
        ),
      if (available > 0)
        PieChartSectionData(
          value: available.toDouble(),
          title: 'Disponibles\n$availablePercent%',
          color: AppTheme.successGreen,
          radius: _touchedPieIndex == 1 ? 70 : 60,
          titleStyle: TextStyle(
            color: AppTheme.primaryWhite,
            fontWeight: FontWeight.bold,
            fontSize: _touchedPieIndex == 1 ? 14 : 12,
          ),
        ),
      if (maintenance > 0)
        PieChartSectionData(
          value: maintenance.toDouble(),
          title: 'Mantenimiento\n$maintenancePercent%',
          color: AppTheme.warningAmber,
          radius: _touchedPieIndex == 2 ? 70 : 60,
          titleStyle: TextStyle(
            color: AppTheme.primaryWhite,
            fontWeight: FontWeight.bold,
            fontSize: _touchedPieIndex == 2 ? 14 : 12,
          ),
        ),
      if (outOfService > 0)
        PieChartSectionData(
          value: outOfService.toDouble(),
          title: 'Fuera Servicio\n$outPercent%',
          color: AppTheme.errorRed,
          radius: _touchedPieIndex == 3 ? 70 : 60,
          titleStyle: TextStyle(
            color: AppTheme.primaryWhite,
            fontWeight: FontWeight.bold,
            fontSize: _touchedPieIndex == 3 ? 14 : 12,
          ),
        ),
    ];
  }

  Widget _buildPeriodButton(String period) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryRed : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          period,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryWhite : AppTheme.mediumGray,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // Diálogo para crear nuevo alquiler
  void _showNewRentalDialog(BuildContext context, EquipmentProvider equipmentProvider, CustomerProvider customerProvider) {
    final availableEquipment = equipmentProvider.availableEquipment;
    final activeCustomers = customerProvider.activeCustomers;
    
    if (availableEquipment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay equipos disponibles para alquilar'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }
    
    if (activeCustomers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay clientes activos. Registra un cliente primero.'),
          backgroundColor: AppTheme.warningAmber,
        ),
      );
      return;
    }
    
    String? selectedEquipmentId = availableEquipment.first.id;
    String? selectedCustomerId = activeCustomers.first.id;
    DateTime rentalStart = DateTime.now();
    DateTime rentalEnd = DateTime.now().add(const Duration(days: 7));
    String rateType = 'day'; // 'day' o 'hour'
    final locationController = TextEditingController();
    final priceController = TextEditingController(
      text: availableEquipment.first.dailyRate?.toStringAsFixed(2) ?? '0.00',
    );
    
    // Actualizar precio cuando cambie el equipo
    void updatePrice() {
      final equipment = availableEquipment.firstWhere((e) => e.id == selectedEquipmentId);
      if (equipment.dailyRate != null) {
        priceController.text = equipment.dailyRate!.toStringAsFixed(2);
      }
    }
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nuevo Alquiler'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // EQUIPO
                const Text('Equipo:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedEquipmentId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    prefixIcon: Icon(Icons.construction),
                  ),
                  items: availableEquipment.map((eq) {
                    return DropdownMenuItem(
                      value: eq.id,
                      child: Text(eq.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedEquipmentId = value;
                      updatePrice();
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // CLIENTE
                const Text('Cliente:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedCustomerId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: activeCustomers.map((customer) {
                    return DropdownMenuItem(
                      value: customer.id,
                      child: Text(customer.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCustomerId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // PRECIO Y TIPO DE TARIFA
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Precio:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: priceController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              prefixIcon: Icon(Icons.attach_money),
                              hintText: '0.00',
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Por:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: rateType,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'day', child: Text('Día')),
                              DropdownMenuItem(value: 'hour', child: Text('Hora')),
                            ],
                            onChanged: (value) {
                              setDialogState(() {
                                rateType = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // LUGAR
                const Text('Lugar del Equipo:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    prefixIcon: Icon(Icons.location_on),
                    hintText: 'Dirección donde estará el equipo',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                
                // FECHA INICIO
                const Text('Fecha de Inicio:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: rentalStart,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() {
                        rentalStart = date;
                        // Ajustar fecha fin si es antes del inicio
                        if (rentalEnd.isBefore(rentalStart)) {
                          rentalEnd = rentalStart.add(const Duration(days: 7));
                        }
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.mediumGray),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          '${rentalStart.day}/${rentalStart.month}/${rentalStart.year}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // FECHA FIN
                const Text('Fecha de Fin:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: rentalEnd,
                      firstDate: rentalStart,
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (date != null) {
                      setDialogState(() {
                        rentalEnd = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.mediumGray),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          '${rentalEnd.day}/${rentalEnd.month}/${rentalEnd.year}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // DURACIÓN Y COSTO TOTAL
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Duración:', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text(
                            rateType == 'day'
                                ? '${rentalEnd.difference(rentalStart).inDays} días'
                                : '${rentalEnd.difference(rentalStart).inHours} horas',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Costo Total:', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text(
                            () {
                              final price = double.tryParse(priceController.text) ?? 0.0;
                              final duration = rateType == 'day'
                                  ? rentalEnd.difference(rentalStart).inDays
                                  : rentalEnd.difference(rentalStart).inHours;
                              final total = price * duration;
                              return 'RD\$${total.toStringAsFixed(2)}';
                            }(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.primaryRed,
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedEquipmentId != null && selectedCustomerId != null) {
                  final equipment = availableEquipment.firstWhere((e) => e.id == selectedEquipmentId);
                  final customer = activeCustomers.firstWhere((c) => c.id == selectedCustomerId);
                  final price = double.tryParse(priceController.text) ?? equipment.dailyRate ?? 0.0;
                  final location = locationController.text.trim().isEmpty 
                      ? customer.address 
                      : locationController.text.trim();
                  
                  final duration = rateType == 'day' 
                      ? rentalEnd.difference(rentalStart).inDays 
                      : rentalEnd.difference(rentalStart).inHours;
                  final totalCost = price * duration;
                  
                  // Crear registro de alquiler en Supabase
                  final rental = Rental(
                    id: 'R${DateTime.now().millisecondsSinceEpoch}',
                    equipmentId: equipment.id,
                    equipmentName: equipment.name,
                    customerId: customer.id,
                    customerName: customer.name,
                    startDate: rentalStart,
                    endDate: rentalEnd,
                    location: location,
                    dailyRate: price,
                    rateType: rateType == 'day' ? RateType.day : RateType.hour,
                    totalCost: totalCost,
                    status: RentalStatus.active,
                  );
                  
                  await SupabaseService.createRental(rental);
                  
                  // Actualizar equipo con información de alquiler
                  final updatedEquipment = Equipment(
                    id: equipment.id,
                    name: equipment.name,
                    category: equipment.category,
                    status: EquipmentStatus.rented,
                    description: equipment.description,
                    imageUrl: equipment.imageUrl,
                    customer: customer.name,
                    location: location,
                    dailyRate: price,
                    rentalStartDate: rentalStart,
                    rentalEndDate: rentalEnd,
                    maintenanceHistory: equipment.maintenanceHistory,
                  );
                  
                  await equipmentProvider.updateEquipment(updatedEquipment);
                  
                  // Actualizar cliente con contador de alquileres
                  final updatedCustomer = customer.copyWith(
                    assignedEquipmentCount: customer.assignedEquipmentCount + 1,
                    totalRentals: customer.totalRentals + 1,
                    lastRentalDate: rentalStart,
                    equipmentIds: [
                      ...(customer.equipmentIds ?? []),
                      equipment.id,
                    ],
                  );
                  
                  await customerProvider.updateCustomer(updatedCustomer);
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    final durationText = rateType == 'day'
                        ? '$duration días'
                        : '$duration horas';
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Alquiler registrado: ${equipment.name} → ${customer.name}\n'
                          '$durationText - Total: RD\$${totalCost.toStringAsFixed(2)}',
                        ),
                        backgroundColor: AppTheme.successGreen,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: AppTheme.primaryWhite,
              ),
              child: const Text('Crear Alquiler'),
            ),
          ],
        ),
      ),
    );
  }

  // Diálogo para crear nueva tarea de mantenimiento
  void _showNewMaintenanceDialog(BuildContext context, MaintenanceProvider maintenanceProvider, EquipmentProvider equipmentProvider) {
    final allEquipment = equipmentProvider.equipment;
    
    if (allEquipment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay equipos registrados'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }
    
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final technicianController = TextEditingController();
    String? selectedEquipmentId = allEquipment.first.id;
    String selectedPriority = 'medium';
    String selectedTaskType = 'maintenance';
    DateTime scheduledDate = DateTime.now().add(const Duration(days: 1));
    DateTime? deliveryDate;
    DateTime? finishDate;
    int estimatedDuration = 60;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nueva Tarea de Mantenimiento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  value: selectedEquipmentId,
                  decoration: const InputDecoration(
                    labelText: 'Equipo',
                    border: OutlineInputBorder(),
                  ),
                  items: allEquipment.map((eq) {
                    return DropdownMenuItem(
                      value: eq.id,
                      child: Text(eq.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedEquipmentId = value;
                    });
                  },
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
                DropdownButtonFormField<String>(
                  value: selectedTaskType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Tarea',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'maintenance', child: Text('Mantenimiento')),
                    DropdownMenuItem(value: 'routine', child: Text('Rutina')),
                    DropdownMenuItem(value: 'repair', child: Text('Reparación')),
                    DropdownMenuItem(value: 'inspection', child: Text('Inspección')),
                    DropdownMenuItem(value: 'upgrade', child: Text('Actualización')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedTaskType = value!;
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
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: deliveryDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        deliveryDate = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha de Entrega',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.local_shipping_rounded),
                    ),
                    child: Text(
                      deliveryDate != null
                          ? '${deliveryDate!.day}/${deliveryDate!.month}/${deliveryDate!.year}'
                          : 'No especificada',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: finishDate ?? deliveryDate ?? DateTime.now(),
                      firstDate: deliveryDate ?? DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        finishDate = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha de Finalización',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.check_circle_rounded),
                    ),
                    child: Text(
                      finishDate != null
                          ? '${finishDate!.day}/${finishDate!.month}/${finishDate!.year}'
                          : 'No especificada',
                    ),
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
                    technicianController.text.isEmpty ||
                    selectedEquipmentId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor completa todos los campos'),
                      backgroundColor: AppTheme.warningAmber,
                    ),
                  );
                  return;
                }
                
                final equipment = allEquipment.firstWhere((e) => e.id == selectedEquipmentId);
                final taskId = 'M${DateTime.now().millisecondsSinceEpoch}';
                
                final TaskType taskType;
                switch (selectedTaskType) {
                  case 'routine':
                    taskType = TaskType.routine;
                    break;
                  case 'repair':
                    taskType = TaskType.repair;
                    break;
                  case 'inspection':
                    taskType = TaskType.inspection;
                    break;
                  case 'upgrade':
                    taskType = TaskType.upgrade;
                    break;
                  default:
                    taskType = TaskType.maintenance;
                }
                
                final newTask = MaintenanceTask(
                  id: taskId,
                  title: titleController.text,
                  description: descriptionController.text,
                  equipmentId: equipment.id,
                  equipmentName: equipment.name,
                  priority: selectedPriority == 'high' ? TaskPriority.high : 
                           selectedPriority == 'low' ? TaskPriority.low : TaskPriority.medium,
                  status: TaskStatus.open,
                  scheduledDate: scheduledDate,
                  assignedTechnician: technicianController.text,
                  estimatedDuration: Duration(minutes: estimatedDuration),
                  taskType: taskType,
                  deliveryDate: deliveryDate,
                  finishDate: finishDate,
                );
                
                await maintenanceProvider.addTask(newTask);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tarea creada: ${titleController.text}'),
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
}
