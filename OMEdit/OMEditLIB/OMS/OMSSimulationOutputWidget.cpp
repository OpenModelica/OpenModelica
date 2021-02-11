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

#include "OMSSimulationOutputWidget.h"
#include "Util/Helper.h"
#include "MainWindow.h"
#include "OMSSimulationDialog.h"
#include "OMSProxy.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Options/OptionsDialog.h"
#include "Util/OutputPlainTextEdit.h"
#include "zmq.h"

#include <QGridLayout>

/*!
 * \class OMSSimulationOutputWidget
 * \brief Simulation output window.
 */
/*!
 * \brief OMSSimulationOutputWidget::OMSSimulationOutputWidget
 * Creates a simulation output window.
 * \param cref
 * \param fileName
 * \param pParent
 */
OMSSimulationOutputWidget::OMSSimulationOutputWidget(const QString &cref, const QString &fileName, QWidget *pParent)
  : QWidget(pParent), mCref(cref)
{
  setWindowTitle(QString("%1 - %2 - %3").arg(Helper::applicationName, mCref, Helper::simulationOutput));
  // progress label
  mpProgressLabel = new Label(tr("Running simulation of <b>%1</b>. Please wait for a while.").arg(mCref));
  mpProgressLabel->setTextFormat(Qt::RichText);
  mpCancelSimulationButton = new QPushButton(Helper::cancelSimulation);
  mpCancelSimulationButton->setEnabled(false);
  connect(mpCancelSimulationButton, SIGNAL(clicked()), SLOT(cancelSimulation()));
  mpProgressBar = new QProgressBar;
  mpProgressBar->setAlignment(Qt::AlignHCenter);
  mpProgressBar->setRange(0, 100);
  mpProgressBar->setTextVisible(true);
  // simulation output
  mpSimulationOutputPlainTextEdit = new OutputPlainTextEdit;
  mpSimulationOutputPlainTextEdit->setFont(QFont(Helper::monospacedFontInfo.family()));
  // layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(5, 5, 5, 5);
  pMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addWidget(mpProgressLabel, 0, 0, 1, 2);
  pMainLayout->addWidget(mpProgressBar, 1, 0);
  pMainLayout->addWidget(mpCancelSimulationButton, 1, 1);
  pMainLayout->addWidget(mpSimulationOutputPlainTextEdit, 2, 0, 1, 2);
  setLayout(pMainLayout);
  // save the model start time
  OMSProxy::instance()->getStartTime(mCref, &mStartTime);
  // save the model stop time
  OMSProxy::instance()->getStopTime(mCref, &mStopTime);
  // create the ArchivedSimulationItem
  mpArchivedOMSSimulationItem = new ArchivedOMSSimulationItem(mCref, mStartTime, mStopTime, this);
  MainWindow::instance()->getOMSSimulationDialog()->getArchivedSimulationsTreeWidget()->addTopLevelItem(mpArchivedOMSSimulationItem);
  // save the last modified datetime of result file.
  char *resultFileName = (char*)"";
  int bufferSize;
  OMSProxy::instance()->getResultFile(mCref, &resultFileName, &bufferSize);
  mResultFilePath = QString("%1/%2").arg(OptionsDialog::instance()->getGeneralSettingsPage()->getWorkingDirectory(), QString(resultFileName));
  // save the current datetime as last modified datetime for result file.
  mResultFileLastModifiedDateTime = QDateTime::currentDateTime();
  mpSimulationProcess = 0;
  mIsSimulationProcessKilled = false;
  mIsSimulationProcessRunning = false;
  // create subscriber socket
  mpContext = zmq_ctx_new();
  mpSubscriberSocket = zmq_socket(mpContext, ZMQ_SUB);
  int rc = zmq_bind(mpSubscriberSocket, "tcp://127.0.0.1:*");
  if (rc == 0) {
    // get the end point
    const size_t endPointSize = 30;
    char endPoint[endPointSize];
    zmq_getsockopt(mpSubscriberSocket, ZMQ_LAST_ENDPOINT, &endPoint, (size_t *)&endPointSize);
    zmq_setsockopt(mpSubscriberSocket, ZMQ_SUBSCRIBE, "", 0);
    mpSubscriberSocketTimer = new QTimer;
    mpSubscriberSocketTimer->setInterval(10);
    connect(mpSubscriberSocketTimer, SIGNAL(timeout()), SLOT(simulationProgressJson()));
    mpSubscriberSocketTimer->start();
    // start the simulation process
    mpSimulationProcess = new QProcess;
    mpSimulationProcess->setWorkingDirectory(OptionsDialog::instance()->getGeneralSettingsPage()->getWorkingDirectory());
    connect(mpSimulationProcess, SIGNAL(started()), SLOT(simulationProcessStarted()));
    connect(mpSimulationProcess, SIGNAL(readyReadStandardOutput()), SLOT(readSimulationStandardOutput()));
    connect(mpSimulationProcess, SIGNAL(readyReadStandardError()), SLOT(readSimulationStandardError()));
  #if (QT_VERSION >= QT_VERSION_CHECK(5, 6, 0))
    connect(mpSimulationProcess, SIGNAL(errorOccurred(QProcess::ProcessError)), SLOT(simulationProcessError(QProcess::ProcessError)));
  #else
    connect(mpSimulationProcess, SIGNAL(error(QProcess::ProcessError)), SLOT(simulationProcessError(QProcess::ProcessError)));
  #endif
    connect(mpSimulationProcess, SIGNAL(finished(int,QProcess::ExitStatus)), SLOT(simulationProcessFinished(int,QProcess::ExitStatus)));
    QStringList args(QString("C:/OpenModelica/OMSimulator/src/OMSimulatorServer/OMSimulatorServer.py"));
    args << QString("--endpoint-pub=%1").arg(QString(endPoint));
    args << QString("--model=%1").arg(fileName);
    // start the executable
    QString process = QString("%1/bin/OMSimulatorPython3").arg(Helper::OpenModelicaHome);
  #ifdef WIN32
    process = process.append(".bat");
  #endif
    // run the simulation executable to create the result file
    writeSimulationOutput(QString("%1 %2\n").arg(process).arg(args.join(" ")), StringHandler::OMEditInfo);
    mpSimulationProcess->start(process, args);
  } else {
    writeSimulationOutput(QString("Error creating ZeroMQ subscriber socket. zmq_bind failed: %1\n").arg(strerror(errno)), StringHandler::OMEditInfo);
  }
}

