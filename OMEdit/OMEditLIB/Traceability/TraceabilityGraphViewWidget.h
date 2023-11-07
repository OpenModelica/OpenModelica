#ifndef TRACEABILITYGRAPHVIEWWIDGET_H
#define TRACEABILITYGRAPHVIEWWIDGET_H


#include <QtGlobal>
#include <QtWidgets>

#include "QWidget"
#include "QWebEngineView"
#include "QUrl"

class TraceabilityGraphViewWidget: public QWidget
{
  Q_OBJECT
public:
  TraceabilityGraphViewWidget(QWidget *pParent = 0);
private:
  QWebEngineView *mpTraceabilityGraphWebView;
  QLabel *mpTraceabilityGraphViewLabel;
};

#endif // TRACEABILITYGRAPHVIEWWIDGET_H
