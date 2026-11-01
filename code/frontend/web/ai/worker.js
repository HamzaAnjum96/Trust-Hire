// Trust Hire — where the on-device model runs, off the page's main thread.
// Started by bridge.js; same pinned WebLLM version.
import { WebWorkerMLCEngineHandler } from 'https://cdn.jsdelivr.net/npm/@mlc-ai/web-llm@0.2.85/+esm';

const handler = new WebWorkerMLCEngineHandler();
self.onmessage = (message) => handler.onmessage(message);
