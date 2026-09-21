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

#include "Cloud/CloudManifest.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSaveFile>
#include <QSet>

namespace {

const int kManifestVersion = 1;

// A sync that removes this much of a package is worth a second look: either the
// user really did reorganise it, or the working copy is not what we think it is.
const int kDeletionCountThreshold = 5;
const double kDeletionFractionThreshold = 0.25;

ManifestEntry entryFromJson(const QJsonObject &object)
{
  ManifestEntry entry;
  entry.relativePath = object.value(QStringLiteral("path")).toString();
  entry.remoteId = object.value(QStringLiteral("id")).toString();
  entry.remoteRevision = object.value(QStringLiteral("revision")).toString();
  entry.contentHash = QByteArray::fromHex(object.value(QStringLiteral("sha256")).toString().toLatin1());
  entry.size = qint64(object.value(QStringLiteral("size")).toDouble(0));
  entry.isFolder = object.value(QStringLiteral("folder")).toBool(false);
  return entry;
}

QJsonObject entryToJson(const ManifestEntry &entry)
{
  QJsonObject object;
  object.insert(QStringLiteral("path"), entry.relativePath);
  object.insert(QStringLiteral("id"), entry.remoteId);
  object.insert(QStringLiteral("revision"), entry.remoteRevision);
  object.insert(QStringLiteral("sha256"), QString::fromLatin1(entry.contentHash.toHex()));
  object.insert(QStringLiteral("size"), entry.size);
  object.insert(QStringLiteral("folder"), entry.isFolder);
  return object;
}

//! True if any path in the set lies under dir.
bool hasDescendant(const QString &dir, const QList<QString> &paths)
{
  const QString prefix = dir + QLatin1Char('/');
  for (const QString &path : paths) {
    if (path.startsWith(prefix)) {
      return true;
    }
  }
  return false;
}

} // namespace

int SyncPlan::count(SyncAction::Kind kind) const
{
  int total = 0;
  for (const SyncAction &action : actions) {
    if (action.kind == kind) {
      ++total;
    }
  }
  return total;
}

bool SyncPlan::hasConflicts() const
{
  return count(SyncAction::Conflict) > 0;
}

QList<SyncAction> SyncPlan::conflicts() const
{
  QList<SyncAction> result;
  for (const SyncAction &action : actions) {
    if (action.kind == SyncAction::Conflict) {
      result << action;
    }
  }
  return result;
}

bool SyncPlan::needsDeletionConfirmation(int manifestFileCount) const
{
  const int deletions = count(SyncAction::DeleteRemote);
  if (deletions == 0) {
    return false;
  }
  return deletions > kDeletionCountThreshold
         || (manifestFileCount > 0 && double(deletions) / double(manifestFileCount) > kDeletionFractionThreshold);
}

int CloudManifest::fileCount() const
{
  int total = 0;
  for (const ManifestEntry &entry : entries) {
    if (!entry.isFolder) {
      ++total;
    }
  }
  return total;
}

bool CloudManifest::load(const QString &path)
{
  QFile file(path);
  if (!file.open(QIODevice::ReadOnly)) {
    return false;
  }
  const QJsonObject root = QJsonDocument::fromJson(file.readAll()).object();
  if (root.value(QStringLiteral("version")).toInt() != kManifestVersion) {
    return false;
  }
  remoteRootId = root.value(QStringLiteral("remoteRootId")).toString();
  deltaToken = root.value(QStringLiteral("deltaToken")).toString();
  // Deliberately not read back: the manifest persists in browser storage while
  // the working copy does not, so a stored "complete" would license deleting
  // every file in the remote folder. It is earned again each run.
  workingCopyComplete = false;
  entries.clear();
  const QJsonArray stored = root.value(QStringLiteral("entries")).toArray();
  for (const QJsonValue &value : stored) {
    const ManifestEntry entry = entryFromJson(value.toObject());
    if (!entry.relativePath.isEmpty()) {
      entries.insert(entry.relativePath, entry);
    }
  }
  return true;
}

bool CloudManifest::save(const QString &path) const
{
  QJsonArray stored;
  for (const ManifestEntry &entry : entries) {
    stored.append(entryToJson(entry));
  }
  QJsonObject root;
  root.insert(QStringLiteral("version"), kManifestVersion);
  root.insert(QStringLiteral("remoteRootId"), remoteRootId);
  root.insert(QStringLiteral("deltaToken"), deltaToken);
  root.insert(QStringLiteral("workingCopyComplete"), workingCopyComplete);
  root.insert(QStringLiteral("entries"), stored);

  QDir().mkpath(QFileInfo(path).absolutePath());
  QSaveFile file(path);
  if (!file.open(QIODevice::WriteOnly)) {
    return false;
  }
  file.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
  return file.commit();
}

