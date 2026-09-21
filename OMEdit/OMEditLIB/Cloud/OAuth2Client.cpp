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

#include "Cloud/OAuth2Client.h"
#include "Cloud/OAuth2Redirect.h"

#include <QCryptographicHash>
#include <memory>
#include <QJsonDocument>
#include <QJsonObject>
#include <QDebug>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QRandomGenerator>
#include <QUrl>
#include <QTimer>
#include <QUrlQuery>

namespace {

//! base64url without padding, as RFC 7636 wants it.
QString base64Url(const QByteArray &bytes)
{
  return QString::fromLatin1(bytes.toBase64(QByteArray::Base64UrlEncoding | QByteArray::OmitTrailingEquals));
}

QString randomToken(int bytes)
{
  QByteArray raw(bytes, Qt::Uninitialized);
  QRandomGenerator::system()->generate(raw.begin(), raw.end());
  return base64Url(raw);
}

//! The access token is treated as expired a minute early, so a request that is
//! about to be sent does not race the expiry.
const int kExpirySlackSeconds = 60;

} // namespace

OAuth2Client::OAuth2Client(const OAuth2Config &config, QNetworkAccessManager *pNetworkAccessManager, QObject *pParent)
  : QObject(pParent), mConfig(config), mpNetworkAccessManager(pNetworkAccessManager)
{
}

QString OAuth2Client::generateCodeVerifier()
{
  return randomToken(32);
}

QString OAuth2Client::codeChallenge(const QString &verifier)
{
  return base64Url(QCryptographicHash::hash(verifier.toLatin1(), QCryptographicHash::Sha256));
}

void OAuth2Client::setTokens(const QString &refreshToken, const QString &accessToken, const QDateTime &accessExpiry)
{
  mRefreshToken = refreshToken;
  mAccessToken = accessToken;
  mAccessExpiry = accessExpiry;
}

bool OAuth2Client::hasUsableAccessToken() const
{
  return !mAccessToken.isEmpty() && mAccessExpiry.isValid()
         && QDateTime::currentDateTimeUtc().addSecs(kExpirySlackSeconds) < mAccessExpiry;
}

void OAuth2Client::signOut()
{
  mAccessToken.clear();
  mRefreshToken.clear();
  mAccessExpiry = QDateTime();
  emit tokensChanged();
}

void OAuth2Client::ensureAccessToken(bool allowInteractive)
{
  if (hasUsableAccessToken()) {
    emit ready();
    return;
  }
  if (mBusy) {
    // The in-flight attempt emits for everyone waiting. Bounded: both the token
    // request and the browser sign-in have timeouts, so this cannot wedge.
    return;
  }
  mAllowInteractive = allowInteractive;
  if (!mRefreshToken.isEmpty()) {
    mBusy = true;
    exchange(QStringLiteral("refresh_token"), QStringList() << QStringLiteral("refresh_token=%1").arg(QString::fromUtf8(QUrl::toPercentEncoding(mRefreshToken))), false);
    return;
  }
  if (!allowInteractive) {
    emit failed(CloudError(CloudError::Auth, tr("Not signed in.")));
    return;
  }
  mBusy = true;
  startInteractive();
}

void OAuth2Client::withAccessToken(QObject *pContext, const std::function<void(const CloudError &)> &callback)
{
  // ready() and failed() are broadcast to everyone waiting on the same renewal,
  // so the shared flag keeps this particular caller to a single delivery.
  auto delivered = std::make_shared<bool>(false);
  auto deliver = [delivered, callback](const CloudError &error) {
    if (*delivered) {
      return;
    }
    *delivered = true;
    callback(error);
  };
  connect(this, &OAuth2Client::ready, pContext, [deliver]() { deliver(CloudError()); });
  connect(this, &OAuth2Client::failed, pContext, [deliver](const CloudError &error) { deliver(error); });
  ensureAccessToken();
}

void OAuth2Client::startInteractive()
{
  OAuth2Redirect *pRedirect = OAuth2Redirect::create(mConfig.redirectUri, this);
  const QString redirectUri = pRedirect->redirectUri();
  if (redirectUri.isEmpty()) {
    mBusy = false;
    pRedirect->deleteLater();
    emit failed(CloudError(CloudError::Auth, tr("Could not set up the sign-in redirect.")));
    return;
  }
  mConfig.redirectUri = redirectUri;
  mCodeVerifier = generateCodeVerifier();
  mState = randomToken(16);

  QUrlQuery query;
  query.addQueryItem(QStringLiteral("response_type"), QStringLiteral("code"));
  query.addQueryItem(QStringLiteral("client_id"), mConfig.clientId);
  query.addQueryItem(QStringLiteral("redirect_uri"), redirectUri);
  query.addQueryItem(QStringLiteral("scope"), mConfig.scope);
  query.addQueryItem(QStringLiteral("state"), mState);
  query.addQueryItem(QStringLiteral("code_challenge"), codeChallenge(mCodeVerifier));
  query.addQueryItem(QStringLiteral("code_challenge_method"), QStringLiteral("S256"));
  for (const QString &parameter : std::as_const(mConfig.extraAuthorizationParameters)) {
    const int equals = parameter.indexOf(QLatin1Char('='));
    if (equals > 0) {
      query.addQueryItem(parameter.left(equals), parameter.mid(equals + 1));
    }
  }
  QUrl url(mConfig.authorizationUrl);
  url.setQuery(query);

  emit phaseChanged(tr("Waiting for you to sign in with the browser..."));
  connect(pRedirect, &OAuth2Redirect::finished, this, &OAuth2Client::onRedirectFinished);
  connect(pRedirect, &OAuth2Redirect::finished, pRedirect, &QObject::deleteLater);
  // Whatever happens next - including the browser refusing to open - arrives as
  // finished(), so there is nothing to report here.
  pRedirect->start(url, mState);
}

