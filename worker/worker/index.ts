import {
  COUNT_KEYS,
  REPORT_INSERT_SQL,
  extractCfGeo,
  jsonHeaders,
  loadDashboardSummary,
  purgeOldReports,
  validateIngestPayload,
  type Env,
  type IngestPayload,
} from "./stats";

const ROUTES = {
  "/api/ingest": handleIngest,
  "/api/dashboard": handleDashboard,
} as const;

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const pathname = new URL(request.url).pathname;
    const route = Object.entries(ROUTES).find(([prefix]) =>
      pathname.startsWith(prefix),
    );
    if (!route) {
      return new Response("Not Found", { status: 404 });
    }
    try {
      return await route[1](request, env);
    } catch (error) {
      console.error(`Worker route failed for ${pathname}:`, error);
      return Response.json(
        { error: "Internal Server Error" },
        {
          headers: jsonHeaders,
          status: 500,
        },
      );
    }
  },
};

async function handleIngest(request: Request, env: Env): Promise<Response> {
  if (request.method !== "POST") {
    return Response.json(
      { error: "Method not allowed" },
      {
        headers: jsonHeaders,
        status: 405,
      },
    );
  }

  let payload: IngestPayload;
  try {
    payload = validateIngestPayload(await request.json());
  } catch (error) {
    return Response.json(
      { error: error instanceof Error ? error.message : "Invalid payload" },
      {
        headers: jsonHeaders,
        status: 400,
      },
    );
  }

  const geo = extractCfGeo(request);
  const values = [
    payload.reportId,
    payload.deviceKey6,
    payload.windowStart,
    payload.windowEnd,
    new Date().toISOString(),
    payload.appVersion,
    geo.country,
    geo.region,
    geo.city,
    geo.latitude,
    geo.longitude,
    geo.colo,
    ...COUNT_KEYS.map((key) => payload.counts[key]),
  ];

  const result = await env.DB.prepare(REPORT_INSERT_SQL).bind(...values).run();
  const changes = Number((result.meta as { changes?: number }).changes ?? 0);

  // Purge reports older than 7 days (best-effort, don't block response)
  void purgeOldReports(env).catch(() => {});

  return Response.json(
    {
      ok: true,
      duplicate: changes === 0,
    },
    {
      headers: jsonHeaders,
    },
  );
}

async function handleDashboard(request: Request, env: Env): Promise<Response> {
  if (request.method !== "GET") {
    return Response.json(
      { error: "Method not allowed" },
      {
        headers: jsonHeaders,
        status: 405,
      },
    );
  }

  const url = new URL(request.url);
  const windowParam = url.searchParams.get("window");
  const summary = await loadDashboardSummary(env, windowParam);
  const cacheTtl = windowParam === "7d" ? 86400 : 60;
  return Response.json(
    {
      generatedAt: new Date().toISOString(),
      ...summary,
    },
    {
      headers: {
        ...jsonHeaders,
        "cache-control": `public, max-age=${cacheTtl}, s-maxage=${cacheTtl}`,
        "cdn-cache-control": `max-age=${cacheTtl}`,
      },
    },
  );
}
