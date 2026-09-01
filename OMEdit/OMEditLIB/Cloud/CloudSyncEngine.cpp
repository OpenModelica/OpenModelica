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

#include "Cloud/CloudSyncEngine.h"
#include "Cloud/CloudProvider.h"
#include "Cloud/CloudTypes.h"

#include <QCryptographicHash>
#include <QDateTime>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>

namespace {

//! Rank of an action in the execution order. See the class comment: uploads must
//! be recorded before any deletion is issued.
int phaseOf(const SyncAction &action)
{
  switch (action.kind) {
    case SyncAction::CreateLocalFolder:  return 0;
    case SyncAction::DownloadNew:
    case SyncAction::DownloadUpdate:     return 1;
    case SyncAction::CreateRemoteFolder: return 2;
    case SyncAction::UploadNew:
    case SyncAction::UpdateRemote:       return 3;
    case SyncAction::AdoptIdentical:     return 4;
    case SyncAction::DeleteRemote:       return 5;
    case SyncAction::DeleteLocal:        return 6;
    case SyncAction::DropManifestEntry:  return 7;
    case SyncAction::Conflict:           return 8;
  }
  return 8;
}

QByteArray hashOf(const QByteArray &contents)
{
  return QCryptographicHash::hash(contents, QCryptographicHash::Sha256);
}

//! Anything whose path has a dot-component: .git and friends are not part of a
//! Modelica package and must not be pushed to somebody's Drive.
bool isHiddenPath(const QString &relativePath)
{
  const QStringList components = relativePath.split(QLatin1Char('/'), Qt::SkipEmptyParts);
  for (const QString &component : components) {
    if (component.startsWith(QLatin1Char('.'))) {
      return true;
    }
  }
  return false;
}

QString conflictCopyName(const QString &relativePath)
{
  const QString stamp = QDateTime::currentDateTime().toString(QStringLiteral("yyyy-MM-dd-hhmmss"));
  const int dot = relativePath.lastIndexOf(QLatin1Char('.'));
  const int slash = relativePath.lastIndexOf(QLatin1Char('/'));
  if (dot > slash) {
    return QStringLiteral("%1.conflict-%2%3").arg(relativePath.left(dot), stamp, relativePath.mid(dot));
  }
  return QStringLiteral("%1.conflict-%2").arg(relativePath, stamp);
}

} // namespace

CloudSyncEngine::CloudSyncEngine(const CloudMount &mount, CloudProvider *pProvider, QObject *pParent)
  : QObject(pParent), mMount(mount), mpProvider(pProvider)
{
}

QString CloudSyncEngine::absolutePath(const QString &relativePath) const
{
  return mMount.localRoot + QLatin1Char('/') + relativePath;
}

QString CloudSyncEngine::parentRemoteId(const QString &relativePath) const
{
  const int slash = relativePath.lastIndexOf(QLatin1Char('/'));
  if (slash < 0) {
    return mMount.remoteRootId;
  }
  return mRemoteIdByPath.value(relativePath.left(slash), mMount.remoteRootId);
}

void CloudSyncEngine::start()
{
  mManifest.load(mMount.manifestPath());
  mManifest.remoteRootId = mMount.remoteRootId;
  mLocal.clear();
  mRemote.clear();
  mRemoteIdByPath.clear();
  mSkipped.clear();
  mCancelled = false;
  mManifestSavedBeforeDeletions = false;
  mDone = 0;

  scanLocal();
  // A working copy that has lost every file the manifest lists was not restored;
  // one missing some of them has had files deleted. Only when nothing is left are
  // the two indistinguishable, and there the safe reading is "not restored".
  int expected = 0;
  int present = 0;
  for (auto it = mManifest.entries.constBegin(); it != mManifest.entries.constEnd(); ++it) {
    if (it.value().isFolder) {
      continue;
    }
    ++expected;
    if (mLocal.contains(it.key())) {
      ++present;
    }
  }
  mManifest.workingCopyComplete = expected == 0 || present > 0;
  cloudLog(QStringLiteral("sync %1: %2 local entries under %3, working copy complete: %4")
               .arg(mMount.remoteName).arg(mLocal.size()).arg(mMount.localRoot)
               .arg(mManifest.workingCopyComplete ? QStringLiteral("yes") : QStringLiteral("no")));

  mRemoteIdByPath.insert(QString(), mMount.remoteRootId);
  mPendingListings = 0;
  mListingFailed = false;
  emit progress(0, 0, tr("Looking at %1...").arg(mMount.remoteName));
  listRemoteFrom(mMount.remoteRootId, QString());
}

