import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';

class QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool reduceMotion;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.reduceMotion,
  });

  @override
  State<QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<QuickActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(
        milliseconds: widget.reduceMotion ? 100 : 200,
      ),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: 2.0,
      end: 8.0,
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
            child: Card(
              elevation: _elevationAnimation.value,
              shadowColor: AppTheme.primaryRed.withOpacity(0.2),
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveHelper.getResponsiveValue(
                    context: context,
                    mobile: 20.0,
                    tablet: 16.0,
                    desktop: 14.0,
                  ),
                  horizontal: ResponsiveHelper.getResponsiveValue(
                    context: context,
                    mobile: 12.0,
                    tablet: 10.0,
                    desktop: 8.0,
                  ),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryWhite,
                      AppTheme.primaryRed.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(
                        ResponsiveHelper.getResponsiveValue(
                          context: context,
                          mobile: 12.0,
                          tablet: 10.0,
                          desktop: 8.0,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.icon,
                        color: AppTheme.primaryRed,
                        size: ResponsiveHelper.getIconSize(context, 24),
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveValue(
                      context: context,
                      mobile: 12.0,
                      tablet: 10.0,
                      desktop: 8.0,
                    )),
                    Text(
                      widget.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlack,
                        fontSize: ResponsiveHelper.getFontSize(context, 14),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onTapDown() {
    if (!widget.reduceMotion) {
      _controller.forward();
    }
  }

  void _onTapUp() {
    widget.onTap();
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
