import 'package:flutter/material.dart';
import 'dart:math' as math;

class InteractiveButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isSuccess;
  final bool isError;
  final bool isPrimary;
  final Color? color;

  const InteractiveButton({
    super.key,
    required this.child,
    required this.onTap,
    this.isSuccess = false,
    this.isError = false,
    this.isPrimary = false,
    this.color,
  });

  @override
  State<InteractiveButton> createState() => _InteractiveButtonState();
}

class _InteractiveButtonState extends State<InteractiveButton>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _feedbackController;
  late AnimationController _hoverController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _liftAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _feedbackController, curve: Curves.linear),
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _feedbackController, curve: Curves.easeOut),
    );

    _liftAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(InteractiveButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.isSuccess && !oldWidget.isSuccess) ||
        (widget.isError && !oldWidget.isError)) {
      _feedbackController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _feedbackController.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        _hoverController.forward();
      },
      onExit: (_) {
        _hoverController.reverse();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge(
            [_pressController, _feedbackController, _hoverController]),
        builder: (context, child) {
          double shakeOffset = 0;
          if (widget.isError) {
            shakeOffset = math.sin(_shakeAnimation.value * math.pi * 4) * 8;
          }

          // Lift on hover, sink on press
          final liftValue = _liftAnimation.value * 4.0;
          final pressValue = _pressController.value * 4.0;
          final totalOffset = -liftValue + pressValue;

          return Transform.translate(
            offset: Offset(shakeOffset, totalOffset),
            child: Transform.scale(
              scale: _scaleAnimation.value + (_liftAnimation.value * 0.02),
              child: GestureDetector(
                onTapDown: widget.onTap != null ? (_) => _pressController.forward() : null,
                onTapUp: widget.onTap != null ? (_) {
                  _pressController.reverse();
                  widget.onTap?.call();
                } : null,
                onTapCancel: widget.onTap != null ? () => _pressController.reverse() : null,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    if (widget.isSuccess)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFC0FF00).withValues(
                                  alpha: 1.0 - _pulseAnimation.value),
                              width: 2 + (_pulseAnimation.value * 12),
                            ),
                          ),
                        ),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                                alpha: 0.1 +
                                    (_liftAnimation.value * 0.05) -
                                    (_pressController.value * 0.05)),
                            blurRadius: 12 +
                                (widget.isPrimary ? 8 : 0) +
                                (_liftAnimation.value * 8) -
                                (_pressController.value * 8),
                            offset: Offset(
                                0,
                                6 +
                                    (_liftAnimation.value * 4) -
                                    (_pressController.value * 4)),
                            spreadRadius: widget.isPrimary ? 1 : 0,
                          ),
                        ],
                      ),
                      child: widget.child,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
