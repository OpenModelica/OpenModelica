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

#include "Util.h"
#include "MainWindow.h"
#include "Editors/ModelicaEditor.h"
#include "LSP/ModelicaLSPClient.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/ModelWidgetContainer.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QSettings>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QTextBlock>
#include <QToolButton>
#include <QTimer>
#include <QUrl>

class LanguageServerNavigationTest : public QObject
{
  Q_OBJECT
private:
  QTemporaryDir mWorkspace;
  ModelicaLSPClient *mpClient = nullptr;
  ModelWidget *mpSource = nullptr;
  ModelWidget *mpTarget = nullptr;

  void writeFile(const QString &name, const QByteArray &text)
  {
    QFile file(mWorkspace.filePath("NavigationSmoke/" + name));
    QVERIFY2(file.open(QIODevice::WriteOnly), qPrintable(file.errorString()));
    QCOMPARE(file.write(text), qint64(text.size()));
  }

  PlainTextEdit *textEditor(ModelWidget *widget)
  {
    return widget->getEditor()->getPlainTextEdit();
  }

  void showText(ModelWidget *widget)
  {
    MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(widget->getLibraryTreeItem());
    widget->getTextViewToolButton()->setChecked(true);
    textEditor(widget)->setFocus();
  }

  void clickReference()
  {
    auto *editor = textEditor(mpSource);
    QTextCursor cursor = editor->document()->find("Target component");
    QVERIFY(!cursor.isNull());
    cursor.setPosition(cursor.selectionStart() + 2);
    editor->setTextCursor(cursor);
    editor->centerCursor();
    const QPoint point = editor->cursorRect(cursor).center();
    QVERIFY(editor->viewport()->rect().contains(point));
    // Exercise the actual Ctrl+click handler, including editor-to-LSP wiring.
    QTest::mouseClick(editor->viewport(), Qt::LeftButton, Qt::ControlModifier, point);
  }

private slots:
  void initTestCase()
  {
    QVERIFY(mWorkspace.isValid());
    QVERIFY(QDir(mWorkspace.path()).mkdir("NavigationSmoke"));
    writeFile("package.mo", "package NavigationSmoke end NavigationSmoke;\n");
    writeFile("Target.mo", "within NavigationSmoke;\nmodel Target\n  Real x;\nend Target;\n");
    writeFile("Use.mo", "within NavigationSmoke;\nmodel Use\n  Target component;\nend Use;\n");
    auto *window = MainWindow::instance();
    window->getLibraryWidget()->openFile(mWorkspace.filePath("NavigationSmoke/package.mo"));
    auto *tree = window->getLibraryWidget()->getLibraryTreeModel();
    auto *source = tree->findLibraryTreeItem("NavigationSmoke.Use");
    auto *target = tree->findLibraryTreeItem("NavigationSmoke.Target");
    QVERIFY(source);
    QVERIFY(target);
    tree->showModelWidget(target);
    mpTarget = target->getModelWidget();
    tree->showModelWidget(source);
    mpSource = source->getModelWidget();
    QVERIFY(mpSource);
    QVERIFY(mpTarget);
    window->show();
  }

  void init()
  {
    // A fallback can open this same class. Leave its cursor on the last line:
    // only consuming the LSP location should move it to the declaration.
    showText(mpTarget);
    auto cursor = textEditor(mpTarget)->textCursor();
    cursor.movePosition(QTextCursor::End);
    textEditor(mpTarget)->setTextCursor(cursor);
    showText(mpSource);
  }

  void followsLanguageServerDefinition()
  {
    QString executable = qEnvironmentVariable("OMEDIT_TEST_LSP_EXECUTABLE");
#ifdef OMEDIT_TEST_LSP_EXECUTABLE
    if (executable.isEmpty()) executable = QStringLiteral(OMEDIT_TEST_LSP_EXECUTABLE);
#endif
    if (executable.isEmpty()) executable = ModelicaLSPClient::findBundledServer();
    QVERIFY2(QFileInfo(executable).isExecutable(), qPrintable(executable));
    QVERIFY2(ModelicaLSPClient::missingRuntimeFiles(executable).isEmpty(), "Missing LSP WASM files");
    qInfo().noquote() << "Language server:" << executable;

    mpClient = new ModelicaLSPClient(MainWindow::instance());
    MainWindow::instance()->setLSPClient(mpClient);
    QSignalSpy initialized(mpClient, &LSPClient::initialized);
    QSignalSpy definitions(mpClient, &LSPClient::definitionResult);
    QSignalSpy errors(mpClient, &LSPClient::serverError);
    connect(mpClient, &LSPClient::serverError, this, [](const QString &error) { qWarning().noquote() << error; });
    QVERIFY(mpClient->start(executable, QUrl::fromLocalFile(mWorkspace.path()).toString(),
                           {mWorkspace.filePath("NavigationSmoke")}));
    QTRY_COMPARE_WITH_TIMEOUT(initialized.count(), 1, 10000);

    clickReference();
    QTRY_COMPARE_WITH_TIMEOUT(definitions.count(), 1, 10000);
    const auto location = qvariant_cast<LSP::Location>(definitions.first().at(1));
    QCOMPARE(QUrl(location.uri).toLocalFile(), mWorkspace.filePath("NavigationSmoke/Target.mo"));
    QCOMPARE(location.range.start.line, 1);
    QTRY_COMPARE_WITH_TIMEOUT(MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidget(), mpTarget, 5000);
    QCOMPARE(QFileInfo(mpTarget->getLibraryTreeItem()->getFileName()).canonicalFilePath(),
             QFileInfo(mWorkspace.filePath("NavigationSmoke/Target.mo")).canonicalFilePath());
    QVERIFY(mpTarget->getTextViewToolButton()->isChecked());
    // OMEdit currently navigates to the start of the returned line.
    QCOMPARE(textEditor(mpTarget)->textCursor().block().text().trimmed(), QString("model Target"));
    QCOMPARE(textEditor(mpTarget)->textCursor().positionInBlock(), 0);
    QCOMPARE(initialized.count(), 1);
    QCOMPARE(errors.count(), 0);
  }

