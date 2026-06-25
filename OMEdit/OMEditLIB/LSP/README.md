# OMEdit Language Server Protocol (LSP) Client

OMEdit includes an opt-in [Language Server Protocol (LSP)](https://microsoft.github.io/language-server-protocol/)
client that connects to an external Modelica language server and surfaces its
capabilities inside the text editor.

## Features

| Feature | How it works |
|---|---|
| **Hover** | Pause the mouse over a symbol — a tooltip shows its documentation. |
| **Go to definition** | Ctrl+Click a symbol to jump to where it is defined, including across files. |
| **Document symbols** | The client keeps every open document in sync so the server always sees the latest text. |

## Enabling the LSP client

### Via the Options dialog

Open *Tools > Options > Language Server* and:

1. Check *Enable Language Server Protocol (LSP)*.
2. Leave *Server Executable* blank — OMEdit will use the bundled server automatically.
3. Click *OK* and restart OMEdit.

If Node.js is not installed, a setup dialog appears with platform-specific
installation instructions.

### Via omedit.ini

Edit `~/.config/openmodelica/omedit.ini` and add:

```ini
[languageServer]
enabled=true
executable=
```

Leave `executable` empty to use the bundled server (requires Node.js on PATH).

## Runtime requirement: Node.js

The bundled server is a JavaScript file; Node.js must be installed to run it.
OMEdit detects this automatically and shows a one-time setup dialog if Node.js
is missing.

| Platform | Install command |
|---|---|
| **Windows** | `winget install OpenJS.NodeJS.LTS` |
| **macOS** | `brew install node` |
| **Linux (Debian/Ubuntu)** | `sudo apt install nodejs` |
| **Linux (Fedora/RHEL)** | `sudo dnf install nodejs` |

Or download directly from [nodejs.org](https://nodejs.org).

## Using a custom server

Set *Server Executable* to any LSP-compatible Modelica server executable:

- A standalone binary: set the path directly, no Node.js needed.
- A `.js` file: OMEdit calls `node <path>` automatically.

## Bundled server

OMEdit ships with a pre-built copy of the
[Modelica Language Server](https://github.com/OpenModelica/modelica-language-server)
in `<install_prefix>/share/omedit/languageserver/` (Linux/macOS) or
`<install_prefix>/bin/languageserver/` (Windows).

The bundle consists of three files that must stay together:
- `server.js` — the language server bundle
- `tree-sitter-modelica.wasm` — Modelica grammar for tree-sitter
- `web-tree-sitter.wasm` — the tree-sitter WebAssembly runtime

## Architecture

`LSPClient` (`LSPClient.h` / `LSPClient.cpp`) manages one `QProcess` and speaks
JSON-RPC 2.0 with `Content-Length` framing.  When the executable ends with `.js`,
`LSPClient::start()` automatically prepends `node` as the program and passes the
`.js` path as an argument.

`LSPSetupDialog` (`LSPSetupDialog.h` / `LSPSetupDialog.cpp`) is shown on startup
when the bundled server is present but Node.js is not on PATH.

`LSPProtocol.h` defines the `LSP::Position`, `LSP::Range`, `LSP::Location`, and
`LSP::DocumentSymbol` data structures.
