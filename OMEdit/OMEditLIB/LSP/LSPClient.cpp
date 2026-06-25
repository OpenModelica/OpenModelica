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

#include "LSP/LSPClient.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonArray>
#include <QStandardPaths>
#include <QUrl>

/*!
 * \brief LSPClient::LSPClient
 * \param pParent
 */
LSPClient::LSPClient(QObject *pParent)
  : QObject(pParent),
    mpProcess(new QProcess(this)),
    mNextId(1),
    mInitialized(false)
{
  qRegisterMetaType<LSP::Location>("LSP::Location");
  qRegisterMetaType<QList<LSP::DocumentSymbol>>("QList<LSP::DocumentSymbol>");
  connect(mpProcess, SIGNAL(readyReadStandardOutput()), this, SLOT(onReadyRead()));
  connect(mpProcess, SIGNAL(errorOccurred(QProcess::ProcessError)), this, SLOT(onProcessError(QProcess::ProcessError)));
  connect(mpProcess, SIGNAL(finished(int,QProcess::ExitStatus)), this, SLOT(onProcessFinished(int,QProcess::ExitStatus)));
}

LSPClient::~LSPClient()
{
  stop();
}

/*!
 * \brief LSPClient::start
 * Starts the language server process and sends the LSP initialize request.
 * \param executable path to the server executable
 * \param rootUri workspace root as a file URI
 * \return true if the process started successfully
 */
bool LSPClient::start(const QString &executable, const QString &rootUri)
{
  if (mpProcess->state() != QProcess::NotRunning) {
    return true;
  }
  mInitialized = false;
  mReadBuffer.clear();
  mPendingRequests.clear();
  mNextId = 1;

  if (executable.endsWith(QStringLiteral(".js"))) {
    QString node = findNodeExecutable();
    if (node.isEmpty()) {
      emit serverError(tr("Node.js not found on PATH. The language server cannot start."));
      return false;
    }
    mpProcess->setProgram(node);
    mpProcess->setArguments({executable, QStringLiteral("--stdio")});
  } else {
    mpProcess->setProgram(executable);
    mpProcess->setArguments({QStringLiteral("--stdio")});
  }
  mpProcess->start();
  if (!mpProcess->waitForStarted(5000)) {
    emit serverError(tr("Failed to start language server: %1").arg(executable));
    return false;
  }

  // Send initialize request
  int id = nextId();
  mPendingRequests.insert(id, QStringLiteral("initialize"));
  QJsonObject initializeParams;
  initializeParams["processId"] = static_cast<int>(QCoreApplication::applicationPid());
  initializeParams["rootUri"] = rootUri;
  QJsonObject capabilities;
  QJsonObject textDocumentCapabilities;
  QJsonObject hoverCapabilities;
  hoverCapabilities["contentFormat"] = QJsonArray{QStringLiteral("plaintext"), QStringLiteral("markdown")};
  textDocumentCapabilities["hover"] = hoverCapabilities;
  capabilities["textDocument"] = textDocumentCapabilities;
  initializeParams["capabilities"] = capabilities;

  QJsonObject request;
  request["jsonrpc"] = QStringLiteral("2.0");
  request["id"] = id;
  request["method"] = QStringLiteral("initialize");
  request["params"] = initializeParams;
  sendMessage(request);
  return true;
}

/*!
 * \brief LSPClient::stop
 * Sends shutdown/exit and terminates the server process.
 */
void LSPClient::stop()
{
  if (mpProcess->state() == QProcess::NotRunning) {
    return;
  }
  if (mInitialized) {
    QJsonObject shutdown;
    shutdown["jsonrpc"] = QStringLiteral("2.0");
    shutdown["id"] = nextId();
    shutdown["method"] = QStringLiteral("shutdown");
    sendMessage(shutdown);

    QJsonObject exitNotif;
    exitNotif["jsonrpc"] = QStringLiteral("2.0");
    exitNotif["method"] = QStringLiteral("exit");
    sendMessage(exitNotif);
  }
  mpProcess->waitForFinished(2000);
  mpProcess->kill();
  mInitialized = false;
}

bool LSPClient::isRunning() const
{
  return mpProcess->state() == QProcess::Running && mInitialized;
}

/*!
 * \brief LSPClient::openDocument
 * Sends textDocument/didOpen notification.
 */
void LSPClient::openDocument(const QString &uri, const QString &languageId, const QString &text)
{
  if (!mInitialized) {
    return;
  }
  QJsonObject textDocument;
  textDocument["uri"] = uri;
  textDocument["languageId"] = languageId;
  textDocument["version"] = 1;
  textDocument["text"] = text;

  QJsonObject params;
  params["textDocument"] = textDocument;

  QJsonObject notification;
  notification["jsonrpc"] = QStringLiteral("2.0");
  notification["method"] = QStringLiteral("textDocument/didOpen");
  notification["params"] = params;
  sendMessage(notification);
}

