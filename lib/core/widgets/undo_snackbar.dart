import 'package:flutter/material.dart';

import '../utils/moss_haptics.dart';

/// Shows a floating "Undo" snackbar.
///
/// Takes a [ScaffoldMessengerState] (not a context) so callers can capture it
/// before popping the screen that triggered the action.
void showUndoSnackBar(
  ScaffoldMessengerState messenger, {
  required String message,
  required VoidCallback onUndo,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'เลิกทำ',
          onPressed: () {
            MossHaptics.light();
            onUndo();
          },
        ),
      ),
    );
}
