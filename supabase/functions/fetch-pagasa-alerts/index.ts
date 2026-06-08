import { createClient } from 'jsr:@supabase/supabase-js@2';

const FUNCTION_NAME = 'fetch-pagasa-alerts';
const ALERTS_TABLE = 'global_alerts';

type IngestResponse = {
  ok: true;
  function: typeof FUNCTION_NAME;
  message: string;
  rowsFetched: number;
  rowsNormalized: number;
  rowsSkipped: number;
  rowsUpserted: number;
};

type ErrorResponse = {
  ok: false;
  function: typeof FUNCTION_NAME;
  error: {
    code: string;
    message: string;
  };
};

type FetchSourceResult = {
  message: string;
  records: RawAlertLike[];
};

type RawAlertLike = Record<string, unknown>;

type NormalizedAlertRow = {
  id: string;
  source: string;
  source_alert_id: string | null;
  title: string;
  severity: string;
  advisory_type: string;
  content: string;
  region: string | null;
  affected_areas: string[];
  risk_tags: string[];
  latitude: number | null;
  longitude: number | null;
  published_at: string;
  updated_at: string;
  expires_at: string | null;
  is_active: boolean;
  ingested_at: string;
};

type SupabaseAdminClient = ReturnType<typeof createSupabaseAdminClient>;

const jsonHeaders = {
  'content-type': 'application/json; charset=utf-8',
};

Deno.serve(async (request: Request): Promise<Response> => {
  try {
    if (request.method !== 'GET' && request.method !== 'POST') {
      return jsonResponse(
        {
          ok: false,
          function: FUNCTION_NAME,
          error: {
            code: 'method_not_allowed',
            message: 'Only GET and POST requests are supported.',
          },
        },
        405,
      );
    }

    const ingestedAt = new Date().toISOString();

    logEvent('ingest_started', {
      method: request.method,
      ingested_at: ingestedAt,
    });

    const supabaseAdmin = createSupabaseAdminClient();
    const sourceResult = await fetchUpstreamAlerts(request);
    const normalizedRows: NormalizedAlertRow[] = [];
    let rowsSkipped = 0;

    for (const [index, rawRecord] of sourceResult.records.entries()) {
      try {
        normalizedRows.push(await normalizeAlertRecord(rawRecord, ingestedAt));
      } catch (error) {
        rowsSkipped += 1;
        logEvent('record_normalization_failed', {
          index,
          source: sanitizeOptionalText(rawRecord.source),
          source_alert_id: sanitizeOptionalText(
            rawRecord.source_alert_id ?? rawRecord.sourceAlertId,
          ),
          reason: error instanceof Error ? error.message : String(error),
        });
      }
    }

    const rowsUpserted = await upsertAlertRows(supabaseAdmin, normalizedRows);

    logEvent('rows_upserted', {
      count: rowsUpserted,
    });

    logEvent('ingest_success', {
      rows_fetched: sourceResult.records.length,
      rows_normalized: normalizedRows.length,
      rows_skipped: rowsSkipped,
      rows_upserted: rowsUpserted,
    });

    return jsonResponse({
      ok: true,
      function: FUNCTION_NAME,
      message: sourceResult.message,
      rowsFetched: sourceResult.records.length,
      rowsNormalized: normalizedRows.length,
      rowsSkipped,
      rowsUpserted,
    });
  } catch (error) {
    logEvent('ingest_failed', {
      reason: error instanceof Error ? error.message : String(error),
    });

    return jsonResponse(
      {
        ok: false,
        function: FUNCTION_NAME,
        error: {
          code: 'internal_error',
          message: error instanceof Error
            ? error.message
            : 'Unexpected function error.',
        },
      },
      500,
    );
  }
});

async function fetchUpstreamAlerts(request: Request): Promise<FetchSourceResult> {
  // TODO(fetch-pagasa-alerts): Fetch real PAGASA/NDRRMC source payloads.
  // TODO(fetch-pagasa-alerts): Add timeout, retry, and source-specific parsers.
  if (isLocalFixtureRequest(request)) {
    return {
      message: 'Loaded local fixture alerts.',
      records: createLocalFixtureAlerts(),
    };
  }

  return {
    message: 'No upstream source configured yet.',
    records: [],
  };
}

function isLocalFixtureRequest(request: Request): boolean {
  const url = new URL(request.url);
  return Deno.env.get('PAGASA_ENABLE_LOCAL_FIXTURE') === 'true' &&
    url.searchParams.get('fixture') === 'sample';
}

