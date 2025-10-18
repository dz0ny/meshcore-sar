/// Channel model - represents a communication channel
class Channel {
  final int index;
  final String name;
  final int? flags;

  Channel({
    required this.index,
    required this.name,
    this.flags,
  });

  /// Display name for the channel
  /// Returns "Public" for channel 0, otherwise returns the custom name or "Channel N"
  String get displayName {
    if (index == 0) {
      return name.isEmpty ? 'Public' : name;
    }
    return name.isEmpty ? 'Channel $index' : name;
  }

  /// Check if channel is the public channel (index 0)
  bool get isPublicChannel => index == 0;

  /// Check if channel has a custom name
  bool get hasCustomName => name.isNotEmpty;

  /// Create from JSON
  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      index: json['index'] as int,
      name: json['name'] as String? ?? '',
      flags: json['flags'] as int?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'name': name,
      'flags': flags,
    };
  }

  /// Create a copy with modified fields
  Channel copyWith({
    int? index,
    String? name,
    int? flags,
  }) {
    return Channel(
      index: index ?? this.index,
      name: name ?? this.name,
      flags: flags ?? this.flags,
    );
  }

  @override
  String toString() {
    return 'Channel(index: $index, name: $name, flags: $flags)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Channel &&
        other.index == index &&
        other.name == name &&
        other.flags == flags;
  }

  @override
  int get hashCode => Object.hash(index, name, flags);
}
