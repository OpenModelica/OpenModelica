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

#ifndef CLOUDMOUNT_H
#define CLOUDMOUNT_H

#include "Cloud/CloudTypes.h"

#include <QList>
#include <QObject>
#include <QString>

/*!
 * \brief A remote folder made available as an ordinary local path.
 *
 * Nothing downstream knows it came from a cloud service. Natively the working
 * copy is a real directory; on the web target it is in the omc worker's
 * filesystem, which the QAbstractFileEngine makes look the same to QFile.
 */
struct CloudMount
{
  QString mountId;
  QString accountKey;
  QString remoteRootId;
  //! What the folder is called remotely; shown in the library tree and dialogs.
  QString remoteName;
  QString localRoot;
  //! Push after every successful save, rather than only when asked.
  bool autoPush = true;

  bool isValid() const { return !mountId.isEmpty() && !localRoot.isEmpty(); }
  //! Outside the working copy: deleting that must not take the sync state with
  //! it, and the manifest must never be uploaded as part of the package.
  QString manifestPath() const;
};

/*!
 * \brief The mounts this installation knows about, remembered across restarts.
 */
class CloudMountManager : public QObject
{
  Q_OBJECT
public:
  static CloudMountManager *instance();

  //! Root of every working copy. "/cloud" on the web target.
  static QString workingCopyRoot();
  static QString manifestRoot();

  QList<CloudMount> mounts();
  CloudMount mount(const QString &mountId);

  //! The mount a path belongs to, or an invalid mount.
  CloudMount mountForPath(const QString &path);

  CloudMount addMount(const QString &accountKey, const QString &remoteRootId, const QString &remoteName);
  void removeMount(const QString &mountId);
  void updateMount(const CloudMount &mount);

signals:
  void mountsChanged();

private:
  CloudMountManager() = default;
  void load();
  void save();

  QList<CloudMount> mMounts;
  bool mLoaded = false;
};

//! True when path lies inside a mounted cloud folder. On the web target this is
//! what decides whether a saved file is also handed to the user as a download.
bool isInsideCloudMount(const QString &path);

/*!
 * \brief The immediate children of a directory, directories marked by a trailing '/'.
 *
 * Not QDir on the web target: it enumerates nothing through the worker-VFS
 * QAbstractFileEngine, even for a directory whose files read back correctly.
 */
QStringList cloudListDirectory(const QString &path);

#endif // CLOUDMOUNT_H
