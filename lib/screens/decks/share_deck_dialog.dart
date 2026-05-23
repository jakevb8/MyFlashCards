// ShareDeckDialog — bottom sheet for sharing a deck via a deep link.
//
// Opens by dispatching ShareDeckRequested to DeckSharingBloc, which publishes
// the deck to Firestore and returns a deep-link string. The sheet shows a
// progress indicator while the publish is in progress, then displays the link
// with a copy button and a system share button once the link is ready.
//
// Errors are shown as a SnackBar; the sheet stays open so the user can retry.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../blocs/deck_sharing/deck_sharing_bloc.dart';
import '../../blocs/deck_sharing/deck_sharing_event.dart';
import '../../blocs/deck_sharing/deck_sharing_state.dart';
import '../../models/deck.dart';
import '../../models/flashcard.dart';

/// Opens the share-deck bottom sheet for [deck] and [cards].
///
/// Dispatches [ShareDeckRequested] immediately on open. Callers must ensure
/// [DeckSharingBloc] is available in the widget tree.
Future<void> showShareDeckSheet(
  BuildContext context, {
  required Deck deck,
  required List<Flashcard> cards,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => BlocProvider.value(
      value: context.read<DeckSharingBloc>(),
      child: _ShareDeckSheet(deck: deck, cards: cards),
    ),
  );
}

class _ShareDeckSheet extends StatefulWidget {
  final Deck deck;
  final List<Flashcard> cards;

  const _ShareDeckSheet({required this.deck, required this.cards});

  @override
  State<_ShareDeckSheet> createState() => _ShareDeckSheetState();
}

class _ShareDeckSheetState extends State<_ShareDeckSheet> {
  // Holds the generated link across state rebuilds so it survives the
  // DeckSharingIdle reset that follows DeckSharingSuccess.
  String? _generatedLink;

  @override
  void initState() {
    super.initState();
    // Kick off the Firestore publish as soon as the sheet opens.
    context.read<DeckSharingBloc>().add(
      ShareDeckRequested(deck: widget.deck, cards: widget.cards),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DeckSharingBloc, DeckSharingState>(
      listener: (context, state) {
        if (state is DeckSharingSuccess) {
          setState(() => _generatedLink = state.shareLink);
        } else if (state is DeckSharingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withAlpha(80),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Share "${widget.deck.name}"',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Anyone with this link can import a copy of your deck.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                if (_generatedLink == null && state is! DeckSharingError) ...[
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Generating link…',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ] else if (_generatedLink != null) ...[
                  _LinkCard(link: _generatedLink!),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => Share.share(
                      _generatedLink!,
                      subject:
                          'Check out my flashcard deck: ${widget.deck.name}',
                    ),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share via…'),
                  ),
                ] else ...[
                  // Error state — show a retry button.
                  FilledButton.icon(
                    onPressed: () {
                      context.read<DeckSharingBloc>().add(
                        ShareDeckRequested(
                          deck: widget.deck,
                          cards: widget.cards,
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Displays the share link in a tappable card with a copy-to-clipboard button.
class _LinkCard extends StatelessWidget {
  final String link;
  const _LinkCard({required this.link});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              link,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: 'Copy link',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: link));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied to clipboard')),
              );
            },
          ),
        ],
      ),
    );
  }
}
