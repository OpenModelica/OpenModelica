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
class TraceabilityPushDialog /*: public QDialog*/
{
//  Q_OBJECT
public:
  TraceabilityPushDialog(/*QWidget *pParent = 0*/);
  void translateURIToJsonMessageFormat(QString modelingActivity, QString toolURI, QString activityURI, QString agentURI, QString sourceModelFileNameURI, QString fmuFileNameURI);
  void translateModelCreationURIToJsonMessageFormat(QString modelingActivity, QString toolURI, QString activityURI, QString agentURI, QString fileNameURI);
  void sendTraceabilityInformation(QString jsonMessageFormat);
private:
  void translateURIToJsonMessageFormat();
  void translateModelCreationURIToJsonMessageFormat(QStringList modelCreationURIList);
  void translateFMUExportURIToJsonMessageFormat(QStringList fmuExportURIList);
//  Label *mpTraceabilityInformationLabel;
//  QPlainTextEdit *mpTraceabilityInformationTextBox;
//  Label *mpFilesDescriptionLabel;
//  QCheckBox *mpCommitTraceabilityURI;
//  QPushButton *mpPushTraceabilitytButton;
//  QPushButton *mpCancelButton;
//  QDialogButtonBox *mpButtonBox;
private slots:
  void traceabilityInformationSent(QNetworkReply *pNetworkReply);
public slots:
  void sendTraceabilityInformation();
};

#endif // TRACEABILITYPUSHDIALOG_H
