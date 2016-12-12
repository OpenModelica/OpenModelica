/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
/*
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#include "CrashReportDialog.h"
#include "Util/Helper.h"
#include "omc_config.h"

#include <QGridLayout>
#include <QMessageBox>

/*!
 * \class CrashReportDialog
 * \brief Interface for sending crash reports.
 */
/*!
 * \brief CrashReportDialog::CrashReportDialog
 */
CrashReportDialog::CrashReportDialog()
  : QDialog(0)
{
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::crashReport));
  setAttribute(Qt::WA_DeleteOnClose);
  // set heading
  mpCrashReportHeading = Utilities::getHeadingLabel(Helper::crashReport);
  // set separator line
  mpHorizontalLine = Utilities::getHeadingLine();
  // Email label and textbox
  mpEmailLabel = new Label(tr("Your Email (in case you want us to contact you regarding this error):"));
  mpEmailTextBox = new QLineEdit;
  // bug description label and textbox
  mpBugDescriptionLabel = new Label(tr("Describe in a few words what you were doing when the error occurred:"));
  mpBugDescriptionTextBox = new QPlainTextEdit(
    QString("%1 connected to %2%5.\nThe running OS is %3 on %4.\n").arg(GIT_SHA,Helper::OpenModelicaVersion,
#if (QT_VERSION >= QT_VERSION_CHECK(5, 4, 0))
  QSysInfo::prettyProductName(), QSysInfo::currentCpuArchitecture(),
#elif defined(__APPLE__)
  "OSX", "unknown (probably amd64)",
#else
  "unknown", "unknown",
#endif
#if defined(LSB_RELEASE)
  " built for " LSB_RELEASE
#else
  ""
#endif
  )
  );
  // files label and checkboxes
  mpFilesDescriptionLabel = new Label(tr("Following selected files will be sent along with the crash report,"));
  QString& tmpPath = Utilities::tempDirectory();
  // omeditcommunication.log file checkbox
  QFileInfo OMEditCommunicationLogFileInfo(QString("%1omeditcommunication.log").arg(tmpPath));
  mpOMEditCommunicationLogFileCheckBox = new QCheckBox(OMEditCommunicationLogFileInfo.absoluteFilePath());
  if (OMEditCommunicationLogFileInfo.exists()) {
    mpOMEditCommunicationLogFileCheckBox->setChecked(true);
  } else {
    mpOMEditCommunicationLogFileCheckBox->setChecked(false);
  }
  // omeditcommands.mos file checkbox
  QFileInfo OMEditCommandsMosFileInfo(QString("%1omeditcommands.mos").arg(tmpPath));
  mpOMEditCommandsMosFileCheckBox = new QCheckBox(OMEditCommandsMosFileInfo.absoluteFilePath());
  if (OMEditCommandsMosFileInfo.exists()) {
    mpOMEditCommandsMosFileCheckBox->setChecked(true);
  } else {
    mpOMEditCommandsMosFileCheckBox->setChecked(false);
  }
  // openmodelica.stacktrace.OMEdit file checkbox
  QFileInfo OMStackTraceFileInfo(QString("%1openmodelica.stacktrace.%2").arg(tmpPath).arg(Helper::OMCServerName));
  mpOMStackTraceFileCheckBox = new QCheckBox(OMStackTraceFileInfo.absoluteFilePath());
  if (OMStackTraceFileInfo.exists()) {
    mpOMStackTraceFileCheckBox->setChecked(true);
  } else {
    mpOMStackTraceFileCheckBox->setChecked(false);
  }
  // create send report button
  mpSendReportButton = new QPushButton(tr("Send Report"));
  mpSendReportButton->setAutoDefault(true);
  connect(mpSendReportButton, SIGNAL(clicked()), SLOT(sendReport()));
  mpCancelButton = new QPushButton(Helper::cancel);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // create buttons box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpSendReportButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // set grid layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addWidget(mpCrashReportHeading, 0, 0);
  pMainLayout->addWidget(mpHorizontalLine, 1, 0);
  pMainLayout->addWidget(mpEmailLabel, 2, 0);
  pMainLayout->addWidget(mpEmailTextBox, 3, 0);
  pMainLayout->addWidget(mpBugDescriptionLabel, 4, 0);
  pMainLayout->addWidget(mpBugDescriptionTextBox, 5, 0);
  int index = 6;
  if (OMEditCommunicationLogFileInfo.exists() || OMEditCommandsMosFileInfo.exists() || OMStackTraceFileInfo.exists()) {
    pMainLayout->addWidget(mpFilesDescriptionLabel, index, 0);
    index++;
  }
  if (OMEditCommunicationLogFileInfo.exists()) {
    pMainLayout->addWidget(mpOMEditCommunicationLogFileCheckBox, index, 0);
    index++;
  }
  if (OMEditCommandsMosFileInfo.exists()) {
    pMainLayout->addWidget(mpOMEditCommandsMosFileCheckBox, index, 0);
    index++;
  }
  if (OMStackTraceFileInfo.exists()) {
    pMainLayout->addWidget(mpOMStackTraceFileCheckBox, index, 0);
    index++;
  }
  pMainLayout->addWidget(mpButtonBox, index, 0, 1, 1, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
 * \brief CrashReportDialog::sendReport
 * Slot activated when mpSendReportButton clicked signal is raised.\n
 * Sends the crash report along with selected log files.
 */
void CrashReportDialog::sendReport()
{
  // ask for e-mail address.
  if (mpEmailTextBox->text().isEmpty()) {
    QMessageBox *pMessageBox = new QMessageBox;
    pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::error));
    pMessageBox->setIcon(QMessageBox::Critical);
    pMessageBox->setAttribute(Qt::WA_DeleteOnClose);
    pMessageBox->setText(tr("We can't contact you with a possible solution if you don't provide a valid e-mail address."));
    pMessageBox->addButton(tr("Send without e-mail"), QMessageBox::AcceptRole);
    pMessageBox->addButton(tr("Let me enter e-mail"), QMessageBox::RejectRole);
    int answer = pMessageBox->exec();
    switch (answer) {
      case QMessageBox::RejectRole:
        mpEmailTextBox->setFocus();
        return;
      case QMessageBox::AcceptRole:
      default:
        break;
    }
  }
  // create the report.
  QHttpMultiPart *pHttpMultiPart = new QHttpMultiPart(QHttpMultiPart::FormDataType);
  // email
  QHttpPart emailHttpPart;
  emailHttpPart.setHeader(QNetworkRequest::ContentDispositionHeader, QVariant("form-data; name=\"email\""));
  emailHttpPart.setBody(mpEmailTextBox->text().toUtf8());
  pHttpMultiPart->append(emailHttpPart);
  // bug description
  QHttpPart bugDescriptionHttpPart;
  bugDescriptionHttpPart.setHeader(QNetworkRequest::ContentDispositionHeader, QVariant("form-data; name=\"bugdescription\""));
  bugDescriptionHttpPart.setBody(mpBugDescriptionTextBox->toPlainText().toUtf8());
  pHttpMultiPart->append(bugDescriptionHttpPart);
  // OMEditCommunicationLogFile
  if (mpOMEditCommunicationLogFileCheckBox->isChecked()) {
    QHttpPart OMEditCommunicationLogFileHttpPart;
    OMEditCommunicationLogFileHttpPart.setHeader(QNetworkRequest::ContentTypeHeader, QVariant("text/plain"));
    OMEditCommunicationLogFileHttpPart.setHeader(QNetworkRequest::ContentDispositionHeader, QVariant("form-data; name=\"omeditcommunication.log\"; filename=\"omeditcommunication.log\""));
    QFile *pOMEditCommunicationLogFileFile = new QFile(mpOMEditCommunicationLogFileCheckBox->text());
    pOMEditCommunicationLogFileFile->open(QIODevice::ReadOnly);
    OMEditCommunicationLogFileHttpPart.setBodyDevice(pOMEditCommunicationLogFileFile);
    pOMEditCommunicationLogFileFile->setParent(pHttpMultiPart); // file will be deleted when we delete pHttpMultiPart
    pHttpMultiPart->append(OMEditCommunicationLogFileHttpPart);
  }
  // OMEditCommandsMosFile
  if (mpOMEditCommandsMosFileCheckBox->isChecked()) {
    QHttpPart OMEditCommandsMosFileHttpPart;
    OMEditCommandsMosFileHttpPart.setHeader(QNetworkRequest::ContentTypeHeader, QVariant("text/plain"));
    OMEditCommandsMosFileHttpPart.setHeader(QNetworkRequest::ContentDispositionHeader, QVariant("form-data; name=\"omeditcommands.mos\"; filename=\"omeditcommands.mos\""));
    QFile *pOMEditCommandsMosFile = new QFile(mpOMEditCommandsMosFileCheckBox->text());
    pOMEditCommandsMosFile->open(QIODevice::ReadOnly);
    OMEditCommandsMosFileHttpPart.setBodyDevice(pOMEditCommandsMosFile);
    pOMEditCommandsMosFile->setParent(pHttpMultiPart); // file will be deleted when we delete pHttpMultiPart
    pHttpMultiPart->append(OMEditCommandsMosFileHttpPart);
  }
  // OMStackTraceFile
  if (mpOMStackTraceFileCheckBox->isChecked()) {
    QHttpPart OMStackTraceFileCheckBoxHttpPart;
    OMStackTraceFileCheckBoxHttpPart.setHeader(QNetworkRequest::ContentTypeHeader, QVariant("text/plain"));
    OMStackTraceFileCheckBoxHttpPart.setHeader(QNetworkRequest::ContentDispositionHeader, QVariant("form-data; name=\"openmodelica.stacktrace.OMEdit\"; filename=\"openmodelica.stacktrace.OMEdit\""));
    QFile *pOMStackTraceFile = new QFile(mpOMStackTraceFileCheckBox->text());
    pOMStackTraceFile->open(QIODevice::ReadOnly);
    OMStackTraceFileCheckBoxHttpPart.setBodyDevice(pOMStackTraceFile);
    pOMStackTraceFile->setParent(pHttpMultiPart); // file will be deleted when we delete pHttpMultiPart
    pHttpMultiPart->append(OMStackTraceFileCheckBoxHttpPart);
  }
  // create the request
  QUrl url("https://dev.openmodelica.org/omeditcrashreports/cgi-bin/server.py");
  QNetworkRequest networkRequest(url);
  QNetworkAccessManager *pNetworkAccessManager = new QNetworkAccessManager;
  QNetworkReply *pNetworkReply = pNetworkAccessManager->post(networkRequest, pHttpMultiPart);
  pNetworkReply->ignoreSslErrors();
  pHttpMultiPart->setParent(pNetworkReply); // delete the pHttpMultiPart with the pNetworkReply
  connect(pNetworkAccessManager, SIGNAL(finished(QNetworkReply*)), SLOT(reportSent(QNetworkReply*)));
}

/*!
 * \brief CrashReportDialog::reportSent
 * \param pNetworkReply
 * Slot activated when QNetworkAccessManager finished signal is raised.\n
 * Shows an error message if crash report was not send correctly.\n
 * Deletes QNetworkReply object which deletes the QHttpMultiPart and QFile objects attached with it.
 */
void CrashReportDialog::reportSent(QNetworkReply *pNetworkReply)
{
  if (pNetworkReply->error() != QNetworkReply::NoError) {
    QMessageBox::critical(0, QString(Helper::applicationName).append(" - ").append(Helper::error),
                          QString("Following error has occurred while sending crash report \n\n%1").arg(pNetworkReply->errorString()),
                          Helper::ok);
  }
  pNetworkReply->deleteLater();
  accept();
}
