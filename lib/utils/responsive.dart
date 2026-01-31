import 'package:flutter/material.dart';

/// Responsive design utilities for handling different screen sizes
class ResponsiveUtil {
  /// Screen size categories
  static const double mobileMax = 600;
  static const double tabletMax = 1200;
  static const double desktopMax = 1920;

  /// Get current screen size category
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileMax) return ScreenSize.mobile;
    if (width < tabletMax) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  /// Check if screen is mobile
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileMax;

  /// Check if screen is tablet
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileMax &&
      MediaQuery.of(context).size.width < tabletMax;

  /// Check if screen is desktop
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletMax;

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return const EdgeInsets.all(12);
      case ScreenSize.tablet:
        return const EdgeInsets.all(16);
      case ScreenSize.desktop:
        return const EdgeInsets.all(24);
    }
  }

  /// Get responsive font size
  static double getResponsiveFontSize(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return mobile;
      case ScreenSize.tablet:
        return tablet;
      case ScreenSize.desktop:
        return desktop;
    }
  }

  /// Get responsive grid columns
  static int getGridColumns(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 1;
      case ScreenSize.tablet:
        return 2;
      case ScreenSize.desktop:
        return 3;
    }
  }

  /// Get responsive width for cards
  static double getCardWidth(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return double.infinity;
      case ScreenSize.tablet:
        return MediaQuery.of(context).size.width / 2 - 12;
      case ScreenSize.desktop:
        return MediaQuery.of(context).size.width / 3 - 16;
    }
  }
}

enum ScreenSize { mobile, tablet, desktop }

/// Responsive widget that builds different layouts for different screen sizes
class ResponsiveWidget extends StatelessWidget {
  final Widget Function(BuildContext) mobileLayout;
  final Widget Function(BuildContext)? tabletLayout;
  final Widget Function(BuildContext)? desktopLayout;

  const ResponsiveWidget({
    required this.mobileLayout,
    this.tabletLayout,
    this.desktopLayout,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveUtil.getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.mobile:
        return mobileLayout(context);
      case ScreenSize.tablet:
        return tabletLayout?.call(context) ?? mobileLayout(context);
      case ScreenSize.desktop:
        return desktopLayout?.call(context) ?? mobileLayout(context);
    }
  }
}

/// Responsive grid view
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final int Function(BuildContext) columnCount;
  final double spacing;
  final double runSpacing;

  const ResponsiveGridView({
    required this.children,
    required this.columnCount,
    this.spacing = 16,
    this.runSpacing = 16,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCount(context),
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: 1.2,
      ),
      itemCount: children.length,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Responsive row that wraps on small screens
class ResponsiveRow extends StatelessWidget {
  final List<ResponsiveRowChild> children;
  final double spacing;

  const ResponsiveRow({required this.children, this.spacing = 16, super.key});

  @override
  Widget build(BuildContext context) {
    if (ResponsiveUtil.isMobile(context)) {
      return Column(
        children: [
          for (int i = 0; i < children.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i < children.length - 1 ? spacing : 0,
              ),
              child: SizedBox(width: double.infinity, child: children[i].child),
            ),
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < children.length; i++)
          Expanded(
            flex: children[i].flex,
            child: Padding(
              padding: EdgeInsets.only(
                right: i < children.length - 1 ? spacing : 0,
              ),
              child: children[i].child,
            ),
          ),
      ],
    );
  }
}

class ResponsiveRowChild {
  final Widget child;
  final int flex;

  ResponsiveRowChild({required this.child, this.flex = 1});
}
