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

/*
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#include "RecursiveFileWatcher.h"

#include <QDir>
#include <QFileInfo>
#include <QFileSystemWatcher>
#include <QTimer>

namespace {
  // A checkout or a build touches many files at once. Waiting for the burst to
  // end reports it as one batch instead of one notification per file.
  const int kFlushDelayMs = 300;
  // Each watched file costs a kernel handle. Past this many only the
  // directories stay watched, which still detects files replaced by a rename.
  const int kMaxWatchedFiles = 20000;
}

/*!
 * \brief RecursiveFileWatcher::stampOf
 * Records the modification time and size used to detect a file change.
 * \param fileInfo file to record
 * \return recorded file state
 */
RecursiveFileWatcher::Stamp RecursiveFileWatcher::stampOf(const QFileInfo &fileInfo)
{
  Stamp stamp;
  stamp.modified = fileInfo.lastModified().toMSecsSinceEpoch();
  stamp.size = fileInfo.size();
  return stamp;
}

/*!
 * \class RecursiveFileWatcher
 * \brief Watches files and directory trees for changes made outside OMEdit.
 *
 * QFileSystemWatcher reports that a directory changed, not which entry did, so
 * every watched directory keeps a snapshot of its files. A change is classified
 * by comparing the directory with its snapshot. Single files are watched
 * together with their parent directory because an editor that replaces a file
 * by a rename also drops the file watch.
 */
/*!
 * \brief RecursiveFileWatcher::RecursiveFileWatcher
 * \param pParent
 */
RecursiveFileWatcher::RecursiveFileWatcher(QObject *pParent)
  : QObject(pParent), mpWatcher(new QFileSystemWatcher(this)), mpFlushTimer(new QTimer(this))
{
  mpFlushTimer->setSingleShot(true);
  mpFlushTimer->setInterval(kFlushDelayMs);
  connect(mpFlushTimer, &QTimer::timeout, this, &RecursiveFileWatcher::flush);
  connect(mpWatcher, &QFileSystemWatcher::directoryChanged, this, &RecursiveFileWatcher::onDirectoryChanged);
  connect(mpWatcher, &QFileSystemWatcher::fileChanged, this, &RecursiveFileWatcher::onFileChanged);
}

/*!
 * \brief RecursiveFileWatcher::isRelevant
 * Decides whether an entry takes part in the snapshot. Subclasses can override
 * this to ignore files that are not of interest. An irrelevant directory is not
 * descended into.
 * \param fileInfo file or directory found below a watched root
 * \return true for every entry by default
 */
bool RecursiveFileWatcher::isRelevant(const QFileInfo &fileInfo) const
{
  Q_UNUSED(fileInfo);
  return true;
}

/*!
 * \brief RecursiveFileWatcher::setRoots
 * Replaces the watched roots. A root is either a directory that is watched
 * recursively or a single file.
 * \param roots watched directories and files
 */
void RecursiveFileWatcher::setRoots(const QStringList &roots)
{
  QStringList absoluteRoots;
  for (const QString &root : roots) {
    const QString absolute = QDir::cleanPath(QFileInfo(root).absoluteFilePath());
    if (!absolute.isEmpty() && !absoluteRoots.contains(absolute)) {
      absoluteRoots.append(absolute);
    }
  }

  QStringList directoryRoots;
  QStringList fileRoots;
  for (const QString &absolute : absoluteRoots) {
    QFileInfo fileInfo(absolute);
    if (fileInfo.exists() && fileInfo.isDir()) {
      directoryRoots.append(absolute);
    } else {
      fileRoots.append(absolute);
    }
  }

  // A root inside another directory root is already covered by the outer
  // root's recursive scan.
  QStringList normalizedDirectories;
  for (const QString &absolute : directoryRoots) {
    bool nested = false;
    for (const QString &other : directoryRoots) {
      if (other != absolute && absolute.startsWith(other + QStringLiteral("/"))) {
        nested = true;
        break;
      }
    }
    if (!nested) {
      normalizedDirectories.append(absolute);
    }
  }

  QStringList normalizedFiles;
  for (const QString &absolute : fileRoots) {
    bool covered = false;
    for (const QString &directory : normalizedDirectories) {
      if (absolute.startsWith(directory + QStringLiteral("/"))) {
        covered = true;
        break;
      }
    }
    if (!covered) {
      normalizedFiles.append(absolute);
    }
  }

  if (normalizedDirectories == mDirectoryRoots && normalizedFiles == mFileRoots) {
    return;
  }

  for (const QString &root : mDirectoryRoots) {
    if (!normalizedDirectories.contains(root)) {
      forgetSubtree(root, nullptr);
    }
  }
  for (const QString &root : mFileRoots) {
    if (!normalizedFiles.contains(root)) {
      unwatchFile(root);
      mFileStamps.remove(root);
    }
  }

  QSet<QString> fileRootParents;
  for (const QString &root : normalizedFiles) {
    const QString parent = QFileInfo(root).absolutePath();
    if (!parent.isEmpty()) {
      fileRootParents.insert(parent);
    }
  }
  for (const QString &parent : mFileRootParents) {
    if (!fileRootParents.contains(parent) && !mDirectoryRoots.contains(parent)
        && !normalizedDirectories.contains(parent)) {
      mpWatcher->removePath(parent);
    }
  }
  for (const QString &parent : fileRootParents) {
    if (!mFileRootParents.contains(parent) && !mDirectoryRoots.contains(parent)
        && !normalizedDirectories.contains(parent)) {
      mpWatcher->addPath(parent);
    }
  }
  mFileRootParents = fileRootParents;

  mDirectoryRoots = normalizedDirectories;
  mFileRoots = normalizedFiles;

  for (const QString &root : normalizedDirectories) {
    if (!mDirectories.contains(root)) {
      snapshotDirectory(root, nullptr);
    }
  }
  for (const QString &root : normalizedFiles) {
    if (!mFileStamps.contains(root)) {
      snapshotFileRoot(root);
    }
  }
}

