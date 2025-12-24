import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';
import 'dashboard/dashboard_screen.dart';
import 'inventory/inventory_screen.dart';
import 'inventory/equipment_form_screen.dart';
import 'customers/customers_screen.dart';
import 'maintenance/maintenance_screen.dart';
import 'profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  final bool reduceMotion;

  const MainScreen({
    super.key,
    required this.reduceMotion,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.dashboard_rounded,
      label: 'Inicio',
      activeIcon: Icons.dashboard_rounded,
    ),
    NavigationItem(
      icon: Icons.inventory_2_outlined,
      label: 'Inventario',
      activeIcon: Icons.inventory_2,
    ),
    NavigationItem(
      icon: Icons.people_outline_rounded,
      label: 'Clientes',
      activeIcon: Icons.people_rounded,
    ),
    NavigationItem(
      icon: Icons.build_outlined,
      label: 'Mantenimiento',
      activeIcon: Icons.build_rounded,
    ),
    NavigationItem(
      icon: Icons.person_outline_rounded,
      label: 'Perfil',
      activeIcon: Icons.person_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.fastOutSlowIn,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
      
      _pageController.animateToPage(
        index,
        duration: Duration(
          milliseconds: widget.reduceMotion ? 150 : 300,
        ),
        curve: Curves.fastOutSlowIn,
      );

      // Animate FAB
      _fabAnimationController.reset();
      _fabAnimationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    
    return Scaffold(
      body: Row(
        children: [
          if (isDesktop) _buildSideNavigationBar(),
          Expanded(
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 1400 : double.infinity,
                ),
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  children: [
                    DashboardScreen(
                      reduceMotion: widget.reduceMotion,
                      onNavigateToPage: _onItemTapped,
                    ),
                    InventoryScreen(reduceMotion: widget.reduceMotion),
                    CustomersScreen(reduceMotion: widget.reduceMotion),
                    MaintenanceScreen(reduceMotion: widget.reduceMotion),
                    ProfileScreen(reduceMotion: widget.reduceMotion),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop ? null : _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _navigationItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = _currentIndex == index;

              return Expanded(
                child: _buildNavigationItem(item, index, isSelected),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSideNavigationBar() {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: AppTheme.lightGray,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.construction_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'C&S',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryRed,
                        ),
                      ),
                      Text(
                        'RENTALS SRL',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.darkGray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              children: _navigationItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = _currentIndex == index;

                return _buildSideNavigationItem(item, index, isSelected);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideNavigationItem(NavigationItem item, int index, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected 
                ? AppTheme.primaryRed.withOpacity(0.1)
                : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: isSelected ? AppTheme.primaryRed : AppTheme.mediumGray,
                  size: 22,
                ),
                const SizedBox(width: 16),
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSelected ? AppTheme.primaryRed : AppTheme.darkGray,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItem(NavigationItem item, int index, bool isSelected) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: SizedBox(
        width: 70,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              color: isSelected
                  ? AppTheme.primaryRed
                  : AppTheme.mediumGray,
              size: 18,
            ),
            const SizedBox(height: 1),
            SizedBox(
              width: 60,
              child: Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: isSelected
                      ? AppTheme.primaryRed
                      : AppTheme.mediumGray,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 9,
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    // Only show FAB on Inventory screen
    if (_currentIndex != 1) return null;

    return ScaleTransition(
      scale: _fabAnimation,
      child: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add equipment functionality
          _showAddEquipmentDialog();
        },
        tooltip: 'Agregar Equipo',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showAddEquipmentDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EquipmentFormScreen(
          equipment: null,
          reduceMotion: widget.reduceMotion,
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
