import { createClient } from 'jsr:@supabase/supabase-js@2';

const FUNCTION_NAME = 'fetch-pagasa-alerts';

type HealthResponse = {
  ok: true;
  function: typeof FUNCTION_NAME;
  message: string;
};

type ErrorResponse = {
  ok: false;
  function: typeof FUNCTION_NAME;
  error: {
    code: string;
    message: string;
  };
};

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

    const supabaseAdmin = createSupabaseAdminClient();

    // TODO(fetch-pagasa-alerts): Fetch and parse PAGASA/NDRRMC source payloads.
    // TODO(fetch-pagasa-alerts): Normalize alert DTOs and upsert into global_alerts.
    void supabaseAdmin;

    return jsonResponse({
      ok: true,
      function: FUNCTION_NAME,
      message: 'PAGASA alert ingestion function is reachable',
    });
  } catch (error) {
    console.error(
      JSON.stringify({
        event: 'fetch_pagasa_alerts_failed',
        error: error instanceof Error ? error.message : String(error),
      }),
    );

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
  body: HealthResponse | ErrorResponse,
  status = 200,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: jsonHeaders,
  });
}