bool isUsableLocalName(const QString &name, QString *reason)
{
  if (name.isEmpty()) {
    *reason = QStringLiteral("the name is empty");
    return false;
  }
  if (name == QLatin1String(".") || name == QLatin1String("..")) {
    *reason = QStringLiteral("the name is a directory reference");
    return false;
  }
  if (name.contains(QLatin1Char('/')) || name.contains(QLatin1Char('\\'))) {
    *reason = QStringLiteral("the name contains a path separator");
    return false;
  }
#if defined(Q_OS_WIN)
  // Reserved on Windows however the file is opened, and a trailing dot or space
  // is silently dropped by the filesystem, which would break the round trip.
  static const QStringList reserved = QStringList()
      << QStringLiteral("CON") << QStringLiteral("PRN") << QStringLiteral("AUX") << QStringLiteral("NUL")
      << QStringLiteral("COM1") << QStringLiteral("COM2") << QStringLiteral("COM3") << QStringLiteral("COM4")
      << QStringLiteral("COM5") << QStringLiteral("COM6") << QStringLiteral("COM7") << QStringLiteral("COM8")
      << QStringLiteral("COM9") << QStringLiteral("LPT1") << QStringLiteral("LPT2") << QStringLiteral("LPT3")
      << QStringLiteral("LPT4") << QStringLiteral("LPT5") << QStringLiteral("LPT6") << QStringLiteral("LPT7")
      << QStringLiteral("LPT8") << QStringLiteral("LPT9");
  const QString stem = name.section(QLatin1Char('.'), 0, 0).toUpper();
  if (reserved.contains(stem)) {
    *reason = QStringLiteral("the name is reserved by Windows");
    return false;
  }
  if (name.endsWith(QLatin1Char('.')) || name.endsWith(QLatin1Char(' '))) {
    *reason = QStringLiteral("the name ends with a dot or a space");
    return false;
  }
  static const QString illegal = QStringLiteral("<>:\"|?*");
  for (const QChar &character : name) {
    if (illegal.contains(character) || character.unicode() < 32) {
      *reason = QStringLiteral("the name contains a character Windows does not allow in a file name");
      return false;
    }
  }
#else
  for (const QChar &character : name) {
    if (character.unicode() == 0) {
      *reason = QStringLiteral("the name contains a null character");
      return false;
    }
  }
#endif
  return true;
}

