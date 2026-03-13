import 'package:flutter/material.dart';
import 'package:saferide/core/constants/app_dimensions.dart';

class SafeAreaWrapper extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final EdgeInsets padding;

  const SafeAreaWrapper({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppDimensions.paddingMD,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: top,
      bottom: bottom,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
