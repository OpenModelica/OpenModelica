#ifndef TRACEABILITYINFORMATIONURI_H
#define TRACEABILITYINFORMATIONURI_H

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
class TraceabilityInformationURI
{
public:
  TraceabilityInformationURI();
  void translateURIToJsonMessageFormat(QString modelingActivity, QString toolURI, QString activityURI, QString agentURI, QString sourceModelFileNameURI, QString fmuFileNameURI);
  void translateModelCreationURIToJsonMessageFormat(QString modelingActivity, QString toolURI, QString activityURI, QString agentURI, QString fileNameURI);
  void sendTraceabilityInformation(QString jsonMessageFormat);
private:
  void translateURIToJsonMessageFormat();
  void translateModelCreationURIToJsonMessageFormat(QStringList modelCreationURIList);
  void translateFMUExportURIToJsonMessageFormat(QStringList fmuExportURIList);
private slots:
  void traceabilityInformationSent(QNetworkReply *pNetworkReply);
public slots:
  void sendTraceabilityInformation();
};

#endif // TRACEABILITYINFORMATIONURI_H
