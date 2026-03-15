import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class AppCard extends StatelessWidget {
  final String? title;
  final String? description;
  final Widget child;
  final Widget? footer;
  final EdgeInsetsGeometry? padding;

  const AppCard({
    super.key,
    this.title,
    this.description,
    required this.child,
    this.footer,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      title: title != null ? Text(title!) : null,
      description: description != null ? Text(description!) : null,
      padding: padding,
      footer: footer,
      child: child,
    );
  }
}
