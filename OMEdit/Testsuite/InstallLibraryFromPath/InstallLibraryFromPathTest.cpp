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

#include "InstallLibraryFromPathTest.h"
#include "Util.h"
#include "Modeling/InstallLibraryDialog.h"
#include "omcruntime_rust.h"

#include <QListWidget>

OMEDITTEST_MAIN(InstallLibraryFromPathTest)

static void writeFile(const QString &fileName, const QByteArray &contents)
{
  QDir().mkpath(QFileInfo(fileName).absolutePath());
  QFile file(fileName);
  QVERIFY(file.open(QIODevice::WriteOnly));
  file.write(contents);
}

static QByteArray readFile(const QString &fileName)
{
  QFile file(fileName);
  return file.open(QIODevice::ReadOnly) ? file.readAll() : QByteArray();
}

void InstallLibraryFromPathTest::initTestCase()
{
  QVERIFY(mDirectory.isValid());
  mSource = mDirectory.filePath("Repo-1");
  writeFile(mSource + "/A/package.mo", "package A\nend A;\n");
  writeFile(mSource + "/A/M.mo", "within A;\nmodel M\nend M;\n");
  writeFile(mSource + "/A/package.order", "M\n");
  writeFile(mSource + "/B.mo", "package B\nend B;\n");
  writeFile(mSource + "/Two.mo", "package X\nend X;\npackage Y\nend Y;\n");
  writeFile(mSource + "/sub/C/package.mo", "package C\nend C;\n");
}

/*!
 * \brief InstallLibraryFromPathTest::install
 * Installs all the packages the dialog lists for path into libraries, and returns their sorted names.
 */
QStringList InstallLibraryFromPathTest::install(const QString &path, const QString &libraries)
{
  InstallLibraryFromPathDialog *pDialog = new InstallLibraryFromPathDialog(path, libraries);
  QStringList names;
  QListWidget *pList = pDialog->findChild<QListWidget*>();
  for (int i = 0; pList && i < pList->count(); ++i) {
    names << pList->item(i)->text();
  }
  QMetaObject::invokeMethod(pDialog, "installPackages");
  names.sort();
  return names;
}

/*!
 * \brief InstallLibraryFromPathTest::fromDirectory
 * The package directories and the .mo files with one class are installed, a file with two classes is not.
 */
void InstallLibraryFromPathTest::fromDirectory()
{
  const QString libraries = mDirectory.filePath("libraries1");
  QCOMPARE(install(mSource, libraries), QStringList({"A", "B", "C"}));
  QCOMPARE(readFile(libraries + "/A/M.mo"), QByteArray("within A;\nmodel M\nend M;\n"));
  QCOMPARE(readFile(libraries + "/B.mo"), QByteArray("package B\nend B;\n"));
  QVERIFY(QFile::exists(libraries + "/C/package.mo"));
  QVERIFY(!QFile::exists(libraries + "/Two.mo"));
  QCOMPARE(install(mSource + "/B.mo", libraries), QStringList({"B (replaces the installed B)"}));
}

/*!
 * \brief InstallLibraryFromPathTest::fromZip
 * Only the packages are extracted from a zip file, without its top directory.
 */
void InstallLibraryFromPathTest::fromZip()
{
  const QString zip = mDirectory.filePath("Repo-1.zip");
  const QByteArray source = mSource.toUtf8(), entry = QByteArray("Repo-1");
  const char *paths[] = {source.constData()}, *entryNames[] = {entry.constData()};
  char *error = omcrs_zip_paths(zip.toUtf8().constData(), paths, entryNames, 1, nullptr, 0);
  QVERIFY2(!error, error);
  const QString libraries = mDirectory.filePath("libraries2");
  QCOMPARE(install(zip, libraries), QStringList({"A", "B", "C"}));
  QCOMPARE(readFile(libraries + "/A/package.order"), QByteArray("M\n"));
  QVERIFY(QFile::exists(libraries + "/B.mo"));
  QVERIFY(QFile::exists(libraries + "/C/package.mo"));
  QCOMPARE(QDir(libraries).entryList(QDir::AllEntries | QDir::NoDotAndDotDot), QStringList({"A", "B.mo", "C"}));
}
