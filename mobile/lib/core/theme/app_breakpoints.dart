import 'package:flutter/material.dart';

enum AppLayoutSize { compact, medium, expanded, wide }

abstract final class AppBreakpoints {
  static const double compact = 600;
  static const double medium = 768;
  static const double expanded = 1024;
  static const double wide = 1440;

  static AppLayoutSize layoutSizeOf(double width) {
    if (width >= wide) return AppLayoutSize.wide;
    if (width >= expanded) return AppLayoutSize.expanded;
    if (width >= medium) return AppLayoutSize.medium;
    return AppLayoutSize.compact;
  }

  static AppLayoutSize fromContext(BuildContext context) {
    return layoutSizeOf(MediaQuery.sizeOf(context).width);
  }

  static bool isCompact(BuildContext context) =>
      fromContext(context) == AppLayoutSize.compact;

  static bool isWide(BuildContext context) {
    final size = fromContext(context);
    return size == AppLayoutSize.expanded || size == AppLayoutSize.wide;
  }

  static int gridColumns(BuildContext context,
      {int compact = 1, int medium = 2, int expanded = 3}) {
    return switch (fromContext(context)) {
      AppLayoutSize.wide => expanded + 1,
      AppLayoutSize.expanded => expanded,
      AppLayoutSize.medium => medium,
      AppLayoutSize.compact => compact,
    };
  }
}
