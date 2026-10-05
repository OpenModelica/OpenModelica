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

// Transparent read access to the omc Web Worker's VFS from the OMEdit main thread.
//
// On wasm omc runs in a Worker with its own (Emscripten) filesystem — the "OM
// VFS". OMEdit, on the main thread, reads many files with QFile/QFileInfo/QDir:
// the library index, installed-library sources, model files the editor opens, etc.
// Those live in the worker's VFS, not the page's MEMFS, so the reads fail.
//
// Rather than stage each file explicitly per feature, install a
// QAbstractFileEngineHandler: for any absolute path that is not already in the
// page MEMFS, hand back an engine that lazily fetches the bytes from the worker
// (synchronously, via the same nested-QEventLoop bridge as every other omc call)
// and serves them. So every QFile/QFileInfo read of a worker-owned file just works.
//
// Writes go the same way in reverse: buffered, then pushed to the worker on
// close/flush (omcWorkerWriteFile), so a model the GUI saves is the file omc reads.
// The push does not wait, so success means "handed over". Directory enumeration
// (QDir) is served via the worker's WASI fd_readdir (omcWorkerListDir).
#if defined(__EMSCRIPTEN__)

#include <QtCore/private/qabstractfileengine_p.h>
#include <QByteArray>
#include <QString>
#include <QStringList>
#include <QDir>
#include <QDirListing>
#include <cstring>
#include <memory>
#include <optional>
#include <utility>
#include <emscripten.h>
#include <emscripten/em_js.h>

// Defined in OMEditLIB/OMC/OMCProxy.cpp (shares the omc worker bridge).
QByteArray omcWorkerReadFile(const char *path);
QStringList omcWorkerListDir(const char *path);
bool omcWorkerWriteFile(const char *path, const QByteArray &data);
bool omcWorkerRemoveFile(const char *path);
bool omcWorkerRenameFile(const char *from, const char *to);

// True if the page MEMFS already has the path (then the default engine handles it).
EM_JS(int, omedit_memfs_exists, (const char *path), {
  try { return FS.analyzePath(UTF8ToString(path)).exists ? 1 : 0; }
  catch (e) { return 0; }
});

namespace {

// Iterates the names omcWorkerListDir returned for a worker directory.
class WorkerVfsIterator : public QAbstractFileEngineIterator
{
public:
  WorkerVfsIterator(const QString &path, QDirListing::IteratorFlags filters,
                    const QStringList &nameFilters, QStringList names)
    : QAbstractFileEngineIterator(path, filters, nameFilters), mNames(std::move(names)) {}

  bool advance() override
  {
    if (mIndex + 1 < mNames.size()) { ++mIndex; return true; }
    return false;
  }
  QString currentFileName() const override { return mNames.value(mIndex); }

private:
  QStringList mNames;
  int mIndex = -1;
};

class WorkerVfsFileEngine : public QAbstractFileEngine
{
public:
  explicit WorkerVfsFileEngine(const QString &fileName) : mName(fileName) {}

  bool open(QIODevice::OpenMode openMode,
            std::optional<QFile::Permissions> = std::nullopt) override
  {
    if (openMode & (QIODevice::WriteOnly | QIODevice::Append)) {
      const bool truncate = openMode & QIODevice::Truncate;
      if (truncate) {
        mData.clear();
      } else {
        ensureFetched();
      }
      mWriting = true;
      mFetched = true;
      mExists = true;
      mPos = (openMode & QIODevice::Append) ? mData.size() : 0;
      // Truncating creates the file even if nothing is ever written to it.
      mDirty = truncate;
      return true;
    }
    if (!ensureFetched()) return false;
    mPos = 0;
    return true;
  }
  bool close() override
  {
    bool ok = flush();
    mWriting = false;
    return ok;
  }

  // QFile flushes once itself and again as the engine closes; only push if dirty.
  bool flush() override
  {
    if (!mWriting || !mDirty) return true;
    if (!omcWorkerWriteFile(mName.toUtf8().constData(), mData)) return false;
    mDirty = false;
    return true;
  }

  qint64 write(const char *data, qint64 len) override
  {
    if (!mWriting || len < 0) return -1;
    if (mPos + len > mData.size()) mData.resize(mPos + len);
    memcpy(mData.data() + mPos, data, len);
    mPos += len;
    mDirty = true;
    return len;
  }

  // The store keys on the whole path: a directory exists when something is under it.
  bool mkdir(const QString &, bool, std::optional<QFile::Permissions> = std::nullopt) const override
  {
    return true;
  }

  // Without these QFile::remove/rename and QDir::rmdir fail on worker-owned paths,
  // which the cloud sync engine needs to propagate a deletion. rmdir removes the
  // whole subtree, since a store directory is only its keys.
  bool remove() override
  {
    const bool ok = omcWorkerRemoveFile(mName.toUtf8().constData());
    if (ok) invalidate();
    return ok;
  }

  bool rmdir(const QString &path, bool recurseParents) const override
  {
    if (recurseParents) return false;
    return omcWorkerRemoveFile(path.toUtf8().constData());
  }

  // The store overwrites on write, so an overwriting rename is the same operation.
  // QSaveFile's temp-then-rename (how the sync manifest is written) needs it.
  bool rename(const QString &newName) override { return renameOverwrite(newName); }

