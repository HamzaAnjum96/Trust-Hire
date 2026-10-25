// Trust Hire — the page's side of the on-device AI.
//
// Loaded by the app only when somebody switches the AI on, never on page load:
// WebLLM is several megabytes and the model hundreds more, and somebody who
// never asks for it should never pay for it. The model itself runs in a Web
// Worker (worker.js) so the app stays responsive while it thinks.
//
// Everything crossing into Dart is a string or a boolean. The request carries
// a JSON Schema, and WebLLM constrains generation to it, so what comes back is
// always the shape the app asked for.

const WEBLLM = 'https://cdn.jsdelivr.net/npm/@mlc-ai/web-llm@0.2.85/+esm';

let webllm = null;
let engine = null;
let loadedModel = null;

async function lib() {
  if (!webllm) webllm = await import(WEBLLM);
  return webllm;
}

/** Whether this browser can run a model at all, and in which precision. */
export async function support() {
  if (!('gpu' in navigator)) return JSON.stringify({ ok: false, reason: 'no-webgpu' });
  try {
    const adapter = await navigator.gpu.requestAdapter();
    if (!adapter) return JSON.stringify({ ok: false, reason: 'no-adapter' });
    return JSON.stringify({ ok: true, f16: adapter.features.has('shader-f16') });
  } catch (error) {
    return JSON.stringify({ ok: false, reason: 'error' });
  }
}

/** Whether [model]'s weights are already in this browser's cache. */
export async function cached(model) {
  return (await lib()).hasModelInCache(model);
}

/** Downloads (first time) or reads from cache, then loads onto the GPU. */
export async function load(model, onProgress) {
  if (engine && loadedModel === model) return;
  const w = await lib();
  if (engine) {
    await engine.unload();
    engine = null;
    loadedModel = null;
  }
  const worker = new Worker(new URL('./worker.js', import.meta.url), { type: 'module' });
  engine = await w.CreateWebWorkerMLCEngine(worker, model, {
    initProgressCallback: (report) => onProgress(report.progress ?? 0, report.text ?? ''),
  });
  loadedModel = model;
}

/** One reply, constrained to the request's JSON Schema. */
export async function complete(requestJson) {
  if (!engine) throw new Error('not_ready');
  const request = JSON.parse(requestJson);
  const reply = await engine.chat.completions.create({
    messages: request.messages,
    temperature: request.temperature,
    max_tokens: request.max_tokens,
    response_format: { type: 'json_object', schema: JSON.stringify(request.schema) },
  });
  return reply.choices?.[0]?.message?.content ?? '';
}

/** Unloads [model] if it is loaded, and deletes its weights from the cache. */
export async function forget(model) {
  if (engine && loadedModel === model) {
    await engine.unload();
    engine = null;
    loadedModel = null;
  }
  await (await lib()).deleteModelAllInfoInCache(model);
}
