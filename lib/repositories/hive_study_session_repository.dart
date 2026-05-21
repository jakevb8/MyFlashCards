// HiveStudySessionRepository — local-first persistence for StudySession records.
//
// Sessions are stored by their UUID key. The box is opened once at app start
// via [init] and stays open for the lifetime of the app, matching the pattern
// used by HiveDeckRepository and HiveFlashcardRepository.

import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/study_session.dart';
import 'study_session_repository.dart';

class HiveStudySessionRepository implements StudySessionRepository {
  static const String _boxName = 'study_sessions';

  Box<StudySession> get _box => Hive.box<StudySession>(_boxName);

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<StudySession>(_boxName);
    }
  }

  @override
  Future<List<StudySession>> getSessions() async => _box.values.toList();

  @override
  Future<void> addSession(StudySession session) async {
    await _box.put(session.id, session);
  }

  @override
  Future<void> clearAll() async {
    await _box.clear();
  }
}
