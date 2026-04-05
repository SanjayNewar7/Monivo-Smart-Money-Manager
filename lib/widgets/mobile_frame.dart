import 'package:flutter/material.dart';

class MobileFrame extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;

  const MobileFrame({
    Key? key,
    required this.child,
    this.backgroundColor,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? const Color(0xFFF5F5F5),
      body: SafeArea(
        child: child,
      ),
    );
  }
}
