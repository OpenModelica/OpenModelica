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

#ifndef CLOUDSYNCENGINE_H
#define CLOUDSYNCENGINE_H

#include "Cloud/CloudManifest.h"
#include "Cloud/CloudMount.h"
#include "Cloud/CloudTypes.h"

#include <QHash>
#include <QList>
#include <QObject>
#include <QPointer>

class CloudProvider;
class CloudReply;

/*!
 * \brief Runs one synchronisation of a mounted folder.
 *
 * planSync() decides what to do; this carries it out in an order that cannot lose
 * data on an interruption:
 *
 *   local folders -> downloads -> remote folders -> uploads
 *   -> SAVE MANIFEST -> remote deletions -> local deletions -> SAVE MANIFEST
 *
 * An entry is dropped only once its remote deletion is confirmed, so an
 * interrupted run leaves a file looking new, never deleted. Conflicts and large
 * deletions are reported, not decided here.
 */
class CloudSyncEngine : public QObject
{
  Q_OBJECT
public:
  //! What to do with one conflicting path. Every value keeps the bytes.
  enum Resolution {
    KeepLocal,
    TakeRemote,
    //! Keep the remote version at the original path and the local one beside it.
    KeepBoth
  };

  CloudSyncEngine(const CloudMount &mount, CloudProvider *pProvider, QObject *pParent = 0);

  void start();
  //! Continue after conflictsDetected(), keyed by relative path.
  void applyResolutions(const QHash<QString, int> &resolutions);
  //! Continue (or abandon) after deletionsNeedConfirmation().
  void confirmDeletions(bool proceed);
  void cancel();

  const CloudManifest &manifest() const { return mManifest; }

signals:
  void progress(int done, int total, const QString &description);
  void conflictsDetected(const QList<SyncAction> &conflicts);
  //! More deletions than looks routine; the user sees them listed before any run.
  void deletionsNeedConfirmation(const QList<SyncAction> &deletions);
  //! Remote entries that could not be represented locally, with the reason.
  void skipped(const QStringList &descriptions);
  void finished(const CloudError &error);

private:
  void scanLocal();
  void scanLocalInto(const QString &directory, const QString &prefix);
  void listRemoteFrom(const QString &folderId, const QString &prefix);
  void remoteListingDone();
  void planAndProceed();
  void runNext();
  void finish(const CloudError &error);
  void recordFromItem(const QString &relativePath, const RemoteItem &item, const QByteArray &contentHash);
  QString absolutePath(const QString &relativePath) const;
  QString parentRemoteId(const QString &relativePath) const;

  CloudMount mMount;
  CloudProvider *mpProvider;
  CloudManifest mManifest;

  QMap<QString, LocalEntry> mLocal;
  QMap<QString, RemoteEntry> mRemote;
  QHash<QString, QString> mRemoteIdByPath;
  QStringList mSkipped;

  SyncPlan mPlan;
  QList<SyncAction> mQueue;
  int mTotal = 0;
  int mDone = 0;
  //! Set once the queue crosses from uploads into deletions.
  bool mManifestSavedBeforeDeletions = false;

  QHash<QString, int> mResolutions;
  //! Where a KeepBoth answer moved the local version, so a re-plan reuses it.
  QHash<QString, QString> mConflictCopies;
  bool mDeletionsConfirmed = false;
  bool mCancelled = false;
  bool mFinished = false;
  //! Outstanding recursive folder listings.
  int mPendingListings = 0;
  bool mListingFailed = false;
  CloudError mListingError;
  QPointer<CloudReply> mpCurrentReply;
};

#endif // CLOUDSYNCENGINE_H