/*!
 * \brief RecursiveFileWatcher::hasChangedSinceSnapshot
 * Compares a file with its recorded state without waiting for the watcher
 * signal. Used before saving so OMEdit does not overwrite an external edit.
 * \param filePath file to check
 * \return true if the file changed or disappeared since it was recorded
 */
bool RecursiveFileWatcher::hasChangedSinceSnapshot(const QString &filePath) const
{
  const QString absolute = QDir::cleanPath(QFileInfo(filePath).absoluteFilePath());
  const QFileInfo fileInfo(absolute);
  if (!isRelevant(fileInfo)) {
    return false;
  }

  const bool exists = fileInfo.exists() && fileInfo.isFile();
  const Stamp currentStamp = exists ? stampOf(fileInfo) : Stamp();
  const auto differs = [exists, &currentStamp](bool known, const Stamp &knownStamp) {
    return exists != known || (exists && (currentStamp.modified != knownStamp.modified
                                          || currentStamp.size != knownStamp.size));
  };

  if (mFileRoots.contains(absolute)) {
    const auto it = mFileStamps.constFind(absolute);
    return differs(it != mFileStamps.constEnd(), it == mFileStamps.constEnd() ? Stamp() : it.value());
  }

  const QString directory = fileInfo.absolutePath();
  const auto directoryIt = mDirectories.constFind(directory);
  if (directoryIt != mDirectories.constEnd()) {
    const auto it = directoryIt->constFind(fileInfo.fileName());
    return differs(it != directoryIt->constEnd(), it == directoryIt->constEnd() ? Stamp() : it.value());
  }

  for (const QString &root : mDirectoryRoots) {
    if (absolute.startsWith(root + QStringLiteral("/"))) {
      return exists;
    }
  }
  return false;
}

/*!
 * \brief RecursiveFileWatcher::ignorePath
 * Records the current state of a file as known, so that a write by OMEdit is
 * not reported as an external change.
 * \param filePath file that OMEdit has just written
 */
void RecursiveFileWatcher::ignorePath(const QString &filePath)
{
  const QString absolute = QDir::cleanPath(QFileInfo(filePath).absoluteFilePath());
  QFileInfo fileInfo(absolute);

  if (mFileRoots.contains(absolute)) {
    if (fileInfo.exists() && fileInfo.isFile()) {
      mFileStamps.insert(absolute, stampOf(fileInfo));
      // Saving on Windows removes and recreates the file, which drops the watch.
      unwatchFile(absolute);
      watchFile(absolute);
    } else {
      mFileStamps.remove(absolute);
      unwatchFile(absolute);
    }
    return;
  }

  const QString directory = fileInfo.absolutePath();
  if (mDirectories.contains(directory)) {
    QHash<QString, Stamp> stamps = mDirectories.value(directory);
    if (fileInfo.exists() && fileInfo.isFile()) {
      stamps.insert(fileInfo.fileName(), stampOf(fileInfo));
      unwatchFile(absolute);
      watchFile(absolute);
    } else {
      stamps.remove(fileInfo.fileName());
      unwatchFile(absolute);
      // A removed directory is not in this snapshot, but its own subtree is.
      forgetSubtree(absolute, nullptr);
    }
    mDirectories.insert(directory, stamps);
    return;
  }

  // A file saved into a new subdirectory of a watched library.
  for (const QString &root : mDirectoryRoots) {
    if (absolute.startsWith(root + QStringLiteral("/"))) {
      snapshotDirectory(directory, nullptr);
      return;
    }
  }
}