void CloudSyncEngine::scanLocal()
{
  scanLocalInto(QDir::cleanPath(mMount.localRoot), QString());
}

/*!
 * \brief Walk the working copy one directory at a time. QDirIterator is not an
 * option: it enumerates nothing through the worker-VFS QAbstractFileEngine.
 */
void CloudSyncEngine::scanLocalInto(const QString &directory, const QString &prefix)
{
  const QStringList names = cloudListDirectory(directory);
  for (const QString &raw : names) {
    const bool isFolder = raw.endsWith(QLatin1Char('/'));
    const QString name = isFolder ? raw.left(raw.size() - 1) : raw;
    if (name.isEmpty()) {
      continue;
    }
    const QString relativePath = prefix.isEmpty() ? name : prefix + QLatin1Char('/') + name;
    if (isHiddenPath(relativePath)) {
      continue;
    }
    LocalEntry entry;
    entry.relativePath = relativePath;
    entry.isFolder = isFolder;
    if (isFolder) {
      mLocal.insert(relativePath, entry);
      scanLocalInto(directory + QLatin1Char('/') + name, relativePath);
      continue;
    }
    QFile file(directory + QLatin1Char('/') + name);
    if (!file.open(QIODevice::ReadOnly)) {
      continue;
    }
    const QByteArray contents = file.readAll();
    entry.contentHash = hashOf(contents);
    entry.size = contents.size();
    // Drive's MD5 is what lets both sides changing to the same bytes be
    // recognised instead of reported as a conflict.
    if (mpProvider && mpProvider->kind() == CloudProviderKind::GoogleDrive) {
      entry.providerHash = QCryptographicHash::hash(contents, QCryptographicHash::Md5).toHex();
    }
    mLocal.insert(relativePath, entry);
  }
}

void CloudSyncEngine::listRemoteFrom(const QString &folderId, const QString &prefix)
{
  ++mPendingListings;
  CloudReply *pReply = mpProvider->listFolder(folderId);
  connect(pReply, &CloudReply::finished, this, [this, pReply, prefix]() {
    --mPendingListings;
    if (pReply->error().isError()) {
      if (!mListingFailed) {
        mListingFailed = true;
        mListingError = pReply->error();
      }
      remoteListingDone();
      return;
    }
    // Drive allows two children of one folder to share a name; a path-based sync
    // cannot choose between them, so both are reported and neither is used.
    QHash<QString, int> nameCounts;
    const QList<RemoteItem> items = pReply->items();
    for (const RemoteItem &item : items) {
      nameCounts[item.name] += 1;
    }
    for (const RemoteItem &item : items) {
      QString reason;
      if (nameCounts.value(item.name) > 1) {
        mSkipped << tr("%1: the folder holds more than one entry with this name").arg(item.name);
        continue;
      }
      if (!isUsableLocalName(item.name, &reason)) {
        mSkipped << tr("%1: %2").arg(item.name, reason);
        continue;
      }
      const QString relativePath = prefix.isEmpty() ? item.name : prefix + QLatin1Char('/') + item.name;
      RemoteEntry entry;
      entry.relativePath = relativePath;
      entry.remoteId = item.id;
      entry.remoteRevision = item.revision;
      entry.contentHash = item.contentHash;
      entry.size = item.size;
      entry.isFolder = item.isFolder;
      mRemote.insert(relativePath, entry);
      mRemoteIdByPath.insert(relativePath, item.id);
      if (item.isFolder && !mCancelled) {
        listRemoteFrom(item.id, relativePath);
      }
    }
    remoteListingDone();
  });
}

