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

// Desktop half of OAuth2Redirect: the system browser plus a loopback listener.
// Both services allow a http://127.0.0.1:<any port> redirect for a public client,
// which is what lets this work without registering a fixed port.

#if !defined(__EMSCRIPTEN__)

#include "Cloud/OAuth2Redirect.h"

#include <QDesktopServices>
#include <QTcpServer>
#include <QTcpSocket>
#include <QTimer>
#include <QUrlQuery>

namespace {

// Long enough for the user to find the browser window, sign in and consent.
const int kTimeoutMs = 5 * 60 * 1000;

const char *const kResponsePage =
    "HTTP/1.1 200 OK\r\n"
    "Content-Type: text/html; charset=utf-8\r\n"
    "Connection: close\r\n"
    "\r\n"
    "<!doctype html><html><head><meta charset=\"utf-8\"><title>OMEdit</title></head>"
    "<body style=\"font-family:sans-serif;padding:2em\">"
    "<h2>OMEdit is signed in</h2><p>You can close this tab and go back to OMEdit.</p>"
    "</body></html>";

class LoopbackRedirect : public OAuth2Redirect
{
public:
  explicit LoopbackRedirect(QObject *pParent) : OAuth2Redirect(pParent)
  {
    mpServer = new QTcpServer(this);
    connect(mpServer, &QTcpServer::newConnection, this, &LoopbackRedirect::onConnection);
    mpTimeout = new QTimer(this);
    mpTimeout->setSingleShot(true);
    mpTimeout->setInterval(kTimeoutMs);
    connect(mpTimeout, &QTimer::timeout, this, [this]() {
      settle(QString(), QString(), tr("Timed out waiting for the sign-in to finish."));
    });
  }

  QString redirectUri() override
  {
    if (!mpServer->isListening() && !mpServer->listen(QHostAddress::LocalHost, 0)) {
      return QString();
    }
    return QStringLiteral("http://127.0.0.1:%1/").arg(mpServer->serverPort());
  }

  bool start(const QUrl &authorizationUrl, const QString &state) override
  {
    // The loopback listener echoes back whatever the service sends; the client
    // does the checking.
    Q_UNUSED(state)
    if (redirectUri().isEmpty()) {
      return false;
    }
    mpTimeout->start();
    if (!QDesktopServices::openUrl(authorizationUrl)) {
      settle(QString(), QString(), tr("Could not open a web browser for signing in."));
      return false;
    }
    return true;
  }

  void cancel() override { settle(QString(), QString(), tr("Sign-in was cancelled.")); }

private:
  void onConnection()
  {
    QTcpSocket *pSocket = mpServer->nextPendingConnection();
    if (!pSocket) {
      return;
    }
    connect(pSocket, &QTcpSocket::readyRead, this, [this, pSocket]() {
      mRequest += pSocket->readAll();
      // The request line is all that is needed and it ends at the first newline.
      const int end = mRequest.indexOf('\n');
      if (end < 0) {
        return;
      }
      const QByteArray line = mRequest.left(end).trimmed();
      pSocket->write(kResponsePage);
      pSocket->disconnectFromHost();
      // "GET /?code=...&state=... HTTP/1.1"
      const QList<QByteArray> parts = line.split(' ');
      if (parts.size() < 2) {
        settle(QString(), QString(), tr("The sign-in redirect could not be read."));
        return;
      }
      const QUrlQuery query(QUrl(QString::fromUtf8(parts.at(1))).query());
      const QString error = query.queryItemValue(QStringLiteral("error"), QUrl::FullyDecoded);
      settle(query.queryItemValue(QStringLiteral("code"), QUrl::FullyDecoded),
             query.queryItemValue(QStringLiteral("state"), QUrl::FullyDecoded),
             error.isEmpty() ? QString() : tr("The service refused the sign-in: %1").arg(error));
    });
    connect(pSocket, &QTcpSocket::disconnected, pSocket, &QObject::deleteLater);
  }

  //! Emit finished() exactly once, however the flow ends.
  void settle(const QString &code, const QString &state, const QString &error)
  {
    if (mSettled) {
      return;
    }
    mSettled = true;
    mpTimeout->stop();
    mpServer->close();
    emit finished(code, state, error.isEmpty() && code.isEmpty() ? tr("No authorization code was returned.") : error);
  }

  QTcpServer *mpServer;
  QTimer *mpTimeout;
  QByteArray mRequest;
  bool mSettled = false;
};

} // namespace

OAuth2Redirect *OAuth2Redirect::create(const QString &configuredUri, QObject *pParent)
{
  // Ignored on purpose: the loopback port is only known once the socket is bound,
  // and both services accept http://127.0.0.1 on any port for a public client.
  Q_UNUSED(configuredUri)
  return new LoopbackRedirect(pParent);
}

#endif // !__EMSCRIPTEN__
