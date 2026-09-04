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

#include "LSP/LSPFileWatcher.h"

#include <QDateTime>
#include <QDir>
#include <QFileInfo>
#include <QFileSystemWatcher>
#include <QRegularExpression>
#include <QTimer>
#include <QUrl>

namespace {
  // Watching a file individually is what detects a rewrite in place, but each
  // watch costs a kernel handle. Past this many files only their directories
  // stay watched, which still reports files added, removed or replaced by a
  // rename — the shape of a checkout — just not a rewrite in place.
  const int kMaxWatchedFiles = 20000;
  // A checkout or a build touches many files at once. Waiting for the burst to
  // end reports it as one batch instead of one notification per file.
  const int kFlushDelayMs = 300;
}

LSPFileWatcher::LSPFileWatcher(QObject *pParent)
  : QObject(pParent), mpWatcher(new QFileSystemWatcher(this)), mpFlushTimer(new QTimer(this)), mWatchLimitReported(false)
{
  mpFlushTimer->setSingleShot(true);
  mpFlushTimer->setInterval(kFlushDelayMs);
  connect(mpFlushTimer, &QTimer::timeout, this, &LSPFileWatcher::flush);
  connect(mpWatcher, &QFileSystemWatcher::directoryChanged, this, &LSPFileWatcher::onDirectoryChanged);
  connect(mpWatcher, &QFileSystemWatcher::fileChanged, this, &LSPFileWatcher::onFileChanged);
}

/*!
 * \brief LSPFileWatcher::setPatterns
 * Takes the file extensions to watch from the glob patterns the server
 * registered. Only the extension part of a "*.{mo,mos}"-style pattern is
 * honoured; any pattern that is not of that shape falls back to watching every
 * file, which is correct but noisier.
 * \param globPatterns glob patterns from the registration
 */
void LSPFileWatcher::setPatterns(const QStringList &globPatterns)
{
  static const QRegularExpression extensionList(QStringLiteral("\\*\\.\\{([^}]+)\\}$"));
  static const QRegularExpression singleExtension(QStringLiteral("\\*\\.([A-Za-z0-9_]+)$"));

  QStringList suffixes;
  for (const QString &pattern : globPatterns) {
    QRegularExpressionMatch match = extensionList.match(pattern);
    if (match.hasMatch()) {
      const QStringList parts = match.captured(1).split(QLatin1Char(','), Qt::SkipEmptyParts);
      for (const QString &part : parts) {
        const QString suffix = part.trimmed();
        if (!suffix.isEmpty() && !suffixes.contains(suffix)) {
          suffixes.append(suffix);
        }
      }
      continue;
    }
    match = singleExtension.match(pattern);
    if (match.hasMatch()) {
      if (!suffixes.contains(match.captured(1))) {
        suffixes.append(match.captured(1));
      }
      continue;
    }
    // An unrecognised pattern: watch everything rather than silently ignore it.
    suffixes.clear();
    break;
  }
  mSuffixes = suffixes;
}

/*!
 * \brief LSPFileWatcher::setRoots
 * Watches the given library roots, dropping the ones that are no longer in the
 * list. Adding a root does not report its files as created: the server loads
 * them itself when the root is announced to it.
 * \param roots library root directories
 */
void LSPFileWatcher::setRoots(const QStringList &roots)
{
  QStringList absolutes;
  for (const QString &root : roots) {
    const QString absolute = QDir::cleanPath(QFileInfo(root).absoluteFilePath());
    if (!absolute.isEmpty() && !absolutes.contains(absolute)) {
      absolutes.append(absolute);
    }
  }
  // A root inside another root is already covered by the outer one's recursive
  // scan, and keeping both would let dropping the outer one unwatch the inner
  // one that is still in the list.
  QStringList normalized;
  for (const QString &absolute : absolutes) {
    bool nested = false;
    for (const QString &other : absolutes) {
      if (other != absolute && absolute.startsWith(other + QStringLiteral("/"))) {
        nested = true;
        break;
      }
    }
    if (!nested) {
      normalized.append(absolute);
    }
  }
  if (normalized == mRoots) {
    return;
  }
  for (const QString &root : mRoots) {
    if (!normalized.contains(root)) {
      forgetSubtree(root, nullptr);
    }
  }
  const QStringList previous = mRoots;
  mRoots = normalized;
  for (const QString &root : mRoots) {
    if (!previous.contains(root)) {
      snapshotDirectory(root, nullptr);
    }
  }
}

