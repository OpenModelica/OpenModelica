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

const omc = require(path.join(__dirname, 'pkg-nodejs', 'OpenModelicaCompiler.js'));

// omc_eval is synchronous and cannot await a network fetch, so a download-driven
// command (installPackage, updatePackageIndex) does not fetch its files — it
// records them as pending and fails (see Curl_wasm.rs). Mirror the browser
// Worker's retry loop here, but synchronously: run the command, fetch any pending
// files with the `curl` binary (browsers stream with progress; Node just blocks),
// stage them in the VFS, and re-run until nothing new is needed. `attempted`
// stops an undownloadable file from looping forever. Without curl, downloads
// simply fail as before.
function evalWithDownloads(src) {
  const attempted = new Set();
  for (;;) {
    const result = omc.omc_eval(src);
    const pending = omc.omc_take_pending_downloads() || [];
    const todo = pending.filter((p) => !attempted.has(p.filename));
    if (todo.length === 0) return result;
    omc.omc_eval('getErrorString()'); // discard the aborted run's diagnostics
    for (const item of todo) {
      attempted.add(item.filename);
      for (const url of item.urls) {
        try {
          const buf = execFileSync('curl', ['-sSL', '-m', '120', '--fail', url], { maxBuffer: 1 << 30 });
          omc.wasi_write_file(item.filename, new Uint8Array(buf));
          break;
        } catch {
          // try the next mirror
        }
      }
    }
  }
}

// Seed the install dir (no OS environment inside wasm). The builtin Modelica
// environment is embedded (openmodelica_wasi), so OPENMODELICAHOME only needs to
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
  process.stdout.write(evalWithDownloads(oneShot));
  process.stdout.write('\n');
  process.exit(0);
}

const rl = readline.createInterface({ input: process.stdin, output: process.stdout, prompt: '>>> ' });
rl.prompt();
rl.on('line', (line) => {
  const cmd = line.trim();
  if (cmd === 'quit()' || cmd === 'exit') { rl.close(); return; }
  if (cmd) process.stdout.write(evalWithDownloads(cmd) + '\n');
  rl.prompt();
});
rl.on('close', () => process.exit(0));