/*!
 * \brief LSPClient::changeDocument
 * Sends textDocument/didChange notification with a full-text sync.
 */
void LSPClient::changeDocument(const QString &uri, int version, const QString &text)
{
  if (!mInitialized) {
    return;
  }
  QJsonObject textDocument;
  textDocument["uri"] = uri;
  textDocument["version"] = version;

  QJsonObject change;
  change["text"] = text;

  QJsonObject params;
  params["textDocument"] = textDocument;
  params["contentChanges"] = QJsonArray{change};

  QJsonObject notification;
  notification["jsonrpc"] = QStringLiteral("2.0");
  notification["method"] = QStringLiteral("textDocument/didChange");
  notification["params"] = params;
  sendMessage(notification);
}

/*!
 * \brief LSPClient::closeDocument
 * Sends textDocument/didClose notification.
 */
void LSPClient::closeDocument(const QString &uri)
{
  if (!mInitialized) {
    return;
  }
  QJsonObject params;
  params["textDocument"] = makeTextDocumentIdentifier(uri);

  QJsonObject notification;
  notification["jsonrpc"] = QStringLiteral("2.0");
  notification["method"] = QStringLiteral("textDocument/didClose");
  notification["params"] = params;
  sendMessage(notification);
}

/*!
 * \brief LSPClient::requestHover
 * Sends textDocument/hover request. Result arrives via hoverResult signal with the returned id.
 * \param line 0-based line number
 * \param character 0-based character offset
 * \return request id, or -1 if not running
 */
int LSPClient::requestHover(const QString &uri, int line, int character)
{
  if (!mInitialized) {
    return -1;
  }
  int id = nextId();
  mPendingRequests.insert(id, QStringLiteral("textDocument/hover"));

  QJsonObject params;
  params["textDocument"] = makeTextDocumentIdentifier(uri);
  params["position"] = makePosition(line, character);

  QJsonObject request;
  request["jsonrpc"] = QStringLiteral("2.0");
  request["id"] = id;
  request["method"] = QStringLiteral("textDocument/hover");
  request["params"] = params;
  sendMessage(request);
  return id;
}

/*!
 * \brief LSPClient::requestDefinition
 * Sends textDocument/definition request. Result arrives via definitionResult(id, ...) signal.
 * \param line 0-based line number
 * \param character 0-based character offset
 * \return request id, or -1 if not running
 */
int LSPClient::requestDefinition(const QString &uri, int line, int character)
{
  if (!mInitialized) {
    return -1;
  }
  int id = nextId();
  mPendingRequests.insert(id, QStringLiteral("textDocument/definition"));

  QJsonObject params;
  params["textDocument"] = makeTextDocumentIdentifier(uri);
  params["position"] = makePosition(line, character);

  QJsonObject request;
  request["jsonrpc"] = QStringLiteral("2.0");
  request["id"] = id;
  request["method"] = QStringLiteral("textDocument/definition");
  request["params"] = params;
  sendMessage(request);
  return id;
}

/*!
 * \brief LSPClient::requestDeclaration
 * Sends textDocument/declaration request. Result arrives via declarationResult(id, ...) signal.
 * \param line 0-based line number
 * \param character 0-based character offset
 * \return request id, or -1 if not running
 */
int LSPClient::requestDeclaration(const QString &uri, int line, int character)
{
  if (!mInitialized) {
    return -1;
  }
  int id = nextId();
  mPendingRequests.insert(id, QStringLiteral("textDocument/declaration"));

  QJsonObject params;
  params["textDocument"] = makeTextDocumentIdentifier(uri);
  params["position"] = makePosition(line, character);

  QJsonObject request;
  request["jsonrpc"] = QStringLiteral("2.0");
  request["id"] = id;
  request["method"] = QStringLiteral("textDocument/declaration");
  request["params"] = params;
  sendMessage(request);
  return id;
}

/*!
 * \brief LSPClient::requestDocumentSymbols
 * Sends textDocument/documentSymbol request. Result arrives via documentSymbolsResult(id, ...) signal.
 * \return request id, or -1 if not running
 */
