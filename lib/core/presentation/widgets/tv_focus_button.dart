import 'package:flutter/material.dart';

class TvFocusButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool isPrimary;
  final double focusedScale;

  const TvFocusButton({
    super.key,
    required this.child,
    required this.onTap,
    this.isPrimary = false,
    this.focusedScale = 1.1,
  });

  @override
  State<TvFocusButton> createState() => _TvFocusButtonState();
}

class _TvFocusButtonState extends State<TvFocusButton> {
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = _isFocused || _isHovered;

    Color backgroundColor;
    Color textColor;

    if (widget.isPrimary) {
      backgroundColor = theme.colorScheme.primary;
      textColor = theme.colorScheme.onPrimary;
    } else {
      backgroundColor = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8);
      textColor = theme.colorScheme.onSurface;
    }

    return FocusableActionDetector(
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
            widget.onTap();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            transform: Matrix4.identity()..scale(active ? widget.focusedScale : 1.0),
            transformAlignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: active
                    ? (widget.isPrimary ? theme.colorScheme.onPrimary : theme.colorScheme.primary)
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.4),
                        blurRadius: 15,
                        spreadRadius: -2,
                        offset: const Offset(0, 5),
                      )
                    ]
                  : [],
            ),
            child: DefaultTextStyle.merge(
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
