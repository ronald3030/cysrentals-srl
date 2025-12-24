import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'providers/equipment_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/maintenance_provider.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'models/customer.dart';
import 'models/equipment.dart';
import 'models/maintenance_task.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar locale para fechas en español
  await initializeDateFormatting('es', null);
  
  // Configuración de Supabase
  String supabaseUrl = 'https://ahhhsqswcgtzdgsolybq.supabase.co';
  String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFoaGhzcXN3Y2d0emRnc29seWJxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY1Mjg1NTgsImV4cCI6MjA4MjEwNDU1OH0.pHq_9te5hzUTiL-SEM3sPQPcVjrQKEEYMsRgpnZ33pY';
  
  // Intentar cargar variables de entorno si existe el archivo (para desarrollo local)
  try {
    await dotenv.load(fileName: '.env');
    supabaseUrl = dotenv.env['SUPABASE_URL'] ?? supabaseUrl;
    supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? supabaseAnonKey;
  } catch (e) {
    // Si no existe .env (como en web), usar valores por defecto
    print('Using default Supabase configuration');
  }
  
  // Inicializar Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  
  // Inicializar Storage bucket
  try {
    await StorageService.initializeBucket();
  } catch (e) {
    print('Error inicializando storage bucket: $e');
  }
  
  // Inicializar Hive (caché offline)
  await Hive.initFlutter();
  
  // Registrar adapters de Hive
  Hive.registerAdapter(CustomerStatusAdapter());
  Hive.registerAdapter(CustomerAdapter());
  Hive.registerAdapter(EquipmentStatusAdapter());
  Hive.registerAdapter(EquipmentAdapter());
  Hive.registerAdapter(MaintenanceRecordAdapter());
  Hive.registerAdapter(MaintenanceTypeAdapter());
  Hive.registerAdapter(TaskPriorityAdapter());
  Hive.registerAdapter(TaskStatusAdapter());
  Hive.registerAdapter(MaintenanceTaskAdapter());
  
  runApp(const CysRentalsApp());
}

class CysRentalsApp extends StatefulWidget {
  const CysRentalsApp({super.key});

  @override
  State<CysRentalsApp> createState() => _CysRentalsAppState();
}

class _CysRentalsAppState extends State<CysRentalsApp> {
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initializeNotifications();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _reduceMotion = prefs.getBool('reduce_motion') ?? false;
    });
  }

  void _initializeNotifications() {
    final notificationService = NotificationService();
    
    // Agregar listener para mostrar SnackBars
    notificationService.addListener((title, message) {
      // Obtener el contexto del router para mostrar notificaciones
      final context = AppRouter.router.routerDelegate.navigatorKey.currentContext;
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(message),
              ],
            ),
            backgroundColor: title.contains('⚠️') || title.contains('⛔') || title.contains('🚨')
                ? AppTheme.errorRed
                : AppTheme.warningAmber,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: AppTheme.primaryWhite,
              onPressed: () {},
            ),
          ),
        );
      }
    });
    
    // Iniciar monitoreo
    notificationService.startMonitoring();
  }

  @override
  void dispose() {
    NotificationService().stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EquipmentProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => MaintenanceProvider()),
      ],
      child: MaterialApp.router(
        title: 'C&S Rentals SRL',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}