/*!
 * \brief RecursiveFileWatcher::resync
 * Drops the recorded state and reads the watched roots again, so that a change
 * made by OMEdit itself is not reported later from a stale snapshot.
 */
void RecursiveFileWatcher::resync()
{
  mpFlushTimer->stop();
  mDirtyDirectories.clear();
  mDirtyFileRootParents.clear();

  const QStringList roots = mDirectoryRoots + mFileRoots;
  const QStringList directories = mDirectories.keys();
  const QSet<QString> watchedFiles = mWatchedFiles;
  const QSet<QString> fileRootParents = mFileRootParents;

  for (const QString &directory : directories) {
    mpWatcher->removePath(directory);
  }
  for (const QString &file : watchedFiles) {
    mpWatcher->removePath(file);
  }
  for (const QString &parent : fileRootParents) {
    mpWatcher->removePath(parent);
  }

  mDirectories.clear();
  mFileStamps.clear();
  mWatchedFiles.clear();
  mFileRootParents.clear();
  mDirectoryRoots.clear();
  mFileRoots.clear();
  mWatchLimitReported = false;

  setRoots(roots);
}

/*!
 * \brief RecursiveFileWatcher::rescan
 * Compares all watched files with the disk now and reports the changes before
 * returning, without waiting for QFileSystemWatcher.
 */
void RecursiveFileWatcher::rescan()
{
  mpFlushTimer->stop();
  for (auto it = mDirectories.constBegin(); it != mDirectories.constEnd(); ++it) {
    mDirtyDirectories.insert(it.key());
  }
  for (const QString &root : mFileRoots) {
    mDirtyFileRootParents.insert(QFileInfo(root).absolutePath());
  }
  flush();
}

/*!
 * \brief RecursiveFileWatcher::watchFile
 * Watches one file if the per-file watch limit has not been reached. The parent
 * directory stays watched, so files added or removed by a rename are still
 * reported after that limit.
 * \param filePath file to watch
 */
void RecursiveFileWatcher::watchFile(const QString &filePath)
{
  if (mWatchedFiles.contains(filePath)) {
    return;
  }
  if (mWatchedFiles.size() >= kMaxWatchedFiles) {
    if (!mWatchLimitReported) {
      mWatchLimitReported = true;
      // In-place edits are no longer detected once the file limit is reached.
      emit watchLimitReached(kMaxWatchedFiles);
    }
    return;
  }
  if (mpWatcher->addPath(filePath)) {
    mWatchedFiles.insert(filePath);
  }
}

/*!
 * \brief RecursiveFileWatcher::unwatchFile
 * Stops watching one file.
 * \param filePath file to stop watching
 */
void RecursiveFileWatcher::unwatchFile(const QString &filePath)
{
  if (mWatchedFiles.remove(filePath)) {
    mpWatcher->removePath(filePath);
  }
}

/*!
 * \brief RecursiveFileWatcher::snapshotDirectory
 * Watches a directory and everything below it and records what it holds.
 * \param directory directory to watch
 * \param pCreatedFiles when set, every file found is reported as created
 */
void RecursiveFileWatcher::snapshotDirectory(const QString &directory, QStringList *pCreatedFiles)
{
  QDir dir(directory);
  if (!dir.exists()) {
    return;
  }
  // Re-add unconditionally: a directory replaced by a rename loses its watch
  // without an entry being removed from mDirectories.
  mpWatcher->addPath(directory);
  // Symbolic links are not followed: a link back into the tree would recurse
  // forever, and the target is watched when it lives under a root.
  const QFileInfoList entries = dir.entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::NoSymLinks);
  // A local copy is written back in one go: inserting a subdirectory below can
  // rehash mDirectories and invalidate a reference into it.
  QHash<QString, Stamp> stamps;
  QStringList subDirectories;
  for (const QFileInfo &entry : entries) {
    if (!isRelevant(entry)) {
      continue;
    }
    if (entry.isDir()) {
      subDirectories.append(entry.absoluteFilePath());
      continue;
    }
    stamps.insert(entry.fileName(), stampOf(entry));
    watchFile(entry.absoluteFilePath());
    if (pCreatedFiles) {
      pCreatedFiles->append(entry.absoluteFilePath());
    }
  }
  mDirectories.insert(directory, stamps);
  for (const QString &subDirectory : subDirectories) {
    snapshotDirectory(subDirectory, pCreatedFiles);
  }
}

