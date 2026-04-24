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

#if QT_VERSION >= QT_VERSION_CHECK(6, 4, 0) && __has_include(<QtHttpServer>)
#include <QtHttpServer/QHttpServer>
#include <QTcpServer>
#include <QJsonValue>
#include <QJsonObject>
#include <QJsonArray>
#include <QImage>
#endif

class MCPServer : public QObject
{
  Q_OBJECT
  public:
  explicit MCPServer(OMCProxy *proxy, int port, bool enableAdminTools, QObject *parent = nullptr);

  #if QT_VERSION >= QT_VERSION_CHECK(6, 4, 0) && __has_include(<QtHttpServer>)
  private:
  QHttpServer m_server;
  QTcpServer m_tcpServer;
  OMCProxy *m_proxy;
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
  QHttpServerResponse handleMCPRequest(const QHttpServerRequest &request, bool vision, bool admin = false);
  QHttpServerResponse handleSimulationTool(const QString &toolName, QJsonValue id, QJsonObject arguments, bool vision);
  QHttpServerResponse handleDiagramTool(const QString &toolName, QJsonValue id, QJsonObject arguments);
  QHttpServerResponse applyShapeAnnotation(QJsonValue id, const QString &className, const QString &view, const QString &shapeStr);
  #endif
};
