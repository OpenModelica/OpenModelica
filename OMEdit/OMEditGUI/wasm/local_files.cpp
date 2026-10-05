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

// The user's own filesystem, which a browser reaches only through a file picker and
// a download. Done on the DOM rather than with QFileDialog::getOpenFileContent,
// whose showOpenFilePicker is Chromium-only and whose rejection Qt drops, so a
// refusal never reaches the callback and a blocking caller waits forever.

#if defined(__EMSCRIPTEN__)

#include "OMEditGUI/wasm/WasmLocalFiles.h"

#include <QByteArray>
#include <QCoreApplication>
#include <QDebug>
#include <QDir>
#include <QEventLoop>
#include <QFile>
#include <QFileInfo>
#include <QInputDialog>
#include <QLineEdit>
#include <QMap>
#include <QRegularExpression>
#include <QStringList>
#include <QTimer>

#include <emscripten.h>
#include <emscripten/em_js.h>

#include <cstdlib>

// Defined in OMEditLIB/OMC/OMCProxy.cpp (the omc worker bridge).
QStringList omcWorkerListDir(const char *path);
int omcWorkerLoadZip(const char *mount, const QByteArray &data);

// Settles Module.__omeditPick exactly once: `change`, `cancel`, or — where `cancel`
// is not fired — the window regaining focus with nothing being read.
EM_JS(void, omedit_pick_open, (const char *accept, int multiple, int directory), {
  const st = { settled: false, reading: false, files: [], error: "" };
  Module.__omeditPick = st;
  // Without transient activation click() is ignored and no event ever arrives; the
  // check is Chromium-only and conservative, so try anyway but time out below.
  const ua = navigator.userActivation;
  const activated = !ua || ua.isActive;
  if (!activated) {
    st.error = "the browser only opens a file dialog while handling a click or key press";
  }
  const input = document.createElement("input");
  input.type = "file";
  if (directory) {
    // Files then arrive named by their path below the picked folder, and an
    // `accept` list would hide the rest of the library.
    input.webkitdirectory = true;
  } else {
    const acc = UTF8ToString(accept);
    if (acc) input.accept = acc;
    if (multiple) input.multiple = true;
  }
  input.style.display = "none";
  document.body.appendChild(input);
  const settle = () => {
    if (st.settled) return;
    st.settled = true;
    try { input.remove(); } catch (e) { /* already gone */ }
  };
  // Where the browser reports a dismissal itself, nothing else may settle the pick:
  // a folder pick adds an "upload N files?" confirmation that the page regains focus
  // in front of, and settling there reports an empty pick.
  const hasCancel = "oncancel" in input;
  input.addEventListener("cancel", settle);
  input.addEventListener("change", async () => {
    st.reading = true;
    try {
      for (const f of input.files) {
        st.files.push({ name: f.webkitRelativePath || f.name,
                        bytes: new Uint8Array(await f.arrayBuffer()) });
      }
    } catch (e) {
      st.error = String(e);
    }
    settle();
  });
  const idle = () => !st.reading && input.files.length === 0;
  if (!hasCancel) {
    // Long, so it outlasts the upload confirmation.
    window.addEventListener("focus", () => {
      setTimeout(() => { if (idle()) settle(); }, 30000);
    }, { once: true });
  }
  input.click();
  if (!activated) {
    setTimeout(() => { if (idle()) settle(); }, 3000);
  }
});

EM_JS(int, omedit_pick_settled, (), {
  return (Module.__omeditPick && Module.__omeditPick.settled) ? 1 : 0;
});
EM_JS(int, omedit_pick_count, (), {
  return (Module.__omeditPick && Module.__omeditPick.files.length) || 0;
});
EM_JS(char *, omedit_pick_name, (int i), {
  const f = Module.__omeditPick.files[i];
  return stringToNewUTF8(f ? f.name : "");
});
EM_JS(char *, omedit_pick_bytes, (int i, int *outLen), {
  const f = Module.__omeditPick.files[i];
  if (!f) { HEAP32[outLen >> 2] = -1; return 0; }
  const len = f.bytes.length;
  const ptr = _malloc(len || 1);
  HEAPU8.set(f.bytes, ptr);
  HEAP32[outLen >> 2] = len;
  return ptr;
});
EM_JS(char *, omedit_pick_error, (), {
  return stringToNewUTF8((Module.__omeditPick && Module.__omeditPick.error) || "");
});
EM_JS(void, omedit_pick_release, (), { Module.__omeditPick = null; });

