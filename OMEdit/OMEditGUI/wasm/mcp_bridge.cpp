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
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

// The MCP server of the web page: JavaScript in the page calls
//   omeditMcp(request, {vision: true, admin: false}) -> Promise<reply | null>
// with a JSON-RPC request. Calling into the application while it waits on the
// omc worker would need a second Asyncify stack, so the requests are queued and
// a timer runs them from the event loop, one at a time.

#if defined(__EMSCRIPTEN__)

#include "MCP/MCPServer.h"

#include <QApplication>
#include <QJsonDocument>
#include <QTimer>

#include <emscripten.h>
#include <emscripten/em_js.h>

#include <cstdlib>

bool omcWorkerCallInFlight();

EM_JS(void, omedit_mcp_install, (), {
  const queue = { waiting: [], running: new Map(), next: 1 };
  Module.__omeditMcp = queue;
  globalThis.omeditMcp = (request, options) => new Promise((resolve, reject) => {
    const body = typeof request === "string" ? request : JSON.stringify(request);
    const vision = !options || options.vision !== false;
    const admin = !!(options && options.admin);
    queue.waiting.push({ body, vision, admin, resolve, reject });
  });
  globalThis.dispatchEvent(new Event("omedit-mcp-ready"));
});

EM_JS(int, omedit_mcp_take, (), {
  const queue = Module.__omeditMcp;
  if (!queue.waiting.length) return 0;
  const id = queue.next++;
  queue.running.set(id, queue.waiting.shift());
  return id;
});

EM_JS(char *, omedit_mcp_body, (int id), {
  return stringToNewUTF8(Module.__omeditMcp.running.get(id).body);
});

EM_JS(int, omedit_mcp_flags, (int id), {
  const request = Module.__omeditMcp.running.get(id);
  return (request.vision ? 1 : 0) | (request.admin ? 2 : 0);
});

EM_JS(void, omedit_mcp_reply, (int id, const char *reply), {
  const queue = Module.__omeditMcp;
  const request = queue.running.get(id);
  queue.running.delete(id);
  const text = UTF8ToString(reply);
  try {
    request.resolve(text ? JSON.parse(text) : null);
  } catch (e) {
    request.reject(e);
  }
});

static void runMCPRequests(MCPServer *pMCPServer)
{
  static bool running = false;
  if (running || omcWorkerCallInFlight() || QApplication::activeModalWidget()) {
    return;
  }
  const int id = omedit_mcp_take();
  if (!id) {
    return;
  }
  running = true;
  char *body = omedit_mcp_body(id);
  const int flags = omedit_mcp_flags(id);
  const QJsonObject reply = pMCPServer->handleMCPRequest(QByteArray(body), QString(), flags & 1, flags & 2);
  free(body);
  omedit_mcp_reply(id, reply.isEmpty() ? "" : QJsonDocument(reply).toJson(QJsonDocument::Compact).constData());
  running = false;
}

void startMCPWebBridge(MCPServer *pMCPServer)
{
  omedit_mcp_install();
  QTimer *pTimer = new QTimer(pMCPServer);
  QObject::connect(pTimer, &QTimer::timeout, pMCPServer, [pMCPServer]() {runMCPRequests(pMCPServer);});
  pTimer->start(50);
}

#endif // __EMSCRIPTEN__
