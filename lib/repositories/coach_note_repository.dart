import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/coach_note.dart';

class CoachNoteRepository {
  static const String boxName = 'coach_notes';
  late final Box<String> _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(boxName);
  }

  CoachNote? getNote(String date) {
    final str = _box.get(date);
    if (str == null) return null;
    try {
      final json = jsonDecode(str) as Map<String, dynamic>;
      return CoachNote.fromJson(json);
    } catch (_) {
      // Fallback for any legacy data
      return CoachNote(date: date, note: str, isAi: false);
    }
  }

  Future<void> saveNote(CoachNote note) async {
    await _box.put(note.date, jsonEncode(note.toJson()));
  }

  List<CoachNote> getRecentNotes(int limit) {
    final notes = <CoachNote>[];
    for (final key in _box.keys) {
      final str = _box.get(key);
      if (str != null) {
        try {
          final json = jsonDecode(str) as Map<String, dynamic>;
          notes.add(CoachNote.fromJson(json));
        } catch (_) {
          notes.add(CoachNote(date: key.toString(), note: str, isAi: false));
        }
      }
    }
    notes.sort((a, b) => b.date.compareTo(a.date)); // Descending
    return notes.take(limit).toList();
  }
}
