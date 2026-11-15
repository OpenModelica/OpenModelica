/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * See the full OSMC Public License conditions for more details.
 */

// The assistant panel of the OMEdit web page: a chat with a language model that
// the user configures (URL, API key, model) and that uses the OMEdit MCP tools
// through omeditMcp(), see mcp_bridge.cpp.

(() => {
  'use strict';

  const STORE_KEY = 'omedit-assistant';
  const DEFAULTS = {
    provider: 'openai', baseUrl: '', apiKey: '', model: '',
    vision: false, admin: false, open: false, width: 400,
  };
  const PROVIDERS = {
    openai: {
      label: 'OpenAI-compatible (Ollama, llama.cpp, LM Studio, vLLM)',
      short: 'OpenAI-compatible', url: 'http://localhost:11434/v1', model: 'qwen3:8b',
    },
    anthropic: {
      label: 'Anthropic', short: 'Anthropic', url: 'https://api.anthropic.com', model: 'claude-opus-5-5',
    },
  };
  const MAX_STEPS = 30;
  const MAX_TOOL_TEXT = 60000;

  const settings = loadSettings();
  let conversation = { provider: settings.provider, messages: [] };
  let running = null;
  let toolCache = { key: null, tools: [], instructions: '' };
  let mcpId = 0;

  function loadSettings() {
    try {
      return { ...DEFAULTS, ...JSON.parse(localStorage.getItem(STORE_KEY) || '{}') };
    } catch (e) {
      return { ...DEFAULTS };
    }
  }

  function saveSettings() {
    try {
      localStorage.setItem(STORE_KEY, JSON.stringify(settings));
    } catch (e) {
      // Private windows and blocked site data: the settings last for this page only.
    }
  }


  const omeditReady = new Promise((resolve) => {
    if (globalThis.omeditMcp) resolve();
    else globalThis.addEventListener('omedit-mcp-ready', () => resolve(), { once: true });
  });

  async function mcp(method, params) {
    await omeditReady;
    const reply = await globalThis.omeditMcp(
      { jsonrpc: '2.0', id: ++mcpId, method, params: params || {} },
      { vision: settings.vision, admin: settings.admin });
    if (!reply) return null;
    if (reply.error) throw new Error(reply.error.message || 'Error from OMEdit');
    return reply.result;
  }

  async function getTools() {
    const key = `${settings.vision}|${settings.admin}`;
    if (toolCache.key !== key) {
      const init = await mcp('initialize', {
        protocolVersion: '2025-11-25', capabilities: {},
        clientInfo: { name: 'OMEdit web assistant', version: '1.0.0' },
      });
      const list = await mcp('tools/list');
      toolCache = { key, tools: (list && list.tools) || [], instructions: (init && init.instructions) || '' };
    }
    return toolCache;
  }

  function systemPrompt(instructions) {
    return [
      'You are an assistant in OMEdit, the OpenModelica editor, which runs in a web browser. '
        + 'The user sees OMEdit next to this chat, and changes that you make with the tools show in OMEdit at once.',
      instructions,
      'Simulations run in the browser. Keep your answers short and use Markdown for code.',
    ].filter(Boolean).join('\n\n');
  }

  async function runTool(call, view) {
    let args = call.input;
    if (args === undefined) {
      try {
        args = call.arguments ? JSON.parse(call.arguments) : {};
      } catch (e) {
        args = null;
      }
    }
    if (call.inputError || !args || typeof args !== 'object' || Array.isArray(args)) {
      const result = { text: 'Error: the tool arguments are not a JSON object.', images: [], isError: true };
      view.done(result);
      return result;
    }
    let result;
    try {
      const reply = await mcp('tools/call', { name: call.name, arguments: args });
      const content = (reply && reply.content) || [];
      result = {
        text: content.filter((c) => c.type === 'text').map((c) => c.text).join('\n'),
        images: content.filter((c) => c.type === 'image').map((c) => ({ data: c.data, mimeType: c.mimeType || 'image/png' })),
        isError: !!(reply && reply.isError),
      };
    } catch (e) {
      result = { text: `Error: ${e.message}`, images: [], isError: true };
    }
    view.done(result);
    return result;
  }

  function limitText(text) {
    if (text.length <= MAX_TOOL_TEXT) return text;
    return `${text.slice(0, MAX_TOOL_TEXT)}\n[Truncated: ${text.length - MAX_TOOL_TEXT} more characters.]`;
  }

  // WebMCP: the same tools for agents in the browser. Its tools return text, so
  // these are the tools without images, and not the admin tools.
  async function registerWebMcpTools() {
    const modelContext = document.modelContext || navigator.modelContext;
    if (!modelContext || typeof modelContext.registerTool !== 'function') return;
    await omeditReady;
    const options = { vision: false, admin: false };
    const list = await globalThis.omeditMcp({ jsonrpc: '2.0', id: ++mcpId, method: 'tools/list' }, options);
    for (const tool of (list && list.result && list.result.tools) || []) {
      const hints = tool.annotations || {};
      try {
        await modelContext.registerTool({
          name: tool.name,
          description: tool.description || '',
          inputSchema: tool.inputSchema || { type: 'object', properties: {} },
          annotations: { readOnlyHint: !!hints.readOnlyHint, consequentialHint: !!hints.destructiveHint },
          async execute(input) {
            const reply = await globalThis.omeditMcp({
              jsonrpc: '2.0', id: ++mcpId, method: 'tools/call', params: { name: tool.name, arguments: input || {} },
            }, options);
            if (reply && reply.error) throw new Error(reply.error.message);
            const result = (reply && reply.result) || {};
            const text = (result.content || []).filter((c) => c.type === 'text').map((c) => c.text).join('\n');
            if (result.isError) throw new Error(text || 'The tool failed.');
            return text;
          },
        });
      } catch (e) {
        console.warn(`WebMCP: could not register ${tool.name}:`, e);
      }
    }
  }
  registerWebMcpTools().catch((e) => console.warn('WebMCP:', e));


  function joinUrl(base, path) {
    return `${base.replace(/\/+$/, '')}/${path}`;
  }

  function unreachable(url) {
    let text = `Could not reach ${url}. Make sure that the server runs and that it accepts requests from ${location.origin} (CORS).`;
    if (/:11434\b/.test(url)) text += ` For Ollama, set OLLAMA_ORIGINS=${location.origin} before you start it.`;
    return new Error(text);
  }

  async function httpError(response, url) {
    let detail = '';
    try {
      const text = await response.text();
      try {
        const json = JSON.parse(text);
        detail = (json.error && (json.error.message || json.error)) || json.message || text;
      } catch (e) {
        detail = text;
      }
    } catch (e) {
      detail = '';
    }
    return new Error(`${response.status} ${response.statusText} from ${url}${detail ? `: ${detail}` : ''}`);
  }

  async function request(url, options) {
    let response;
    try {
      response = await fetch(url, options);
    } catch (e) {
      if (e.name === 'AbortError') throw e;
      throw unreachable(url);
    }
    if (!response.ok) throw await httpError(response, url);
    return response;
  }

  function post(url, headers, body, signal) {
    return request(url, { method: 'POST', headers, body: JSON.stringify(body), signal });
  }

  function isEventStream(response) {
    return (response.headers.get('content-type') || '').includes('text/event-stream');
  }

  async function readEvents(response, onData) {
    const reader = response.body.getReader();
    const decoder = new TextDecoder();
    let buffer = '';
    let data = [];
    const dispatch = () => {
      if (data.length) onData(data.join('\n'));
      data = [];
    };
    for (;;) {
      const { value, done } = await reader.read();
      buffer += decoder.decode(value || new Uint8Array(), { stream: !done });
      const lines = buffer.split(/\r?\n/);
      buffer = done ? '' : lines.pop();
      for (const line of lines) {
        if (line === '') dispatch();
        else if (line.startsWith('data:')) data.push(line.slice(5).replace(/^ /, ''));
      }
      if (done) break;
    }
    dispatch();
  }

  // complete() streams one model turn into the view and returns
  // { message, toolCalls, note }; message is the turn in the provider's format.

  const openai = {
    userMessage(text) {
      return { role: 'user', content: text };
    },

    async complete(history, tools, system, view, signal) {
      const url = joinUrl(settings.baseUrl || PROVIDERS.openai.url, 'chat/completions');
      const headers = { 'Content-Type': 'application/json' };
      if (settings.apiKey) headers.Authorization = `Bearer ${settings.apiKey}`;
      const body = { model: settings.model, messages: [{ role: 'system', content: system }, ...history], stream: true };
      if (tools.length) {
        body.tools = tools.map((t) => ({
          type: 'function',
          function: { name: t.name, description: t.description || '', parameters: t.inputSchema || { type: 'object', properties: {} } },
        }));
      }
      const response = await post(url, headers, body, signal);
      let text = '';
      let thinking = '';
      let finish = null;
      const calls = [];
      const onChoice = (choice) => {
        const delta = choice.delta || choice.message || {};
        const reasoning = delta.reasoning_content || delta.reasoning;
        if (reasoning) {
          thinking += reasoning;
          view.thinking(thinking);
        }
        if (delta.content) {
          text += delta.content;
          view.text(text);
        }
        (delta.tool_calls || []).forEach((toolCall, position) => {
          const index = toolCall.index ?? position;
          const call = calls[index] || (calls[index] = { key: index, id: '', name: '', arguments: '' });
          if (toolCall.id) call.id = toolCall.id;
          const fn = toolCall.function || {};
          if (fn.name && !call.name) call.name = fn.name;
          if (fn.arguments) call.arguments += typeof fn.arguments === 'string' ? fn.arguments : JSON.stringify(fn.arguments);
          if (call.name) view.tool(index, call.name, call.arguments);
        });
        if (choice.finish_reason) finish = choice.finish_reason;
      };
      const onJson = (json) => {
        if (json.error) throw new Error(json.error.message || String(json.error));
        (json.choices || []).forEach(onChoice);
      };
      if (isEventStream(response)) {
        await readEvents(response, (data) => {
          if (data !== '[DONE]') onJson(JSON.parse(data));
        });
      } else {
        onJson(await response.json());
      }
      const toolCalls = calls.filter((c) => c && c.name);
      toolCalls.forEach((c, i) => { if (!c.id) c.id = `call_${Date.now()}_${i}`; });
      let message = null;
      if (text || toolCalls.length) {
        message = { role: 'assistant', content: text };
        if (toolCalls.length) {
          message.tool_calls = toolCalls.map((c) => ({ id: c.id, type: 'function', function: { name: c.name, arguments: c.arguments || '{}' } }));
        }
      }
      return { message, toolCalls, note: finish === 'length' ? 'The reply was cut off at the output limit.' : null };
    },

    toolResults(calls, results) {
      const messages = calls.map((call, i) => ({
        role: 'tool', tool_call_id: call.id, content: limitText(results[i].text) || '(no output)',
      }));
      const images = results.flatMap((r) => r.images);
      if (settings.vision && images.length) {
        messages.push({
          role: 'user',
          content: [{ type: 'text', text: 'The images that the tools returned:' },
            ...images.map((im) => ({ type: 'image_url', image_url: { url: `data:${im.mimeType};base64,${im.data}` } }))],
        });
      }
      return messages;
    },

    async listModels() {
      const url = joinUrl(settings.baseUrl || PROVIDERS.openai.url, 'models');
      const headers = settings.apiKey ? { Authorization: `Bearer ${settings.apiKey}` } : {};
      const json = await (await request(url, { headers })).json();
      return (json.data || json.models || []).map((m) => m.id || m.name).filter(Boolean);
    },
  };

  const anthropic = {
    base() {
      return (settings.baseUrl || PROVIDERS.anthropic.url).replace(/\/+$/, '').replace(/\/v1$/, '');
    },

    headers() {
      const headers = {
        'content-type': 'application/json',
        'anthropic-version': '2023-06-01',
        'anthropic-dangerous-direct-browser-access': 'true',
      };
      if (settings.apiKey) headers['x-api-key'] = settings.apiKey;
      return headers;
    },

    userMessage(text) {
      return { role: 'user', content: [{ type: 'text', text }] };
    },

    async complete(history, tools, system, view, signal) {
      const url = joinUrl(this.base(), 'v1/messages');
      const body = { model: settings.model, max_tokens: 64000, system, messages: history, stream: true };
      if (tools.length) {
        body.tools = tools.map((t) => ({
          name: t.name, description: t.description || '', input_schema: t.inputSchema || { type: 'object', properties: {} },
        }));
      }
      const response = await post(url, this.headers(), body, signal);
      const blocks = [];
      const partialJson = [];
      const inputErrors = new Set();
      let stopReason = null;
      let stopDetails = null;
      const joined = (type, field) => blocks.filter((b) => b && b.type === type).map((b) => b[field]).join('\n\n');
      await readEvents(response, (data) => {
        const event = JSON.parse(data);
        switch (event.type) {
          case 'content_block_start': {
            const block = { ...event.content_block };
            blocks[event.index] = block;
            partialJson[event.index] = '';
            if (block.type === 'tool_use') view.tool(event.index, block.name, '');
            else if (block.type === 'thinking' || block.type === 'redacted_thinking') view.status('think', 'Thinking...');
            break;
          }
          case 'content_block_delta': {
            const block = blocks[event.index];
            const delta = event.delta;
            if (delta.type === 'text_delta') {
              block.text += delta.text;
              view.text(joined('text', 'text'));
            } else if (delta.type === 'input_json_delta') {
              partialJson[event.index] += delta.partial_json;
              view.tool(event.index, block.name, partialJson[event.index]);
            } else if (delta.type === 'thinking_delta') {
              block.thinking += delta.thinking;
              view.thinking(joined('thinking', 'thinking'));
            } else if (delta.type === 'signature_delta') {
              block.signature = (block.signature || '') + delta.signature;
            }
            break;
          }
          case 'content_block_stop': {
            const block = blocks[event.index];
            if (block.type === 'tool_use') {
              try {
                block.input = partialJson[event.index] ? JSON.parse(partialJson[event.index]) : {};
              } catch (e) {
                block.input = {};
                inputErrors.add(block.id);
              }
            }
            break;
          }
          case 'message_delta':
            if (event.delta && event.delta.stop_reason) stopReason = event.delta.stop_reason;
            if (event.delta && event.delta.stop_details) stopDetails = event.delta.stop_details;
            break;
          case 'error':
            throw new Error((event.error && event.error.message) || 'Error from the Anthropic API');
          default:
            break;
        }
      });
      const content = blocks.filter((b) => b && !(b.type === 'text' && !b.text));
      const toolCalls = [];
      blocks.forEach((b, key) => {
        if (b && b.type === 'tool_use') toolCalls.push({ key, id: b.id, name: b.name, input: b.input, inputError: inputErrors.has(b.id) });
      });
      let note = null;
      if (stopReason === 'refusal') {
        note = `The model declined the request${stopDetails && stopDetails.category ? ` (${stopDetails.category})` : ''}.`;
      } else if (stopReason === 'max_tokens') {
        note = 'The reply was cut off at the output limit.';
      }
      return { message: content.length ? { role: 'assistant', content } : null, toolCalls, note };
    },

    toolResults(calls, results) {
      return [{
        role: 'user',
        content: calls.map((call, i) => {
          const result = results[i];
          const content = [];
          if (result.text) content.push({ type: 'text', text: limitText(result.text) });
          for (const im of result.images) {
            content.push({ type: 'image', source: { type: 'base64', media_type: im.mimeType, data: im.data } });
          }
          if (!content.length) content.push({ type: 'text', text: '(no output)' });
          return { type: 'tool_result', tool_use_id: call.id, content, is_error: result.isError };
        }),
      }];
    },

    async listModels() {
      const url = joinUrl(this.base(), 'v1/models?limit=100');
      const json = await (await request(url, { headers: this.headers() })).json();
      return (json.data || []).map((m) => m.id);
    },
  };

  const ADAPTERS = { openai, anthropic };

  function escapeHtml(text) {
    return text.replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  }

  // Math for markdown-it: $...$, $$...$$, \(...\) and \[...\] go to KaTeX. The
  // inline rule runs before "escape", which would turn \( into (. A $ that opens
  // or closes next to a space, or is followed by a digit, is a price, not math.
  function mathPlugin(md, katex) {
    const render = (tex, display) => {
      try {
        return katex.renderToString(tex, { displayMode: display, throwOnError: false });
      } catch (e) {
        return `<code>${escapeHtml(tex)}</code>`;
      }
    };
    md.inline.ruler.before('escape', 'math_inline', (state, silent) => {
      const { src, pos } = state;
      const open = src.startsWith('\\(', pos) ? '\\(' : src.startsWith('$$', pos) ? '$$' : src[pos] === '$' ? '$' : null;
      if (!open) return false;
      const close = open === '\\(' ? '\\)' : open;
      const end = src.indexOf(close, pos + open.length);
      if (end <= pos + open.length) return false;
      const tex = src.slice(pos + open.length, end);
      if (open === '$' && (/^\s|\s$/.test(tex) || /\d/.test(src[end + 1] || ''))) return false;
      if (!silent) {
        const token = state.push('math_inline', 'math', 0);
        token.content = tex;
        token.info = open === '$$' ? 'display' : '';
      }
      state.pos = end + close.length;
      return true;
    });
    md.block.ruler.before('fence', 'math_block', (state, startLine, endLine, silent) => {
      if (state.sCount[startLine] - state.blkIndent >= 4) return false;
      const lineAt = (n) => state.src.slice(state.bMarks[n] + state.tShift[n], state.eMarks[n]);
      const first = lineAt(startLine);
      const close = first.startsWith('$$') ? '$$' : first.startsWith('\\[') ? '\\]' : null;
      if (!close) return false;
      if (silent) return true;
      const parts = [];
      let line = startLine;
      let rest = first.slice(2);
      for (;;) {
        const at = rest.indexOf(close);
        if (at >= 0) {
          parts.push(rest.slice(0, at));
          break;
        }
        parts.push(rest);
        if (++line >= endLine) break;
        rest = lineAt(line);
      }
      state.line = Math.min(line + 1, endLine);
      const token = state.push('math_block', 'math', 0);
      token.block = true;
      token.content = parts.join('\n');
      token.map = [startLine, state.line];
      return true;
    }, { alt: ['paragraph', 'reference', 'blockquote', 'list'] });
    md.renderer.rules.math_inline = (tokens, i) => render(tokens[i].content, tokens[i].info === 'display');
    md.renderer.rules.math_block = (tokens, i) => `<div class="as-math">${render(tokens[i].content, true)}</div>`;
  }

  // Raw HTML stays text (html: false) and markdown-it refuses javascript: and
  // similar links. An image becomes a link, so the page loads nothing the model names.
  function createMarkdown() {
    if (typeof globalThis.markdownit !== 'function') return null;
    const md = globalThis.markdownit({ html: false, linkify: true, breaks: true });
    if (globalThis.katex) mathPlugin(md, globalThis.katex);
    const linkOpen = md.renderer.rules.link_open || ((tokens, i, options, env, self) => self.renderToken(tokens, i, options));
    md.renderer.rules.link_open = (tokens, i, options, env, self) => {
      tokens[i].attrSet('target', '_blank');
      tokens[i].attrSet('rel', 'noopener noreferrer');
      return linkOpen(tokens, i, options, env, self);
    };
    md.renderer.rules.image = (tokens, i) => {
      const src = tokens[i].attrGet('src') || '';
      return `<a href="${escapeHtml(src)}" target="_blank" rel="noopener noreferrer">${escapeHtml(tokens[i].content || src)}</a>`;
    };
    return md;
  }

  const markdown = createMarkdown();

  function renderMarkdown(source) {
    if (markdown) return markdown.render(source);
    return `<p>${escapeHtml(source).replace(/\n/g, '<br>')}</p>`;
  }

  // Some servers return the reasoning of a model inline as <think>...</think>.
  function splitThinking(text) {
    const match = text.match(/^\s*<think>([\s\S]*?)(<\/think>|$)/);
    if (!match) return { thinking: '', text };
    return { thinking: match[1].trim(), text: text.slice(match[0].length) };
  }


  const ICONS = {
    chat: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>',
    plus: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M12 5v14M5 12h14"/></svg>',
    gear: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>',
    hide: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m9 18 6-6-6-6"/></svg>',
  };

  function el(tag, attributes, ...children) {
    const node = document.createElement(tag);
    for (const [key, value] of Object.entries(attributes || {})) {
      if (key === 'html') node.innerHTML = value;
      else if (key === 'text') node.textContent = value;
      else if (key.startsWith('on')) node.addEventListener(key.slice(2), value);
      else if (value === true) node.setAttribute(key, '');
      else if (value !== false && value != null) node.setAttribute(key, value);
    }
    for (const child of children) if (child != null) node.append(child);
    return node;
  }

  const root = document.getElementById('assistant');
  const splitter = document.getElementById('assistant-splitter');
  if (!root || !splitter) return;

  const providerSelect = el('select', { name: 'provider' },
    ...Object.entries(PROVIDERS).map(([id, p]) => el('option', { value: id, text: p.label })));
  const urlInput = el('input', { type: 'url', name: 'baseUrl', autocomplete: 'off', spellcheck: 'false' });
  const keyInput = el('input', { type: 'password', name: 'apiKey', autocomplete: 'off' });
  const modelInput = el('input', { type: 'text', name: 'model', list: 'as-models', autocomplete: 'off', spellcheck: 'false' });
  const modelList = el('datalist', { id: 'as-models' });
  const visionInput = el('input', { type: 'checkbox', name: 'vision' });
  const adminInput = el('input', { type: 'checkbox', name: 'admin' });
  const settingsNote = el('p', { class: 'as-note', text: 'The settings and the API key are stored in this browser.' });
  const settingsPanel = el('section', { class: 'as-settings', hidden: true },
    el('label', {}, 'Provider', providerSelect),
    el('label', {}, 'Server URL', urlInput),
    el('label', {}, 'API key', keyInput),
    el('label', {}, 'Model', el('span', { class: 'as-row' }, modelInput,
      el('button', { type: 'button', class: 'as-button', text: 'List', title: 'Get the models from the server', onclick: listModels }))),
    modelList,
    el('label', { class: 'as-check' }, visionInput, 'Send images (diagrams, plots) to the model'),
    el('label', { class: 'as-check' }, adminInput, 'Allow the tools that load files and libraries and reset OMEdit'),
    settingsNote);

  const status = el('span', { class: 'as-status' });
  const settingsButton = el('button', { type: 'button', class: 'as-icon', title: 'Settings', 'aria-pressed': 'false', html: ICONS.gear, onclick: toggleSettings });
  const newButton = el('button', { type: 'button', class: 'as-icon', title: 'New chat', html: ICONS.plus, onclick: newChat });
  const messages = el('div', { class: 'as-messages', role: 'log', 'aria-live': 'polite' });
  const textarea = el('textarea', { rows: '3', placeholder: 'Ask about the classes in OMEdit, or ask to build, simulate and plot a model' });
  const sendButton = el('button', { type: 'submit', class: 'as-button primary', text: 'Send' });
  const hint = el('span', { class: 'as-hint', text: 'Enter sends, Shift+Enter starts a new line' });
  const stopButton = el('button', { type: 'button', class: 'as-button', text: 'Stop', hidden: true, onclick: stop });
  const form = el('form', { class: 'as-input' }, textarea,
    el('div', { class: 'as-actions' }, hint, stopButton, sendButton));

  root.append(
    el('button', { type: 'button', class: 'as-tab', title: 'Show the assistant', onclick: () => setOpen(true), html: `${ICONS.chat}<span>Assistant</span>` }),
    el('div', { class: 'as-panel' },
      el('header', { class: 'as-header' },
        el('span', { class: 'as-title', text: 'Assistant' }), status, newButton, settingsButton,
        el('button', { type: 'button', class: 'as-icon', title: 'Hide the assistant', html: ICONS.hide, onclick: () => setOpen(false) })),
      settingsPanel, messages, form));
  root.querySelectorAll('.as-tab svg').forEach((svg) => { svg.style.width = '16px'; svg.style.height = '16px'; });

  // Keyboard and clipboard events in the panel are not for OMEdit.
  for (const type of ['keydown', 'keyup', 'keypress', 'paste', 'copy', 'cut']) {
    root.addEventListener(type, (event) => event.stopPropagation());
  }

  function showSettings() {
    providerSelect.value = settings.provider;
    urlInput.value = settings.baseUrl;
    keyInput.value = settings.apiKey;
    modelInput.value = settings.model;
    visionInput.checked = settings.vision;
    adminInput.checked = settings.admin;
    const provider = PROVIDERS[settings.provider];
    urlInput.placeholder = provider.url;
    modelInput.placeholder = provider.model;
    status.textContent = `${settings.model || 'No model'} · ${provider.short}`;
  }

  function readSettings() {
    const providerChanged = providerSelect.value !== settings.provider;
    Object.assign(settings, {
      provider: providerSelect.value,
      baseUrl: urlInput.value.trim(),
      apiKey: keyInput.value.trim(),
      model: modelInput.value.trim(),
      vision: visionInput.checked,
      admin: adminInput.checked,
    });
    saveSettings();
    showSettings();
    if (providerChanged && conversation.messages.length && !running) {
      conversation = { provider: settings.provider, messages: [] };
      showEmpty();
      notice('The provider changed, so a new chat starts.');
    }
  }
  settingsPanel.addEventListener('change', readSettings);

  function toggleSettings(open) {
    const show = typeof open === 'boolean' ? open : settingsPanel.hidden;
    settingsPanel.hidden = !show;
    settingsButton.setAttribute('aria-pressed', String(show));
  }

  async function listModels() {
    readSettings();
    settingsNote.textContent = 'Getting the models...';
    try {
      const models = await ADAPTERS[settings.provider].listModels();
      modelList.replaceChildren(...models.map((id) => el('option', { value: id })));
      settingsNote.textContent = models.length ? `${models.length} models. Select one in the Model field.` : 'The server has no models.';
    } catch (e) {
      settingsNote.textContent = e.message;
    }
  }

  function setOpen(open) {
    settings.open = open;
    saveSettings();
    root.classList.toggle('collapsed', !open);
    document.body.classList.toggle('assistant-collapsed', !open);
    window.dispatchEvent(new Event('resize'));
    if (open) textarea.focus();
  }

  function setWidth(width) {
    settings.width = Math.round(Math.max(280, Math.min(width, window.innerWidth - 320)));
    root.style.setProperty('--as-width', `${settings.width}px`);
  }

  splitter.addEventListener('pointerdown', (event) => {
    splitter.setPointerCapture(event.pointerId);
    splitter.classList.add('dragging');
    document.body.classList.add('assistant-dragging');
  });
  splitter.addEventListener('pointermove', (event) => {
    if (splitter.hasPointerCapture(event.pointerId)) setWidth(window.innerWidth - event.clientX);
  });
  const endDrag = (event) => {
    if (!splitter.hasPointerCapture(event.pointerId)) return;
    splitter.releasePointerCapture(event.pointerId);
    splitter.classList.remove('dragging');
    document.body.classList.remove('assistant-dragging');
    saveSettings();
    window.dispatchEvent(new Event('resize'));
  };
  splitter.addEventListener('pointerup', endDrag);
  splitter.addEventListener('pointercancel', endDrag);

  function scrollDown() {
    messages.scrollTop = messages.scrollHeight;
  }

  function add(node) {
    const empty = messages.querySelector('.as-empty');
    if (empty) empty.remove();
    const atBottom = messages.scrollHeight - messages.scrollTop - messages.clientHeight < 40;
    messages.append(node);
    if (atBottom) scrollDown();
    return node;
  }

  function showEmpty() {
    messages.replaceChildren(el('p', { class: 'as-empty',
      text: 'Ask about the classes that are loaded in OMEdit, or ask to build, simulate and plot a model. Set the server and the model in the settings first.' }));
  }

  function notice(text) {
    add(el('div', { class: 'as-msg notice', text }));
  }

  function showError(error) {
    add(el('div', { class: 'as-msg error', text: error.message || String(error) }));
  }

  const HINT = 'Enter sends, Shift+Enter starts a new line';
  const live = {
    kind: '', text: '', since: 0, timer: null, painted: 0,
    set(kind, text) {
      if (kind !== this.kind) this.since = Date.now();
      this.kind = kind;
      this.text = text;
      if (!this.timer) this.timer = setInterval(() => this.paint(), 1000);
      if (Date.now() - this.painted > 100) this.paint();
    },
    paint() {
      this.painted = Date.now();
      hint.classList.toggle('live', !!this.text);
      hint.textContent = this.text ? `${this.text} · ${Math.round((Date.now() - this.since) / 1000)} s` : HINT;
    },
    end() {
      clearInterval(this.timer);
      this.timer = null;
      this.kind = '';
      this.text = '';
      this.paint();
    },
  };
  const characters = (text) => `${text.length.toLocaleString()} characters`;

  function assistantView() {
    let thinkingNode = null;
    let thinkingClosed = false;
    let textNode = null;
    let pending = null;
    const tools = new Map();
    const render = () => {
      pending = null;
      const atBottom = messages.scrollHeight - messages.scrollTop - messages.clientHeight < 40;
      if (thinkingNode && thinkingNode.dataset.text) {
        const body = thinkingNode.querySelector('.body');
        const follow = body.scrollHeight - body.scrollTop - body.clientHeight < 40;
        body.textContent = thinkingNode.dataset.text;
        if (follow) body.scrollTop = body.scrollHeight;
      }
      if (textNode) textNode.innerHTML = renderMarkdown(textNode.dataset.text);
      if (atBottom) scrollDown();
    };
    const schedule = () => {
      if (!pending) pending = requestAnimationFrame(render);
    };
    const closeThinking = () => {
      if (thinkingNode && !thinkingClosed) thinkingNode.open = false;
      thinkingClosed = true;
    };
    const setThinking = (text) => {
      if (!text) return;
      if (!thinkingNode) {
        thinkingNode = el('details', { class: 'as-thinking', open: !thinkingClosed }, el('summary', { text: 'Thinking' }), el('div', { class: 'body' }));
        if (textNode) textNode.before(thinkingNode);
        else add(thinkingNode);
      }
      thinkingNode.dataset.text = text;
      if (!thinkingClosed) live.set('think', `Thinking... ${characters(text)}`);
      schedule();
    };
    let reasoning = '';
    live.set('wait', 'Waiting for the model...');
    return {
      status(kind, text) {
        live.set(kind, text);
      },
      thinking(text) {
        reasoning = text;
        setThinking(text);
      },
      text(text) {
        const split = splitThinking(text);
        if (split.thinking) setThinking([reasoning, split.thinking].filter(Boolean).join('\n\n'));
        if (!split.text.trim()) return;
        closeThinking();
        if (!textNode) textNode = add(el('div', { class: 'as-msg assistant' }));
        textNode.dataset.text = split.text;
        live.set('text', `Writing the answer... ${characters(split.text)}`);
        schedule();
      },
      tool(key, name, argumentText) {
        closeThinking();
        if (!tools.has(key)) tools.set(key, toolView(name));
        tools.get(key).update(argumentText);
        live.set(`tool${key}`, `Writing a call to ${name}... ${characters(argumentText)}`);
      },
      toolView(call) {
        const view = tools.get(call.key) || toolView(call.name);
        view.start(call);
        live.set(`run${call.key}`, `Running ${call.name}...`);
        return view;
      },
    };
  }

  function toolView(name) {
    const state = el('span', { class: 'state', text: 'writing...' });
    const args = el('span', { class: 'args' });
    const argumentsBlock = el('pre');
    const body = el('div', { class: 'body' }, el('h5', { text: 'Arguments' }), argumentsBlock);
    const node = add(el('details', { class: 'as-tool' },
      el('summary', {}, el('span', { class: 'name', text: name }), args, state),
      body));
    let latest = '';
    let pending = null;
    return {
      update(argumentText) {
        latest = argumentText;
        if (!pending) {
          pending = requestAnimationFrame(() => {
            pending = null;
            args.textContent = latest.length > 200 ? `...${latest.slice(-200)}` : latest;
          });
        }
      },
      start(call) {
        if (pending) cancelAnimationFrame(pending);
        pending = null;
        const argumentText = call.input !== undefined ? JSON.stringify(call.input) : (call.arguments || '{}');
        args.textContent = argumentText === '{}' ? '' : argumentText;
        try {
          argumentsBlock.textContent = JSON.stringify(JSON.parse(argumentText), null, 2);
        } catch (e) {
          argumentsBlock.textContent = argumentText;
        }
        state.textContent = 'running...';
      },
      done(result) {
        node.classList.add(result.isError ? 'failed' : 'ok');
        state.textContent = result.isError ? 'failed' : 'done';
        body.append(el('h5', { text: 'Result' }));
        if (result.text) body.append(el('pre', { text: result.text.length > 20000 ? `${result.text.slice(0, 20000)}\n...` : result.text }));
        for (const image of result.images) {
          const img = el('img', { src: `data:${image.mimeType};base64,${image.data}`, alt: `Image from ${name}` });
          body.append(img);
          add(el('div', { class: 'as-msg' }, img.cloneNode()));
        }
      },
    };
  }

  function setRunning(isRunning) {
    root.classList.toggle('running', isRunning);
    sendButton.hidden = isRunning;
    stopButton.hidden = !isRunning;
    newButton.disabled = isRunning;
  }

  function stop() {
    if (!running) return;
    running.stopped = true;
    running.controller.abort();
  }

  function newChat() {
    if (running) return;
    conversation = { provider: settings.provider, messages: [] };
    showEmpty();
    textarea.focus();
  }

  async function waitForOMEdit() {
    if (globalThis.omeditMcp) return;
    const waiting = add(el('div', { class: 'as-msg notice', text: 'Waiting for OMEdit to start...' }));
    await omeditReady;
    waiting.remove();
  }

  // The point in the history before a user message, to go back to. Anthropic
  // takes the text after tool results into the same user message.
  function historyMark() {
    const history = conversation.messages;
    const last = history[history.length - 1];
    const merge = settings.provider === 'anthropic' && last && last.role === 'user';
    return { conversation, length: history.length, content: merge ? last.content.length : -1 };
  }

  function truncateHistory(mark) {
    const history = mark.conversation.messages;
    history.length = mark.length;
    if (mark.content >= 0) history[mark.length - 1].content.length = mark.content;
  }

  function rewind(turn) {
    if (turn.mark.conversation === conversation) truncateHistory(turn.mark);
    while (turn.nextSibling) turn.nextSibling.remove();
    turn.remove();
    if (!messages.children.length) showEmpty();
  }

  function userTurn(text, mark) {
    const turn = el('div', { class: 'as-turn' }, el('div', { class: 'as-msg user', text }));
    turn.mark = mark;
    turn.append(el('div', { class: 'as-msg-actions' },
      el('button', { type: 'button', text: 'Edit', title: 'Edit this message. The chat goes back to here; the changes in OMEdit stay.',
        onclick: () => {
          if (running) return;
          rewind(turn);
          textarea.value = text;
          textarea.focus();
        } }),
      el('button', { type: 'button', text: 'Retry', title: 'Send this message again from here. The changes in OMEdit stay.',
        onclick: () => {
          if (running) return;
          rewind(turn);
          send(text);
        } })));
    return add(turn);
  }

  async function send(text) {
    if (running) return;
    if (!settings.model) {
      toggleSettings(true);
      showError(new Error('Set the model in the settings.'));
      return;
    }
    toggleSettings(false);
    const adapter = ADAPTERS[settings.provider];
    if (conversation.provider !== settings.provider) conversation = { provider: settings.provider, messages: [] };
    const history = conversation.messages;
    const mark = historyMark();
    userTurn(text, mark);
    if (mark.content >= 0) {
      history[history.length - 1].content.push({ type: 'text', text });
    } else {
      history.push(adapter.userMessage(text));
    }
    running = { controller: new AbortController(), stopped: false };
    setRunning(true);
    try {
      await waitForOMEdit();
      const { tools, instructions } = await getTools();
      for (let step = 0; ; step++) {
        if (step === MAX_STEPS) {
          notice(`Stopped after ${MAX_STEPS} model calls.`);
          break;
        }
        const view = assistantView();
        let turn;
        try {
          turn = await adapter.complete(history, tools, systemPrompt(instructions), view, running.controller.signal);
        } catch (e) {
          if (running.stopped) {
            notice('Stopped.');
            return;
          }
          throw e;
        }
        if (turn.message) history.push(turn.message);
        if (turn.note) notice(turn.note);
        if (!turn.toolCalls.length) break;
        const results = [];
        for (const call of turn.toolCalls) results.push(await runTool(call, view.toolView(call)));
        history.push(...adapter.toolResults(turn.toolCalls, results));
        if (running.stopped) {
          notice('Stopped.');
          return;
        }
      }
    } catch (e) {
      truncateHistory(mark);
      showError(e);
    } finally {
      running = null;
      live.end();
      setRunning(false);
    }
  }

  const sentTexts = [];
  let recalled = -1;
  form.addEventListener('submit', (event) => {
    event.preventDefault();
    const text = textarea.value.trim();
    if (!text || running) return;
    textarea.value = '';
    if (sentTexts[sentTexts.length - 1] !== text) sentTexts.push(text);
    recalled = -1;
    send(text);
  });
  textarea.addEventListener('keydown', (event) => {
    if (event.key === 'Enter' && !event.shiftKey && !event.isComposing) {
      event.preventDefault();
      form.requestSubmit();
      return;
    }
    const up = event.key === 'ArrowUp';
    if ((up || event.key === 'ArrowDown') && sentTexts.length
        && (textarea.value === '' || (recalled >= 0 && textarea.value === sentTexts[recalled]))) {
      event.preventDefault();
      if (up) recalled = recalled < 0 ? sentTexts.length - 1 : Math.max(0, recalled - 1);
      else if (recalled >= 0) recalled = recalled + 1 < sentTexts.length ? recalled + 1 : -1;
      textarea.value = recalled >= 0 ? sentTexts[recalled] : '';
    }
  });

  showSettings();
  showEmpty();
  setWidth(settings.width);
  root.classList.toggle('collapsed', !settings.open);
  document.body.classList.toggle('assistant-collapsed', !settings.open);
  if (!settings.model) toggleSettings(true);
})();
