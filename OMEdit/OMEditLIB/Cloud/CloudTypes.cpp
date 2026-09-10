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

#include "Cloud/CloudTypes.h"

#include <QCoreApplication>
#include <QDebug>

#if defined(__EMSCRIPTEN__)
#include <emscripten.h>
#include <emscripten/em_js.h>

EM_JS(void, omedit_cloud_log, (const char *message), {
  console.log("[OMEdit]", UTF8ToString(message));
});
#endif

void cloudLog(const QString &message)
{
#if defined(__EMSCRIPTEN__)
  omedit_cloud_log(message.toUtf8().constData());
#else
  qDebug().noquote() << "[OMEdit]" << message;
#endif
}

QString cloudProviderKindToString(CloudProviderKind kind)
{
  switch (kind) {
    case CloudProviderKind::GoogleDrive: return QStringLiteral("googledrive");
    case CloudProviderKind::OneDrive:    return QStringLiteral("onedrive");
  }
  return QString();
}

bool cloudProviderKindFromString(const QString &text, CloudProviderKind *kind)
{
  if (text == QLatin1String("googledrive")) {
    *kind = CloudProviderKind::GoogleDrive;
    return true;
  }
  if (text == QLatin1String("onedrive")) {
    *kind = CloudProviderKind::OneDrive;
    return true;
  }
  return false;
}

QString cloudProviderDisplayName(CloudProviderKind kind)
{
  switch (kind) {
    case CloudProviderKind::GoogleDrive:
      return QCoreApplication::translate("Cloud", "Google Drive");
    case CloudProviderKind::OneDrive:
      return QCoreApplication::translate("Cloud", "OneDrive");
  }
  return QString();
}

CloudError CloudError::fromHttpStatus(int status, const QString &message)
{
  Code code = Provider;
  switch (status) {
    case 401: code = Auth; break;
    // Not Auth: Drive also returns 403 for rate limiting and for a plain
    // permission denial, and treating those as "sign in again" would loop.
    // The provider refines it from the error body.
    case 403: code = Provider; break;
    case 404: code = NotFound; break;
    // 412 is our own If-Match precondition; 409 is a name/parent clash.
    case 409:
    case 412: code = Conflict; break;
    case 429: code = RateLimited; break;
    default:
      if (status >= 500) {
        code = Network;
      }
      break;
  }
  return CloudError(code, message, status);
}
