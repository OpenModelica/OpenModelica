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

#include "Cloud/CloudProvider.h"
#include "Cloud/OAuth2Client.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QTimer>

void CloudReply::abort()
{
  if (mFinished || mAborted) {
    return;
  }
  mAborted = true;
  if (mpNetworkReply) {
    mpNetworkReply->abort();
  } else {
    finish(CloudError(CloudError::Cancelled, tr("Cancelled.")));
  }
}

void CloudReply::finish(const CloudError &error)
{
  if (mFinished) {
    return;
  }
  mFinished = true;
  mError = mAborted && !error.isError() ? CloudError(CloudError::Cancelled, tr("Cancelled.")) : error;
  // Never synchronous: an operation can finish before the call that started it
  // returns, and the caller connects to finished() only afterwards.
  QMetaObject::invokeMethod(this, [this]() {
    emit finished();
    deleteLater();
  }, Qt::QueuedConnection);
}

void CloudReply::trackNetworkReply(QNetworkReply *pNetworkReply)
{
  mpNetworkReply = pNetworkReply;
  connect(pNetworkReply, &QNetworkReply::downloadProgress, this, &CloudReply::progress);
  connect(pNetworkReply, &QNetworkReply::uploadProgress, this, &CloudReply::progress);
}

CloudProvider::CloudProvider(OAuth2Client *pOAuth2Client, QNetworkAccessManager *pNetworkAccessManager, QObject *pParent)
  : QObject(pParent), mpOAuth2Client(pOAuth2Client), mpNetworkAccessManager(pNetworkAccessManager)
{
}

CloudReply *CloudProvider::send(const QNetworkRequest &request, const QByteArray &verb, const QByteArray &body,
                                const std::function<void(CloudReply *, const QByteArray &)> &parse)
{
  CloudReply *pReply = new CloudReply(this);
  dispatch(pReply, request, verb, body, parse, false);
  return pReply;
}

void CloudProvider::dispatch(CloudReply *pReply, const QNetworkRequest &request, const QByteArray &verb,
                             const QByteArray &body, const std::function<void(CloudReply *, const QByteArray &)> &parse,
                             bool isRetry)
{
  mpOAuth2Client->withAccessToken(pReply, [this, pReply, request, verb, body, parse, isRetry](const CloudError &tokenError) {
    if (tokenError.isError()) {
      pReply->finish(tokenError);
      return;
    }
    QNetworkRequest authorized(request);
    authorized.setRawHeader("Authorization", "Bearer " + mpOAuth2Client->accessToken().toUtf8());
    cloudLog(QStringLiteral("cloud %1 %2").arg(QString::fromUtf8(verb), authorized.url().toString()));
    QNetworkReply *pNetworkReply = mpNetworkAccessManager->sendCustomRequest(authorized, verb, body);
    pReply->trackNetworkReply(pNetworkReply);
    // emscripten fetch has no timeout of its own.
    QTimer *pTimeout = new QTimer(pNetworkReply);
    pTimeout->setSingleShot(true);
    connect(pTimeout, &QTimer::timeout, pNetworkReply, [pNetworkReply]() {
      cloudLog(QStringLiteral("cloud request timed out %1").arg(pNetworkReply->url().toString()));
      pNetworkReply->abort();
    });
    pTimeout->start(60000);
    connect(pNetworkReply, &QNetworkReply::finished, pReply,
            [this, pReply, pNetworkReply, request, verb, body, parse, isRetry]() {
      pNetworkReply->deleteLater();
      const int status = pNetworkReply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
      const QByteArray payload = pNetworkReply->readAll();
      cloudLog(QStringLiteral("cloud <- %1 qt error %2 bytes %3")
                   .arg(status).arg(int(pNetworkReply->error())).arg(payload.size()));
      if (pNetworkReply->error() == QNetworkReply::OperationCanceledError) {
        pReply->finish(CloudError(CloudError::Cancelled, tr("Cancelled.")));
        return;
      }
      // Expired or revoked between the check and the service reading it.
      if (status == 401 && !isRetry) {
        mpOAuth2Client->setTokens(mpOAuth2Client->refreshToken(), QString(), QDateTime());
        dispatch(pReply, request, verb, body, parse, true);
        return;
      }
      if (status < 200 || status >= 300) {
        pReply->finish(classifyError(status, payload, pNetworkReply->errorString()));
        return;
      }
      if (pNetworkReply->error() != QNetworkReply::NoError) {
        pReply->finish(CloudError(CloudError::Network, pNetworkReply->errorString()));
        return;
      }
      if (parse) {
        parse(pReply, payload);
      }
      pReply->finish(CloudError());
    });
  });
}

/*!
 * \brief Turn an error response into a CloudError.
 * Both services wrap the reason in {"error": {"message": ...}}; a provider
 * overrides this where the status alone is ambiguous, as Drive's 403 is.
 */
CloudError CloudProvider::classifyError(int status, const QByteArray &payload, const QString &fallback) const
{
  const QJsonObject error = QJsonDocument::fromJson(payload).object().value(QStringLiteral("error")).toObject();
  QString message = error.value(QStringLiteral("message")).toString();
  if (message.isEmpty()) {
    message = fallback;
  }
  return CloudError::fromHttpStatus(status, message);
}
