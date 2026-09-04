import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../l10n/app_localizations.dart';
import '../providers/connection_provider.dart';
import 'toast_logger.dart';

enum AdvertMode { flood, direct }

Future<void> triggerAdvertFeedback(BuildContext context) async {
  final platform = Theme.of(context).platform;

  try {
    if (platform == TargetPlatform.iOS) {
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 50));
      await HapticFeedback.lightImpact();
    } else {
      if (await Vibration.hasVibrator()) {
        await Vibration.vibrate(duration: 50);
      } else {
        await HapticFeedback.mediumImpact();
      }
    }
  } catch (e) {
    debugPrint('Haptic feedback error: $e');
    await HapticFeedback.vibrate();
  }
}

Future<AdvertMode?> showAdvertModeSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context);

  return showModalBottomSheet<AdvertMode>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.advertMode,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.advertModeSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.hub_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              title: Text(l10n.flood),
              subtitle: Text(l10n.relayThroughRepeatersAcrossTheMesh),
              trailing: const Icon(Icons.chevron_right_rounded),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onTap: () => Navigator.of(context).pop(AdvertMode.flood),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.near_me_rounded,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
              title: Text(l10n.direct),
              subtitle: Text(l10n.nearbyOnlyWithoutRepeaterFlooding),
              trailing: const Icon(Icons.chevron_right_rounded),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onTap: () => Navigator.of(context).pop(AdvertMode.direct),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> advertiseDevice(
  BuildContext context, {
  bool floodMode = true,
}) async {
  final connectionProvider = context.read<ConnectionProvider>();

  if (!connectionProvider.deviceInfo.isConnected) {
    if (context.mounted) {
      ToastLogger.error(
        context,
        AppLocalizations.of(context)!.deviceNotConnected,
      );
    }
    return;
  }

  try {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        ToastLogger.error(
          context,
          AppLocalizations.of(context)!.locationServicesDisabled,
        );
      }
      return;
    }

    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted) {
          ToastLogger.error(
            context,
            AppLocalizations.of(context)!.locationPermissionDenied,
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        ToastLogger.error(
          context,
          AppLocalizations.of(context)!.locationPermissionPermanentlyDenied,
        );
      }
      return;
    }

    // Get current GPS position
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('❌ Failed to get GPS position: $e');
      if (context.mounted) {
        ToastLogger.error(
          context,
          AppLocalizations.of(context)!.failedToGetGpsLocation,
        );
      }
      return;
    }

    // Update lat/lon on device
    await connectionProvider.setAdvertLatLon(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    // Small delay to ensure the lat/lon is set
    await Future.delayed(const Duration(milliseconds: 100));

    await connectionProvider.sendSelfAdvert(floodMode: floodMode);

    if (context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      ToastLogger.success(
        context,
        floodMode ? l10n.floodAdvertSent : l10n.directAdvertSent,
      );
    }
  } catch (e) {
    debugPrint('❌ Failed to advertise device: $e');
    if (context.mounted) {
      ToastLogger.error(
        context,
        AppLocalizations.of(context)!.failedToAdvertise(e.toString()),
      );
    }
  }
}