/*!
 * \brief OMSSimulationOutputWidget::~OMSSimulationOutputWidget
 * Saves the simulation output window geometry.
 */
OMSSimulationOutputWidget::~OMSSimulationOutputWidget()
{
  if (OptionsDialog::instance()->getGeneralSettingsPage()->getPreserveUserCustomizations()) {
    Utilities::getApplicationSettings()->setValue("OMSSimulationOutputWidget/geometry", saveGeometry());
  }
  if (mpSimulationProcess) {
    mpSimulationProcess->deleteLater();
  }
  zmq_close(mpSubscriberSocket);
  zmq_ctx_destroy(mpContext);
}

/*!
 * \brief OMSSimulationOutputWidget::simulationProcessStarted
 * Updates the simulation output window when the simulation has started.
 */
void OMSSimulationOutputWidget::simulationProcessStarted()
{
  mIsSimulationProcessRunning = true;
  mpProgressLabel->setText(tr("Running simulation of %1. Please wait for a while.").arg(mCref));
  mpProgressBar->setRange(0, 100);
  mpProgressBar->setTextVisible(true);
  mpCancelSimulationButton->setEnabled(true);
  mpArchivedOMSSimulationItem->setStatus(Helper::running);
}

void OMSSimulationOutputWidget::readSimulationStandardOutput()
{
  writeSimulationOutput(QString(mpSimulationProcess->readAllStandardOutput()), StringHandler::Unknown);
}

void OMSSimulationOutputWidget::readSimulationStandardError()
{
  writeSimulationOutput(QString(mpSimulationProcess->readAllStandardError()), StringHandler::Error);
}

void OMSSimulationOutputWidget::simulationProcessError(QProcess::ProcessError error)
{
  Q_UNUSED(error);
  mpSubscriberSocketTimer->stop();
  mIsSimulationProcessRunning = false;
  /* this signal is raised when we kill the simulation process forcefully. */
  if (!isSimulationProcessKilled()) {
    writeSimulationOutput(mpSimulationProcess->errorString(), StringHandler::Error);
  }
}

/*!
 * \brief OMSSimulationOutputWidget::writeSimulationOutput
 * Writes the simulation output.
 * \param output
 * \param type
 */