void CloudSyncEngine::remoteListingDone()
{
  if (mPendingListings > 0) {
    return;
  }
  if (mListingFailed) {
    finish(mListingError);
    return;
  }
  if (mCancelled) {
    finish(CloudError(CloudError::Cancelled, tr("Cancelled.")));
    return;
  }
  if (!mSkipped.isEmpty()) {
    emit skipped(mSkipped);
  }
  planAndProceed();
}

void CloudSyncEngine::planAndProceed()
{
  mPlan = planSync(mManifest, mLocal, mRemote);

  // Fold in whatever the user chose for the conflicts reported last time round.
  if (!mResolutions.isEmpty()) {
    QList<SyncAction> resolved;
    for (SyncAction action : std::as_const(mPlan.actions)) {
      if (action.kind != SyncAction::Conflict || !mResolutions.contains(action.relativePath)) {
        resolved << action;
        continue;
      }
      const Resolution resolution = Resolution(mResolutions.value(action.relativePath));
      const bool remoteExists = mRemote.contains(action.relativePath);
      const bool localExists = mLocal.contains(action.relativePath);
      if (resolution == KeepBoth && localExists) {
        // Move ours aside so the remote version can land at the real path. Only
        // once: a re-plan must not rename the copy it made last time.
        if (!mConflictCopies.contains(action.relativePath)) {
          const QString copy = conflictCopyName(action.relativePath);
          if (QFile::rename(absolutePath(action.relativePath), absolutePath(copy))) {
            mConflictCopies.insert(action.relativePath, copy);
          }
        }
        if (mConflictCopies.contains(action.relativePath)) {
          SyncAction upload;
          upload.kind = SyncAction::UploadNew;
          upload.relativePath = mConflictCopies.value(action.relativePath);
          resolved << upload;
        }
      }
      if (resolution == KeepLocal) {
        SyncAction push;
        push.relativePath = action.relativePath;
        push.remoteId = action.remoteId;
        // Deliberately unguarded: the user has just been shown the other version
        // and asked for theirs to win.
        push.expectedRevision.clear();
        if (!localExists) {
          // "Mine" is a deletion, so keeping it means removing the remote.
          push.kind = SyncAction::DeleteRemote;
        } else {
          push.kind = remoteExists ? SyncAction::UpdateRemote : SyncAction::UploadNew;
        }
        resolved << push;
      } else {
        SyncAction take;
        take.relativePath = action.relativePath;
        take.remoteId = action.remoteId;
        take.kind = remoteExists ? SyncAction::DownloadUpdate : SyncAction::DeleteLocal;
        resolved << take;
      }
    }
    mPlan.actions = resolved;
  }

  if (mPlan.hasConflicts()) {
    emit conflictsDetected(mPlan.conflicts());
    return;
  }
  if (!mDeletionsConfirmed && mPlan.needsDeletionConfirmation(mManifest.fileCount())) {
    QList<SyncAction> deletions;
    for (const SyncAction &action : std::as_const(mPlan.actions)) {
      if (action.kind == SyncAction::DeleteRemote) {
        deletions << action;
      }
    }
    emit deletionsNeedConfirmation(deletions);
    return;
  }

  cloudLog(QStringLiteral("sync plan: %1 actions (%2 uploads, %3 downloads, %4 remote deletes), %5 remote entries")
               .arg(mPlan.actions.size())
               .arg(mPlan.count(SyncAction::UploadNew) + mPlan.count(SyncAction::UpdateRemote))
               .arg(mPlan.count(SyncAction::DownloadNew) + mPlan.count(SyncAction::DownloadUpdate))
               .arg(mPlan.count(SyncAction::DeleteRemote))
               .arg(mRemote.size()));
  mQueue = mPlan.actions;
  std::stable_sort(mQueue.begin(), mQueue.end(),
                   [](const SyncAction &a, const SyncAction &b) { return phaseOf(a) < phaseOf(b); });
  mTotal = mQueue.size();
  mDone = 0;
  if (mQueue.isEmpty()) {
    // Still worth recording: the working copy has now been seen in full.
    mManifest.workingCopyComplete = true;
    mManifest.save(mMount.manifestPath());
    finish(CloudError());
    return;
  }
  runNext();
}

