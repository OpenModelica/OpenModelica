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

#include "MCPServerTest.h"
#include "Util.h"
#include "MainWindow.h"
#include "MCP/MCPServer.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Editors/ModelicaEditor.h"
#include "Options/OptionsDialog.h"

#include <QCheckBox>
#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>

OMEDITTEST_MAIN(MCPServerTest)

namespace {
bool writeFile(const QString &filePath, const QByteArray &contents)
{
  QFile file(filePath);
  if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
    return false;
  }
  return file.write(contents) == qint64(contents.size());
}

QString canonicalPath(const QString &filePath)
{
  return QFileInfo(filePath).canonicalFilePath();
}

QJsonObject edit(const QString &oldText, const QString &newText, bool replaceAll = false)
{
  QJsonObject edit{{"oldText", oldText}, {"newText", newText}};
  if (replaceAll) {
    edit.insert("replaceAll", true);
  }
  return edit;
}

QString parameterValue(const QString &className, const QString &parameter)
{
  return MainWindow::instance()->getOMCProxy()->getParameterValue(className, parameter);
}

const QByteArray oneFileText = "package OneFile\n"
                               "  model M\n"
                               "    parameter Real   k=1;\n"
                               "    parameter Real j = 1;\n"
                               "    parameter Real l = 1;\n"
                               "  end M;\n"
                               "end OneFile;\n";
const QByteArray directoryMText = "within Dir;\nmodel M\n  parameter Real k=1;\nend M;\n";
}

#ifdef OMEDIT_MCP
QJsonObject MCPServerTest::callTool(const QString &name, const QJsonObject &arguments)
{
  const QJsonObject request{{"jsonrpc", "2.0"}, {"id", 1}, {"method", "tools/call"},
                            {"params", QJsonObject{{"name", name}, {"arguments", arguments}}}};
  return mpServer->handleMCPRequest(QJsonDocument(request).toJson(), QString(), true).value("result").toObject();
}
#else
QJsonObject MCPServerTest::callTool(const QString &, const QJsonObject &)
{
  return QJsonObject();
}
#endif

QString MCPServerTest::text(const QJsonObject &result)
{
  QStringList texts;
  for (const QJsonValue &content : result.value("content").toArray()) {
    texts.append(content.toObject().value("text").toString());
  }
  return texts.join("\n");
}

LibraryTreeItem* MCPServerTest::findLibraryTreeItem(const QString &className)
{
  return MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(className);
}

void MCPServerTest::initTestCase()
{
#ifndef OMEDIT_MCP
  QSKIP("OMEdit is built without the MCP server.");
#else
  QVERIFY(mTempDir.isValid());
  mpServer = new MCPServer(MainWindow::instance()->getOMCProxy(), false, this);
  mOneFile = mTempDir.filePath("OneFile.mo");
  QVERIFY(writeFile(mOneFile, oneFileText));
  QVERIFY(QDir(mTempDir.path()).mkpath("Dir"));
  QVERIFY(writeFile(mTempDir.filePath("Dir/package.mo"), "package Dir\nend Dir;\n"));
  QVERIFY(writeFile(mTempDir.filePath("Dir/package.order"), "M\n"));
  mDirectoryFile = mTempDir.filePath("Dir/M.mo");
  QVERIFY(writeFile(mDirectoryFile, directoryMText));
  LibraryWidget *pLibraryWidget = MainWindow::instance()->getLibraryWidget();
  pLibraryWidget->openModelicaFile(mOneFile, Helper::utf8, false);
  pLibraryWidget->openModelicaFile(mTempDir.filePath("Dir/package.mo"), Helper::utf8, false);
  QVERIFY(findLibraryTreeItem("OneFile.M"));
  QVERIFY(findLibraryTreeItem("Dir.M"));
#endif
}

