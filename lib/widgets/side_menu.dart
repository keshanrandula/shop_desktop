import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Container(
      width: AppConstants.sidebarWidth,
      height: double.infinity,
      color: AppTheme.surface,
      child: Column(
        children: [
          // Elegant Header with animated gradient effect border
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.border, width: 1.2),
              ),
            ),
            child: Row(
              children: [
                // Glowing Logo container
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ShopPOS',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Material 3 POS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),

          // Side Menu Navigation Items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: ListView(
                children: [
                  _MenuRailItem(
                    title: 'Dashboard',
                    icon: Icons.grid_view_rounded,
                    isActive: appState.selectedPageIndex == 0,
                    onTap: () => appState.setPageIndex(0),
                    activeColor: AppTheme.primary,
                  ),
                  const SizedBox(height: 10),
                  _MenuRailItem(
                    title: 'Billing',
                    icon: Icons.receipt_long_rounded,
                    isActive: appState.selectedPageIndex == 1,
                    onTap: () => appState.setPageIndex(1),
                    activeColor: AppTheme.secondary,
                  ),
                  const SizedBox(height: 10),
                  _MenuRailItem(
                    title: 'Inventory',
                    icon: Icons.inventory_2_rounded,
                    isActive: appState.selectedPageIndex == 2,
                    onTap: () => appState.setPageIndex(2),
                    activeColor: AppTheme.tertiary,
                  ),
                  const SizedBox(height: 10),
                  _MenuRailItem(
                    title: 'Sales History',
                    icon: Icons.history_rounded,
                    isActive: appState.selectedPageIndex == 3,
                    onTap: () => appState.setPageIndex(3),
                    activeColor: AppTheme.success,
                  ),
                  const SizedBox(height: 10),
                  _MenuRailItem(
                    title: 'Suppliers',
                    icon: Icons.local_shipping_rounded,
                    isActive: appState.selectedPageIndex == 4,
                    onTap: () => appState.setPageIndex(4),
                    activeColor: AppTheme.warning,
                  ),
                  const SizedBox(height: 10),
                  _MenuRailItem(
                    title: 'Reports',
                    icon: Icons.assessment_rounded,
                    isActive: appState.selectedPageIndex == 5,
                    onTap: () => appState.setPageIndex(5),
                    activeColor: AppTheme.tertiary,
                  ),
                ],
              ),
            ),
          ),

          // User Profile & Logout Panel
          if (appState.currentUser != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              margin: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border, width: 1),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.primary,
                    child: Text(
                      appState.currentUser!.username[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appState.currentUser!.username,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          appState.currentUser!.role,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => appState.logout(),
                    icon: const Icon(Icons.logout_rounded, size: 16, color: AppTheme.danger),
                    tooltip: 'Log out',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // Database Status Widget with sleek border and reconnect button
          Container(
            padding: const EdgeInsets.all(18.0),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppTheme.border, width: 1.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Pulse animation for status indicator
                    _StatusIndicatorPulse(
                      isConnected: appState.isDbConnected,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        appState.isDbConnected ? 'MongoDB Server Online' : 'Database Offline',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: appState.isDbConnected
                              ? AppTheme.textSecondary
                              : AppTheme.danger,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (!appState.isDbConnected) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: appState.isConnectingDb ? null : () => appState.initDatabase(),
                    icon: const Icon(Icons.sync_rounded, size: 14),
                    label: Text(
                      appState.isConnectingDb ? 'Connecting...' : 'Reconnect Now',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.secondary,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      backgroundColor: AppTheme.secondary.withOpacity(0.08),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRailItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;

  const _MenuRailItem({
    Key? key,
    required this.title,
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.activeColor,
  }) : super(key: key);

  @override
  State<_MenuRailItem> createState() => _MenuRailItemState();
}

class _MenuRailItemState extends State<_MenuRailItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          decoration: BoxDecoration(
            color: widget.isActive
                ? widget.activeColor.withOpacity(0.12)
                : (_isHovered ? AppTheme.border.withOpacity(0.3) : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isActive
                  ? widget.activeColor.withOpacity(0.3)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon with glowing effect if active
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? widget.activeColor.withOpacity(0.2)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  size: 20,
                  color: widget.isActive ? widget.activeColor : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              // Menu Label text
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: widget.isActive ? FontWeight.w800 : FontWeight.w500,
                  color: widget.isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              // M3 Active selector indicator dot
              if (widget.isActive)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.activeColor,
                    boxShadow: [
                      BoxShadow(
                        color: widget.activeColor,
                        blurRadius: 4,
                      )
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusIndicatorPulse extends StatefulWidget {
  final bool isConnected;
  const _StatusIndicatorPulse({Key? key, required this.isConnected}) : super(key: key);

  @override
  State<_StatusIndicatorPulse> createState() => _StatusIndicatorPulseState();
}

class _StatusIndicatorPulseState extends State<_StatusIndicatorPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.isConnected ? AppTheme.success : AppTheme.danger;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor.withOpacity(0.3 * _pulseAnimation.value),
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor,
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.5),
                    blurRadius: 4,
                  )
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
