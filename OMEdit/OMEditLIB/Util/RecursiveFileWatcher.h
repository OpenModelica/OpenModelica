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

#pragma once

#include <QHash>
#include <QObject>
#include <QSet>
#include <QStringList>

class QFileInfo;
class QFileSystemWatcher;
class QTimer;

class RecursiveFileWatcher : public QObject
{
  Q_OBJECT
public:
  explicit RecursiveFileWatcher(QObject *pParent = nullptr);

  void setRoots(const QStringList &roots);
  bool hasChangedSinceSnapshot(const QString &filePath) const;
  void ignorePath(const QString &filePath);
  void resync();
  void rescan();

signals:
  void filesChanged(const QStringList &changedFiles, const QStringList &createdFiles, const QStringList &deletedFiles);
  void watchLimitReached(int limit);

protected:
  virtual bool isRelevant(const QFileInfo &fileInfo) const;

private slots:
  void onDirectoryChanged(const QString &directory);
  void onFileChanged(const QString &filePath);
  void flush();

private:
  struct Stamp {
    qint64 modified = 0;
    qint64 size = 0;
  };

  static Stamp stampOf(const QFileInfo &fileInfo);
  QFileSystemWatcher *mpWatcher;
  QTimer *mpFlushTimer;
  QStringList mDirectoryRoots;
  QStringList mFileRoots;
  QHash<QString, QHash<QString, Stamp>> mDirectories;
  QHash<QString, Stamp> mFileStamps;
  QSet<QString> mFileRootParents;
  QSet<QString> mWatchedFiles;
  QSet<QString> mDirtyDirectories;
  QSet<QString> mDirtyFileRootParents;
  bool mWatchLimitReported = false;

  void watchFile(const QString &filePath);
  void unwatchFile(const QString &filePath);
  void snapshotDirectory(const QString &directory, QStringList *pCreatedFiles);
  void rescanDirectory(const QString &directory, QStringList *pCreatedFiles, QStringList *pDeletedFiles, QStringList *pChangedFiles);
  void snapshotFileRoot(const QString &filePath);
  void rescanFileRoot(const QString &filePath, QStringList *pCreatedFiles, QStringList *pDeletedFiles, QStringList *pChangedFiles);
  void forgetSubtree(const QString &root, QStringList *pDeletedFiles);
  QStringList trackedChildren(const QString &directory) const;
};
