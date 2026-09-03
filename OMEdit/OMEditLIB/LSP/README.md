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

1. Check the *Language Server Protocol (LSP)* group.
2. Leave *Server Executable* blank — OMEdit uses a bundled server automatically if one
   was installed with it (see [Bundled server](#bundled-server)); otherwise use
   *Download...* to fetch one.
3. Click *OK*. The language server starts immediately.

If Node.js is not installed, a setup dialog appears offering the two ways to get
a server: downloading a standalone one, or installing Node.js to use the bundled
one.

### Via omedit.ini

Edit `~/.config/openmodelica/omedit.ini` and add:

```ini
[languageServer]
enabled=true
executable=
```

Leave `executable` empty to use the bundled server (requires Node.js on PATH), or
point it at a standalone server binary, which does not.

## Getting a server

### Standalone binary (no Node.js)

*Download...* on the options page fetches a standalone server for the current
platform into OMEdit's application data directory and points *Server Executable*
at it. The Node.js runtime is built into that executable, so nothing else has to
be installed. The drop-down beside the button chooses between the release OMEdit
was built against and the latest one published.

The download is verified: OMEdit reads the SHA256 the GitHub release publishes for
each asset, hashes what it received, and writes the files out only if they match —
so a corrupted or substituted download never becomes the executable it starts. The
server binary and both WASM files are staged in a temporary directory and only
replace an installed server once all three have arrived and passed. If a release
publishes no checksums (older ones do not), OMEdit says which files cannot be
verified and asks before downloading them, defaulting to no.

### Bundled server (needs Node.js)

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

## Crash recovery

If the server process exits unexpectedly, `LSPClient` restarts it automatically
after a short delay, up to 5 times within a 3-minute window (matching
`vscode-languageclient`'s default policy). Once that limit is hit it stops
retrying and reports the failure as an error message. Every crash and restart
attempt is also appended to `languageserver_crash.log` in OMEdit's temporary
directory (see *Tools > Open Temporary Directory*), so the log can be attached
to a bug report.

## Using a custom server

Set *Server Executable* to any LSP-compatible Modelica server executable:

- A standalone binary: set the path directly, no Node.js needed.
- A `.js` file: OMEdit calls `node <path>` automatically.

## Bundled server

A build can install a copy of the
[Modelica Language Server](https://github.com/OpenModelica/modelica-language-server)
in `<install_prefix>/share/omedit/languageserver/` (Linux/macOS) or
`<install_prefix>/bin/languageserver/` (Windows). **The build never downloads one.** A
default build installs no server; the user gets one from *Download...* on the options
page, or points *Server Executable* at a server they already have.

The bundle consists of three files that must stay together:
- `server.js` — the language server bundle
- `tree-sitter-modelica.wasm` — Modelica grammar for tree-sitter
- `web-tree-sitter.wasm` — the tree-sitter WebAssembly runtime

To install a server with OMEdit, build one yourself and configure with
`-DMODELICA_LS_DIR=<dir>`, where `<dir>` holds those three files — mainly useful when
developing against an unreleased server version. CMake copies them into the install tree
and warns (without failing) if any is missing. Nothing is fetched at configure time.

`MODELICA_LS_VERSION` is unrelated to installing: it names the release the options page
offers to download, and is passed to `OMEditLib` as a compile definition so the version
OMEdit was tested with is the one it offers.

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
