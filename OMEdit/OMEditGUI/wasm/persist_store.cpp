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

// Persistence for the web target, over localStorage. The page filesystem and the
// omc worker's VFS are both in memory, so the tree under /persist (settings, the
// mount list, the sync manifests) is mirrored into browser storage; tokens get
// keys of their own so clearing one does not clear the other.
//
// localStorage and not IndexedDB because restore() must run before QSettings is
// first read - during startup - and waiting on IndexedDB there means an Asyncify
// suspend, which hangs the application. Working-copy contents are too big for
// this store and belong in IndexedDB, which is fine long after startup.
//
// /persist stays in the page MEMFS; worker_vfs_engine.cpp excludes that prefix.

#if defined(__EMSCRIPTEN__)

#include "Util/PersistentStorage.h"

#include <QByteArray>
#include <QCoreApplication>
#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QHash>
#include <QStringList>
#include <QTimer>

#include <emscripten.h>
#include <emscripten/em_js.h>

#include <cstdlib>

// Every key this application owns, so clearing site data by hand is predictable
// and so nothing else on the origin is disturbed.
EM_JS(char *, omedit_storage_keys, (const char *prefix), {
  const wanted = UTF8ToString(prefix);
  const keys = [];
  try {
    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      if (key && key.startsWith(wanted)) keys.push(key.slice(wanted.length));
    }
  } catch (e) {
    // Private windows and blocked site data; the session runs without persistence.
    console.warn("[OMEdit] no browser storage; nothing will survive a reload", e);
  }
  return stringToNewUTF8(keys.join("\n"));
});

EM_JS(char *, omedit_storage_get, (const char *key), {
  try {
    return stringToNewUTF8(localStorage.getItem(UTF8ToString(key)) || "");
  } catch (e) {
    return stringToNewUTF8("");
  }
});

EM_JS(void, omedit_storage_set, (const char *key, const char *value), {
  try {
    localStorage.setItem(UTF8ToString(key), UTF8ToString(value));
  } catch (e) {
    // Quota exceeded, or storage blocked. Losing this costs the user their
    // settings on the next reload, not their work.
    console.warn("[OMEdit] could not store", UTF8ToString(key), e);
  }
});

EM_JS(void, omedit_storage_remove, (const char *key), {
  try { localStorage.removeItem(UTF8ToString(key)); } catch (e) { /* blocked */ }
});

//! Restore the tree straight into the page filesystem. Not QDir/QFile: this runs
//! before QApplication exists.
EM_JS(int, omedit_storage_restore_tree, (const char *prefix, const char *root), {
  const wanted = UTF8ToString(prefix);
  const base = UTF8ToString(root);
  let restored = 0;
  try {
    FS.mkdirTree(base);
  } catch (e) {
    // already there
  }
  let keys = [];
  try {
    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      if (key && key.startsWith(wanted)) keys.push(key);
    }
  } catch (e) {
    console.warn("[OMEdit] no browser storage; nothing will survive a reload", e);
    return 0;
  }
  for (const key of keys) {
    const relative = key.slice(wanted.length);
    // A key is a relative path; anything climbing out of the tree is not ours.
    if (!relative || relative.startsWith("/") || relative.includes("..")) continue;
    const path = base + "/" + relative;
    try {
      const slash = path.lastIndexOf("/");
      if (slash > 0) FS.mkdirTree(path.slice(0, slash));
      const encoded = localStorage.getItem(key) || "";
      const binary = atob(encoded);
      const bytes = new Uint8Array(binary.length);
      for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
      FS.writeFile(path, bytes);
      restored++;
    } catch (e) {
      console.warn("[OMEdit] could not restore", relative, e);
    }
  }
  return restored;
});