void MCPServerTest::getSourceCodeKeepsText()
{
  QJsonObject result = callTool("getSourceCode", {{"className", "OneFile.M"}});
  QVERIFY(!result.value("isError").toBool());
  QCOMPARE(text(result), QString("  model M\n    parameter Real   k=1;\n    parameter Real j = 1;\n    parameter Real l = 1;\n  end M;"));

  result = callTool("getSourceCode", {{"className", "OneFile.M"}, {"startLine", 3}, {"endLine", 3}, {"lineNumbers", true}});
  QCOMPARE(text(result), QString("     3\t    parameter Real   k=1;"));

  result = callTool("getSourceCode", {{"className", "OneFile.M"}, {"startLine", 10}});
  QVERIFY(result.value("isError").toBool());
  QVERIFY2(text(result).contains("lines 2 to 6"), qPrintable(text(result)));

  result = callTool("getSourceCode", {{"className", "Dir.M"}});
  QCOMPARE(text(result), QString(directoryMText));
}

void MCPServerTest::editSourceCode()
{
  const QJsonObject result = callTool("editSourceCode", {{"className", "OneFile.M"}, {"edits", QJsonArray{edit("Real   k=1;", "Real   k=2;")}}});
  QVERIFY2(!result.value("isError").toBool(), qPrintable(text(result)));
  QVERIFY2(text(result).contains("--- OneFile.M\n+++ OneFile.M\n@@ -2,4 +2,4 @@\n   model M\n-    parameter Real   k=1;\n"
                                  "+    parameter Real   k=2;\n     parameter Real j = 1;\n     parameter Real l = 1;"), qPrintable(text(result)));
  QCOMPARE(parameterValue("OneFile.M", "k"), QString("2"));
  const QString source = text(callTool("getSourceCode", {{"className", "OneFile.M"}}));
  QVERIFY2(source.contains("parameter Real   k=2;\n    parameter Real j = 1;"), qPrintable(source));
  QVERIFY(!findLibraryTreeItem("OneFile")->isSaved());
  QFile file(mOneFile);
  QVERIFY(file.open(QIODevice::ReadOnly));
  QCOMPARE(file.readAll(), oneFileText);
}

void MCPServerTest::editSourceCodeErrors()
{
  QJsonObject result = callTool("editSourceCode", {{"className", "OneFile.M"}, {"edits", QJsonArray{edit("k=5", "k=6")}}});
  QVERIFY(result.value("isError").toBool());
  QVERIFY2(text(result).contains("was not found"), qPrintable(text(result)));

  result = callTool("editSourceCode", {{"className", "OneFile.M"}, {"edits", QJsonArray{edit("= 1;", "= 3;")}}});
  QVERIFY(result.value("isError").toBool());
  QVERIFY2(text(result).contains("found 2 times, on lines 4, 5"), qPrintable(text(result)));

  result = callTool("editSourceCode", {{"className", "OneFile.M"}, {"edits", QJsonArray{edit("= 1;", "= 3;", true)}}});
  QVERIFY2(!result.value("isError").toBool(), qPrintable(text(result)));
  QCOMPARE(parameterValue("OneFile.M", "l"), QString("3"));

  result = callTool("editSourceCode", {{"className", "OneFile.M"}, {"edits", QJsonArray{edit("Real l = 3;", "Real l = 4;"), edit("Real x", "Real y")}}});
  QVERIFY(result.value("isError").toBool());
  QVERIFY2(text(result).contains("Edit 2"), qPrintable(text(result)));
  QCOMPARE(parameterValue("OneFile.M", "l"), QString("3"));

  result = callTool("editSourceCode", {{"className", "OneFile.M"}, {"edits", QJsonArray{edit("Real j = 3;", "Real j = ;")}}});
  QVERIFY(result.value("isError").toBool());
  QVERIFY2(text(result).contains("syntax errors"), qPrintable(text(result)));

  result = callTool("editSourceCode", {{"className", "OneFile.M"}, {"edits", QJsonArray{edit("model M", "model N"), edit("end M;", "end N;")}}});
  QVERIFY(result.value("isError").toBool());
  QVERIFY2(text(result).contains("must define only the class OneFile.M"), qPrintable(text(result)));
  QVERIFY(findLibraryTreeItem("OneFile.M"));
  QVERIFY(text(callTool("getSourceCode", {{"className", "OneFile.M"}})).contains("parameter Real j = 3;"));
}

