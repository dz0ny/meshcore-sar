export 'package:meshcore_client/meshcore_client.dart'
    show Contact, ContactType, ContactTelemetry, AdvertLocation;

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:meshcore_client/meshcore_client.dart';

extension ContactLocalization on Contact {
  /// Returns the localized display name for special contacts (e.g. Public Channel).
  /// For all other contacts, returns [displayName].
  String getLocalizedDisplayName(BuildContext context) {
    if (isPublicChannel) {
      return AppLocalizations.of(context)!.publicChannel;
    }
    return displayName;
  }
}
