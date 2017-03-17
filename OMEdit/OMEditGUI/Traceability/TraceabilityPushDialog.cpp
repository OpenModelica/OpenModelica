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
TraceabilityPushDialog::TraceabilityPushDialog(/*QWidget *pParent*/)
  /*: QDialog(pParent)*/
{
//  setWindowTitle(QString(Helper::applicationName).append(" - ").append(tr("Send Traceability Information to Daemon")));
//  setAttribute(Qt::WA_DeleteOnClose);
//  resize(700, 400);
//  // Traceability information
//  QGroupBox *pTraceabilityInformationGroupBox = new QGroupBox(tr("Traceability Information:"));
//  mpTraceabilityInformationTextBox = new QPlainTextEdit;
//  mpTraceabilityInformationTextBox->setLineWrapMode(QPlainTextEdit::NoWrap);
//  mpTraceabilityInformationTextBox->setFont(QFont(Helper::monospacedFontInfo.family()));
//  mpTraceabilityInformationTextBox->setReadOnly(false);
//  QGridLayout *pTraceabilityInformationLayout = new QGridLayout;
//  pTraceabilityInformationLayout->addWidget(mpTraceabilityInformationTextBox);
//  pTraceabilityInformationGroupBox->setLayout(pTraceabilityInformationLayout);
//  // Commit Traceability URI
//  mpCommitTraceabilityURI = new QCheckBox(tr("Commit traceability URI"));
//  mpCommitTraceabilityURI->setChecked(true);
//  // Create the buttons
//  mpPushTraceabilitytButton = new QPushButton(tr("Push"));
//  mpPushTraceabilitytButton->setEnabled(true);
//  connect(mpPushTraceabilitytButton, SIGNAL(clicked()), SLOT(sendTraceabilityInformation()));
//  mpCancelButton = new QPushButton(Helper::cancel);
//  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
//  // create buttons box
//  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
//  mpButtonBox->addButton(mpPushTraceabilitytButton, QDialogButtonBox::ActionRole);
//  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
//  // set the layout
//  QGridLayout *pMainLayout = new QGridLayout;
//  pMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
//  pMainLayout->addWidget(pTraceabilityInformationGroupBox, 1, 0);
//  pMainLayout->addWidget(mpCommitTraceabilityURI, 2, 0 );
//  pMainLayout->addWidget(mpButtonBox, 3, 0, Qt::AlignRight);
//  setLayout(pMainLayout);

//  translateURIToJsonMessageFormat();
}

void TraceabilityPushDialog::translateURIToJsonMessageFormat() {

//  QString filePath = MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidget()->getLibraryTreeItem()->getFileName();
//  QString nameStructure = MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidget()->getLibraryTreeItem()->getNameStructure();
//  QFileInfo info(filePath);
//  QFile URIFile(info.absolutePath() + "/" + nameStructure +".md");
//  QStringList URIList;
//  if (URIFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
//    QString readURI = URIFile.readAll();
//    URIList = readURI.split(',');
//    if (URIList.at(0).compare("Model Creation") == 0)
//       translateModelCreationURIToJsonMessageFormat(URIList);
//    else if (URIList.at(0).compare("FMU Export") == 0 || URIList.at(0).compare("Model Modification") == 0 || URIList.at(0).compare("ModelDescription Import") == 0)
//       translateFMUExportURIToJsonMessageFormat(URIList);
//    else
//      mpTraceabilityInformationTextBox->setPlainText("Unknown Modeling activity");
//    URIFile.close();
//  }
//  else {
//    mpTraceabilityInformationTextBox->setPlainText("The file " + URIFile.fileName() +" not found");
//  }
}

