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

// The sync engine driven end to end against a provider that lives in memory:
// what the planner decides is one thing, carrying it out in an order that cannot
// lose data is another. No network, and the working copy is a temporary
// directory.

#include "Cloud/CloudManifest.h"
#include "Cloud/CloudMount.h"
#include "Cloud/CloudProvider.h"
#include "Cloud/CloudSyncEngine.h"

#include <QCoreApplication>
#include <QCryptographicHash>
#include <QDir>
#include <QElapsedTimer>
#include <QFile>
#include <QSettings>
#include <QTemporaryDir>
#include <QtTest>

namespace {

struct FakeItem
{
  QString id;
  QString name;
  QString parentId;
  bool isFolder = false;
  QByteArray contents;
  int revision = 1;
  bool trashed = false;
};

/*!
 * \brief A cloud service in a QMap.
 *
 * Replies finish through the same queued emission the real ones use, so the
 * engine is exercised over the event loop exactly as it is in the application.
 */
class FakeProvider : public CloudProvider
{
  Q_OBJECT
public:
  FakeProvider() : CloudProvider(0, 0, 0) {}

  QMap<QString, FakeItem> items;
  int nextId = 1;
  //! Fail the nth request of this kind, to see what an interruption leaves behind.
  QString failVerb;
  int failAfter = -1;

  QString add(const QString &name, const QString &parentId, const QByteArray &contents, bool isFolder = false)
  {
    FakeItem item;
    item.id = QStringLiteral("item-%1").arg(nextId++);
    item.name = name;
    item.parentId = parentId;
    item.contents = contents;
    item.isFolder = isFolder;
    items.insert(item.id, item);
    return item.id;
  }

  QString idFor(const QString &name) const
  {
    for (const FakeItem &item : items) {
      if (item.name == name && !item.trashed) {
        return item.id;
      }
    }
    return QString();
  }

  CloudProviderKind kind() const override { return CloudProviderKind::GoogleDrive; }

  CloudReply *userInfo() override { return done(CloudReply::pending(this)); }
  CloudReply *appRootFolder() override { return done(CloudReply::pending(this)); }

  CloudReply *listFolder(const QString &folderId) override
  {
    CloudReply *pReply = CloudReply::pending(this);
    QList<RemoteItem> found;
    for (const FakeItem &item : std::as_const(items)) {
      if (item.parentId != folderId || item.trashed) {
        continue;
      }
      found << toRemote(item);
    }
    pReply->setItems(found);
    return done(pReply);
  }

  CloudReply *metadata(const QString &itemId) override
  {
    CloudReply *pReply = CloudReply::pending(this);
    pReply->setItem(toRemote(items.value(itemId)));
    return done(pReply);
  }

  CloudReply *download(const QString &fileId) override
  {
    CloudReply *pReply = CloudReply::pending(this);
    if (!items.contains(fileId)) {
      return fail(pReply, CloudError::NotFound, QStringLiteral("no such file"));
    }
    pReply->setData(items.value(fileId).contents);
    return done(pReply);
  }

  CloudReply *createFolder(const QString &parentId, const QString &name) override
  {
    CloudReply *pReply = CloudReply::pending(this);
    if (shouldFail(QStringLiteral("createFolder"))) {
      return fail(pReply, CloudError::Provider, QStringLiteral("refused"));
    }
    pReply->setItem(toRemote(items.value(add(name, parentId, QByteArray(), true))));
    return done(pReply);
  }

  CloudReply *uploadNew(const QString &parentId, const QString &name, const QByteArray &contents) override
  {
    CloudReply *pReply = CloudReply::pending(this);
    if (shouldFail(QStringLiteral("upload"))) {
      return fail(pReply, CloudError::Provider, QStringLiteral("refused"));
    }
    pReply->setItem(toRemote(items.value(add(name, parentId, contents))));
    return done(pReply);
  }

  CloudReply *uploadUpdate(const QString &fileId, const QByteArray &contents,
                           const QString &expectedRevision) override
  {
    CloudReply *pReply = CloudReply::pending(this);
    if (shouldFail(QStringLiteral("upload"))) {
      return fail(pReply, CloudError::Provider, QStringLiteral("refused"));
    }
    FakeItem item = items.value(fileId);
    if (!expectedRevision.isEmpty() && expectedRevision != QString::number(item.revision)) {
      return fail(pReply, CloudError::Conflict, QStringLiteral("revision moved on"));
    }
    item.contents = contents;
    item.revision += 1;
    items.insert(fileId, item);
    pReply->setItem(toRemote(item));
    return done(pReply);
  }

