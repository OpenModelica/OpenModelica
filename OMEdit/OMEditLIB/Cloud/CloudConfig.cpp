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

#include "Cloud/CloudConfig.h"
#include "Util/PersistentStorage.h"
#include "Util/Utilities.h"

#include <QEventLoop>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QSettings>
#include <QTimer>

#if defined(__EMSCRIPTEN__)
#include <emscripten.h>
#include <emscripten/em_js.h>
#include <cstdlib>

// Resolved against the page, not the origin root: the file is staged beside the
// application so that a versioned deployment carries the configuration it was
// built with, and a relative QUrl has no scheme for QNetworkAccessManager to use.
EM_JS(char *, omedit_cloud_config_url, (), {
  try {
    return stringToNewUTF8(new URL("cloud_config.json", location.href).href);
  } catch (e) {
    return stringToNewUTF8("");
  }
});

// Synchronous on purpose. A nested QEventLoop waiting on a QNetworkReply is the
// one thing that must not happen on this thread - it swallows other replies and
// can unwind Asyncify from under a callback - whereas a synchronous XHR simply
// blocks, involving neither. The file is a few hundred bytes from our own origin.
EM_JS(char *, omedit_fetch_text_sync, (const char *url), {
  try {
    const request = new XMLHttpRequest();
    request.open("GET", UTF8ToString(url), false);
    request.send();
    if (request.status >= 200 && request.status < 300) {
      return stringToNewUTF8(request.responseText);
    }
  } catch (e) {
    console.warn("[OMEdit] could not read cloud_config.json", e);
  }
  return stringToNewUTF8("");
});
#endif

namespace {

const char *const kConfigFileName = "cloud_config.json";

// Endpoints are part of the protocol, not of a deployment, so they are the one
// thing here that is compiled in.
struct ProviderEndpoints
{
  const char *authorizationUrl;
  const char *tokenUrl;
  const char *scope;
  const char *extraAuthorizationParameters; // comma separated
};

const ProviderEndpoints kGoogle = {
  "https://accounts.google.com/o/oauth2/v2/auth",
  "https://oauth2.googleapis.com/token",
  // drive.file keeps this a non-sensitive scope: no Google app verification, and
  // the application only ever sees what it created or the user handed it.
  "https://www.googleapis.com/auth/drive.file",
  // access_type=offline is what makes Google return a refresh token at all, and
  // it only returns one on a consent screen the user actually saw.
  "access_type=offline,prompt=consent,include_granted_scopes=true"
};

const ProviderEndpoints kMicrosoft = {
  "https://login.microsoftonline.com/common/oauth2/v2.0/authorize",
  "https://login.microsoftonline.com/common/oauth2/v2.0/token",
  "offline_access User.Read Files.ReadWrite",
  ""
};

const ProviderEndpoints &endpoints(CloudProviderKind kind)
{
  return kind == CloudProviderKind::GoogleDrive ? kGoogle : kMicrosoft;
}

int providerIndex(CloudProviderKind kind)
{
  return kind == CloudProviderKind::GoogleDrive ? 0 : 1;
}

CloudClientRegistration registrationFromJson(const QJsonObject &object)
{
  CloudClientRegistration registration;
  registration.clientId = object.value(QStringLiteral("clientId")).toString();
  registration.clientSecret = object.value(QStringLiteral("clientSecret")).toString();
  registration.fullDriveScope = object.value(QStringLiteral("fullDriveScope")).toBool(false);
  registration.redirectUri = object.value(QStringLiteral("redirectUri")).toString();
  return registration;
}

} // namespace

CloudConfig *CloudConfig::instance()
{
  static CloudConfig config;
  return &config;
}

QString CloudConfig::settingsKey(CloudProviderKind kind, const QString &field)
{
  return QStringLiteral("cloud/%1/%2").arg(cloudProviderKindToString(kind), field);
}