void MCPServerTest::setSourceCodeKeepsText()
{
  const QString code = "model M\n  parameter Real   k=7;\n  parameter Real j = 3;\n  parameter Real l = 3;\nend M;";
  const QJsonObject result = callTool("setSourceCode", {{"className", "OneFile.M"}, {"code", code}});
  QVERIFY2(!result.value("isError").toBool(), qPrintable(text(result)));
  QVERIFY2(text(result).contains("@@ -2,5 +2,5 @@"), qPrintable(text(result)));
  QVERIFY2(text(result).contains("-    parameter Real   k=2;\n"), qPrintable(text(result)));
  QVERIFY2(text(result).contains("+  parameter Real   k=7;\n"), qPrintable(text(result)));
  QCOMPARE(text(callTool("getSourceCode", {{"className", "OneFile.M"}})), code);
  QCOMPARE(parameterValue("OneFile.M", "k"), QString("7"));
}

void MCPServerTest::getClassLocation()
{
  QJsonObject location = QJsonDocument::fromJson(text(callTool("getClassLocation", {{"className", "OneFile.M"}})).toUtf8()).object();
  QCOMPARE(canonicalPath(location.value("file").toString()), canonicalPath(mOneFile));
  QCOMPARE(location.value("startLine").toInt(), 2);
  QCOMPARE(location.value("endLine").toInt(), 6);
  QCOMPARE(location.value("library").toString(), QString("OneFile"));
  QCOMPARE(canonicalPath(location.value("libraryFile").toString()), canonicalPath(mOneFile));
  QCOMPARE(location.value("unsavedChanges").toBool(), true);
  QCOMPARE(location.value("readOnly").toBool(), false);

  location = QJsonDocument::fromJson(text(callTool("getClassLocation", {{"className", "Dir.M"}})).toUtf8()).object();
  QCOMPARE(canonicalPath(location.value("file").toString()), canonicalPath(mDirectoryFile));
  QCOMPARE(location.value("startLine").toInt(), 2);
  QCOMPARE(location.value("unsavedChanges").toBool(), false);

  QVERIFY(callTool("getClassLocation", {{"className", "NoSuchClass"}}).value("isError").toBool());
  if (!MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidget()) {
    const QJsonObject result = callTool("getClassLocation", {});
    QVERIFY(result.value("isError").toBool());
    QVERIFY2(text(result).contains("No active model"), qPrintable(text(result)));
  }
}

void MCPServerTest::refuseUnappliedTextChanges()
{
  LibraryTreeItem *pLibraryTreeItem = findLibraryTreeItem("OneFile.M");
  MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(pLibraryTreeItem, true);
  ModelWidget *pModelWidget = pLibraryTreeItem->getModelWidget();
  QVERIFY(pModelWidget);
  if (!pModelWidget->isLoadedWidgetComponents()) {
    pModelWidget->createModelWidgetComponents();
  }
  ModelicaEditor *pModelicaEditor = dynamic_cast<ModelicaEditor*>(pModelWidget->getEditor());
  QVERIFY(pModelicaEditor);

  pModelicaEditor->setTextChanged(true);
  QJsonObject result = callTool("editSourceCode", {{"className", "OneFile"}, {"edits", QJsonArray{edit("k=7", "k=8")}}});
  QVERIFY(result.value("isError").toBool());
  QVERIFY2(text(result).contains("text view"), qPrintable(text(result)));

  pModelicaEditor->setTextChanged(false);
  result = callTool("editSourceCode", {{"className", "OneFile.M"}, {"edits", QJsonArray{edit("k=7", "k=8")}}});
  QVERIFY2(!result.value("isError").toBool(), qPrintable(text(result)));
  QVERIFY2(pModelicaEditor->getPlainText().contains("parameter Real   k=8;"), qPrintable(pModelicaEditor->getPlainText()));

  const QJsonObject location = QJsonDocument::fromJson(text(callTool("getClassLocation", {})).toUtf8()).object();
  QCOMPARE(location.value("className").toString(), QString("OneFile.M"));
}