  CloudReply *trashItem(const QString &itemId, const QString &expectedRevision) override
  {
    CloudReply *pReply = CloudReply::pending(this);
    if (shouldFail(QStringLiteral("trash"))) {
      return fail(pReply, CloudError::Provider, QStringLiteral("refused"));
    }
    FakeItem item = items.value(itemId);
    if (!expectedRevision.isEmpty() && expectedRevision != QString::number(item.revision)) {
      return fail(pReply, CloudError::Conflict, QStringLiteral("revision moved on"));
    }
    item.trashed = true;
    items.insert(itemId, item);
    return done(pReply);
  }

  CloudReply *currentDeltaToken(const QString &) override
  {
    CloudReply *pReply = CloudReply::pending(this);
    pReply->setDeltaToken(QStringLiteral("token"));
    return done(pReply);
  }

  CloudReply *changes(const QString &, const QString &) override { return done(CloudReply::pending(this)); }

private:
  RemoteItem toRemote(const FakeItem &item) const
  {
    RemoteItem remote;
    remote.id = item.id;
    remote.name = item.name;
    remote.isFolder = item.isFolder;
    remote.size = item.contents.size();
    remote.revision = QString::number(item.revision);
    remote.contentHash = QString::fromLatin1(
        QCryptographicHash::hash(item.contents, QCryptographicHash::Md5).toHex());
    return remote;
  }

  bool shouldFail(const QString &verb)
  {
    if (verb != failVerb || failAfter < 0) {
      return false;
    }
    return failAfter-- == 0;
  }

  CloudReply *done(CloudReply *pReply)
  {
    pReply->finish(CloudError());
    return pReply;
  }

  CloudReply *fail(CloudReply *pReply, CloudError::Code code, const QString &message)
  {
    pReply->finish(CloudError(code, message));
    return pReply;
  }
};

QByteArray hashOf(const QByteArray &contents)
{
  return QCryptographicHash::hash(contents, QCryptographicHash::Sha256);
}

void writeFile(const QString &path, const QByteArray &contents)
{
  QDir().mkpath(QFileInfo(path).absolutePath());
  QFile file(path);
  QVERIFY2(file.open(QIODevice::WriteOnly | QIODevice::Truncate), qPrintable(path));
  file.write(contents);
}

QByteArray readFile(const QString &path)
{
  QFile file(path);
  if (!file.open(QIODevice::ReadOnly)) {
    return QByteArray();
  }
  return file.readAll();
}

} // namespace

class CloudSyncEngineTest : public QObject
{
  Q_OBJECT
private slots:
  void initTestCase();
  void init();
  void cleanup();

  void uploadsAWorkingCopy();
  void downloadsIntoAnEmptyWorkingCopy();
  void conflictKeepsBothVersions();
  void conflictTakesTheRemoteVersion();
  void cancellingAConflictEndsTheRun();
  void keepingALocalDeletionRemovesTheRemote();
  void aDeletedFileIsRemovedRemotely();
  void declinedDeletionsChangeNothing();
  void aWipedWorkingCopyIsRestoredNotPropagated();
  void anInterruptedUploadLeavesNothingDeleted();

private:
  //! One run of the engine, with the answers it may ask for prepared in advance.
  CloudError run(CloudSyncEngine *pEngine, const QHash<QString, int> &resolutions = QHash<QString, int>(),
                 bool confirmDeletions = true);
  CloudSyncEngine *newEngine();

  QTemporaryDir *mpTempDir = 0;
  FakeProvider *mpProvider = 0;
  CloudMount mMount;
  QString mRootId;
  QList<SyncAction> mLastConflicts;
  QList<SyncAction> mLastDeletions;
  bool mCancelOnConflict = false;
};

void CloudSyncEngineTest::initTestCase()
{
  // Keep the manifests out of the real settings directory.
  static QTemporaryDir settingsDir;
  QSettings::setPath(QSettings::IniFormat, QSettings::UserScope, settingsDir.path());
}

void CloudSyncEngineTest::init()
{
  mpTempDir = new QTemporaryDir;
  mpProvider = new FakeProvider;
  mRootId = QStringLiteral("root");
  mMount = CloudMount();
  mMount.mountId = QStringLiteral("test");
  mMount.accountKey = QStringLiteral("fake:test");
  mMount.remoteRootId = mRootId;
  mMount.remoteName = QStringLiteral("Package");
  mMount.localRoot = mpTempDir->path() + QStringLiteral("/work");
  QDir().mkpath(mMount.localRoot);
  QFile::remove(mMount.manifestPath());
  mLastConflicts.clear();
  mLastDeletions.clear();
  mCancelOnConflict = false;
}