  bool renameOverwrite(const QString &newName) override
  {
    if (!omcWorkerRenameFile(mName.toUtf8().constData(), newName.toUtf8().constData())) {
      return false;
    }
    setFileName(newName);
    return true;
  }

  qint64 size() const override { ensureFetched(); return mExists ? mData.size() : 0; }
  qint64 pos() const override { return mPos; }
  bool seek(qint64 p) override
  {
    if (p < 0 || (!mWriting && p > mData.size())) return false;
    mPos = p;
    return true;
  }
  bool setSize(qint64 n) override
  {
    if (!mWriting || n < 0) return false;
    mData.resize(n);
    if (mPos > n) mPos = n;
    mDirty = true;
    return true;
  }
  bool isSequential() const override { return false; }

  qint64 read(char *data, qint64 maxlen) override
  {
    if (!mExists) return -1;
    qint64 n = qMin<qint64>(maxlen, mData.size() - mPos);
    if (n <= 0) return 0;
    memcpy(data, mData.constData() + mPos, n);
    mPos += n;
    return n;
  }

  FileFlags fileFlags(FileFlags type = FileInfoAll) const override
  {
    // Writable, so QFileInfo::isWritable() on a save path must not say no.
    const FileFlags perms = ReadOwnerPerm | ReadUserPerm | ReadGroupPerm | ReadOtherPerm
                            | WriteOwnerPerm | WriteUserPerm | WriteGroupPerm | WriteOtherPerm;
    FileFlags f;
    if (ensureFetched()) {
      f |= ExistsFlag | FileType | perms;
    } else if (ensureDirListed()) {
      f |= ExistsFlag | DirectoryType | perms;
    }
    return f & type;
  }

  IteratorUniquePtr beginEntryList(const QString &path, QDirListing::IteratorFlags filters,
                                   const QStringList &filterNames) override
  {
    ensureDirListed();
    QStringList names;
    for (const QString &e : std::as_const(mDirEntries)) {
      names << (e.endsWith(QLatin1Char('/')) ? e.left(e.size() - 1) : e);
    }
    return std::make_unique<WorkerVfsIterator>(path, filters, filterNames, names);
  }

  bool caseSensitive() const override { return true; }
  bool isRelativePath() const override { return false; }

  QString fileName(FileName file = DefaultName) const override
  {
    int slash = mName.lastIndexOf(QLatin1Char('/'));
    switch (file) {
      case BaseName:          return slash >= 0 ? mName.mid(slash + 1) : mName;
      case PathName:
      case AbsolutePathName:  return slash > 0 ? mName.left(slash) : QStringLiteral("/");
      default:                return mName;
    }
  }

  void setFileName(const QString &file) override
  {
    mName = file;
    invalidate();
  }

private:
  void invalidate()
  {
    mFetched = false; mExists = false; mData.clear(); mPos = 0;
    mDirFetched = false; mDirEntries.clear(); mWriting = false; mDirty = false;
  }

  bool ensureFetched() const
  {
    if (!mFetched) {
      mFetched = true;
      mData = omcWorkerReadFile(mName.toUtf8().constData());
      mExists = !mData.isNull();
    }
    return mExists;
  }

  // Lazily list the path as a directory (empty ⇒ not a worker directory).
  bool ensureDirListed() const
  {
    if (!mDirFetched) {
      mDirFetched = true;
      mDirEntries = omcWorkerListDir(mName.toUtf8().constData());
    }
    return !mDirEntries.isEmpty();
  }

  QString mName;
  mutable QByteArray mData;
  mutable bool mFetched = false;
  mutable bool mExists = false;
  mutable QStringList mDirEntries;
  mutable bool mDirFetched = false;
  qint64 mPos = 0;
  bool mWriting = false;
  bool mDirty = false;
};

class WorkerVfsHandler : public QAbstractFileEngineHandler
{
public:
  std::unique_ptr<QAbstractFileEngine> create(const QString &fileName) const override
  {
    // Only absolute paths (Qt resources start with ':', relative paths don't start
    // with '/'). If the page MEMFS already has it, let the default engine serve it.
    if (fileName.isEmpty() || fileName.at(0) != QLatin1Char('/')) return nullptr;
    // Page-local tree: settings, the cloud sync manifests, the session list. These
    // are the main thread's own and are mirrored to IndexedDB, so they must stay in
    // MEMFS — the "already exists" test below cannot see a file being created.
    if (fileName.startsWith(QLatin1String("/persist/"))) return nullptr;
    if (omedit_memfs_exists(fileName.toUtf8().constData())) return nullptr;
    return std::make_unique<WorkerVfsFileEngine>(fileName);
  }
};

WorkerVfsHandler *gWorkerVfsHandler = nullptr;

} // namespace

// Install the handler once. Safe to call before the worker is up: reads just
// report "not found" until omc_worker_ready (omcWorkerReadFile guards on it).
void omcInstallWorkerVfsFileEngine()
{
  if (!gWorkerVfsHandler) gWorkerVfsHandler = new WorkerVfsHandler();
}

#endif // __EMSCRIPTEN__
