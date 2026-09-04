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

// The three-way sync planner. Every row of the decision matrix is asserted here,
// plus the rules that stop a missing working copy from wiping a cloud package.
// Pure: no network, no provider, no files beyond the manifest round trip.

#include "Cloud/CloudManifest.h"

#include <QCryptographicHash>
#include <QTemporaryDir>
#include <QtTest>

namespace {

QByteArray hashOf(const QByteArray &contents)
{
  return QCryptographicHash::hash(contents, QCryptographicHash::Sha256);
}

void addManifest(CloudManifest *pManifest, const QString &path, const QByteArray &contents, const QString &revision,
                 bool isFolder = false)
{
  ManifestEntry entry;
  entry.relativePath = path;
  entry.remoteId = QStringLiteral("id-%1").arg(path);
  entry.remoteRevision = revision;
  entry.contentHash = isFolder ? QByteArray() : hashOf(contents);
  entry.size = contents.size();
  entry.isFolder = isFolder;
  pManifest->entries.insert(path, entry);
}

void addLocal(QMap<QString, LocalEntry> *pLocal, const QString &path, const QByteArray &contents,
              bool isFolder = false)
{
  LocalEntry entry;
  entry.relativePath = path;
  entry.contentHash = isFolder ? QByteArray() : hashOf(contents);
  entry.size = contents.size();
  entry.isFolder = isFolder;
  pLocal->insert(path, entry);
}

void addRemote(QMap<QString, RemoteEntry> *pRemote, const QString &path, const QString &revision,
               bool isFolder = false)
{
  RemoteEntry entry;
  entry.relativePath = path;
  entry.remoteId = QStringLiteral("id-%1").arg(path);
  entry.remoteRevision = revision;
  entry.isFolder = isFolder;
  pRemote->insert(path, entry);
}

//! The single action the plan proposes for path, or a default-constructed one.
SyncAction actionFor(const SyncPlan &plan, const QString &path)
{
  for (const SyncAction &action : plan.actions) {
    if (action.relativePath == path) {
      return action;
    }
  }
  SyncAction none;
  none.kind = SyncAction::DropManifestEntry;
  none.relativePath = QStringLiteral("<absent>");
  return none;
}

bool hasActionFor(const SyncPlan &plan, const QString &path)
{
  for (const SyncAction &action : plan.actions) {
    if (action.relativePath == path) {
      return true;
    }
  }
  return false;
}

bool hasAction(const SyncPlan &plan, const QString &path, SyncAction::Kind kind)
{
  for (const SyncAction &action : plan.actions) {
    if (action.relativePath == path && action.kind == kind) {
      return true;
    }
  }
  return false;
}

} // namespace

class CloudSyncPlanTest : public QObject
{
  Q_OBJECT
private slots:
  void matrix_data();
  void matrix();
  void incompleteWorkingCopyNeverDeletes();
  void completenessIsNotPersisted();
  void deletionThreshold();
  void folderRemovedOnlyWhenEmpty();
  void manifestRoundTrip();
  void unusableRemoteNames();
};

/*!
 * \brief One row per case in the decision matrix.
 * "-" means the file is not present in that view.
 */
void CloudSyncPlanTest::matrix_data()
{
  QTest::addColumn<QString>("manifestContents");
  QTest::addColumn<QString>("manifestRevision");
  QTest::addColumn<QString>("localContents");
  QTest::addColumn<QString>("remoteRevision");
  QTest::addColumn<int>("expectedKind");
  QTest::addColumn<int>("expectedConflict");

  QTest::newRow("new local")
      << "-" << "-" << "a" << "-" << int(SyncAction::UploadNew) << int(SyncAction::NoConflict);
  QTest::newRow("new remote")
      << "-" << "-" << "-" << "r1" << int(SyncAction::DownloadNew) << int(SyncAction::NoConflict);
  QTest::newRow("both created")
      << "-" << "-" << "a" << "r1" << int(SyncAction::Conflict) << int(SyncAction::BothCreated);
  QTest::newRow("unchanged")
      << "a" << "r1" << "a" << "r1" << -1 << int(SyncAction::NoConflict);
  QTest::newRow("local edit")
      << "a" << "r1" << "b" << "r1" << int(SyncAction::UpdateRemote) << int(SyncAction::NoConflict);
  QTest::newRow("remote edit")
      << "a" << "r1" << "a" << "r2" << int(SyncAction::DownloadUpdate) << int(SyncAction::NoConflict);
  QTest::newRow("both edited")
      << "a" << "r1" << "b" << "r2" << int(SyncAction::Conflict) << int(SyncAction::BothChanged);
  QTest::newRow("local delete")
      << "a" << "r1" << "-" << "r1" << int(SyncAction::DeleteRemote) << int(SyncAction::NoConflict);
  QTest::newRow("remote delete")
      << "a" << "r1" << "a" << "-" << int(SyncAction::DeleteLocal) << int(SyncAction::NoConflict);
  QTest::newRow("local delete vs remote edit")
      << "a" << "r1" << "-" << "r2" << int(SyncAction::Conflict) << int(SyncAction::LocalDeletedRemoteChanged);
  QTest::newRow("local edit vs remote delete")
      << "a" << "r1" << "b" << "-" << int(SyncAction::Conflict) << int(SyncAction::LocalChangedRemoteDeleted);
  QTest::newRow("deleted both sides")
      << "a" << "r1" << "-" << "-" << int(SyncAction::DropManifestEntry) << int(SyncAction::NoConflict);
}

