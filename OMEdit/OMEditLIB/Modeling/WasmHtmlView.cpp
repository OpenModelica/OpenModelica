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

#include "Modeling/WasmHtmlView.h"

#if defined(__EMSCRIPTEN__)

#include <QDebug>
#include <QEvent>
#include <QFile>
#include <QHash>
#include <QJsonArray>
#include <QJsonDocument>
#include <QTimer>

#include <emscripten.h>

// The iframes, by id, in Module.__omeditHtmlViews. A srcdoc page has the origin of OMEdit, so
// OMEdit reaches into it and it calls __omeditHtmlLink with the links that are clicked in it.
EM_JS(void, omedit_html_set, (int id, const char *html), {
  const views = Module.__omeditHtmlViews || (Module.__omeditHtmlViews = {});
  if (!window.__omeditHtmlLink) {
    window.__omeditHtmlLink = (viewId, url) => {
      const pUrl = stringToNewUTF8(url);
      try {
        Module._omedit_html_view_link(viewId, pUrl);
      } finally {
        _free(pUrl);
      }
    };
  }
  let frame = views[id];
  if (!frame) {
    frame = document.createElement("iframe");
    frame.style.cssText = "position:absolute;border:0;margin:0;padding:0;z-index:1;display:none;background:white";
    frame.onload = () => Module._omedit_html_view_loaded(id);
    views[id] = frame;
  }
  frame.srcdoc = UTF8ToString(html);
});

// Places the iframe in the client area, .qt-window, of the DOM element of the top-level window;
// returns 0 if that element is not there yet.
EM_JS(int, omedit_html_place, (int id, const char *windowId, int x, int y, int width, int height, int visible), {
  const frame = (Module.__omeditHtmlViews || {})[id];
  if (!frame) {
    return 1;
  }
  if (!frame.isConnected) {
    if (!visible) {
      return 1;
    }
    const elementId = "qt-window-" + UTF8ToString(windowId);
    let element = document.getElementById(elementId);
    if (!element) {
      for (const e of document.querySelectorAll("*")) {
        if (e.shadowRoot && (element = e.shadowRoot.getElementById(elementId))) {
          break;
        }
      }
    }
    const client = element && element.querySelector(".qt-window");
    if (!client) {
      return 0;
    }
    client.appendChild(frame);
  }
  frame.style.left = x + "px";
  frame.style.top = y + "px";
  frame.style.width = width + "px";
  frame.style.height = height + "px";
  frame.style.display = visible ? "block" : "none";
  return 1;
});

EM_JS(void, omedit_html_remove, (int id), {
  const views = Module.__omeditHtmlViews || {};
  if (views[id]) {
    views[id].remove();
    delete views[id];
  }
});

EM_JS(char *, omedit_html_eval, (int id, const char *script), {
  const frame = (Module.__omeditHtmlViews || {})[id];
  let result = null;
  try {
    result = frame.contentWindow.eval(UTF8ToString(script));
  } catch (e) {
    console.warn("[OMEdit-wasm] script in the HTML view failed: " + e);
  }
  return stringToNewUTF8(JSON.stringify([result === undefined ? null : result]));
});

EM_JS(char *, omedit_html_blob, (const char *bytes, int length), {
  return stringToNewUTF8(URL.createObjectURL(new Blob([HEAPU8.slice(bytes, bytes + length)], {type: "text/javascript"})));
});

namespace {
QHash<int, WasmHtmlView*> views;
int nextId = 1;
}

extern "C" EMSCRIPTEN_KEEPALIVE void omedit_html_view_link(int id, const char *url)
{
  const QUrl link(QString::fromUtf8(url));
  // Not from within the browser's event handler, but from the event loop.
  QTimer::singleShot(0, [id, link]() {
    if (WasmHtmlView *pView = WasmHtmlView::find(id)) {
      emit pView->linkClicked(link);
    }
  });
}

extern "C" EMSCRIPTEN_KEEPALIVE void omedit_html_view_loaded(int id)
{
  QTimer::singleShot(0, [id]() {
    if (WasmHtmlView *pView = WasmHtmlView::find(id)) {
      emit pView->loadFinished(true);
    }
  });
}

WasmHtmlView::WasmHtmlView(QWidget *pParent)
  : QWidget(pParent), mId(nextId++)
{
  views.insert(mId, this);
}

WasmHtmlView::~WasmHtmlView()
{
  views.remove(mId);
  omedit_html_remove(mId);
}

WasmHtmlView* WasmHtmlView::find(int id)
{
  return views.value(id, nullptr);
}

