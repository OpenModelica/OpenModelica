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

#include "Cloud/CloudAccount.h"
#include "Cloud/CloudConfig.h"
#include "Cloud/CloudProvider.h"
#include "Cloud/GoogleDriveProvider.h"
#include "Cloud/OAuth2Client.h"
#include "Cloud/OneDriveProvider.h"
#include "Util/NetworkAccessManager.h"
#include "Util/PersistentStorage.h"
#include "Util/Utilities.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSettings>

namespace {

const char *const kAccountsKey = "cloud/accounts";

CloudProvider *makeProvider(CloudProviderKind kind, OAuth2Client *pOAuth2Client,
                            QNetworkAccessManager *pNetworkAccessManager, QObject *pParent)
{
  switch (kind) {
    case CloudProviderKind::GoogleDrive:
      return new GoogleDriveProvider(pOAuth2Client, pNetworkAccessManager, pParent);
    case CloudProviderKind::OneDrive:
      return new OneDriveProvider(pOAuth2Client, pNetworkAccessManager, pParent);
  }
  return 0;
}

} // namespace

CloudAccount::CloudAccount(CloudProviderKind kind, const QString &accountId, const QString &displayName,
                           QNetworkAccessManager *pNetworkAccessManager, QObject *pParent)
  : QObject(pParent), mKind(kind), mAccountId(accountId), mDisplayName(displayName)
{
  mpOAuth2Client = new OAuth2Client(CloudConfig::instance()->oauthConfig(kind), pNetworkAccessManager, this);
  mpProvider = makeProvider(kind, mpOAuth2Client, pNetworkAccessManager, this);
  // An account whose identity is not known yet - the candidate a sign-in starts
  // with - has no key of its own to store anything under, and must not pick up
  // whatever a previous candidate left behind. Doing so sends it down the silent
  // refresh path instead of opening the sign-in window, and the retry that
  // follows a failed refresh happens outside the user gesture, so the browser
  // blocks the popup and nothing appears at all.
  if (!mAccountId.isEmpty()) {
    const QByteArray refreshToken = PersistentStorage::secret(key());
    if (!refreshToken.isEmpty()) {
      mpOAuth2Client->setTokens(QString::fromUtf8(refreshToken), QString(), QDateTime());
    }
  }
  // Microsoft rotates the refresh token on every renewal, so it has to be written
  // back each time or the next session starts with a token the service rejects.
  connect(mpOAuth2Client, &OAuth2Client::tokensChanged, this, &CloudAccount::saveTokens);
}

QString CloudAccount::makeKey(CloudProviderKind kind, const QString &accountId)
{
  return QStringLiteral("%1:%2").arg(cloudProviderKindToString(kind), accountId);
}

bool CloudAccount::isSignedIn() const
{
  return mpOAuth2Client->isSignedIn();
}

void CloudAccount::signOut()
{
  mpOAuth2Client->signOut();
  PersistentStorage::removeSecret(key());
}

void CloudAccount::saveTokens()
{
  if (mAccountId.isEmpty()) {
    return; // nothing to key the secret on yet
  }
  const QString refreshToken = mpOAuth2Client->refreshToken();
  if (refreshToken.isEmpty()) {
    PersistentStorage::removeSecret(key());
  } else {
    PersistentStorage::setSecret(key(), refreshToken.toUtf8());
  }
}

CloudAccountManager *CloudAccountManager::instance()
{
  static CloudAccountManager manager;
  return &manager;
}

void CloudAccountManager::setNetworkAccessManager(QNetworkAccessManager *pNetworkAccessManager)
{
  mpNetworkAccessManager = pNetworkAccessManager;
}

QNetworkAccessManager *CloudAccountManager::networkAccessManager()
{
  if (!mpNetworkAccessManager) {
    mpNetworkAccessManager = new NetworkAccessManager;
  }
  return mpNetworkAccessManager;
}

