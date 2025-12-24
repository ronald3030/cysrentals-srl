import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';
import '../models/equipment.dart';

class EquipmentCard extends StatefulWidget {
  final Equipment equipment;
  final bool isGridView;
  final VoidCallback onTap;
  final bool reduceMotion;

  const EquipmentCard({
    super.key,
    required this.equipment,
    required this.isGridView,
    required this.onTap,
    required this.reduceMotion,
  });

  @override
  State<EquipmentCard> createState() => _EquipmentCardState();
}

class _EquipmentCardState extends State<EquipmentCard>
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
    switch (widget.equipment.status) {
      case EquipmentStatus.available:
        return AppTheme.successGreen;
      case EquipmentStatus.rented:
        return AppTheme.primaryRed;
      case EquipmentStatus.maintenance:
        return AppTheme.warningAmber;
      case EquipmentStatus.outOfService:
        return AppTheme.darkGray;
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
              margin: const EdgeInsets.all(2),
              child: widget.isGridView ? _buildGridCard() : _buildListCard(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: _buildImageSection(),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.equipment.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.equipment.id,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mediumGray,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                _buildStatusChip(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListCard() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppTheme.lightGray,
            ),
            child: _buildPlaceholderImage(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.equipment.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.equipment.id,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mediumGray,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatusChip(),
                    const SizedBox(width: 8),
                    Text(
                      widget.equipment.category,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mediumGray,
                      ),
                    ),
                  ],
                ),
                if (widget.equipment.customer != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 14,
                        color: AppTheme.mediumGray,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.equipment.customer!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.mediumGray,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
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

  Widget _buildImageSection() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        color: AppTheme.lightGray,
      ),
      child: Stack(
        children: [
          _buildPlaceholderImage(),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryWhite.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.equipment.category,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return ClipRRect(
      borderRadius: widget.isGridView
          ? const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            )
          : BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppTheme.lightGray,
        child: Icon(
          _getCategoryIcon(),
          size: widget.isGridView ? 48 : 32,
          color: AppTheme.mediumGray,
        ),
      ),
    );
  }

  IconData _getCategoryIcon() {
    // Iconos específicos por nombre de equipo
    final equipmentName = widget.equipment.name.toLowerCase();
    
    if (equipmentName.contains('excavadora')) {
      return Icons.agriculture_rounded; // Icono de excavadora
    } else if (equipmentName.contains('mezcladora') || equipmentName.contains('concreto')) {
      return Icons.engineering_rounded; // Icono de mezcladora
    } else if (equipmentName.contains('motosierra')) {
      return Icons.carpenter_rounded; // Icono de herramienta de corte
    } else if (equipmentName.contains('taladro')) {
      return Icons.handyman_rounded; // Icono de taladro
    } else if (equipmentName.contains('arnés') || equipmentName.contains('seguridad')) {
      return Icons.verified_user_rounded; // Icono de seguridad
    }
    
    // Fallback a categoría
    switch (widget.equipment.category.toLowerCase()) {
      case 'construcción':
        return Icons.construction_rounded;
      case 'jardinería':
        return Icons.park_rounded;
      case 'herramientas eléctricas':
        return Icons.build_rounded;
      case 'maquinaria pesada':
        return Icons.precision_manufacturing_rounded;
      case 'equipo de seguridad':
        return Icons.security_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        widget.equipment.status.displayName,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: _statusColor,
          fontWeight: FontWeight.w600,
          fontSize: 9,
        ),
      ),
    );
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
