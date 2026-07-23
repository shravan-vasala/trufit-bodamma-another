class WorkoutPlan {
  final String planName;
  final List<WorkoutDay> days;

  WorkoutPlan({required this.planName, required this.days});

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    return WorkoutPlan(
      planName: json['planName'] as String,
      days: (json['days'] as List)
          .map((d) => WorkoutDay.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'planName': planName,
        'days': days.map((d) => d.toJson()).toList(),
      };
}

class WorkoutDay {
  final String dayId;
  final String? label;
  final List<WorkoutSection> sections;

  WorkoutDay({required this.dayId, this.label, required this.sections});

  factory WorkoutDay.fromJson(Map<String, dynamic> json) {
    return WorkoutDay(
      dayId: json['dayId'] as String,
      label: json['label'] as String?,
      sections: (json['sections'] as List)
          .map((s) => WorkoutSection.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'dayId': dayId,
        if (label != null) 'label': label,
        'sections': sections.map((s) => s.toJson()).toList(),
      };
}

class WorkoutSection {
  final String title;
  final List<Exercise> exercises;

  WorkoutSection({required this.title, required this.exercises});

  factory WorkoutSection.fromJson(Map<String, dynamic> json) {
    return WorkoutSection(
      title: json['title'] as String,
      exercises: (json['exercises'] as List)
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };
}

class Exercise {
  final String name;
  final String youtubeUrl;
  final List<int> reps;
  final String note;
  final String sideInfo;
  final int restSecondsAfterSet;

  Exercise({
    required this.name,
    required this.youtubeUrl,
    required this.reps,
    this.note = '',
    this.sideInfo = 'None',
    this.restSecondsAfterSet = 0,
  });

  String? get youtubeVideoId {
    final uri = Uri.tryParse(youtubeUrl);
    if (uri == null) return null;
    
    // Handle youtu.be/ID format
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    
    // Handle youtube.com/watch?v=ID or youtube.com/shorts/ID format
    if (uri.host.contains('youtube.com')) {
      if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'shorts') {
        if (uri.pathSegments.length > 1) {
          return uri.pathSegments[1];
        }
      }
      return uri.queryParameters['v'];
    }
    return null;
  }

  String get thumbnailUrl {
    final id = youtubeVideoId;
    if (id == null || id.isEmpty || id == 'XXXX') {
      return '';
    }
    return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
  }

  String get repsDisplay {
    if (reps.length == 1) return '${reps.first}';
    return reps.join(', ');
  }

  int get setCount => reps.length;

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'] as String,
      youtubeUrl: json['youtubeUrl'] as String? ?? '',
      reps: (json['reps'] as List).map((r) => r as int).toList(),
      note: json['note'] as String? ?? '',
      sideInfo: json['sideInfo'] as String? ?? 'None',
      restSecondsAfterSet: json['restSecondsAfterSet'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'youtubeUrl': youtubeUrl,
        'reps': reps,
        'note': note,
        'sideInfo': sideInfo,
        'restSecondsAfterSet': restSecondsAfterSet,
      };
}
