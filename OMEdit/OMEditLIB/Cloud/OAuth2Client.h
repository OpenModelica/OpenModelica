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

#ifndef OAUTH2CLIENT_H
#define OAUTH2CLIENT_H

#include "Cloud/CloudTypes.h"

#include <QDateTime>
#include <QObject>

#include <functional>
#include <QString>
#include <QStringList>

class QNetworkAccessManager;

//! Endpoints and registration of one OAuth 2.0 application.
struct OAuth2Config
{
  QString authorizationUrl;
  QString tokenUrl;
  QString clientId;
  //! Only Google needs one, and only because its token endpoint rejects a PKCE
  //! exchange without it. Deployment configuration, not a confidential value.
  QString clientSecret;
  QString scope;
  QString redirectUri;
  //! "access_type=offline", "prompt=consent", ... appended to the authorization URL.
  QStringList extraAuthorizationParameters;
};

/*!
 * \brief Authorization code flow with PKCE, for a public client.
 *
 * Not QtNetworkAuth: that module is in neither Qt kit here. The interactive half
 * differs completely between the two platforms and lives behind OAuth2Redirect.
 */
class OAuth2Client : public QObject
{
  Q_OBJECT
public:
  OAuth2Client(const OAuth2Config &config, QNetworkAccessManager *pNetworkAccessManager, QObject *pParent = 0);

  const OAuth2Config &config() const { return mConfig; }

  //! Restore a previous sign-in. An expired access token is fine: it gets refreshed.
  void setTokens(const QString &refreshToken, const QString &accessToken, const QDateTime &accessExpiry);
  QString refreshToken() const { return mRefreshToken; }
  QString accessToken() const { return mAccessToken; }
  QDateTime accessExpiry() const { return mAccessExpiry; }
  bool isSignedIn() const { return !mRefreshToken.isEmpty() || hasUsableAccessToken(); }

  //! Makes accessToken() usable, then emits ready(). Refreshes silently where it
  //! can; the interactive flow is the fallback.
  void ensureAccessToken(bool allowInteractive = true);

  //! Runs callback once, when a token is available or getting one failed. Tied
  //! to pContext's lifetime, so an abandoned request leaves nothing dangling.
  void withAccessToken(QObject *pContext, const std::function<void(const CloudError &)> &callback);

  //! Forget the tokens. Does not revoke them at the service.
  void signOut();

  static QString generateCodeVerifier();
  static QString codeChallenge(const QString &verifier);

signals:
  //! Coarse progress, for a dialog that would otherwise just say "signing in".
  void phaseChanged(const QString &description);
  void ready();
  void failed(const CloudError &error);
  //! The refresh token changed and should be written back to the secret store.
  void tokensChanged();

private slots:
  void onRedirectFinished(const QString &code, const QString &state, const QString &error);

private:
  bool hasUsableAccessToken() const;
  void startInteractive();
  void exchange(const QString &grantType, const QStringList &parameters, bool interactive);

  OAuth2Config mConfig;
  QNetworkAccessManager *mpNetworkAccessManager;
  QString mAccessToken;
  QString mRefreshToken;
  QDateTime mAccessExpiry;
  QString mCodeVerifier;
  QString mState;
  bool mBusy = false;
  bool mAllowInteractive = true;
};

#endif // OAUTH2CLIENT_H
