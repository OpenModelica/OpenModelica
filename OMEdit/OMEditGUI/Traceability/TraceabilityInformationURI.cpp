#include "TraceabilityInformationURI.h"
#include "MainWindow.h"
#include "Util/Helper.h"
#include "Modeling/MessagesWidget.h"
#include "Options/OptionsDialog.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Git/GitCommands.h"

/*!
 * \class TraceabilityInformationURI
 * \brief Creates a dialog that shows the traceability information.
 */
/*!
 * \brief TraceabilityInformationURI::TraceabilityInformationURI
 */
TraceabilityInformationURI::TraceabilityInformationURI(QObject  *pParent)
  : QObject(pParent)
{
}

void TraceabilityInformationURI::translateModelCreationURIToJsonMessageFormat(QString modelingActivity, QString toolURI, QString activityURI, QString agentURI, QString fileNameURI, QString entityType, QString path, QString gitHash)
{
  QString  email, userName;
  userName = OptionsDialog::instance()->getTraceabilityPage()->getUserName()->text();
  email = OptionsDialog::instance()->getTraceabilityPage()->getEmail()->text();
  QString jsonMessageFormat = QString("{\"rdf:RDF\" : {\n"
                                       "      \"xmlns:rdf\" : \"http://www.w3.org/1999/02/22-rdf-syntax-ns#\",\n"
                                       "      \"xmlns:prov\": \"http://www.w3.org/ns/prov#\",\n"
                                       "      \"messageFormatVersion\": \"1.4\",\n"
                                       "      \"prov:Entity\": [\n"
                                       "            {\n"
                                       "            \"rdf:about\": \"%4\",\n"
                                       "            \"type\": \"Simulation Tool\",\n"
                                       "            \"version\": \"OpenModelica\",\n"
                                       "            \"name\": \"OpenModelica\"\n"
                                       "            },\n"
                                       "            {\n"
                                       "            \"rdf:about\" : \"%1\",\n"
                                       "            \"path\" : \"%9\",\n"
                                       "            \"type\" : \"%8\",\n"
                                       "            \"hash\" : \"%10\",\n"
                                       "            \"prov:wasAttributedTo\": {\"prov:Agent\": {\"rdf:about\": \"%3\"}},\n"
                                       "            \"prov:wasGeneratedBy\": {\"prov:Activity\": {\"rdf:about\": \"%2\"}}\n"
                                       "            }\n"
                                       "      ],\n "
                                       "     \"prov:Agent\": [\n"
                                       "            {\n"
                                       "            \"rdf:about\": \"%3\",\n"
                                       "            \"name\": \"%5\",\n"
                                       "            \"email\": \"%6\"\n"
                                       "            }\n"
                                       "     ],\n"
                                       "     \"prov:Activity\": [\n"
                                       "            {\n"
                                       "            \"time\": \"2016-09-19T13:53:06Z\",\n"
                                       "            \"type\": \"%7\",\n"
                                       "            \"prov:wasAssociatedWith\": {\"prov:Agent\": {\"rdf:about\": \"%3\"}},\n"
                                       "            \"prov:used\": {\"prov:Entity\": [ {\"rdf:about\": \"%4\"}]},\n"
                                       "            \"rdf:about\": \"%2\"\n"
                                       "            }\n"
                                       "     ]\n"
                                       "}}").arg(fileNameURI.simplified()).arg(activityURI.simplified()).arg(agentURI.simplified()).arg(toolURI.simplified()).arg(userName).arg(email).arg(modelingActivity).arg(entityType.simplified()).arg(path.simplified()).arg(gitHash.simplified());
  sendTraceabilityInformation(jsonMessageFormat);
}