void OAuth2Client::onRedirectFinished(const QString &code, const QString &state, const QString &error)
{
  if (!error.isEmpty()) {
    mBusy = false;
    emit failed(CloudError(CloudError::Auth, error));
    return;
  }
  // A mismatched state means the response is not the one this flow asked for.
  if (state != mState) {
    mBusy = false;
    emit failed(CloudError(CloudError::Auth, tr("The sign-in response did not match the request.")));
    return;
  }
  emit phaseChanged(tr("Exchanging the authorization code..."));
  QStringList parameters;
  parameters << QStringLiteral("code=%1").arg(QString::fromUtf8(QUrl::toPercentEncoding(code)));
  parameters << QStringLiteral("redirect_uri=%1").arg(QString::fromUtf8(QUrl::toPercentEncoding(mConfig.redirectUri)));
  parameters << QStringLiteral("code_verifier=%1").arg(mCodeVerifier);
  exchange(QStringLiteral("authorization_code"), parameters, true);
}

void OAuth2Client::exchange(const QString &grantType, const QStringList &parameters, bool interactive)
{
  QStringList body;
  body << QStringLiteral("grant_type=%1").arg(grantType);
  body << QStringLiteral("client_id=%1").arg(QString::fromUtf8(QUrl::toPercentEncoding(mConfig.clientId)));
  if (!mConfig.clientSecret.isEmpty()) {
    body << QStringLiteral("client_secret=%1").arg(QString::fromUtf8(QUrl::toPercentEncoding(mConfig.clientSecret)));
  }
  body << parameters;

  QNetworkRequest request((QUrl(mConfig.tokenUrl)));
  request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/x-www-form-urlencoded"));
  cloudLog(QStringLiteral("token request -> %1 grant %2").arg(mConfig.tokenUrl, grantType));
  QNetworkReply *pReply = mpNetworkAccessManager->post(request, body.join(QLatin1Char('&')).toUtf8());
  // A request that never completes would leave the dialog waiting for ever; on
  // wasm the transport is emscripten fetch, which has no timeout of its own.
  QTimer *pTimeout = new QTimer(pReply);
  pTimeout->setSingleShot(true);
  connect(pTimeout, &QTimer::timeout, pReply, [pReply]() {
    cloudLog(QStringLiteral("token request timed out"));
    pReply->abort();
  });
  pTimeout->start(30000);
  connect(pReply, &QNetworkReply::errorOccurred, this, [](QNetworkReply::NetworkError error) {
    cloudLog(QStringLiteral("token request error %1").arg(int(error)));
  });
  connect(pReply, &QNetworkReply::finished, this, [this, pReply, interactive]() {
    pReply->deleteLater();
    const QByteArray payload = pReply->readAll();
    const int status = pReply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    const QString transportError = pReply->errorString();
    const bool requestFailed = pReply->error() != QNetworkReply::NoError || status < 200 || status >= 300;
    cloudLog(QStringLiteral("token response status %1 qt error %2").arg(status).arg(int(pReply->error())));
    // Everything below runs application code - storing the refresh token, sending
    // the next request - and none of it may run inside the network callback: that
    // is a JS->wasm frame, and anything that waits there unwinds Asyncify from
    // under the browser and wedges the runtime. Hand it to the event loop first.
    QTimer::singleShot(0, this, [this, payload, status, transportError, requestFailed, interactive]() {
      mBusy = false;
      const QJsonObject object = QJsonDocument::fromJson(payload).object();
      if (requestFailed) {
        const QString description = object.value(QStringLiteral("error_description")).toString(
            object.value(QStringLiteral("error")).toString(transportError));
        // A refresh token can be revoked or simply expire. The account then has to
        // be signed in again - but not from here: opening the sign-in window
        // outside a user gesture is blocked by the browser, and the user would see
        // nothing happen at all. Report it and let them start the sign-in.
        if (!interactive) {
          mRefreshToken.clear();
          emit tokensChanged();
          emit failed(CloudError(CloudError::Auth, tr("The saved sign-in is no longer valid. Sign in again.")));
          return;
        }
        emit failed(CloudError(CloudError::Auth, description, status));
        return;
      }
      mAccessToken = object.value(QStringLiteral("access_token")).toString();
      const int expiresIn = object.value(QStringLiteral("expires_in")).toInt(3600);
      mAccessExpiry = QDateTime::currentDateTimeUtc().addSecs(expiresIn);
      // Only replace the refresh token when the service sent a new one: a refresh
      // response usually omits it, and Microsoft rotates it on every use.
      const QString newRefreshToken = object.value(QStringLiteral("refresh_token")).toString();
      if (!newRefreshToken.isEmpty()) {
        mRefreshToken = newRefreshToken;
      }
      if (mAccessToken.isEmpty()) {
        emit failed(CloudError(CloudError::Protocol, tr("The service returned no access token.")));
        return;
      }
      emit tokensChanged();
      emit ready();
    });
  });
}
