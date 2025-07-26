import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../utils/app_theme.dart';
import 'animated_layout_grid.dart';

class FloatingBottomNavbar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FloatingBottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<FloatingBottomNavbar> createState() => _FloatingBottomNavbarState();
}

class _FloatingBottomNavbarState extends State<FloatingBottomNavbar>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  final List<NavItem> _navItems = [
    NavItem(icon: Icons.home, index: 0),
    NavItem(icon: Icons.monitor, index: 1),
    NavItem(icon: Icons.add_road_outlined, index: 2),
    NavItem(icon: Icons.person, index: 3),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600), // Smoother, longer animation
      vsync: this,
    );

    // Create animations that directly use the controller
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic, // Smooth, non-jittery reverse
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic, // Same curve for consistency
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _onItemTap(int index) {
    widget.onTap(index);
    // Remove the delay to prevent animation conflicts
    _toggleMenu();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    // Get all responsive values from utility
    final navbarWidth =
        _isExpanded ? responsive.navbarWidth : responsive.navbarCollapsedWidth;
    final navbarHeight = responsive.navbarHeight;
    final bottomPadding = responsive.navbarBottomPadding;
    final iconSize = responsive.navbarIconSize;
    final menuButtonSize = responsive.navbarMenuButtonSize;

    return Positioned(
      bottom: bottomPadding,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 600,
          ), // Match the controller duration for smoothness
          curve: Curves.easeOutBack, // More elegant curve for expansion
          width: navbarWidth,
          height: navbarHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
                  _isExpanded
                      ? [
                        AppColors.secondary, // Light green when expanded
                        AppColors
                            .secondaryLight, // Slightly darker light green gradient
                      ]
                      : [
                        AppColors.primary, // Bright green when collapsed
                        AppColors.onTap, // Darker green variant
                      ],
            ),
            borderRadius: BorderRadius.circular(navbarHeight / 2),
            boxShadow: [
              BoxShadow(
                color:
                    _isExpanded
                        ? Colors.black.withOpacity(0.08)
                        : AppColors.primary.withOpacity(0.3),
                blurRadius: _isExpanded ? 25 : 20, // Dynamic shadow blur
                offset: Offset(
                  0,
                  _isExpanded ? 10 : 8,
                ), // Dynamic shadow offset
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(navbarHeight / 2),
            child: Stack(
              children: [
                // Menu button - always centered
                Center(
                  child: GestureDetector(
                    onTap: _toggleMenu,
                    child: Container(
                      width: menuButtonSize,
                      height: menuButtonSize,
                      decoration: BoxDecoration(
                        color:
                            Colors
                                .transparent, // Remove background when expanded and collapsed
                        borderRadius: BorderRadius.circular(menuButtonSize / 2),
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 600),
                          child: AnimatedLayoutGrid(
                            key: ValueKey(_isExpanded),
                            size: iconSize,
                            color: _isExpanded ? Colors.black54 : Colors.black,
                            strokeWidth: 2.0,
                            isAnimating: _isExpanded,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Navigation items - only visible when expanded
                if (_isExpanded)
                  Positioned.fill(
                    child: Padding(
                      padding: responsive.navbarContentPadding,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Left side items (Home, Providers)
                          ..._navItems.take(2).map((item) {
                            final isSelected =
                                widget.currentIndex == item.index;
                            return Expanded(
                              child: Center(
                                child: AnimatedBuilder(
                                  animation: _controller,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _scaleAnimation.value,
                                      child: Opacity(
                                        opacity: _opacityAnimation.value,
                                        child: GestureDetector(
                                          onTap: () => _onItemTap(item.index),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeInOutCubic,
                                            padding:
                                                responsive.navbarItemPadding,
                                            decoration: BoxDecoration(
                                              color:
                                                  isSelected
                                                      ? AppColors.deepGreen
                                                      : Colors.transparent,
                                              borderRadius: BorderRadius.circular(
                                                responsive
                                                    .navbarItemCircularRadius,
                                              ),
                                            ),
                                            child: Icon(
                                              item.icon,
                                              color:
                                                  isSelected
                                                      ? Colors.white
                                                      : Colors.black54,
                                              size: iconSize,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          }).toList(),

                          // Center space for menu button
                          Expanded(child: SizedBox(width: menuButtonSize)),

                          // Right side items (Marketplace, Profile)
                          ..._navItems.skip(2).map((item) {
                            final isSelected =
                                widget.currentIndex == item.index;
                            return Expanded(
                              child: Center(
                                child: AnimatedBuilder(
                                  animation: _controller,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _scaleAnimation.value,
                                      child: Opacity(
                                        opacity: _opacityAnimation.value,
                                        child: GestureDetector(
                                          onTap: () => _onItemTap(item.index),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeInOutCubic,
                                            padding:
                                                responsive.navbarItemPadding,
                                            decoration: BoxDecoration(
                                              color:
                                                  isSelected
                                                      ? AppColors.deepGreen
                                                      : Colors.transparent,
                                              borderRadius: BorderRadius.circular(
                                                responsive
                                                    .navbarItemCircularRadius,
                                              ),
                                            ),
                                            child: Icon(
                                              item.icon,
                                              color:
                                                  isSelected
                                                      ? Colors.white
                                                      : Colors.black54,
                                              size: iconSize,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final int index;

  NavItem({required this.icon, required this.index});
}
