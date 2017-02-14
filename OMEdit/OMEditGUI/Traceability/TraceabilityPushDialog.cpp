#include "TraceabilityPushDialog.h"
#include "MainWindow.h"
#include "Util/Helper.h"
#include "Modeling/MessagesWidget.h"
#include "Options/OptionsDialog.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Git/GitCommands.h"

/*!
 * \class TraceabilityPushDialog
 * \brief Creates a dialog that shows the traceability information.
 */
/*!
 * \brief TraceabilityPushDialog::TraceabilityPushDialog
 * \param pMainWindow - pointer to MainWindow
 */
TraceabilityPushDialog::TraceabilityPushDialog(QWidget *pParent)
  : QDialog(pParent)
{
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(tr("Send Traceability Information to Daemon")));
  setAttribute(Qt::WA_DeleteOnClose);
  resize(700, 400);
  // Traceability information
  QGroupBox *pTraceabilityInformationGroupBox = new QGroupBox(tr("Traceability Information:"));
  mpTraceabilityInformationTextBox = new QPlainTextEdit;
  mpTraceabilityInformationTextBox->setLineWrapMode(QPlainTextEdit::NoWrap);
//  mpTraceabilityInformationTextBox->setFont(QFont(Helper::monospacedFontInfo.family()));
  mpTraceabilityInformationTextBox->setReadOnly(false);
  QGridLayout *pTraceabilityInformationLayout = new QGridLayout;
  pTraceabilityInformationLayout->addWidget(mpTraceabilityInformationTextBox);
  pTraceabilityInformationGroupBox->setLayout(pTraceabilityInformationLayout);
  // Commit Traceability URI
  mpCommitTraceabilityURI = new QCheckBox(tr("Commit traceability URI"));
  mpCommitTraceabilityURI->setChecked(true);
  // Create the buttons
  mpPushTraceabilitytButton = new QPushButton(tr("Push"));
  mpPushTraceabilitytButton->setEnabled(true);
  connect(mpPushTraceabilitytButton, SIGNAL(clicked()), SLOT(sendTraceabilityInformation()));
  mpCancelButton = new QPushButton(Helper::cancel);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // create buttons box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpPushTraceabilitytButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // set the layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addWidget(pTraceabilityInformationGroupBox, 1, 0);
  pMainLayout->addWidget(mpCommitTraceabilityURI, 2, 0 );
  pMainLayout->addWidget(mpButtonBox, 3, 0, Qt::AlignRight);
  setLayout(pMainLayout);

  translateURIToJsonMessageFormat();

}

