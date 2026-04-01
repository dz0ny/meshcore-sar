import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/models/channel.dart';
import 'package:meshcore_sar_app/providers/channels_provider.dart';

void main() {
  group('ChannelsProvider device sync preparation', () {
    test('clears runtime channel state before sync', () {
      final provider = ChannelsProvider();

      provider.addOrUpdateChannel(
        index: 2,
        name: 'Ops',
        secret: Uint8List.fromList(List<int>.filled(16, 7)),
      );
      provider.selectChannel(2);

      provider.prepareForDeviceSync();

      expect(provider.channels, isEmpty);
      expect(provider.selectedChannelIndex, 0);
      expect(provider.selectedChannel, isNull);
    });
  });

  group('ChannelsProvider mesh hash lookup', () {
    test('resolves a unique channel display name by hash byte', () {
      final provider = ChannelsProvider();
      final channel = Channel.create(index: 3, name: '#ops');

      provider.addOrUpdateChannelObject(channel);

      expect(
        provider.getUniqueChannelDisplayNameByHashByte(channel.hashByte),
        '#ops',
      );
    });

    test('does not resolve ambiguous hash matches', () {
      final provider = ChannelsProvider();
      final secret = Uint8List.fromList(List<int>.filled(16, 7));
      final firstChannel = Channel.create(
        index: 1,
        name: 'Ops 1',
        explicitSecret: secret,
      );

      provider.addOrUpdateChannelObject(firstChannel);
      provider.addOrUpdateChannelObject(
        Channel.create(index: 2, name: 'Ops 2', explicitSecret: secret),
      );

      expect(
        provider.getUniqueChannelDisplayNameByHashByte(firstChannel.hashByte),
        isNull,
      );
    });
  });
}
