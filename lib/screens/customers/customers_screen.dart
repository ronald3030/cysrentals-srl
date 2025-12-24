import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../models/customer.dart';
import '../../models/rental.dart';
import '../../providers/customer_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/customer_card.dart';
import 'customer_form_screen.dart';

class RentalHistory {
  final String equipmentName;
  final String equipmentId;
  final DateTime startDate;
  final DateTime endDate;
  final double totalCost;
  final String location;
  final int daysRented;
  final double dailyRate;

  RentalHistory({
    required this.equipmentName,
    required this.equipmentId,
    required this.startDate,
    required this.endDate,
    required this.totalCost,
    required this.location,
    required this.daysRented,
    required this.dailyRate,
  });
}

class CustomersScreen extends StatefulWidget {
  final bool reduceMotion;

  const CustomersScreen({
    super.key,
    required this.reduceMotion,
  });

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen>
    with TickerProviderStateMixin {
  late AnimationController _searchController;
  late Animation<double> _searchAnimation;
  
  final TextEditingController _searchTextController = TextEditingController();
  bool _isSearching = false;

  List<Customer> _filteredCustomers = [];

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
    
    _searchTextController.addListener(_filterCustomers);
    
    // Cargar clientes al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchTextController.dispose();
    super.dispose();
  }

  void _filterCustomers() {
    setState(() {
      final provider = context.read<CustomerProvider>();
      final query = _searchTextController.text.toLowerCase();
      if (query.isEmpty) {
        _filteredCustomers = provider.customers;
      } else {
        _filteredCustomers = provider.customers.where((customer) {
          return customer.name.toLowerCase().contains(query) ||
              customer.phone.contains(query) ||
              customer.address.toLowerCase().contains(query) ||
              customer.id.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _refreshCustomers() async {
    await context.read<CustomerProvider>().loadCustomers();
    _filterCustomers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Consumer<CustomerProvider>(
        builder: (context, customerProvider, child) {
          // Actualizar filteredCustomers cuando cambien los datos
          if (_searchTextController.text.isEmpty) {
            _filteredCustomers = customerProvider.customers;
          } else {
            final query = _searchTextController.text.toLowerCase();
            _filteredCustomers = customerProvider.customers.where((customer) {
              return customer.name.toLowerCase().contains(query) ||
                  customer.phone.contains(query) ||
                  customer.address.toLowerCase().contains(query) ||
                  customer.id.toLowerCase().contains(query);
            }).toList();
          }

          return RefreshIndicator(
            onRefresh: _refreshCustomers,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
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
                            'Clientes',
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
                              'Clientes',
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
                      icon: Icon(_isSearching ? Icons.search_off : Icons.search),
                      onPressed: () {
                        setState(() {
                          _isSearching = !_isSearching;
                          if (!_isSearching) {
                            _searchTextController.clear();
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                SliverPadding(
                  padding: EdgeInsets.all(
                    ResponsiveHelper.getPadding(context) * 0.5,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (_isSearching) _buildSearchBar(),
                      _buildStatsRow(customerProvider),
                      const SizedBox(height: 16),
                    ]),
                  ),
                ),
                if (customerProvider.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  _buildCustomersListSimple(),
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
        title: Text(
          'Clientes',
          style: Theme.of(context).textTheme.headlineMedium,
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
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchTextController,
        decoration: InputDecoration(
          hintText: 'Buscar clientes...',
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
    );
  }

  Widget _buildStatsRow(CustomerProvider provider) {
    final activeCustomers = provider.activeCustomers.length;
    final totalEquipment = provider.totalAssignedEquipment;

    return AnimationConfiguration.synchronized(
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
                  'Clientes Activos',
                  activeCustomers.toString(),
                  Icons.people_rounded,
                  AppTheme.successGreen,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildStatCard(
                  'Equipos Prestados',
                  totalEquipment.toString(),
                  Icons.inventory_2_rounded,
                  AppTheme.primaryRed,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildStatCard(
                  'Total Clientes',
                  provider.customers.length.toString(),
                  Icons.business_rounded,
                  AppTheme.warningAmber,
                ),
              ),
            ],
          ),
        ),
      ),
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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
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

  Widget _buildCustomersList() {
    if (_filteredCustomers.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 64,
                color: AppTheme.mediumGray,
              ),
              const SizedBox(height: 16),
              Text(
                'No se encontraron clientes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.mediumGray,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search',
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
            final customer = _filteredCustomers[index];
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
                    child: CustomerCard(
                      customer: customer,
                      onTap: () => _showCustomerDetails(customer),
                      onAddressUpdate: () => _showAddressUpdateDialog(customer),
                      reduceMotion: widget.reduceMotion,
                    ),
                  ),
                ),
              ),
            );
          },
          childCount: _filteredCustomers.length,
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CustomerFormScreen(
              reduceMotion: widget.reduceMotion,
            ),
          ),
        );
      },
      tooltip: 'Agregar Cliente',
      child: const Icon(Icons.person_add_rounded),
    );
  }

  Widget _buildCustomersListSimple() {
    if (_filteredCustomers.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 64,
                color: AppTheme.mediumGray,
              ),
              SizedBox(height: 16),
              Text(
                'No se encontraron clientes',
                style: TextStyle(color: AppTheme.mediumGray),
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
            final customer = _filteredCustomers[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CustomerCard(
                customer: customer,
                onTap: () => _showCustomerDetails(customer),
                onAddressUpdate: () => _showAddressUpdateDialog(customer),
                onEdit: () => _navigateToEditForm(customer),
                onDelete: () => _confirmDeleteCustomer(customer),
                reduceMotion: widget.reduceMotion,
              ),
            );
          },
          childCount: _filteredCustomers.length,
        ),
      ),
    );
  }

