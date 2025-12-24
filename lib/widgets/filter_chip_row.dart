import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FilterChipRow extends StatefulWidget {
  final List<String> options;
  final String selectedOption;
  final Function(String) onSelectionChanged;
  final bool reduceMotion;

  const FilterChipRow({
    super.key,
    required this.options,
    required this.selectedOption,
    required this.onSelectionChanged,
    required this.reduceMotion,
  });

  @override
  State<FilterChipRow> createState() => _FilterChipRowState();
}

class _FilterChipRowState extends State<FilterChipRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(
        milliseconds: widget.reduceMotion ? 150 : 200,
      ),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.options.length,
        itemBuilder: (context, index) {
          final option = widget.options[index];
          final isSelected = option == widget.selectedOption;
          
          return Padding(
            padding: EdgeInsets.only(
              right: index < widget.options.length - 1 ? 8 : 0,
            ),
            child: _FilterChip(
              label: option,
              isSelected: isSelected,
              onTap: () => widget.onSelectionChanged(option),
              reduceMotion: widget.reduceMotion,
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool reduceMotion;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.reduceMotion,
  });

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

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
      end: 0.96,
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
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: Duration(
                milliseconds: widget.reduceMotion ? 150 : 200,
              ),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? AppTheme.primaryRed
                    : AppTheme.lightGray,
                borderRadius: BorderRadius.circular(20),
                border: widget.isSelected
                    ? null
                    : Border.all(
                        color: AppTheme.mediumGray.withOpacity(0.3),
                        width: 1,
                      ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryRed.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: AnimatedDefaultTextStyle(
                duration: Duration(
                  milliseconds: widget.reduceMotion ? 150 : 200,
                ),
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: widget.isSelected
                      ? AppTheme.primaryWhite
                      : AppTheme.primaryBlack,
                  fontWeight: widget.isSelected
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
                child: Text(widget.label),
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