void OMSSimulationOutputWidget::writeSimulationOutput(const QString &output, StringHandler::SimulationMessageType type)
{
  QTextCharFormat textCharFormat;
  textCharFormat.setForeground(StringHandler::getSimulationMessageTypeColor(type));
  mpSimulationOutputPlainTextEdit->appendOutput(output, textCharFormat);
}

/*!
 * \brief OMSSimulationOutputWidget::simulationProgressJson
 * Reads the simulation progress json and updates the progress bar.
 */
void OMSSimulationOutputWidget::simulationProgressJson()
{
  zmq_msg_t replyMsg;
  zmq_msg_init(&replyMsg);
  int size = zmq_msg_recv(&replyMsg, mpSubscriberSocket, ZMQ_DONTWAIT);
  if (size > -1) {
    // copy the zmq_msg_t to char*
    char *reply = (char*)malloc(size + 1);
    memcpy(reply, zmq_msg_data(&replyMsg), size);
    reply[size] = 0;
    QString progressJson = QString(reply);
    int colonIndex = progressJson.indexOf(":");
    if (colonIndex != -1) {
      QString progressStr = progressJson.mid(colonIndex + 1);
      progressStr.chop(1);
      bool ok;
      int progress = progressStr.toInt(&ok);
      if (ok) {
        mpProgressBar->setValue(progress);
      }
    }
  }
  // release the zmq_msg_t
  zmq_msg_close(&replyMsg);
}

/*!
 * \brief OMSSimulationOutputWidget::simulationProcessFinished
 * Updates the simulation output window when the simulation is finished.
 * \param exitCode
 * \param exitStatus
 */
void OMSSimulationOutputWidget::simulationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
  mpSubscriberSocketTimer->stop();
  mIsSimulationProcessRunning = false;
  QString exitCodeStr = tr("Simulation process failed. Exited with code %1.").arg(QString::number(exitCode));
  if (exitStatus == QProcess::NormalExit && exitCode == 0) {
    writeSimulationOutput(tr("Simulation process finished successfully."), StringHandler::OMEditInfo);
  } else if (mpSimulationProcess->error() == QProcess::UnknownError) {
    writeSimulationOutput(exitCodeStr, StringHandler::Error);
  } else {
    writeSimulationOutput(mpSimulationProcess->errorString() + "\n" + exitCodeStr, StringHandler::Error);
  }

  mpProgressLabel->setText(tr("Simulation of %1 is finished.").arg(mCref));
  mpProgressBar->setValue(mpProgressBar->maximum());
  mpCancelSimulationButton->setEnabled(false);
  // simulation finished show the results
  MainWindow::instance()->getOMSSimulationDialog()->simulationFinished(mResultFilePath, mResultFileLastModifiedDateTime);
  mpArchivedOMSSimulationItem->setStatus(Helper::finished);
}

/*!
 * \brief OMSSimulationOutputWidget::cancelSimulation
 * Slot activated when mpCancelSimulationButton clicked SIGNAL is raised.\n
 * Cancels the running simulation.
 */
void OMSSimulationOutputWidget::cancelSimulation()
{
  if (isSimulationProcessRunning()) {
    mIsSimulationProcessKilled = true;
    mpSimulationProcess->kill();
    mpProgressLabel->setText(tr("Simulation of %1 is cancelled.").arg(mCref));
    mpProgressBar->setValue(mpProgressBar->maximum());
    mpCancelSimulationButton->setEnabled(false);
    mpArchivedOMSSimulationItem->setStatus(Helper::finished);
  }
}

/*!
 * \brief OMSSimulationOutputWidget::keyPressEvent
 * Closes the widget when Esc key is pressed.
 * \param event
 */
void OMSSimulationOutputWidget::keyPressEvent(QKeyEvent *event)
{
  if (event->key() == Qt::Key_Escape) {
    close();
    return;
  }
  QWidget::keyPressEvent(event);
}

/*!
 * \brief OMSSimulationOutputWidget::closeEvent
 * Reimplementation of QWidget::closeEvent(). Ignores the event if simulation process is running.
 * \param event
 */
void OMSSimulationOutputWidget::closeEvent(QCloseEvent *event)
{
  if (isSimulationProcessRunning()) {
    event->ignore();
  } else {
    event->accept();
  }
}
