import { createClient } from 'jsr:@supabase/supabase-js@2';

const FUNCTION_NAME = 'fetch-pagasa-alerts';
const ALERTS_TABLE = 'global_alerts';
const SOURCE_URL_ENV = 'PAGASA_ALERT_SOURCE_URL';
const FETCH_TIMEOUT_MS = 10_000;
const MAX_FETCH_ATTEMPTS = 3;
const USER_AGENT = 'Crisync academic emergency preparedness project';

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

export class PublicSourceFetchError extends Error {
  constructor(message: string, readonly safeMessage: string) {
    super(message);
    this.name = 'PublicSourceFetchError';
  }
}

const jsonHeaders = {
  'content-type': 'application/json; charset=utf-8',
};

if (import.meta.main) {
  Deno.serve(handleRequest);
}

async function handleRequest(request: Request): Promise<Response> {
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

    if (error instanceof PublicSourceFetchError) {
      return jsonResponse(
        {
          ok: false,
          function: FUNCTION_NAME,
          error: {
            code: 'source_fetch_failed',
            message: error.safeMessage,
          },
        },
        502,
      );
    }

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
}

async function fetchUpstreamAlerts(request: Request): Promise<FetchSourceResult> {
  // TODO(fetch-pagasa-alerts): Replace this public-page parser with an official
  // PAGASA API parser if one becomes available for this use case.
  const localFixture = getLocalFixtureName(request);
  if (localFixture === 'sample') {
    return {
      message: 'Loaded local fixture alerts.',
      records: createLocalFixtureAlerts(),
    };
  }

  if (localFixture === 'html') {
    const parsedRecord = await parsePublicAlertPage(
      createLocalHtmlFixture(),
      'local-fixture://pagasa-alert-page',
      new Date(),
    );

    return {
      message: 'Loaded local HTML parser fixture.',
      records: isRelevantToBaybayArea(parsedRecord) ? [parsedRecord] : [],
    };
  }

  const sourceUrl = sanitizeOptionalText(Deno.env.get(SOURCE_URL_ENV));
  if (!sourceUrl) {
    return {
      message: `${SOURCE_URL_ENV} is not configured.`,
      records: [],
    };
  }

  const html = await fetchPublicSourceText(sourceUrl);
  const parsedRecord = await parsePublicAlertPage(html, sourceUrl, new Date());

  if (!isRelevantToBaybayArea(parsedRecord)) {
    logEvent('source_not_relevant', {
      source_host: safeHostname(sourceUrl),
      title: sanitizeOptionalText(parsedRecord.title),
    });

    return {
      message: 'Configured source was fetched, but no Baybay/Eastern Visayas relevant alert was found.',
      records: [],
    };
  }

  return {
    message: 'Configured public alert source fetched and parsed.',
    records: [parsedRecord],
  };
}