void CloudSyncPlanTest::matrix()
{
  QFETCH(QString, manifestContents);
  QFETCH(QString, manifestRevision);
  QFETCH(QString, localContents);
  QFETCH(QString, remoteRevision);
  QFETCH(int, expectedKind);
  QFETCH(int, expectedConflict);

  const QString path = QStringLiteral("package.mo");
  CloudManifest manifest;
  // The whole matrix assumes a working copy we trust; the incomplete case has
  // its own test below.
  manifest.workingCopyComplete = true;
  QMap<QString, LocalEntry> local;
  QMap<QString, RemoteEntry> remote;

  if (manifestContents != QLatin1String("-")) {
    addManifest(&manifest, path, manifestContents.toUtf8(), manifestRevision);
  }
  if (localContents != QLatin1String("-")) {
    addLocal(&local, path, localContents.toUtf8());
  }
  if (remoteRevision != QLatin1String("-")) {
    addRemote(&remote, path, remoteRevision);
  }

  const SyncPlan plan = planSync(manifest, local, remote);

  if (expectedKind < 0) {
    QVERIFY2(!hasActionFor(plan, path), "a file that did not move must produce no action");
    return;
  }
  QVERIFY2(hasActionFor(plan, path), "expected an action for the file");
  const SyncAction action = actionFor(plan, path);
  QCOMPARE(int(action.kind), expectedKind);
  QCOMPARE(int(action.conflict), expectedConflict);
}

/*!
 * \brief The regression this whole design exists for.
 * On the web target the working copy lives in memory. If a restore fails, every
 * file looks locally deleted - and a push must not turn that into a wiped
 * package.
 */
void CloudSyncPlanTest::incompleteWorkingCopyNeverDeletes()
{
  CloudManifest manifest;
  manifest.workingCopyComplete = false;
  QMap<QString, RemoteEntry> remote;
  for (int i = 0; i < 20; ++i) {
    const QString path = QStringLiteral("Sub%1.mo").arg(i);
    addManifest(&manifest, path, "contents", QStringLiteral("r1"));
    addRemote(&remote, path, QStringLiteral("r1"));
  }

  // Nothing restored at all.
  const SyncPlan plan = planSync(manifest, QMap<QString, LocalEntry>(), remote);
  QCOMPARE(plan.count(SyncAction::DeleteRemote), 0);

  // Nothing is deleted - and every missing file is fetched back instead. Skipping
  // them left the working copy permanently empty, which on the web target is its
  // state after every reload.
  QCOMPARE(plan.count(SyncAction::DownloadNew), 20);

  // And the same tree with the flag set does propagate the deletions, so the
  // test above is not passing for the wrong reason.
  manifest.workingCopyComplete = true;
  const SyncPlan trusted = planSync(manifest, QMap<QString, LocalEntry>(), remote);
  QCOMPARE(trusted.count(SyncAction::DeleteRemote), 20);
  QCOMPARE(trusted.count(SyncAction::DownloadNew), 0);
}

/*!
 * \brief A manifest never carries the completeness flag across a restart.
 * It is written to browser storage while the working copy lives in memory, so a
 * stored "complete" would license deleting everything the copy no longer holds.
 */
void CloudSyncPlanTest::completenessIsNotPersisted()
{
  QTemporaryDir directory;
  QVERIFY(directory.isValid());
  const QString path = directory.filePath(QStringLiteral("manifest.json"));

  CloudManifest written;
  written.workingCopyComplete = true;
  addManifest(&written, QStringLiteral("package.mo"), "a", QStringLiteral("r1"));
  QVERIFY(written.save(path));

  CloudManifest read;
  QVERIFY(read.load(path));
  QCOMPARE(read.workingCopyComplete, false);
}

void CloudSyncPlanTest::deletionThreshold()
{
  CloudManifest manifest;
  manifest.workingCopyComplete = true;
  QMap<QString, LocalEntry> local;
  QMap<QString, RemoteEntry> remote;
  for (int i = 0; i < 20; ++i) {
    const QString path = QStringLiteral("Sub%1.mo").arg(i);
    addManifest(&manifest, path, "contents", QStringLiteral("r1"));
    addRemote(&remote, path, QStringLiteral("r1"));
    // Keep most of them, delete six.
    if (i >= 6) {
      addLocal(&local, path, "contents");
    }
  }
  const SyncPlan plan = planSync(manifest, local, remote);
  QCOMPARE(plan.count(SyncAction::DeleteRemote), 6);
  QVERIFY2(plan.needsDeletionConfirmation(manifest.fileCount()), "six deletions must be confirmed");

  // Removing a single file out of twenty is ordinary editing.
  QMap<QString, LocalEntry> almostAll = local;
  for (int i = 1; i < 6; ++i) {
    addLocal(&almostAll, QStringLiteral("Sub%1.mo").arg(i), "contents");
  }
  const SyncPlan small = planSync(manifest, almostAll, remote);
  QCOMPARE(small.count(SyncAction::DeleteRemote), 1);
  QVERIFY2(!small.needsDeletionConfirmation(manifest.fileCount()), "one deletion of twenty needs no confirmation");
}

