// Run with: node --test   (Node 20 or later; nothing to install)
import { test } from 'node:test';
import assert from 'node:assert/strict';
import worker, { allowedOrigin, check, contentOf } from '../src/index.js';

const SITE = 'https://hamzaanjum96.github.io';
const env = (over = {}) => ({
  MODEL: '@cf/meta/llama-4-scout-17b-16e-instruct',
  ALLOWED_ORIGINS: `${SITE},http://localhost:8099`,
  AI: { run: async () => ({ response: { ok: true } }) },
  ...over,
});
const post = (body, origin = SITE) =>
  new Request('https://ai.example/v1/chat/completions', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...(origin ? { Origin: origin } : {}) },
    body: typeof body === 'string' ? body : JSON.stringify(body),
  });
const ask = { messages: [{ role: 'user', content: 'plumber chahiye' }] };

test('the site gets an answer in the OpenAI shape the app reads', async () => {
  const res = await worker.fetch(post(ask), env());
  assert.equal(res.status, 200);
  assert.equal(res.headers.get('Access-Control-Allow-Origin'), SITE);
  const body = await res.json();
  assert.equal(body.choices[0].message.content, '{"ok":true}');
});

test('another site is refused, and gets no CORS header', async () => {
  const res = await worker.fetch(post(ask, 'https://evil.example'), env());
  assert.equal(res.status, 403);
  assert.equal(res.headers.get('Access-Control-Allow-Origin'), null);
  assert.equal(allowedOrigin('https://hamzaanjum96.github.io.evil.example', env()), null);
});

test('the request cannot choose the model', async () => {
  let used;
  const e = env({ AI: { run: async (model) => ((used = model), { response: 'x' }) } });
  await worker.fetch(post({ ...ask, model: '@cf/meta/llama-3.3-70b-instruct-fp8-fast' }), e);
  assert.equal(used, '@cf/meta/llama-4-scout-17b-16e-instruct');
});

test('sizes are capped, and malformed requests refused', () => {
  assert.equal(check({ ...ask, max_tokens: 99999 }).input.max_tokens, 512);
  assert.equal(check({ ...ask, temperature: 7 }).input.temperature, 1);
  assert.ok(check({ messages: [] }).error);
  assert.ok(check({ messages: Array(13).fill(ask.messages[0]) }).error);
  assert.ok(check({ messages: [{ role: 'user', content: 'x'.repeat(24001) }] }).error);
  assert.ok(check({ messages: [{ role: 'tool', content: 'x' }] }).error);
});

test("OpenAI's nested schema is passed as Workers AI expects", () => {
  const schema = { type: 'object', properties: { a: { type: 'string' } } };
  const { input } = check({
    ...ask,
    response_format: { type: 'json_schema', json_schema: { name: 'reply', schema } },
  });
  assert.deepEqual(input.response_format, { type: 'json_schema', json_schema: schema });
});

test('every reply shape the models give is read', () => {
  assert.equal(contentOf({ choices: [{ message: { content: '{}' } }] }), '{}');
  assert.equal(contentOf({ response: 'text' }), 'text');
  assert.equal(contentOf({ response: { a: 1 } }), '{"a":1}');
  assert.equal(contentOf({}), null);
});

test('a model failure says little, and a rate limit says so', async () => {
  const failing = env({ AI: { run: async () => { throw new Error('prompt was: secret'); } } });
  const res = await worker.fetch(post(ask), failing);
  assert.equal(res.status, 502);
  assert.doesNotMatch(await res.text(), /secret/);

  const limited = env({ RATE_LIMITER: { limit: async () => ({ success: false }) } });
  assert.equal((await worker.fetch(post(ask), limited)).status, 429);
});

test('the preflight is answered for the site', async () => {
  const res = await worker.fetch(
    new Request('https://ai.example/v1/chat/completions', { method: 'OPTIONS', headers: { Origin: SITE } }),
    env(),
  );
  assert.equal(res.status, 204);
  assert.match(res.headers.get('Access-Control-Allow-Methods'), /POST/);
});
