#ifndef TRACEABILITYGRAPHVIEWWIDGET_H
#define TRACEABILITYGRAPHVIEWWIDGET_H


#include <QtGlobal>
#include <QtWidgets>

#include "QWidget"
#include "QUrl"
#ifndef OM_DISABLE_DOCUMENTATION
#ifdef OM_OMEDIT_ENABLE_QTWEBENGINE
#include <QWebEngineView>
#else // #ifdef OM_OMEDIT_ENABLE_QTWEBENGINE
#include <QWebView>
#endif // #ifdef OM_OMEDIT_ENABLE_QTWEBENGINE
#endif // #ifndef OM_DISABLE_DOCUMENTATION

class TraceabilityGraphViewWidget: public QWidget
{
  Q_OBJECT
public:
  TraceabilityGraphViewWidget(QWidget *pParent = 0);
private:
#ifndef OM_DISABLE_DOCUMENTATION
#ifdef OM_OMEDIT_ENABLE_QTWEBENGINE
  QWebEngineView *mpTraceabilityGraphWebView;
#else // #ifdef OM_OMEDIT_ENABLE_QTWEBENGINE
  QWebView *mpTraceabilityGraphWebView;
#endif // #ifdef OM_OMEDIT_ENABLE_QTWEBENGINE
#endif // #ifndef OM_DISABLE_DOCUMENTATION
  QLabel *mpTraceabilityGraphViewLabel;
};

#endif // TRACEABILITYGRAPHVIEWWIDGET_H
