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

#include "GitLineChangesTest.h"
#include "Editors/GitLineChanges.h"

#include <QtTest>

QTEST_APPLESS_MAIN(GitLineChangesTest)

void GitLineChangesTest::computeChanges_data()
{
  const int A = GitLineChanges::Added;
  const int M = GitLineChanges::Modified;
  const int DA = GitLineChanges::DeletedAbove;
  const int DB = GitLineChanges::DeletedBelow;
  QTest::addColumn<QStringList>("oldLines");
  QTest::addColumn<QStringList>("newLines");
  QTest::addColumn<QList<int>>("changes");

  QTest::newRow("unchanged") << QStringList({"a", "b", "c"}) << QStringList({"a", "b", "c"}) << QList<int>({0, 0, 0});
  QTest::newRow("added") << QStringList({"a", "b", "c"}) << QStringList({"a", "x", "b", "c"}) << QList<int>({0, A, 0, 0});
  QTest::newRow("added at end") << QStringList({"a"}) << QStringList({"a", "x", "y"}) << QList<int>({0, A, A});
  QTest::newRow("new file") << QStringList() << QStringList({"a", "b"}) << QList<int>({A, A});
  QTest::newRow("modified") << QStringList({"a", "b", "c"}) << QStringList({"a", "B", "c"}) << QList<int>({0, M, 0});
  QTest::newRow("modified with more lines") << QStringList({"a", "b", "c"}) << QStringList({"a", "B1", "B2", "c"}) << QList<int>({0, M, M, 0});
  QTest::newRow("deleted") << QStringList({"a", "b", "c"}) << QStringList({"a", "c"}) << QList<int>({0, DA});
  QTest::newRow("deleted at start") << QStringList({"a", "b", "c"}) << QStringList({"b", "c"}) << QList<int>({DA, 0});
  QTest::newRow("deleted at end") << QStringList({"a", "b", "c"}) << QStringList({"a", "b"}) << QList<int>({0, DB});
  QTest::newRow("repeated lines") << QStringList({"x", "a", "x"}) << QStringList({"x", "x"}) << QList<int>({0, DA});
  QTest::newRow("mixed") << QStringList({"a", "b", "c", "d", "e"}) << QStringList({"a", "X", "c", "e", "f"})
                         << QList<int>({0, M, 0, DA, A});
  QTest::newRow("moved line") << QStringList({"a", "b", "c", "d"}) << QStringList({"b", "c", "d", "a"})
                              << QList<int>({DA, 0, 0, A});
}

void GitLineChangesTest::computeChanges()
{
  QFETCH(QStringList, oldLines);
  QFETCH(QStringList, newLines);
  QFETCH(QList<int>, changes);
  QCOMPARE(GitLineChanges::computeChanges(oldLines, newLines), changes);
}

void GitLineChangesTest::largeDifference()
{
  // no common lines in the middle; the changed range is marked as modified
  QStringList oldLines, newLines;
  oldLines << "begin";
  newLines << "begin";
  for (int i = 0; i < 2000; ++i) {
    oldLines << QString("old %1").arg(i);
    newLines << QString("new %1").arg(i);
  }
  oldLines << "end";
  newLines << "end";
  const QList<int> changes = GitLineChanges::computeChanges(oldLines, newLines);
  QCOMPARE(changes.size(), newLines.size());
  QCOMPARE(changes.first(), int(GitLineChanges::None));
  QCOMPARE(changes.last(), int(GitLineChanges::None));
  for (int i = 1; i < changes.size() - 1; ++i) {
    QCOMPARE(changes.at(i), int(GitLineChanges::Modified));
  }
}

void GitLineChangesTest::tooManyLines()
{
  // diff_match_patch stores a line as one 16-bit character
  QStringList oldLines, newLines;
  for (int i = 0; i < 70000; ++i) {
    oldLines << QString("line %1").arg(i);
  }
  // only the changed lines are given to diff_match_patch
  newLines = oldLines;
  newLines[10] = "changed";
  QList<int> changes(newLines.size(), int(GitLineChanges::None));
  changes[10] = GitLineChanges::Modified;
  QCOMPARE(GitLineChanges::computeChanges(oldLines, newLines), changes);
  // too many distinct changed lines; the changed range is marked as modified
  newLines.clear();
  newLines << oldLines.first();
  for (int i = 1; i < oldLines.size() - 1; ++i) {
    newLines << QString("new line %1").arg(i);
  }
  newLines << oldLines.last();
  changes.fill(int(GitLineChanges::Modified));
  changes.first() = GitLineChanges::None;
  changes.last() = GitLineChanges::None;
  QCOMPARE(GitLineChanges::computeChanges(oldLines, newLines), changes);
}
