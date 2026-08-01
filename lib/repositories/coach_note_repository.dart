import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class CoachNote {
  final String date;
  final String note;
  final bool isAi;

  CoachNote({
    required this.date,
    required this.note,
    required this.isAi,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'note': note,
      'isAi': isAi,
    };
  }

  factory CoachNote.fromJson(Map<String, dynamic> json) {
    return CoachNote(
      date: json['date'] as String,
      note: json['note'] as String,
      isAi: json['isAi'] as bool? ?? false,
    );
  }
}

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
