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
2. Leave *Server Executable* blank to use `modelica-language-server` from `PATH`, or
   click *Browse* / *Auto Detect* to locate it manually.
3. Click *OK* and restart OMEdit.

### Via omedit.ini

Edit `~/.config/openmodelica/omedit.ini` and add:

```ini
[languageServer]
enabled=true
executable=
```

Leave `executable` empty to use `PATH` auto-detection.

## Installing the language server

The officially supported server is the
[Modelica Language Server](https://github.com/OpenModelica/modelica-language-server).
Install it with npm:

```sh
npm install --global modelica-language-server
```

Or point *Server Executable* at any LSP-compatible Modelica server that communicates
over stdin/stdout.

## Architecture

`LSPClient` (`LSPClient.h` / `LSPClient.cpp`) manages one `QProcess` and speaks
JSON-RPC 2.0 with `Content-Length` framing.  Each `ModelicaEditor` connects to
the client's signals and tracks pending request IDs so multiple open editors do
not interfere with each other.

`LSPProtocol.h` defines the `LSP::Position`, `LSP::Range`, `LSP::Location`, and
`LSP::DocumentSymbol` data structures used throughout the integration.

The client is instantiated in `OMEditApplication.cpp` (after settings are read) and
stored on `MainWindow` via `setLSPClient()`.