  void _showCustomerDetails(Customer customer) async {
    // Cargar historial de alquileres desde Supabase
    List<RentalHistory> history = [];
    try {
      final rentals = await SupabaseService.getRentalsByCustomer(customer.id);
      history = rentals.map((rental) {
        return RentalHistory(
          equipmentName: rental.equipmentName,
          equipmentId: rental.equipmentId,
          startDate: rental.startDate,
          endDate: rental.endDate,
          totalCost: rental.totalCost,
          location: rental.location,
          daysRented: rental.rateType == RateType.day 
              ? rental.durationInDays 
              : (rental.durationInHours / 24).ceil(),
          dailyRate: rental.dailyRate,
        );
      }).toList();
    } catch (e) {
      print('Error cargando historial de alquileres: $e');
    }
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CustomerDetailsSheet(
        customer: customer,
        reduceMotion: widget.reduceMotion,
        rentalHistory: {customer.id: history},
      ),
    );
  }

  void _showAddressUpdateDialog(Customer customer) {
    final addressController = TextEditingController(text: customer.address);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Actualizar Dirección'),
        content: TextField(
          controller: addressController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Dirección del Cliente',
            hintText: 'Ingresa la nueva dirección...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement address update functionality
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dirección actualizada exitosamente'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  void _navigateToEditForm(Customer customer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomerFormScreen(
          customer: customer,
          reduceMotion: widget.reduceMotion,
        ),
      ),
    );
  }

  void _confirmDeleteCustomer(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar a "${customer.name}"?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteCustomer(customer);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: AppTheme.primaryWhite,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCustomer(Customer customer) async {
    try {
      await context.read<CustomerProvider>().deleteCustomer(customer.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cliente eliminado exitosamente'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: ${e.toString()}'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    }
  }
}

class _CustomerDetailsSheet extends StatefulWidget {
  final Customer customer;
  final bool reduceMotion;
  final Map<String, List<RentalHistory>> rentalHistory;

  const _CustomerDetailsSheet({
    required this.customer,
    required this.reduceMotion,
    required this.rentalHistory,
  });

  @override
  State<_CustomerDetailsSheet> createState() => _CustomerDetailsSheetState();
}

class _CustomerDetailsSheetState extends State<_CustomerDetailsSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.customer.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: widget.customer.status == CustomerStatus.active
                            ? AppTheme.successGreen.withOpacity(0.1)
                            : AppTheme.mediumGray.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        widget.customer.status.displayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: widget.customer.status == CustomerStatus.active
                              ? AppTheme.successGreen
                              : AppTheme.mediumGray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Información'),
                    Tab(text: 'Historial'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            Icons.phone_rounded,
            'Teléfono',
            widget.customer.phone,
            context,
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.location_on_rounded,
            'Dirección',
            widget.customer.address,
            context,
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.inventory_2_rounded,
            'Cantidad de Equipos',
            '${widget.customer.assignedEquipmentCount} artículos',
            context,
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.history_rounded,
            'Total Alquileres',
            '${widget.customer.totalRentals} alquileres',
            context,
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.schedule_rounded,
            'Último Alquiler',
            _formatDate(widget.customer.lastRentalDate),
            context,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Navigate to customer equipment list
              },
              icon: const Icon(Icons.inventory_2_rounded),
              label: const Text('Ver Equipos'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final history = widget.rentalHistory[widget.customer.id] ?? [];
    
    if (history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 64,
              color: AppTheme.mediumGray,
            ),
            SizedBox(height: 16),
            Text(
              'Sin historial de alquileres',
              style: TextStyle(
                color: AppTheme.mediumGray,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    double totalRevenue = history.fold(0, (sum, rental) => sum + rental.totalCost);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '${history.length}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryRed,
                    ),
                  ),
                  const Text('Alquileres', style: TextStyle(fontSize: 12)),
                ],
              ),
              Container(width: 1, height: 30, color: AppTheme.lightGray),
              Column(
                children: [
                  Text(
                    'RD\$${totalRevenue.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryRed,
                    ),
                  ),
                  const Text('Ingresos Total', style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final rental = history[index];
              return _buildRentalHistoryCard(rental);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRentalHistoryCard(RentalHistory rental) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    rental.equipmentName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'RD\$${rental.totalCost.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppTheme.successGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'ID: ${rental.equipmentId}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.mediumGray,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: AppTheme.mediumGray),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    rental.location,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Período',
                    '${_formatDate(rental.startDate)} - ${_formatDate(rental.endDate)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem('Días', '${rental.daysRented}'),
                ),
                Expanded(
                  child: _buildDetailItem('Tarifa Diaria', 'RD\$${rental.dailyRate.toStringAsFixed(0)}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.mediumGray,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
