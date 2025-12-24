import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../models/equipment.dart';
import '../../providers/equipment_provider.dart';
import '../../widgets/equipment_card.dart';
import '../../widgets/filter_chip_row.dart';
import 'equipment_detail_screen.dart';
import 'equipment_form_screen.dart';

class InventoryScreen extends StatefulWidget {
  final bool reduceMotion;

  const InventoryScreen({
    super.key,
    required this.reduceMotion,
  });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _searchAnimationController;
  late Animation<double> _searchAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isGridView = true;
  String _selectedCategory = 'Todos';
  String _selectedStatus = 'Todos';

  final List<String> _categories = [
    'Todos',
    'Construcción',
    'Jardinería', 
    'Herramientas Eléctricas',
    'Maquinaria Pesada',
    'Equipo de Seguridad',
  ];

  final List<String> _statusFilters = [
    'Todos',
    'Disponible',
    'Alquilado',
    'Mantenimiento',
    'Fuera de Servicio',
  ];

  List<Equipment> _filteredEquipment = [];

  @override
  void initState() {
    super.initState();
    _searchAnimationController = AnimationController(
      duration: Duration(
        milliseconds: widget.reduceMotion ? 200 : 300,
      ),
      vsync: this,
    );
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    );
    
    _searchController.addListener(() {
      _filterEquipment();
    });
    
