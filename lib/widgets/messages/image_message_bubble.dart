import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:provider/provider.dart';
import '../../models/contact.dart';
import '../../models/message.dart';
import '../../providers/connection_provider.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/image_provider.dart' as ip;
import '../../utils/image_message_parser.dart';
import 'transfer_timeout.dart';

/// A message bubble that shows a received or sent image.
///
/// On first render the image is not yet fetched (only the IE2 envelope is
/// known).  The user taps the thumbnail placeholder → IR2 fetch request is
/// sent → binary fragments stream in → bubble rebuilds with the full image.
class ImageMessageBubble extends StatefulWidget {
  final Message message;
  final bool isSentByMe;

  const ImageMessageBubble({
    super.key,
    required this.message,
    required this.isSentByMe,
  });

  @override
  State<ImageMessageBubble> createState() => _ImageMessageBubbleState();
}

class _ImageMessageBubbleState extends State<ImageMessageBubble> {
  static const int _maxFetchHops = 3;
  bool _isRequesting = false;
  String? _errorText;
  Timer? _requestTimeoutTimer;

  @override
  void dispose() {
    _requestTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radioBw = context.select<ConnectionProvider, int?>(
      (p) => p.deviceInfo.radioBw,
    );
    final radioSf = context.select<ConnectionProvider, int?>(
      (p) => p.deviceInfo.radioSf,
    );
    final radioCr = context.select<ConnectionProvider, int?>(
      (p) => p.deviceInfo.radioCr,
    );
    final envelope = ImageEnvelope.tryParse(widget.message.text);
    if (envelope == null) return const SizedBox.shrink();

    return Consumer<ip.ImageProvider>(
      builder: (context, imageProvider, _) {
        final session = imageProvider.session(envelope.sessionId);
        final sender = _resolveSender(envelope);
        final effectivePathLen =
            sender != null && sender.outPathLen >= 0
            ? sender.outPathLen
            : widget.message.pathLen;
        final isComplete = imageProvider.isComplete(envelope.sessionId);
        final eta = imageProvider.estimateRemainingTransferTime(
          envelope.sessionId,
        );

        if (_isRequesting && isComplete) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _isRequesting = false);
          });
        }

        final received = session?.receivedCount ?? 0;
        final total = session?.total ?? envelope.total;
        final imageBytes = isComplete ? session?.imageBytes : null;

        return GestureDetector(
          onTap: isComplete
              ? () => _showFullScreen(context, imageBytes!)
              : null,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 256),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image area: 256×256 placeholder or actual image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImageArea(
                    context,
                    imageBytes: imageBytes,
                    isComplete: isComplete,
                    isRequesting: _isRequesting,
                    received: received,
                    total: total,
                    envelope: envelope,
                    radioBw: radioBw,
                    radioSf: radioSf,
                    radioCr: radioCr,
                    pathLen: effectivePathLen,
                  ),
                ),
                const SizedBox(height: 4),
                // Status line
                Text(
                  _statusText(
                    isComplete: isComplete,
                    isRequesting: _isRequesting,
                    received: received,
                    total: total,
                    envelope: envelope,
                    radioBw: radioBw,
                    radioSf: radioSf,
                    radioCr: radioCr,
                    error: _errorText,
                    isSentByMe: widget.isSentByMe,
                    eta: eta,
                    pathLen: effectivePathLen,
                  ),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageArea(
    BuildContext context, {
    required Uint8List? imageBytes,
    required bool isComplete,
    required bool isRequesting,
    required int received,
    required int total,
    required ImageEnvelope envelope,
    required int? radioBw,
    required int? radioSf,
    required int? radioCr,
    required int pathLen,
  }) {
    if (isComplete && imageBytes != null) {
      return AspectRatio(
        aspectRatio: 1.0,
        child: AvifImage.memory(imageBytes, fit: BoxFit.cover),
      );
    }

    // Placeholder with fetch/progress UI.
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        color: Colors.grey.shade800,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isRequesting) ...[
              // Download progress ring.
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: total > 0 ? received / total : null,
                  strokeWidth: 3,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                '$received/$total',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ] else if (_errorText != null) ...[
              const Icon(Icons.broken_image, color: Colors.red, size: 36),
            ] else ...[
              // Tap-to-load icon.
              IconButton(
                onPressed: () => _requestAndFetch(
                  envelope,
                  radioBw: radioBw,
                  radioSf: radioSf,
                  radioCr: radioCr,
                  pathLen: pathLen,
                ),
                icon: const Icon(Icons.download_rounded, size: 40),
                color: Colors.white70,
                tooltip: 'Load image',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _requestAndFetch(
    ImageEnvelope envelope, {
    int? radioBw,
    int? radioSf,
    int? radioCr,
    int pathLen = 0,
  }) async {
    if (_isRequesting) return;
    final conn = context.read<ConnectionProvider>();
    var sender = _resolveSender(envelope);
    if (sender == null ||
        sender.outPathLen < 0 ||
        sender.outPathLen > _maxFetchHops) {
      await conn.getContacts();
      if (!mounted) return;
      sender = _resolveSender(envelope);
    }
    if (sender == null) {
      await _showBlockingAlert(
        'Cannot fetch image',
        'Sender contact is unknown. Sync contacts first.',
      );
      return;
    }
    if (sender.outPathLen < 0) {
      await _showBlockingAlert(
        'Cannot fetch image',
        'Sender route is unknown. Sync contacts/path first.',
      );
      return;
    }
    if (sender.outPathLen > _maxFetchHops) {
      await _showBlockingAlert(
        'Cannot fetch image',
        'Message is too far (${sender.outPathLen} hops, max $_maxFetchHops).',
      );
      return;
    }
    if (sender.outPathLen >= 2) {
      _showToast(
        'Image fetch over ${sender.outPathLen} hops may take a while.',
      );
    }

    setState(() => _errorText = null);
    final imageProvider = context.read<ip.ImageProvider>();
    final deviceKey = conn.deviceInfo.publicKey;
    if (deviceKey == null || deviceKey.length < 6) {
      await _showBlockingAlert(
        'Cannot fetch image',
        'Device key is unavailable.',
      );
      return;
    }

    final requesterKey6 = deviceKey
        .sublist(0, 6)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    // If we already have some fragments, request only what's missing.
    final missing = imageProvider.missingFragmentIndices(envelope.sessionId);
    final isPartialResume =
        missing.isNotEmpty && missing.length < envelope.total;
    final request = isPartialResume
        ? ImageFetchRequest(
            sessionId: envelope.sessionId,
            want: 'missing',
            missingIndices: missing,
            requesterKey6: requesterKey6,
            timestampSec: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          )
        : ImageFetchRequest(
            sessionId: envelope.sessionId,
            requesterKey6: requesterKey6,
            timestampSec: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          );

    setState(() {
      _isRequesting = true;
      _errorText = null;
    });

    final payload = request.encodeBinary();
    try {
      await conn.sendRawVoicePacket(
        contactPath: sender.outPath,
        contactPathLen: sender.outPathLen,
        payload: payload,
      );
    } catch (_) {
      if (mounted) {
        _showToast('Image fetch failed to send request');
        setState(() {
          _isRequesting = false;
          _errorText = 'Image unavailable right now';
        });
      }
      return;
    }
    if (!mounted) return;

    // Timeout = 2× estimated LoRa airtime (min 30s).
    final effectivePathLen = sender.outPathLen >= 0 ? sender.outPathLen : pathLen;
    final txEstimate = estimateImageTransmitDuration(
      fragmentCount: missing.isEmpty ? envelope.total : missing.length,
      sizeBytes: missing.isEmpty
          ? envelope.sizeBytes
          : (envelope.sizeBytes * missing.length / envelope.total).round(),
      pathLen: effectivePathLen,
      radioBw: radioBw,
      radioSf: radioSf,
      radioCr: radioCr,
    );
    _requestTimeoutTimer?.cancel();
    _requestTimeoutTimer = TransferTimeout.start(
      txEstimate: txEstimate,
      onTimeout: () {
        if (mounted &&
            _isRequesting &&
            !imageProvider.isComplete(envelope.sessionId)) {
          _showToast('Image fetch timed out');
          setState(() {
            _isRequesting = false;
            _errorText = 'Image fetch timed out';
          });
        }
      },
    );
  }

  Contact? _resolveSender(ImageEnvelope envelope) {
    final contactsProvider = context.read<ContactsProvider>();

    // For sent direct messages, fetch must target the recipient peer first.
    final recipientKey = widget.message.recipientPublicKey;
    if (widget.isSentByMe && recipientKey != null && recipientKey.isNotEmpty) {
      final byKey = contactsProvider.findContactByKey(recipientKey);
      if (byKey != null) return byKey;
      if (recipientKey.length >= 6) {
        final byPrefix = contactsProvider.findContactByPrefix(
          Uint8List.fromList(recipientKey.sublist(0, 6)),
        );
        if (byPrefix != null) return byPrefix;
      }
    }

    final senderPrefix = widget.message.senderPublicKeyPrefix;
    if (senderPrefix != null && senderPrefix.length >= 6) {
      final c = contactsProvider.findContactByPrefix(
        Uint8List.fromList(senderPrefix.sublist(0, 6)),
      );
      if (c != null) return c;
    }
    final contact = contactsProvider.findContactByPrefixHex(
      envelope.senderKey6,
    );
    if (contact != null) return contact;

    final senderName = widget.message.senderName?.trim();
    if (senderName != null && senderName.isNotEmpty) {
      for (final c in contactsProvider.contacts) {
        if (c.advName.trim().toLowerCase() == senderName.toLowerCase()) {
          return c;
        }
      }
    }

    return null;
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  Future<void> _showBlockingAlert(String title, String message) async {
    if (!mounted) return;
    _showToast('$title: $message');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static String _statusText({
    required bool isComplete,
    required bool isRequesting,
    required int received,
    required int total,
    required ImageEnvelope envelope,
    required int pathLen,
    required int? radioBw,
    required int? radioSf,
    required int? radioCr,
    required String? error,
    required bool isSentByMe,
    required Duration? eta,
  }) {
    final txEstimate = estimateImageTransmitDuration(
      fragmentCount: envelope.total,
      sizeBytes: envelope.sizeBytes,
      pathLen: pathLen,
      radioBw: radioBw,
      radioSf: radioSf,
      radioCr: radioCr,
    );
    final txEstimateLabel = _formatTransmitEstimate(txEstimate);

    if (error != null) return error;
    if (isRequesting) {
      final etaLabel = _formatEta(eta);
      return '📥 Loading… $received/$total · $etaLabel · $txEstimateLabel';
    }
    if (isComplete) {
      final base =
          '🖼️ ${envelope.width}×${envelope.height} ${envelope.format.label}';
      return isSentByMe
          ? '$base · ${envelope.total} seg · $txEstimateLabel'
          : '$base · $txEstimateLabel';
    }
    return '🖼️ Tap to load · ${envelope.width}×${envelope.height} · $txEstimateLabel';
  }

  static String _formatTransmitEstimate(Duration value) {
    if (value.inSeconds < 60) return '~${value.inSeconds}s tx';
    final minutes = value.inMinutes;
    final seconds = value.inSeconds % 60;
    return '~${minutes}m ${seconds}s tx';
  }

  static String _formatEta(Duration? eta) {
    if (eta == null || eta <= Duration.zero) return 'ETA --';
    if (eta.inSeconds < 60) return 'ETA ~${eta.inSeconds}s';
    final minutes = eta.inMinutes;
    final seconds = eta.inSeconds % 60;
    return 'ETA ~${minutes}m ${seconds}s';
  }

  void _showFullScreen(BuildContext context, Uint8List imageBytes) {
    showGeneralDialog<void>(
      context: context,
      barrierColor: Colors.black,
      barrierDismissible: true,
      barrierLabel: 'Close image preview',
      pageBuilder: (dialogContext, animation, secondaryAnimation) => Material(
        color: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 1000.0,
                clipBehavior: Clip.none,
                boundaryMargin: const EdgeInsets.all(100000),
                child: SizedBox.expand(
                  child: AvifImage.memory(imageBytes, fit: BoxFit.cover),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: IconButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close),
                  color: Colors.white,
                  tooltip: 'Close',
                ),
              ),
            ),
          ],
        ),
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 150),
    );
  }
}
