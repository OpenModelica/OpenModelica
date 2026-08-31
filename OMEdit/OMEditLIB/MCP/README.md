# OMEdit MCP Server

OMEdit includes a built-in [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) server that exposes Modelica scripting tools to AI assistants.

## Enabling the MCP Server

Edit `~/.config/openmodelica/omedit.ini` and add the following section:

```ini
[modelContextProtocol]
enableAdminTools=true
enabled=true
port=3000
```

Restart OMEdit. The MCP server will be available at `http://localhost:3000/mcp`.

## Connecting AI Assistants

### Claude Code (CLI)

Add the MCP server to your project by running:

```sh
claude mcp add --transport http omedit http://localhost:3000/mcp
```

Or pass it as a command-line option for a single session:

```sh
claude --mcp-server omedit=http://localhost:3000/mcp
```

### llama.cpp (llama-server)

Start `llama-server` and open up the web interface.

Go to Settings > MCP > Add new server and enter `http://localhost:3000/mcp`

### Other Clients

Any MCP-compatible client that supports the HTTP (Streamable HTTP) transport can connect to `http://localhost:3000/mcp`.