import { useEffect, useMemo, useState } from "react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

type WindowKey = "24h" | "7d" | "30d";

type PacketTypeEntry = {
  key: string;
  label: string;
  total: number;
};

type PathModeEntry = {
  key: string;
  label: string;
  total: number;
};

type ReporterSummary = {
  key6: string;
  lastSeen: string;
  packetTotal: number;
  country: string;
  city: string;
  latitude: number | null;
  longitude: number | null;
};

type ChartPoint = {
  label: string;
  totalPackets: number;
  reports: number;
};

type LocationPoint = {
  key6: string;
  city: string;
  country: string;
  latitude: number;
  longitude: number;
};

type DashboardResponse = {
  generatedAt: string;
  filter: {
    windowKey: WindowKey;
    label: string;
    sinceIso: string;
    bucket: "hour" | "day";
  };
  reportCount: number;
  uniqueDevices: number;
  decodedPackets: number;
  decodeFailures: number;
  packetTypeTotals: PacketTypeEntry[];
  pathModeTotals: PathModeEntry[];
  recentReporters: ReporterSummary[];
  chartPoints: ChartPoint[];
  locationPoints: LocationPoint[];
};

const WINDOW_OPTIONS: Array<{ key: WindowKey; label: string }> = [
  { key: "24h", label: "24h" },
  { key: "7d", label: "7 days" },
  { key: "30d", label: "30 days" },
];

const PACKET_TYPE_INFO: Record<string, { title: string; summary: string }> = {
  pt_00: { title: "FLOOD REQUEST", summary: "Encrypted request to a known peer" },
  pt_01: { title: "FLOOD RESPONSE", summary: "Encrypted reply to a request" },
  pt_02: { title: "FLOOD TEXT", summary: "Encrypted direct text with timestamp and retry flags" },
  pt_03: { title: "FLOOD ACK", summary: "4-byte acknowledgement for an earlier message" },
  pt_04: { title: "FLOOD ADVERTISEMENT", summary: "Signed node identity broadcast" },
  pt_05: { title: "FLOOD GROUP_TEXT", summary: "Encrypted channel text matched by channel hash" },
  pt_06: { title: "FLOOD GROUP_DATA", summary: "Encrypted channel data with type and length" },
  pt_07: { title: "FLOOD ANON_REQUEST", summary: "Request using an ephemeral sender key" },
  pt_08: { title: "FLOOD RETURNED_PATH", summary: "Return route back to sender, with optional bundled ACK" },
  pt_09: { title: "FLOOD TRACE_PATH", summary: "Direct trace that records SNR at each hop" },
  pt_0a: { title: "FLOOD MULTIPART", summary: "Wrapper for one packet in a multipart sequence" },
  pt_0b: { title: "FLOOD CONTROL", summary: "Discovery or other control data" },
  pt_0c: { title: "RESERVED 0x0C", summary: "Reserved protocol type" },
  pt_0d: { title: "RESERVED 0x0D", summary: "Reserved protocol type" },
  pt_0e: { title: "RESERVED 0x0E", summary: "Reserved protocol type" },
  pt_0f: { title: "RAW CUSTOM", summary: "Application-defined custom packet" },
};

const PATH_MODE_ICONS: Record<string, string> = {
  path_mode_1b: "1B",
  path_mode_2b: "2B",
  path_mode_3b: "3B",
  path_mode_none: "--",
  path_mode_unknown: "??",
};