void CloudSyncPlanTest::folderRemovedOnlyWhenEmpty()
{
  CloudManifest manifest;
  manifest.workingCopyComplete = true;
  addManifest(&manifest, QStringLiteral("Sub"), QByteArray(), QStringLiteral("r1"), true);
  addManifest(&manifest, QStringLiteral("Sub/package.mo"), "a", QStringLiteral("r1"));

  QMap<QString, RemoteEntry> remote;
  addRemote(&remote, QStringLiteral("Sub"), QStringLiteral("r1"), true);
  addRemote(&remote, QStringLiteral("Sub/package.mo"), QStringLiteral("r1"));
  // Something else appeared in the folder that we have never seen.
  addRemote(&remote, QStringLiteral("Sub/Other.mo"), QStringLiteral("r1"));

  // The whole subpackage is gone locally.
  const SyncPlan plan = planSync(manifest, QMap<QString, LocalEntry>(), remote);
  QCOMPARE(actionFor(plan, QStringLiteral("Sub/package.mo")).kind, SyncAction::DeleteRemote);
  QCOMPARE(actionFor(plan, QStringLiteral("Sub/Other.mo")).kind, SyncAction::DownloadNew);
  QVERIFY2(!hasAction(plan, QStringLiteral("Sub"), SyncAction::DeleteRemote),
           "a folder still holding a file must not be removed");
  QVERIFY(plan.skipped.contains(QStringLiteral("Sub")));

  // Without the stranger, the now-empty folder goes too.
  QMap<QString, RemoteEntry> emptied = remote;
  emptied.remove(QStringLiteral("Sub/Other.mo"));
  const SyncPlan cleared = planSync(manifest, QMap<QString, LocalEntry>(), emptied);
  QVERIFY(hasAction(cleared, QStringLiteral("Sub"), SyncAction::DeleteRemote));
  // And it must not also be proposed for local recreation - the two would cancel.
  QVERIFY2(!hasAction(cleared, QStringLiteral("Sub"), SyncAction::CreateLocalFolder),
           "a folder being deleted remotely must not also be created locally");
}

void CloudSyncPlanTest::manifestRoundTrip()
{
  QTemporaryDir directory;
  QVERIFY(directory.isValid());
  const QString path = directory.filePath(QStringLiteral("manifest.json"));

  CloudManifest written;
  written.remoteRootId = QStringLiteral("root-id");
  written.deltaToken = QStringLiteral("token-1");
  written.workingCopyComplete = true;
  addManifest(&written, QStringLiteral("package.mo"), "a", QStringLiteral("r1"));
  addManifest(&written, QStringLiteral("Sub"), QByteArray(), QStringLiteral("r1"), true);
  QVERIFY(written.save(path));

  CloudManifest read;
  QVERIFY(read.load(path));
  QCOMPARE(read.remoteRootId, written.remoteRootId);
  QCOMPARE(read.deltaToken, written.deltaToken);
  // Deliberately not carried across: see completenessIsNotPersisted().
  QCOMPARE(read.workingCopyComplete, false);
  QCOMPARE(read.entries.size(), 2);
  QCOMPARE(read.entries.value(QStringLiteral("package.mo")).contentHash,
           written.entries.value(QStringLiteral("package.mo")).contentHash);
  QCOMPARE(read.entries.value(QStringLiteral("Sub")).isFolder, true);
  QCOMPARE(read.fileCount(), 1);
}

void CloudSyncPlanTest::unusableRemoteNames()
{
  QString reason;
  QVERIFY(isUsableLocalName(QStringLiteral("Package.mo"), &reason));
  QVERIFY(!isUsableLocalName(QString(), &reason));
  QVERIFY(!isUsableLocalName(QStringLiteral(".."), &reason));
  QVERIFY(!isUsableLocalName(QStringLiteral("a/b.mo"), &reason));
#if defined(Q_OS_WIN)
  QVERIFY(!isUsableLocalName(QStringLiteral("CON.mo"), &reason));
  QVERIFY(!isUsableLocalName(QStringLiteral("name."), &reason));
  QVERIFY(!isUsableLocalName(QStringLiteral("a:b.mo"), &reason));
#endif
}

QTEST_APPLESS_MAIN(CloudSyncPlanTest)

#include "CloudSyncPlanTest.moc"