void CloudConfig::ensureLoaded(QNetworkAccessManager *pNetworkAccessManager)
{
  if (mLoaded) {
    return;
  }
  mLoaded = true;

  QByteArray contents;
#if defined(__EMSCRIPTEN__)
  // Served next to the application, so a relative URL reaches it wherever the
  // deployment is rooted.
  Q_UNUSED(pNetworkAccessManager)
  char *rawUrl = omedit_cloud_config_url();
  const QString configUrl = QString::fromUtf8(rawUrl);
  free(rawUrl);
  if (!configUrl.isEmpty()) {
    char *rawContents = omedit_fetch_text_sync(configUrl.toUtf8().constData());
    contents = QByteArray(rawContents);
    free(rawContents);
  }
#else
  Q_UNUSED(pNetworkAccessManager)
  QFile file(PersistentStorage::root() + QLatin1Char('/') + QLatin1String(kConfigFileName));
  if (file.open(QIODevice::ReadOnly)) {
    contents = file.readAll();
  }
#endif
  if (contents.isEmpty()) {
    return;
  }
  const QJsonObject root = QJsonDocument::fromJson(contents).object();
  mDeploymentRegistrations[providerIndex(CloudProviderKind::GoogleDrive)] =
      registrationFromJson(root.value(QStringLiteral("googledrive")).toObject());
  mDeploymentRegistrations[providerIndex(CloudProviderKind::OneDrive)] =
      registrationFromJson(root.value(QStringLiteral("onedrive")).toObject());
}

CloudClientRegistration CloudConfig::registration(CloudProviderKind kind) const
{
  QSettings *pSettings = Utilities::getApplicationSettings();
  CloudClientRegistration registration = mDeploymentRegistrations[providerIndex(kind)];
  const QString clientId = pSettings->value(settingsKey(kind, QStringLiteral("clientId"))).toString();
  if (!clientId.isEmpty()) {
    registration.clientId = clientId;
    // A user-supplied id comes with its own secret, or none; the deployment's
    // secret belongs to a different application and must not be paired with it.
    registration.clientSecret = pSettings->value(settingsKey(kind, QStringLiteral("clientSecret"))).toString();
    registration.redirectUri = pSettings->value(settingsKey(kind, QStringLiteral("redirectUri"))).toString();
  }
  if (pSettings->contains(settingsKey(kind, QStringLiteral("fullDriveScope")))) {
    registration.fullDriveScope = pSettings->value(settingsKey(kind, QStringLiteral("fullDriveScope"))).toBool();
  }
  return registration;
}

void CloudConfig::setRegistration(CloudProviderKind kind, const CloudClientRegistration &registration)
{
  QSettings *pSettings = Utilities::getApplicationSettings();
  pSettings->setValue(settingsKey(kind, QStringLiteral("clientId")), registration.clientId);
  pSettings->setValue(settingsKey(kind, QStringLiteral("clientSecret")), registration.clientSecret);
  pSettings->setValue(settingsKey(kind, QStringLiteral("fullDriveScope")), registration.fullDriveScope);
  pSettings->setValue(settingsKey(kind, QStringLiteral("redirectUri")), registration.redirectUri);
}

OAuth2Config CloudConfig::oauthConfig(CloudProviderKind kind) const
{
  const ProviderEndpoints &provider = endpoints(kind);
  const CloudClientRegistration client = registration(kind);

  OAuth2Config config;
  config.authorizationUrl = QLatin1String(provider.authorizationUrl);
  config.tokenUrl = QLatin1String(provider.tokenUrl);
  config.clientId = client.clientId;
  config.clientSecret = client.clientSecret;
  config.redirectUri = client.redirectUri;
  config.scope = QLatin1String(provider.scope);
  if (kind == CloudProviderKind::GoogleDrive && client.fullDriveScope) {
    config.scope = QStringLiteral("https://www.googleapis.com/auth/drive");
  }
  const QString extra = QLatin1String(provider.extraAuthorizationParameters);
  if (!extra.isEmpty()) {
    config.extraAuthorizationParameters = extra.split(QLatin1Char(','), Qt::SkipEmptyParts);
  }
  return config;
}
