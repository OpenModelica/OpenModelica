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

#include "LSP/LSPProtocol.h"

#include <QObject>
#include <QProcess>
#include <QByteArray>
#include <QHash>
#include <QJsonObject>

/*!
 * \class LSPClient
 * \brief Manages a language server process using the LSP JSON-RPC protocol (stdin/stdout).
 */
class LSPClient : public QObject
{
  Q_OBJECT
public:
  explicit LSPClient(QObject *pParent = nullptr);
  ~LSPClient();

  bool start(const QString &executable, const QString &rootUri, const QStringList &libraries = QStringList());
  void stop();
  bool isRunning() const;

  static QString findNodeExecutable();
  static QString findBundledServer();

  void openDocument(const QString &uri, const QString &languageId, const QString &text);
  void changeDocument(const QString &uri, int version, const QString &text);
  void closeDocument(const QString &uri);
  int requestHover(const QString &uri, int line, int character);
  int requestDefinition(const QString &uri, int line, int character);
  int requestDeclaration(const QString &uri, int line, int character);
  int requestDocumentSymbols(const QString &uri);

signals:
  void initialized();
  void hoverResult(int requestId, QString content);
  void definitionResult(int requestId, LSP::Location location);
  void declarationResult(int requestId, LSP::Location location);
  void documentSymbolsResult(int requestId, QList<LSP::DocumentSymbol> symbols);
  void serverError(QString message);
  void logMessage(QString message, int type);

private slots:
  void onReadyRead();
  void onProcessError(QProcess::ProcessError error);
  void onProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);

private:
  QProcess *mpProcess;
  QByteArray mReadBuffer;
  int mNextId;
  bool mInitialized;
  QHash<int, QString> mPendingRequests; // id -> method name

  void sendMessage(const QJsonObject &message);
  void processMessage(const QJsonObject &message);
  void handleResponse(int id, const QJsonValue &result);
  void handleNotification(const QString &method, const QJsonObject &params);
  int nextId() { return mNextId++; }

  static QJsonObject makePosition(int line, int character);
  static QJsonObject makeTextDocumentIdentifier(const QString &uri);
};