int LSPClient::requestDocumentSymbols(const QString &uri)
{
  if (!mInitialized) {
    return -1;
  }
  int id = nextId();
  mPendingRequests.insert(id, QStringLiteral("textDocument/documentSymbol"));

  QJsonObject params;
  params["textDocument"] = makeTextDocumentIdentifier(uri);

  QJsonObject request;
  request["jsonrpc"] = QStringLiteral("2.0");
  request["id"] = id;
  request["method"] = QStringLiteral("textDocument/documentSymbol");
  request["params"] = params;
  sendMessage(request);
  return id;
}

/*!
 * \brief LSPClient::onReadyRead
 * Reads available bytes from the server process and processes complete messages.
 */
void LSPClient::onReadyRead()
{
  mReadBuffer.append(mpProcess->readAllStandardOutput());
  while (true) {
    // Look for the header/body separator
    int separatorIndex = mReadBuffer.indexOf("\r\n\r\n");
    if (separatorIndex == -1) {
      break;
    }
    QByteArray header = mReadBuffer.left(separatorIndex);
    int contentLength = -1;
    for (const QByteArray &line : header.split('\n')) {
      QByteArray trimmed = line.trimmed();
      if (trimmed.startsWith("Content-Length:")) {
        contentLength = trimmed.mid(15).trimmed().toInt();
        break;
      }
    }
    if (contentLength < 0) {
      // Malformed message; discard up to and including separator
      mReadBuffer.remove(0, separatorIndex + 4);
      continue;
    }
    int bodyStart = separatorIndex + 4;
    if (mReadBuffer.size() < bodyStart + contentLength) {
      break; // Incomplete body; wait for more data
    }
    QByteArray body = mReadBuffer.mid(bodyStart, contentLength);
    mReadBuffer.remove(0, bodyStart + contentLength);

    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(body, &parseError);
    if (parseError.error == QJsonParseError::NoError && doc.isObject()) {
      processMessage(doc.object());
    }
  }
}

/*!
 * \brief LSPClient::onProcessError
 */
void LSPClient::onProcessError(QProcess::ProcessError error)
{
  Q_UNUSED(error)
  emit serverError(tr("Language server process error: %1").arg(mpProcess->errorString()));
}

/*!
 * \brief LSPClient::onProcessFinished
 */
void LSPClient::onProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
  Q_UNUSED(exitCode)
  Q_UNUSED(exitStatus)
  mInitialized = false;
}

/*!
 * \brief LSPClient::sendMessage
 * Serializes a JSON-RPC message with Content-Length framing and writes it to the server's stdin.
 */
void LSPClient::sendMessage(const QJsonObject &message)
{
  QByteArray body = QJsonDocument(message).toJson(QJsonDocument::Compact);
  QByteArray header = QStringLiteral("Content-Length: %1\r\n\r\n").arg(body.size()).toUtf8();
  mpProcess->write(header);
  mpProcess->write(body);
}

/*!
 * \brief LSPClient::processMessage
 * Dispatches an incoming JSON-RPC message to the appropriate handler.
 */
void LSPClient::processMessage(const QJsonObject &message)
{
  if (message.contains("id") && !message.contains("method")) {
    // Response
    QJsonValue idValue = message["id"];
    int id = idValue.isDouble() ? static_cast<int>(idValue.toDouble()) : -1;
    if (id >= 0 && mPendingRequests.contains(id)) {
      handleResponse(id, message["result"]);
      mPendingRequests.remove(id);
    }
  } else if (message.contains("method")) {
    // Notification or request from server
    handleNotification(message["method"].toString(), message["params"].toObject());
  }
}

/*!
 * \brief LSPClient::handleResponse
 * Handles a JSON-RPC response for a previously sent request.
 */