void CloudSyncEngine::applyResolutions(const QHash<QString, int> &resolutions)
{
  // Merged, not replaced: a later round only carries the conflicts still open.
  for (auto it = resolutions.constBegin(); it != resolutions.constEnd(); ++it) {
    mResolutions.insert(it.key(), it.value());
  }
  planAndProceed();
}

void CloudSyncEngine::confirmDeletions(bool proceed)
{
  if (!proceed) {
    finish(CloudError(CloudError::Cancelled, tr("Synchronisation cancelled; nothing was changed.")));
    return;
  }
  mDeletionsConfirmed = true;
  planAndProceed();
}

void CloudSyncEngine::cancel()
{
  mCancelled = true;
  if (mpCurrentReply && !mpCurrentReply->isFinished()) {
    mpCurrentReply->abort();
    return;
  }
  if (mPendingListings == 0) {
    // Cancelled while waiting for an answer: nothing is in flight to unwind, so
    // the run has to end here or it never ends at all.
    finish(CloudError(CloudError::Cancelled, tr("Cancelled.")));
  }
}

void CloudSyncEngine::recordFromItem(const QString &relativePath, const RemoteItem &item, const QByteArray &contentHash)
{
  ManifestEntry entry;
  entry.relativePath = relativePath;
  entry.remoteId = item.id;
  entry.remoteRevision = item.revision;
  entry.contentHash = contentHash;
  entry.size = item.size;
  entry.isFolder = item.isFolder;
  mManifest.entries.insert(relativePath, entry);
  if (!item.id.isEmpty()) {
    mRemoteIdByPath.insert(relativePath, item.id);
  }
}

