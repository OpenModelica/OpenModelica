#include "TraceabilityGraphViewWidget.h"

TraceabilityGraphViewWidget::TraceabilityGraphViewWidget(QWidget *pParent)
  : QWidget(pParent)
{
  mpTraceabilityGraphWebView = new QWebView;
  mpTraceabilityGraphWebView->load(QUrl("http://localhost:7474/browser/"));
  mpTraceabilityGraphViewLabel = new QLabel(tr("Traceability Graph View"));
  QFont font;
  font.setPointSize(15);
  font.setBold(true);
  mpTraceabilityGraphViewLabel->setFont(font);
  // set the layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->addWidget(mpTraceabilityGraphViewLabel, 0, 0);
  pMainLayout->addWidget(mpTraceabilityGraphWebView, 1, 0);
  setLayout(pMainLayout);
}
