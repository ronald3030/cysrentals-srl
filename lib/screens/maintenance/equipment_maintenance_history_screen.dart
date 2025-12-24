import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/equipment.dart';

class EquipmentMaintenanceHistoryScreen extends StatelessWidget {
  final Equipment equipment;

  const EquipmentMaintenanceHistoryScreen({
    super.key,
    required this.equipment,
  });

  @override
  Widget build(BuildContext context) {
    final history = equipment.maintenanceHistory ?? [];
    final total = history.fold<double>(0, (s, r) => s + (r.cost ?? 0));
    final avg = history.isNotEmpty ? total / history.length : 0.0;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHeaderCard(context),
                const SizedBox(height: 12),
                _buildSummaryRow(context, history.length, total, avg),
                const SizedBox(height: 16),
              ]),
            ),
          ),
          if (history.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'Sin registros de mantenimiento',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildRecordCard(context, history[index]),
                  childCount: history.length,
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
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
                equipment.name,
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
                  equipment.name,
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

  Widget _buildHeaderCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.history_rounded, color: AppTheme.primaryRed),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historial de Mantenimiento',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'ID: ${equipment.id}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, int count, double total, double avg) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: _buildSummaryItem(context, 'Registros', '$count', Icons.list_alt_rounded, AppTheme.primaryRed)),
            const SizedBox(width: 12),
            Expanded(child: _buildSummaryItem(context, 'Costo Total', 'RD\$${total.toStringAsFixed(0)}', Icons.attach_money_rounded, AppTheme.warningAmber)),
            const SizedBox(width: 12),
            Expanded(child: _buildSummaryItem(context, 'Promedio', 'RD\$${avg.toStringAsFixed(0)}', Icons.analytics_rounded, AppTheme.successGreen)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray)),
      ],
    );
  }

  Widget _buildRecordCard(BuildContext context, MaintenanceRecord record) {
    Color typeColor;
    IconData typeIcon;
    switch (record.type) {
      case MaintenanceType.routine:
        typeColor = AppTheme.successGreen;
        typeIcon = Icons.schedule_rounded;
        break;
      case MaintenanceType.repair:
        typeColor = AppTheme.primaryRed;
        typeIcon = Icons.build_rounded;
        break;
      case MaintenanceType.inspection:
        typeColor = AppTheme.warningAmber;
        typeIcon = Icons.search_rounded;
        break;
      case MaintenanceType.upgrade:
        typeColor = Colors.blue;
        typeIcon = Icons.upgrade_rounded;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(typeIcon, color: typeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(record.type.displayName, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: typeColor, fontWeight: FontWeight.w600)),
                      Text('ID: ${record.id}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (record.cost != null)
                      Text('RD\$${record.cost!.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    Text(_formatDate(record.date), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(record.description, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_rounded, size: 16, color: AppTheme.mediumGray),
                const SizedBox(width: 6),
                Text(record.technician, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}


