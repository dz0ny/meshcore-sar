import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/l10n/app_localizations.dart';
import 'package:meshcore_sar_app/models/message.dart';
import 'package:meshcore_sar_app/providers/app_provider.dart';
import 'package:meshcore_sar_app/providers/channels_provider.dart';
import 'package:meshcore_sar_app/providers/connection_provider.dart';
import 'package:meshcore_sar_app/providers/contacts_provider.dart';
import 'package:meshcore_sar_app/providers/drawing_provider.dart';
import 'package:meshcore_sar_app/providers/image_provider.dart' as ip;
import 'package:meshcore_sar_app/providers/messages_provider.dart';
import 'package:meshcore_sar_app/providers/voice_provider.dart';
import 'package:meshcore_sar_app/services/voice_codec_service.dart';
import 'package:meshcore_sar_app/services/voice_player_service.dart';
import 'package:meshcore_sar_app/widgets/messages/message_bubble.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('received bubbles show signal chips on double tap', (
    tester,
  ) async {
    final harness = await _TestHarness.create();
    try {
      final message = Message(
        id: 'received-signal',
        messageType: MessageType.contact,
        senderPublicKeyPrefix: _prefix(1),
        pathLen: 1,
        textType: MessageTextType.plain,
        senderTimestamp: 1700000000,
        text: 'Inbound message',
        receivedAt: DateTime.fromMillisecondsSinceEpoch(1700000000500),
        deliveryStatus: MessageDeliveryStatus.received,
        lastEchoRssiDbm: -84,
        lastEchoSnrRaw: 24,
      );

      await tester.pumpWidget(_buildApp(harness, message));
      await tester.pump(const Duration(milliseconds: 60));

      expect(find.text('1 hop'), findsNothing);
      expect(find.text('Fair'), findsNothing);
      expect(find.text('-84'), findsNothing);
      expect(find.text('6.0'), findsNothing);

      await tester.tap(find.text('Inbound message'));
      await tester.pump(kDoubleTapTimeout);

      expect(find.text('1 hop'), findsNothing);
      expect(find.text('-84'), findsNothing);

      await _doubleTap(tester, find.text('Inbound message'));

      expect(find.text('1 hop'), findsOneWidget);
      expect(find.text('Fair'), findsOneWidget);
      expect(find.text('-84'), findsOneWidget);
      expect(find.text('6.0'), findsOneWidget);
    } finally {
      await _disposeHarness(tester, harness);
    }
  });

  testWidgets('delivered direct bubbles show timing chips on double tap', (
    tester,
  ) async {
    final harness = await _TestHarness.create();
    try {
      final message = Message(
        id: 'sent-direct-signal',
        messageType: MessageType.contact,
        senderPublicKeyPrefix: _prefix(11),
        recipientPublicKey: _key(77),
        pathLen: 0,
        textType: MessageTextType.plain,
        senderTimestamp: 1700000000,
        text: 'Outbound message',
        receivedAt: DateTime.fromMillisecondsSinceEpoch(1700000000500),
        deliveryStatus: MessageDeliveryStatus.delivered,
        roundTripTimeMs: 320,
      );

      await tester.pumpWidget(_buildApp(harness, message));
      await tester.pump(const Duration(milliseconds: 60));

      expect(find.text('Direct'), findsNothing);
      expect(find.text('320ms'), findsNothing);

      await tester.tap(find.text('Outbound message'));
      await tester.pump(kDoubleTapTimeout);

      expect(find.text('Direct'), findsNothing);
      expect(find.text('320ms'), findsNothing);

      await _doubleTap(tester, find.text('Outbound message'));

      expect(find.text('Direct'), findsOneWidget);
      expect(find.text('320ms'), findsOneWidget);
    } finally {
      await _disposeHarness(tester, harness);
    }
  });

  testWidgets('sent channel bubbles show echo chips on double tap', (
    tester,
  ) async {
    final harness = await _TestHarness.create();
    try {
      final message = Message(
        id: 'sent-channel-signal',
        messageType: MessageType.channel,
        senderPublicKeyPrefix: _prefix(21),
        channelIdx: 0,
        pathLen: 0,
        textType: MessageTextType.plain,
        senderTimestamp: 1700000000,
        text: 'Broadcast message',
        receivedAt: DateTime.fromMillisecondsSinceEpoch(1700000000500),
        deliveryStatus: MessageDeliveryStatus.sent,
        echoCount: 2,
        lastEchoRssiDbm: -76,
        lastEchoSnrRaw: 20,
      );

      await tester.pumpWidget(_buildApp(harness, message));
      await tester.pump(const Duration(milliseconds: 60));

      expect(find.text('x2'), findsNothing);
      expect(find.text('-76'), findsNothing);
      expect(find.text('5.0'), findsNothing);

      await tester.tap(find.text('Broadcast message'));
      await tester.pump(kDoubleTapTimeout);

      expect(find.text('x2'), findsNothing);
      expect(find.text('-76'), findsNothing);

      await _doubleTap(tester, find.text('Broadcast message'));

      expect(find.text('x2'), findsOneWidget);
      expect(find.text('-76'), findsOneWidget);
      expect(find.text('5.0'), findsOneWidget);
    } finally {
      await _disposeHarness(tester, harness);
    }
  });
}

