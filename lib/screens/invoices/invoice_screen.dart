import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/responsive_helper.dart';
import '../../models/rental.dart';
import '../../models/customer.dart';
import '../../models/equipment.dart';
import '../../services/supabase_service.dart';
import '../../services/invoice_service.dart';
import '../../theme/app_theme.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  bool _isLoading = false;
  bool _isGenerating = false;
  List<Rental> _rentals = [];
  Rental? _selectedRental;
  Customer? _selectedCustomer;
  Equipment? _selectedEquipment;
  final _invoiceNumberController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRentals();
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadRentals() async {
    setState(() => _isLoading = true);
    try {
      final rentals = await SupabaseService.getRentals();
      setState(() {
        _rentals = rentals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar alquileres: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _loadCustomerAndEquipment(Rental rental) async {
    try {
      final customers = await SupabaseService.getCustomers();
      final equipment = await SupabaseService.getEquipment();
      
      setState(() {
        _selectedCustomer = customers.firstWhere(
          (c) => c.id == rental.customerId,
          orElse: () => Customer(
            id: rental.customerId,
            name: rental.customerName,
            phone: '',
            address: '',
            assignedEquipmentCount: 0,
            totalRentals: 0,
            lastRentalDate: DateTime.now(),
            status: CustomerStatus.active,
            email: '',
          ),
        );
        _selectedEquipment = equipment.firstWhere(
          (e) => e.id == rental.equipmentId,
          orElse: () => Equipment(
            id: rental.equipmentId,
            name: rental.equipmentName,
            category: '',
            status: EquipmentStatus.rented,
            description: '',
          ),
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar detalles: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _generateInvoice(bool share) async {
    if (_selectedRental == null || _selectedCustomer == null || _selectedEquipment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un alquiler primero'),
          backgroundColor: AppTheme.warningAmber,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final invoiceService = InvoiceService();
      
      if (share) {
        await invoiceService.shareInvoice(
          customer: _selectedCustomer!,
          equipment: _selectedEquipment!,
          startDate: _selectedRental!.startDate,
          endDate: _selectedRental!.endDate,
          dailyRate: _selectedRental!.dailyRate,
          totalAmount: _selectedRental!.totalCost,
          notes: _notesController.text.trim(),
          invoiceNumber: _invoiceNumberController.text.trim(),
        );
      } else {
        await invoiceService.printInvoice(
          customer: _selectedCustomer!,
          equipment: _selectedEquipment!,
          startDate: _selectedRental!.startDate,
          endDate: _selectedRental!.endDate,
          dailyRate: _selectedRental!.dailyRate,
          totalAmount: _selectedRental!.totalCost,
          notes: _notesController.text.trim(),
          invoiceNumber: _invoiceNumberController.text.trim(),
        );
      }

      setState(() => _isGenerating = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(share ? '✅ Factura compartida exitosamente' : '✅ Factura enviada a imprimir'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'es');
    final currencyFormat = NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generar Factura'),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: AppTheme.primaryWhite,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(
                ResponsiveHelper.getPadding(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(
                        ResponsiveHelper.getPadding(context),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seleccionar Alquiler',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryRed,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<Rental>(
                            value: _selectedRental,
                            decoration: InputDecoration(
                              labelText: 'Alquiler',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.receipt_long),
                            ),
                            items: _rentals.map((rental) {
                              return DropdownMenuItem(
                                value: rental,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      rental.equipmentName,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      '${rental.customerName} • ${dateFormat.format(rental.startDate)}',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.mediumGray),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (rental) {
                              setState(() => _selectedRental = rental);
                              if (rental != null) {
                                _loadCustomerAndEquipment(rental);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_selectedRental != null) ...[
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Detalles del Alquiler',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryRed,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow('Equipo', _selectedRental!.equipmentName),
                            _buildDetailRow('Cliente', _selectedRental!.customerName),
                            _buildDetailRow('Ubicación', _selectedRental!.location),
                            _buildDetailRow(
                              'Período',
                              '${dateFormat.format(_selectedRental!.startDate)} - ${dateFormat.format(_selectedRental!.endDate)}',
                            ),
                            _buildDetailRow(
                              'Días',
                              '${_selectedRental!.endDate.difference(_selectedRental!.startDate).inDays + 1}',
                            ),
                            _buildDetailRow(
                              'Tarifa Diaria',
                              currencyFormat.format(_selectedRental!.dailyRate),
                            ),
                            const Divider(height: 24),
                            _buildDetailRow(
                              'TOTAL',
                              currencyFormat.format(_selectedRental!.totalCost),
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Información Adicional',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryRed,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _invoiceNumberController,
                              decoration: InputDecoration(
                                labelText: 'Número de Factura (opcional)',
                                hintText: 'Se generará automáticamente',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.numbers),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _notesController,
                              decoration: InputDecoration(
                                labelText: 'Notas (opcional)',
                                hintText: 'Información adicional',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.note),
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _isGenerating ? null : () => _generateInvoice(false),
                              icon: const Icon(Icons.print),
                              label: const Text('Imprimir'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.darkGray,
                                foregroundColor: AppTheme.primaryWhite,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _isGenerating ? null : () => _generateInvoice(true),
                              icon: const Icon(Icons.share),
                              label: const Text('Compartir PDF'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryRed,
                                foregroundColor: AppTheme.primaryWhite,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveValue(
                      context: context,
                      mobile: 120.0,
                      tablet: 100.0,
                      desktop: 80.0,
                    )), // Padding adicional al final
                  ],

                  if (_rentals.isEmpty && !_isLoading) ...[
                    SizedBox(height: ResponsiveHelper.getResponsiveValue(
                      context: context,
                      mobile: 120.0,
                      tablet: 100.0,
                      desktop: 80.0,
                    )),
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_rounded,
                            size: 80,
                            color: AppTheme.mediumGray.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay alquileres disponibles',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.mediumGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? AppTheme.primaryBlack : AppTheme.darkGray,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? AppTheme.primaryRed : AppTheme.primaryBlack,
            ),
          ),
        ],
      ),
    );
  }
}