void TraceabilityPushDialog::translateURIToJsonMessageFormat()
{
  QString filePath = MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidget()->getLibraryTreeItem()->getFileName();
  QString nameStructure = MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidget()->getLibraryTreeItem()->getNameStructure();
  QFileInfo info(filePath);
  QFile URIFile(info.absolutePath() + "/" + nameStructure +".md");

  QString fileNameURI, activityURI, agentURI, toolURI;
  QString Test;
  QStringList URIList;
  URIFile.open(QIODevice::ReadOnly | QIODevice::Text);
  Test = URIFile.readAll();
  URIList = Test.split(',');
  URIFile.close();
  for (int i = 0; i < URIList.size(); ++i){
      fileNameURI = URIList.at(0);
      activityURI = URIList.at(1);
      agentURI = URIList.at(2);
      toolURI =URIList.at(3);
    }

 QString jsonMessageFormat = QString("{\"rdf:RDF\" : {\n"
                                          "      \"xmlns:rdf\" : \"http://www.w3.org/1999/02/22-rdf-syntax-ns#\",\n"
                                          "      \"xmlns:prov\": \"http://www.w3.org/ns/prov#\",\n"
                                          "      \"messageFormatVersion\": \"0.1\",\n"
                                          "      \"prov:Entity\": [\n"
                                          "            {\n"
                                          "            \"rdf:about\": \"%4\",\n"
                                          "            \"type\": \"softwareTool\",\n"
                                          "            \"name\": \"OpenModelica\"\n"
                                          "            },\n"
                                          "            {\n"
                                          "            \"rdf:about\" : \"%1\",\n"
                                          "            \"path\" : \"%1\",\n"
                                          "            \"type\" : \"%2\",\n"
                                          "            \"prov:wasAttributedTo\": {\"prov:Agent\": {\"rdf:about\": \"%3\"}},\n"
                                          "            \"prov:wasGeneratedBy\": {\"prov:Activity\": {\"rdf:about\": \"%2\"}}\n"
                                          "            }\n"
                                          "      ],\n "
                                          "     \"prov:Agent\": [\n"
                                          "            {\n"
                                          "            \"rdf:about\": \"%3\",\n"
                                          "            \"name\": \"Alachew Mengist\",\n"
                                          "            \"email\": \"alachew.mengist@liu.se\"\n"
                                          "            }\n"
                                          "     ],\n"
                                          "     \"prov:Activity\": [\n"
                                          "            {\n"
                                          "            \"type\": \"activity\",\n"
                                          "            \"prov:wasAssociatedWith\": {\"prov:Agent\": {\"rdf:about\": \"%3\"}},\n"
                                          "            \"prov:used\": {\"prov:Entity\": {\"rdf:about\": \"%4\"}},\n"
                                          "            \"rdf:about\": \"%2\"\n"
                                          "            }\n"
                                          "     ]\n"
                                          "}}").arg(fileNameURI.simplified()).arg(activityURI.simplified()).arg(agentURI.simplified()).arg(toolURI.simplified());

  mpTraceabilityInformationTextBox->setPlainText(jsonMessageFormat);
}
/*!
 * \brief TraceabilityPushDialog::sendTraceabilityInformation
 * Slot activated when mpPushTraceabilitytButton clicked signal is raised.\n
 * Sends the traceability information.
 */
void TraceabilityPushDialog::sendTraceabilityInformation()
{
  QString traceabilityInformation = mpTraceabilityInformationTextBox->toPlainText();
  QByteArray OSLCTriples;
  OSLCTriples.append(traceabilityInformation.toUtf8());
  // create the request
  QString ipAdress = OptionsDialog::instance()->getTraceabilityPage()->getTraceabilityDaemonIpAdress()->text();
  QString port = OptionsDialog::instance()->getTraceabilityPage()->getTraceabilityDaemonPort()->text();
  QUrl url("http://"+ ipAdress +":"+ port +"/traces/push/json");
  QNetworkRequest networkRequest(url);
  networkRequest.setHeader(QNetworkRequest::ContentTypeHeader, "application/json" );
  networkRequest.setRawHeader( "Accept-Charset", "UTF-8");
  QNetworkAccessManager *pNetworkAccessManager = new QNetworkAccessManager;
  QNetworkReply *pNetworkReply = pNetworkAccessManager->post(networkRequest, OSLCTriples);
  pNetworkReply->ignoreSslErrors();
  connect(pNetworkAccessManager, SIGNAL(finished(QNetworkReply*)), SLOT(traceabilityInformationSent(QNetworkReply*)));
}

/*!
 * \brief TraceabilityPushDialog::traceabilityInformationSent
 * \param pNetworkReply
 * Slot activated when QNetworkAccessManager finished signal is raised.\n
 * Shows an error message if the traceability information was not send correctly.\n
 * Deletes QNetworkReply object which deletes the QHttpMultiPart and QFile objects attached with it.
 */
void TraceabilityPushDialog::traceabilityInformationSent(QNetworkReply *pNetworkReply)
{
  if (pNetworkReply->error() != QNetworkReply::NoError) {
     QMessageBox::critical(0, QString(Helper::applicationName).append(" - ").append(Helper::error),
                            QString("Following error has occurred while sending the traceability information \n\n%1").arg(pNetworkReply->errorString()),
                            Helper::ok);
  }
  else
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::CompositeModel, "", false, 0, 0, 0, 0,
                                                                 tr("The traceability information has been sent to Daemon"),
                                                                 Helper::scriptingKind, Helper::notificationLevel));
  pNetworkReply->deleteLater();
  accept();
}