void TraceabilityPushDialog::translateModelCreationURIToJsonMessageFormat(QStringList modelCreationURIList)
{
//  QString userName = OptionsDialog::instance()->getTraceabilityPage()->getUserName()->text();
//  QString email = OptionsDialog::instance()->getTraceabilityPage()->getEmail()->text();
//  QString fileNameURI , activityURI, agentURI, toolURI;
//  for (int i = 0; i < modelCreationURIList.size(); ++i) {
//    if (i == 1)
//      toolURI = modelCreationURIList.at(1);
//    if (i == 2)
//      agentURI = modelCreationURIList.at(2);
//    if (i == 3)
//      activityURI = modelCreationURIList.at(3);
//    if (i == 4)
//      fileNameURI = modelCreationURIList.at(4);
//  }
//  if (fileNameURI.isEmpty()|| activityURI.isEmpty()|| agentURI.isEmpty()|| toolURI.isEmpty()) {
//    QMessageBox::information(0, QString(Helper::applicationName).append(" - ").append(Helper::error),
//                             QString("The traceability information is not complete. The dialog with incomplete information will pop up."), Helper::ok);
//  }
//  QString jsonMessageFormat = QString("{\"rdf:RDF\" : {\n"
//                                       "      \"xmlns:rdf\" : \"http://www.w3.org/1999/02/22-rdf-syntax-ns#\",\n"
//                                       "      \"xmlns:prov\": \"http://www.w3.org/ns/prov#\",\n"
//                                       "      \"messageFormatVersion\": \"0.1\",\n"
//                                       "      \"prov:Entity\": [\n"
//                                       "            {\n"
//                                       "            \"rdf:about\": \"%4\",\n"
//                                       "            \"type\": \"softwareTool\",\n"
//                                       "            \"name\": \"OpenModelica\"\n"
//                                       "            },\n"
//                                       "            {\n"
//                                       "            \"rdf:about\" : \"%1\",\n"
//                                       "            \"path\" : \"%1\",\n"
//                                       "            \"type\" : \"Model Creation\",\n"
//                                       "            \"prov:wasAttributedTo\": {\"prov:Agent\": {\"rdf:about\": \"%3\"}},\n"
//                                       "            \"prov:wasGeneratedBy\": {\"prov:Activity\": {\"rdf:about\": \"%2\"}}\n"
//                                       "            }\n"
//                                       "      ],\n "
//                                       "     \"prov:Agent\": [\n"
//                                       "            {\n"
//                                       "            \"rdf:about\": \"%3\",\n"
//                                       "            \"name\": \"%5\",\n"
//                                       "            \"Email\": \"%6\"\n"
//                                       "            }\n"
//                                       "     ],\n"
//                                       "     \"prov:Activity\": [\n"
//                                       "            {\n"
//                                       "            \"type\": \"Model Creation\",\n"
//                                       "            \"prov:wasAssociatedWith\": {\"prov:Agent\": {\"rdf:about\": \"%3\"}},\n"
//                                       "            \"prov:used\": {\"prov:Entity\": {\"rdf:about\": \"%4\"}},\n"
//                                       "            \"rdf:about\": \"%2\"\n"
//                                       "            }\n"
//                                       "     ]\n"
//                                       "}}").arg(fileNameURI.simplified()).arg(activityURI.simplified()).arg(agentURI.simplified()).arg(toolURI.simplified()).arg(userName).arg(email);
//  mpTraceabilityInformationTextBox->setPlainText(jsonMessageFormat);
}

void TraceabilityPushDialog::translateFMUExportURIToJsonMessageFormat(QStringList fmuExportURIList)
{
//  QString toolURI, activityURI, agentURI, modelingActivity, sourceModelFileNameURI, fmuFileNameURI, email, userName;
//  userName = OptionsDialog::instance()->getTraceabilityPage()->getUserName()->text();
//  email = OptionsDialog::instance()->getTraceabilityPage()->getEmail()->text();
//  for (int i = 0; i < fmuExportURIList.size(); ++i) {
//    if (i == 0)
//       modelingActivity = fmuExportURIList.at(0);
//    if (i == 1)
//      toolURI = fmuExportURIList.at(1);
//    if (i == 2)
//      fmuFileNameURI = fmuExportURIList.at(2);
//    if (i == 3)
//      agentURI = fmuExportURIList.at(3);
//    if (i == 4)
//      activityURI = fmuExportURIList.at(4);
//    if (i == 5)
//      sourceModelFileNameURI = fmuExportURIList.at(5);
//  }
//  if (sourceModelFileNameURI.isEmpty()|| activityURI.isEmpty()|| agentURI.isEmpty()|| toolURI.isEmpty() || modelingActivity.isEmpty()|| fmuFileNameURI.isEmpty()) {
//    QMessageBox::information(0, QString(Helper::applicationName).append(" - ").append(Helper::error),
//                             QString("The traceability information is not complete. The dialog with incomplete information will pop up."), Helper::ok);
//  }
//  QString jsonMessageFormat = QString("{\"rdf:RDF\" : {\n"
//                                       "      \"xmlns:rdf\" : \"http://www.w3.org/1999/02/22-rdf-syntax-ns#\",\n"
//                                       "      \"xmlns:prov\": \"http://www.w3.org/ns/prov#\",\n"
//                                       "      \"messageFormatVersion\": \"0.1\",\n"
//                                       "      \"prov:Entity\": [\n"
//                                       "            {\n"
//                                       "            \"rdf:about\": \"%2\",\n"
//                                       "            \"type\": \"softwareTool\",\n"
//                                       "            \"name\": \"OpenModelica\"\n"
//                                       "            },\n"
//                                       "            {\n"
//                                       "            \"rdf:about\" : \"%3\",\n"
//                                       "            \"type\" : \"%1\",\n"
//                                       "            \"prov:wasAttributedTo\": {\"prov:Agent\": {\"rdf:about\": \"%4\"}},\n"
//                                       "            \"prov:wasGeneratedBy\": {\"prov:Activity\": {\"rdf:about\": \"%5\"}},\n"
//                                       "            \"prov:wasDerivedFrom\": [{\"prov:Entity\": {\"rdf:about\": \"%6\"}}]\n"
//                                       "            }\n"
//                                       "      ],\n "
//                                       "     \"prov:Agent\": [\n"
//                                       "            {\n"
//                                       "            \"rdf:about\": \"%4\",\n"
//                                       "            \"name\": \"%7\",\n"
//                                       "            \"Email\": \"%8\"\n"
//                                       "            }\n"
//                                       "     ],\n"
//                                       "     \"prov:Activity\": [\n"
//                                       "            {\n"
//                                       "            \"type\": \"%1\",\n"
//                                       "            \"prov:wasAssociatedWith\": {\"prov:Agent\": {\"rdf:about\": \"%4\"}},\n"
//                                       "            \"prov:used\": {\"prov:Entity\": {\"rdf:about\": \"%2\"}},\n"
//                                       "            \"rdf:about\": \"%5\"\n"
//                                       "            }\n"
//                                       "     ]\n"
//                                       "}}").arg(modelingActivity.simplified()).arg(toolURI.simplified()).arg(fmuFileNameURI.simplified()).arg(agentURI.simplified()).arg(activityURI.simplified()).arg(sourceModelFileNameURI.simplified()).arg(userName).arg(email);
//  mpTraceabilityInformationTextBox->setPlainText(jsonMessageFormat);
}