SyncPlan planSync(const CloudManifest &manifest, const QMap<QString, LocalEntry> &local,
                  const QMap<QString, RemoteEntry> &remote)
{
  SyncPlan plan;

  QSet<QString> paths;
  for (auto it = manifest.entries.constBegin(); it != manifest.entries.constEnd(); ++it) {
    paths.insert(it.key());
  }
  for (auto it = local.constBegin(); it != local.constEnd(); ++it) {
    paths.insert(it.key());
  }
  for (auto it = remote.constBegin(); it != remote.constEnd(); ++it) {
    paths.insert(it.key());
  }

  // Sorted so a parent folder is always acted on before its children, and so the
  // plan reads in an order a person can follow.
  QList<QString> sorted = paths.values();
  std::sort(sorted.begin(), sorted.end());

  QList<QString> remotePaths = remote.keys();
  QList<QString> deletedRemotePaths;

  for (const QString &path : std::as_const(sorted)) {
    const bool inManifest = manifest.entries.contains(path);
    const bool inLocal = local.contains(path);
    const bool inRemote = remote.contains(path);
    const ManifestEntry manifestEntry = manifest.entries.value(path);
    const LocalEntry localEntry = local.value(path);
    const RemoteEntry remoteEntry = remote.value(path);

    SyncAction action;
    action.relativePath = path;
    action.remoteId = inRemote ? remoteEntry.remoteId : manifestEntry.remoteId;
    action.expectedRevision = manifestEntry.remoteRevision;
    action.isFolder = (inLocal && localEntry.isFolder) || (inRemote && remoteEntry.isFolder)
                      || (inManifest && manifestEntry.isFolder);

    // Folders carry no contents of their own, so they only ever need creating or,
    // once everything under them has gone, removing.
    if (action.isFolder) {
      if (inLocal && !inRemote) {
        // Only a folder that never reached the remote needs creating there; one
        // the manifest knows was removed remotely goes away with its files.
        if (!inManifest) {
          action.kind = SyncAction::CreateRemoteFolder;
          plan.actions << action;
        }
      } else if (!inLocal && inRemote) {
        // A folder the manifest knows, missing locally, is a local deletion - and
        // the pass at the end decides whether it may go. Recreating it here would
        // contradict that. While the working copy is unverified, missing means
        // "not restored yet", so it is created rather than deleted.
        if (!inManifest || !manifest.workingCopyComplete) {
          action.kind = SyncAction::CreateLocalFolder;
          plan.actions << action;
        }
      } else if (inManifest && !inLocal && !inRemote) {
        action.kind = SyncAction::DropManifestEntry;
        plan.actions << action;
      }
      continue;
    }

    if (!inManifest) {
      if (inLocal && !inRemote) {
        action.kind = SyncAction::UploadNew;
      } else if (!inLocal && inRemote) {
        action.kind = SyncAction::DownloadNew;
      } else if (inLocal && inRemote) {
        // No common ancestor. Identical bytes are not a conflict, just something
        // to record; anything else is for the user to settle.
        if (!localEntry.providerHash.isEmpty()
            && localEntry.providerHash == remoteEntry.contentHash.toLatin1()) {
          action.kind = SyncAction::AdoptIdentical;
        } else {
          action.kind = SyncAction::Conflict;
          action.conflict = SyncAction::BothCreated;
        }
      } else {
        continue;
      }
      plan.actions << action;
      continue;
    }

    const bool localChanged = inLocal && localEntry.contentHash != manifestEntry.contentHash;
    const bool remoteChanged = inRemote && remoteEntry.remoteRevision != manifestEntry.remoteRevision;

    if (inLocal && inRemote) {
      if (!localChanged && !remoteChanged) {
        continue;
      }
      if (localChanged && !remoteChanged) {
        action.kind = SyncAction::UpdateRemote;
      } else if (!localChanged && remoteChanged) {
        action.kind = SyncAction::DownloadUpdate;
      } else if (!localEntry.providerHash.isEmpty()
                 && localEntry.providerHash == remoteEntry.contentHash.toLatin1()) {
        // Both moved, but to the same bytes - nothing to reconcile.
        action.kind = SyncAction::AdoptIdentical;
      } else {
        action.kind = SyncAction::Conflict;
        action.conflict = SyncAction::BothChanged;
      }
      plan.actions << action;
      continue;
    }

    if (!inLocal && inRemote) {
      // On a working copy that was never fully restored, missing means "not here
      // yet", not "deleted" - so fetch it back. Skipping instead left the copy
      // permanently empty: on the web target it is wiped by every reload, so the
      // files could never come back and reopening a mount produced nothing.
      // Fetching cannot lose anything, so it applies whether or not the remote
      // moved on in the meantime.
      if (!manifest.workingCopyComplete) {
        action.kind = SyncAction::DownloadNew;
        plan.actions << action;
        continue;
      }
      if (remoteChanged) {
        // Deleting now would throw away an edit made elsewhere.
        action.kind = SyncAction::Conflict;
        action.conflict = SyncAction::LocalDeletedRemoteChanged;
        plan.actions << action;
        continue;
      }
      action.kind = SyncAction::DeleteRemote;
      deletedRemotePaths << path;
      plan.actions << action;
      continue;
    }

    if (inLocal && !inRemote) {
      if (localChanged) {
        action.kind = SyncAction::Conflict;
        action.conflict = SyncAction::LocalChangedRemoteDeleted;
      } else {
        action.kind = SyncAction::DeleteLocal;
      }
      plan.actions << action;
      continue;
    }

    // Gone from both sides.
    action.kind = SyncAction::DropManifestEntry;
    plan.actions << action;
  }

  // A folder may only be removed once nothing is left under it. Deepest first, so
  // that removing A/B lets A go too; anything the remote still holds there - a
  // file someone else added, or one this plan is keeping - means the folder stays.
  if (manifest.workingCopyComplete) {
    QSet<QString> deleted(deletedRemotePaths.constBegin(), deletedRemotePaths.constEnd());
    QList<QString> folders;
    for (const QString &path : std::as_const(sorted)) {
      if (manifest.entries.value(path).isFolder && !local.contains(path) && remote.contains(path)) {
        folders << path;
      }
    }
    std::sort(folders.begin(), folders.end(), std::greater<QString>());
    for (const QString &path : std::as_const(folders)) {
      QList<QString> survivors;
      for (const QString &remotePath : std::as_const(remotePaths)) {
        if (!deleted.contains(remotePath)) {
          survivors << remotePath;
        }
      }
      if (hasDescendant(path, survivors)) {
        plan.skipped << path;
        continue;
      }
      SyncAction action;
      action.kind = SyncAction::DeleteRemote;
      action.relativePath = path;
      action.remoteId = remote.value(path).remoteId;
      action.expectedRevision = manifest.entries.value(path).remoteRevision;
      action.isFolder = true;
      plan.actions << action;
      deleted.insert(path);
    }
  }

  return plan;
}