function createLocalFixtureAlerts(): RawAlertLike[] {
  return [
    {
      source: 'PAGASA',
      source_alert_id: 'local-fixture-alert-1',
      title: ' Local Fixture Rainfall Advisory ',
      severity: 'High',
      advisory_type: 'Rainfall',
      content: 'Sample local fixture only.  Do not use as production data.',
      region: 'Eastern Visayas',
      affected_areas: ['Baybay City', ' Leyte '],
      risk_tags: [' flood prone ', 'Flood-Prone', 'coastal warning'],
      latitude: 10.6785,
      longitude: 124.8006,
      published_at: '2026-06-08T00:00:00.000Z',
      updated_at: '2026-06-08T00:00:00.000Z',
      expires_at: null,
      is_active: true,
    },
  ];
}

async function normalizeAlertRecord(
  rawRecord: RawAlertLike,
  ingestedAt: string,
): Promise<NormalizedAlertRow> {
  const source = sanitizeRequiredText(rawRecord.source, 'source').toUpperCase();
  const sourceAlertId = sanitizeOptionalText(
    rawRecord.source_alert_id ?? rawRecord.sourceAlertId,
  );
  const title = sanitizeRequiredText(rawRecord.title, 'title');
  const severity = normalizeSeverity(rawRecord.severity);
  const advisoryType = sanitizeOptionalText(
    rawRecord.advisory_type ?? rawRecord.advisoryType,
  ) ?? 'general';
  const content = sanitizeRequiredText(rawRecord.content, 'content');
  const publishedAt = parseRequiredDate(
    rawRecord.published_at ?? rawRecord.publishedAt,
    'published_at',
  );
  const updatedAt = parseOptionalDate(
    rawRecord.updated_at ?? rawRecord.updatedAt,
  ) ?? ingestedAt;
  const expiresAt = parseOptionalDate(
    rawRecord.expires_at ?? rawRecord.expiresAt,
  );
  const id = await normalizeAlertId(rawRecord.id, {
    source,
    sourceAlertId,
    title,
    advisoryType,
    publishedAt,
  });

  return {
    id,
    source,
    source_alert_id: sourceAlertId,
    title,
    severity,
    advisory_type: advisoryType,
    content,
    region: sanitizeOptionalText(rawRecord.region),
    affected_areas: normalizeStringList(
      rawRecord.affected_areas ?? rawRecord.affectedAreas,
    ),
    risk_tags: normalizeRiskTags(rawRecord.risk_tags ?? rawRecord.riskTags),
    latitude: parseOptionalNumber(rawRecord.latitude),
    longitude: parseOptionalNumber(rawRecord.longitude),
    published_at: publishedAt,
    updated_at: updatedAt,
    expires_at: expiresAt,
    is_active: parseBoolean(rawRecord.is_active ?? rawRecord.isActive, true),
    ingested_at: ingestedAt,
  };
}

async function normalizeAlertId(
  rawId: unknown,
  stableFields: {
    source: string;
    sourceAlertId: string | null;
    title: string;
    advisoryType: string;
    publishedAt: string;
  },
): Promise<string> {
  const explicitId = sanitizeOptionalText(rawId);
  if (explicitId && isUuid(explicitId)) {
    return explicitId.toLowerCase();
  }

  const seed = stableFields.sourceAlertId
    ? `${stableFields.source}:${stableFields.sourceAlertId}`
    : [
      stableFields.source,
      stableFields.title,
      stableFields.advisoryType,
      stableFields.publishedAt,
    ].join('|');

  return deterministicUuid(seed);
}

async function upsertAlertRows(
  supabaseAdmin: SupabaseAdminClient,
  rows: NormalizedAlertRow[],
): Promise<number> {
  if (rows.length === 0) {
    return 0;
  }

  const rowsWithSourceAlertId = rows.filter((row) => row.source_alert_id);
  const rowsWithoutSourceAlertId = rows.filter((row) => !row.source_alert_id);

  let rowsUpserted = 0;

  rowsUpserted += await upsertAlertBatch(
    supabaseAdmin,
    rowsWithSourceAlertId,
    'source,source_alert_id',
  );
  rowsUpserted += await upsertAlertBatch(
    supabaseAdmin,
    rowsWithoutSourceAlertId,
    'id',
  );

  return rowsUpserted;
}

async function upsertAlertBatch(
  supabaseAdmin: SupabaseAdminClient,
  rows: NormalizedAlertRow[],
  onConflict: string,
): Promise<number> {
  if (rows.length === 0) {
    return 0;
  }

  const { error } = await supabaseAdmin
    .from(ALERTS_TABLE)
    .upsert(rows, { onConflict });

  if (error) {
    throw new Error(`Failed to upsert ${ALERTS_TABLE}: ${error.message}`);
  }

  return rows.length;
}