void TraceabilityPushDialog::translateModelCreationURIToJsonMessageFormat(QString modelingActivity, QString toolURI, QString activityURI, QString agentURI, QString fileNameURI)
{
  QString  email, userName;
  userName = OptionsDialog::instance()->getTraceabilityPage()->getUserName()->text();
  email = OptionsDialog::instance()->getTraceabilityPage()->getEmail()->text();
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
                                       "            \"type\" : \"%7\",\n"
                                       "            \"prov:wasAttributedTo\": {\"prov:Agent\": {\"rdf:about\": \"%3\"}},\n"
                                       "            \"prov:wasGeneratedBy\": {\"prov:Activity\": {\"rdf:about\": \"%2\"}}\n"
                                       "            }\n"
                                       "      ],\n "
                                       "     \"prov:Agent\": [\n"
                                       "            {\n"
                                       "            \"rdf:about\": \"%3\",\n"
                                       "            \"name\": \"%5\",\n"
                                       "            \"Email\": \"%6\"\n"
                                       "            }\n"
                                       "     ],\n"
                                       "     \"prov:Activity\": [\n"
                                       "            {\n"
                                       "            \"type\": \"%7\",\n"
                                       "            \"prov:wasAssociatedWith\": {\"prov:Agent\": {\"rdf:about\": \"%3\"}},\n"
                                       "            \"prov:used\": {\"prov:Entity\": {\"rdf:about\": \"%4\"}},\n"
                                       "            \"rdf:about\": \"%2\"\n"
                                       "            }\n"
                                       "     ]\n"
                                       "}}").arg(fileNameURI.simplified()).arg(activityURI.simplified()).arg(agentURI.simplified()).arg(toolURI.simplified()).arg(userName).arg(email).arg(modelingActivity);
  sendTraceabilityInformation(jsonMessageFormat);
}

