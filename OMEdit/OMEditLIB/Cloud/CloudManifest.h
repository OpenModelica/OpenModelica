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

#ifndef CLOUDMANIFEST_H
#define CLOUDMANIFEST_H

#include <QByteArray>
#include <QList>
#include <QMap>
#include <QString>
#include <QStringList>

/*!
 * \brief What one file looked like the last time it was in sync.
 *
 * The common ancestor of the three-way comparison: without it there is no
 * telling "the user deleted this" from "this has not arrived yet".
 */
struct ManifestEntry
{
  QString relativePath;
  QString remoteId;
  QString remoteRevision;
  //! SHA-256 of the bytes at the last sync, so a local edit is detectable
  //! without trusting timestamps.
  QByteArray contentHash;
  qint64 size = 0;
  bool isFolder = false;
};

//! The working copy as it is right now.
struct LocalEntry
{
  QString relativePath;
  QByteArray contentHash;
  //! Only filled for a provider that publishes a comparable hash (Drive's MD5),
  //! and only used to spot that both sides were changed to the same bytes.
  QByteArray providerHash;
  qint64 size = 0;
  bool isFolder = false;
};

//! The remote tree as it is right now, keyed by the same relative paths.
struct RemoteEntry
{
  QString relativePath;
  QString remoteId;
  QString remoteRevision;
  QString contentHash;
  qint64 size = 0;
  bool isFolder = false;
};

/*!
 * \brief One thing the sync has to do. A Conflict is carried to the user and the
 * engine re-plans with their answer; nothing here discards anybody's bytes.
 */
struct SyncAction
{
  enum Kind {
    UploadNew,
    UpdateRemote,
    DownloadNew,
    DownloadUpdate,
    DeleteRemote,
    DeleteLocal,
    CreateRemoteFolder,
    CreateLocalFolder,
    //! Both sides already agree; record it and move on.
    AdoptIdentical,
    //! Gone from both sides; only the manifest still mentions it.
    DropManifestEntry,
    Conflict
  };

  enum ConflictKind {
    NoConflict,
    //! Changed on both sides since the last sync.
    BothChanged,
    //! Appeared on both sides with no common ancestor.
    BothCreated,
    //! Deleted here, changed there - deleting would discard their edit.
    LocalDeletedRemoteChanged,
    //! Changed here, deleted there - deleting would discard our edit.
    LocalChangedRemoteDeleted
  };

  Kind kind = AdoptIdentical;
  ConflictKind conflict = NoConflict;
  QString relativePath;
  QString remoteId;
  //! The revision the write is allowed to overwrite; empty means unguarded, which
  //! only happens once the user has resolved a conflict.
  QString expectedRevision;
  bool isFolder = false;
};

/*!
 * \brief The work of one synchronisation, and what it would cost.
 */
struct SyncPlan
{
  QList<SyncAction> actions;
  //! Paths the remote holds that cannot be represented locally, or that collide.
  QStringList skipped;

  int count(SyncAction::Kind kind) const;
  bool hasConflicts() const;
  QList<SyncAction> conflicts() const;

  //! True when enough is being deleted to want a second look. Removing most of a
  //! package is either a reorganisation or a bug, and only the user can tell.
  bool needsDeletionConfirmation(int manifestFileCount) const;
};

/*!
 * \brief The last synced state of one mounted folder.
 */
class CloudManifest
{
public:
  QMap<QString, ManifestEntry> entries;
  QString remoteRootId;
  //! Where the next changes() call resumes from.
  QString deltaToken;
  /*!
   * \brief Whether a file missing from the working copy means it was deleted.
   * False when the working copy holds none of what the manifest lists - what a
   * reload leaves behind on the web target - and then nothing is deleted.
   */
  bool workingCopyComplete = false;

  bool load(const QString &path);
  //! Written through a temporary file, so an interrupted write cannot truncate it.
  bool save(const QString &path) const;

  int fileCount() const;
};

/*!
 * \brief Decide what to do, comparing the last synced state with both sides.
 *
 * Pure, so every case is testable. Anything ambiguous becomes a Conflict rather
 * than a guess, and a deletion needs workingCopyComplete.
 */
SyncPlan planSync(const CloudManifest &manifest, const QMap<QString, LocalEntry> &local,
                  const QMap<QString, RemoteEntry> &remote);

//! Rejects a remote name that cannot be part of a local path on this platform.
bool isUsableLocalName(const QString &name, QString *reason);

#endif // CLOUDMANIFEST_H