function normalizeRiskTags(value: unknown): string[] {
  return dedupeStrings(
    coerceList(value)
      .map((tag) => sanitizeText(tag).toLowerCase())
      .map((tag) => tag.replace(/[\s-]+/g, '_'))
      .filter((tag) => tag.length > 0),
  );
}

function normalizeStringList(value: unknown): string[] {
  return dedupeStrings(
    coerceList(value)
      .map((item) => sanitizeText(item))
      .filter((item) => item.length > 0),
  );
}

function normalizeSeverity(value: unknown): string {
  const severity = sanitizeText(value).toLowerCase();
  return severity === 'high' || severity === 'medium' || severity === 'low'
    ? severity
    : 'low';
}

function coerceList(value: unknown): unknown[] {
  if (Array.isArray(value)) {
    return value;
  }

  if (typeof value === 'string') {
    return value.split(',');
  }

  return [];
}

function dedupeStrings(values: string[]): string[] {
  return [...new Set(values)];
}

function sanitizeRequiredText(value: unknown, fieldName: string): string {
  const text = sanitizeText(value);
  if (!text) {
    throw new Error(`Missing required text field: ${fieldName}`);
  }

  return text;
}

function sanitizeOptionalText(value: unknown): string | null {
  const text = sanitizeText(value);
  return text.length > 0 ? text : null;
}

function sanitizeText(value: unknown): string {
  if (value === null || value === undefined) {
    return '';
  }

  return String(value).replace(/\s+/g, ' ').trim();
}

function parseRequiredDate(value: unknown, fieldName: string): string {
  const parsed = parseDate(value);
  if (!parsed) {
    throw new Error(`Missing or invalid date field: ${fieldName}`);
  }

  return parsed;
}

function parseOptionalDate(value: unknown): string | null {
  return parseDate(value);
}

function parseDate(value: unknown): string | null {
  if (value instanceof Date && Number.isFinite(value.getTime())) {
    return value.toISOString();
  }

  if (typeof value === 'number' && Number.isFinite(value)) {
    const dateFromNumber = new Date(value);
    return Number.isFinite(dateFromNumber.getTime())
      ? dateFromNumber.toISOString()
      : null;
  }

  const text = sanitizeText(value);
  if (!text) {
    return null;
  }

  const date = new Date(text);
  return Number.isFinite(date.getTime()) ? date.toISOString() : null;
}

function parseOptionalNumber(value: unknown): number | null {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value;
  }

  const text = sanitizeText(value);
  if (!text) {
    return null;
  }

  const parsed = Number(text);
  return Number.isFinite(parsed) ? parsed : null;
}

function parseBoolean(value: unknown, fallback: boolean): boolean {
  if (typeof value === 'boolean') {
    return value;
  }

  const text = sanitizeText(value).toLowerCase();
  if (['true', '1', 'yes', 'y'].includes(text)) {
    return true;
  }
  if (['false', '0', 'no', 'n'].includes(text)) {
    return false;
  }

  return fallback;
}

async function deterministicUuid(seed: string): Promise<string> {
  const digest = new Uint8Array(
    await crypto.subtle.digest('SHA-256', new TextEncoder().encode(seed)),
  );

  digest[6] = (digest[6] & 0x0f) | 0x50;
  digest[8] = (digest[8] & 0x3f) | 0x80;

  const hex = [...digest.slice(0, 16)]
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');

  return [
    hex.slice(0, 8),
    hex.slice(8, 12),
    hex.slice(12, 16),
    hex.slice(16, 20),
    hex.slice(20, 32),
  ].join('-');
}

function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
    .test(value);
}

function createSupabaseAdminClient() {
  const supabaseUrl = Deno.env.get('SUPABASE_URL') ??
    Deno.env.get('PAGASA_SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ??
    Deno.env.get('PAGASA_SUPABASE_SERVICE_ROLE_KEY');

  if (!supabaseUrl) {
    throw new Error(
      'Missing SUPABASE_URL or PAGASA_SUPABASE_URL environment variable.',
    );
  }

  if (!serviceRoleKey) {
    throw new Error(
      'Missing SUPABASE_SERVICE_ROLE_KEY or PAGASA_SUPABASE_SERVICE_ROLE_KEY environment variable.',
    );
  }

  return createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
}

function jsonResponse(
  body: IngestResponse | ErrorResponse,
  status = 200,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: jsonHeaders,
  });
}

function logEvent(event: string, fields: Record<string, unknown> = {}): void {
  console.log(JSON.stringify({
    event,
    function: FUNCTION_NAME,
    ...fields,
  }));
}