Widget _buildApp(_TestHarness harness, Message message) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: harness.connectionProvider),
      ChangeNotifierProvider.value(value: harness.contactsProvider),
      ChangeNotifierProvider.value(value: harness.messagesProvider),
      ChangeNotifierProvider.value(value: harness.drawingProvider),
      ChangeNotifierProvider.value(value: harness.channelsProvider),
      ChangeNotifierProvider.value(value: harness.voiceProvider),
      ChangeNotifierProvider.value(value: harness.imageProvider),
      ChangeNotifierProvider.value(value: harness.appProvider),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: MessageBubble(message: message)),
    ),
  );
}

class _TestHarness {
  final connectionProvider = ConnectionProvider();
  final contactsProvider = ContactsProvider();
  final messagesProvider = MessagesProvider();
  final drawingProvider = DrawingProvider();
  final channelsProvider = ChannelsProvider()..initializePublicChannel();
  final voiceProvider = VoiceProvider(
    codec: VoiceCodecService(),
    player: VoicePlayerService(),
  );
  final imageProvider = ip.ImageProvider();

  late final AppProvider appProvider;

  static Future<_TestHarness> create() async {
    final harness = _TestHarness();
    await harness.messagesProvider.initialize();
    await harness.drawingProvider.initialize();
    harness.appProvider = AppProvider(
      connectionProvider: harness.connectionProvider,
      contactsProvider: harness.contactsProvider,
      messagesProvider: harness.messagesProvider,
      drawingProvider: harness.drawingProvider,
      channelsProvider: harness.channelsProvider,
      voiceProvider: harness.voiceProvider,
      imageProvider: harness.imageProvider,
    );
    return harness;
  }

  bool _isDisposed = false;

  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    appProvider.dispose();
    voiceProvider.dispose();
    imageProvider.dispose();
    drawingProvider.dispose();
    messagesProvider.dispose();
    contactsProvider.dispose();
    connectionProvider.dispose();
    channelsProvider.dispose();
  }
}

Uint8List _prefix(int seed) =>
    Uint8List.fromList(List<int>.generate(6, (index) => seed + index));

Uint8List _key(int seed) =>
    Uint8List.fromList(List<int>.generate(32, (index) => seed + index));

Future<void> _disposeHarness(WidgetTester tester, _TestHarness harness) async {
  await tester.pump(kDoubleTapTimeout);
  await tester.pumpWidget(const SizedBox.shrink());
  harness.dispose();
  await tester.pump();
}

Future<void> _doubleTap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump(kDoubleTapMinTime);
  await tester.tap(finder);
  await tester.pump();
}