void CloudSyncEngineTest::cleanup()
{
  QFile::remove(mMount.manifestPath());
  delete mpProvider;
  mpProvider = 0;
  delete mpTempDir;
  mpTempDir = 0;
}

CloudSyncEngine *CloudSyncEngineTest::newEngine()
{
  return new CloudSyncEngine(mMount, mpProvider, this);
}

CloudError CloudSyncEngineTest::run(CloudSyncEngine *pEngine, const QHash<QString, int> &resolutions,
                                    bool confirmDeletions)
{
  CloudError result;
  bool finished = false;
  connect(pEngine, &CloudSyncEngine::finished, this, [&result, &finished](const CloudError &error) {
    result = error;
    finished = true;
  });
  connect(pEngine, &CloudSyncEngine::conflictsDetected, this,
          [this, pEngine, resolutions](const QList<SyncAction> &conflicts) {
    mLastConflicts = conflicts;
    if (mCancelOnConflict) {
      pEngine->cancel();
      return;
    }
    QHash<QString, int> answers;
    for (const SyncAction &conflict : conflicts) {
      answers.insert(conflict.relativePath, resolutions.value(conflict.relativePath, CloudSyncEngine::KeepBoth));
    }
    pEngine->applyResolutions(answers);
  });
  connect(pEngine, &CloudSyncEngine::deletionsNeedConfirmation, this,
          [this, pEngine, confirmDeletions](const QList<SyncAction> &deletions) {
    mLastDeletions = deletions;
    pEngine->confirmDeletions(confirmDeletions);
  });
  pEngine->start();
  QElapsedTimer timer;
  timer.start();
  while (!finished && timer.elapsed() < 5000) {
    QCoreApplication::processEvents(QEventLoop::AllEvents, 20);
  }
  if (!finished) {
    result = CloudError(CloudError::Network, QStringLiteral("the engine never finished"));
  }
  pEngine->deleteLater();
  return result;
}

void CloudSyncEngineTest::uploadsAWorkingCopy()
{
  writeFile(mMount.localRoot + QStringLiteral("/package.mo"), "package P end P;");
  writeFile(mMount.localRoot + QStringLiteral("/Sub/package.mo"), "package Sub end Sub;");

  const CloudError error = run(newEngine());
  QVERIFY(!error.isError());
  QVERIFY(!mpProvider->idFor(QStringLiteral("Sub")).isEmpty());
  QCOMPARE(mpProvider->items.value(mpProvider->idFor(QStringLiteral("Sub"))).isFolder, true);

  CloudManifest manifest;
  QVERIFY(manifest.load(mMount.manifestPath()));
  QCOMPARE(manifest.fileCount(), 2);
}

void CloudSyncEngineTest::downloadsIntoAnEmptyWorkingCopy()
{
  const QString folder = mpProvider->add(QStringLiteral("Sub"), mRootId, QByteArray(), true);
  mpProvider->add(QStringLiteral("package.mo"), mRootId, "package P end P;");
  mpProvider->add(QStringLiteral("M.mo"), folder, "model M end M;");

  const CloudError error = run(newEngine());
  QVERIFY(!error.isError());
  QCOMPARE(readFile(mMount.localRoot + QStringLiteral("/package.mo")), QByteArray("package P end P;"));
  QCOMPARE(readFile(mMount.localRoot + QStringLiteral("/Sub/M.mo")), QByteArray("model M end M;"));
}

