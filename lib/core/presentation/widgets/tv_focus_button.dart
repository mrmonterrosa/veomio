import 'package:flutter/material.dart';

class TvFocusButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool isPrimary;
  final double focusedScale;
  final ValueChanged<bool>? onFocusChange;
  final FocusNode? focusNode;
  final bool isCircle;
  final EdgeInsetsGeometry? padding;

  const TvFocusButton({
    super.key,
    required this.child,
    required this.onTap,
    this.isPrimary = false,
    this.focusedScale = 1.1,
    this.onFocusChange,
    this.focusNode,
    this.isCircle = false,
    this.padding,
  });

  @override
  State<TvFocusButton> createState() => _TvFocusButtonState();
}

class _TvFocusButtonState extends State<TvFocusButton> {
  bool _isFocused = false;
  bool _isHovered = false;
  FocusNode? _internalFocusNode;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }
    _effectiveFocusNode.addListener(_handleFocusChange);
    _isFocused = _effectiveFocusNode.hasFocus;
  }

  @override
  void didUpdateWidget(TvFocusButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _internalFocusNode)?.removeListener(_handleFocusChange);
      if (widget.focusNode != null) {
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      } else {
        _internalFocusNode ??= FocusNode();
      }
      _effectiveFocusNode.addListener(_handleFocusChange);
      _isFocused = _effectiveFocusNode.hasFocus;
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_isFocused != _effectiveFocusNode.hasFocus) {
      setState(() {
        _isFocused = _effectiveFocusNode.hasFocus;
      });
      widget.onFocusChange?.call(_isFocused);
      if (_isFocused) {
        Scrollable.ensureVisible(
          context,
          alignment: 0.5,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      }
    }
  }

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
      focusNode: _effectiveFocusNode,
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
            duration: const Duration(milliseconds: 50),
            curve: Curves.easeOutCubic,
            transform: Matrix4.identity()..scale(active ? widget.focusedScale : 1.0),
            transformAlignment: Alignment.center,
            padding: widget.padding ?? (widget.isCircle ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 24, vertical: 10)),
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: widget.isCircle ? null : BorderRadius.circular(8),
              border: Border.all(
                color: active ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      )
                    ]
                  : [],
            ),
            child: DefaultTextStyle.merge(
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
