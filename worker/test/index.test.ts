import { describe, expect, test } from 'bun:test';

import {
  REPORT_INSERT_SQL,
  buildWindowFilter,
  createEmptyCounts,
  extractCfGeo,
  loadDashboardSummary,
  summarizeRows,
  validateIngestPayload,
} from '../worker/stats';

describe('validateIngestPayload', () => {
  test('accepts a complete payload with fixed columns', () => {
    const counts = createEmptyCounts();
    counts.pt_04 = 12;
    counts.path_mode_2b = 4;

    const payload = validateIngestPayload({
      reportId: 'a1b2c3d4e5f6:2026-04-03T10:00:00.000Z',
      deviceKey6: 'a1b2c3d4e5f6',
      windowStart: '2026-04-03T10:00:00.000Z',
      windowEnd: '2026-04-03T10:05:00.000Z',
      appVersion: '2026.0402.1+44',
      counts,
    });

    expect(payload.counts.pt_04).toBe(12);
    expect(payload.counts.path_mode_2b).toBe(4);
  });

  test('rejects missing fixed count keys', () => {
    expect(() =>
      validateIngestPayload({
        reportId: 'a1b2c3d4e5f6:2026-04-03T10:00:00.000Z',
        deviceKey6: 'a1b2c3d4e5f6',
        windowStart: '2026-04-03T10:00:00.000Z',
        windowEnd: '2026-04-03T10:05:00.000Z',
        appVersion: '2026.0402.1+44',
        counts: {},
      }),
    ).toThrow('counts.pt_00 must be a number.');
  });
});

describe('worker helpers', () => {
  test('uses insert-or-ignore semantics for idempotent reports', () => {
    expect(REPORT_INSERT_SQL).toContain('INSERT OR IGNORE INTO reports');
  });

  test('extractCfGeo reads Cloudflare request metadata', () => {
    const request = new Request('https://example.com/') as Request & {
      cf?: Record<string, unknown>;
    };
    request.cf = {
      country: 'SI',
      region: 'Ljubljana',
      city: 'Ljubljana',
      latitude: '46.0569',
      longitude: '14.5058',
      colo: 'LJU',
    };

    const geo = extractCfGeo(request);

    expect(geo.country).toBe('SI');
    expect(geo.latitude).toBe(46.0569);
    expect(geo.longitude).toBe(14.5058);
    expect(geo.colo).toBe('LJU');
  });

  test('summarizeRows aggregates packet and path mode totals', () => {
    const filter = buildWindowFilter('24h', new Date('2026-04-03T12:00:00.000Z'));
    const rows = [
      {
        ...createEmptyCounts(),
        report_id: 'a1',
        device_key6: 'a1b2c3d4e5f6',
        window_start: '2026-04-03T10:00:00.000Z',
        window_end: '2026-04-03T10:05:00.000Z',
        received_at: '2026-04-03T10:05:03.000Z',
        app_version: '2026.0402.1+44',
        cf_country: 'SI',
        cf_region: 'Ljubljana',
        cf_city: 'Ljubljana',
        cf_latitude: 46.0569,
        cf_longitude: 14.5058,
        cf_colo: 'LJU',
        pt_04: 12,
        path_mode_2b: 12,
      },
      {
        ...createEmptyCounts(),
        report_id: 'a2',
        device_key6: '001122334455',
        window_start: '2026-04-03T11:00:00.000Z',
        window_end: '2026-04-03T11:05:00.000Z',
        received_at: '2026-04-03T11:05:02.000Z',
        app_version: '2026.0402.1+44',
        cf_country: 'DE',
        cf_region: 'Berlin',
        cf_city: 'Berlin',
        cf_latitude: 52.52,
        cf_longitude: 13.405,
        cf_colo: 'FRA',
        pt_05: 3,
        decode_fail: 1,
        path_mode_none: 1,
        path_mode_3b: 2,
      },
    ];

    const summary = summarizeRows(rows, filter);

    expect(summary.reportCount).toBe(2);
    expect(summary.uniqueDevices).toBe(2);
    expect(summary.decodedPackets).toBe(15);
    expect(summary.decodeFailures).toBe(1);
    expect(summary.pathModeTotals[0]?.total).toBe(12);
    expect(summary.locationPoints).toHaveLength(2);
  });

  test('loadDashboardSummary reads D1 rows for the selected window', async () => {
    const rows = [
      {
        ...createEmptyCounts(),
        report_id: 'a1',
        device_key6: 'a1b2c3d4e5f6',
        window_start: '2026-04-03T10:00:00.000Z',
        window_end: '2026-04-03T10:05:00.000Z',
        received_at: '2026-04-03T10:05:03.000Z',
        app_version: '2026.0402.1+44',
        cf_country: 'SI',
        cf_region: 'Ljubljana',
        cf_city: 'Ljubljana',
        cf_latitude: 46.0569,
        cf_longitude: 14.5058,
        cf_colo: 'LJU',
        pt_04: 5,
      },
    ];

    const env = {
      DB: {
        prepare() {
          return {
            bind() {
              return {
                async all() {
                  return { results: rows };
                },
              };
            },
          };
        },
      },
    } as any;

    const summary = await loadDashboardSummary(
      env,
      '24h',
      new Date('2026-04-03T12:00:00.000Z'),
    );

    expect(summary.reportCount).toBe(1);
    expect(summary.packetTypeTotals[0]?.key).toBe('pt_04');
    expect(summary.packetTypeTotals[0]?.total).toBe(5);
  });
});
