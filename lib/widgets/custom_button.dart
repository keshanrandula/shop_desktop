import 'package:flutter/material.dart';
import '../utils/theme.dart';

enum ButtonType { primary, accent, success, danger, outlined }

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonType type;
  final double? width;
  final double height;
  final bool isLoading;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.type = ButtonType.primary,
    this.width,
    this.height = 48.0,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isHovered = false;

  Color _getButtonColor() {
    if (widget.onPressed == null) return AppTheme.surfaceSecondary;
    switch (widget.type) {
      case ButtonType.primary:
        return _isHovered ? AppTheme.primaryLight : AppTheme.primary;
      case ButtonType.accent:
        return _isHovered ? AppTheme.accent.withAlpha(220) : AppTheme.accent;
      case ButtonType.success:
        return _isHovered ? AppTheme.success.withAlpha(220) : AppTheme.success;
      case ButtonType.danger:
        return _isHovered ? AppTheme.danger.withAlpha(220) : AppTheme.danger;
      case ButtonType.outlined:
        return Colors.transparent;
    }
  }

  Color _getTextColor() {
    if (widget.onPressed == null) return AppTheme.textMuted;
    if (widget.type == ButtonType.outlined) {
      return _isHovered ? AppTheme.primaryLight : AppTheme.textPrimary;
    }
    return AppTheme.textPrimary;
  }

  Border? _getBorder() {
    if (widget.type == ButtonType.outlined) {
      return Border.all(
        color: _isHovered ? AppTheme.primaryLight : AppTheme.border,
        width: 1.5,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onPressed != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: _getButtonColor(),
          borderRadius: BorderRadius.circular(8),
          border: _getBorder(),
          boxShadow: _isHovered && widget.onPressed != null && widget.type != ButtonType.outlined
              ? [
                  BoxShadow(
                    color: _getButtonColor().withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isLoading ? null : widget.onPressed,
            borderRadius: BorderRadius.circular(8),
            splashColor: AppTheme.textPrimary.withOpacity(0.1),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.textPrimary),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              size: 18,
                              color: _getTextColor(),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.text,
                            style: TextStyle(
                              color: _getTextColor(),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
