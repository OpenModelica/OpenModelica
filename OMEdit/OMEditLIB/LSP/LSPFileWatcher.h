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

#pragma once

#include "LSP/LSPProtocol.h"

#include <QObject>
#include <QHash>
#include <QSet>
#include <QStringList>

class QFileSystemWatcher;
class QTimer;

/*!
 * \class LSPFileWatcher
 * \brief Watches library roots for Modelica files changed outside OMEdit and
 * reports them as LSP file events.
 *
 * A language server indexes the files it loaded from disk. Edits made in OMEdit
 * reach it through textDocument/didChange, but a git checkout, an external
 * editor or a script leaves that index stale. This watcher spots such changes
 * so the client can send workspace/didChangeWatchedFiles.
 *
 * QFileSystemWatcher reports that something in a directory changed, not what,
 * so every watched directory keeps a snapshot of the files it held; a change is
 * classified by diffing the directory against its snapshot.
 */
class LSPFileWatcher : public QObject
{
  Q_OBJECT
public:
  explicit LSPFileWatcher(QObject *pParent = nullptr);

  void setPatterns(const QStringList &globPatterns);
  void setRoots(const QStringList &roots);

signals:
  void filesChanged(QList<LSP::FileEvent> events);
  //! Emitted once when so many files are watched that in-place edits stop being detected.
  void watchLimitReached(int limit);

private slots:
  void onDirectoryChanged(const QString &directory);
  void onFileChanged(const QString &filePath);
  void flush();

private:
  //! What a file looked like when its directory was last scanned.
  struct Stamp {
    qint64 modified = 0;
    qint64 size = 0;
  };

  QFileSystemWatcher *mpWatcher;
  QTimer *mpFlushTimer;
  QStringList mRoots;
  //! File extensions taken from the registered glob patterns. Empty means every file.
  QStringList mSuffixes;
  //! directory -> file name -> stamp, for every directory being watched.
  QHash<QString, QHash<QString, Stamp>> mDirectories;
  //! Files watched individually, which is what detects a rewrite in place.
  QSet<QString> mWatchedFiles;
  QSet<QString> mDirtyDirectories;
  bool mWatchLimitReported;

  bool matches(const QString &fileName) const;
  void watchFile(const QString &filePath);
  void unwatchFile(const QString &filePath);
  void snapshotDirectory(const QString &directory, QList<LSP::FileEvent> *pEvents);
  void rescanDirectory(const QString &directory, QList<LSP::FileEvent> *pEvents);
  void forgetSubtree(const QString &root, QList<LSP::FileEvent> *pEvents);
  QStringList trackedChildren(const QString &directory) const;

  static QString uriOf(const QString &filePath);
};
