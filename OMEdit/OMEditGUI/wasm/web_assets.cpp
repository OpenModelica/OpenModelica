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

// The page serves <home>/share/ (the translations) from share/ next to
// OMEdit-qt.html. share/index.json maps each file to a hash of its contents.
// A file is downloaded into MEMFS the first time Qt looks at it, so only the
// translations of the selected language are downloaded. The XHR is synchronous
// because the translations are loaded before the event loop runs.
#if defined(__EMSCRIPTEN__)

#include <QtCore/private/qabstractfileengine_p.h>
#include <QDir>
#include <QString>
#include <emscripten/em_js.h>

EM_JS(int, omedit_web_asset_fetch, (const char *relPath, const char *path), {
  if (Module.__omeditWebAssets === undefined) {
    Module.__omeditWebAssets = null;
    try {
      const xhr = new XMLHttpRequest();
      xhr.open("GET", new URL("share/index.json", document.baseURI), false);
      xhr.setRequestHeader("Cache-Control", "no-cache");
      xhr.send();
      if (xhr.status === 200) {
        Module.__omeditWebAssets = new Map(Object.entries(JSON.parse(xhr.responseText)));
      }
    } catch (e) {
      console.error("[OMEdit-wasm] cannot read share/index.json", e);
    }
  }
  const assets = Module.__omeditWebAssets;
  const rel = UTF8ToString(relPath);
  if (!assets || !assets.has(rel)) return 0;
  const target = UTF8ToString(path);
  if (FS.analyzePath(target).exists) return 1;
  const hash = assets.get(rel);
  assets.delete(rel);
  try {
    const xhr = new XMLHttpRequest();
    xhr.open("GET", new URL("share/" + rel + "?v=" + hash, document.baseURI), false);
    // A synchronous XHR on the main thread cannot set responseType.
    xhr.overrideMimeType("text/plain; charset=x-user-defined");
    xhr.send();
    if (xhr.status !== 200) return 0;
    const text = xhr.responseText;
    const bytes = new Uint8Array(text.length);
    for (let i = 0; i < text.length; i++) bytes[i] = text.charCodeAt(i) & 0xff;
    FS.mkdirTree(target.substring(0, target.lastIndexOf("/")));
    FS.writeFile(target, bytes);
    return 1;
  } catch (e) {
    console.error("[OMEdit-wasm] cannot download share/" + rel, e);
    return 0;
  }
});

static QString gWebAssetRoot;

bool omeditFetchWebAsset(const QString &fileName)
{
  if (gWebAssetRoot.isEmpty() || !fileName.startsWith(gWebAssetRoot)) return false;
  const QString relPath = fileName.mid(gWebAssetRoot.size());
  return omedit_web_asset_fetch(relPath.toUtf8().constData(), fileName.toUtf8().constData());
}

namespace {

class WebAssetHandler : public QAbstractFileEngineHandler
{
public:
  std::unique_ptr<QAbstractFileEngine> create(const QString &fileName) const override
  {
    omeditFetchWebAsset(fileName);
    return nullptr;
  }
};

WebAssetHandler *gWebAssetHandler = nullptr;

} // namespace

void omeditInstallWebAssetFileEngine(const QString &installationDirectory)
{
  if (gWebAssetHandler) return;
  gWebAssetRoot = QDir::cleanPath(installationDirectory + QStringLiteral("/share")) + QLatin1Char('/');
  gWebAssetHandler = new WebAssetHandler();
}

#endif // __EMSCRIPTEN__
