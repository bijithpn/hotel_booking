import 'package:flutter/widgets.dart';

Widget responsiveRow(
  BuildContext context,
  List<Widget> children, {
  CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  double breakpoint = Responsive.mobileMaxWidth,
}) {
  if (Responsive.widthOf(context) >= breakpoint) {
    return Row(crossAxisAlignment: crossAxisAlignment, children: children);
  }
  final stacked = <Widget>[];
  for (final child in children) {
    if (child is Expanded) {
      stacked.add(SizedBox(width: double.infinity, child: child.child));
    } else if (child is SizedBox &&
        child.width != null &&
        child.height == null) {
      stacked.add(SizedBox(height: child.width));
    } else {
      stacked.add(child);
    }
  }
  return Column(crossAxisAlignment: crossAxisAlignment, children: stacked);
}

class Responsive {
  Responsive._();

  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1024;

  static double widthOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static bool isMobile(BuildContext context) =>
      widthOf(context) < mobileMaxWidth;

  static bool isTablet(BuildContext context) {
    final w = widthOf(context);
    return w >= mobileMaxWidth && w < tabletMaxWidth;
  }

  static bool isDesktop(BuildContext context) =>
      widthOf(context) >= tabletMaxWidth;

  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final w = widthOf(context);
    if (w >= tabletMaxWidth) return desktop ?? tablet ?? mobile;
    if (w >= mobileMaxWidth) return tablet ?? mobile;
    return mobile;
  }
}

extension ResponsiveContext on BuildContext {
  bool get isMobile => Responsive.isMobile(this);
  bool get isTablet => Responsive.isTablet(this);
  bool get isDesktop => Responsive.isDesktop(this);
}