/*!
 * \brief RecursiveFileWatcher::rescanDirectory
 * Compares a directory with its snapshot and reports the differences.
 * \param directory directory to scan
 * \param pCreatedFiles created files are appended here
 * \param pDeletedFiles deleted files are appended here
 * \param pChangedFiles modified files are appended here
 */
void RecursiveFileWatcher::rescanDirectory(const QString &directory, QStringList *pCreatedFiles, QStringList *pDeletedFiles, QStringList *pChangedFiles)
{
  QDir dir(directory);
  if (!dir.exists()) {
    forgetSubtree(directory, pDeletedFiles);
    return;
  }
  mpWatcher->addPath(directory);

  QHash<QString, Stamp> stamps = mDirectories.value(directory);
  QSet<QString> seen;
  QStringList newSubDirectories;
  const QFileInfoList entries = dir.entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::NoSymLinks);
  for (const QFileInfo &entry : entries) {
    if (!isRelevant(entry)) {
      continue;
    }
    if (entry.isDir()) {
      if (!mDirectories.contains(entry.absoluteFilePath())) {
        newSubDirectories.append(entry.absoluteFilePath());
      }
      continue;
    }
    seen.insert(entry.fileName());
    const Stamp stamp = stampOf(entry);
    auto it = stamps.find(entry.fileName());
    if (it == stamps.end()) {
      stamps.insert(entry.fileName(), stamp);
      watchFile(entry.absoluteFilePath());
      pCreatedFiles->append(entry.absoluteFilePath());
    } else if (it->modified != stamp.modified || it->size != stamp.size) {
      *it = stamp;
      // A file replaced by a rename loses its watch, so re-add it.
      unwatchFile(entry.absoluteFilePath());
      watchFile(entry.absoluteFilePath());
      pChangedFiles->append(entry.absoluteFilePath());
    }
  }
  for (auto it = stamps.begin(); it != stamps.end();) {
    if (seen.contains(it.key())) {
      ++it;
      continue;
    }
    const QString filePath = directory + QStringLiteral("/") + it.key();
    unwatchFile(filePath);
    pDeletedFiles->append(filePath);
    it = stamps.erase(it);
  }
  mDirectories.insert(directory, stamps);

  for (const QString &subDirectory : newSubDirectories) {
    snapshotDirectory(subDirectory, pCreatedFiles);
  }
  const QStringList children = trackedChildren(directory);
  for (const QString &child : children) {
    if (!QDir(child).exists()) {
      forgetSubtree(child, pDeletedFiles);
    }
  }
}

/*!
 * \brief RecursiveFileWatcher::snapshotFileRoot
 * Records the state of a single-file root and starts watching it.
 * \param filePath root file to record
 */
void RecursiveFileWatcher::snapshotFileRoot(const QString &filePath)
{
  QFileInfo fileInfo(filePath);
  if (fileInfo.exists() && fileInfo.isFile()) {
    mFileStamps.insert(filePath, stampOf(fileInfo));
    watchFile(filePath);
  } else {
    mFileStamps.remove(filePath);
  }
}

/*!
 * \brief RecursiveFileWatcher::rescanFileRoot
 * Compares a single-file root with its snapshot and reports the difference.
 * \param filePath root file to scan
 * \param pCreatedFiles created files are appended here
 * \param pDeletedFiles deleted files are appended here
 * \param pChangedFiles modified files are appended here
 */
void RecursiveFileWatcher::rescanFileRoot(const QString &filePath, QStringList *pCreatedFiles, QStringList *pDeletedFiles, QStringList *pChangedFiles)
{
  QFileInfo fileInfo(filePath);
  if (!fileInfo.exists() || !fileInfo.isFile()) {
    if (mFileStamps.remove(filePath)) {
      pDeletedFiles->append(filePath);
    }
    unwatchFile(filePath);
    return;
  }

  const Stamp stamp = stampOf(fileInfo);
  auto it = mFileStamps.find(filePath);
  if (it == mFileStamps.end()) {
    mFileStamps.insert(filePath, stamp);
    watchFile(filePath);
    pCreatedFiles->append(filePath);
  } else if (it->modified != stamp.modified || it->size != stamp.size) {
    *it = stamp;
    unwatchFile(filePath);
    watchFile(filePath);
    pChangedFiles->append(filePath);
  } else {
    watchFile(filePath);
  }
}

