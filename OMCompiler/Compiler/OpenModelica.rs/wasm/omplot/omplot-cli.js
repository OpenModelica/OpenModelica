#!/usr/bin/env node
// Runs omplot.wasm (the OMPlot module built for wasm32-wasip1) under Node's
// WASI: `node omplot-cli.js vars Model_res.arrow`. The host filesystem is
// preopened at `/`; result-file arguments are passed as absolute host paths.
import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { WASI } from 'node:wasi';

const isFile = (a) => /\.(mat|arrow|csv|plt)$/.test(a) || a.includes('/');
const args = process.argv.slice(2).map((a) => (a.startsWith('--') || !isFile(a) ? a : resolve(a)));
const wasi = new WASI({ version: 'preview1', args: ['omplot', ...args], env: {}, preopens: { '/': '/' }, returnOnExit: true });
const wasm = await WebAssembly.compile(await readFile(new URL('./omplot.wasm', import.meta.url)));
const instance = await WebAssembly.instantiate(wasm, wasi.getImportObject());
process.exitCode = wasi.start(instance);
