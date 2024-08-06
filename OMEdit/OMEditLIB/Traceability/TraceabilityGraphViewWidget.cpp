#include "TraceabilityGraphViewWidget.h"

TraceabilityGraphViewWidget::TraceabilityGraphViewWidget(QWidget *pParent)
  : QWidget(pParent)
{
#ifndef OM_DISABLE_DOCUMENTATION
#ifdef OM_OMEDIT_ENABLE_QTWEBENGINE
  mpTraceabilityGraphWebView = new QWebEngineView;
#else // #ifdef OM_OMEDIT_ENABLE_QTWEBENGINE
  mpTraceabilityGraphWebView = new QWebView;
#endif // #ifdef OM_OMEDIT_ENABLE_QTWEBENGINE
  mpTraceabilityGraphWebView->load(QUrl("http://localhost:7474/browser/"));
#endif // #ifndef OM_DISABLE_DOCUMENTATION
  mpTraceabilityGraphViewLabel = new QLabel(tr("Traceability Graph View"));
  QFont font;
  font.setPointSize(15);
  font.setBold(true);
  mpTraceabilityGraphViewLabel->setFont(font);
  // set the layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->addWidget(mpTraceabilityGraphViewLabel, 0, 0);
#ifndef OM_DISABLE_DOCUMENTATION
  pMainLayout->addWidget(mpTraceabilityGraphWebView, 1, 0);
#else // #ifndef OM_DISABLE_DOCUMENTATION
  qDebug() << "Traceability graph view is not supported due to missing webkit and webengine.";
#endif // #ifndef OM_DISABLE_DOCUMENTATION
  setLayout(pMainLayout);
}
