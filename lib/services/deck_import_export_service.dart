// DeckImportExportService — serializes/deserializes decks+cards to JSON and CSV,
// writes the output to the device temp directory, and triggers the platform
// share sheet via share_plus.
//
// Import flow: file_picker opens a single .json or .csv file → bytes decoded
// to String → format detected by extension → parsed into a DeckImportExportBundle.
//
// Export flow: deck + cards serialized to string → written to
// <tempDir>/<deckName>_<timestamp>.<ext> → Share.shareXFiles invoked.
//
// All I/O lives here so blocs and widgets stay pure. The service is stateless
// and can be injected as a singleton.

import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';

/// A parsed deck together with its cards, returned by [DeckImportExportService.pickAndParse].
class DeckImportExportBundle {
  final Deck deck;
  final List<Flashcard> cards;
  const DeckImportExportBundle({required this.deck, required this.cards});
}

class DeckImportExportService {
  // ---------------------------------------------------------------------------
  // Export
  // ---------------------------------------------------------------------------

  /// Serializes [deck] and [cards] to a JSON string.
  ///
  /// Uses [Deck.toJson] / [Flashcard.toJson] directly — no custom mapping.
  /// The envelope includes a [schemaVersion] for forward-compatibility.
  String encodeJson(Deck deck, List<Flashcard> cards) {
    final payload = {
      'schemaVersion': 1,
      'deck': deck.toJson(),
      'cards': cards.map((c) => c.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Serializes [deck] and [cards] to a CSV string (RFC 4180-compatible).
  ///
  /// Row 0: a comment line (`# `) carrying deck metadata.
  /// Row 1: column headers.
  /// Rows 2+: one card per row.
  ///
  /// Nullable SM-2 fields (easeFactor, intervalDays, repetitions, nextReviewAt)
  /// are written as empty string and parsed back to null on import.
  String encodeCsv(Deck deck, List<Flashcard> cards) {
    final buf = StringBuffer();

    // Deck metadata comment row — parsed on import to reconstruct the Deck.
    buf.writeln(
      '# ${_encodeCsvField(deck.id)},'
      '${_encodeCsvField(deck.name)},'
      '${_encodeCsvField(deck.description)},'
      '${_encodeCsvField(deck.createdAt.toIso8601String())},'
      '${_encodeCsvField(deck.updatedAt.toIso8601String())}',
    );

    // Column header row.
    buf.writeln(
      'id,deckId,front,back,createdAt,updatedAt,'
      'starCount,archived,easeFactor,intervalDays,repetitions,nextReviewAt',
    );

    for (final c in cards) {
      buf.writeln(
        '${_encodeCsvField(c.id)},'
        '${_encodeCsvField(c.deckId)},'
        '${_encodeCsvField(c.front)},'
        '${_encodeCsvField(c.back)},'
        '${_encodeCsvField(c.createdAt.toIso8601String())},'
        '${_encodeCsvField(c.updatedAt.toIso8601String())},'
        '${c.starCount},'
        '${c.archived},'
        '${c.easeFactor ?? ''},'
        '${c.intervalDays ?? ''},'
        '${c.repetitions ?? ''},'
        '${_encodeCsvField(c.nextReviewAt?.toIso8601String() ?? '')}',
      );
    }

    return buf.toString();
  }

  /// Writes the encoded deck to a temp file and invokes the platform share sheet.
  ///
  /// [format] must be `'json'` or `'csv'`. The file name is derived from the
  /// deck name with a timestamp suffix to avoid collisions.
  Future<void> exportAndShare(
    Deck deck,
    List<Flashcard> cards, {
    required String format,
  }) async {
    final content = format == 'csv'
        ? encodeCsv(deck, cards)
        : encodeJson(deck, cards);

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // Sanitize deck name for use as a file name component.
    final safeName = deck.name.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    final file = File('${tempDir.path}/${safeName}_$timestamp.$format');
    await file.writeAsString(content, encoding: utf8);

    await Share.shareXFiles([
      XFile(file.path),
    ], subject: '${deck.name} flashcard deck');
  }

  // ---------------------------------------------------------------------------
  // Import
  // ---------------------------------------------------------------------------

  /// Opens the platform file picker filtered to .json and .csv, parses the
  /// selected file, and returns a [DeckImportExportBundle].
  ///
  /// Returns `null` if the user cancels without selecting a file.
  /// Throws [FormatException] if the file cannot be parsed.
  Future<DeckImportExportBundle?> pickAndParse() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw const FormatException('Selected file is empty');
    }

    final content = utf8.decode(bytes);
    final ext = (file.extension ?? '').toLowerCase();

    if (ext == 'json') return _parseJson(content);
    if (ext == 'csv') return _parseCsv(content);
    throw FormatException('Unsupported file type: $ext');
  }

  // ---------------------------------------------------------------------------
  // ---------------------------------------------------------------------------
  // Public decode entry point (used by DeckSharingService)
  // ---------------------------------------------------------------------------

  /// Parses a JSON export string previously produced by [encodeJson].
  ///
  /// Public wrapper around [_parseJson] so [DeckSharingService] can deserialize
  /// a shared deck payload without duplicating parsing logic.
  /// Throws [FormatException] on malformed input.
  DeckImportExportBundle decodeJson(String source) => _parseJson(source);

  // ---------------------------------------------------------------------------
  // Private parsers
  // ---------------------------------------------------------------------------

  /// Parses a JSON export string produced by [encodeJson].
  ///
  /// Tolerates missing SM-2 fields (they default to null in [Flashcard.fromJson]).
  /// Throws [FormatException] on malformed JSON or missing required top-level keys.
  DeckImportExportBundle _parseJson(String source) {
    final dynamic raw;
    try {
      raw = json.decode(source);
    } catch (e) {
      throw FormatException('Invalid JSON: $e');
    }
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('JSON root must be an object');
    }
    if (!raw.containsKey('deck') || !raw.containsKey('cards')) {
      throw const FormatException('JSON missing required keys: deck, cards');
    }

    final deck = Deck.fromJson(raw['deck'] as Map<String, dynamic>);
    final cardsRaw = raw['cards'] as List<dynamic>;
    final cards = cardsRaw
        .map((c) => Flashcard.fromJson(c as Map<String, dynamic>))
        .toList();

    return DeckImportExportBundle(deck: deck, cards: cards);
  }