// A download rather than a save picker, so there is nothing to reject.
EM_JS(void, omedit_download_bytes, (const char *name, const char *bytes, int len), {
  const blob = new Blob([HEAPU8.slice(bytes, bytes + len)], { type: "application/octet-stream" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = UTF8ToString(name);
  a.style.display = "none";
  document.body.appendChild(a);
  a.click();
  setTimeout(() => { a.remove(); URL.revokeObjectURL(url); }, 0);
});

namespace {

// Where a picked file is staged, so nothing downstream knows it came from outside.
const QLatin1String kUploadDir("/uploads");

/*!
 * \brief Qt name filter -> the input's `accept`: "All Files (*.mo *.mol)" becomes
 * ".mo,.mol". Anything not a plain suffix matches everything, so it yields no accept
 * list rather than one the user cannot get past.
 */
QString acceptFromNameFilter(const QString &nameFilter)
{
  QStringList suffixes;
  static const QRegularExpression parens(QStringLiteral("\\(([^()]*)\\)"));
  QRegularExpressionMatchIterator groups = parens.globalMatch(nameFilter);
  while (groups.hasNext()) {
    const QStringList patterns = groups.next().captured(1).split(QLatin1Char(' '), Qt::SkipEmptyParts);
    for (const QString &pattern : patterns) {
      if (!pattern.startsWith(QLatin1String("*.")) || pattern.mid(2).contains(QLatin1Char('*'))
          || pattern == QLatin1String("*.*")) {
        return QString();
      }
      const QString suffix = QLatin1Char('.') + pattern.mid(2);
      if (!suffixes.contains(suffix)) {
        suffixes << suffix;
      }
    }
  }
  return suffixes.join(QLatin1Char(','));
}

// Keep the path a folder pick came with — a library needs its Resources/ next to
// its .mo — without letting it escape the upload directory.
QString stagePath(const QString &pickedName)
{
  QStringList parts;
  const QStringList given = QDir::cleanPath(pickedName).split(QLatin1Char('/'), Qt::SkipEmptyParts);
  for (const QString &part : given) {
    if (part == QLatin1String("..") || part == QLatin1String(".")) {
      return QString();
    }
    parts << part;
  }
  return parts.join(QLatin1Char('/'));
}

// One picked file, from the JS side into the omc filesystem.
QString stageFile(int index)
{
  char *rawName = omedit_pick_name(index);
  const QString name = stagePath(QString::fromUtf8(rawName));
  free(rawName);
  if (name.isEmpty()) {
    return QString();
  }
  int len = -1;
  char *raw = omedit_pick_bytes(index, &len);
  if (!raw || len < 0) {
    free(raw);
    qWarning() << "[OMEdit-wasm] could not read the picked file" << name;
    return QString();
  }
  const QByteArray content(raw, len);
  free(raw);

  const QString path = QString("%1/%2").arg(kUploadDir, name);
  QFile file(path);
  if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
    qWarning() << "[OMEdit-wasm] could not stage" << path << file.errorString();
    return QString();
  }
  const bool written = file.write(content) == content.size();
  file.close();
  if (!written) {
    qWarning() << "[OMEdit-wasm] short write staging" << path;
    return QString();
  }
  return path;
}

// Everything under dir, files only, as absolute paths.
QStringList listTree(const QString &dir)
{
  QStringList files;
  const QStringList entries = omcWorkerListDir(dir.toUtf8().constData());
  for (const QString &entry : entries) {
    if (entry.endsWith(QLatin1Char('/'))) {
      files << listTree(QString("%1/%2").arg(dir, entry.left(entry.size() - 1)));
    } else {
      files << QString("%1/%2").arg(dir, entry);
    }
  }
  return files;
}

QStringList entryFiles(const QStringList &paths)
{
  static const QStringList suffixes = {QStringLiteral("mo"), QStringLiteral("mol"),
                                       QStringLiteral("bmo"), QStringLiteral("ssp"),
                                       QStringLiteral("crml")};
  QMap<int, QStringList> byDepth;
  QString package;
  int packageDepth = -1;
  for (const QString &path : paths) {
    const QFileInfo info(path);
    if (!suffixes.contains(info.suffix().toLower())) {
      continue;
    }
    const int depth = path.count(QLatin1Char('/'));
    if (info.fileName().compare(QLatin1String("package.mo"), Qt::CaseInsensitive) == 0
        && (packageDepth < 0 || depth < packageDepth)) {
      package = path;
      packageDepth = depth;
    }
    byDepth[depth] << path;
  }
  if (!package.isEmpty()) {
    return QStringList{package};
  }
  return byDepth.isEmpty() ? QStringList() : byDepth.first();
}

QStringList pickFiles(const QString &accept, bool multiple, bool directory)
{
  omedit_pick_open(accept.toUtf8().constData(), multiple ? 1 : 0, directory ? 1 : 0);
  // Wait as every omc call on this thread does (OMCProxy::omcWorkerWaitReply): a
  // nonzero poll, or Qt never yields to the browser, and exec() re-entered because
  // it can return without the condition holding.
  if (!omedit_pick_settled()) {
    QEventLoop loop;
    QTimer poll;
    QObject::connect(&poll, &QTimer::timeout, &loop, [&loop]() {
      if (omedit_pick_settled()) {
        loop.quit();
      }
    });
    poll.start(50);
    while (!omedit_pick_settled()) {
      loop.exec();
    }
  }
  QStringList paths;
  const int count = omedit_pick_count();
  for (int i = 0; i < count; ++i) {
    const QString path = stageFile(i);
    if (!path.isEmpty()) {
      paths << path;
    }
  }
  char *rawError = omedit_pick_error();
  const QString error = QString::fromUtf8(rawError);
  free(rawError);
  omedit_pick_release();
  // A refusal is silent in the browser, so say so rather than look like a no-op.
  if (paths.isEmpty()) {
    qWarning() << "[OMEdit-wasm] file dialog picked nothing" << error;
  }
  return paths;
}

} // namespace

/*!
 * \brief Ask the browser for files and stage them in the omc filesystem.
 * \return the paths they were staged at, empty if the user cancelled.
 */
QStringList WasmLocalFiles::openFiles(const QString &nameFilter, bool multiple)
{
  return pickFiles(acceptFromNameFilter(nameFilter), multiple, false);
}

/*!
 * \brief Ask the browser for a folder and stage the tree, structure intact.
 * \return the directory it was staged at, empty if the user cancelled.
 */
QString WasmLocalFiles::openFolder()
{
  const QStringList paths = pickFiles(QString(), true, true);
  if (paths.isEmpty()) {
    return QString();
  }
  const QString relative = paths.first().mid(kUploadDir.size() + 1);
  if (!relative.contains(QLatin1Char('/'))) {
    return QString(kUploadDir);
  }
  return QString("%1/%2").arg(kUploadDir, relative.section(QLatin1Char('/'), 0, 0));
}

/*!
 * \brief Unzip a staged archive into the omc filesystem.
 * \return the directory it was unpacked into, empty if nothing was.
 */
QString WasmLocalFiles::expandArchive(const QString &archivePath)
{
  QFile archive(archivePath);
  if (!archive.open(QIODevice::ReadOnly)) {
    qWarning() << "[OMEdit-wasm] could not read" << archivePath << archive.errorString();
    return QString();
  }
  const QByteArray data = archive.readAll();
  archive.close();
  const QString mount = QString("%1/%2").arg(kUploadDir, QFileInfo(archivePath).completeBaseName());
  if (omcWorkerLoadZip(mount.toUtf8().constData(), data) <= 0) {
    qWarning() << "[OMEdit-wasm] nothing extracted from" << archivePath;
    return QString();
  }
  return mount;
}

/*!
 * \brief The files to load from a staged tree: its package.mo, else the loadable
 * files in the shallowest directory that holds any.
 */
QStringList WasmLocalFiles::libraryFiles(const QString &dir)
{
  return entryFiles(listTree(dir));
}

/*!
 * \brief Only the file name is asked for — the browser picks the directory when the
 * download runs. The returned path is where the caller writes, in the omc filesystem.
 */
QString WasmLocalFiles::saveFileName(QWidget *parent, const QString &caption, const QString &dir,
                                     const QString &proposedName)
{
  bool ok = false;
  const QString name = QInputDialog::getText(parent, caption,
                                             QCoreApplication::translate("WasmLocalFiles",
                                                                         "File name (downloaded once saved):"),
                                             QLineEdit::Normal, proposedName, &ok);
  if (!ok) {
    return QString();
  }
  const QString baseName = QFileInfo(name.trimmed()).fileName();
  if (baseName.isEmpty()) {
    return QString();
  }
  return QString("%1/%2").arg(dir.isEmpty() ? QDir::homePath() : dir, baseName);
}

/*!
 * \brief Hand a file the caller has finished writing to the browser as a download.
 */
bool WasmLocalFiles::download(const QString &path)
{
  QFile file(path);
  if (!file.open(QIODevice::ReadOnly)) {
    qWarning() << "[OMEdit-wasm] nothing to download at" << path << file.errorString();
    return false;
  }
  const QByteArray data = file.readAll();
  file.close();
  omedit_download_bytes(QFileInfo(path).fileName().toUtf8().constData(), data.constData(), data.size());
  return true;
}

#endif // __EMSCRIPTEN__