bool LSPFileWatcher::matches(const QString &fileName) const
{
  if (mSuffixes.isEmpty()) {
    return true;
  }
  const QString suffix = QFileInfo(fileName).suffix();
  for (const QString &candidate : mSuffixes) {
    if (suffix.compare(candidate, Qt::CaseInsensitive) == 0) {
      return true;
    }
  }
  return false;
}

void LSPFileWatcher::watchFile(const QString &filePath)
{
  if (mWatchedFiles.contains(filePath)) {
    return;
  }
  if (mWatchedFiles.size() >= kMaxWatchedFiles) {
    if (!mWatchLimitReported) {
      mWatchLimitReported = true;
      emit watchLimitReached(kMaxWatchedFiles);
    }
    return;
  }
  if (mpWatcher->addPath(filePath)) {
    mWatchedFiles.insert(filePath);
  }
}

void LSPFileWatcher::unwatchFile(const QString &filePath)
{
  if (mWatchedFiles.remove(filePath)) {
    mpWatcher->removePath(filePath);
  }
}

/*!
 * \brief LSPFileWatcher::snapshotDirectory
 * Watches a directory and everything below it, recording what each directory
 * holds so a later scan can tell what changed.
 * \param directory directory to watch
 * \param pEvents when set, every file found is reported as created
 */
void LSPFileWatcher::snapshotDirectory(const QString &directory, QList<LSP::FileEvent> *pEvents)
{
  QDir dir(directory);
  if (!dir.exists()) {
    return;
  }
  if (!mDirectories.contains(directory)) {
    mpWatcher->addPath(directory);
  }
  // Symbolic links are not followed: a link back into the tree would recurse
  // forever, and the target is watched anyway when it lives under a root.
  const QFileInfoList entries = dir.entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::NoSymLinks);
  // The snapshot is built in a local and stored in one go. Holding a reference
  // into mDirectories across the recursion below would dangle: inserting a
  // subdirectory can rehash the table.
  QHash<QString, Stamp> stamps;
  QStringList subDirectories;
  for (const QFileInfo &entry : entries) {
    if (entry.isDir()) {
      subDirectories.append(entry.absoluteFilePath());
      continue;
    }
    if (!matches(entry.fileName())) {
      continue;
    }
    Stamp stamp;
    stamp.modified = entry.lastModified().toMSecsSinceEpoch();
    stamp.size = entry.size();
    stamps.insert(entry.fileName(), stamp);
    watchFile(entry.absoluteFilePath());
    if (pEvents) {
      LSP::FileEvent event;
      event.uri = uriOf(entry.absoluteFilePath());
      event.type = LSP::FileEvent::Created;
      pEvents->append(event);
    }
  }
  mDirectories.insert(directory, stamps);
  for (const QString &subDirectory : subDirectories) {
    snapshotDirectory(subDirectory, pEvents);
  }
}

/*!
 * \brief LSPFileWatcher::rescanDirectory
 * Diffs a directory against its snapshot and appends what changed.
 * \param directory directory to scan
 * \param pEvents events are appended here
 */
