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
#include "Util/Helper.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QStandardPaths>

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
 * installed share directory (Linux / macOS), and finally the share directory
 * of the OpenModelica installation OMEdit is talking to — a binary run from
 * the build tree has no share directory of its own.
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

  QStringList directories;
  directories << appDir.absolutePath()
              << QDir::cleanPath(appDir.filePath(QStringLiteral("../share/omedit")));
  if (!Helper::OpenModelicaHome.isEmpty()) {
    directories << QDir::cleanPath(Helper::OpenModelicaHome + QStringLiteral("/share/omedit"));
  }

  // Prefer a standalone binary — no Node.js required — over server.js.
  for (const QString &name : {binaryName, jsName}) {
    for (const QString &directory : directories) {
      const QString candidate = directory + QStringLiteral("/") + name;
      if (QFile::exists(candidate)) {
        return candidate;
      }
    }
  }
  return QString();
}

/*!
 * \brief ModelicaLSPClient::resolveExecutable
 * Resolves the server to run: the configured one, else a bundled one, else a
 * standalone server on PATH.
 *
 * A bundled server.js cannot run without Node.js, so when Node.js is missing a
 * standalone server on PATH is preferred over it. The unusable bundled path is
 * still returned as a last resort, so the caller can tell the user that Node.js
 * is what is missing instead of reporting no server at all.
 */
QString ModelicaLSPClient::resolveExecutable(const QString &configured)
{
  if (!configured.isEmpty()) {
    return configured;
  }
  const QString bundled = findBundledServer();
  const bool bundledNeedsNode = bundled.endsWith(QStringLiteral(".js")) && LSPClient::findNodeExecutable().isEmpty();
  if (!bundled.isEmpty() && !bundledNeedsNode) {
    return bundled;
  }
  const QString onPath = QStandardPaths::findExecutable(defaultServerName());
  if (!onPath.isEmpty()) {
    return onPath;
  }
  return bundled;
}
