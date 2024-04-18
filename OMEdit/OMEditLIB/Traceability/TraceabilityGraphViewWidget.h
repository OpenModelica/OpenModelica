#ifndef TRACEABILITYGRAPHVIEWWIDGET_H
#define TRACEABILITYGRAPHVIEWWIDGET_H


#include <QtGlobal>
#include <QtWidgets>

#include "QWidget"
#include "QUrl"
#ifdef OM_OMEDIT_ENABLE_QTWEBENGINE
#include <QWebEngineView>
#else
#include <QWebView>
#endif

class TraceabilityGraphViewWidget: public QWidget
{
  Q_OBJECT
public:
  TraceabilityGraphViewWidget(QWidget *pParent = 0);
private:
#ifdef OM_OMEDIT_ENABLE_QTWEBENGINE
  QWebEngineView *mpTraceabilityGraphWebView;
#else
  QWebView *mpTraceabilityGraphWebView;
#endif
  QLabel *mpTraceabilityGraphViewLabel;
};

#endif // TRACEABILITYGRAPHVIEWWIDGET_H
