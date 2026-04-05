import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class AppToast {
  const AppToast._();

  static String formatError(Object error) {
    final message = error.toString().trim();
    return message.isEmpty ? 'Unknown error.' : message;
  }

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    bool destructive = false,
  }) {
    final toaster = ShadToaster.maybeOf(context);
    if (toaster != null) {
      toaster.show(
        destructive
            ? ShadToast.destructive(
                title: Text(title),
                description: Text(message),
              )
            : ShadToast(
                title: Text(title),
                description: Text(message),
              ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text('$title: $message')));
  }

  static void success(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    show(context, title: title, message: message);
  }

  static void error(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    show(context, title: title, message: message, destructive: true);
  }

  static void errorFromException(
    BuildContext context, {
    required String title,
    required Object error,
  }) {
    show(
      context,
      title: title,
      message: formatError(error),
      destructive: true,
    );
  }
}