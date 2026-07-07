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

#ifndef WASMDOCVIEWER_H
#define WASMDOCVIEWER_H

// Qt-for-WebAssembly documentation viewer. QtWebEngine has no wasm build, and
// QtWebView's DOM-overlay WebView does not composite when embedded in the QWidget
// tree under Qt-wasm (the content reaches the iframe but nothing is placed on the
// canvas). QTextBrowser is a plain QWidget that renders Qt rich-text HTML, so it
// works reliably in the dock. This presents the slice of the QWebEngineView/
// QWebEnginePage API that DocumentationWidget uses over a QTextBrowser.
//
// Viewer-only: HTML renders and links route through acceptNavigationRequest; the
// WYSIWYG editor paths (runJavaScript, toHtml, page actions, contentEditable) are
// no-ops. QTextBrowser supports a subset of HTML4/CSS2 (no JavaScript, no remote
// resources), which covers typical Modelica documentation.
#if defined(__EMSCRIPTEN__)

#include <QTextBrowser>
#include <QObject>
#include <QString>
#include <QUrl>
#include <QPointF>

class QAction;

class QWebEngineSettings
{
public:
  enum FontFamily { StandardFont };
  enum WebAttribute { LocalStorageEnabled };
  void setFontFamily(FontFamily, const QString &) {}
  void setAttribute(WebAttribute, bool) {}
  void setDefaultTextEncoding(const char *) {}
};

class QWebEnginePage : public QObject
{
  Q_OBJECT
public:
  enum WebAction {
    SelectAll, Copy, Cut, Paste, ToggleBold, ToggleItalic, ToggleUnderline,
    ToggleStrikethrough, Indent, Outdent
  };
  enum WebWindowType {
    WebBrowserWindow, WebBrowserTab, WebDialog, WebBrowserBackgroundTab
  };
  enum NavigationType {
    NavigationTypeLinkClicked, NavigationTypeTyped, NavigationTypeFormSubmitted,
    NavigationTypeBackForward, NavigationTypeReload, NavigationTypeRedirect,
    NavigationTypeOther
  };
  explicit QWebEnginePage(QObject *parent = nullptr) : QObject(parent) {}
  void setBrowser(QTextBrowser *browser) { mpBrowser = browser; }
  void runJavaScript(const QString &) {}
  template<typename F> void runJavaScript(const QString &, F) {}
  template<typename F> void toHtml(F) const {}
  QAction *action(WebAction) const { return nullptr; }
  void triggerAction(WebAction, bool checked = false) { Q_UNUSED(checked); }
  void setContentEditable(bool) {}
  bool isContentEditable() const { return false; }
  QString selectedText() const;
  bool hasSelection() const;
  QPointF scrollPosition() const;
  void setHtml(const QString &);
  void setUrl(const QUrl &);
  void emitLinkHovered(const QString &link) { emit linkHovered(link); }
  virtual bool acceptNavigationRequest(const QUrl &, NavigationType, bool) { return true; }
signals:
  void linkClicked(const QUrl &);
  void linkHovered(const QString &);
  void selectionChanged();
private:
  QTextBrowser *mpBrowser = nullptr;
};

class QWebEngineView : public QTextBrowser
{
  Q_OBJECT
public:
  explicit QWebEngineView(QWidget *parent = nullptr);
  QWebEnginePage *page() const { return mpPage; }
  void setPage(QWebEnginePage *pPage);
  QAction *pageAction(QWebEnginePage::WebAction) const { return nullptr; }
  QWebEngineSettings *settings() const { static QWebEngineSettings settings; return &settings; }
  void setUrl(const QUrl &url);
  void setHtml(const QString &html);
  void load(const QUrl &url) { setUrl(url); }
  void setZoomFactor(qreal zoom);
  qreal zoomFactor() const { return mZoom; }
signals:
  void loadFinished(bool ok);
protected:
  virtual QWebEngineView *createWindow(QWebEnginePage::WebWindowType) { return nullptr; }
private slots:
  void onAnchorClicked(const QUrl &url);
  void onHighlighted(const QUrl &url);
private:
  QWebEnginePage *mpPage = nullptr;
  qreal mZoom = 1.0;
  qreal mBaseFontPointSize = 0.0;
};

#endif // __EMSCRIPTEN__
#endif // WASMDOCVIEWER_H
