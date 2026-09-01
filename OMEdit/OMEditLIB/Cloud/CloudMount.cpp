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

#include "Cloud/CloudMount.h"
#include "Cloud/CloudCache.h"
#include "Cloud/CloudTypes.h"
#include "Util/PersistentStorage.h"

#include <QCryptographicHash>
#include <QDir>
#include <QFileInfo>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSaveFile>

namespace {

const char *const kMountsFileName = "cloud-mounts.json";

QString mountsFilePath()
{
  return CloudMountManager::manifestRoot() + QLatin1Char('/') + QLatin1String(kMountsFileName);
}

//! A folder name that is safe on every platform and stable across restarts.
QString makeMountId(const QString &accountKey, const QString &remoteRootId)
{
  const QByteArray digest =
      QCryptographicHash::hash((accountKey + QLatin1Char('/') + remoteRootId).toUtf8(), QCryptographicHash::Sha1);
  return QString::fromLatin1(digest.toHex().left(16));
}

/*!
 * \brief A remote name reduced to something usable as a directory name.
 * Only for the working copy's own folder - the files inside keep their real
 * names, and one that cannot be represented locally is reported rather than
 * mangled (see isUsableLocalName).
 */
QString sanitiseFolderName(const QString &name)
{
  QString safe;
  for (const QChar &character : name) {
    safe += (character.isLetterOrNumber() || character == QLatin1Char('.') || character == QLatin1Char('-')
             || character == QLatin1Char('_'))
                ? character
                : QLatin1Char('_');
  }
  safe = safe.trimmed();
  return safe.isEmpty() ? QStringLiteral("package") : safe;
}

} // namespace

QString CloudMount::manifestPath() const
{
  return CloudMountManager::manifestRoot() + QStringLiteral("/manifest-") + mountId + QStringLiteral(".json");
}

CloudMountManager *CloudMountManager::instance()
{
  static CloudMountManager manager;
  return &manager;
}

QString CloudMountManager::workingCopyRoot()
{
#if defined(__EMSCRIPTEN__)
  // In the omc worker's filesystem, so that omc reads the same bytes the GUI
  // writes. Deliberately not under /persist, which is the page's own tree.
  return QStringLiteral("/cloud");
#else
  return PersistentStorage::root() + QStringLiteral("/cloud");
#endif
}

QString CloudMountManager::manifestRoot()
{
  // Always page-local and persisted: on the web target the working copy is
  // volatile, and a manifest that vanished with it could not tell a lost restore
  // from a deliberate deletion.
  return PersistentStorage::root();
}

void CloudMountManager::load()
{
  if (mLoaded) {
    return;
  }
  mLoaded = true;
  QFile file(mountsFilePath());
  if (!file.open(QIODevice::ReadOnly)) {
    return;
  }
  const QJsonArray stored = QJsonDocument::fromJson(file.readAll()).array();
  for (const QJsonValue &value : stored) {
    const QJsonObject object = value.toObject();
    CloudMount mount;
    mount.mountId = object.value(QStringLiteral("mountId")).toString();
    mount.accountKey = object.value(QStringLiteral("accountKey")).toString();
    mount.remoteRootId = object.value(QStringLiteral("remoteRootId")).toString();
    mount.remoteName = object.value(QStringLiteral("remoteName")).toString();
    mount.localRoot = object.value(QStringLiteral("localRoot")).toString();
    mount.autoPush = object.value(QStringLiteral("autoPush")).toBool(true);
    if (mount.isValid()) {
      mMounts << mount;
    }
  }
}

void CloudMountManager::save()
{
  QJsonArray stored;
  for (const CloudMount &mount : std::as_const(mMounts)) {
    QJsonObject object;
    object.insert(QStringLiteral("mountId"), mount.mountId);
    object.insert(QStringLiteral("accountKey"), mount.accountKey);
    object.insert(QStringLiteral("remoteRootId"), mount.remoteRootId);
    object.insert(QStringLiteral("remoteName"), mount.remoteName);
    object.insert(QStringLiteral("localRoot"), mount.localRoot);
    object.insert(QStringLiteral("autoPush"), mount.autoPush);
    stored.append(object);
  }
  QDir().mkpath(manifestRoot());
  QSaveFile file(mountsFilePath());
  if (file.open(QIODevice::WriteOnly)) {
    file.write(QJsonDocument(stored).toJson(QJsonDocument::Indented));
    file.commit();
  }
  PersistentStorage::scheduleSnapshot();
  emit mountsChanged();
}

QList<CloudMount> CloudMountManager::mounts()
{
  load();
  return mMounts;
}

CloudMount CloudMountManager::mount(const QString &mountId)
{
  load();
  for (const CloudMount &mount : std::as_const(mMounts)) {
    if (mount.mountId == mountId) {
      return mount;
    }
  }
  return CloudMount();
}

CloudMount CloudMountManager::mountForPath(const QString &path)
{
  load();
  const QString cleaned = QDir::cleanPath(path);
  for (const CloudMount &mount : std::as_const(mMounts)) {
    const QString root = QDir::cleanPath(mount.localRoot);
    if (cleaned == root || cleaned.startsWith(root + QLatin1Char('/'))) {
      return mount;
    }
  }
  return CloudMount();
}

CloudMount CloudMountManager::addMount(const QString &accountKey, const QString &remoteRootId,
                                       const QString &remoteName)
{
  load();
  const QString mountId = makeMountId(accountKey, remoteRootId);
  for (const CloudMount &existing : std::as_const(mMounts)) {
    if (existing.mountId == mountId) {
      return existing;
    }
  }
  CloudMount mount;
  mount.mountId = mountId;
  mount.accountKey = accountKey;
  mount.remoteRootId = remoteRootId;
  mount.remoteName = remoteName;
  // The mount id keeps two folders of the same name apart.
  mount.localRoot = QStringLiteral("%1/%2-%3").arg(workingCopyRoot(), sanitiseFolderName(remoteName), mountId);
  mMounts << mount;
  save();
  return mount;
}

void CloudMountManager::removeMount(const QString &mountId)
{
  load();
  for (int i = 0; i < mMounts.size(); ++i) {
    if (mMounts.at(i).mountId != mountId) {
      continue;
    }
    const CloudMount mount = mMounts.takeAt(i);
    // The working copy, its cache and the manifest go; nothing is touched remotely.
    QDir(mount.localRoot).removeRecursively();
    QFile::remove(mount.manifestPath());
    CloudCache::forget(mount);
    save();
    return;
  }
}

void CloudMountManager::updateMount(const CloudMount &mount)
{
  load();
  for (int i = 0; i < mMounts.size(); ++i) {
    if (mMounts.at(i).mountId == mount.mountId) {
      mMounts[i] = mount;
      save();
      return;
    }
  }
}

bool isInsideCloudMount(const QString &path)
{
  return CloudMountManager::instance()->mountForPath(path).isValid();
}

#if defined(__EMSCRIPTEN__)
// Defined in OMEditLIB/OMC/OMCProxy.cpp; the omc worker's directory listing.
QStringList omcWorkerListDir(const char *path);
#endif

QStringList cloudListDirectory(const QString &path)
{
#if defined(__EMSCRIPTEN__)
  return omcWorkerListDir(path.toUtf8().constData());
#else
  QStringList names;
  const QFileInfoList entries = QDir(path).entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot);
  for (const QFileInfo &info : entries) {
    names << (info.isDir() ? info.fileName() + QLatin1Char('/') : info.fileName());
  }
  return names;
#endif
}
