import 'package:flutter/material.dart';

class TvFocusCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double focusedScale;
  final EdgeInsetsGeometry margin;
  final BorderRadius borderRadius;
  final ValueChanged<bool>? onFocusChange;
  final FocusNode? focusNode;

  const TvFocusCard({
    super.key,
    required this.child,
    this.onTap,
    this.onFocusChange,
    this.focusNode,
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
    final active = _isFocused || _isHovered || (widget.focusNode?.hasFocus ?? false);

    return Padding(
      padding: widget.margin,
      child: FocusableActionDetector(
        focusNode: widget.focusNode,
        onFocusChange: (focused) {
          setState(() {
            _isFocused = focused;
          });
          widget.onFocusChange?.call(focused);
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
            child: Builder(
              builder: (context) {
                final outerRadius = widget.borderRadius is BorderRadius
                    ? BorderRadius.only(
                        topLeft: (widget.borderRadius as BorderRadius).topLeft + const Radius.circular(3),
                        topRight: (widget.borderRadius as BorderRadius).topRight + const Radius.circular(3),
                        bottomLeft: (widget.borderRadius as BorderRadius).bottomLeft + const Radius.circular(3),
                        bottomRight: (widget.borderRadius as BorderRadius).bottomRight + const Radius.circular(3),
                      )
                    : widget.borderRadius;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  transform: Matrix4.identity()..scale(active ? widget.focusedScale : 1.0),
                  transformAlignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: outerRadius,
                    color: active ? Colors.white : Colors.transparent,
                  ),
                  padding: const EdgeInsets.all(3),
                  child: widget.child,
                );
              }
            ),
          ),
        ),
      ),
    );
  }
}
