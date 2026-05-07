import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../theme/app_colors.dart';

class CowWalkingLoader extends StatefulWidget {
  const CowWalkingLoader({
    super.key,
    this.size = 50,
    this.color = AppColors.primary,
    this.showLabel = true,
    this.label = 'Loading...',
    this.compact = false,
  });

  final double size;
  final Color color;
  final bool showLabel;
  final String label;
  final bool compact;

  @override
  State<CowWalkingLoader> createState() => _CowWalkingLoaderState();
}

class _CowWalkingLoaderState extends State<CowWalkingLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _walkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _walkAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackHeight = widget.compact ? 4.0 : 6.0;

final cowHeight =
    widget.compact ? widget.size * 0.55 : widget.size * 0.85;

final cowWidth = cowHeight * 1.8;
    final maxTravel = widget.compact ? widget.size * 0.9 : widget.size * 1.35;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.compact ? widget.size * 1.5 : widget.size * 2.2,
height: widget.compact ? widget.size * 0.8 : widget.size * 1.4,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final travel = width - cowWidth;
              final clampedTravel = travel > 0 ? travel : maxTravel;
              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Positioned(
                    bottom: widget.compact ? 6 : 10,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: trackHeight,
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _walkAnimation,
                    builder: (context, _) {
                      return Positioned(
                        left: clampedTravel * _walkAnimation.value,
                        bottom: widget.compact ? 5 : 8,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.rotationY(
                            _walkAnimation.value > 0.5 ? 0 : 3.1415926535,
                          ),
                          child: SizedBox(
                            width: cowWidth,
                            height: cowHeight,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(widget.compact ? 4 : 6),
                              child: Image.asset(
                                AppAssets.cowBar,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.low,
                                errorBuilder: (_, _, _) => Icon(
                                  Icons.pets_rounded,
                                  size: cowHeight,
                                  color: widget.color,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
        if (widget.showLabel && !widget.compact) ...[
          const SizedBox(height: 6),
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.grey,
            ),
          ),
        ],
      ],
    );
  }
}
