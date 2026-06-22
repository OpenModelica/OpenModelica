#!/usr/bin/env node
//
// Minimal OpenModelica wasm CLI. Loads the wasm-bindgen package built by
// wasm/build.sh, initialises the compiler runtime, then evaluates interactive
// commands as strings and prints the replies — the same string-to-string
// protocol the interactive ZeroMQ server speaks.
//
//   node wasm/omc-cli.js 'getVersion()'     # one-shot
//   node wasm/omc-cli.js                     # REPL (Ctrl-D or quit() to exit)
//
'use strict';

const path = require('node:path');
const readline = require('node:readline');
const { execFileSync } = require('node:child_process');

// The Curl package (Curl_wasm.rs) downloads via a *synchronous* XMLHttpRequest —
// which browsers provide but Node does not. Shim a minimal one backed by the
// `curl` binary so download-driven commands (installPackage, updatePackageIndex)
// work from the Node CLI too. Without curl, downloads simply fail as before.
if (typeof globalThis.XMLHttpRequest === 'undefined') {
  globalThis.XMLHttpRequest = class {
    open(_method, url, _async) { this._url = url; this._status = 0; this._text = ''; }
    overrideMimeType() {}
    setRequestHeader() {}
    send() {
      try {
        const buf = execFileSync('curl', ['-sSL', '-m', '120', '--fail', this._url], { maxBuffer: 1 << 30 });
        // charset=x-user-defined contract: the low byte of each char is the raw byte.
        this._text = buf.toString('latin1');
        this._status = 200;
      } catch {
        this._status = 0;
        this._text = '';
      }
    }
    get status() { return this._status; }
    get responseText() { return this._text; }
  };
}

const omc = require(path.join(__dirname, 'pkg-nodejs', 'OpenModelicaCompiler.js'));

// Seed the install dir (no OS environment inside wasm). The builtin Modelica
// environment is embedded (openmodelica_vfs), so OPENMODELICAHOME only needs to
// be a non-empty path — the builtins resolve by basename regardless of value.
omc.omc_set_env('OPENMODELICAHOME', process.env.OPENMODELICAHOME || '/usr');

if (!omc.omc_init()) {
  // The wasm32-unknown-unknown build has no filesystem / OPENMODELICAHOME yet,
  // so full initialisation (loading the Modelica library, etc.) may not
  // complete; simple, self-contained commands can still work.
  console.error('warning: omc_init() reported failure (no filesystem/OPENMODELICAHOME in this wasm build)');
}

const oneShot = process.argv.slice(2).join(' ').trim();
if (oneShot) {
  process.stdout.write(omc.omc_eval(oneShot));
  process.stdout.write('\n');
  process.exit(0);
}

const rl = readline.createInterface({ input: process.stdin, output: process.stdout, prompt: '>>> ' });
rl.prompt();
rl.on('line', (line) => {
  const cmd = line.trim();
  if (cmd === 'quit()' || cmd === 'exit') { rl.close(); return; }
  if (cmd) process.stdout.write(omc.omc_eval(cmd) + '\n');
  rl.prompt();
});
rl.on('close', () => process.exit(0));
