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

#include "LSP/ModelicaLSPClient.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QJsonArray>

/*!
 * \brief ModelicaLSPClient::ModelicaLSPClient
 * \param pParent
 */
ModelicaLSPClient::ModelicaLSPClient(QObject *pParent)
  : LSPClient(pParent)
{
}

/*!
 * \brief ModelicaLSPClient::defaultServerName
 */
QString ModelicaLSPClient::defaultServerName()
{
  return QStringLiteral("modelica-language-server");
}

/*!
 * \brief ModelicaLSPClient::initializationOptions
 * Passes the configured library roots to the server as its modelicaPath so that
 * go-to-definition and hover can resolve symbols across files.
 */
QJsonObject ModelicaLSPClient::initializationOptions(const QStringList &libraries) const
{
  QJsonObject options;
  if (!libraries.isEmpty()) {
    QJsonArray modelicaPath;
    for (const QString &lib : libraries) {
      modelicaPath.append(lib);
    }
    options["modelicaPath"] = modelicaPath;
  }
  return options;
}

/*!
 * \brief ModelicaLSPClient::findBundledServer
 * Looks for the Modelica language server shipped alongside OMEdit.
 * Prefers a standalone binary (no Node.js required) over server.js.
 * Checks next to the executable first (Windows / dev builds), then the
 * installed share directory (Linux / macOS).
 */
QString ModelicaLSPClient::findBundledServer()
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
