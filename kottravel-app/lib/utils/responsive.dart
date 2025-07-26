import 'package:flutter/material.dart';

class Responsive {
  final BuildContext context;
  final MediaQueryData _mediaQuery;
  final Orientation _orientation;
  
  Responsive(this.context) 
    : _mediaQuery = MediaQuery.of(context),
      _orientation = MediaQuery.of(context).orientation;

  // Screen dimensions
  double get screenWidth => _mediaQuery.size.width;
  double get screenHeight => _mediaQuery.size.height;
  
  // Orientation helpers
  bool get isLandscape => _orientation == Orientation.landscape;
  bool get isPortrait => _orientation == Orientation.portrait;
  
  // Device type detection
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1024;
  bool get isDesktop => screenWidth >= 1024;
  
  // Responsive sizing methods
  
  /// Returns responsive width based on percentage of screen width
  /// with optional min/max constraints
  double widthPercent(double percent, {double? min, double? max}) {
    final value = screenWidth * (percent / 100);
    if (min != null && max != null) {
      return value.clamp(min, max);
    }
    return value;
  }
  
  /// Returns responsive height based on percentage of screen height
  /// with optional min/max constraints
  double heightPercent(double percent, {double? min, double? max}) {
    final value = screenHeight * (percent / 100);
    if (min != null && max != null) {
      return value.clamp(min, max);
    }
    return value;
  }
  
  /// Returns responsive font size based on screen width
  double fontSize({
    required double mobile,
    double? tablet,
    double? desktop,
    double? min,
    double? max,
  }) {
    double size;
    if (isMobile) {
      size = screenWidth * (mobile / 100);
    } else if (isTablet) {
      size = screenWidth * ((tablet ?? mobile) / 100);
    } else {
      size = screenWidth * ((desktop ?? tablet ?? mobile) / 100);
    }
    
    if (min != null && max != null) {
      return size.clamp(min, max);
    }
    return size;
  }
  
  /// Returns responsive icon size
  double iconSize({
    double mobile = 15.0,
    double? tablet,
    double? desktop,
    double min = 16.0,
    double max = 100.0,
  }) {
    return fontSize(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      min: min,
      max: max,
    );
  }
  
  /// Returns responsive spacing
  double spacing({
    double mobile = 2.0,
    double? tablet,
    double? desktop,
    double min = 8.0,
    double max = 32.0,
  }) {
    return heightPercent(
      isLandscape ? (mobile * 1.5) : mobile,
      min: min,
      max: max,
    );
  }
  
  /// Returns responsive padding
  EdgeInsets padding({
    double horizontal = 5.0,
    double vertical = 2.0,
    double? horizontalTablet,
    double? verticalTablet,
    double? horizontalDesktop,
    double? verticalDesktop,
  }) {
    double h, v;
    
    if (isMobile) {
      h = widthPercent(horizontal);
      v = heightPercent(vertical);
    } else if (isTablet) {
      h = widthPercent(horizontalTablet ?? horizontal);
      v = heightPercent(verticalTablet ?? vertical);
    } else {
      h = widthPercent(horizontalDesktop ?? horizontalTablet ?? horizontal);
      v = heightPercent(verticalDesktop ?? verticalTablet ?? vertical);
    }
    
    return EdgeInsets.symmetric(horizontal: h, vertical: v);
  }
  
  /// Returns responsive margins
  EdgeInsets margin({
    double horizontal = 3.0,
    double vertical = 1.0,
    double? horizontalTablet,
    double? verticalTablet,
    double? horizontalDesktop,
    double? verticalDesktop,
  }) {
    return padding(
      horizontal: horizontal,
      vertical: vertical,
      horizontalTablet: horizontalTablet,
      verticalTablet: verticalTablet,
      horizontalDesktop: horizontalDesktop,
      verticalDesktop: verticalDesktop,
    );
  }
  
  // Navbar specific responsive values
  double get navbarWidth {
    if (isLandscape) {
      return widthPercent(60, min: 260.0, max: 400.0);
    }
    return widthPercent(85, min: 260.0, max: 400.0);
  }
  
  double get navbarCollapsedWidth {
    if (isLandscape) {
      return widthPercent(8, min: 50.0, max: 65.0);
    }
    return widthPercent(15, min: 50.0, max: 65.0);
  }
  
  double get navbarHeight {
    if (isLandscape) {
      return heightPercent(12, min: 48.0, max: 65.0);
    }
    return heightPercent(7, min: 48.0, max: 65.0);
  }
  
  double get navbarBottomPadding {
    if (isLandscape) {
      return heightPercent(6, min: 16.0, max: 40.0);
    }
    return heightPercent(4, min: 16.0, max: 40.0);
  }
  
  double get navbarIconSize {
    if (isLandscape) {
      return widthPercent(3, min: 16.0, max: 24.0);
    }
    return widthPercent(5, min: 16.0, max: 24.0);
  }
  
  double get navbarMenuButtonSize {
    if (isLandscape) {
      return widthPercent(5, min: 30.0, max: 42.0);
    }
    return widthPercent(8, min: 30.0, max: 42.0);
  }
  
  EdgeInsets get navbarItemPadding {
    final paddingValue = isLandscape 
        ? widthPercent(0.8, min: 3.0, max: 10.0)
        : widthPercent(1.2, min: 3.0, max: 10.0);
    return EdgeInsets.all(paddingValue);
  }
  
  double get navbarItemBorderRadius {
    return isLandscape 
        ? widthPercent(1.5, min: 6.0, max: 14.0)
        : widthPercent(2, min: 6.0, max: 14.0);
  }
  
  // Perfect circular border radius for selected items
  double get navbarItemCircularRadius {
    // Make it perfectly circular based on icon size + padding
    final iconSize = navbarIconSize;
    final padding = navbarItemPadding.horizontal;
    return (iconSize + padding * 2) / 2;
  }
  
  EdgeInsets get navbarContentPadding {
    return EdgeInsets.symmetric(
      horizontal: isLandscape 
          ? widthPercent(2, min: 6.0, max: 18.0)
          : widthPercent(3, min: 6.0, max: 18.0),
      vertical: isLandscape 
          ? heightPercent(1, min: 2.0, max: 8.0)
          : heightPercent(0.5, min: 2.0, max: 8.0),
    );
  }
  
  // Screen specific responsive values
  double get screenNavbarSpace {
    if (isLandscape) {
      return heightPercent(20, min: 60.0, max: 120.0);
    }
    return heightPercent(15, min: 60.0, max: 120.0);
  }
  
  // Common text sizes
  double get titleSize => fontSize(mobile: 6.0, min: 18.0, max: 32.0);
  double get subtitleSize => fontSize(mobile: 4.0, min: 12.0, max: 20.0);
  double get appBarTitleSize => fontSize(mobile: 4.5, min: 16.0, max: 20.0);
  double get mainIconSize => iconSize(mobile: 15.0, min: 40.0, max: 100.0);
  
  // Common spacing
  double get mainSpacing => spacing(mobile: 2.0, min: 10.0, max: 25.0);
  EdgeInsets get screenPadding => padding(
    horizontal: isLandscape ? 8.0 : 5.0,
    vertical: isLandscape ? 3.0 : 2.0,
  );
}

// Extension for easy access
extension ResponsiveContext on BuildContext {
  Responsive get responsive => Responsive(this);
}