  void fallsBackOnEmptyDefinitionAndAcceptsNextRequest()
  {
    mpClient = new ModelicaLSPClient(MainWindow::instance());
    MainWindow::instance()->setLSPClient(mpClient);
    QSignalSpy initialized(mpClient, &LSPClient::initialized);
    QSignalSpy definitions(mpClient, &LSPClient::definitionResult);
    QSignalSpy errors(mpClient, &LSPClient::serverError);

    bool observedEmptyResponse = false;
    bool navigatedOnEmptyResponse = false;
    QObject observation; // Cancels callbacks even when an assertion returns early.
    connect(mpClient, &LSPClient::definitionResult, &observation,
            [&](int, const LSP::Location &location) {
      if (!location.isValid()) {
        // Observe after the editor's synchronous response handler. Waiting for
        // the target with QTRY alone could accept the later timeout fallback.
        QTimer::singleShot(0, &observation, [&]() {
          navigatedOnEmptyResponse = MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidget() == mpTarget;
          observedEmptyResponse = true;
        });
      }
    });
    QVERIFY(mpClient->start(QStringLiteral(OMEDIT_DEFINITION_TEST_SERVER),
                           QUrl::fromLocalFile(mWorkspace.path()).toString()));
    QTRY_COMPARE_WITH_TIMEOUT(initialized.count(), 1, 10000);

    clickReference();
    QTRY_VERIFY_WITH_TIMEOUT(observedEmptyResponse, 5000);
    QCOMPARE(definitions.count(), 1);
    QVERIFY(!qvariant_cast<LSP::Location>(definitions.first().at(1)).isValid());
    QVERIFY2(navigatedOnEmptyResponse, "Empty LSP response did not immediately invoke class-tree fallback");
    QVERIFY(mpClient->isRunning());

    // Return to the source and try again with the same editor and client. The
    // fixture now resolves the definition; a stale pending request must not
    // suppress this Ctrl+click or prevent the returned location being applied.
    showText(mpSource);
    clickReference();
    QTRY_COMPARE_WITH_TIMEOUT(definitions.count(), 2, 5000);
    QVERIFY(definitions.at(0).at(0).toInt() != definitions.at(1).at(0).toInt());
    const auto location = qvariant_cast<LSP::Location>(definitions.at(1).at(1));
    QCOMPARE(QUrl(location.uri).toLocalFile(), mWorkspace.filePath("NavigationSmoke/Target.mo"));
    QCOMPARE(MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidget(), mpTarget);
    QCOMPARE(textEditor(mpTarget)->textCursor().block().text().trimmed(), QString("model Target"));
    QCOMPARE(textEditor(mpTarget)->textCursor().positionInBlock(), 0);
    QCOMPARE(initialized.count(), 1);
    QCOMPARE(errors.count(), 0);
    QVERIFY(mpClient->isRunning());
  }

  void fallsBackWithoutLanguageServer()
  {
    QVERIFY(!MainWindow::instance()->getLSPClient());
    clickReference();
    QTRY_COMPARE_WITH_TIMEOUT(MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidget(), mpTarget, 5000);
  }

  void cleanup()
  {
    if (QTest::currentTestFailed()) {
      const QString screenshot = QDir::temp().filePath(
        QString::fromLatin1(QTest::currentTestFunction()) + ".png");
      if (MainWindow::instance()->grab().save(screenshot)) {
        qInfo().noquote() << "Failure screenshot:" << screenshot;
      }
    }
    // Also runs after a failed assertion; stop only the process this test owns.
    MainWindow::instance()->stopLanguageServer();
    mpClient = nullptr;
  }

  void cleanupTestCase()
  {
    MainWindow::instance()->close();
  }
};

// Isolate settings before OMEditApplication reads them. Use the same startup as
// OMEDITTEST_MAIN, with the temporary settings directory alive until app exit.
int main(int argc, char *argv[])
{
  MMC_INIT();
  MMC_TRY_TOP()
  QTemporaryDir settings;
  if (!settings.isValid()) return 1;
  QSettings::setPath(QSettings::IniFormat, QSettings::UserScope, settings.path());
  QSettings::setPath(QSettings::IniFormat, QSettings::SystemScope, settings.path());
  Q_INIT_RESOURCE(resource_omedit);
  OMEditApplication app(argc, argv, threadData, true);
  app.setAttribute(Qt::AA_Use96Dpi, true);
  LanguageServerNavigationTest test;
  return QTest::qExec(&test, argc, argv);
  MMC_CATCH_TOP(return 1);
}

#include "LanguageServerNavigationTest.moc"