void MCPServerTest::reloadFileChangedOnDisk()
{
  QVERIFY(findLibraryTreeItem("Dir")->isSaved());
  QCheckBox *pReloadCheckBox = OptionsDialog::instance()->getGeneralSettingsPage()->getReloadLibraryOnFileChangeCheckBox();
  pReloadCheckBox->setChecked(false);
  const QByteArray changedText = "within Dir;\nmodel M\n  parameter Real k=3;\n  parameter Real x=4;\nend M;\n";
  QVERIFY(writeFile(mDirectoryFile, changedText));
  QJsonObject result = callTool("getSourceCode", {{"className", "Dir.M"}});
  QVERIFY2(text(result).startsWith(QString(directoryMText)), qPrintable(text(result)));
  QVERIFY2(text(result).contains("option to reload libraries"), qPrintable(text(result)));

  pReloadCheckBox->setChecked(true);
  result = callTool("getSourceCode", {{"className", "Dir.M"}});
  QCOMPARE(text(result), QString(changedText));
  QCOMPARE(parameterValue("Dir.M", "x"), QString("4"));
  QVERIFY(findLibraryTreeItem("Dir")->isSaved());
  QVERIFY(findLibraryTreeItem("Dir.M")->isSaved());

  QVERIFY(writeFile(mDirectoryFile, "within Dir;\nmodel M\n  parameter Real k=;\nend M;\n"));
  result = callTool("getSourceCode", {{"className", "Dir.M"}});
  QVERIFY2(text(result).startsWith(QString(changedText)), qPrintable(text(result)));
  QVERIFY2(text(result).contains("they have errors"), qPrintable(text(result)));

  const QByteArray fixedText = "within Dir;\nmodel M\n  parameter Real k=5;\nend M;\n";
  QVERIFY(writeFile(mDirectoryFile, fixedText));
  QCOMPARE(text(callTool("getSourceCode", {{"className", "Dir.M"}})), QString(fixedText));

  QVERIFY(writeFile(mTempDir.filePath("Dir/N.mo"), "within Dir;\nmodel N\nend N;\n"));
  QVERIFY(writeFile(mTempDir.filePath("Dir/package.order"), "M\nN\n"));
  result = callTool("getClassNames", {{"className", "Dir"}});
  QVERIFY2(text(result).contains("\"N\""), qPrintable(text(result)));
  QVERIFY(findLibraryTreeItem("Dir.N"));

  result = callTool("editSourceCode", {{"className", "Dir.M"}, {"edits", QJsonArray{edit("k=5", "k=6")}}});
  QVERIFY2(!result.value("isError").toBool(), qPrintable(text(result)));
  QVERIFY(writeFile(mDirectoryFile, "within Dir;\nmodel M\n  parameter Real k=99;\nend M;\n"));
  result = callTool("getSourceCode", {{"className", "Dir.M"}});
  QVERIFY2(text(result).contains("k=6;"), qPrintable(text(result)));
  QVERIFY2(text(result).contains("has unsaved changes"), qPrintable(text(result)));
}

void MCPServerTest::cleanupTestCase()
{
  LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
  for (const QString &library : {QString("OneFile"), QString("Dir")}) {
    if (LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItemOneLevel(library)) {
      pLibraryTreeModel->unloadClass(pLibraryTreeItem, false);
    }
  }
  MainWindow::instance()->close();
}
