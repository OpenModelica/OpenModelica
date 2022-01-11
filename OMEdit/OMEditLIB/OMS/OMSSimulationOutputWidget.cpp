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
#include "Plotting/VariablesWidget.h"
#include "OMSSimulationDialog.h"
#include "OMSProxy.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Options/OptionsDialog.h"
#include "Simulation/ArchivedSimulationsWidget.h"
#include "Util/OutputPlainTextEdit.h"
#include "zmq.h"

#include <QGridLayout>

const long timeout = 500;

/*!
 * \class SimulationSubscriberSocket
 * \brief Reads the simulation progress in a loop.
 */
/*!
 * \brief SimulationSubscriberSocket::SimulationSubscriberSocket
 */
SimulationSubscriberSocket::SimulationSubscriberSocket()
{
  // create subscriber socket
  mpContext = zmq_ctx_new();
  mpSocket = zmq_socket(mpContext, ZMQ_SUB);
  int rc = zmq_bind(mpSocket, "tcp://127.0.0.1:*");
  if (rc == 0) {
    // get the end point
    const size_t endPointSize = 30;
    char endPoint[endPointSize];
    zmq_getsockopt(mpSocket, ZMQ_LAST_ENDPOINT, &endPoint, (size_t *)&endPointSize);
    zmq_setsockopt(mpSocket, ZMQ_SUBSCRIBE, "", 0);
    mEndPoint = QString(endPoint);
    mErrorString = "";
  } else {
    mEndPoint = "";
    mErrorString = QString("Error creating ZeroMQ subscriber socket. zmq_bind failed: %1\n").arg(strerror(errno));
  }
  mSocketConnected = false;
}

/*!
 * \brief SimulationSubscriberSocket::~SimulationSubscriberSocket
 */
SimulationSubscriberSocket::~SimulationSubscriberSocket()
{
  zmq_close(mpSocket);
  zmq_ctx_destroy(mpContext);
}

/*!
 * \brief SimulationSubscriberSocket::readSimulationData
 * Reads the socket message in a infinite loop in a non-blocking mode.
 */
void SimulationSubscriberSocket::readSimulationData()
{
  while (isSocketConnected()) {
    zmq_msg_t replyMsg;
    zmq_msg_init(&replyMsg);
    int size = zmq_msg_recv(&replyMsg, mpSocket, ZMQ_DONTWAIT);
    if (size > -1) {
      // copy the zmq_msg_t to char*
      char *reply = (char*)malloc(size + 1);
      memcpy(reply, zmq_msg_data(&replyMsg), size);
      reply[size] = 0;
      emit simulationDataPublished(QByteArray(reply));
    }
    zmq_msg_close(&replyMsg);
  }
}

/*!
 * \class SimulationRequestSocket
 * \brief Request socket for simulation.
 */
/*!
 * \brief SimulationRequestSocket::SimulationRequestSocket
 */
SimulationRequestSocket::SimulationRequestSocket()
{
  // create request reply socket
  mpContext = zmq_ctx_new();
  mpSocket = zmq_socket(mpContext, ZMQ_REQ);
  int rc = zmq_bind(mpSocket, "tcp://127.0.0.1:*");
  if (rc == 0) {
    // get the end point
    const size_t endPointSize = 30;
    char endPoint[endPointSize];
    zmq_getsockopt(mpSocket, ZMQ_LAST_ENDPOINT, &endPoint, (size_t *)&endPointSize);
    mEndPoint = QString(endPoint);
    mErrorString = "";
  } else {
    mEndPoint = "";
    mErrorString = QString("Error creating ZeroMQ request socket. zmq_bind failed: %1\n").arg(strerror(errno));
  }
  mSocketConnected = false;
}

/*!
 * \brief SimulationRequestSocket::~SimulationRequestSocket
 */
SimulationRequestSocket::~SimulationRequestSocket()
{
  zmq_close(mpSocket);
  zmq_ctx_destroy(mpContext);
}

