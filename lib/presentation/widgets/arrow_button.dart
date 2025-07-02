import 'dart:math' as math;

import 'package:flutter/material.dart';

class ArrowButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool enabled;
  final double height;
  final double width;
  final bool reverse;

  const ArrowButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.enabled = true,
    this.height = 52,
    this.width = 140,
    this.reverse = false,
  });

  factory ArrowButton.next({
    Key? key,
    String? label,
    VoidCallback? onPressed,
    bool enabled = true,
  }) =>
      ArrowButton(
        key: key,
        label: label ?? 'Next',
        icon: Icons.arrow_forward_rounded,
        onPressed: onPressed,
        enabled: enabled,
        reverse: false,
      );

  factory ArrowButton.previous({
    Key? key,
    String? label,
    VoidCallback? onPressed,
    bool enabled = true,
  }) =>
      ArrowButton(
        key: key,
        label: label ?? 'Previous',
        icon: Icons.arrow_back_rounded,
        onPressed: onPressed,
        enabled: enabled,
        reverse: true,
      );

  @override
  State<ArrowButton> createState() => _ArrowButtonState();
}

class _ArrowButtonState extends State<ArrowButton>
    with TickerProviderStateMixin {
  bool _hovering = false;
  bool _pressed = false;

  late final AnimationController _shineCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _shineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double scale = _pressed ? 0.95 : (_hovering ? 1.03 : 1.0);

    final activeGrad = LinearGradient(
      colors: widget.reverse
          ? [const Color(0xFF8E99F3), const Color(0xFF536DFE)]
          : [const Color(0xFF43CEA2), const Color(0xFF185A9D)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    const disabledGrad = LinearGradient(
      colors: [Color(0xFFE0E0E0), Color(0xFFBDBDBD)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: scale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background
              Container(
                height: widget.height,
                width: widget.width,
                decoration: BoxDecoration(
                  gradient: widget.enabled ? activeGrad : disabledGrad,
                  borderRadius: BorderRadius.circular(widget.height / 2),
                  boxShadow: widget.enabled
                      ? [
                          const BoxShadow(
                            color: Colors.black38,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          )
                        ]
                      : [],
                ),
              ),
              // Shine animation
              if (widget.enabled)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _shineCtrl,
                    builder: (_, __) {
                      final double slide = _shineCtrl.value * 2 - 1;
                      return Transform.rotate(
                        angle: -math.pi / 4,
                        child: FractionalTranslation(
                          translation: Offset(slide, 0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.0),
                                  Colors.white.withOpacity(0.25),
                                  Colors.white.withOpacity(0.0),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              // Content
              Row(
                mainAxisSize: MainAxisSize.min,
                children: widget.reverse
                    ? [
                        Icon(widget.icon, color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          widget.label,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.6,
                                  ),
                        ),
                      ]
                    : [
                        Text(
                          widget.label,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.6,
                                  ),
                        ),
                        const SizedBox(width: 8),
                        Icon(widget.icon, color: Colors.white, size: 22),
                      ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