export function DashboardShell() {
  const [windowKey, setWindowKey] = useState<WindowKey>("24h");
  const [summary, setSummary] = useState<DashboardResponse | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let isCancelled = false;

    async function load() {
      setIsLoading(true);
      setError(null);
      try {
        const response = await fetch(`/api/dashboard?window=${windowKey}`, {
          headers: { accept: "application/json" },
        });
        if (!response.ok) {
          throw new Error(`Dashboard request failed (${response.status})`);
        }
        const nextSummary = (await response.json()) as DashboardResponse;
        if (!isCancelled) setSummary(nextSummary);
      } catch (nextError) {
        if (!isCancelled) {
          setError(nextError instanceof Error ? nextError.message : String(nextError));
        }
      } finally {
        if (!isCancelled) setIsLoading(false);
      }
    }

    void load();
    return () => { isCancelled = true; };
  }, [windowKey]);

  const activePacketTypes = useMemo(
    () => (summary?.packetTypeTotals ?? []).filter((e) => e.total > 0),
    [summary],
  );
  const activePathModes = useMemo(
    () => (summary?.pathModeTotals ?? []).filter((e) => e.total > 0),
    [summary],
  );
  const totalPackets = useMemo(
    () => (summary ? summary.decodedPackets + summary.decodeFailures : 0),
    [summary],
  );
  const decodeRate = totalPackets > 0
    ? ((summary!.decodedPackets / totalPackets) * 100).toFixed(1)
    : "0";
  const maxTrend = Math.max(...(summary?.chartPoints ?? []).map((p) => p.totalPackets), 1);

  return (
    <div className="mx-auto max-w-[1320px] px-5 py-8">
      <Tabs value={windowKey} onValueChange={(v) => setWindowKey(v as WindowKey)}>
        {/* Header */}
        <header className="mb-8 flex flex-wrap items-end justify-between gap-4">
          <div className="space-y-2">
            <div className="flex items-center gap-2">
              <span className="inline-flex h-8 w-8 items-center justify-center rounded-lg bg-primary text-sm font-bold text-primary-foreground">M</span>
              <h1 className="text-2xl font-semibold tracking-tight">MeshCore SAR</h1>
            </div>
            <p className="max-w-xl text-sm text-muted-foreground">
              Anonymous mesh network traffic overview. Location is derived from Cloudflare ingress metadata.
            </p>
          </div>
          <div className="flex items-center gap-3">
            <TabsList className="h-9 rounded-full bg-secondary/60 p-1">
              {WINDOW_OPTIONS.map((o) => (
                <TabsTrigger key={o.key} value={o.key} className="rounded-full px-4 text-xs">
                  {o.label}
                </TabsTrigger>
              ))}
            </TabsList>
            {summary && (
              <span className="text-xs text-muted-foreground">
                Updated {formatRelative(summary.generatedAt)}
              </span>
            )}
          </div>
        </header>

        {error && (
          <div className="mb-6 flex items-center gap-3 rounded-2xl border border-destructive/20 bg-destructive/10 px-5 py-3 text-sm text-destructive">
            <span className="flex-1">{error}</span>
            <Button size="sm" variant="outline" onClick={() => setWindowKey((c) => c)}>Retry</Button>
          </div>
        )}

        <TabsContent value={windowKey} className="space-y-6">
          {/* Key metrics */}
          <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <MetricCard
              label="Active Nodes"
              value={summary?.uniqueDevices ?? 0}
              note="Unique reporting nodes in this window"
            />
            <MetricCard
              label="Total Packets"
              value={totalPackets}
              note="All received packets (decoded + failed)"
            />
            <MetricCard
              label="Decode Rate"
              value={`${decodeRate}%`}
              note={`${summary?.decodedPackets ?? 0} decoded, ${summary?.decodeFailures ?? 0} failed`}
            />
            <MetricCard
              label="Packet Types"
              value={activePacketTypes.length}
              note={`of 16 protocol types observed`}
            />
          </section>

          {/* Map + Traffic trend */}
          <section className="grid gap-4 xl:grid-cols-[1.4fr_1fr]">
            <Card>
              <CardHeader>
                <CardTitle>Reporter Locations</CardTitle>
                <CardDescription>
                  Approximate locations from Cloudflare edge nodes, not device GPS.
                </CardDescription>
              </CardHeader>
              <CardContent>
                <ReporterMap locations={summary?.locationPoints ?? []} />
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Traffic Over Time</CardTitle>
                <CardDescription>Packets per {summary?.filter.bucket ?? "time"} bucket</CardDescription>
              </CardHeader>
              <CardContent>
                {isLoading && !summary ? (
                  <EmptyState label="Loading..." />
                ) : summary?.chartPoints.length ? (
                  <TrafficChart points={summary.chartPoints} maxValue={maxTrend} />
                ) : (
                  <EmptyState label="No data for this window." />
                )}
              </CardContent>
            </Card>
          </section>

          {/* Protocol breakdown */}
          <section className="grid gap-4 xl:grid-cols-[1.4fr_1fr]">
            <Card>
              <CardHeader>
                <CardTitle>Protocol Packet Types</CardTitle>
                <CardDescription>
                  MeshCore protocol uses 16 packet type codes (0x00 - 0x0F).
                  Showing types with traffic in this window.
                </CardDescription>
              </CardHeader>
              <CardContent>
                {activePacketTypes.length ? (
                  <div className="grid gap-2 sm:grid-cols-2">
                    {activePacketTypes.map((entry) => {
                      const pct = totalPackets > 0 ? ((entry.total / totalPackets) * 100).toFixed(1) : "0";
                      const info = PACKET_TYPE_INFO[entry.key];
                      return (
                        <div key={entry.key} className="flex gap-3 rounded-xl border border-border/50 bg-secondary/30 p-3">
                          <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-xs font-mono font-semibold text-primary">
                            {entry.key.replace("pt_", "0x").toUpperCase()}
                          </div>
                          <div className="min-w-0 flex-1">
                            <div className="flex items-baseline justify-between gap-2">
                              <span className="text-sm font-medium">{entry.label}</span>
                              <span className="shrink-0 text-xs text-muted-foreground">{pct}%</span>
                            </div>
                            <div className="mt-0.5 font-mono text-[0.65rem] text-muted-foreground/70">
                              {info?.title ?? entry.key}
                            </div>
                            <p className="mt-0.5 text-xs text-muted-foreground">
                              {info?.summary ?? ""}
                            </p>
                            <div className="mt-1.5 flex items-center gap-2">
                              <div className="h-1.5 flex-1 overflow-hidden rounded-full bg-secondary">
                                <div
                                  className="h-full rounded-full bg-primary/70"
                                  style={{ width: `${pct}%` }}
                                />
                              </div>
                              <span className="text-xs font-semibold tabular-nums">{entry.total.toLocaleString()}</span>
                            </div>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                ) : (
                  <EmptyState label="No packet data yet." />
                )}
              </CardContent>
            </Card>

            <div className="space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle>Path Routing Modes</CardTitle>
                  <CardDescription>
                    Path hash byte length determines routing precision.
                    Longer hashes allow more specific multi-hop paths.
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  {activePathModes.length ? (
                    <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
                      {activePathModes.map((entry) => {
                        const pct = totalPackets > 0 ? ((entry.total / totalPackets) * 100).toFixed(1) : "0";
                        return (
                          <div key={entry.key} className="rounded-xl border border-border/50 bg-secondary/30 p-4 text-center">
                            <div className="mx-auto mb-2 flex h-10 w-10 items-center justify-center rounded-full bg-primary/10 text-sm font-bold text-primary">
                              {PATH_MODE_ICONS[entry.key] ?? "?"}
                            </div>
                            <div className="text-lg font-semibold tabular-nums">{entry.total.toLocaleString()}</div>
                            <div className="mt-0.5 text-xs text-muted-foreground">{entry.label}</div>
                            <div className="mt-1 text-xs text-muted-foreground">{pct}%</div>
                          </div>
                        );
                      })}
                    </div>
                  ) : (
                    <EmptyState label="No path mode samples." />
                  )}
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle>Reporting Regions</CardTitle>
                  <CardDescription>Geographic distribution of mesh nodes</CardDescription>
                </CardHeader>
                <CardContent>
                  {summary?.locationPoints.length ? (
                    <div className="flex flex-wrap gap-2">
                      {dedupeLocations(summary.locationPoints).map((loc) => (
                        <Badge key={`${loc.city}-${loc.country}`} variant="outline" className="gap-1.5 px-3 py-1.5">
                          <span className="font-medium">{loc.city}</span>
                          <span className="text-muted-foreground">{loc.country}</span>
                        </Badge>
                      ))}
                    </div>
                  ) : (
                    <EmptyState label="No location data yet." />
                  )}
                </CardContent>
              </Card>
            </div>
          </section>
        </TabsContent>
      </Tabs>
    </div>
  );
}

const CHART_H = 240;
const CHART_PAD = { top: 20, right: 16, bottom: 32, left: 48 };

function TrafficChart({ points, maxValue }: { points: ChartPoint[]; maxValue: number }) {
  const [hover, setHover] = useState<number | null>(null);
  const count = points.length;
  if (count === 0) return null;

  const innerW = 100; // we use viewBox percentages
  const innerH = CHART_H - CHART_PAD.top - CHART_PAD.bottom;

  // find peak
  const peakIdx = points.reduce((best, p, i) => (p.totalPackets > points[best].totalPackets ? i : best), 0);

  // Y axis grid: 4 nice lines
  const gridLines = niceGridLines(maxValue, 4);

  // point positions (normalized 0-1)
  const xs = points.map((_, i) => i / Math.max(count - 1, 1));
  const ys = points.map((p) => 1 - p.totalPackets / maxValue);

  // SVG path for the line
  const linePath = xs.map((x, i) => `${i === 0 ? "M" : "L"}${x * innerW},${ys[i] * innerH}`).join(" ");
  // area path (closed to bottom)
  const areaPath = `${linePath} L${xs[xs.length - 1] * innerW},${innerH} L0,${innerH} Z`;

  // X-axis labels: show ~6 evenly spaced
  const labelStep = Math.max(1, Math.floor(count / 6));
  const xLabels = points
    .map((p, i) => ({ i, label: p.label.slice(5) }))
    .filter((_, i) => i % labelStep === 0 || i === count - 1);

  return (
    <div className="relative select-none">
      <svg
        viewBox={`${-CHART_PAD.left} ${-CHART_PAD.top} ${innerW + CHART_PAD.left + CHART_PAD.right} ${CHART_H}`}
        className="h-auto w-full"
        preserveAspectRatio="none"
        onMouseLeave={() => setHover(null)}
      >
        <defs>
          <linearGradient id="areaFill" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="hsl(178, 83%, 31%)" stopOpacity={0.35} />
            <stop offset="100%" stopColor="hsl(178, 83%, 31%)" stopOpacity={0.03} />
          </linearGradient>
          <linearGradient id="lineStroke" x1="0" y1="0" x2="1" y2="0">
            <stop offset="0%" stopColor="hsl(178, 83%, 38%)" />
            <stop offset="100%" stopColor="hsl(178, 60%, 28%)" />
          </linearGradient>
        </defs>

        {/* Y grid lines */}
        {gridLines.map((val) => {
          const y = (1 - val / maxValue) * innerH;
          return (
            <g key={val}>
              <line x1={0} y1={y} x2={innerW} y2={y} stroke="hsl(206, 22%, 87%)" strokeWidth={0.3} />
              <text x={-6} y={y} textAnchor="end" dominantBaseline="middle" fill="hsl(208, 19%, 55%)" fontSize={3.2} fontFamily="var(--font-sans)">
                {formatCompact(val)}
              </text>
            </g>
          );
        })}

        {/* baseline */}
        <line x1={0} y1={innerH} x2={innerW} y2={innerH} stroke="hsl(206, 22%, 87%)" strokeWidth={0.4} />

        {/* area fill */}
        <path d={areaPath} fill="url(#areaFill)" />

        {/* line */}
        <path d={linePath} fill="none" stroke="url(#lineStroke)" strokeWidth={0.7} strokeLinecap="round" strokeLinejoin="round" />

        {/* peak dot */}
        <circle
          cx={xs[peakIdx] * innerW}
          cy={ys[peakIdx] * innerH}
          r={1.5}
          fill="hsl(178, 83%, 31%)"
          stroke="white"
          strokeWidth={0.6}
        />

        {/* peak label */}
        <text
          x={xs[peakIdx] * innerW}
          y={ys[peakIdx] * innerH - 4}
          textAnchor="middle"
          fill="hsl(178, 83%, 28%)"
          fontSize={3}
          fontWeight={600}
          fontFamily="var(--font-sans)"
        >
          {points[peakIdx].totalPackets.toLocaleString()}
        </text>

        {/* X-axis labels */}
        {xLabels.map(({ i, label }) => (
          <text
            key={i}
            x={xs[i] * innerW}
            y={innerH + 10}
            textAnchor="middle"
            fill="hsl(208, 19%, 55%)"
            fontSize={2.8}
            fontFamily="var(--font-sans)"
          >
            {label}
          </text>
        ))}

        {/* invisible hover zones */}
        {points.map((point, i) => {
          const sliceW = innerW / count;
          return (
            <rect
              key={point.label}
              x={xs[i] * innerW - sliceW / 2}
              y={0}
              width={sliceW}
              height={innerH}
              fill="transparent"
              onMouseEnter={() => setHover(i)}
            />
          );
        })}

        {/* hover indicator */}
        {hover !== null && (
          <>
            <line
              x1={xs[hover] * innerW}
              y1={0}
              x2={xs[hover] * innerW}
              y2={innerH}
              stroke="hsl(178, 83%, 31%)"
              strokeWidth={0.3}
              strokeDasharray="1.5 1"
            />
            <circle
              cx={xs[hover] * innerW}
              cy={ys[hover] * innerH}
              r={1.2}
              fill="white"
              stroke="hsl(178, 83%, 31%)"
              strokeWidth={0.6}
            />
          </>
        )}
      </svg>

      {/* hover tooltip */}
      {hover !== null && (
        <div
          className="pointer-events-none absolute -top-2 z-10 -translate-x-1/2 rounded-lg border border-border/50 bg-card px-3 py-1.5 text-xs shadow-lg"
          style={{
            left: `${(CHART_PAD.left + xs[hover] * innerW) / (innerW + CHART_PAD.left + CHART_PAD.right) * 100}%`,
          }}
        >
          <div className="font-semibold tabular-nums">{points[hover].totalPackets.toLocaleString()} packets</div>
          <div className="text-muted-foreground">{points[hover].label}</div>
        </div>
      )}
    </div>
  );
}

function niceGridLines(max: number, count: number): number[] {
  if (max <= 0) return [0];
  const rough = max / count;
  const magnitude = 10 ** Math.floor(Math.log10(rough));
  const residual = rough / magnitude;
  const nice = residual <= 1.5 ? 1 : residual <= 3 ? 2 : residual <= 7 ? 5 : 10;
  const step = nice * magnitude;
  const lines: number[] = [];
  for (let v = step; v <= max; v += step) {
    lines.push(Math.round(v));
  }
  return lines;
}

function formatCompact(n: number): string {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`;
  if (n >= 1_000) return `${(n / 1_000).toFixed(n >= 10_000 ? 0 : 1)}K`;
  return String(n);
}

function MetricCard({ label, value, note }: { label: string; value: number | string; note: string }) {
  return (
    <Card>
      <CardHeader className="gap-1.5">
        <CardDescription className="text-xs uppercase tracking-wider">{label}</CardDescription>
        <CardTitle className="text-3xl tabular-nums">{typeof value === "number" ? value.toLocaleString() : value}</CardTitle>
        <CardDescription>{note}</CardDescription>
      </CardHeader>
    </Card>
  );
}

function EmptyState({ label }: { label: string }) {
  return (
    <div className="rounded-2xl border border-dashed border-border bg-secondary/20 px-4 py-8 text-center text-sm text-muted-foreground">
      {label}
    </div>
  );
}

function ReporterMap({ locations }: { locations: LocationPoint[] }) {
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted || typeof window === "undefined") {
    return (
      <div className="flex min-h-[360px] items-center justify-center rounded-xl bg-secondary/30 text-sm text-muted-foreground">
        Loading map...
      </div>
    );
  }

  return <LeafletMap locations={locations} />;
}

function LeafletMap({ locations }: { locations: LocationPoint[] }) {
  const [leaflet, setLeaflet] = useState<{
    MapContainer: typeof import("react-leaflet").MapContainer;
    TileLayer: typeof import("react-leaflet").TileLayer;
    CircleMarker: typeof import("react-leaflet").CircleMarker;
    Tooltip: typeof import("react-leaflet").Tooltip;
    L: typeof import("leaflet");
  } | null>(null);

  useEffect(() => {
    Promise.all([
      import("react-leaflet"),
      import("leaflet"),
    ]).then(([rl, L]) => {
      setLeaflet({
        MapContainer: rl.MapContainer,
        TileLayer: rl.TileLayer,
        CircleMarker: rl.CircleMarker,
        Tooltip: rl.Tooltip,
        L: L.default ?? L,
      });
    });
  }, []);

  if (!leaflet) {
    return (
      <div className="flex min-h-[360px] items-center justify-center rounded-xl bg-secondary/30 text-sm text-muted-foreground">
        Loading map...
      </div>
    );
  }

  const { MapContainer, TileLayer, CircleMarker, Tooltip } = leaflet;

  const center: [number, number] = locations.length
    ? [
        locations.reduce((s, l) => s + l.latitude, 0) / locations.length,
        locations.reduce((s, l) => s + l.longitude, 0) / locations.length,
      ]
    : [46.0, 14.5];

  return (
    <>
      <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
      <div className="overflow-hidden rounded-xl">
        <MapContainer
          center={center}
          zoom={locations.length > 1 ? 4 : 8}
          scrollWheelZoom={true}
          style={{ height: 360, width: "100%" }}
          attributionControl={true}
        >
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          />
          {locations.map((loc) => (
            <CircleMarker
              key={`${loc.latitude}-${loc.longitude}-${loc.city}`}
              center={[loc.latitude, loc.longitude]}
              radius={8}
              pathOptions={{
                color: "hsl(178, 83%, 31%)",
                fillColor: "hsl(178, 83%, 45%)",
                fillOpacity: 0.6,
                weight: 2,
              }}
            >
              <Tooltip>
                {loc.city}, {loc.country}
              </Tooltip>
            </CircleMarker>
          ))}
        </MapContainer>
      </div>
    </>
  );
}

function dedupeLocations(locations: LocationPoint[]) {
  const seen = new Set<string>();
  return locations.filter((loc) => {
    const key = `${loc.city}-${loc.country}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

function formatRelative(value: string) {
  const diffMs = Date.now() - new Date(value).getTime();
  const diffMin = Math.floor(diffMs / 60000);
  if (diffMin < 1) return "just now";
  if (diffMin < 60) return `${diffMin}m ago`;
  const diffHr = Math.floor(diffMin / 60);
  if (diffHr < 24) return `${diffHr}h ago`;
  return `${Math.floor(diffHr / 24)}d ago`;
}