    // Cargar equipos al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EquipmentProvider>().loadEquipment();
    });
  }

  @override
  void dispose() {
    _searchAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterEquipment() {
    final provider = context.read<EquipmentProvider>();
    setState(() {
      _filteredEquipment = provider.equipment.where((equipment) {
        final matchesSearch = _searchController.text.isEmpty ||
            equipment.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            equipment.id.toLowerCase().contains(_searchController.text.toLowerCase());
        
        final matchesCategory = _selectedCategory == 'Todos' ||
            equipment.category == _selectedCategory;
        
        final matchesStatus = _selectedStatus == 'Todos' ||
            equipment.status.displayName == _selectedStatus;
        
        return matchesSearch && matchesCategory && matchesStatus;
      }).toList();
    });
  }

  Future<void> _refreshEquipment() async {
    await context.read<EquipmentProvider>().loadEquipment();
    _filterEquipment();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Consumer<EquipmentProvider>(
        builder: (context, equipmentProvider, child) {
          // Calcular equipos filtrados sin llamar setState
          List<Equipment> displayedEquipment;
          if (_searchController.text.isEmpty && _selectedCategory == 'Todos' && _selectedStatus == 'Todos') {
            displayedEquipment = equipmentProvider.equipment;
          } else {
            displayedEquipment = equipmentProvider.equipment.where((equipment) {
              final matchesSearch = _searchController.text.isEmpty ||
                  equipment.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                  equipment.id.toLowerCase().contains(_searchController.text.toLowerCase());
              
              final matchesCategory = _selectedCategory == 'Todos' ||
                  equipment.category == _selectedCategory;
              
              final matchesStatus = _selectedStatus == 'Todos' ||
                  equipment.status.displayName == _selectedStatus;
              
              return matchesSearch && matchesCategory && matchesStatus;
            }).toList();
          }
          _filteredEquipment = displayedEquipment;

          return RefreshIndicator(
            onRefresh: _refreshEquipment,
            child: CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildStatsRow(equipmentProvider),
                      const SizedBox(height: 16),
                      _buildSearchBar(),
                      const SizedBox(height: 16),
                      _buildFilterChips(),
                      const SizedBox(height: 16),
                      _buildViewToggle(),
                      const SizedBox(height: 16),
                    ]),
                  ),
                ),
                if (equipmentProvider.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  _buildEquipmentGrid(),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100), // Bottom padding for navigation
                ),
              ],
            ),
          );
        },
      ),
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
                'Inventario de Equipos',
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
                  'Inventario de Equipos',
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
                _searchController.clear();
                _filterEquipment();
              }
            });
            
            if (_isSearching) {
              _searchAnimationController.forward();
            } else {
              _searchAnimationController.reverse();
            }
          },
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
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar equipos...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchController.clear();
                      _filterEquipment();
                    },
                  )
                : null,
          ),
          onChanged: (value) => _filterEquipment(),
        ),
      ),
    );
  }

  Widget _buildStatsRow(EquipmentProvider provider) {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    provider.availableEquipment.length.toString(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.successGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text('Disponibles'),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    provider.rentedEquipment.length.toString(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.primaryRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text('Alquilados'),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    '${provider.utilizationRate.toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.warningAmber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text('Utilización'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categoría',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        FilterChipRow(
          options: _categories,
          selectedOption: _selectedCategory,
          onSelectionChanged: (category) {
            setState(() {
              _selectedCategory = category;
            });
            _filterEquipment();
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
            _filterEquipment();
          },
          reduceMotion: widget.reduceMotion,
        ),
      ],
    );
  }

  Widget _buildViewToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${_filteredEquipment.length} artículos',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.mediumGray,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.lightGray,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildViewToggleButton(
                icon: Icons.grid_view_rounded,
                isSelected: _isGridView,
                onTap: () => setState(() => _isGridView = true),
              ),
              _buildViewToggleButton(
                icon: Icons.view_list_rounded,
                isSelected: !_isGridView,
                onTap: () => setState(() => _isGridView = false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(
          milliseconds: widget.reduceMotion ? 150 : 200,
        ),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryRed : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          color: isSelected ? AppTheme.primaryWhite : AppTheme.mediumGray,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildEquipmentGrid() {
    if (_filteredEquipment.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: AppTheme.mediumGray,
              ),
              const SizedBox(height: 16),
              Text(
                'No se encontraron equipos',
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

    if (_isGridView) {
      final crossAxisCount = ResponsiveHelper.getGridColumns(context);
      return SliverPadding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getPadding(context),
        ),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: ResponsiveHelper.getResponsiveValue(
              context: context,
              mobile: 0.9,
              tablet: 1.0,
              desktop: 1.1,
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
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final equipment = _filteredEquipment[index];
              return AnimationConfiguration.staggeredGrid(
                position: index,
                duration: Duration(
                  milliseconds: widget.reduceMotion ? 300 : 500,
                ),
                columnCount: crossAxisCount,
                child: SlideAnimation(
                  verticalOffset: widget.reduceMotion ? 20 : 50,
                  child: FadeInAnimation(
                    child: _buildEquipmentCardWithActions(equipment, true),
                  ),
                ),
              );
            },
            childCount: _filteredEquipment.length,
          ),
        ),
      );
    } else {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final equipment = _filteredEquipment[index];
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
                      child: _buildEquipmentCardWithActions(equipment, false),
                    ),
                  ),
                ),
              );
            },
            childCount: _filteredEquipment.length,
          ),
        ),
      );
    }
  }

  void _navigateToDetail(Equipment equipment) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            EquipmentDetailScreen(
          equipment: equipment,
          reduceMotion: widget.reduceMotion,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.fastOutSlowIn;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: Duration(
          milliseconds: widget.reduceMotion ? 200 : 300,
        ),
      ),
    );
  }

  Widget _buildEquipmentCardWithActions(Equipment equipment, bool isGridView) {
    return Stack(
      children: [
        EquipmentCard(
          equipment: equipment,
          isGridView: isGridView,
          onTap: () => _navigateToDetail(equipment),
          reduceMotion: widget.reduceMotion,
        ),
        Positioned(
          top: 8,
          right: 8,
          child: PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.primaryWhite.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.more_vert,
                size: 20,
                color: AppTheme.darkGray,
              ),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20, color: AppTheme.primaryRed),
                    SizedBox(width: 12),
                    Text('Editar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: AppTheme.errorRed),
                    SizedBox(width: 12),
                    Text('Eliminar'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'edit') {
                _navigateToForm(equipment);
              } else if (value == 'delete') {
                _confirmDelete(equipment);
              }
            },
          ),
        ),
      ],
    );
  }

  void _navigateToForm(Equipment? equipment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EquipmentFormScreen(
          equipment: equipment,
          reduceMotion: widget.reduceMotion,
        ),
      ),
    ).then((_) {
      // Recargar lista después de agregar/editar
      _refreshEquipment();
    });
  }

  void _confirmDelete(Equipment equipment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de eliminar "${equipment.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteEquipment(equipment);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: AppTheme.primaryWhite,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEquipment(Equipment equipment) async {
    try {
      await context.read<EquipmentProvider>().deleteEquipment(equipment.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${equipment.name} eliminado exitosamente'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        _refreshEquipment();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
}