/*!
 * \brief SimulationRequestSocket::sendRequest
 * * Send request in json form,
 * {"fcn": "simulation", "arg": "pause"}"
 * \param function
 * \param argument
 */
void SimulationRequestSocket::sendRequest(const QString &function, const QString &argument)
{
  // send request
  QJsonObject jsonObject;
  jsonObject.insert(QStringLiteral("fcn"), QJsonValue::fromVariant(function));
  jsonObject.insert(QStringLiteral("arg"), QJsonValue::fromVariant(argument));
  QJsonDocument doc(jsonObject);
  QByteArray request = doc.toJson(QJsonDocument::Compact);
  const char* request_ = request.constData();
  zmq_msg_t requestMsg;
  zmq_msg_init_size(&requestMsg, strlen(request_));
  // copy the char* to zmq_msg_t
  memcpy(zmq_msg_data(&requestMsg), request_, strlen(request_));
  zmq_msg_send(&requestMsg, mpSocket, 0);
  zmq_msg_close(&requestMsg);

  // read reply
  zmq_msg_t replyMsg;
  zmq_msg_init(&replyMsg);
  int size = zmq_msg_recv(&replyMsg, mpSocket, 0);
  if (size > -1) {
    // copy the zmq_msg_t to char*
    char *reply = (char*)malloc(size + 1);
    memcpy(reply, zmq_msg_data(&replyMsg), size);
    reply[size] = 0;
    emit simulationReply(QByteArray(reply), function, argument);
  }
  zmq_msg_close(&replyMsg);
}

/*!
 * \class OMSSimulationOutputWidget
 * \brief Simulation output window.
 */
/*!
 * \brief OMSSimulationOutputWidget::OMSSimulationOutputWidget
 * Creates a simulation output window.
 * \param cref
 * \param fileName
 * \param interactive
 * \param pParent
 */
