#ifndef QTWEBENGINE_COMPAT_H
#define QTWEBENGINE_COMPAT_H

// Compile-only stubs for the QtWebEngine API that DocumentationWidget uses, for
// the Qt-for-WebAssembly build. QtWebEngine needs Chromium and is unavailable on
// wasm, so the documentation viewer/editor is non-functional on the web build;
// these stubs only let it compile and link. Native builds include the real
// QtWebEngine headers instead (DocumentationWidget guards the include).
//
// Also stubbed for the MSVC (clang-cl cross) build via OM_OMEDIT_NO_WEBENGINE:
// the aqt msvc Qt's WebEngine crashes in Chromium/ANGLE init (OMDev's patched Qt
// is fine), so the documentation/traceability views are no-ops there too.
//
// The stub bases are Q_OBJECT so moc can chain DocumentationViewer/Documentation
// Page (which derive from them and carry Q_OBJECT). Methods are inline no-ops;
// the callback-taking ones (runJavaScript/toHtml) are templates that accept and
// ignore any functor. Base-class signals are connected via the string-based
// SIGNAL()/SLOT() macros at the call sites, so they need not be declared here.
#if defined(__EMSCRIPTEN__) || defined(OM_OMEDIT_NO_WEBENGINE)

#include <QWidget>
#include <QObject>
#include <QAction>
#include <QString>
#include <QUrl>
#include <QPointF>

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
  void runJavaScript(const QString &) {}
  template<typename F> void runJavaScript(const QString &, F) {}
  template<typename F> void toHtml(F) const {}
  QAction *action(WebAction) const { return nullptr; }
  void triggerAction(WebAction, bool checked = false) { Q_UNUSED(checked); }
  void setContentEditable(bool) {}
  bool isContentEditable() const { return false; }
  QString selectedText() const { return QString(); }
  bool hasSelection() const { return false; }
  QPointF scrollPosition() const { return QPointF(); }
  void setHtml(const QString &) {}
  void setUrl(const QUrl &) {}
protected:
  virtual bool acceptNavigationRequest(const QUrl &, NavigationType, bool) { return true; }
};

class QWebEngineView : public QWidget
{
  Q_OBJECT
public:
  explicit QWebEngineView(QWidget *parent = nullptr) : QWidget(parent) {}
  QWebEnginePage *page() const { return mpPage; }
  void setPage(QWebEnginePage *pPage) { mpPage = pPage; }
  QAction *pageAction(QWebEnginePage::WebAction) const { return nullptr; }
  QWebEngineSettings *settings() const { static QWebEngineSettings settings; return &settings; }
  void setUrl(const QUrl &) {}
  void setHtml(const QString &) {}
  void load(const QUrl &) {}
  void setZoomFactor(qreal) {}
  qreal zoomFactor() const { return 1.0; }
protected:
  virtual QWebEngineView *createWindow(QWebEnginePage::WebWindowType) { return nullptr; }
private:
  QWebEnginePage *mpPage = nullptr;
};

#endif // __EMSCRIPTEN__
#endif // QTWEBENGINE_COMPAT_H