void CloudAccountManager::load()
{
  if (mLoaded) {
    return;
  }
  mLoaded = true;
  CloudConfig::instance()->ensureLoaded(networkAccessManager());
  // Clear out anything an earlier build stored against an unidentified account.
  PersistentStorage::removeSecret(CloudAccount::makeKey(CloudProviderKind::GoogleDrive, QString()));
  PersistentStorage::removeSecret(CloudAccount::makeKey(CloudProviderKind::OneDrive, QString()));
  const QJsonArray stored =
      QJsonDocument::fromJson(Utilities::getApplicationSettings()->value(QLatin1String(kAccountsKey)).toByteArray()).array();
  for (const QJsonValue &value : stored) {
    const QJsonObject object = value.toObject();
    CloudProviderKind kind;
    if (!cloudProviderKindFromString(object.value(QStringLiteral("kind")).toString(), &kind)) {
      continue;
    }
    mAccounts << new CloudAccount(kind, object.value(QStringLiteral("accountId")).toString(),
                                  object.value(QStringLiteral("displayName")).toString(), networkAccessManager(), this);
  }
}

void CloudAccountManager::save()
{
  QJsonArray stored;
  for (const CloudAccount *pAccount : std::as_const(mAccounts)) {
    QJsonObject object;
    object.insert(QStringLiteral("kind"), cloudProviderKindToString(pAccount->kind()));
    object.insert(QStringLiteral("accountId"), pAccount->accountId());
    object.insert(QStringLiteral("displayName"), pAccount->displayName());
    stored.append(object);
  }
  Utilities::getApplicationSettings()->setValue(QLatin1String(kAccountsKey),
                                                QJsonDocument(stored).toJson(QJsonDocument::Compact));
  PersistentStorage::scheduleSnapshot();
  emit accountsChanged();
}

QList<CloudAccount *> CloudAccountManager::accounts()
{
  load();
  return mAccounts;
}

CloudAccount *CloudAccountManager::account(const QString &key)
{
  load();
  for (CloudAccount *pAccount : std::as_const(mAccounts)) {
    if (pAccount->key() == key) {
      return pAccount;
    }
  }
  return 0;
}

void CloudAccountManager::addAccount(CloudProviderKind kind)
{
  load();
  CloudConfig::instance()->ensureLoaded(networkAccessManager());
  if (!CloudConfig::instance()->registration(kind).isConfigured()) {
    emit addAccountFailed(CloudError(CloudError::Provider,
                                     tr("%1 has not been set up for this installation. Add a client ID on the Cloud "
                                        "Storage page of the options dialog.")
                                         .arg(cloudProviderDisplayName(kind))));
    return;
  }

  // Who signed in is only known once the service says so, so the account is built
  // with a placeholder identity and adopted - or merged into the existing one -
  // when userInfo() answers.
  CloudAccount *pCandidate = new CloudAccount(kind, QString(), QString(), networkAccessManager(), this);
  connect(pCandidate->oauth2Client(), &OAuth2Client::phaseChanged, this, &CloudAccountManager::addAccountPhase);
  CloudReply *pReply = pCandidate->provider()->userInfo();
  connect(pReply, &CloudReply::finished, this, [this, pReply, pCandidate, kind]() {
    if (pReply->error().isError()) {
      pCandidate->deleteLater();
      emit addAccountFailed(pReply->error());
      return;
    }
    const RemoteItem identity = pReply->item();
    if (identity.id.isEmpty()) {
      pCandidate->deleteLater();
      emit addAccountFailed(CloudError(CloudError::Protocol,
                                       tr("The service did not say which account signed in.")));
      return;
    }
    const QString refreshToken = pCandidate->oauth2Client()->refreshToken();
    const QString accessToken = pCandidate->oauth2Client()->accessToken();
    const QDateTime accessExpiry = pCandidate->oauth2Client()->accessExpiry();
    pCandidate->deleteLater();

    CloudAccount *pAccount = account(CloudAccount::makeKey(kind, identity.id));
    if (!pAccount) {
      pAccount = new CloudAccount(kind, identity.id, identity.name, networkAccessManager(), this);
      mAccounts << pAccount;
    }
    pAccount->setDisplayName(identity.name);
    // Move the freshly issued tokens onto the account that keeps them, now that
    // its key - which the secret store is keyed by - is known.
    pAccount->oauth2Client()->setTokens(refreshToken, accessToken, accessExpiry);
    pAccount->saveTokens();
    save();
    emit accountAdded(pAccount->key());
  });
}

void CloudAccountManager::removeAccount(const QString &key)
{
  load();
  for (int i = 0; i < mAccounts.size(); ++i) {
    if (mAccounts.at(i)->key() != key) {
      continue;
    }
    CloudAccount *pAccount = mAccounts.takeAt(i);
    pAccount->signOut();
    pAccount->deleteLater();
    save();
    return;
  }
}
