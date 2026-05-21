// Dialog and bottom-sheet helpers for FEAT-006 import/export.
//
// Keeping these extracted prevents DeckListScreen and FlashcardListScreen from
// growing too large.  All functions are pure UI — no bloc interaction here.

import 'package:flutter/material.dart';

enum ImportDuplicateAction { replace, merge, cancel }

/// Shows an AlertDialog when an imported deck name clashes with an existing one.
///
/// Returns [ImportDuplicateAction.replace], [ImportDuplicateAction.merge], or
/// [ImportDuplicateAction.cancel] depending on what the user taps. Dismissing
/// the dialog (back button / tap outside) is treated as cancel.
Future<ImportDuplicateAction> showDuplicateDeckDialog(
  BuildContext context, {
  required String deckName,
}) async {
  final result = await showDialog<ImportDuplicateAction>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Deck already exists'),
      content: Text(
        '"$deckName" already exists on this device. '
        'What would you like to do?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, ImportDuplicateAction.cancel),
          child: const Text('Cancel'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.pop(ctx, ImportDuplicateAction.merge),
          child: const Text('Merge'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
            foregroundColor: Theme.of(ctx).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(ctx, ImportDuplicateAction.replace),
          child: const Text('Replace'),
        ),
      ],
    ),
  );
  return result ?? ImportDuplicateAction.cancel;
}
