import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../models/equipment.dart';
import '../../models/rental.dart';
import '../../models/maintenance_task.dart';
import '../../providers/equipment_provider.dart';
import '../../services/supabase_service.dart';

class ProfitabilityScreen extends StatefulWidget {
  const ProfitabilityScreen({super.key});

  @override
  State<ProfitabilityScreen> createState() => _ProfitabilityScreenState();
}

class _ProfitabilityScreenState extends State<ProfitabilityScreen> {
  bool _isLoading = false;
  List<Rental> _allRentals = [];
  List<MaintenanceTask> _allMaintenanceTasks = [];
  String? _selectedEquipmentId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  
  final _currencyFormat = NumberFormat.currency(symbol: 'RD\$', decimalDigits: 2);
  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final rentals = await SupabaseService.getRentals();
      final tasks = await SupabaseService.getMaintenanceTasks();
      
      setState(() {
        _allRentals = rentals;
        _allMaintenanceTasks = tasks;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Rental> get _filteredRentals {
    return _allRentals.where((rental) {
      final matchesEquipment = _selectedEquipmentId == null || 
                                rental.equipmentId == _selectedEquipmentId;
      final matchesDate = rental.startDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
                          rental.startDate.isBefore(_endDate.add(const Duration(days: 1)));
      return matchesEquipment && matchesDate;
    }).toList();
  }

  Map<String, EquipmentProfitability> _calculateProfitability() {
    final Map<String, EquipmentProfitability> profitability = {};
    
    for (final rental in _filteredRentals) {
      if (!profitability.containsKey(rental.equipmentId)) {
        profitability[rental.equipmentId] = EquipmentProfitability(
          equipmentId: rental.equipmentId,
          equipmentName: rental.equipmentName,
        );
      }
      profitability[rental.equipmentId]!.addRental(rental);
    }
    
    for (final task in _allMaintenanceTasks) {
      if (task.completedAt != null &&
          task.completedAt!.isAfter(_startDate.subtract(const Duration(days: 1))) &&
          task.completedAt!.isBefore(_endDate.add(const Duration(days: 1)))) {
        if (_selectedEquipmentId == null || task.equipmentId == _selectedEquipmentId) {
          if (!profitability.containsKey(task.equipmentId)) {
            profitability[task.equipmentId] = EquipmentProfitability(
              equipmentId: task.equipmentId,
              equipmentName: task.equipmentName,
            );
          }
          profitability[task.equipmentId]!.addMaintenanceCost(task.cost ?? 0);
        }
      }
    }
    
    return profitability;
  }

  Map<String, double> _calculateMonthlyRevenue() {
    final Map<String, double> monthlyRevenue = {};
    
    for (final rental in _filteredRentals) {
      final monthKey = DateFormat('yyyy-MM').format(rental.startDate);
      monthlyRevenue[monthKey] = (monthlyRevenue[monthKey] ?? 0) + rental.totalCost;
    }
    
    return monthlyRevenue;
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryRed,
              onPrimary: AppTheme.primaryWhite,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profitabilityData = _calculateProfitability();
    final monthlyRevenue = _calculateMonthlyRevenue();
    
    final totalRevenue = _filteredRentals.fold<double>(
      0, (sum, rental) => sum + rental.totalCost
    );
    final totalMaintenanceCost = profitabilityData.values.fold<double>(
      0, (sum, data) => sum + data.maintenanceCost
    );
    final netProfit = totalRevenue - totalMaintenanceCost;
    final profitMargin = totalRevenue > 0 ? (netProfit / totalRevenue) * 100 : 0.0;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis de Rentabilidad'),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: AppTheme.primaryWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Actualizar datos',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(
                  ResponsiveHelper.getPadding(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filtros
                    _buildFiltersSection(context),
                    const SizedBox(height: 24),
                    
                    // Resumen general
                    _buildSummaryCards(
                      totalRevenue,
                      totalMaintenanceCost,
                      netProfit,
                      profitMargin,
                    ),
                    const SizedBox(height: 24),
                    
                    // Ingresos por mes
                    if (monthlyRevenue.isNotEmpty) ...[
                      _buildMonthlyRevenueSection(monthlyRevenue),
                      const SizedBox(height: 24),
                    ],
                    
                    // Rentabilidad por equipo
                    _buildProfitabilityByEquipment(profitabilityData),
                    const SizedBox(height: 24),
                    
                    // Historial de rentas
                    _buildRentalHistory(),
                    SizedBox(height: ResponsiveHelper.getResponsiveValue(
                      context: context,
                      mobile: 120.0,
                      tablet: 100.0,
                      desktop: 80.0,
                    )), // Bottom padding for navigation
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFiltersSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(
          ResponsiveHelper.getPadding(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtros',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Consumer<EquipmentProvider>(
                    builder: (context, provider, child) {
                      return DropdownButtonFormField<String?>(
                        value: _selectedEquipmentId,
                        decoration: const InputDecoration(
                          labelText: 'Equipo',
                          prefixIcon: Icon(Icons.inventory_2_rounded),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Todos los equipos'),
                          ),
                          ...provider.equipment.map((eq) {
                            return DropdownMenuItem(
                              value: eq.id,
                              child: Text(eq.name),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedEquipmentId = value;
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectDateRange,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Rango de fechas',
                        prefixIcon: Icon(Icons.date_range_rounded),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        '${_dateFormat.format(_startDate)} - ${_dateFormat.format(_endDate)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
    double totalRevenue,
    double totalMaintenanceCost,
    double netProfit,
    double profitMargin,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen del Período',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildMetricCard(
              'Ingresos Totales',
              _currencyFormat.format(totalRevenue),
              Icons.attach_money_rounded,
              AppTheme.successGreen,
            ),
            _buildMetricCard(
              'Costos de Mantenimiento',
              _currencyFormat.format(totalMaintenanceCost),
              Icons.build_rounded,
              AppTheme.warningAmber,
            ),
            _buildMetricCard(
              'Ganancia Neta',
              _currencyFormat.format(netProfit),
              Icons.trending_up_rounded,
              netProfit >= 0 ? AppTheme.successGreen : AppTheme.errorRed,
            ),
            _buildMetricCard(
              'Margen de Ganancia',
              '${profitMargin.toStringAsFixed(1)}%',
              Icons.percent_rounded,
              profitMargin >= 50 ? AppTheme.successGreen : 
              profitMargin >= 25 ? AppTheme.warningAmber : AppTheme.errorRed,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(
          ResponsiveHelper.getResponsiveValue(
            context: context,
            mobile: 16.0,
            tablet: 20.0,
            desktop: 24.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyRevenueSection(Map<String, double> monthlyRevenue) {
    final sortedMonths = monthlyRevenue.keys.toList()..sort();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ingresos Mensuales',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedMonths.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final monthKey = sortedMonths[index];
              final revenue = monthlyRevenue[monthKey]!;
              final date = DateFormat('yyyy-MM').parse(monthKey);
              final monthName = DateFormat.yMMMM('es').format(date);
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
                  child: const Icon(Icons.calendar_month_rounded, color: AppTheme.primaryRed),
                ),
                title: Text(
                  monthName[0].toUpperCase() + monthName.substring(1),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Text(
                  _currencyFormat.format(revenue),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successGreen,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProfitabilityByEquipment(Map<String, EquipmentProfitability> data) {
    final sortedData = data.values.toList()
      ..sort((a, b) => b.netProfit.compareTo(a.netProfit));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rentabilidad por Equipo',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (sortedData.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('No hay datos para mostrar'),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedData.length,
            itemBuilder: (context, index) {
              final item = sortedData[index];
              final profitMargin = item.revenue > 0 
                  ? (item.netProfit / item.revenue) * 100 
                  : 0;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: item.netProfit >= 0 
                        ? AppTheme.successGreen.withOpacity(0.1)
                        : AppTheme.errorRed.withOpacity(0.1),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      color: item.netProfit >= 0 
                          ? AppTheme.successGreen 
                          : AppTheme.errorRed,
                    ),
                  ),
                  title: Text(
                    item.equipmentName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${item.rentalCount} alquileres • Ganancia: ${_currencyFormat.format(item.netProfit)}',
                  ),
                  trailing: Chip(
                    label: Text(
                      '${profitMargin.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryWhite,
                      ),
                    ),
                    backgroundColor: profitMargin >= 50 
                        ? AppTheme.successGreen 
                        : profitMargin >= 25 
                            ? AppTheme.warningAmber 
                            : AppTheme.errorRed,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildDetailRow('Ingresos por alquiler', _currencyFormat.format(item.revenue)),
                          const SizedBox(height: 8),
                          _buildDetailRow('Costos de mantenimiento', _currencyFormat.format(item.maintenanceCost)),
                          const SizedBox(height: 8),
                          _buildDetailRow('Ganancia neta', _currencyFormat.format(item.netProfit)),
                          const SizedBox(height: 8),
                          _buildDetailRow('Margen de ganancia', '${profitMargin.toStringAsFixed(1)}%'),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[600]),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildRentalHistory() {
    final sortedRentals = _filteredRentals.toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historial de Alquileres',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (sortedRentals.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('No hay alquileres en este período'),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedRentals.length,
            itemBuilder: (context, index) {
              final rental = sortedRentals[index];
              final duration = rental.endDate.difference(rental.startDate).inDays;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(rental.status).withOpacity(0.1),
                    child: Icon(
                      _getStatusIcon(rental.status),
                      color: _getStatusColor(rental.status),
                    ),
                  ),
                  title: Text(
                    rental.equipmentName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${rental.customerName} • ${_dateFormat.format(rental.startDate)} - ${_dateFormat.format(rental.endDate)}\n'
                    '$duration días • ${rental.rateType == RateType.day ? 'Por día' : 'Por hora'}',
                  ),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _currencyFormat.format(rental.totalCost),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.successGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(rental.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(rental.status),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(rental.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Color _getStatusColor(RentalStatus status) {
    switch (status) {
      case RentalStatus.active:
        return AppTheme.warningAmber;
      case RentalStatus.completed:
        return AppTheme.successGreen;
      case RentalStatus.cancelled:
        return AppTheme.errorRed;
    }
  }

  IconData _getStatusIcon(RentalStatus status) {
    switch (status) {
      case RentalStatus.active:
        return Icons.pending_rounded;
      case RentalStatus.completed:
        return Icons.check_circle_rounded;
      case RentalStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  String _getStatusText(RentalStatus status) {
    switch (status) {
      case RentalStatus.active:
        return 'Activo';
      case RentalStatus.completed:
        return 'Completado';
      case RentalStatus.cancelled:
        return 'Cancelado';
    }
  }
}

class EquipmentProfitability {
  final String equipmentId;
  final String equipmentName;
  double revenue = 0;
  double maintenanceCost = 0;
  int rentalCount = 0;

  EquipmentProfitability({
    required this.equipmentId,
    required this.equipmentName,
  });

  void addRental(Rental rental) {
    revenue += rental.totalCost;
    rentalCount++;
  }

  void addMaintenanceCost(double cost) {
    maintenanceCost += cost;
  }

  double get netProfit => revenue - maintenanceCost;
}