void LSPFileWatcher::rescanDirectory(const QString &directory, QList<LSP::FileEvent> *pEvents)
{
  QDir dir(directory);
  if (!dir.exists()) {
    forgetSubtree(directory, pEvents);
    return;
  }
  // A copy, written back below: snapshotDirectory() inserts into mDirectories,
  // which can rehash it and invalidate any reference held into it here.
  QHash<QString, Stamp> stamps = mDirectories.value(directory);
  QSet<QString> seen;
  QStringList newSubDirectories;
  const QFileInfoList entries = dir.entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::NoSymLinks);
  for (const QFileInfo &entry : entries) {
    if (entry.isDir()) {
      const QString subDirectory = entry.absoluteFilePath();
      if (!mDirectories.contains(subDirectory)) {
        // A directory that appeared: everything in it is new to the server.
        newSubDirectories.append(subDirectory);
      }
      continue;
    }
    if (!matches(entry.fileName())) {
      continue;
    }
    seen.insert(entry.fileName());
    Stamp stamp;
    stamp.modified = entry.lastModified().toMSecsSinceEpoch();
    stamp.size = entry.size();
    LSP::FileEvent event;
    event.uri = uriOf(entry.absoluteFilePath());
    auto it = stamps.find(entry.fileName());
    if (it == stamps.end()) {
      stamps.insert(entry.fileName(), stamp);
      watchFile(entry.absoluteFilePath());
      event.type = LSP::FileEvent::Created;
      pEvents->append(event);
    } else if (it->modified != stamp.modified || it->size != stamp.size) {
      *it = stamp;
      // A file replaced by a rename loses its watch, so re-add it.
      watchFile(entry.absoluteFilePath());
      event.type = LSP::FileEvent::Changed;
      pEvents->append(event);
    }
  }
  for (auto it = stamps.begin(); it != stamps.end();) {
    if (seen.contains(it.key())) {
      ++it;
      continue;
    }
    const QString filePath = directory + QStringLiteral("/") + it.key();
    unwatchFile(filePath);
    LSP::FileEvent event;
    event.uri = uriOf(filePath);
    event.type = LSP::FileEvent::Deleted;
    pEvents->append(event);
    it = stamps.erase(it);
  }
  mDirectories.insert(directory, stamps);
  for (const QString &subDirectory : newSubDirectories) {
    snapshotDirectory(subDirectory, pEvents);
  }
  // A removed subdirectory takes its files with it.
  const QStringList children = trackedChildren(directory);
  for (const QString &child : children) {
    if (!QDir(child).exists()) {
      forgetSubtree(child, pEvents);
    }
  }
}

/*!
 * \brief LSPFileWatcher::forgetSubtree
 * Stops watching a directory and everything below it.
 * \param root subtree root
 * \param pEvents when set, every file that was known there is reported as deleted
 */
void LSPFileWatcher::forgetSubtree(const QString &root, QList<LSP::FileEvent> *pEvents)
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
      if (pEvents) {
        LSP::FileEvent event;
        event.uri = uriOf(filePath);
        event.type = LSP::FileEvent::Deleted;
        pEvents->append(event);
      }
    }
  }
}

QStringList LSPFileWatcher::trackedChildren(const QString &directory) const
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

void LSPFileWatcher::onDirectoryChanged(const QString &directory)
{
  if (mDirectories.contains(directory)) {
    mDirtyDirectories.insert(directory);
    mpFlushTimer->start();
  }
}

void LSPFileWatcher::onFileChanged(const QString &filePath)
{
  // The file itself is not diffed here: its directory is, which also re-adds
  // the watch that a rewrite by rename dropped.
  const QString directory = QFileInfo(filePath).absolutePath();
  if (mDirectories.contains(directory)) {
    mDirtyDirectories.insert(directory);
    mpFlushTimer->start();
  }
}

void LSPFileWatcher::flush()
{
  QList<LSP::FileEvent> events;
  while (!mDirtyDirectories.isEmpty()) {
    const QString directory = *mDirtyDirectories.constBegin();
    mDirtyDirectories.remove(directory);
    if (!mDirectories.contains(directory)) {
      continue;
    }
    rescanDirectory(directory, &events);
  }
  if (!events.isEmpty()) {
    emit filesChanged(events);
  }
}

QString LSPFileWatcher::uriOf(const QString &filePath)
{
  return QUrl::fromLocalFile(filePath).toString();
}
