import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../models/equipment.dart';
import '../../models/maintenance_task.dart';
import '../../providers/equipment_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../reports/profitability_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool reduceMotion;

  const ProfileScreen({
    super.key,
    required this.reduceMotion,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _avatarController;
  late Animation<double> _avatarAnimation;
  
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'Español';

  // Sample user data - in real app this would come from authentication
  final Map<String, dynamic> _userData = {
    'name': 'Carlos Mendoza',
    'email': 'carlos.mendoza@csrentalsrd.com',
    'role': 'Gerente General',
    'branch': 'Sucursal Santo Domingo',
    'phone': '+1 (809) 456-7890',
    'employeeId': 'EMP001',
    'joinDate': DateTime(2020, 1, 15),
  };

  @override
  void initState() {
    super.initState();
    _avatarController = AnimationController(
      duration: Duration(
        milliseconds: widget.reduceMotion ? 300 : 800,
      ),
      vsync: this,
    );
    _avatarAnimation = CurvedAnimation(
      parent: _avatarController,
      curve: Curves.elasticOut,
    );
    
    _loadSettings();
    _avatarController.forward();
  }

  @override
  void dispose() {
    _avatarController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      
      // Cargar datos del perfil guardados
      _userData['name'] = prefs.getString('user_name') ?? 'Carlos Mendoza';
      _userData['email'] = prefs.getString('user_email') ?? 'carlos.mendoza@csrentalsrd.com';
      _userData['phone'] = prefs.getString('user_phone') ?? '+1 (809) 456-7890';
      _userData['branch'] = prefs.getString('user_branch') ?? 'Sucursal Santo Domingo';
      _userData['role'] = prefs.getString('user_role') ?? 'Gerente General';
      _userData['employeeId'] = prefs.getString('user_employee_id') ?? 'EMP001';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
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
                _buildUserInfo(),
                const SizedBox(height: 24),
                _buildQuickStats(),
                const SizedBox(height: 24),
                _buildQuickActions(),
                const SizedBox(height: 24),
                _buildSettingsSection(),
                const SizedBox(height: 24),
                _buildAccountSection(),
                const SizedBox(height: 24),
                _buildAboutSection(),
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
                'Perfil',
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
                  'Perfil',
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
          icon: const Icon(Icons.edit_rounded),
          onPressed: () => _showEditProfileDialog(),
          tooltip: 'Editar Perfil',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildUserInfo() {
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
                children: [
                  ScaleTransition(
                    scale: _avatarAnimation,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: AppTheme.primaryRed.withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 50,
                        color: AppTheme.primaryRed,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userData['name'],
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _userData['role'],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildUserDetailRow(
                    Icons.email_outlined,
                    'Correo',
                    _userData['email'],
                  ),
                  const SizedBox(height: 12),
                  _buildUserDetailRow(
                    Icons.business_outlined,
                    'Sucursal',
                    _userData['branch'],
                  ),
                  const SizedBox(height: 12),
                  _buildUserDetailRow(
                    Icons.phone_outlined,
                    'Teléfono',
                    _userData['phone'],
                  ),
                  const SizedBox(height: 12),
                  _buildUserDetailRow(
                    Icons.badge_outlined,
                    'ID Empleado',
                    _userData['employeeId'],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.mediumGray,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.mediumGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Consumer3<EquipmentProvider, CustomerProvider, MaintenanceProvider>(
      builder: (context, equipmentProvider, customerProvider, maintenanceProvider, child) {
        final totalEquipment = equipmentProvider.equipment.length;
        final activeRentals = equipmentProvider.equipment.where((e) => e.status == EquipmentStatus.rented).length;
        final totalCustomers = customerProvider.customers.length;
        final pendingTasks = maintenanceProvider.tasks.where((t) => t.status != TaskStatus.completed).length;
        
        return AnimationConfiguration.synchronized(
          duration: Duration(milliseconds: widget.reduceMotion ? 300 : 700),
          child: SlideAnimation(
            verticalOffset: widget.reduceMotion ? 20 : 50,
            child: FadeInAnimation(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'Estadísticas Rápidas',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Equipos',
                          totalEquipment.toString(),
                          Icons.inventory_2_rounded,
                          AppTheme.primaryRed,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Alquileres',
                          activeRentals.toString(),
                          Icons.assignment_turned_in_rounded,
                          AppTheme.successGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Clientes',
                          totalCustomers.toString(),
                          Icons.people_rounded,
                          AppTheme.primaryRed.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Tareas',
                          pendingTasks.toString(),
                          Icons.build_rounded,
                          AppTheme.warningAmber,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
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
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.mediumGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return AnimationConfiguration.synchronized(
      duration: Duration(milliseconds: widget.reduceMotion ? 300 : 750),
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
                    'Accesos Rápidos',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildActionTile(
                    Icons.analytics_rounded,
                    'Ver Rentabilidad',
                    'Analiza ingresos y ganancias',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfitabilityScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 24),
                  _buildActionTile(
                    Icons.backup_rounded,
                    'Respaldar Datos',
                    'Guarda una copia de seguridad',
                    _showBackupDialog,
                  ),
                  const Divider(height: 24),
                  _buildActionTile(
                    Icons.help_outline_rounded,
                    'Ayuda y Soporte',
                    'Obtén ayuda o reporta problemas',
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Contacto: soporte@csrentalsrd.com'),
                          backgroundColor: AppTheme.primaryRed,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primaryRed, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.mediumGray,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.mediumGray),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
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
                    'Preferencias',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingItem(
                    Icons.notifications_outlined,
                    'Notificaciones',
                    'Recibir notificaciones push',
                    Switch(
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                        _saveSetting('notifications_enabled', value);
                      },
                      activeColor: AppTheme.primaryRed,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Recibirás notificaciones sobre:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.mediumGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildNotificationInfo(Icons.warning_rounded, 'Tareas vencidas'),
                  const SizedBox(height: 4),
                  _buildNotificationInfo(Icons.access_time_rounded, 'Alquileres próximos a vencer'),
                  const SizedBox(height: 4),
                  _buildNotificationInfo(Icons.calendar_today_rounded, 'Recordatorios importantes'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    IconData icon,
    String title,
    String subtitle,
    Widget trailing,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.lightGray,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryRed,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mediumGray,
                ),
              ),
            ],
          ),
        ),
        trailing,
      ],
    );
  }

  Widget _buildNotificationInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.mediumGray),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.mediumGray,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
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
                    'Cuenta',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildActionItem(
                    Icons.security_rounded,
                    'Cambiar Contraseña',
                    'Actualizar contraseña de tu cuenta',
                    () => _showChangePasswordDialog(),
                  ),
                  const SizedBox(height: 16),
                  _buildActionItem(
                    Icons.backup_rounded,
                    'Respaldar Datos',
                    'Exportar datos para respaldo',
                    () => _showBackupDialog(),
                  ),
                  const SizedBox(height: 16),
                  _buildActionItem(
                    Icons.logout_rounded,
                    'Cerrar Sesión',
                    'Cerrar sesión de tu cuenta',
                    () => _showSignOutDialog(),
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppTheme.errorRed : AppTheme.primaryRed;
    
    return GestureDetector(
      onTap: onTap,
      child: Row(
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDestructive ? AppTheme.errorRed : null,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mediumGray,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: AppTheme.mediumGray,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return AnimationConfiguration.synchronized(
      duration: Duration(
        milliseconds: widget.reduceMotion ? 300 : 1000,
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
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.business_rounded,
                          color: AppTheme.primaryRed,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'C&S Rentals SRL',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryRed,
                              ),
                            ),
                            Text(
                              'Sistema de Gestión de Alquileres',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.mediumGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  _buildInfoRow('Versión', '1.0.0'),
                  const SizedBox(height: 12),
                  _buildInfoRow('Build', '100'),
                  const SizedBox(height: 12),
                  _buildInfoRow('Entorno', 'Producción'),
                  const SizedBox(height: 12),
                  _buildInfoRow('Base de Datos', 'Supabase Cloud'),
                  const Divider(height: 32),
                  Text(
                    'Información de Contacto',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildContactRow(Icons.email_outlined, 'info@csrentalsrd.com'),
                  const SizedBox(height: 8),
                  _buildContactRow(Icons.phone_outlined, '+1 (809) 456-7890'),
                  const SizedBox(height: 8),
                  _buildContactRow(Icons.language_rounded, 'www.csrentalsrd.com'),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showPrivacyPolicy(),
                          icon: const Icon(Icons.privacy_tip_outlined, size: 18),
                          label: const Text('Privacidad'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryRed,
                            side: const BorderSide(color: AppTheme.primaryRed),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showTermsOfService(),
                          icon: const Icon(Icons.description_outlined, size: 18),
                          label: const Text('Términos'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryRed,
                            side: const BorderSide(color: AppTheme.primaryRed),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '© 2025 C&S Rentals SRL. Todos los derechos reservados.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.mediumGray,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Desarrollado por Ronald Familia',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.mediumGray,
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
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

  Widget _buildContactRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.mediumGray),
        const SizedBox(width: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.mediumGray,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.mediumGray,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _userData['name']);
    final emailController = TextEditingController(text: _userData['email']);
    final phoneController = TextEditingController(text: _userData['phone']);
    final branchController = TextEditingController(text: _userData['branch']);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: ResponsiveHelper.getDialogWidth(context),
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: AlertDialog(
            title: Row(
              children: [
                Icon(Icons.edit_rounded, color: AppTheme.primaryRed),
                const SizedBox(width: 12),
                const Text('Editar Perfil'),
              ],
            ),
            content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingrese su nombre';
                    }
                    if (value.trim().length < 3) {
                      return 'El nombre debe tener al menos 3 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingrese su correo';
                    }
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Ingrese un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingrese su teléfono';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: branchController,
                  decoration: const InputDecoration(
                    labelText: 'Sucursal',
                    prefixIcon: Icon(Icons.business_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingrese su sucursal';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              nameController.dispose();
              emailController.dispose();
              phoneController.dispose();
              branchController.dispose();
              Navigator.of(context).pop();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                // Guardar los datos
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('user_name', nameController.text.trim());
                await prefs.setString('user_email', emailController.text.trim());
                await prefs.setString('user_phone', phoneController.text.trim());
                await prefs.setString('user_branch', branchController.text.trim());

                // Actualizar el estado
                setState(() {
                  _userData['name'] = nameController.text.trim();
                  _userData['email'] = emailController.text.trim();
                  _userData['phone'] = phoneController.text.trim();
                  _userData['branch'] = branchController.text.trim();
                });

                // Limpiar controladores
                nameController.dispose();
                emailController.dispose();
                phoneController.dispose();
                branchController.dispose();

                // Cerrar el diálogo
                Navigator.of(context).pop();

                // Mostrar mensaje de éxito
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Perfil actualizado exitosamente'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Contraseña'),
        content: const Text('La funcionalidad para cambiar contraseña se implementará aquí.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Respaldar Datos'),
        content: const Text('La funcionalidad de respaldo de datos se implementará aquí.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement sign out functionality
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Política de Privacidad'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Última actualización: 23 de diciembre de 2025\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                '1. INFORMACIÓN GENERAL\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'C&S Rentals SRL, en cumplimiento con la Ley No. 172-13 de Protección de Datos Personales de la República Dominicana, se compromete a proteger la privacidad y seguridad de los datos personales de sus clientes y usuarios.\n',
              ),
              const Text(
                '2. DATOS RECOPILADOS\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Recopilamos los siguientes datos:\n'
                '• Nombre completo y cédula de identidad\n'
                '• Dirección de correo electrónico y teléfono\n'
                '• Dirección física\n'
                '• Información de equipos alquilados\n'
                '• Historial de transacciones\n',
              ),
              const Text(
                '3. USO DE LA INFORMACIÓN\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Los datos personales se utilizan exclusivamente para:\n'
                '• Gestión de contratos de alquiler\n'
                '• Facturación y cobros\n'
                '• Comunicación con clientes\n'
                '• Cumplimiento de obligaciones legales\n',
              ),
              const Text(
                '4. PROTECCIÓN DE DATOS\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Implementamos medidas técnicas y organizativas para proteger sus datos contra acceso no autorizado, pérdida o alteración, conforme a la Ley 172-13.\n',
              ),
              const Text(
                '5. DERECHOS DEL TITULAR\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Según la Ley 172-13, usted tiene derecho a:\n'
                '• Acceder a sus datos personales\n'
                '• Rectificar datos inexactos\n'
                '• Cancelar sus datos\n'
                '• Oponerse al tratamiento\n',
              ),
              const Text(
                '6. CONTACTO\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Para ejercer sus derechos o consultas:\n'
                'Email: info@csrentalsrd.com\n'
                'Teléfono: +1 (809) 456-7890\n',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Términos de Servicio'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Última actualización: 23 de diciembre de 2025\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                '1. ACEPTACIÓN DE TÉRMINOS\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Al utilizar este sistema, usted acepta estos términos y condiciones en su totalidad, regulados por las leyes de la República Dominicana.\n',
              ),
              const Text(
                '2. SERVICIOS\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'C&S Rentals SRL ofrece servicios de alquiler de equipos y maquinaria, sujeto a disponibilidad y condiciones específicas de cada contrato.\n',
              ),
              const Text(
                '3. RESPONSABILIDADES DEL CLIENTE\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                '• Proporcionar información veraz y actualizada\n'
                '• Usar los equipos conforme a su propósito\n'
                '• Devolver equipos en buen estado\n'
                '• Cumplir con pagos y plazos acordados\n'
                '• Notificar daños o problemas inmediatamente\n',
              ),
              const Text(
                '4. RESPONSABILIDADES DE C&S RENTALS\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                '• Entregar equipos en buen estado\n'
                '• Proporcionar mantenimiento preventivo\n'
                '• Brindar soporte técnico\n'
                '• Mantener confidencialidad de datos\n',
              ),
              const Text(
                '5. PAGOS Y FACTURACIÓN\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Los pagos se rigen por el Código Civil Dominicano y Ley de Comercio. Precios sujetos a ITBIS según Ley 11-92 del Código Tributario.\n',
              ),
              const Text(
                '6. GARANTÍAS Y LIMITACIONES\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Los equipos se alquilan "tal cual". C&S Rentals no se responsabiliza por daños indirectos o pérdidas de producción, conforme al Código Civil Dominicano.\n',
              ),
              const Text(
                '7. RESOLUCIÓN DE CONFLICTOS\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Cualquier disputa se resolverá mediante arbitraje o tribunales competentes de la República Dominicana, según la Ley 489-08 de Arbitraje Comercial.\n',
              ),
              const Text(
                '8. MODIFICACIONES\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'C&S Rentals se reserva el derecho de modificar estos términos, notificando a los usuarios con 30 días de anticipación.\n',
              ),
              const Text(
                '9. LEY APLICABLE\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Estos términos se rigen por las leyes de la República Dominicana, incluyendo:\n'
                '• Ley No. 172-13 (Protección de Datos)\n'
                '• Ley No. 489-08 (Arbitraje Comercial)\n'
                '• Código Civil Dominicano\n'
                '• Código Tributario (Ley 11-92)\n',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