function getLocalFixtureName(request: Request): string | null {
  const url = new URL(request.url);
  if (Deno.env.get('PAGASA_ENABLE_LOCAL_FIXTURE') !== 'true') {
    return null;
  }

  return sanitizeOptionalText(url.searchParams.get('fixture'));
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

export function createLocalHtmlFixture(): string {
  return `
    <!doctype html>
    <html>
      <head>
        <title>Heavy Rainfall Advisory for Eastern Visayas</title>
      </head>
      <body>
        <h1>Heavy Rainfall Advisory for Eastern Visayas</h1>
        <p>Published: June 8, 2026 8:00 AM</p>
        <p>
          PAGASA advises residents of Baybay City, Leyte and nearby low-lying
          areas to monitor flooding and landslide-prone communities.
        </p>
      </body>
    </html>
  `;
}

export async function fetchPublicSourceText(sourceUrl: string): Promise<string> {
  let lastError: unknown;

  for (let attempt = 1; attempt <= MAX_FETCH_ATTEMPTS; attempt += 1) {
    try {
      const response = await fetchWithTimeout(sourceUrl, FETCH_TIMEOUT_MS);
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      return await response.text();
    } catch (error) {
      lastError = error;
      logEvent('source_fetch_attempt_failed', {
        attempt,
        max_attempts: MAX_FETCH_ATTEMPTS,
        source_host: safeHostname(sourceUrl),
        reason: error instanceof Error ? error.message : String(error),
      });

      if (attempt < MAX_FETCH_ATTEMPTS) {
        await delay(500 * 2 ** (attempt - 1));
      }
    }
  }

  throw new PublicSourceFetchError(
    lastError instanceof Error ? lastError.message : String(lastError),
    'Unable to fetch configured PAGASA alert source.',
  );
}

async function fetchWithTimeout(
  sourceUrl: string,
  timeoutMs: number,
): Promise<Response> {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

  try {
    return await fetch(sourceUrl, {
      signal: controller.signal,
      headers: {
        accept: 'text/html,application/xhtml+xml,text/plain;q=0.9,*/*;q=0.8',
        'user-agent': USER_AGENT,
      },
    });
  } finally {
    clearTimeout(timeoutId);
  }
}

export async function parsePublicAlertPage(
  html: string,
  sourceUrl: string,
  now: Date,
): Promise<RawAlertLike> {
  const readableText = htmlToReadableText(html);
  const title = extractTitle(html, readableText);
  const content = extractContent(readableText, title);
  const publishedAt = extractPublishedDate(readableText, now);
  const advisoryType = inferAdvisoryType(`${title} ${content}`);
  const affectedAreas = inferAffectedAreas(`${title} ${content}`);

  return {
    source: 'PAGASA',
    source_alert_id: await buildSourceAlertId({
      title,
      sourceUrl,
      publishedAt,
    }),
    title,
    severity: inferSeverity(`${title} ${content}`),
    advisory_type: advisoryType,
    content,
    region: affectedAreas.length > 0 ? 'Eastern Visayas' : null,
    affected_areas: affectedAreas,
    risk_tags: inferRiskTags(`${title} ${content}`),
    latitude: null,
    longitude: null,
    published_at: publishedAt,
    updated_at: now.toISOString(),
    expires_at: null,
    is_active: true,
  };
}

export function htmlToReadableText(html: string): string {
  return decodeHtmlEntities(html)
    .replace(/<script[\s\S]*?<\/script>/gi, ' ')
    .replace(/<style[\s\S]*?<\/style>/gi, ' ')
    .replace(/<!--[\s\S]*?-->/g, ' ')
    .replace(/<\/(p|div|section|article|header|footer|h[1-6]|li|tr)>/gi, '\n')
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/<[^>]+>/g, ' ')
    .split('\n')
    .map((line) => sanitizeText(line))
    .filter((line) => line.length > 0)
    .join('\n');
}

