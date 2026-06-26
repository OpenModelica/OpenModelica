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
// Read-only: writes fall through (return failure). Directory enumeration (QDir)
// is served via the worker's WASI fd_readdir (omcWorkerListDir).
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
    if (openMode & QIODevice::WriteOnly) return false;
    if (!ensureFetched()) return false;
    mPos = 0;
    return true;
  }
  bool close() override { return true; }

  qint64 size() const override { ensureFetched(); return mExists ? mData.size() : 0; }
  qint64 pos() const override { return mPos; }
  bool seek(qint64 p) override { if (p < 0 || p > mData.size()) return false; mPos = p; return true; }
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
    FileFlags f;
    if (ensureFetched()) {
      f |= ExistsFlag | FileType;
      f |= ReadOwnerPerm | ReadUserPerm | ReadGroupPerm | ReadOtherPerm;
    } else if (ensureDirListed()) {
      f |= ExistsFlag | DirectoryType;
      f |= ReadOwnerPerm | ReadUserPerm | ReadGroupPerm | ReadOtherPerm;
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
    mName = file; mFetched = false; mExists = false; mData.clear(); mPos = 0;
    mDirFetched = false; mDirEntries.clear();
  }

private:
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
};

class WorkerVfsHandler : public QAbstractFileEngineHandler
{
public:
  std::unique_ptr<QAbstractFileEngine> create(const QString &fileName) const override
  {
    // Only absolute paths (Qt resources start with ':', relative paths don't start
    // with '/'). If the page MEMFS already has it, let the default engine serve it.
    if (fileName.isEmpty() || fileName.at(0) != QLatin1Char('/')) return nullptr;
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
