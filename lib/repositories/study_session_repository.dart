import '../models/study_session.dart';

abstract class StudySessionRepository {
  /// Returns all recorded study sessions, unsorted.
  Future<List<StudySession>> getSessions();

  /// Persists a new session. [session.id] must be unique.
  Future<void> addSession(StudySession session);

  /// Removes all sessions (used before a full restore).
  Future<void> clearAll();
}