void TraceabilityPushDialog::translateURIToJsonMessageFormat(QString modelingActivity, QString toolURI, QString activityURI, QString agentURI, QString sourceModelFileNameURI, QString fmuFileNameURI)
{
  QString  email, userName;
  userName = OptionsDialog::instance()->getTraceabilityPage()->getUserName()->text();
  email = OptionsDialog::instance()->getTraceabilityPage()->getEmail()->text();
//  if (sourceModelFileNameURI.isEmpty()|| activityURI.isEmpty()|| agentURI.isEmpty()|| toolURI.isEmpty() || modelingActivity.isEmpty()|| fmuFileNameURI.isEmpty()) {
//    QMessageBox::information(0, QString(Helper::applicationName).append(" - ").append(Helper::error),
//                             QString("The traceability information is not complete. The dialog with incomplete information will pop up."), Helper::ok);
//  }
  QString jsonMessageFormat = QString("{\"rdf:RDF\" : {\n"
                                       "      \"xmlns:rdf\" : \"http://www.w3.org/1999/02/22-rdf-syntax-ns#\",\n"
                                       "      \"xmlns:prov\": \"http://www.w3.org/ns/prov#\",\n"
                                       "      \"messageFormatVersion\": \"0.1\",\n"
                                       "      \"prov:Entity\": [\n"
                                       "            {\n"
                                       "            \"rdf:about\": \"%2\",\n"
                                       "            \"type\": \"softwareTool\",\n"
                                       "            \"name\": \"OpenModelica\"\n"
                                       "            },\n"
                                       "            {\n"
                                       "            \"rdf:about\" : \"%3\",\n"
                                       "            \"type\" : \"%1\",\n"
                                       "            \"prov:wasAttributedTo\": {\"prov:Agent\": {\"rdf:about\": \"%4\"}},\n"
                                       "            \"prov:wasGeneratedBy\": {\"prov:Activity\": {\"rdf:about\": \"%5\"}},\n"
                                       "            \"prov:wasDerivedFrom\": [{\"prov:Entity\": {\"rdf:about\": \"%6\"}}]\n"
                                       "            }\n"
                                       "      ],\n "
                                       "     \"prov:Agent\": [\n"
                                       "            {\n"
                                       "            \"rdf:about\": \"%4\",\n"
                                       "            \"name\": \"%7\",\n"
                                       "            \"Email\": \"%8\"\n"
                                       "            }\n"
                                       "     ],\n"
                                       "     \"prov:Activity\": [\n"
                                       "            {\n"
                                       "            \"type\": \"%1\",\n"
                                       "            \"prov:wasAssociatedWith\": {\"prov:Agent\": {\"rdf:about\": \"%4\"}},\n"
                                       "            \"prov:used\": {\"prov:Entity\": {\"rdf:about\": \"%2\"}},\n"
                                       "            \"rdf:about\": \"%5\"\n"
                                       "            }\n"
                                       "     ]\n"
                                       "}}").arg(modelingActivity.simplified()).arg(toolURI.simplified()).arg(fmuFileNameURI.simplified()).arg(agentURI.simplified()).arg(activityURI.simplified()).arg(sourceModelFileNameURI.simplified()).arg(userName).arg(email);
  sendTraceabilityInformation(jsonMessageFormat);
}

void TraceabilityPushDialog::sendTraceabilityInformation(QString jsonMessageFormat)
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
  QNetworkAccessManager *pNetworkAccessManager = new QNetworkAccessManager;
  QNetworkReply *pNetworkReply = pNetworkAccessManager->post(networkRequest, traceabilityInformation);
  pNetworkReply->ignoreSslErrors();
  if (pNetworkReply->error() != QNetworkReply::NoError) {
     QMessageBox::critical(0, QString(Helper::applicationName).append(" - ").append(Helper::error),
                            QString("Following error has occurred while sending the traceability information \n\n%1").arg(pNetworkReply->errorString()),
                            Helper::ok);
  }
  else {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::CompositeModel, "", false, 0, 0, 0, 0,
                                                                 "The traceability information has been sent to Daemon",
                                                                 Helper::scriptingKind, Helper::notificationLevel));
 }
//      pNetworkReply->deleteLater();
}


/*!
 * \brief TraceabilityPushDialog::sendTraceabilityInformation
 * Slot activated when mpPushTraceabilitytButton clicked signal is raised.\n
 * Sends the traceability information.
 */
void TraceabilityPushDialog::sendTraceabilityInformation()
{
//  QString traceabilityInformation = mpTraceabilityInformationTextBox->toPlainText();
//  QByteArray OSLCTriples;
//  OSLCTriples.append(traceabilityInformation.toUtf8());
//  // create the request
//  QString ipAdress = OptionsDialog::instance()->getTraceabilityPage()->getTraceabilityDaemonIpAdress()->text();
//  QString port = OptionsDialog::instance()->getTraceabilityPage()->getTraceabilityDaemonPort()->text();
//  QUrl url("http://"+ ipAdress +":"+ port +"/traces/push/json");
//  QNetworkRequest networkRequest(url);
//  networkRequest.setHeader(QNetworkRequest::ContentTypeHeader, "application/json" );
//  networkRequest.setRawHeader( "Accept-Charset", "UTF-8");
//  QNetworkAccessManager *pNetworkAccessManager = new QNetworkAccessManager;
//  QNetworkReply *pNetworkReply = pNetworkAccessManager->post(networkRequest, OSLCTriples);
//  pNetworkReply->ignoreSslErrors();
//  connect(pNetworkAccessManager, SIGNAL(finished(QNetworkReply*)), SLOT(traceabilityInformationSent(QNetworkReply*)));
}

/*!
 * \brief TraceabilityPushDialog::traceabilityInformationSent
 * \param pNetworkReply
 * Slot activated when QNetworkAccessManager finished signal is raised.\n
 * Shows an error message if the traceability information was not send correctly.\n
 * Deletes QNetworkReply object
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
                                                                 "The traceability information has been sent to Daemon",
                                                                 Helper::scriptingKind, Helper::notificationLevel));
  pNetworkReply->deleteLater();
//  accept();
}
