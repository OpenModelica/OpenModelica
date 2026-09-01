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

#ifndef CLOUDACCOUNT_H
#define CLOUDACCOUNT_H

#include "Cloud/CloudTypes.h"

#include <QList>
#include <QObject>
#include <QString>

class CloudProvider;
class OAuth2Client;
class QNetworkAccessManager;

/*!
 * \brief One signed-in cloud account and the provider that talks to it.
 *
 * The refresh token lives in PersistentStorage's secret store, never the settings
 * ini - a file users routinely copy between machines.
 */
class CloudAccount : public QObject
{
  Q_OBJECT
public:
  CloudAccount(CloudProviderKind kind, const QString &accountId, const QString &displayName,
               QNetworkAccessManager *pNetworkAccessManager, QObject *pParent = 0);

  //! Stable across restarts, and the key both the settings and the secret use.
  static QString makeKey(CloudProviderKind kind, const QString &accountId);
  QString key() const { return makeKey(mKind, mAccountId); }

  CloudProviderKind kind() const { return mKind; }
  QString accountId() const { return mAccountId; }
  QString displayName() const { return mDisplayName; }
  void setDisplayName(const QString &displayName) { mDisplayName = displayName; }

  CloudProvider *provider() const { return mpProvider; }
  OAuth2Client *oauth2Client() const { return mpOAuth2Client; }

  bool isSignedIn() const;
  void signOut();

public slots:
  //! Write the current refresh token to the secret store.
  void saveTokens();

private:
  CloudProviderKind mKind;
  QString mAccountId;
  QString mDisplayName;
  OAuth2Client *mpOAuth2Client;
  CloudProvider *mpProvider;
};

/*!
 * \brief The set of accounts the user has added, and adding new ones.
 */
class CloudAccountManager : public QObject
{
  Q_OBJECT
public:
  static CloudAccountManager *instance();

  //! Overrides the manager used for every cloud request; for tests. Left alone,
  //! OMEdit's own is used, so desktop proxy authentication keeps working.
  void setNetworkAccessManager(QNetworkAccessManager *pNetworkAccessManager);
  QNetworkAccessManager *networkAccessManager();

  QList<CloudAccount *> accounts();
  CloudAccount *account(const QString &key);

  //! Emits accountAdded() once the service says who signed in; signing in twice
  //! to the same account updates it rather than duplicating it.
  void addAccount(CloudProviderKind kind);
  void removeAccount(const QString &key);

signals:
  void accountsChanged();
  //! Progress of an in-flight addAccount(), for the options page.
  void addAccountPhase(const QString &description);
  void accountAdded(const QString &key);
  void addAccountFailed(const CloudError &error);

private:
  CloudAccountManager() = default;
  void load();
  void save();

  QNetworkAccessManager *mpNetworkAccessManager = 0;
  QList<CloudAccount *> mAccounts;
  bool mLoaded = false;
};

#endif // CLOUDACCOUNT_H