void CloudSyncEngineTest::conflictKeepsBothVersions()
{
  const QString fileId = mpProvider->add(QStringLiteral("M.mo"), mRootId, "model M end M;");
  writeFile(mMount.localRoot + QStringLiteral("/M.mo"), "model M end M;");
  QVERIFY(!run(newEngine()).isError());

  // Both sides move away from the synced state.
  writeFile(mMount.localRoot + QStringLiteral("/M.mo"), "model M // mine\nend M;");
  FakeItem remote = mpProvider->items.value(fileId);
  remote.contents = "model M // theirs\nend M;";
  remote.revision += 1;
  mpProvider->items.insert(fileId, remote);

  QHash<QString, int> answers;
  answers.insert(QStringLiteral("M.mo"), CloudSyncEngine::KeepBoth);
  QVERIFY(!run(newEngine(), answers).isError());

  QCOMPARE(mLastConflicts.size(), 1);
  QCOMPARE(mLastConflicts.first().conflict, SyncAction::BothChanged);
  // Theirs at the original name, mine beside it, and mine is up there too.
  QCOMPARE(readFile(mMount.localRoot + QStringLiteral("/M.mo")), QByteArray("model M // theirs\nend M;"));
  const QStringList copies = QDir(mMount.localRoot).entryList(QStringList() << QStringLiteral("M.conflict-*.mo"));
  QCOMPARE(copies.size(), 1);
  QCOMPARE(readFile(mMount.localRoot + QLatin1Char('/') + copies.first()), QByteArray("model M // mine\nend M;"));
  QVERIFY(!mpProvider->idFor(copies.first()).isEmpty());
}

void CloudSyncEngineTest::conflictTakesTheRemoteVersion()
{
  const QString fileId = mpProvider->add(QStringLiteral("M.mo"), mRootId, "model M end M;");
  writeFile(mMount.localRoot + QStringLiteral("/M.mo"), "model M end M;");
  QVERIFY(!run(newEngine()).isError());

  writeFile(mMount.localRoot + QStringLiteral("/M.mo"), "model M // mine\nend M;");
  FakeItem remote = mpProvider->items.value(fileId);
  remote.contents = "model M // theirs\nend M;";
  remote.revision += 1;
  mpProvider->items.insert(fileId, remote);

  QHash<QString, int> answers;
  answers.insert(QStringLiteral("M.mo"), CloudSyncEngine::TakeRemote);
  QVERIFY(!run(newEngine(), answers).isError());

  QCOMPARE(readFile(mMount.localRoot + QStringLiteral("/M.mo")), QByteArray("model M // theirs\nend M;"));
  QCOMPARE(QDir(mMount.localRoot).entryList(QStringList() << QStringLiteral("M.conflict-*.mo")).size(), 0);
}

void CloudSyncEngineTest::cancellingAConflictEndsTheRun()
{
  const QString fileId = mpProvider->add(QStringLiteral("M.mo"), mRootId, "model M end M;");
  writeFile(mMount.localRoot + QStringLiteral("/M.mo"), "model M end M;");
  QVERIFY(!run(newEngine()).isError());

  writeFile(mMount.localRoot + QStringLiteral("/M.mo"), "model M // mine\nend M;");
  FakeItem remote = mpProvider->items.value(fileId);
  remote.contents = "model M // theirs\nend M;";
  remote.revision += 1;
  mpProvider->items.insert(fileId, remote);

  // Nothing is in flight while the dialog is up, so the engine has to end the run
  // itself; otherwise a dismissed dialog leaves it waiting forever.
  mCancelOnConflict = true;
  const CloudError error = run(newEngine());
  QCOMPARE(error.code, CloudError::Cancelled);
  QCOMPARE(readFile(mMount.localRoot + QStringLiteral("/M.mo")), QByteArray("model M // mine\nend M;"));
  QCOMPARE(mpProvider->items.value(fileId).contents, QByteArray("model M // theirs\nend M;"));
}

void CloudSyncEngineTest::keepingALocalDeletionRemovesTheRemote()
{
  const QString fileId = mpProvider->add(QStringLiteral("M.mo"), mRootId, "model M end M;");
  mpProvider->add(QStringLiteral("package.mo"), mRootId, "package P end P;");
  writeFile(mMount.localRoot + QStringLiteral("/M.mo"), "model M end M;");
  writeFile(mMount.localRoot + QStringLiteral("/package.mo"), "package P end P;");
  QVERIFY(!run(newEngine()).isError());

  // Deleted here, changed there: keeping "mine" has to mean removing theirs, not
  // quietly doing nothing.
  QVERIFY(QFile::remove(mMount.localRoot + QStringLiteral("/M.mo")));
  FakeItem remote = mpProvider->items.value(fileId);
  remote.contents = "model M // theirs\nend M;";
  remote.revision += 1;
  mpProvider->items.insert(fileId, remote);

  QHash<QString, int> answers;
  answers.insert(QStringLiteral("M.mo"), CloudSyncEngine::KeepLocal);
  QVERIFY(!run(newEngine(), answers).isError());

  QCOMPARE(mLastConflicts.size(), 1);
  QCOMPARE(mLastConflicts.first().conflict, SyncAction::LocalDeletedRemoteChanged);
  QCOMPARE(mpProvider->items.value(fileId).trashed, true);
  QVERIFY(!QFile::exists(mMount.localRoot + QStringLiteral("/M.mo")));
}

