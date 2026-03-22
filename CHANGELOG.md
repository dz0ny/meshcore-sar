# Changelog

## 2026-03-15 to 2026-03-22

- Device connectivity and routing: added Android USB serial companion support, serial compass support, GPS module controls, per-contact path size selection, and favourites support via firmware flags.
- Location and map intelligence: added RSSI-based repeater trilateration and contact location estimates, isolated MET history, matched the official advert import/discovery flow, and refreshed map presentation by removing contact trails.
- Telemetry and device info: surfaced self telemetry and sensor defaults, opened device info from signal and battery taps, improved signal chip behavior, fixed duplicate telemetry delivery, and restored telemetry refresh behavior.
- Contacts and messaging: added meshcore:// contact sharing and repeater neighbour views, supported MeshCore message links, fixed DM retry behavior, corrected room poster naming, and compacted the recipient selector.
- UI polish and platform upkeep: improved device settings layout, tightened sensor and contact presentation, expanded localization coverage, and refreshed platform dependencies and build numbers.

## Key PRs

- [#26](https://github.com/dz0ny/meshcore-sar/pull/26) Merge pull request #26 from `dz0ny/feat/sensor-telemetry-preview`

## 2026-03-08 to 2026-03-14

- Discovery and contacts: finished the discovery flow, removed artificial UI delays, added profile storage and sync, and allowed contact name overrides.
- Messaging and channels: fixed channel sync, deduplication, overwrite and deletion issues, cleared message input after send, and added delayed-message warning tracking.
- Voice and transport: improved voice playback quality, improved scan and advert parsing, and kept route path data visible in logs.
- Maps and field operations: enabled iOS background GPS updates, added GPX trail import/export, introduced a fullscreen repeater map, and added live mesh traffic views.
- Localization and UI polish: added multilingual localization coverage, updated locale strings, fixed onboarding layout issues, and refined channel and contacts presentation.

## Key PRs

- [#16](https://github.com/dz0ny/meshcore-sar/pull/16) Merge pull request #16 from `MGJ520/main`