OMSSimulationOutputWidget::OMSSimulationOutputWidget(const QString &cref, const QString &fileName, bool interactive, QWidget *pParent)
  : QWidget(pParent), mCref(cref)
{
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
  pMainLayout->setContentsMargins(2, 2, 2, 2);
  pMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addWidget(mpProgressLabel, 0, 0);
  pMainLayout->addWidget(mpProgressBar, 0, 1);
  if (interactive) {
    QPushButton *pPauseButton = new QPushButton("Pause");
    connect(pPauseButton, SIGNAL(clicked()), SLOT(pauseSimulation()));
    pMainLayout->addWidget(pPauseButton, 0, 2);
    QPushButton *pContinueButton = new QPushButton("Continue");
    connect(pContinueButton, SIGNAL(clicked()), SLOT(continueSimulation()));
    pMainLayout->addWidget(pContinueButton, 0, 3);
    QPushButton *pEndButton = new QPushButton("End");
    connect(pEndButton, SIGNAL(clicked()), SLOT(endSimulation()));
    //pMainLayout->addWidget(pEndButton, 0, 4);
  }
  pMainLayout->addWidget(mpCancelSimulationButton, 0, 5);
  pMainLayout->addWidget(mpSimulationOutputPlainTextEdit, 1, 0, 1, 6);
  setLayout(pMainLayout);
  // save the model start time
  OMSProxy::instance()->getStartTime(mCref, &mStartTime);
  // save the model stop time
  OMSProxy::instance()->getStopTime(mCref, &mStopTime);
  // create the ArchivedSimulationItem
  mpArchivedSimulationItem = new ArchivedSimulationItem(mCref, mStartTime, mStopTime, this);
  ArchivedSimulationsWidget::instance()->getArchivedSimulationsTreeWidget()->addTopLevelItem(mpArchivedSimulationItem);
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
  mpSimulationSubscriberSocket = new SimulationSubscriberSocket;
  if (interactive) {
    // create request socket
    mpSimulationRequestSocket = new SimulationRequestSocket;
  } else {
    mpSimulationRequestSocket = 0;
  }
  bool errorInitializingSockets = false;
  if (!mpSimulationSubscriberSocket->getErrorString().isEmpty()) {
    writeSimulationOutput(mpSimulationSubscriberSocket->getErrorString(), StringHandler::Error);
    errorInitializingSockets = true;
  }
  if (interactive && !mpSimulationRequestSocket->getErrorString().isEmpty()) {
    writeSimulationOutput(mpSimulationRequestSocket->getErrorString(), StringHandler::Error);
    errorInitializingSockets = true;
  }
  if (!errorInitializingSockets) {
    mpSimulationSubscriberSocket->moveToThread(&mSimulationSubscribeThread);
    connect(&mSimulationSubscribeThread, SIGNAL(started()), mpSimulationSubscriberSocket, SLOT(readSimulationData()));
    connect(mpSimulationSubscriberSocket, SIGNAL(simulationDataPublished(QByteArray)), this, SLOT(simulationDataPublished(QByteArray)));
    if (mpSimulationRequestSocket) {
      mpSimulationRequestSocket->moveToThread(&mSimulationRequestThread);
      connect(this, SIGNAL(sendRequest(QString,QString)), mpSimulationRequestSocket, SLOT(sendRequest(QString,QString)));
      connect(mpSimulationRequestSocket, SIGNAL(simulationReply(QByteArray,QString,QString)), SLOT(simulationReply(QByteArray,QString,QString)));
    }
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
    QStringList args(QString("%1/share/OMSimulator/scripts/OMSimulatorServer.py").arg(Helper::OpenModelicaHome));
    args << QString("--model=%1").arg(fileName);
    args << QString("--endpoint-pub=%1").arg(QString(mpSimulationSubscriberSocket->getEndPoint()));
    if (interactive) {
      args << QString("--endpoint-rep=%1").arg(QString(mpSimulationRequestSocket->getEndPoint()));
      args << QStringLiteral("--interactive");
    }
    OMSimulatorPage *pOMSimulatorPage = OptionsDialog::instance()->getOMSimulatorPage();
    int logLevel = pOMSimulatorPage->getLoggingLevelComboBox()->itemData(pOMSimulatorPage->getLoggingLevelComboBox()->currentIndex()).toInt();
    args << QString("--logLevel=%1").arg(logLevel);
    QStringList options = StringHandler::splitStringWithSpaces(pOMSimulatorPage->getCommandLineOptionsTextBox()->text(), false);
    if (!options.isEmpty()) {
      args << QString("--option");
    }
    foreach (QString option, options) {
      args << QString("\"%1\"").arg(option);
    }
    // start the executable
    QString process;
#if defined(_WIN32)
    process = QString("python");
    QProcessEnvironment processEnvironment = QProcessEnvironment::systemEnvironment();
    QString OMHOME = QString(Helper::OpenModelicaHome);
    processEnvironment.insert("PYTHONPATH",  OMHOME + "/bin;" + OMHOME + "/lib;" + processEnvironment.value("PYTHONPATH"));
    processEnvironment.insert("PATH",  OMHOME + "/bin;" + OMHOME + "/lib;" + processEnvironment.value("PATH"));
    mpSimulationProcess->setProcessEnvironment(processEnvironment);
#else
    process = QString("%1/bin/OMSimulatorPython3").arg(Helper::OpenModelicaHome);
#endif
    // run the simulation executable to create the result file
    writeSimulationOutput(QString("%1 %2\n").arg(process).arg(args.join(" ")), StringHandler::OMEditInfo);
    mpSimulationProcess->start(process, args);
  }
}

/*!
 * \brief OMSSimulationOutputWidget::~OMSSimulationOutputWidget
 * Saves the simulation output window geometry.
 */
