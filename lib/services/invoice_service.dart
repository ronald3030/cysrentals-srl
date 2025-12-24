import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../models/equipment.dart';

class InvoiceService {
  static final InvoiceService _instance = InvoiceService._internal();
  factory InvoiceService() => _instance;
  InvoiceService._internal();

  // Colores de la marca (en formato PDF)
  static final primaryRed = PdfColor.fromHex('#D32F2F');
  static final primaryBlack = PdfColor.fromHex('#000000');
  static final lightGray = PdfColor.fromHex('#F5F5F5');
  static final mediumGray = PdfColor.fromHex('#9E9E9E');
  static final white = PdfColor.fromHex('#FFFFFF');

  Future<Uint8List> generateInvoicePdf({
    required Customer customer,
    required Equipment equipment,
    required DateTime startDate,
    required DateTime endDate,
    required double dailyRate,
    required double totalAmount,
    String? notes,
    String invoiceNumber = '',
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy', 'es');
    final currencyFormat = NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$');
    final days = endDate.difference(startDate).inDays + 1;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado
              _buildHeader(invoiceNumber),
              pw.SizedBox(height: 30),
              // Cliente
              _buildCustomerInfo(customer),
              pw.SizedBox(height: 30),
              // Detalles
              _buildRentalDetails(
                equipment: equipment,
                startDate: startDate,
                endDate: endDate,
                days: days,
                dailyRate: dailyRate,
                dateFormat: dateFormat,
                currencyFormat: currencyFormat,
              ),
              pw.SizedBox(height: 30),
              // Total
              _buildTotalSection(totalAmount, currencyFormat),
              pw.SizedBox(height: 20),
              // Notas
              if (notes != null && notes.isNotEmpty) ...[
                _buildNotes(notes),
                pw.SizedBox(height: 20),
              ],
              pw.Spacer(),
              // Footer
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(String invoiceNumber) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: lightGray,
        border: pw.Border.all(color: primaryRed, width: 2),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'C&S RENTALS SRL',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryRed,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('RNC: 132141882', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 4),
              pw.Text('Tel: +1 (829) 640-3732', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Email: info@csrentalssrl.com', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Web: www.csrentalssrl.com', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 4),
              pw.Text('Santiago, República Dominicana', style: pw.TextStyle(fontSize: 10, color: mediumGray)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: primaryRed,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  'FACTURA',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: white,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'No. ${invoiceNumber.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString().substring(7) : invoiceNumber}',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 10, color: mediumGray),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCustomerInfo(Customer customer) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: mediumGray),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CLIENTE',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: primaryRed,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            customer.name,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          if (customer.phone.isNotEmpty)
            pw.Text('Tel: ${customer.phone}', style: const pw.TextStyle(fontSize: 10)),
          if (customer.email != null && customer.email!.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text('Email: ${customer.email}', style: const pw.TextStyle(fontSize: 10)),
          ],
          if (customer.address.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text('Dirección: ${customer.address}', style: pw.TextStyle(fontSize: 10, color: mediumGray)),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildRentalDetails({
    required Equipment equipment,
    required DateTime startDate,
    required DateTime endDate,
    required int days,
    required double dailyRate,
    required DateFormat dateFormat,
    required NumberFormat currencyFormat,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: mediumGray),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: primaryRed,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(7),
                topRight: pw.Radius.circular(7),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    'DESCRIPCIÓN',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: white,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    'DÍAS',
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: white),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    'TARIFA',
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: white),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: white),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Alquiler de Equipo', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text(equipment.name, style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 2),
                      pw.Text('Categoría: ${equipment.category}', style: pw.TextStyle(fontSize: 9, color: mediumGray)),
                      pw.SizedBox(height: 6),
                      pw.Text('Período: ${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(days.toString(), style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.center),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(currencyFormat.format(dailyRate), style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.right),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(currencyFormat.format(dailyRate * days), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTotalSection(double totalAmount, NumberFormat currencyFormat) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: lightGray,
        border: pw.Border.all(color: primaryRed, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text('TOTAL A PAGAR: ', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(width: 10),
          pw.Text(
            currencyFormat.format(totalAmount),
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: primaryRed),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildNotes(String notes) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: lightGray,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('NOTAS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryRed)),
          pw.SizedBox(height: 6),
          pw.Text(notes, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(color: mediumGray, thickness: 1),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('TÉRMINOS Y CONDICIONES', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryRed)),
                pw.SizedBox(height: 4),
                pw.Text('• El equipo debe ser devuelto en las mismas condiciones', style: pw.TextStyle(fontSize: 7, color: mediumGray)),
                pw.Text('• Cualquier daño será cobrado al cliente', style: pw.TextStyle(fontSize: 7, color: mediumGray)),
                pw.Text('• Pagos sujetos a términos del contrato', style: pw.TextStyle(fontSize: 7, color: mediumGray)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Desarrollado por Ronald Familia', style: pw.TextStyle(fontSize: 7, color: mediumGray)),
                pw.SizedBox(height: 2),
                pw.Text('C&S Rentals SRL © ${DateTime.now().year}', style: pw.TextStyle(fontSize: 7, color: mediumGray)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Future<void> shareInvoice({
    required Customer customer,
    required Equipment equipment,
    required DateTime startDate,
    required DateTime endDate,
    required double dailyRate,
    required double totalAmount,
    String? notes,
    String invoiceNumber = '',
  }) async {
    final pdfBytes = await generateInvoicePdf(
      customer: customer,
      equipment: equipment,
      startDate: startDate,
      endDate: endDate,
      dailyRate: dailyRate,
      totalAmount: totalAmount,
      notes: notes,
      invoiceNumber: invoiceNumber,
    );

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'factura_${invoiceNumber.isEmpty ? DateTime.now().millisecondsSinceEpoch : invoiceNumber}.pdf',
    );
  }

  Future<void> printInvoice({
    required Customer customer,
    required Equipment equipment,
    required DateTime startDate,
    required DateTime endDate,
    required double dailyRate,
    required double totalAmount,
    String? notes,
    String invoiceNumber = '',
  }) async {
    await Printing.layoutPdf(
      onLayout: (format) async => generateInvoicePdf(
        customer: customer,
        equipment: equipment,
        startDate: startDate,
        endDate: endDate,
        dailyRate: dailyRate,
        totalAmount: totalAmount,
        notes: notes,
        invoiceNumber: invoiceNumber,
      ),
    );
  }
}
