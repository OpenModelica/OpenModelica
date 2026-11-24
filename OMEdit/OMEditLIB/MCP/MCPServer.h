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

#pragma once
#include "OMC/OMCProxy.h"
#include <QObject>
#include <QtGlobal>

#if QT_VERSION >= QT_VERSION_CHECK(6, 4, 0)
#define OMEDIT_MCP 1
#include <QJsonValue>
#include <QJsonObject>
#include <QJsonArray>
#include <QImage>
#if __has_include(<QtHttpServer>)
#define OMEDIT_MCP_HTTP 1
#include <QtHttpServer/QHttpServer>
#include <QTcpServer>
#endif
#endif

class MCPServer : public QObject
{
  Q_OBJECT
  public:
  explicit MCPServer(OMCProxy *proxy, bool enableAdminTools, QObject *parent = nullptr);
  void listen(const QString &hostAddress, int port);

  #ifdef OMEDIT_MCP
  QJsonObject handleMCPRequest(const QByteArray &body, const QString &baseUrl, bool vision, bool admin = false);
  private:
  #ifdef OMEDIT_MCP_HTTP
  QHttpServer m_server;
  QTcpServer m_tcpServer;
  #endif
  OMCProxy *m_proxy;
  bool m_enableAdminTools;
  QJsonArray m_toolsArray;
  QJsonArray m_toolsArrayNoVision;
  QJsonObject m_toolsObject;
  QJsonArray m_adminToolsArray;
  QJsonObject m_adminToolsObject;

  QJsonObject makeRPCError(QJsonValue id, int code, QString message);
  QJsonObject makeRPCResponse(QJsonValue id, QJsonObject result);
  QJsonObject makeMCPToolResponse(QJsonValue id, QJsonArray contents);
  QJsonObject makeMCPToolResponse(QJsonValue id, QJsonObject contents);
  QJsonObject makeMCPResourceResponse(QJsonValue id, QString uri, QImage image);
  QJsonObject makeMCPError(QJsonValue id, QString message);
  QJsonObject handleSimulationTool(const QString &toolName, QJsonValue id, QJsonObject arguments, bool vision);
  QJsonObject handleDiagramTool(const QString &toolName, QJsonValue id, QJsonObject arguments);
  QJsonObject applyShapeAnnotation(QJsonValue id, const QString &className, const QString &view, const QString &shapeStr);
  #endif
};

#if defined(__EMSCRIPTEN__)
void startMCPWebBridge(MCPServer *pMCPServer);
#endif
