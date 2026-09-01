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

// The working-copy cache for the web target, over IndexedDB. Keys are the
// absolute working-copy paths, so a mount's contents are one key range and the
// restore needs no index of its own.
//
// Nothing here runs during startup, which is what makes IndexedDB usable at all.
// The callbacks arrive in JS frames, so the work they trigger is deferred to a
// fresh turn of the event loop before it touches the omc worker: reaching it
// needs an Asyncify suspend, and suspending inside a JS frame hangs the page.

#if defined(__EMSCRIPTEN__)

#include "Cloud/CloudCache.h"
#include "Cloud/CloudTypes.h"

#include <QByteArray>
#include <QFile>
#include <QHash>
#include <QList>
#include <QPair>
#include <QString>
#include <QStringList>
#include <QTimer>

#include <emscripten.h>
#include <emscripten/em_js.h>

#include <cstdlib>

// Defined in OMEditLIB/OMC/OMCProxy.cpp; one round trip for the whole tree.
int omcWorkerWriteFiles(const QList<QPair<QString, QByteArray> > &files);

EM_JS(void, omedit_cache_open, (), {
  if (Module.__omeditCacheOpen) return;
  Module.__omeditCacheOpen = function () {
    if (!Module.__omeditCacheDb) {
      Module.__omeditCacheDb = new Promise((resolve, reject) => {
        let request;
        try {
          request = indexedDB.open("omedit-cloud-cache", 1);
        } catch (e) {
          reject(e);
          return;
        }
        request.onupgradeneeded = () => request.result.createObjectStore("files");
        request.onsuccess = () => resolve(request.result);
        request.onerror = () => reject(request.error);
      });
    }
    return Module.__omeditCacheDb;
  };
});

EM_JS(void, omedit_cache_batch_add, (const char *key, const char *bytes, int length), {
  if (!Module.__omeditCacheBatch) Module.__omeditCacheBatch = [];
  Module.__omeditCacheBatch.push({ key: UTF8ToString(key), data: HEAPU8.slice(bytes, bytes + length) });
});

// One transaction for the whole mount: the stale range goes and the new contents
// arrive together, so an interrupted write cannot leave a half-replaced package.
EM_JS(void, omedit_cache_batch_commit, (const char *prefix), {
  const entries = Module.__omeditCacheBatch || [];
  Module.__omeditCacheBatch = null;
  const range = UTF8ToString(prefix);
  Module.__omeditCacheOpen().then((db) => {
    const store = db.transaction("files", "readwrite").objectStore("files");
    store.delete(IDBKeyRange.bound(range, range + String.fromCharCode(0xffff)));
    for (const entry of entries) store.put(entry.data, entry.key);
  }).catch((e) => console.warn("[OMEdit] could not cache the working copy", e));
});

EM_JS(void, omedit_cache_forget, (const char *prefix), {
  const range = UTF8ToString(prefix);
  Module.__omeditCacheOpen().then((db) => {
    db.transaction("files", "readwrite").objectStore("files").delete(IDBKeyRange.bound(range, range + String.fromCharCode(0xffff)));
  }).catch((e) => console.warn("[OMEdit] could not clear the cache", e));
});

EM_JS(void, omedit_cache_read_prefix, (const char *prefix, int token), {
  const range = UTF8ToString(prefix);
  Module.__omeditCacheEntries = [];
  Module.__omeditCacheOpen().then((db) => new Promise((resolve, reject) => {
    const request = db.transaction("files", "readonly").objectStore("files")
                      .openCursor(IDBKeyRange.bound(range, range + String.fromCharCode(0xffff)));
    const found = [];
    request.onsuccess = () => {
      const cursor = request.result;
      if (!cursor) { resolve(found); return; }
      found.push({ key: cursor.key, data: cursor.value });
      cursor.continue();
    };
    request.onerror = () => reject(request.error);
  })).then((found) => {
    Module.__omeditCacheEntries = found;
    Module._omedit_cache_read_done(token);
  }).catch((e) => {
    console.warn("[OMEdit] could not read the cache", e);
    Module.__omeditCacheEntries = [];
    Module._omedit_cache_read_done(token);
  });
});

