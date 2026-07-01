# OMEdit Language Server Protocol (LSP) Client

OMEdit includes an opt-in [Language Server Protocol (LSP)](https://microsoft.github.io/language-server-protocol/)
client that connects to an external Modelica language server and surfaces its
capabilities inside the text editor.

## Features

| Feature | How it works |
|---|---|
| **Hover** | Pause the mouse over a symbol — a tooltip shows its documentation. |
| **Go to definition** | Ctrl+Click a symbol, or pick *Go to Definition* from the right-click menu, to jump to where it is defined (including across files). Falls back to OMEdit's built-in class navigation when the server cannot resolve the symbol. |
| **Document sync** | Open documents are kept in sync (`didOpen`/`didChange`/`didClose`) so the server always sees the latest text. |

## Enabling the LSP client

### Via the Options dialog

Open *Tools > Options > Language Server* and:

1. Check *Enable Language Server*.
2. Leave *Server Executable* blank — OMEdit will use the bundled server automatically.
3. Click *OK*. The language server starts immediately.

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

The bundled server is a JavaScript file; **Node.js (version 16 or later)** must be
installed to run it. OMEdit detects this automatically and shows a one-time setup
dialog when the language server is enabled while Node.js is missing.

| Platform | Install command |
|---|---|
| **Windows** | `winget install OpenJS.NodeJS.LTS` |
| **macOS** | `brew install node` |
| **Linux (Debian/Ubuntu)** | `sudo apt install nodejs` |
| **Linux (Fedora/RHEL)** | `sudo dnf install nodejs` |

Or download directly from [nodejs.org](https://nodejs.org). On older Debian/Ubuntu
releases the distribution `nodejs` package may be too old; install a current
release from [NodeSource](https://github.com/nodesource/distributions) or via
[nvm](https://github.com/nvm-sh/nvm) instead.

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

`LSPClient` (`LSPClient.h` / `LSPClient.cpp`) is an abstract base that manages one
`QProcess` and speaks JSON-RPC 2.0 with `Content-Length` framing.  When the
executable ends with `.js`, `LSPClient::start()` automatically prepends `node` as
the program and passes the `.js` path as an argument.

`ModelicaLSPClient` (`ModelicaLSPClient.h` / `ModelicaLSPClient.cpp`) is the
concrete client for the Modelica language server.  It locates the bundled server
and supplies the Modelica-specific initialization options (the library search
path).

`LSPSetupDialog` (`LSPSetupDialog.h` / `LSPSetupDialog.cpp`) is shown when the
user enables the bundled JavaScript server but Node.js is not found on PATH.

`LSPProtocol.h` defines the `LSP::Position`, `LSP::Range`, and `LSP::Location`
data structures.