namespace {

const QLatin1String kPersistRoot("/persist");
const char *const kFilePrefix = "omedit/persist/";
const char *const kAuthPrefix = "omedit/auth/";

QTimer *gSnapshotTimer = nullptr;
QHash<QString, QByteArray> gSecrets;
bool gSecretsLoaded = false;

QString storageGet(const QString &key)
{
  char *raw = omedit_storage_get(key.toUtf8().constData());
  const QString value = QString::fromUtf8(raw);
  free(raw);
  return value;
}

QStringList storageKeys(const char *prefix)
{
  char *raw = omedit_storage_keys(prefix);
  const QString joined = QString::fromUtf8(raw);
  free(raw);
  return joined.isEmpty() ? QStringList() : joined.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
}

//! Every file under /persist, as paths relative to it.
QStringList persistedFiles()
{
  QStringList relative;
  QDirIterator it(kPersistRoot, QDir::Files, QDirIterator::Subdirectories);
  const int prefix = QString(kPersistRoot).size() + 1;
  while (it.hasNext()) {
    relative << it.next().mid(prefix);
  }
  return relative;
}

//! Cheap stand-in for a change notification: path, size and mtime of every file.
QByteArray treeFingerprint()
{
  QByteArray fingerprint;
  QStringList relatives = persistedFiles();
  relatives.sort();
  for (const QString &relative : std::as_const(relatives)) {
    const QFileInfo info(kPersistRoot + QLatin1Char('/') + relative);
    fingerprint += relative.toUtf8() + ':' + QByteArray::number(info.size()) + ':'
                   + QByteArray::number(info.lastModified().toMSecsSinceEpoch()) + '\n';
  }
  return fingerprint;
}

void loadSecrets()
{
  if (gSecretsLoaded) {
    return;
  }
  gSecretsLoaded = true;
  const QStringList keys = storageKeys(kAuthPrefix);
  for (const QString &key : keys) {
    gSecrets.insert(key, QByteArray::fromBase64(storageGet(QLatin1String(kAuthPrefix) + key).toLatin1()));
  }
}

} // namespace

QString PersistentStorage::root()
{
  return kPersistRoot;
}

bool PersistentStorage::restore()
{
  omedit_storage_restore_tree(kFilePrefix, QString(kPersistRoot).toUtf8().constData());
  loadSecrets();
  return true;
}

void PersistentStorage::scheduleSnapshot()
{
  if (!gSnapshotTimer) {
    gSnapshotTimer = new QTimer();
    gSnapshotTimer->setSingleShot(true);
    gSnapshotTimer->setInterval(1500);
    QObject::connect(gSnapshotTimer, &QTimer::timeout, []() { PersistentStorage::snapshotNow(); });
  }
  gSnapshotTimer->start();
}

bool PersistentStorage::snapshotNow()
{
  const QStringList relatives = persistedFiles();
  QStringList written;
  for (const QString &relative : relatives) {
    QFile file(kPersistRoot + QLatin1Char('/') + relative);
    if (!file.open(QIODevice::ReadOnly)) {
      continue;
    }
    omedit_storage_set((QLatin1String(kFilePrefix) + relative).toUtf8().constData(),
                       file.readAll().toBase64().constData());
    written << relative;
  }
  // Drop keys for files that are gone, so a deleted mount does not come back.
  const QStringList stored = storageKeys(kFilePrefix);
  for (const QString &relative : stored) {
    if (!written.contains(relative)) {
      omedit_storage_remove((QLatin1String(kFilePrefix) + relative).toUtf8().constData());
    }
  }
  return true;
}

//! Write the tree back on the way out.
extern "C" EMSCRIPTEN_KEEPALIVE void omedit_persist_flush()
{
  PersistentStorage::snapshotNow();
}

// pagehide is the event that actually fires when a tab is closed or bfcached;
// visibilitychange covers a backgrounded tab the browser may later discard.
EM_JS(void, omedit_install_unload_flush, (), {
  const flush = () => { try { Module._omedit_persist_flush(); } catch (e) {} };
  addEventListener("pagehide", flush);
  document.addEventListener("visibilitychange", () => {
    if (document.visibilityState === "hidden") flush();
  });
});

void PersistentStorage::startAutoSnapshot()
{
  static QTimer *pollTimer = nullptr;
  if (pollTimer) {
    return;
  }
  static QByteArray lastFingerprint = treeFingerprint();
  pollTimer = new QTimer();
  QObject::connect(pollTimer, &QTimer::timeout, []() {
    const QByteArray fingerprint = treeFingerprint();
    if (fingerprint != lastFingerprint) {
      lastFingerprint = fingerprint;
      PersistentStorage::scheduleSnapshot();
    }
  });
  pollTimer->start(5000);
  QObject::connect(qApp, &QCoreApplication::aboutToQuit, []() { PersistentStorage::snapshotNow(); });
  // A tab is usually closed without aboutToQuit ever arriving.
  omedit_install_unload_flush();
}

QByteArray PersistentStorage::secret(const QString &key)
{
  return gSecrets.value(key);
}

bool PersistentStorage::setSecret(const QString &key, const QByteArray &value)
{
  gSecrets.insert(key, value);
  omedit_storage_set((QLatin1String(kAuthPrefix) + key).toUtf8().constData(), value.toBase64().constData());
  return true;
}

bool PersistentStorage::removeSecret(const QString &key)
{
  gSecrets.remove(key);
  omedit_storage_remove((QLatin1String(kAuthPrefix) + key).toUtf8().constData());
  return true;
}

QStringList PersistentStorage::secretKeys()
{
  return gSecrets.keys();
}

#endif // __EMSCRIPTEN__