/*!
 * \brief RecursiveFileWatcher::forgetSubtree
 * Stops watching a directory and everything below it.
 * \param root subtree root
 * \param pDeletedFiles when set, every file known there is reported as deleted
 */
void RecursiveFileWatcher::forgetSubtree(const QString &root, QStringList *pDeletedFiles)
{
  const QString prefix = root + QStringLiteral("/");
  const QStringList directories = mDirectories.keys();
  for (const QString &directory : directories) {
    if (directory != root && !directory.startsWith(prefix)) {
      continue;
    }
    const QHash<QString, Stamp> stamps = mDirectories.take(directory);
    mpWatcher->removePath(directory);
    mDirtyDirectories.remove(directory);
    for (auto it = stamps.constBegin(); it != stamps.constEnd(); ++it) {
      const QString filePath = directory + QStringLiteral("/") + it.key();
      unwatchFile(filePath);
      if (pDeletedFiles) {
        pDeletedFiles->append(filePath);
      }
    }
  }
}

/*!
 * \brief RecursiveFileWatcher::trackedChildren
 * Returns the directories tracked directly below a directory.
 * \param directory parent directory
 * \return immediate tracked subdirectories
 */
QStringList RecursiveFileWatcher::trackedChildren(const QString &directory) const
{
  const QString prefix = directory + QStringLiteral("/");
  QStringList children;
  for (auto it = mDirectories.constBegin(); it != mDirectories.constEnd(); ++it) {
    if (it.key().startsWith(prefix) && !it.key().mid(prefix.length()).contains(QLatin1Char('/'))) {
      children.append(it.key());
    }
  }
  return children;
}

/*!
 * \brief RecursiveFileWatcher::onDirectoryChanged
 * Marks a watched directory for rescan. The rescan is delayed so a burst of
 * changes is reported once.
 * \param directory directory reported by QFileSystemWatcher
 */
void RecursiveFileWatcher::onDirectoryChanged(const QString &directory)
{
  const QString absolute = QDir::cleanPath(directory);
  if (mDirectories.contains(absolute)) {
    mDirtyDirectories.insert(absolute);
  }
  if (mFileRootParents.contains(absolute)) {
    mDirtyFileRootParents.insert(absolute);
  }
  if (!mDirtyDirectories.isEmpty() || !mDirtyFileRootParents.isEmpty()) {
    mpFlushTimer->start();
  }
}

/*!
 * \brief RecursiveFileWatcher::onFileChanged
 * Marks the parent directory for rescan, because a rewrite can replace the
 * watched file.
 * \param filePath file reported by QFileSystemWatcher
 */
void RecursiveFileWatcher::onFileChanged(const QString &filePath)
{
  // The parent directory is rescanned, which also re-adds a watch dropped by a
  // rewrite through a rename.
  const QString directory = QDir::cleanPath(QFileInfo(filePath).absolutePath());
  if (mFileRoots.contains(QDir::cleanPath(filePath))) {
    mDirtyFileRootParents.insert(directory);
  } else if (mDirectories.contains(directory)) {
    mDirtyDirectories.insert(directory);
  }
  if (!mDirtyDirectories.isEmpty() || !mDirtyFileRootParents.isEmpty()) {
    mpFlushTimer->start();
  }
}

/*!
 * \brief RecursiveFileWatcher::flush
 * Rescans the dirty directories and single-file roots, then reports all
 * changes found in one batch.
 */
void RecursiveFileWatcher::flush()
{
  QStringList changedFiles;
  QStringList createdFiles;
  QStringList deletedFiles;

  while (!mDirtyDirectories.isEmpty()) {
    const QString directory = *mDirtyDirectories.constBegin();
    mDirtyDirectories.remove(directory);
    if (mDirectories.contains(directory)) {
      rescanDirectory(directory, &createdFiles, &deletedFiles, &changedFiles);
    }
  }

  while (!mDirtyFileRootParents.isEmpty()) {
    const QString parent = *mDirtyFileRootParents.constBegin();
    mDirtyFileRootParents.remove(parent);
    for (const QString &root : mFileRoots) {
      if (QFileInfo(root).absolutePath() == parent) {
        rescanFileRoot(root, &createdFiles, &deletedFiles, &changedFiles);
      }
    }
  }

  if (!changedFiles.isEmpty() || !createdFiles.isEmpty() || !deletedFiles.isEmpty()) {
    emit filesChanged(changedFiles, createdFiles, deletedFiles);
  }
}
