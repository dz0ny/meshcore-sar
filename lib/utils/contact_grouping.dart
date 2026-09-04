import '../models/contact.dart';

class InferredContactGroup {
  final String key;
  final String label;
  final List<Contact> contacts;
  final List<String> matchPrefixes;

  const InferredContactGroup({
    required this.key,
    required this.label,
    required this.contacts,
    List<String>? matchPrefixes,
  }) : matchPrefixes = matchPrefixes ?? const <String>[];

  DateTime get latestSeen => contacts.first.lastSeenTime;
}

class ContactGrouping {
  static final RegExp _prefixedNamePattern = RegExp(
    r'^([A-Za-z0-9]{2,})([-_/:])',
  );

  static String? inferredGroupLabelForContact(Contact contact) {
    return _extractPrefix(contact.displayName)?.label;
  }

  static bool contactMatchesInferredGroupLabel(Contact contact, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return false;
    }

    final groupLabel = inferredGroupLabelForContact(contact)?.toLowerCase();
    return groupLabel?.contains(normalizedQuery) ?? false;
  }

  static String? sharedInferredGroupLabel(List<Contact> contacts) {
    String? sharedLabel;
    for (final contact in contacts) {
      final label = inferredGroupLabelForContact(contact);
      if (label == null) {
        return null;
      }
      if (sharedLabel == null) {
        sharedLabel = label;
        continue;
      }
      if (sharedLabel != label) {
        return null;
      }
    }
    return sharedLabel;
  }

  static String? sharedParentGroupLabel(List<String> labels) {
    if (labels.isEmpty) {
      return null;
    }

    var commonPrefix = labels.first;
    for (final label in labels.skip(1)) {
      final maxLength = commonPrefix.length < label.length
          ? commonPrefix.length
          : label.length;
      var matchLength = 0;
      while (matchLength < maxLength &&
          commonPrefix.codeUnitAt(matchLength) ==
              label.codeUnitAt(matchLength)) {
        matchLength++;
      }
      commonPrefix = commonPrefix.substring(0, matchLength);
      if (commonPrefix.isEmpty) {
        return null;
      }
    }

    final separatorIndex = commonPrefix.lastIndexOf(RegExp(r'[-_/:]'));
    if (separatorIndex < 1) {
      return null;
    }

    final parentLabel = commonPrefix.substring(0, separatorIndex + 1);
    return parentLabel.length >= 3 ? parentLabel : null;
  }

  static List<Contact> sortByLastSeen(List<Contact> contacts) {
    return List<Contact>.from(contacts)
      ..sort((a, b) => b.lastSeenTime.compareTo(a.lastSeenTime));
  }

  static List<InferredContactGroup> inferGroups(
    List<Contact> contacts, {
    int minGroupSize = 4,
    int? maxNamedGroups,
    String? overflowGroupLabel,
  }) {
    final sortedContacts = sortByLastSeen(contacts);
    final groupedContacts = <String, List<Contact>>{};
    final groupLabels = <String, String>{};

    for (final contact in sortedContacts) {
      final prefix = _extractPrefix(contact.displayName);
      if (prefix == null) continue;
      groupedContacts.putIfAbsent(prefix.key, () => <Contact>[]).add(contact);
      groupLabels.putIfAbsent(prefix.key, () => prefix.label);
    }

    final rankedGroups = <InferredContactGroup>[];
    for (final entry in groupedContacts.entries) {
      if (entry.value.length < minGroupSize) continue;
      rankedGroups.add(
        InferredContactGroup(
          key: entry.key,
          label: groupLabels[entry.key] ?? entry.key,
          contacts: entry.value,
          matchPrefixes: [groupLabels[entry.key] ?? entry.key],
        ),
      );
    }
    rankedGroups.sort((a, b) => b.latestSeen.compareTo(a.latestSeen));

    if (maxNamedGroups != null &&
        overflowGroupLabel != null &&
        rankedGroups.length > maxNamedGroups) {
      final retainedGroups = rankedGroups.take(maxNamedGroups).toList();
      final overflowGroups = rankedGroups.skip(maxNamedGroups).toList();
      final parentLabel = sharedParentGroupLabel([
        for (final group in overflowGroups) ...group.matchPrefixes,
      ]);
      if (parentLabel != null) {
        final overflowContacts = overflowGroups
            .expand((group) => group.contacts)
            .toList();
        return [
          ...retainedGroups,
          InferredContactGroup(
            key: parentLabel,
            label: parentLabel,
            contacts: sortByLastSeen(overflowContacts),
            matchPrefixes: [parentLabel],
          ),
        ];
      }

      return rankedGroups;
    }
    return rankedGroups;
  }

  static _GroupPrefix? _extractPrefix(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final match = _prefixedNamePattern.firstMatch(trimmed);
    if (match == null) return null;

    final rawPrefix = match.group(1);
    final separator = match.group(2);
    if (rawPrefix == null || separator == null) return null;

    return _GroupPrefix(
      key: rawPrefix.toUpperCase(),
      label: '$rawPrefix$separator',
    );
  }
}

class _GroupPrefix {
  final String key;
  final String label;

  const _GroupPrefix({required this.key, required this.label});
}
