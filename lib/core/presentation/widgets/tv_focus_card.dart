import 'package:flutter/material.dart';

class TvFocusCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double focusedScale;
  final EdgeInsetsGeometry margin;
  final BorderRadius borderRadius;

  const TvFocusCard({
    super.key,
    required this.child,
    this.onTap,
    this.focusedScale = 1.05,
    this.margin = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  State<TvFocusCard> createState() => _TvFocusCardState();
}

class _TvFocusCardState extends State<TvFocusCard> {
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = _isFocused || _isHovered;

    return Padding(
      padding: widget.margin,
      child: FocusableActionDetector(
        onFocusChange: (focused) {
          setState(() {
            _isFocused = focused;
          });
          if (focused) {
            Scrollable.ensureVisible(
              context,
              alignment: 0.5,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
            );
          }
        },
        onShowHoverHighlight: (hovered) {
          setState(() {
            _isHovered = hovered;
          });
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap?.call();
              return null;
            },
          ),
        },
        child: MouseRegion(
          cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              transform: Matrix4.identity()..scale(active ? widget.focusedScale : 1.0),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius,
                border: Border.all(
                  color: active ? theme.colorScheme.primary : Colors.transparent,
                  width: 4,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 25,
                          spreadRadius: -5,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : [],
              ),
              child: ClipRRect(
                borderRadius: widget.borderRadius,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
