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

#include "LanguageServerTest.h"
#include "Util.h"
#include "MainWindow.h"
#include "LSP/ModelicaLSPClient.h"
#include "Util/Helper.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QStringBuilder>
#include <QtTest/QtTest>

namespace {
  //! Name the build installs the standalone server under.
  QString serverBinaryName()
  {
#ifdef Q_OS_WIN
    return QStringLiteral("modelica-language-server.exe");
#else
    return QStringLiteral("modelica-language-server");
#endif
  }
}

OMEDITTEST_MAIN(LanguageServerTest)

void LanguageServerTest::createServerFile(const QString &filePath)
{
  QVERIFY2(QDir().mkpath(QFileInfo(filePath).absolutePath()), qPrintable(filePath));
  QFile file(filePath);
  QVERIFY2(file.open(QIODevice::WriteOnly), qPrintable(filePath));
  file.write("placeholder\n");
  file.close();
  // findBundledServer() only checks for existence, but an installed server is
  // executable and the tests should not depend on that staying true.
  file.setPermissions(file.permissions() | QFileDevice::ExeOwner);
}

QString LanguageServerTest::installedServerDirectory() const
{
  return mTemporaryHome % QStringLiteral("/share/omedit/ls");
}

void LanguageServerTest::initTestCase()
{
  // findBundledServer() searches OpenModelicaHome, so a temporary one stands in
  // for an installation without needing anything to be installed.
  mOriginalOpenModelicaHome = Helper::OpenModelicaHome;
  mTemporaryHome = QDir::tempPath() % QStringLiteral("/omedit-languageserver-test-")
                   % QString::number(QCoreApplication::applicationPid());
  QVERIFY(QDir().mkpath(mTemporaryHome));
  Helper::OpenModelicaHome = mTemporaryHome;
}

void LanguageServerTest::findsInstalledBinary()
{
  QDir(installedServerDirectory()).removeRecursively();
  const QString server = installedServerDirectory() % QStringLiteral("/") % serverBinaryName();
  createServerFile(server);

  QCOMPARE(ModelicaLSPClient::findBundledServer(), server);
}

void LanguageServerTest::prefersBinaryOverScript()
{
  QDir(installedServerDirectory()).removeRecursively();
  const QString binary = installedServerDirectory() % QStringLiteral("/") % serverBinaryName();
  const QString script = installedServerDirectory() % QStringLiteral("/server.js");
  createServerFile(script);
  createServerFile(binary);

  // The standalone server needs no Node.js, so it wins.
  QCOMPARE(ModelicaLSPClient::findBundledServer(), binary);
}

void LanguageServerTest::findsScriptWhenNoBinary()
{
  QDir(installedServerDirectory()).removeRecursively();
  const QString script = installedServerDirectory() % QStringLiteral("/server.js");
  createServerFile(script);

  QCOMPARE(ModelicaLSPClient::findBundledServer(), script);
}

void LanguageServerTest::ignoresEmptyInstallation()
{
  QVERIFY(QDir(installedServerDirectory()).removeRecursively());

  // A server may still be found next to the test executable, so assert only
  // that nothing is reported out of the installation under test.
  const QString found = ModelicaLSPClient::findBundledServer();
  QVERIFY2(!found.startsWith(mTemporaryHome), qPrintable(found));
}

void LanguageServerTest::emptySettingUsesInstalledServer()
{
  QDir(installedServerDirectory()).removeRecursively();
  const QString server = installedServerDirectory() % QStringLiteral("/") % serverBinaryName();
  createServerFile(server);

  // An empty *Server Executable* setting runs the server that was installed.
  QCOMPARE(ModelicaLSPClient::resolveExecutable(QString()), server);
}

void LanguageServerTest::configuredSettingWins()
{
  QDir(installedServerDirectory()).removeRecursively();
  const QString server = installedServerDirectory() % QStringLiteral("/") % serverBinaryName();
  createServerFile(server);

  // A server the user configured is used as given, installed one or not.
  const QString configured = QDir::tempPath() % QStringLiteral("/a-server-of-my-own");
  QCOMPARE(ModelicaLSPClient::resolveExecutable(configured), configured);
}

void LanguageServerTest::reportsMissingRuntimeFiles()
{
  QDir(installedServerDirectory()).removeRecursively();
  const QString server = installedServerDirectory() % QStringLiteral("/") % serverBinaryName();
  createServerFile(server);

  // The server on its own cannot parse anything: it loads the grammar and the
  // tree-sitter runtime from its own directory.
  QCOMPARE(ModelicaLSPClient::missingRuntimeFiles(server),
           QStringList({QStringLiteral("tree-sitter-modelica.wasm"),
                        QStringLiteral("web-tree-sitter.wasm")}));

  createServerFile(installedServerDirectory() % QStringLiteral("/tree-sitter-modelica.wasm"));
  QCOMPARE(ModelicaLSPClient::missingRuntimeFiles(server),
           QStringList({QStringLiteral("web-tree-sitter.wasm")}));
}

void LanguageServerTest::reportsNothingWhenRuntimeFilesPresent()
{
  QDir(installedServerDirectory()).removeRecursively();
  const QString server = installedServerDirectory() % QStringLiteral("/") % serverBinaryName();
  createServerFile(server);
  createServerFile(installedServerDirectory() % QStringLiteral("/tree-sitter-modelica.wasm"));
  createServerFile(installedServerDirectory() % QStringLiteral("/web-tree-sitter.wasm"));

  QVERIFY(ModelicaLSPClient::missingRuntimeFiles(server).isEmpty());
}

void LanguageServerTest::cleanupTestCase()
{
  Helper::OpenModelicaHome = mOriginalOpenModelicaHome;
  QDir(mTemporaryHome).removeRecursively();
  MainWindow::instance()->close();
}
