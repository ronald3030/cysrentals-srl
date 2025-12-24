import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';
import '../models/customer.dart';

class CustomerCard extends StatefulWidget {
  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback onAddressUpdate;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool reduceMotion;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.onTap,
    required this.onAddressUpdate,
    this.onEdit,
    this.onDelete,
    required this.reduceMotion,
  });

  @override
  State<CustomerCard> createState() => _CustomerCardState();
}

class _CustomerCardState extends State<CustomerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(
        milliseconds: widget.reduceMotion ? 100 : 150,
      ),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: 2.0,
      end: 6.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _statusColor {
    switch (widget.customer.status) {
      case CustomerStatus.active:
        return AppTheme.successGreen;
      case CustomerStatus.inactive:
        return AppTheme.mediumGray;
      case CustomerStatus.suspended:
        return AppTheme.errorRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _onTapDown(),
            onTapUp: (_) => _onTapUp(),
            onTapCancel: () => _onTapCancel(),
            onTap: widget.onTap,
            child: Card(
              elevation: _elevationAnimation.value,
              shadowColor: _statusColor.withOpacity(0.2),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 12),
                    _buildContactInfo(),
                    const SizedBox(height: 12),
                    _buildStatsRow(),
                    const SizedBox(height: 12),
                    _buildActionRow(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.business_rounded,
            color: _statusColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.customer.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                widget.customer.id,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mediumGray,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _statusColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            widget.customer.status.displayName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo() {
    return Column(
      children: [
        Row(
          children: [
            const Icon(
              Icons.phone_outlined,
              size: 16,
              color: AppTheme.mediumGray,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.customer.phone,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkGray,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 16,
              color: AppTheme.mediumGray,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.customer.address,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkGray,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildStatItem(
            'Equipos',
            widget.customer.assignedEquipmentCount.toString(),
            Icons.inventory_2_outlined,
          ),
          const Spacer(),
          _buildStatItem(
            'Total Alquileres',
            widget.customer.totalRentals.toString(),
            Icons.history_rounded,
          ),
          const Spacer(),
          _buildStatItem(
            'Last Rental',
            _formatLastRental(),
            Icons.schedule_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.primaryRed,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryBlack,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.mediumGray,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.onAddressUpdate,
            icon: const Icon(
              Icons.location_on_rounded,
              size: 16,
            ),
            label: const Text('Actualizar Dirección'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryRed,
              side: const BorderSide(color: AppTheme.primaryRed),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.lightGray,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: () async {
              final Uri telUri = Uri(scheme: 'tel', path: widget.customer.phone);
              if (await canLaunchUrl(telUri)) {
                await launchUrl(telUri);
              }
            },
            icon: const Icon(
              Icons.phone_rounded,
              color: AppTheme.successGreen,
              size: 20,
            ),
            tooltip: 'Llamar Cliente',
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.lightGray,
            borderRadius: BorderRadius.circular(8),
          ),
          child: PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppTheme.mediumGray,
              size: 20,
            ),
            tooltip: 'Más opciones',
            onSelected: (value) {
              if (value == 'edit' && widget.onEdit != null) {
                widget.onEdit!();
              } else if (value == 'delete' && widget.onDelete != null) {
                widget.onDelete!();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: AppTheme.primaryRed),
                    SizedBox(width: 8),
                    Text('Eliminar', style: TextStyle(color: AppTheme.primaryRed)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatLastRental() {
    final now = DateTime.now();
    final difference = now.difference(widget.customer.lastRentalDate).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return '1d ago';
    } else if (difference < 7) {
      return '${difference}d ago';
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return '${weeks}w ago';
    } else {
      final months = (difference / 30).floor();
      return '${months}m ago';
    }
  }

  void _onTapDown() {
    if (!widget.reduceMotion) {
      _controller.forward();
    }
  }

  void _onTapUp() {
    if (!widget.reduceMotion) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (!widget.reduceMotion) {
      _controller.reverse();
    }
  }
}