EM_JS(int, omedit_cache_entry_count, (), {
  return (Module.__omeditCacheEntries || []).length;
});

EM_JS(char *, omedit_cache_entry_key, (int index), {
  return stringToNewUTF8(Module.__omeditCacheEntries[index].key);
});

EM_JS(int, omedit_cache_entry_size, (int index), {
  const data = Module.__omeditCacheEntries[index].data;
  return data ? data.byteLength : 0;
});

EM_JS(void, omedit_cache_entry_copy, (int index, char *destination), {
  const data = Module.__omeditCacheEntries[index].data;
  HEAPU8.set(data instanceof Uint8Array ? data : new Uint8Array(data), destination);
});

EM_JS(void, omedit_cache_entries_clear, (), {
  Module.__omeditCacheEntries = null;
});

namespace {

QHash<int, std::function<void(int)>> gPending;
int gNextToken = 1;

QString prefixOf(const CloudMount &mount)
{
  return mount.localRoot + QLatin1Char('/');
}

void collect(const QString &directory, QList<QPair<QString, QByteArray> > *pFiles)
{
  const QStringList names = cloudListDirectory(directory);
  for (const QString &raw : names) {
    const bool isFolder = raw.endsWith(QLatin1Char('/'));
    const QString name = isFolder ? raw.left(raw.size() - 1) : raw;
    if (name.isEmpty()) {
      continue;
    }
    const QString path = directory + QLatin1Char('/') + name;
    if (isFolder) {
      collect(path, pFiles);
      continue;
    }
    QFile file(path);
    if (file.open(QIODevice::ReadOnly)) {
      pFiles->append(qMakePair(path, file.readAll()));
    }
  }
}

//! Hand the entries JS collected to the omc worker, in one round trip.
void drainRestore(int token)
{
  const std::function<void(int)> done = gPending.take(token);
  QList<QPair<QString, QByteArray> > files;
  const int count = omedit_cache_entry_count();
  for (int i = 0; i < count; ++i) {
    char *key = omedit_cache_entry_key(i);
    const QString path = QString::fromUtf8(key);
    free(key);
    QByteArray contents(omedit_cache_entry_size(i), '\0');
    if (!contents.isEmpty()) {
      omedit_cache_entry_copy(i, contents.data());
    }
    files.append(qMakePair(path, contents));
  }
  omedit_cache_entries_clear();
  int written = 0;
  if (!files.isEmpty()) {
    written = omcWorkerWriteFiles(files);
  }
  if (done) {
    done(written < 0 ? 0 : written);
  }
}

} // namespace

// Called from the IndexedDB callback, so it only hands the work to the event
// loop; the drain talks to the omc worker.
extern "C" EMSCRIPTEN_KEEPALIVE void omedit_cache_read_done(int token)
{
  QTimer::singleShot(0, [token]() { drainRestore(token); });
}

bool CloudCache::isAvailable()
{
  return true;
}

void CloudCache::save(const CloudMount &mount)
{
  if (!mount.isValid()) {
    return;
  }
  omedit_cache_open();
  QList<QPair<QString, QByteArray> > files;
  collect(mount.localRoot, &files);
  if (files.isEmpty()) {
    // Either there is nothing worth keeping or the working copy could not be
    // read; neither is a reason to throw away what the cache already holds.
    return;
  }
  for (const auto &file : std::as_const(files)) {
    omedit_cache_batch_add(file.first.toUtf8().constData(), file.second.constData(), file.second.size());
  }
  omedit_cache_batch_commit(prefixOf(mount).toUtf8().constData());
}

void CloudCache::restore(const CloudMount &mount, const std::function<void(int)> &done)
{
  if (!mount.isValid()) {
    if (done) {
      QTimer::singleShot(0, [done]() { done(0); });
    }
    return;
  }
  omedit_cache_open();
  const int token = gNextToken++;
  gPending.insert(token, done);
  omedit_cache_read_prefix(prefixOf(mount).toUtf8().constData(), token);
}

void CloudCache::forget(const CloudMount &mount)
{
  if (!mount.isValid()) {
    return;
  }
  omedit_cache_open();
  omedit_cache_forget(prefixOf(mount).toUtf8().constData());
}

#endif // __EMSCRIPTEN__
