#ifndef TRACEABILITYPUSHDIALOG_H
#define TRACEABILITYPUSHDIALOG_H

#include <QtGlobal>
#include <QDialog>
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
#include <QtWidgets>
#include <QNetworkReply>
#include <QHttpMultiPart>
#else
#include <QtCore>
#include <QtGui>
#include <QtNetwork>
#endif


class Label;
class TraceabilityPushDialog : public QDialog
{
  Q_OBJECT
public:
  TraceabilityPushDialog(QWidget *pParent = 0);
private:
  void translateURIToJsonMessageFormat();
  Label *mpTraceabilityInformationLabel;
  QPlainTextEdit *mpTraceabilityInformationTextBox;
  Label *mpFilesDescriptionLabel;
  QCheckBox *mpCommitTraceabilityURI;
  QPushButton *mpPushTraceabilitytButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
public slots:
  void sendTraceabilityInformation();
  void traceabilityInformationSent(QNetworkReply *pNetworkReply);
};

#endif // TRACEABILITYPUSHDIALOG_H