void CloudSyncEngine::runNext()
{
  if (mCancelled) {
    finish(CloudError(CloudError::Cancelled, tr("Cancelled.")));
    return;
  }
  if (mQueue.isEmpty()) {
    mManifest.workingCopyComplete = true;
    // Where the next run resumes from, so a restart revalidates cheaply.
    CloudReply *pToken = mpProvider->currentDeltaToken(mMount.remoteRootId);
    mpCurrentReply = pToken;
    connect(pToken, &CloudReply::finished, this, [this, pToken]() {
      if (!pToken->error().isError()) {
        mManifest.deltaToken = pToken->deltaToken();
      }
      mManifest.save(mMount.manifestPath());
      finish(CloudError());
    });
    return;
  }

  const SyncAction action = mQueue.takeFirst();
  // The one ordering rule that matters: everything uploaded is on record before
  // the first deletion goes out.
  if (!mManifestSavedBeforeDeletions && phaseOf(action) >= 5) {
    mManifestSavedBeforeDeletions = true;
    mManifest.save(mMount.manifestPath());
  }
  emit progress(mDone++, mTotal, action.relativePath);

  switch (action.kind) {
    case SyncAction::CreateLocalFolder: {
      QDir().mkpath(absolutePath(action.relativePath));
      ManifestEntry entry;
      entry.relativePath = action.relativePath;
      entry.remoteId = action.remoteId;
      entry.remoteRevision = mRemote.value(action.relativePath).remoteRevision;
      entry.isFolder = true;
      mManifest.entries.insert(action.relativePath, entry);
      runNext();
      return;
    }
    case SyncAction::DownloadNew:
    case SyncAction::DownloadUpdate: {
      CloudReply *pReply = mpProvider->download(action.remoteId);
      mpCurrentReply = pReply;
      connect(pReply, &CloudReply::finished, this, [this, pReply, action]() {
        if (pReply->error().isError()) {
          finish(pReply->error());
          return;
        }
        const QString path = absolutePath(action.relativePath);
        QDir().mkpath(QFileInfo(path).absolutePath());
        QFile file(path);
        if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
          finish(CloudError(CloudError::Provider, tr("Could not write %1.").arg(path)));
          return;
        }
        const QByteArray contents = pReply->data();
        file.write(contents);
        file.close();
        RemoteItem item;
        item.id = action.remoteId;
        item.revision = mRemote.value(action.relativePath).remoteRevision;
        item.size = contents.size();
        recordFromItem(action.relativePath, item, hashOf(contents));
        runNext();
      });
      return;
    }
    case SyncAction::CreateRemoteFolder: {
      const QString name = action.relativePath.section(QLatin1Char('/'), -1);
      CloudReply *pReply = mpProvider->createFolder(parentRemoteId(action.relativePath), name);
      mpCurrentReply = pReply;
      connect(pReply, &CloudReply::finished, this, [this, pReply, action]() {
        if (pReply->error().isError()) {
          finish(pReply->error());
          return;
        }
        recordFromItem(action.relativePath, pReply->item(), QByteArray());
        runNext();
      });
      return;
    }
    case SyncAction::UploadNew:
    case SyncAction::UpdateRemote: {
      QFile file(absolutePath(action.relativePath));
      if (!file.open(QIODevice::ReadOnly)) {
        // Vanished between the scan and now; the next run will see it properly.
        runNext();
        return;
      }
      const QByteArray contents = file.readAll();
      file.close();
      CloudReply *pReply =
          action.kind == SyncAction::UploadNew
              ? mpProvider->uploadNew(parentRemoteId(action.relativePath),
                                      action.relativePath.section(QLatin1Char('/'), -1), contents)
              : mpProvider->uploadUpdate(action.remoteId, contents, action.expectedRevision);
      mpCurrentReply = pReply;
      connect(pReply, &CloudReply::finished, this, [this, pReply, action, contents]() {
        if (pReply->error().isError()) {
          finish(pReply->error());
          return;
        }
        recordFromItem(action.relativePath, pReply->item(), hashOf(contents));
        runNext();
      });
      return;
    }
    case SyncAction::AdoptIdentical: {
      RemoteItem item;
      item.id = action.remoteId;
      item.revision = mRemote.value(action.relativePath).remoteRevision;
      recordFromItem(action.relativePath, item, mLocal.value(action.relativePath).contentHash);
      runNext();
      return;
    }
    case SyncAction::DeleteRemote: {
      CloudReply *pReply = mpProvider->trashItem(action.remoteId, action.expectedRevision);
      mpCurrentReply = pReply;
      connect(pReply, &CloudReply::finished, this, [this, pReply, action]() {
        if (pReply->error().isError()) {
          finish(pReply->error());
          return;
        }
        // Only now, with the removal confirmed, does the entry go.
        mManifest.entries.remove(action.relativePath);
        runNext();
      });
      return;
    }
    case SyncAction::DeleteLocal: {
      const QString path = absolutePath(action.relativePath);
      if (action.isFolder) {
        QDir(path).removeRecursively();
      } else {
        QFile::remove(path);
      }
      mManifest.entries.remove(action.relativePath);
      runNext();
      return;
    }
    case SyncAction::DropManifestEntry: {
      mManifest.entries.remove(action.relativePath);
      runNext();
      return;
    }
    case SyncAction::Conflict:
      // Unresolved conflicts never reach the queue.
      runNext();
      return;
  }
}

void CloudSyncEngine::finish(const CloudError &error)
{
  if (mFinished) {
    return;
  }
  mFinished = true;
  // Also on the way out of a failure: without this the next run sees everything
  // uploaded before it as created on both sides, with no common ancestor.
  mManifest.save(mMount.manifestPath());
  emit progress(mTotal, mTotal, QString());
  emit finished(error);
}
