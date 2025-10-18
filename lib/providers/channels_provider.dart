import 'package:flutter/foundation.dart';
import '../models/channel.dart';

/// Manages channel information from the MeshCore device
class ChannelsProvider with ChangeNotifier {
  final Map<int, Channel> _channels = {};

  /// Get all channels
  List<Channel> get channels => _channels.values.toList()..sort((a, b) => a.index.compareTo(b.index));

  /// Get a specific channel by index
  Channel? getChannel(int index) => _channels[index];

  /// Get the display name for a channel
  String getChannelDisplayName(int index) {
    final channel = _channels[index];
    if (channel != null) {
      return channel.displayName;
    }
    // Fallback if channel hasn't been synced yet
    return index == 0 ? 'Public' : 'Channel $index';
  }

  /// Add or update a channel
  void addOrUpdateChannel(int index, String name, {int? flags}) {
    _channels[index] = Channel(
      index: index,
      name: name,
      flags: flags,
    );
    notifyListeners();
  }

  /// Clear all channels
  void clear() {
    _channels.clear();
    notifyListeners();
  }

  /// Check if channels have been loaded
  bool get hasChannels => _channels.isNotEmpty;

  /// Get the number of channels
  int get channelCount => _channels.length;

  @override
  void dispose() {
    _channels.clear();
    super.dispose();
  }
}