OMSSimulationOutputWidget::~OMSSimulationOutputWidget()
{
  // simulation subscriber socket
  if (mpSimulationSubscriberSocket->isSocketConnected()) {
    mpSimulationSubscriberSocket->setSocketConnected(false);
    mSimulationSubscribeThread.exit();
    mSimulationSubscribeThread.wait(timeout);
  }
  delete mpSimulationSubscriberSocket;
  // simulation request socket
  if (mpSimulationRequestSocket) {
    if (mpSimulationRequestSocket->isSocketConnected()) {
      mpSimulationRequestSocket->setSocketConnected(false);
      mSimulationRequestThread.exit();
      mSimulationRequestThread.wait(timeout);
    }
    delete mpSimulationRequestSocket;
  }
  // simulation process
  if (mpSimulationProcess && isSimulationProcessRunning()) {
    mpSimulationProcess->kill();
    mpSimulationProcess->deleteLater();
  }
}

/*!
 * \brief OMSSimulationOutputWidget::parseSimulationProgress
 * Parses the simulation progress json.
 * {"progress": 0}
 * {"progress": 50}
 * {"progress": 100}
 * \param progress
 */
void OMSSimulationOutputWidget::parseSimulationProgress(const QVariant progress)
{
  QVariantMap progressMap = progress.toMap();
  bool ok;
  int progressValue = progressMap.value("progress").toInt(&ok);
  if (ok) {
    mpProgressBar->setValue(progressValue);
  }
}

/*!
 * \brief OMSSimulationOutputWidget::parseSimulationVariables
 * {"TestSimulation.Root.CauerLowPassSC.C1.v": {"type": "Real", "kind": "unknown"}, "TestSimulation.Root.CauerLowPassSC.Rp1.not1.y": {"type": "Bool", "kind": "unknown"}}
 * \param variables
 */
void OMSSimulationOutputWidget::parseSimulationVariables(const QVariant variables)
{
  QStringList variablesList;
  QVariantMap variableMap = variables.toMap();

  QVariantMap::const_iterator iterator = variableMap.constBegin();
  while (iterator != variableMap.constEnd()) {
    variablesList.append(iterator.key());
    ++iterator;
  }

  MainWindow::instance()->getVariablesWidget()->insertVariablesItemsToTree(mCref, OptionsDialog::instance()->getGeneralSettingsPage()->getWorkingDirectory(), variablesList, SimulationOptions());
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
  mpArchivedSimulationItem->setStatus(Helper::running);
  mpSimulationSubscriberSocket->setSocketConnected(true);
  mSimulationSubscribeThread.start();
  if (mpSimulationRequestSocket) {
    mpSimulationRequestSocket->setSocketConnected(true);
    mSimulationRequestThread.start();
    emit sendRequest("signals", "available");
  }
}

/*!
 * \brief OMSSimulationOutputWidget::readSimulationStandardOutput
 * Reads the simulation stdout.
 */
void OMSSimulationOutputWidget::readSimulationStandardOutput()
{
  writeSimulationOutput(QString(mpSimulationProcess->readAllStandardOutput()), StringHandler::Unknown);
}

/*!
 * \brief OMSSimulationOutputWidget::readSimulationStandardError
 * Reads the simulation stderr.
 */
void OMSSimulationOutputWidget::readSimulationStandardError()
{
  writeSimulationOutput(QString(mpSimulationProcess->readAllStandardError()), StringHandler::Error);
}

/*!
 * \brief OMSSimulationOutputWidget::simulationProcessError
 * Handles the simulation process error.
 * \param error
 */