  /// Parses a CSV export string produced by [encodeCsv].
  ///
  /// Expects Row 0 to be the deck metadata comment (prefixed with `# `),
  /// Row 1 to be the column header row, and subsequent rows to be card data.
  /// Throws [FormatException] on structural errors.
  DeckImportExportBundle _parseCsv(String source) {
    // Split on line endings, filtering completely blank lines.
    final rawLines = source
        .split(RegExp(r'\r?\n'))
        .where((l) => l.isNotEmpty)
        .toList();

    if (rawLines.length < 2) {
      throw const FormatException(
        'CSV must have at least a metadata row and a header row',
      );
    }

    // --- Deck row (starts with '# ') ---
    final deckLine = rawLines[0];
    if (!deckLine.startsWith('# ')) {
      throw const FormatException(
        'CSV row 0 must be a deck metadata comment (# ...)',
      );
    }
    final deckFields = _parseCsvLine(deckLine.substring(2));
    if (deckFields.length < 5) {
      throw const FormatException('CSV deck row must have 5 fields');
    }
    final deck = Deck(
      id: deckFields[0],
      name: deckFields[1],
      description: deckFields[2],
      createdAt: DateTime.parse(deckFields[3]),
      updatedAt: DateTime.parse(deckFields[4]),
    );

    // Skip the header row (index 1).
    final cards = <Flashcard>[];
    for (var i = 2; i < rawLines.length; i++) {
      final fields = _parseCsvLine(rawLines[i]);
      if (fields.length != 12) {
        throw FormatException(
          'CSV card row $i has ${fields.length} fields, expected 12',
        );
      }
      cards.add(
        Flashcard(
          id: fields[0],
          deckId: fields[1],
          front: fields[2],
          back: fields[3],
          createdAt: DateTime.parse(fields[4]),
          updatedAt: DateTime.parse(fields[5]),
          starCount: int.parse(fields[6]),
          archived: fields[7] == 'true',
          easeFactor: fields[8].isEmpty ? null : double.parse(fields[8]),
          intervalDays: fields[9].isEmpty ? null : int.parse(fields[9]),
          repetitions: fields[10].isEmpty ? null : int.parse(fields[10]),
          nextReviewAt: fields[11].isEmpty ? null : DateTime.parse(fields[11]),
        ),
      );
    }

    return DeckImportExportBundle(deck: deck, cards: cards);
  }

  // ---------------------------------------------------------------------------
  // CSV helpers (RFC 4180 subset)
  // ---------------------------------------------------------------------------

  /// Wraps a CSV field value in double-quotes if it contains commas, newlines,
  /// or double-quotes. Internal double-quotes are escaped as `""`.
  String _encodeCsvField(String value) {
    if (value.contains(',') ||
        value.contains('\n') ||
        value.contains('\r') ||
        value.contains('"')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Parses a single CSV line into a list of field strings.
  ///
  /// Handles RFC 4180 quoting: fields wrapped in `"..."` may contain commas
  /// and newlines; `""` inside a quoted field represents a literal `"`.
  List<String> _parseCsvLine(String line) {
    final fields = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;
    var i = 0;

    while (i < line.length) {
      final ch = line[i];
      if (inQuotes) {
        if (ch == '"') {
          // Peek ahead: "" → literal quote; " alone → end of quoted field.
          if (i + 1 < line.length && line[i + 1] == '"') {
            buf.write('"');
            i += 2;
          } else {
            inQuotes = false;
            i++;
          }
        } else {
          buf.write(ch);
          i++;
        }
      } else {
        if (ch == '"') {
          inQuotes = true;
          i++;
        } else if (ch == ',') {
          fields.add(buf.toString());
          buf.clear();
          i++;
        } else {
          buf.write(ch);
          i++;
        }
      }
    }
    fields.add(buf.toString()); // last field
    return fields;
  }
}