void CloudSyncEngineTest::aDeletedFileIsRemovedRemotely()
{
  const QString removedId = mpProvider->add(QStringLiteral("M0.mo"), mRootId, "model M end M;");
  QStringList kept;
  writeFile(mMount.localRoot + QStringLiteral("/M0.mo"), "model M end M;");
  for (int i = 1; i < 10; ++i) {
    const QString name = QStringLiteral("M%1.mo").arg(i);
    kept << mpProvider->add(name, mRootId, "model M end M;");
    writeFile(mMount.localRoot + QLatin1Char('/') + name, "model M end M;");
  }
  QVERIFY(!run(newEngine()).isError());

  // One of ten: a routine deletion, not worth an interruption.
  QVERIFY(QFile::remove(mMount.localRoot + QStringLiteral("/M0.mo")));
  QVERIFY(!run(newEngine()).isError());
  QVERIFY(mLastDeletions.isEmpty());
  QCOMPARE(mpProvider->items.value(removedId).trashed, true);
  for (const QString &id : std::as_const(kept)) {
    QCOMPARE(mpProvider->items.value(id).trashed, false);
  }
}

void CloudSyncEngineTest::declinedDeletionsChangeNothing()
{
  QStringList ids;
  for (int i = 0; i < 10; ++i) {
    const QString name = QStringLiteral("M%1.mo").arg(i);
    ids << mpProvider->add(name, mRootId, "model M end M;");
    writeFile(mMount.localRoot + QLatin1Char('/') + name, "model M end M;");
  }
  QVERIFY(!run(newEngine()).isError());

  // Eight of ten is past both thresholds, so it has to be confirmed.
  for (int i = 0; i < 8; ++i) {
    QVERIFY(QFile::remove(mMount.localRoot + QStringLiteral("/M%1.mo").arg(i)));
  }
  const CloudError error = run(newEngine(), QHash<QString, int>(), false);
  QCOMPARE(error.code, CloudError::Cancelled);
  QCOMPARE(mLastDeletions.size(), 8);
  for (const QString &id : std::as_const(ids)) {
    QCOMPARE(mpProvider->items.value(id).trashed, false);
  }
}

void CloudSyncEngineTest::aWipedWorkingCopyIsRestoredNotPropagated()
{
  for (int i = 0; i < 10; ++i) {
    const QString name = QStringLiteral("M%1.mo").arg(i);
    mpProvider->add(name, mRootId, "model M end M;");
    writeFile(mMount.localRoot + QLatin1Char('/') + name, "model M end M;");
  }
  QVERIFY(!run(newEngine()).isError());

  // What a browser reload leaves behind. Nothing about it says "deleted".
  QVERIFY(QDir(mMount.localRoot).removeRecursively());
  QDir().mkpath(mMount.localRoot);

  QVERIFY(!run(newEngine()).isError());
  QVERIFY(mLastDeletions.isEmpty());
  for (const FakeItem &item : std::as_const(mpProvider->items)) {
    QCOMPARE(item.trashed, false);
  }
  QCOMPARE(QDir(mMount.localRoot).entryList(QDir::Files).size(), 10);
}

void CloudSyncEngineTest::anInterruptedUploadLeavesNothingDeleted()
{
  writeFile(mMount.localRoot + QStringLiteral("/A.mo"), "model A end A;");
  writeFile(mMount.localRoot + QStringLiteral("/B.mo"), "model B end B;");
  mpProvider->failVerb = QStringLiteral("upload");
  mpProvider->failAfter = 1;

  QVERIFY(run(newEngine()).isError());
  // What did get up there is on record, so the next run updates rather than
  // duplicating it, and nothing was removed on either side.
  CloudManifest manifest;
  QVERIFY(manifest.load(mMount.manifestPath()));
  QCOMPARE(manifest.fileCount(), 1);
  QVERIFY(QFile::exists(mMount.localRoot + QStringLiteral("/A.mo")));
  QVERIFY(QFile::exists(mMount.localRoot + QStringLiteral("/B.mo")));

  mpProvider->failAfter = -1;
  QVERIFY(!run(newEngine()).isError());
  QCOMPARE(mpProvider->items.size(), 2);
}

QTEST_GUILESS_MAIN(CloudSyncEngineTest)

#include "CloudSyncEngineTest.moc"