void TraceabilityInformationURI::translateURIToJsonMessageFormat(QString modelingActivity, QString toolURI, QString activityURI, QString agentURI, QString sourceModelFileNameURI, QString fmuFileNameURI, QString entityType, QString path, QString gitHash)
{
  QString  email, userName;
  userName = OptionsDialog::instance()->getTraceabilityPage()->getUserName()->text();
  email = OptionsDialog::instance()->getTraceabilityPage()->getEmail()->text();
  QString jsonMessageFormat = QString("{\"rdf:RDF\" : {\n"
                                       "      \"xmlns:rdf\" : \"http://www.w3.org/1999/02/22-rdf-syntax-ns#\",\n"
                                       "      \"xmlns:prov\": \"http://www.w3.org/ns/prov#\",\n"
                                       "      \"messageFormatVersion\": \"1.4\",\n"
                                       "      \"prov:Entity\": [\n"
                                       "            {\n"
                                       "            \"rdf:about\": \"%2\",\n"
                                       "            \"type\": \"Simulation Tool\",\n"
                                       "            \"version\": \"OpenModelica\",\n"
                                       "            \"name\": \"OpenModelica\"\n"
                                       "            },\n"
                                       "            {\n"
                                       "            \"rdf:about\" : \"%3\",\n"
                                       "            \"type\" : \"%9\",\n"
                                       "            \"path\" : \"%10\",\n"
                                       "            \"hash\" : \"%11\",\n"
                                       "            \"prov:wasAttributedTo\": {\"prov:Agent\": {\"rdf:about\": \"%4\"}},\n"
                                       "            \"prov:wasGeneratedBy\": {\"prov:Activity\": {\"rdf:about\": \"%5\"}},\n"
                                       "            \"prov:wasDerivedFrom\": {\"prov:Entity\": [{\"rdf:about\": \"%6\"}]}\n"
                                       "            }\n"
                                       "      ],\n "
                                       "     \"prov:Agent\": [\n"
                                       "            {\n"
                                       "            \"rdf:about\": \"%4\",\n"
                                       "            \"name\": \"%7\",\n"
                                       "            \"email\": \"%8\"\n"
                                       "            }\n"
                                       "     ],\n"
                                       "     \"prov:Activity\": [\n"
                                       "            {\n"
                                       "            \"time\": \"2016-09-19T13:53:06Z\",\n"
                                       "            \"type\": \"%1\",\n"
                                       "            \"prov:wasAssociatedWith\": {\"prov:Agent\": {\"rdf:about\": \"%4\"}},\n"
                                       "            \"prov:used\": {\"prov:Entity\": [{\"rdf:about\": \"%2\"}]},\n"
                                       "            \"rdf:about\": \"%5\"\n"
                                       "            }\n"
                                       "     ]\n"
                                       "}}").arg(modelingActivity.simplified()).arg(toolURI.simplified()).arg(fmuFileNameURI.simplified()).arg(agentURI.simplified()).arg(activityURI.simplified()).arg(sourceModelFileNameURI.simplified()).arg(userName).arg(email).arg(entityType.simplified()).arg(path.simplified()).arg(gitHash.simplified());
  sendTraceabilityInformation(jsonMessageFormat);
}

void TraceabilityInformationURI::sendTraceabilityInformation(QString jsonMessageFormat)
{
  QByteArray traceabilityInformation;
  traceabilityInformation.append(jsonMessageFormat.toUtf8());
  // create the request
  QString ipAdress = OptionsDialog::instance()->getTraceabilityPage()->getTraceabilityDaemonIpAdress()->text();
  QString port = OptionsDialog::instance()->getTraceabilityPage()->getTraceabilityDaemonPort()->text();
  QUrl url("http://"+ ipAdress +":"+ port +"/traces/push/json");
  QNetworkRequest networkRequest(url);
  networkRequest.setHeader(QNetworkRequest::ContentTypeHeader, "application/json" );
  networkRequest.setRawHeader( "Accept-Charset", "UTF-8");
  QNetworkAccessManager * pNetworkAccessManager = new QNetworkAccessManager;
  QNetworkReply *pNetworkReply =   pNetworkAccessManager->post(networkRequest, traceabilityInformation);
  pNetworkReply->ignoreSslErrors();
  connect(pNetworkAccessManager, SIGNAL(finished(QNetworkReply*)),this, SLOT(traceabilityInformationSent(QNetworkReply*)));
}

/*!
 * \brief TraceabilityInformationURI::traceabilityInformationSent
 * \param pNetworkReply
 * Slot activated when QNetworkAccessManager finished signal is raised.\n
 * Shows an error message if the traceability information was not send correctly.\n
 * Deletes QNetworkReply object
 */
void TraceabilityInformationURI::traceabilityInformationSent(QNetworkReply *pNetworkReply)
{
  if (pNetworkReply->error() != QNetworkReply::NoError) {
     QMessageBox::critical(0, QString(Helper::applicationName).append(" - ").append(Helper::error),
                           QString("Following error has occurred while sending the traceability information \n\n%1").arg(pNetworkReply->errorString()),
                           Helper::ok);
  }
  else
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::CompositeModel, "", false, 0, 0, 0, 0,
                                             "The traceability information has been sent to Daemon", Helper::scriptingKind, Helper::notificationLevel));
  pNetworkReply->deleteLater();
}
