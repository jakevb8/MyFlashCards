import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../blocs/deck/deck_bloc.dart';
import '../../blocs/deck/deck_event.dart';
import '../../models/deck.dart';

class DeckFormScreen extends StatefulWidget {
  final Deck? deck;
  const DeckFormScreen({super.key, this.deck});

  @override
  State<DeckFormScreen> createState() => _DeckFormScreenState();
}

class _DeckFormScreenState extends State<DeckFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;

  bool get isEditing => widget.deck != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.deck?.name ?? '');
    _descController = TextEditingController(
      text: widget.deck?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    if (isEditing) {
      final updated = widget.deck!.copyWith(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        updatedAt: now,
      );
      context.read<DeckBloc>().add(UpdateDeck(updated));
    } else {
      final deck = Deck(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        createdAt: now,
        updatedAt: now,
      );
      context.read<DeckBloc>().add(AddDeck(deck));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Deck' : 'New Deck')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Deck Name',
                  prefixIcon: Icon(Icons.layers_outlined),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _submit,
                icon: Icon(isEditing ? Icons.save_outlined : Icons.add),
                label: Text(isEditing ? 'Save Changes' : 'Create Deck'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