/*!
 * \brief WasmHtmlView::setHtml
 * Shows the page. A link clicked in it, or opened with window.open, is emitted as linkClicked.
 * \param html
 */
void WasmHtmlView::setHtml(const QString &html)
{
  const QString links = QString(R"(<script type="text/javascript">
window.open = function(url) { parent.__omeditHtmlLink(%1, String(url)); return null; };
document.addEventListener("click", function(event) {
  var a = event.defaultPrevented || !event.target.closest ? null : event.target.closest("a");
  var href = a ? (a.href && a.href.baseVal !== undefined ? a.href.baseVal : a.href) : "";
  if (href) {
    event.preventDefault();
    parent.__omeditHtmlLink(%1, String(href));
  }
});
</script>
)").arg(mId);
  QString page = html;
  const int head = page.indexOf("<head>");
  page.insert(head >= 0 ? head + 6 : 0, links);
  omedit_html_set(mId, page.toUtf8().constData());
  updateFrame();
}

/*!
 * \brief WasmHtmlView::runJavaScript
 * Runs the script in the page and calls the callback with its result, before returning.
 * \param script
 * \param callback
 */
void WasmHtmlView::runJavaScript(const QString &script, const std::function<void(const QVariant&)> &callback)
{
  char *pResult = omedit_html_eval(mId, script.toUtf8().constData());
  const QJsonArray result = QJsonDocument::fromJson(QByteArray(pResult)).array();
  free(pResult);
  callback(result.isEmpty() ? QVariant() : result.at(0).toVariant());
}

/*!
 * \brief WasmHtmlView::scriptUrl
 * Returns a URL of a script in the resources that a page can load, made once.
 * \param resource
 * \return
 */
QString WasmHtmlView::scriptUrl(const QString &resource)
{
  static QHash<QString, QString> urls;
  if (!urls.contains(resource)) {
    QFile file(resource);
    if (!file.open(QIODevice::ReadOnly)) {
      return QString();
    }
    const QByteArray bytes = file.readAll();
    char *pUrl = omedit_html_blob(bytes.constData(), bytes.size());
    urls.insert(resource, QString::fromUtf8(pUrl));
    free(pUrl);
  }
  return urls.value(resource);
}

void WasmHtmlView::showEvent(QShowEvent *pEvent)
{
  QWidget::showEvent(pEvent);
  QTimer::singleShot(0, this, &WasmHtmlView::updateFrame);
}

void WasmHtmlView::hideEvent(QHideEvent *pEvent)
{
  QWidget::hideEvent(pEvent);
  updateFrame();
}

void WasmHtmlView::resizeEvent(QResizeEvent *pEvent)
{
  QWidget::resizeEvent(pEvent);
  updateFrame();
}

void WasmHtmlView::moveEvent(QMoveEvent *pEvent)
{
  QWidget::moveEvent(pEvent);
  updateFrame();
}

bool WasmHtmlView::eventFilter(QObject *pObject, QEvent *pEvent)
{
  if (pObject == mpWindow) {
    switch (pEvent->type()) {
      case QEvent::Show:
      case QEvent::Hide:
      case QEvent::Resize:
      case QEvent::LayoutRequest:
      case QEvent::WindowStateChange:
        QTimer::singleShot(0, this, &WasmHtmlView::updateFrame);
        break;
      default:
        break;
    }
  }
  return QWidget::eventFilter(pObject, pEvent);
}

/*!
 * \brief WasmHtmlView::updateFrame
 * Puts the iframe where the widget is in its window, and shows it only when the widget is shown.
 * The window may not be in the DOM yet when it is first shown, then it is tried again.
 */
void WasmHtmlView::updateFrame()
{
  QWidget *pWindow = window();
  if (pWindow != mpWindow) {
    if (mpWindow) {
      mpWindow->removeEventFilter(this);
    }
    mpWindow = pWindow;
    mpWindow->installEventFilter(this);
  }
  const bool visible = isVisible() && !pWindow->isMinimized();
  const QPoint position = mapTo(pWindow, QPoint(0, 0));
  const QByteArray windowId = QByteArray::number(static_cast<qulonglong>(visible ? pWindow->winId() : 0));
  if (omedit_html_place(mId, windowId.constData(), position.x(), position.y(), width(), height(), visible)) {
    mPlaceAttempts = 0;
  } else if (++mPlaceAttempts < 50) {
    QTimer::singleShot(100, this, &WasmHtmlView::updateFrame);
  } else {
    qWarning() << "[OMEdit-wasm] no DOM element for the window of the HTML view" << windowId;
  }
}

#endif // __EMSCRIPTEN__
