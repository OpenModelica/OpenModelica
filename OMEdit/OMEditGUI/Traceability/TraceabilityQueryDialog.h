#ifndef TRACEABILITYQUERYDIALOG_H
#define TRACEABILITYQUERYDIALOG_H

#include <QtGlobal>
#include <QDialog>
#include "QWebView"
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
#include <QtWidgets>
#include <QNetworkReply>
#else
#include <QtCore>
#include <QtGui>
#include <QtNetwork>

#endif

class Label;
class TraceabilityQueryDialog : public QDialog
{
  Q_OBJECT
public:
  TraceabilityQueryDialog(QWidget *pParent = 0);
private:
  void translateURIToJsonMessageFormat();
  Label *mpNodeToQueryLabel;
  QComboBox *mpNodeToQueryComboBox;
  QRadioButton *mpTraceToRadioButton;
  QRadioButton *mpTraceFromRadioButton;
  QPlainTextEdit *mpTraceabilityInformationTextBox;
  QWebView *mpTraceabilityGraphWebView;
  QPushButton *mpQueryTraceabilitytButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
public slots:
  void queryTraceabilityInformation();
  void readTraceabilityInformation(QNetworkReply *pNetworkReply);
};



#endif // TRACEABILITYQUERYDIALOG_H
