class SavedContactGroup {
  final String id;
  final String sectionKey;
  final String label;
  final String query;
  final DateTime createdAt;
  final List<String>? matchPrefixes;
  final bool isAutoGroup;

  const SavedContactGroup({
    required this.id,
    required this.sectionKey,
    required this.label,
    required this.query,
    required this.createdAt,
    this.matchPrefixes,
    this.isAutoGroup = false,
  });

  SavedContactGroup copyWith({
    String? id,
    String? sectionKey,
    String? label,
    String? query,
    DateTime? createdAt,
    List<String>? matchPrefixes,
    bool? isAutoGroup,
  }) {
    return SavedContactGroup(
      id: id ?? this.id,
      sectionKey: sectionKey ?? this.sectionKey,
      label: label ?? this.label,
      query: query ?? this.query,
      createdAt: createdAt ?? this.createdAt,
      matchPrefixes: matchPrefixes ?? this.matchPrefixes,
      isAutoGroup: isAutoGroup ?? this.isAutoGroup,
    );
  }
}
