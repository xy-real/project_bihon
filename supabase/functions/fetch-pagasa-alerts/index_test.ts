import {
  assert,
  assertEquals,
  assertStringIncludes,
} from 'jsr:@std/assert@1';
import {
  createLocalHtmlFixture,
  fetchPublicSourceText,
  htmlToReadableText,
  inferRiskTags,
  isRelevantToBaybayArea,
  normalizeAlertRecord,
  parsePublicAlertPage,
  PublicSourceFetchError,
  upsertAlertRows,
} from './index.ts';

Deno.test('parser strips HTML and extracts readable alert content', async () => {
  const html = createLocalHtmlFixture();
  const readableText = htmlToReadableText(html);
  const parsed = await parsePublicAlertPage(
    html,
    'https://example.test/advisory',
    new Date('2026-06-08T00:00:00.000Z'),
  );

  assertStringIncludes(readableText, 'Heavy Rainfall Advisory');
  assertStringIncludes(readableText, 'Baybay City');
  assertEquals(parsed.title, 'Heavy Rainfall Advisory for Eastern Visayas');
  assertStringIncludes(String(parsed.content), 'low-lying areas');
});

Deno.test('risk tag inference maps public text to canonical tags', () => {
  const tags = inferRiskTags(
    'Heavy rainfall may cause flooding in low-lying coastal communities near steep slopes.',
  );

  assertEquals(tags, ['flood_prone', 'coastal', 'landslide_prone']);
});

Deno.test('Baybay and Eastern Visayas relevance detection works', () => {
  assert(
    isRelevantToBaybayArea({
      title: 'Rainfall Advisory',
      content: 'Expected impacts over Leyte and Eastern Visayas.',
    }),
  );

  assert(
    !isRelevantToBaybayArea({
      title: 'Mindanao Advisory',
      content: 'Expected impacts over Davao Region.',
    }),
  );
});

Deno.test('normalizer produces global_alerts row shape', async () => {
  const parsed = await parsePublicAlertPage(
    createLocalHtmlFixture(),
    'https://example.test/advisory',
    new Date('2026-06-08T00:00:00.000Z'),
  );
  const row = await normalizeAlertRecord(
    parsed,
    '2026-06-08T00:01:00.000Z',
  );

  assertEquals(row.source, 'PAGASA');
  assertEquals(row.advisory_type, 'rainfall');
  assertEquals(row.severity, 'high');
  assertEquals(row.region, 'Eastern Visayas');
  assertEquals(row.affected_areas, [
    'Baybay City',
    'Leyte',
    'Eastern Visayas',
  ]);
  assertEquals(row.risk_tags, ['flood_prone', 'landslide_prone']);
  assertEquals(row.is_active, true);
  assertEquals(row.ingested_at, '2026-06-08T00:01:00.000Z');
});

Deno.test('upsert groups duplicate-safe rows by source_alert_id conflict target', async () => {
  const row = await normalizeAlertRecord(
    {
      source: 'PAGASA',
      source_alert_id: 'duplicate-source-id',
      title: 'Rainfall Advisory for Leyte',
      severity: 'High',
      advisory_type: 'rainfall',
      content: 'Heavy rainfall over Leyte.',
      affected_areas: ['Leyte'],
      risk_tags: ['flood_prone'],
      published_at: '2026-06-08T00:00:00.000Z',
      updated_at: '2026-06-08T00:00:00.000Z',
      is_active: true,
    },
    '2026-06-08T00:01:00.000Z',
  );
  const conflictTargets: string[] = [];
  const fakeSupabase = {
    from(table: string) {
      assertEquals(table, 'global_alerts');
      return {
        upsert(rows: unknown[], options: { onConflict: string }) {
          assertEquals(rows.length, 2);
          conflictTargets.push(options.onConflict);
          return Promise.resolve({ error: null });
        },
      };
    },
  };

  const count = await upsertAlertRows(
    fakeSupabase as never,
    [row, row],
  );

  assertEquals(count, 2);
  assertEquals(conflictTargets, ['source,source_alert_id']);
});

Deno.test('fetch failure returns safe error before any database mutation', async () => {
  let error: unknown;

  try {
    await fetchPublicSourceText('http://127.0.0.1:1/unreachable-alert-source');
  } catch (caught) {
    error = caught;
  }

  assert(error instanceof PublicSourceFetchError);
  assertEquals(
    error.safeMessage,
    'Unable to fetch configured PAGASA alert source.',
  );
});
