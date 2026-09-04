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

#ifndef CLOUDCONFIG_H
#define CLOUDCONFIG_H

#include "Cloud/CloudTypes.h"
#include "Cloud/OAuth2Client.h"

#include <QString>

class QNetworkAccessManager;

//! What a deployment has to supply for one service before it can be used.
struct CloudClientRegistration
{
  QString clientId;
  //! Google rejects a PKCE exchange without one even for a public client, so it
  //! is deployment configuration and not confidential. Microsoft needs none.
  QString clientSecret;
  //! Full Drive access instead of drive.file, for a deployment that registered
  //! and verified its own client with Google. Ignored for OneDrive.
  bool fullDriveScope = false;
  //! Overrides the default /oauth-callback.html at the origin root, which is one
  //! registered URI for every versioned path under it (no wildcards are allowed).
  QString redirectUri;

  bool isConfigured() const { return !clientId.isEmpty(); }
};

/*!
 * \brief Which OAuth applications this installation talks to.
 *
 * Never compiled in: a client id identifies the deployment. Settings first, then
 * cloud_config.json, then nothing - which reports itself as not set up.
 */
class CloudConfig
{
public:
  static CloudConfig *instance();

  //! Called from user-initiated actions, never during startup: on the web target
  //! the first call blocks briefly while cloud_config.json is fetched.
  void ensureLoaded(QNetworkAccessManager *pNetworkAccessManager);

  CloudClientRegistration registration(CloudProviderKind kind) const;
  void setRegistration(CloudProviderKind kind, const CloudClientRegistration &registration);

  //! Endpoints, scopes and the registration, ready for OAuth2Client.
  OAuth2Config oauthConfig(CloudProviderKind kind) const;

private:
  CloudConfig() = default;
  static QString settingsKey(CloudProviderKind kind, const QString &field);

  CloudClientRegistration mDeploymentRegistrations[2];
  bool mLoaded = false;
};

#endif // CLOUDCONFIG_H
