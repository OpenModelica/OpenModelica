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

/*
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#include "Modeling/LibraryFileWatcher.h"
#include "Util/RecursiveFileWatcher.h"

#include <QFile>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QtTest>

namespace {
bool writeFile(const QString &filePath, const QByteArray &contents)
{
  QFile file(filePath);
  if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
    return false;
  }
  return file.write(contents) == qint64(contents.size());
}

//! Every path the given signal argument carried, from all signals received so far.
QStringList pathsOf(const QSignalSpy &spy, int argument)
{
  QStringList paths;
  for (const QList<QVariant> &signalArguments : spy) {
    paths.append(signalArguments.at(argument).toStringList());
  }
  return paths;
}
}

class RecursiveFileWatcherTest : public QObject
{
  Q_OBJECT
private slots:
  void detectsChangedFile();
  void checksChangesBeforeWatcherFlush();
  void rescanReportsChangesAtOnce();
  void detectsCreatedAndDeletedFile();
  void ignorePathDoesNotReportChange();
  void watchesSingleFileRoot();
  void ignoresEditorTemporaryFiles();
};

void RecursiveFileWatcherTest::detectsChangedFile()
{
  QTemporaryDir tempDir;
  QVERIFY(tempDir.isValid());
  const QString filePath = tempDir.filePath(QStringLiteral("A.mo"));
  QVERIFY(writeFile(filePath, "model A\nend A;\n"));

  RecursiveFileWatcher watcher;
  watcher.setRoots(QStringList{tempDir.path()});
  QSignalSpy spy(&watcher, &RecursiveFileWatcher::filesChanged);
  QVERIFY(writeFile(filePath, "model A\n  Real x;\nend A;\n"));

  QTRY_VERIFY_WITH_TIMEOUT((!pathsOf(spy, 0).isEmpty()), 5000);
  QCOMPARE(pathsOf(spy, 0), QStringList{filePath});
  QVERIFY(pathsOf(spy, 1).isEmpty());
  QVERIFY(pathsOf(spy, 2).isEmpty());
}

void RecursiveFileWatcherTest::checksChangesBeforeWatcherFlush()
{
  QTemporaryDir tempDir;
  QVERIFY(tempDir.isValid());
  const QString filePath = tempDir.filePath(QStringLiteral("A.mo"));
  QVERIFY(writeFile(filePath, "model A\nend A;\n"));

  RecursiveFileWatcher watcher;
  watcher.setRoots(QStringList{tempDir.path()});
  QVERIFY(writeFile(filePath, "model A\n  Real x;\nend A;\n"));
  QVERIFY(watcher.hasChangedSinceSnapshot(filePath));

  watcher.ignorePath(filePath);
  QVERIFY(!watcher.hasChangedSinceSnapshot(filePath));
}

void RecursiveFileWatcherTest::rescanReportsChangesAtOnce()
{
  QTemporaryDir tempDir;
  QVERIFY(tempDir.isValid());
  const QString filePath = tempDir.filePath(QStringLiteral("A.mo"));
  QVERIFY(writeFile(filePath, "model A\nend A;\n"));

  RecursiveFileWatcher watcher;
  watcher.setRoots(QStringList{tempDir.path()});
  QSignalSpy spy(&watcher, &RecursiveFileWatcher::filesChanged);
  QVERIFY(writeFile(filePath, "model A\n  Real x;\nend A;\n"));
  watcher.rescan();
  QCOMPARE(spy.count(), 1);
  QCOMPARE(pathsOf(spy, 0), QStringList{filePath});

  watcher.rescan();
  QCOMPARE(spy.count(), 1);
}

void RecursiveFileWatcherTest::detectsCreatedAndDeletedFile()
{
  QTemporaryDir tempDir;
  QVERIFY(tempDir.isValid());
  RecursiveFileWatcher watcher;
  watcher.setRoots(QStringList{tempDir.path()});
  QSignalSpy spy(&watcher, &RecursiveFileWatcher::filesChanged);

  const QString filePath = tempDir.filePath(QStringLiteral("New.mo"));
  QVERIFY(writeFile(filePath, "model New\nend New;\n"));
  QVERIFY(watcher.hasChangedSinceSnapshot(filePath));
  QTRY_VERIFY_WITH_TIMEOUT((pathsOf(spy, 1).contains(filePath)), 5000);
  QCOMPARE(pathsOf(spy, 1), QStringList{filePath});

  spy.clear();
  QVERIFY(QFile::remove(filePath));
  QVERIFY(watcher.hasChangedSinceSnapshot(filePath));
  QTRY_VERIFY_WITH_TIMEOUT((pathsOf(spy, 2).contains(filePath)), 5000);
  QCOMPARE(pathsOf(spy, 2), QStringList{filePath});
}

void RecursiveFileWatcherTest::ignorePathDoesNotReportChange()
{
  QTemporaryDir tempDir;
  QVERIFY(tempDir.isValid());
  const QString filePath = tempDir.filePath(QStringLiteral("A.mo"));
  QVERIFY(writeFile(filePath, "model A\nend A;\n"));
  RecursiveFileWatcher watcher;
  watcher.setRoots(QStringList{tempDir.path()});
  QSignalSpy spy(&watcher, &RecursiveFileWatcher::filesChanged);

  QVERIFY(writeFile(filePath, "model A\n  Real x;\nend A;\n"));
  watcher.ignorePath(filePath);
  QTest::qWait(1500);
  QCOMPARE(spy.count(), 0);
}

void RecursiveFileWatcherTest::watchesSingleFileRoot()
{
  QTemporaryDir tempDir;
  QVERIFY(tempDir.isValid());
  const QString filePath = tempDir.filePath(QStringLiteral("A.mo"));
  QVERIFY(writeFile(filePath, "model A\nend A;\n"));
  RecursiveFileWatcher watcher;
  watcher.setRoots(QStringList{filePath});
  QSignalSpy spy(&watcher, &RecursiveFileWatcher::filesChanged);

  QVERIFY(writeFile(filePath, "model A\n  Real x;\nend A;\n"));
  QTRY_VERIFY_WITH_TIMEOUT((pathsOf(spy, 0).contains(filePath)), 5000);
  QCOMPARE(pathsOf(spy, 0), QStringList{filePath});
}

void RecursiveFileWatcherTest::ignoresEditorTemporaryFiles()
{
  QTemporaryDir tempDir;
  QVERIFY(tempDir.isValid());
  QVERIFY(writeFile(tempDir.filePath(QStringLiteral("package.mo")), "package P\nend P;\n"));
  LibraryFileWatcher watcher;
  watcher.setRoots(QStringList{tempDir.path()});
  QSignalSpy spy(&watcher, &RecursiveFileWatcher::filesChanged);

  QVERIFY(writeFile(tempDir.filePath(QStringLiteral(".A.mo.swp")), "temporary"));
  QVERIFY(writeFile(tempDir.filePath(QStringLiteral("A.mo~")), "temporary"));
  QVERIFY(writeFile(tempDir.filePath(QStringLiteral("A.bak-mo")), "backup"));
  QTest::qWait(1500);
  QCOMPARE(spy.count(), 0);

  const QString filePath = tempDir.filePath(QStringLiteral("B.mo"));
  QVERIFY(writeFile(filePath, "model B\nend B;\n"));
  QTRY_VERIFY_WITH_TIMEOUT((pathsOf(spy, 1).contains(filePath)), 5000);
  QCOMPARE(pathsOf(spy, 1), QStringList{filePath});
}

QTEST_GUILESS_MAIN(RecursiveFileWatcherTest)

#include "RecursiveFileWatcherTest.moc"
