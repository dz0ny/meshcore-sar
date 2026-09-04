import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/models/contact.dart';
import 'package:meshcore_sar_app/utils/contact_grouping.dart';

void main() {
  Contact buildContact({
    required int seed,
    required String name,
    required DateTime lastSeen,
  }) {
    return Contact(
      publicKey: Uint8List.fromList(
        List<int>.generate(32, (index) => (seed + index) % 255),
      ),
      type: ContactType.chat,
      flags: 0,
      outPathLen: 0,
      outPath: Uint8List(64),
      advName: name,
      lastAdvert: lastSeen.millisecondsSinceEpoch ~/ 1000,
      advLat: 0,
      advLon: 0,
      lastMod: lastSeen.millisecondsSinceEpoch ~/ 1000,
    );
  }

  group('ContactGrouping.inferGroups', () {
    test(
      'groups prefixed contacts only when at least four share the prefix',
      () {
        final now = DateTime(2026, 3, 10, 12);
        final groups = ContactGrouping.inferGroups([
          buildContact(seed: 1, name: 'SI-1', lastSeen: now),
          buildContact(
            seed: 2,
            name: 'SI-2',
            lastSeen: now.subtract(const Duration(minutes: 1)),
          ),
          buildContact(
            seed: 3,
            name: 'SI-3',
            lastSeen: now.subtract(const Duration(minutes: 2)),
          ),
          buildContact(
            seed: 4,
            name: 'SI-4',
            lastSeen: now.subtract(const Duration(minutes: 3)),
          ),
          buildContact(
            seed: 5,
            name: 'OTHER',
            lastSeen: now.subtract(const Duration(minutes: 4)),
          ),
        ]);

        expect(groups, hasLength(1));
        expect(groups.first.label, 'SI-');
        expect(groups.first.contacts.map((contact) => contact.displayName), [
          'SI-1',
          'SI-2',
          'SI-3',
          'SI-4',
        ]);
      },
    );

    test('does not group when only three contacts share a prefix', () {
      final now = DateTime(2026, 3, 10, 12);
      final groups = ContactGrouping.inferGroups([
        buildContact(seed: 1, name: 'SI-1', lastSeen: now),
        buildContact(
          seed: 2,
          name: 'SI-2',
          lastSeen: now.subtract(const Duration(minutes: 1)),
        ),
        buildContact(
          seed: 3,
          name: 'SI-3',
          lastSeen: now.subtract(const Duration(minutes: 2)),
        ),
      ]);

      expect(groups, isEmpty);
    });

    test('orders groups by latest last seen', () {
      final now = DateTime(2026, 3, 10, 12);
      final groups = ContactGrouping.inferGroups([
        buildContact(seed: 2, name: 'SI-1', lastSeen: now),
        buildContact(
          seed: 3,
          name: 'SI-2',
          lastSeen: now.subtract(const Duration(minutes: 2)),
        ),
        buildContact(
          seed: 4,
          name: 'SI-3',
          lastSeen: now.subtract(const Duration(minutes: 3)),
        ),
        buildContact(
          seed: 5,
          name: 'SI-4',
          lastSeen: now.subtract(const Duration(minutes: 4)),
        ),
        buildContact(
          seed: 6,
          name: 'HR-1',
          lastSeen: now.subtract(const Duration(minutes: 1)),
        ),
        buildContact(
          seed: 7,
          name: 'HR-2',
          lastSeen: now.subtract(const Duration(minutes: 5)),
        ),
        buildContact(
          seed: 8,
          name: 'HR-3',
          lastSeen: now.subtract(const Duration(minutes: 6)),
        ),
        buildContact(
          seed: 9,
          name: 'HR-4',
          lastSeen: now.subtract(const Duration(minutes: 7)),
        ),
      ]);

      expect(groups, hasLength(2));
      expect(groups.first.label, 'SI-');
      expect(groups.last.label, 'HR-');
    });

    test('collapses extra auto-groups into a shared parent prefix', () {
      final now = DateTime(2026, 3, 10, 12);
      final groups = ContactGrouping.inferGroups(
        [
          buildContact(seed: 1, name: 'AL-1', lastSeen: now),
          buildContact(
            seed: 2,
            name: 'AL-2',
            lastSeen: now.subtract(const Duration(minutes: 1)),
          ),
          buildContact(
            seed: 3,
            name: 'AL-3',
            lastSeen: now.subtract(const Duration(minutes: 2)),
          ),
          buildContact(
            seed: 4,
            name: 'AL-4',
            lastSeen: now.subtract(const Duration(minutes: 3)),
          ),
          buildContact(
            seed: 5,
            name: 'BR-1',
            lastSeen: now.subtract(const Duration(minutes: 4)),
          ),
          buildContact(
            seed: 6,
            name: 'BR-2',
            lastSeen: now.subtract(const Duration(minutes: 5)),
          ),
          buildContact(
            seed: 7,
            name: 'BR-3',
            lastSeen: now.subtract(const Duration(minutes: 6)),
          ),
          buildContact(
            seed: 8,
            name: 'BR-4',
            lastSeen: now.subtract(const Duration(minutes: 7)),
          ),
          buildContact(
            seed: 9,
            name: 'HU-PE-1',
            lastSeen: now.subtract(const Duration(minutes: 8)),
          ),
          buildContact(
            seed: 10,
            name: 'HU-PE-2',
            lastSeen: now.subtract(const Duration(minutes: 9)),
          ),
          buildContact(
            seed: 11,
            name: 'HU-GA-1',
            lastSeen: now.subtract(const Duration(minutes: 10)),
          ),
          buildContact(
            seed: 12,
            name: 'HU-GA-2',
            lastSeen: now.subtract(const Duration(minutes: 11)),
          ),
          buildContact(
            seed: 13,
            name: 'HU-PE-3',
            lastSeen: now.subtract(const Duration(minutes: 12)),
          ),
          buildContact(
            seed: 14,
            name: 'HU-PE-4',
            lastSeen: now.subtract(const Duration(minutes: 13)),
          ),
          buildContact(
            seed: 15,
            name: 'HU-GA-3',
            lastSeen: now.subtract(const Duration(minutes: 14)),
          ),
          buildContact(
            seed: 16,
            name: 'HU-GA-4',
            lastSeen: now.subtract(const Duration(minutes: 15)),
          ),
        ],
        maxNamedGroups: 2,
        overflowGroupLabel: 'Others',
      );

      expect(groups, hasLength(3));
      expect(groups[0].label, 'AL-');
      expect(groups[1].label, 'BR-');
      expect(groups[2].label, 'HU-');
      expect(groups[2].contacts.map((contact) => contact.displayName), [
        'HU-PE-1',
        'HU-PE-2',
        'HU-GA-1',
        'HU-GA-2',
        'HU-PE-3',
        'HU-PE-4',
        'HU-GA-3',
        'HU-GA-4',
      ]);
      expect(groups[2].matchPrefixes, ['HU-']);
    });

    test(
      'does not create an Others bucket when overflow has no shared parent',
      () {
        final now = DateTime(2026, 3, 10, 12);
        final groups = ContactGrouping.inferGroups(
          [
            buildContact(seed: 1, name: 'AL-1', lastSeen: now),
            buildContact(
              seed: 2,
              name: 'AL-2',
              lastSeen: now.subtract(const Duration(minutes: 1)),
            ),
            buildContact(
              seed: 3,
              name: 'AL-3',
              lastSeen: now.subtract(const Duration(minutes: 2)),
            ),
            buildContact(
              seed: 4,
              name: 'AL-4',
              lastSeen: now.subtract(const Duration(minutes: 3)),
            ),
            buildContact(
              seed: 5,
              name: 'BR-1',
              lastSeen: now.subtract(const Duration(minutes: 4)),
            ),
            buildContact(
              seed: 6,
              name: 'BR-2',
              lastSeen: now.subtract(const Duration(minutes: 5)),
            ),
            buildContact(
              seed: 7,
              name: 'BR-3',
              lastSeen: now.subtract(const Duration(minutes: 6)),
            ),
            buildContact(
              seed: 8,
              name: 'BR-4',
              lastSeen: now.subtract(const Duration(minutes: 7)),
            ),
            buildContact(
              seed: 9,
              name: 'CR-1',
              lastSeen: now.subtract(const Duration(minutes: 8)),
            ),
            buildContact(
              seed: 10,
              name: 'CR-2',
              lastSeen: now.subtract(const Duration(minutes: 9)),
            ),
            buildContact(
              seed: 11,
              name: 'CR-3',
              lastSeen: now.subtract(const Duration(minutes: 10)),
            ),
            buildContact(
              seed: 12,
              name: 'CR-4',
              lastSeen: now.subtract(const Duration(minutes: 11)),
            ),
          ],
          maxNamedGroups: 2,
          overflowGroupLabel: 'Others',
        );

        expect(groups.map((group) => group.label), ['AL-', 'BR-', 'CR-']);
      },
    );
  });

  group('ContactGrouping.contactMatchesInferredGroupLabel', () {
    test('matches the inferred auto-group label for prefixed contacts', () {
      final contact = buildContact(
        seed: 99,
        name: 'SI-1',
        lastSeen: DateTime(2026, 3, 10, 12),
      );

      expect(
        ContactGrouping.contactMatchesInferredGroupLabel(contact, 'SI-'),
        isTrue,
      );
      expect(
        ContactGrouping.contactMatchesInferredGroupLabel(contact, 'si'),
        isTrue,
      );
    });

    test('returns false when a contact has no inferred auto-group label', () {
      final contact = buildContact(
        seed: 100,
        name: 'Lone Contact',
        lastSeen: DateTime(2026, 3, 10, 12),
      );

      expect(
        ContactGrouping.contactMatchesInferredGroupLabel(contact, 'SI'),
        isFalse,
      );
    });

    test('finds a shared inferred label for related repeater names', () {
      final contacts = [
        buildContact(
          seed: 101,
          name: 'HU-PE',
          lastSeen: DateTime(2026, 3, 10, 12),
        ),
        buildContact(
          seed: 102,
          name: 'HU-GA',
          lastSeen: DateTime(2026, 3, 10, 11, 59),
        ),
      ];

      expect(ContactGrouping.sharedInferredGroupLabel(contacts), 'HU-');
    });

    test('finds a shared parent label for related subgroup prefixes', () {
      expect(
        ContactGrouping.sharedParentGroupLabel(['HU-PE-', 'HU-GA-']),
        'HU-',
      );
      expect(ContactGrouping.sharedParentGroupLabel(['AL-', 'BR-']), isNull);
    });
  });
}
