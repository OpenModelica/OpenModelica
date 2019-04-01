#ifndef TRACEABILITYGRAPHVIEWWIDGET_H
#define TRACEABILITYGRAPHVIEWWIDGET_H


#include <QtGlobal>
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
#include <QtWidgets>
#else
#include <QtCore>
#include <QtGui>
#endif

#include "QWidget"
#include "QWebView"
#include "QUrl"

class TraceabilityGraphViewWidget: public QWidget
{
  Q_OBJECT
public:
  TraceabilityGraphViewWidget(QWidget *pParent = 0);
private:
  QWebView *mpTraceabilityGraphWebView;
  QLabel *mpTraceabilityGraphViewLabel;
};

#endif // TRACEABILITYGRAPHVIEWWIDGET_H