void LSPClient::handleResponse(int id, const QJsonValue &result)
{
  QString method = mPendingRequests.value(id);

  if (method == QStringLiteral("initialize")) {
    // Complete the handshake
    QJsonObject initializedNotif;
    initializedNotif["jsonrpc"] = QStringLiteral("2.0");
    initializedNotif["method"] = QStringLiteral("initialized");
    initializedNotif["params"] = QJsonObject{};
    sendMessage(initializedNotif);
    mInitialized = true;
    emit initialized();
    return;
  }

  if (method == QStringLiteral("textDocument/hover")) {
    if (result.isNull() || result.isUndefined()) {
      emit hoverResult(id, QString());
      return;
    }
    QJsonObject hoverObj = result.toObject();
    QJsonValue contents = hoverObj["contents"];
    QString text;
    if (contents.isString()) {
      text = contents.toString();
    } else if (contents.isObject()) {
      QJsonObject contentsObj = contents.toObject();
      text = contentsObj["value"].toString();
    } else if (contents.isArray()) {
      QStringList parts;
      for (const QJsonValue &v : contents.toArray()) {
        if (v.isString()) {
          parts << v.toString();
        } else if (v.isObject()) {
          parts << v.toObject()["value"].toString();
        }
      }
      text = parts.join(QStringLiteral("\n\n"));
    }
    emit hoverResult(id, text);
    return;
  }

  if (method == QStringLiteral("textDocument/definition") || method == QStringLiteral("textDocument/declaration")) {
    LSP::Location location;
    QJsonObject locObj;
    if (result.isArray() && !result.toArray().isEmpty()) {
      locObj = result.toArray().first().toObject();
    } else if (result.isObject()) {
      locObj = result.toObject();
    }
    if (!locObj.isEmpty()) {
      location.uri = locObj["uri"].toString();
      QJsonObject rangeObj = locObj["range"].toObject();
      QJsonObject startObj = rangeObj["start"].toObject();
      location.range.start.line = startObj["line"].toInt();
      location.range.start.character = startObj["character"].toInt();
      QJsonObject endObj = rangeObj["end"].toObject();
      location.range.end.line = endObj["line"].toInt();
      location.range.end.character = endObj["character"].toInt();
    }
    if (method == QStringLiteral("textDocument/declaration")) {
      emit declarationResult(id, location);
    } else {
      emit definitionResult(id, location);
    }
    return;
  }

  if (method == QStringLiteral("textDocument/documentSymbol")) {
    QList<LSP::DocumentSymbol> symbols;
    if (result.isArray()) {
      for (const QJsonValue &v : result.toArray()) {
        QJsonObject symObj = v.toObject();
        LSP::DocumentSymbol sym;
        sym.name = symObj["name"].toString();
        sym.kind = symObj["kind"].toInt(5);
        QJsonObject rangeObj = symObj["range"].toObject();
        QJsonObject startObj = rangeObj["start"].toObject();
        sym.range.start.line = startObj["line"].toInt();
        sym.range.start.character = startObj["character"].toInt();
        QJsonObject endObj = rangeObj["end"].toObject();
        sym.range.end.line = endObj["line"].toInt();
        sym.range.end.character = endObj["character"].toInt();
        symbols.append(sym);
      }
    }
    emit documentSymbolsResult(id, symbols);
    return;
  }
}

/*!
 * \brief LSPClient::handleNotification
 * Handles server-initiated notifications (currently only logged/ignored).
 */
void LSPClient::handleNotification(const QString &method, const QJsonObject &params)
{
  if (method == QStringLiteral("window/logMessage") || method == QStringLiteral("window/showMessage")) {
    emit logMessage(params["message"].toString(), params["type"].toInt(4));
    return;
  }
  // Other server-initiated notifications (diagnostics, etc.) are not yet consumed.
}

/*!
 * \brief LSPClient::findNodeExecutable
 * Returns the full path to the node executable, or an empty string if not found.
 */
QString LSPClient::findNodeExecutable()
{
  return QStandardPaths::findExecutable(QStringLiteral("node"));
}

/*!
 * \brief LSPClient::findBundledServer
 * Looks for the language server shipped alongside OMEdit.
 * Prefers a standalone binary (no Node.js required) over server.js.
 * Checks next to the executable first (Windows / dev builds), then the
 * installed share directory (Linux / macOS).
 */
QString LSPClient::findBundledServer()
{
  QDir appDir(QCoreApplication::applicationDirPath());

#ifdef Q_OS_WIN
  const QString binaryName = QStringLiteral("languageserver/modelica-language-server.exe");
#else
  const QString binaryName = QStringLiteral("languageserver/modelica-language-server");
#endif
  const QString jsName = QStringLiteral("languageserver/server.js");

  // Prefer standalone binary — no Node.js required.
  QString candidate = appDir.filePath(binaryName);
  if (QFile::exists(candidate)) {
    return candidate;
  }
  candidate = QDir::cleanPath(appDir.filePath(QStringLiteral("../share/omedit/") + binaryName));
  if (QFile::exists(candidate)) {
    return candidate;
  }

  // Fall back to server.js (requires Node.js on PATH).
  candidate = appDir.filePath(jsName);
  if (QFile::exists(candidate)) {
    return candidate;
  }
  candidate = QDir::cleanPath(appDir.filePath(QStringLiteral("../share/omedit/") + jsName));
  if (QFile::exists(candidate)) {
    return candidate;
  }
  return QString();
}

QJsonObject LSPClient::makePosition(int line, int character)
{
  QJsonObject pos;
  pos["line"] = line;
  pos["character"] = character;
  return pos;
}

QJsonObject LSPClient::makeTextDocumentIdentifier(const QString &uri)
{
  QJsonObject obj;
  obj["uri"] = uri;
  return obj;
}