function extractTitle(html: string, readableText: string): string {
  const candidates = [
    matchHtmlContent(html, /<h1[^>]*>([\s\S]*?)<\/h1>/i),
    matchHtmlAttribute(
      html,
      /<meta[^>]+(?:property|name)=["'](?:og:title|twitter:title)["'][^>]+content=["']([^"']+)["'][^>]*>/i,
    ),
    matchHtmlContent(html, /<title[^>]*>([\s\S]*?)<\/title>/i),
    readableText.split('\n')[0],
  ];

  return sanitizeRequiredText(
    candidates.find((candidate) => sanitizeText(candidate).length > 0),
    'title',
  );
}

function extractContent(readableText: string, title: string): string {
  const lines = readableText
    .split('\n')
    .map((line) => sanitizeText(line))
    .filter((line) => line.length > 0);
  const bodyLines = lines.filter((line, index) =>
    index !== 0 || line.toLowerCase() !== title.toLowerCase()
  );
  const content = sanitizeText(bodyLines.join(' '));

  return content || title;
}

function extractPublishedDate(readableText: string, now: Date): string {
  const text = readableText.replace(/\s+/g, ' ');
  const patterns = [
    /(?:published|issued|posted|updated)\s*:?\s*([A-Z][a-z]+ \d{1,2}, \d{4}(?:\s+\d{1,2}:\d{2}\s*(?:AM|PM)?)?)/i,
    /(\d{1,2}\s+[A-Z][a-z]+\s+\d{4}(?:\s+\d{1,2}:\d{2}\s*(?:AM|PM)?)?)/i,
    /(\d{4}-\d{2}-\d{2}(?:[T\s]\d{2}:\d{2}(?::\d{2})?(?:Z|[+-]\d{2}:?\d{2})?)?)/,
  ];

  for (const pattern of patterns) {
    const match = text.match(pattern);
    if (!match?.[1]) {
      continue;
    }

    const parsed = parseDate(match[1]);
    if (parsed) {
      return parsed;
    }
  }

  return now.toISOString();
}

export function inferAdvisoryType(text: string): string {
  const normalized = text.toLowerCase();
  if (/\bstorm surge\b/.test(normalized)) return 'storm_surge';
  if (/\btyphoon\b|\btropical cyclone\b|\bstorm warning\b/.test(normalized)) {
    return 'typhoon';
  }
  if (/\brainfall\b|\bheavy rain\b|\bmonsoon\b/.test(normalized)) {
    return 'rainfall';
  }
  if (/\bflood\b|\bflooding\b/.test(normalized)) return 'flood';
  if (/\bheat\b|\bheat index\b/.test(normalized)) return 'heat';
  return 'general';
}

export function inferSeverity(text: string): string {
  const normalized = text.toLowerCase();
  if (
    /\burgent\b|\bsevere\b|\bheavy rainfall\b|\btyphoon warning\b|\bstorm surge warning\b/
      .test(normalized)
  ) {
    return 'high';
  }
  if (/\badvisory\b|\bmoderate\b|\bwatch\b/.test(normalized)) {
    return 'medium';
  }
  return 'low';
}

export function inferRiskTags(text: string): string[] {
  const normalized = text.toLowerCase();
  const tags: string[] = [];

  if (/\bflood\b|\bflooding\b|\bheavy rainfall\b|\blow-lying\b|\blow lying\b/.test(normalized)) {
    tags.push('flood_prone');
  }
  if (/\bstorm surge\b|\bcoastal\b|\btyphoon\b|\btropical cyclone\b/.test(normalized)) {
    tags.push('coastal');
  }
  if (/\blandslide\b|\bmountain\b|\bsteep slope\b|\bsteep slopes\b/.test(normalized)) {
    tags.push('landslide_prone');
  }

  return dedupeStrings(tags);
}

export function inferAffectedAreas(text: string): string[] {
  const normalized = text.toLowerCase();
  const areas: string[] = [];

  if (/\bbaybay\b|\bbaybay city\b/.test(normalized)) areas.push('Baybay City');
  if (/\bleyte\b/.test(normalized)) areas.push('Leyte');
  if (/\beastern visayas\b|\bregion viii\b|\bregion 8\b/.test(normalized)) {
    areas.push('Eastern Visayas');
  }
  if (/\bvisayas\b/.test(normalized)) areas.push('Visayas');

  return dedupeStrings(areas);
}

export function isRelevantToBaybayArea(record: RawAlertLike): boolean {
  const haystack = [
    record.title,
    record.content,
    record.region,
    ...(coerceList(record.affected_areas ?? record.affectedAreas)),
  ].map((item) => sanitizeText(item).toLowerCase()).join(' ');

  return /\bbaybay\b|\bleyte\b|\beastern visayas\b|\bregion viii\b|\bregion 8\b|\bvisayas\b/
    .test(haystack);
}

async function buildSourceAlertId(input: {
  title: string;
  sourceUrl: string;
  publishedAt: string;
}): Promise<string> {
  return `public-page-${await deterministicUuid(
    `${input.sourceUrl}|${input.title}|${input.publishedAt}`,
  )}`;
}

function matchHtmlContent(html: string, pattern: RegExp): string | null {
  const match = html.match(pattern);
  return match?.[1] ? htmlToReadableText(match[1]) : null;
}

function matchHtmlAttribute(html: string, pattern: RegExp): string | null {
  const match = html.match(pattern);
  return match?.[1] ? decodeHtmlEntities(match[1]) : null;
}

function decodeHtmlEntities(value: string): string {
  const namedEntities: Record<string, string> = {
    amp: '&',
    apos: "'",
    gt: '>',
    lt: '<',
    nbsp: ' ',
    quot: '"',
  };

  return value.replace(/&(#x?[0-9a-f]+|[a-z]+);/gi, (entity, code) => {
    const normalizedCode = String(code).toLowerCase();
    if (normalizedCode.startsWith('#x')) {
      return String.fromCodePoint(Number.parseInt(normalizedCode.slice(2), 16));
    }
    if (normalizedCode.startsWith('#')) {
      return String.fromCodePoint(Number.parseInt(normalizedCode.slice(1), 10));
    }
    return namedEntities[normalizedCode] ?? entity;
  });
}

function safeHostname(sourceUrl: string): string {
  try {
    return new URL(sourceUrl).hostname;
  } catch (_) {
    return 'invalid-url';
  }
}

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export async function normalizeAlertRecord(
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

export async function upsertAlertRows(
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
