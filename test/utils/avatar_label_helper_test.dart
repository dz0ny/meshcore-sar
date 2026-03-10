import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/utils/avatar_label_helper.dart';

void main() {
  group('AvatarLabelHelper.buildLabel', () {
    test('returns two initials for multi-word names', () {
      expect(AvatarLabelHelper.buildLabel('John Smith'), 'JS');
    });

    test('returns first two characters for single-word names', () {
      expect(AvatarLabelHelper.buildLabel('Alpha'), 'AL');
    });

    test('allows three compact characters for hash-prefixed names', () {
      expect(AvatarLabelHelper.buildLabel('#ops'), '#OP');
    });

    test('removes spacing after hash-prefixed names', () {
      expect(AvatarLabelHelper.buildLabel('# foo alpha'), '#FO');
    });

    test('keeps non-hash labels at two characters', () {
      expect(AvatarLabelHelper.buildLabel('abc'), 'AB');
    });

    test('strips emoji when building fallback initials', () {
      expect(AvatarLabelHelper.buildLabel('Charlie 🙂 Delta'), 'CD');
    });

    test('strips leading emoji when building fallback initials', () {
      expect(AvatarLabelHelper.buildLabel('🙂 Charlie'), 'CH');
    });
  });
}
