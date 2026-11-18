// Trust Hire's AI: one Cloudflare Worker in front of Workers AI.
//
// The app speaks an OpenAI-style chat completion (POST /v1/chat/completions,
// a JSON-schema response format), so this is the only place that knows which
// model answers. It holds no key: the Workers AI binding (`env.AI`) is
// authorised by the account the Worker is deployed to, so nothing secret is
// in this file, in the app, or in the repository.
//
// What it guards, because anyone can call a public URL:
// - only the site's own origins may call it from a browser (CORS);
// - the model is fixed here; a request cannot pick a bigger, dearer one;
// - requests are capped in size, turns, tokens and temperature;
// - each address gets a few requests a minute (when the rate-limit binding is
//   configured), so one visitor cannot spend the day's free allowance.
// It never logs what people typed.

const LIMITS = {
  messages: 12,
  characters: 24000,
  schemaCharacters: 8000,
  maxTokens: 512,
};

const ROLES = new Set(['system', 'user', 'assistant']);

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const origin = request.headers.get('Origin');
    const allowed = allowedOrigin(origin, env);

    // A browser on another site never gets an answer it can read.
    if (origin && !allowed) {
      return json({ error: 'origin not allowed' }, 403);
    }

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: cors(allowed) });
    }

    if (request.method === 'GET' && url.pathname === '/health') {
      return json({ ok: true, model: env.MODEL }, 200, allowed);
    }

    if (request.method !== 'POST' || url.pathname !== '/v1/chat/completions') {
      return json({ error: 'not found' }, 404, allowed);
    }

    if (env.RATE_LIMITER) {
      const key = request.headers.get('CF-Connecting-IP') || 'unknown';
      const { success } = await env.RATE_LIMITER.limit({ key });
      if (!success) return json({ error: 'too many requests' }, 429, allowed);
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return json({ error: 'body is not JSON' }, 400, allowed);
    }

    const checked = check(body);
    if (checked.error) return json({ error: checked.error }, 400, allowed);

    let result;
    try {
      result = await env.AI.run(env.MODEL, checked.input);
    } catch {
      // The model's own error text can carry the prompt back; say less.
      return json({ error: 'the model could not answer' }, 502, allowed);
    }

    const content = contentOf(result);
    if (content === null) {
      return json({ error: 'the model gave no answer' }, 502, allowed);
    }

    return json(
      {
        object: 'chat.completion',
        model: env.MODEL,
        choices: [
          {
            index: 0,
            message: { role: 'assistant', content },
            finish_reason: 'stop',
          },
        ],
      },
      200,
      allowed,
    );
  },
};

/// The origin to echo back, or null when this one may not call.
export function allowedOrigin(origin, env) {
  if (!origin) return null;
  const list = String(env.ALLOWED_ORIGINS || '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
  return list.includes(origin) ? origin : null;
}

/// What the model is asked, or why the request was refused.
export function check(body) {
  if (!body || typeof body !== 'object') return { error: 'body must be an object' };

  const { messages } = body;
  if (!Array.isArray(messages) || messages.length === 0) {
    return { error: 'messages must be a non-empty list' };
  }
  if (messages.length > LIMITS.messages) return { error: 'too many messages' };

  let characters = 0;
  for (const m of messages) {
    if (!m || !ROLES.has(m.role) || typeof m.content !== 'string') {
      return { error: 'each message needs a role and text' };
    }
    characters += m.content.length;
  }
  if (characters > LIMITS.characters) return { error: 'messages are too long' };

  const input = {
    messages: messages.map((m) => ({ role: m.role, content: m.content })),
    max_tokens: clamp(Number(body.max_tokens) || 320, 1, LIMITS.maxTokens),
    temperature: clamp(Number(body.temperature ?? 0.2), 0, 1),
  };

  // OpenAI's shape nests the schema under json_schema.schema; Workers AI takes
  // the schema itself under json_schema.
  const format = body.response_format;
  if (format) {
    const schema = format.json_schema?.schema ?? format.json_schema;
    if (!schema || typeof schema !== 'object') {
      return { error: 'response_format needs a JSON schema' };
    }
    if (JSON.stringify(schema).length > LIMITS.schemaCharacters) {
      return { error: 'schema is too long' };
    }
    input.response_format = { type: 'json_schema', json_schema: schema };
  }

  return { input };
}

/// The reply's text, whichever shape the model answered in.
export function contentOf(result) {
  if (!result || typeof result !== 'object') return null;
  const choice = result.choices?.[0]?.message?.content;
  if (typeof choice === 'string') return choice;
  const { response } = result;
  if (typeof response === 'string') return response;
  if (response && typeof response === 'object') return JSON.stringify(response);
  return null;
}

function clamp(n, low, high) {
  return Math.min(high, Math.max(low, n));
}

function cors(origin) {
  if (!origin) return {};
  return {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Max-Age': '86400',
    Vary: 'Origin',
  };
}

function json(data, status, origin = null) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json', ...cors(origin) },
  });
}