void OMSSimulationOutputWidget::simulationProcessError(QProcess::ProcessError error)
{
  Q_UNUSED(error);
  mIsSimulationProcessRunning = false;
  /* this signal is raised when we kill the simulation process forcefully. */
  if (!isSimulationProcessKilled()) {
    writeSimulationOutput(mpSimulationProcess->errorString(), StringHandler::Error);
  }
  if (error == QProcess::FailedToStart) {
    simulationProcessFinished(0, QProcess::NormalExit);
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
 * \brief OMSSimulationOutputWidget::simulationDataPublished
 * Reads the simulation published data.
 * Expected data,
 * status {"progress": 0}
 * \param data
 */
void OMSSimulationOutputWidget::simulationDataPublished(const QByteArray &data)
{
//  writeSimulationOutput(data + "\n", StringHandler::Info);
//  return;
  QByteArray jsonData;
  if (data.startsWith("status")) {
    jsonData = data.mid(QString("status").length());
  } else {
    writeSimulationOutput(QString("Unknown simulation data %1.\n").arg(QString(data)), StringHandler::Error);
    return;
  }
  JsonDocument jsonDocument;
  if (!jsonDocument.parse(jsonData)) {
    writeSimulationOutput(QString("Failed to parse json data %1.\n").arg(QString(jsonData)), StringHandler::Error);
    return;
  } else {
    if (data.startsWith("status")) {
      parseSimulationProgress(jsonDocument.result);
    }
  }
}

/*!
 * \brief OMSSimulationOutputWidget::simulationReply
 * Expected data,
 * {'status': 'ack', 'result', self._signals}
 * {'status': 'nack', 'error'}
 * \param reply
 */
void OMSSimulationOutputWidget::simulationReply(const QByteArray &reply, const QString &function, const QString &argument)
{
//  writeSimulationOutput(reply + "\n", StringHandler::Info);
  JsonDocument jsonDocument;
  if (jsonDocument.parse(reply)) {
    QVariantMap resultMap = jsonDocument.result.toMap();
    if (resultMap.value("status").toString().compare(QStringLiteral("nack")) == 0) {
      writeSimulationOutput(QString("Failed to parse json data %1.\n").arg(QString(reply)), StringHandler::Error);
    } else if (resultMap.value("status").toString().compare(QStringLiteral("ack")) == 0) {
      if ((function.compare(QStringLiteral("signals")) == 0) && (argument.compare(QStringLiteral("available")) == 0)) {
        parseSimulationVariables(resultMap.value("result"));
      }
    }
  } else {
    writeSimulationOutput(QString("Failed to parse json data %1.\n").arg(QString(reply)), StringHandler::Error);
  }
}

/*!
 * \brief OMSSimulationOutputWidget::simulationProcessFinished
 * Updates the simulation output window when the simulation is finished.
 * \param exitCode
 * \param exitStatus
 */
void OMSSimulationOutputWidget::simulationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
  mIsSimulationProcessRunning = false;
  QString exitCodeStr = tr("Simulation process failed. Exited with code %1.").arg(Utilities::formatExitCode(exitCode));
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
  if (!mpSimulationRequestSocket) {
    MainWindow::instance()->getOMSSimulationDialog()->simulationFinished(mResultFilePath, mResultFileLastModifiedDateTime);
  }
  mpArchivedSimulationItem->setStatus(Helper::finished);
  mpSimulationSubscriberSocket->setSocketConnected(false);
  mSimulationSubscribeThread.exit();
  mSimulationSubscribeThread.wait(timeout);
  if (mpSimulationRequestSocket) {
    mpSimulationRequestSocket->setSocketConnected(false);
    mSimulationRequestThread.exit();
    mSimulationRequestThread.wait(timeout);
  }
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
    mpArchivedSimulationItem->setStatus(Helper::finished);
  }
}

void OMSSimulationOutputWidget::pauseSimulation()
{
  if (mpSimulationRequestSocket) {
    emit sendRequest("simulation", "pause");
  }
}

void OMSSimulationOutputWidget::continueSimulation()
{
  if (mpSimulationRequestSocket) {
    emit sendRequest("simulation", "continue");
  }
}

void OMSSimulationOutputWidget::endSimulation()
{
  if (mpSimulationRequestSocket) {
    emit sendRequest("simulation", "end");
  }
}
