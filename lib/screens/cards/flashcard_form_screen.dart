import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../blocs/flashcard/flashcard_bloc.dart';
import '../../blocs/flashcard/flashcard_event.dart';
import '../../models/flashcard.dart';

class FlashcardFormScreen extends StatefulWidget {
  final String deckId;
  final Flashcard? flashcard;
  const FlashcardFormScreen({super.key, required this.deckId, this.flashcard});

  @override
  State<FlashcardFormScreen> createState() => _FlashcardFormScreenState();
}

class _FlashcardFormScreenState extends State<FlashcardFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _frontController;
  late final TextEditingController _backController;

  bool get isEditing => widget.flashcard != null;

  @override
  void initState() {
    super.initState();
    _frontController = TextEditingController(
      text: widget.flashcard?.front ?? '',
    );
    _backController = TextEditingController(text: widget.flashcard?.back ?? '');
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    if (isEditing) {
      final updated = widget.flashcard!.copyWith(
        front: _frontController.text.trim(),
        back: _backController.text.trim(),
        updatedAt: now,
      );
      context.read<FlashcardBloc>().add(UpdateFlashcard(updated));
    } else {
      final card = Flashcard(
        id: const Uuid().v4(),
        deckId: widget.deckId,
        front: _frontController.text.trim(),
        back: _backController.text.trim(),
        createdAt: now,
        updatedAt: now,
      );
      context.read<FlashcardBloc>().add(AddFlashcard(card));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Card' : 'New Card')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _frontController,
                decoration: const InputDecoration(
                  labelText: 'Front (Question)',
                  prefixIcon: Icon(Icons.help_outline),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Front is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _backController,
                decoration: const InputDecoration(
                  labelText: 'Back (Answer)',
                  prefixIcon: Icon(Icons.lightbulb_outline),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Back is required' : null,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _submit,
                icon: Icon(isEditing ? Icons.save_outlined : Icons.add),
                label: Text(isEditing ? 'Save Changes' : 'Add Card'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
