/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#include "OMSProxy.h"
#include "Util/Helper.h"
#include "MainWindow.h"
#include "Util/Utilities.h"
#include "OMS/OMSModel.h"
#include "zmq.h"
#include <QJsonObject>
#include <QJsonDocument>
#include <QJsonArray>

#include <QApplication>
#include <QTime>

#define LOG_COMMAND(command,args) \
  QElapsedTimer commandTime; \
  commandTime.start(); \
  command = QString("%1(%2)").arg(command, args.join(",")); \
  logCommand(command);

GuiRequestSocket::GuiRequestSocket()
{
  mpContext = zmq_ctx_new();
  mpSocket = zmq_socket(mpContext, ZMQ_REQ);

  // Prevent GUI from hanging indefinitely if the Python server crashes or hangs.
  int timeout = 10000; // 10 s
  zmq_setsockopt(mpSocket, ZMQ_RCVTIMEO, &timeout, sizeof(timeout));
  zmq_setsockopt(mpSocket, ZMQ_SNDTIMEO, &timeout, sizeof(timeout));

  // Allow sending a new request after a timeout without receiving the stale reply,
  // so the REQ socket does not enter the EFSM error state on the next send.
#ifndef ZMQ_REQ_RELAXED
#define ZMQ_REQ_RELAXED 99
#endif
  int relaxed = 1;
  zmq_setsockopt(mpSocket, ZMQ_REQ_RELAXED, &relaxed, sizeof(relaxed));

  int rc = zmq_bind(mpSocket, "tcp://127.0.0.1:*");
  if (rc == 0) {
    char endPoint[64];
    size_t endPointSize = sizeof(endPoint);
    zmq_getsockopt(mpSocket, ZMQ_LAST_ENDPOINT, endPoint, &endPointSize);
    mEndPoint = QString(endPoint);
    mSocketConnected = true;
  } else {
    mEndPoint = "";
    mSocketConnected = false;
    qDebug() << "Failed to bind GUI ZMQ socket:" << strerror(errno);
  }
}

GuiRequestSocket::~GuiRequestSocket()
{
  zmq_close(mpSocket);
  zmq_ctx_destroy(mpContext);
}

bool GuiRequestSocket::sendCommand(const QJsonObject &command, QJsonObject &reply)
{
  if (!mSocketConnected)
    return false;

  QByteArray data = QJsonDocument(command).toJson(QJsonDocument::Compact);

  zmq_msg_t msg;
  zmq_msg_init_size(&msg, data.size());
  memcpy(zmq_msg_data(&msg), data.constData(), data.size());

  int rc = zmq_msg_send(&msg, mpSocket, 0);
  zmq_msg_close(&msg);

  if (rc == -1) {
    qDebug() << "ZMQ send failed for" << command["method"].toString() << ":" << strerror(errno);
    return false;
  }

  zmq_msg_t rep;
  zmq_msg_init(&rep);
  rc = zmq_msg_recv(&rep, mpSocket, 0);

  if (rc == -1) {
    zmq_msg_close(&rep);
    if (errno == EAGAIN)
      qDebug() << "ZMQ recv timeout for" << command["method"].toString() << ": Python server did not reply within 10 s";
    else
      qDebug() << "ZMQ recv failed for" << command["method"].toString() << ":" << strerror(errno);
    return false;
  }

  QByteArray response((char*)zmq_msg_data(&rep), zmq_msg_size(&rep));
  zmq_msg_close(&rep);

  QJsonDocument doc = QJsonDocument::fromJson(response);
  if (!doc.isObject())
    return false;

  reply = doc.object();
  return true;
}


/*!
 * \brief loggingCallback
 * Callback function to handle the OMSimulator logging.
 * \param type
 * \param message
 */
void loggingCallback(oms_message_type_enu_t type, const char *message)
{
  QString level = Helper::notificationLevel;
  switch (type) {
    case oms_message_warning:
      level = Helper::notificationLevel;
      break;
    case oms_message_error:
      level = Helper::errorLevel;
      break;
    case oms_message_info:
    case oms_message_debug:
    case oms_message_trace:
    default:
      level = Helper::notificationLevel;
      break;
  }
  emit OMSProxy::instance()->emitLogGUIMessage(MessageItem(MessageItem::Modelica, QString(message), Helper::scriptingKind, level));
  //  qDebug() << "loggingCallback" << type << message;
}

/*!
 * \class OMSProxy
 * \brief Interface for call OMSimulator API.
 */

OMSProxy *OMSProxy::mpInstance = 0;

/*!
 * \brief OMSProxy::create
 */
void OMSProxy::create()
{
  if (!mpInstance) {
    mpInstance = new OMSProxy;
  }
}

/*!
 * \brief OMSProxy::destroy
 */
void OMSProxy::destroy()
{
  oms_setLoggingCallback(0);
  mpInstance->deleteLater();
  mpInstance = 0;
}

/*!
 * \brief OMSProxy::OMSProxy
 */
OMSProxy::OMSProxy()
{
  /* create a file to write OMSimulator communication log */
  QString communicationLogFilePath = QString("%1omscommunication.log").arg(Utilities::tempDirectory());
#ifdef Q_OS_WIN
  mpCommunicationLogFile = _wfopen((wchar_t*)communicationLogFilePath.utf16(), L"w");
#else
  mpCommunicationLogFile = fopen(communicationLogFilePath.toUtf8().constData(), "w");
#endif
  mTotalOMSCallsTime = 0.0;
  // OMSimulator global settings
  //setCommandLineOption("--suppressPath=true");
  setLogFile(QString(Utilities::tempDirectory() + "/omslog.txt"));
  setTempDirectory(Utilities::tempDirectory());
  setLoggingCallback();
  qRegisterMetaType<MessageItem>("MessageItem");
  connect(this, SIGNAL(logGUIMessage(MessageItem)), MessagesWidget::instance(), SLOT(addGUIMessage(MessageItem)));
  mpGuiRequestSocket = new GuiRequestSocket();
  startGuiServer();
}

OMSProxy::~OMSProxy()
{
  // send graceful shutdown so Python can clean up before we close the socket
  // also check the process state directly — mServerReady can be stale if the process
  // crashed right before the destructor runs and the finished() signal hasn't been processed yet
  if (mServerReady && mpGuiRequestSocket && mpGuiProcess && mpGuiProcess->state() == QProcess::Running) {
    QJsonObject obj;
    obj["method"] = "shutdown";
    QJsonObject reply;
    mpGuiRequestSocket->sendCommand(obj, reply);
  }

  // wait for process to exit cleanly, then force-kill if it doesn't
  if (mpGuiProcess && mpGuiProcess->state() != QProcess::NotRunning) {
    mpGuiProcess->waitForFinished(3000);
    if (mpGuiProcess->state() != QProcess::NotRunning) {
      mpGuiProcess->kill();
      mpGuiProcess->waitForFinished(1000);
    }
  }

  // close ZMQ socket and destroy context
  delete mpGuiRequestSocket;
  mpGuiRequestSocket = nullptr;

  if (mpCommunicationLogFile) {
    fclose(mpCommunicationLogFile);
  }
}

void OMSProxy::startGuiServer()
{
  QString pythonExe = "C:/ProgramData/anaconda3/python.exe"; // full path if needed
  QString script = "C:/OPENMODELICAGIT/OpenModelica/OMSimulator/src/OMSimulatorServer/OMSimulatorCommand.py";

  mpGuiProcess = new QProcess(this);

  // connect signals
  connect(mpGuiProcess, &QProcess::started, this, &OMSProxy::guiProcessStarted);
  connect(mpGuiProcess, &QProcess::errorOccurred, this, &OMSProxy::guiProcessError);
  connect(mpGuiProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, &OMSProxy::guiProcessFinished);

  connect(mpGuiProcess, &QProcess::readyReadStandardOutput, this, &OMSProxy::readGuiServerStandardOutput);
  connect(mpGuiProcess, &QProcess::readyReadStandardError, this, &OMSProxy::readGuiServerStandardError);
  QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
  env.insert("PYTHONPATH", "C:/ProgramData/anaconda3/python.exe");
  mpGuiProcess->setProcessEnvironment(env);
  QString endpoint = mpGuiRequestSocket->endPoint();
  QStringList args;
  args << script << "--endpoint-rep" << endpoint;
  mpGuiProcess->start(pythonExe, args);
}

void OMSProxy::guiProcessStarted()
{
  mServerReady = true;
  MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
    tr("OMSimulator Python server started at %1.").arg(mpGuiRequestSocket->endPoint()),
    Helper::scriptingKind, Helper::notificationLevel));
}

void OMSProxy::guiProcessError(QProcess::ProcessError error)
{
  mServerReady = false;
  QString msg;
  switch (error) {
    case QProcess::FailedToStart:
      msg = tr("OMSimulator Python server failed to start. Check the Python executable and script paths.");
      break;
    case QProcess::Crashed:
      msg = tr("OMSimulator Python server crashed.");
      break;
    case QProcess::Timedout:
      msg = tr("OMSimulator Python server timed out.");
      break;
    default:
      msg = tr("OMSimulator Python server process error (%1).").arg(error);
      break;
  }
  MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, msg,
    Helper::scriptingKind, Helper::errorLevel));
}

void OMSProxy::guiProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
  mServerReady = false;
  if (exitStatus == QProcess::CrashExit || exitCode != 0) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
      tr("OMSimulator Python server exited unexpectedly (exit code %1).").arg(exitCode),
      Helper::scriptingKind, Helper::errorLevel));
  }
}

void OMSProxy::readGuiServerStandardOutput()
{
  QString output = QString::fromUtf8(mpGuiProcess->readAllStandardOutput()).trimmed();
  if (!output.isEmpty()) {
    qDebug().noquote() << output;
    emit logGUIMessage(MessageItem(MessageItem::Modelica, output, Helper::scriptingKind, Helper::notificationLevel));
  }
}

void OMSProxy::readGuiServerStandardError()
{
  QString error = QString::fromUtf8(mpGuiProcess->readAllStandardError()).trimmed();
  if (!error.isEmpty()) {
    qDebug().noquote() << error;
    emit logGUIMessage(MessageItem(MessageItem::Modelica, error, Helper::scriptingKind, Helper::errorLevel));
  }
}

/*!
 * \brief OMSProxy::logCommand
 * Writes the command to the omscommunication.log file.
 * \param command - the command to write
 */
void OMSProxy::logCommand(QString command)
{
  // write the log to communication log file
  if (mpCommunicationLogFile) {
    fputs(QString("%1 %2\n").arg(command, QTime::currentTime().toString("hh:mm:ss:zzz")).toUtf8().constData(), mpCommunicationLogFile);
  }
}

/*!
 * \brief OMSProxy::logResponse
 * Writes the response to the omscommunication.log file.
 * \param response - the response to write
 * \param status - execution status of the command
 * \param responseTime - the response end time
 */
void OMSProxy::logResponse(QString command, oms_status_enu_t status, QElapsedTimer *responseTime)
{
  double elapsed = (double)responseTime->elapsed() / 1000.0;
  QString firstLine("");
  for (int i = 0; i < command.length(); i++) {
    if (command[i] != '\n') {
      firstLine.append(command[i]);
    } else {
      break;
    }
  }

  // write the log to communication log file
  if (mpCommunicationLogFile) {
    mTotalOMSCallsTime += elapsed;
    fputs(QString("%1 %2\n").arg(status).arg(QTime::currentTime().toString("hh:mm:ss:zzz")).toUtf8().constData(), mpCommunicationLogFile);
    fputs(QString("#s#; %1; %2; \'%3\'\n\n").arg(QString::number(elapsed, 'f', 6)).arg(QString::number(mTotalOMSCallsTime, 'f', 6)).arg(firstLine).toUtf8().constData(),  mpCommunicationLogFile);
  }

  // flush the logs if --Debug=true
  if (MainWindow::instance()->isDebug()) {
    fflush(NULL);
  }

  MainWindow::instance()->printStandardOutAndErrorFilesMessages();
}

/*!
 * \brief OMSProxy::getSystemTypeString
 * Returns the oms_system_enu_t as string.
 * \param type
 * \return
 */
QString OMSProxy::getSystemTypeString(oms_system_enu_t type)
{
  switch (type) {
    case oms_system_wc:
      return Helper::systemWC;
    case oms_system_sc:
      return Helper::systemSC;
    default:
      // should never be reached
      return Helper::systemWC;
  }
}

/*!
 * \brief OMSProxy::getSystemTypeShortString
 * Returns the oms_system_enu_t as short string.
 * \param type
 * \return
 */
QString OMSProxy::getSystemTypeShortString(oms_system_enu_t type)
{
  switch (type) {
    case oms_system_wc:
      return "WC";
    case oms_system_sc:
      return "SC";
    default:
      // should never be reached
      return "WC";
  }
}

/*!
 * \brief OMSProxy::getFMUKindString
 * Returns the oms_fmi_kind_enu_t as string.
 * \param kind
 * \return
 */
QString OMSProxy::getFMUKindString(oms_fmi_kind_enu_t kind)
{
  switch (kind) {
    case oms_fmi_kind_me:
      return "ME";
    case oms_fmi_kind_cs:
      return "CS";
    case oms_fmi_kind_me_and_cs:
      return "ME & CS";
    case oms_fmi_kind_unknown:
    default:
      // should never be reached
      return "";
  }
}

/*!
 * \brief OMSProxy::getSignalTypeString
 * Returns the oms_signal_type_integer as string.
 * \param type
 * \return
 */
QString OMSProxy::getSignalTypeString(oms_signal_type_enu_t type)
{
  switch (type) {
    case oms_signal_type_real:
      return "Real";
    case oms_signal_type_integer:
      return "Integer";
    case oms_signal_type_boolean:
      return "Boolean";
    case oms_signal_type_string:
      return "String";
    case oms_signal_type_enum:
      return "Enum";
    case oms_signal_type_bus:
      return "Bus";
    default:
      // should never be reached
      return "";
  }
}

/*!
 * \brief OMSProxy::getCausalityString
 * Returns the oms_causality_enu_t as string.
 * \param causality
 * \return
 */
QString OMSProxy::getCausalityString(oms_causality_enu_t causality)
{
  switch (causality) {
    case oms_causality_input:
      return "Input";
    case oms_causality_output:
      return "Output";
    case oms_causality_parameter:
      return "Parameter";
    case oms_causality_undefined:
    default:
      // should never be reached
      return "";
  }
}

/*!
 * \brief OMSProxy::statusToBool
 * Converts the oms_status_enu_t to bool.
 * \param status
 * \return
 */
bool OMSProxy::statusToBool(oms_status_enu_t status)
{
  switch (status) {
    case oms_status_ok:
    case oms_status_warning:
    case oms_status_pending:
      return true;
    default:
      return false;
  }
}

/*!
 * \brief OMSProxy::sendZmqCommand
 * Centralized helper for all ZMQ JSON commands: logs the command and reply to the
 * communication log file (same format as the old oms_* calls), checks for errors,
 * and posts a message to the GUI message widget on failure.
 * Returns true only when the Python server replies with status "ok".
 */
bool OMSProxy::sendZmqCommand(const QJsonObject &obj, QJsonObject &reply)
{
  QString method = obj["method"].toString();

  if (!mServerReady) {
    QString msg = tr("OMSimulator Python server is not running. Cannot execute '%1'.").arg(method);
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, msg,
      Helper::scriptingKind, Helper::errorLevel));
    QApplication::processEvents(QEventLoop::ExcludeUserInputEvents);
    return false;
  }

  QElapsedTimer commandTime;
  commandTime.start();

  if (mpCommunicationLogFile) {
    QString entry = QString("zmq(%1) %2\n")
      .arg(QJsonDocument(obj).toJson(QJsonDocument::Compact),
           QTime::currentTime().toString("hh:mm:ss:zzz"));
    fputs(entry.toUtf8().constData(), mpCommunicationLogFile);
  }

  bool ok = mpGuiRequestSocket->sendCommand(obj, reply);
  double elapsed = commandTime.elapsed() / 1000.0;

  if (mpCommunicationLogFile) {
    mTotalOMSCallsTime += elapsed;
    QString status = ok ? reply["status"].toString() : "timeout";
    fputs(QString("%1 %2\n").arg(status, QTime::currentTime().toString("hh:mm:ss:zzz")).toUtf8().constData(), mpCommunicationLogFile);
    fputs(QString("#s#; %1; %2; '%3'\n\n")
      .arg(QString::number(elapsed, 'f', 6),
           QString::number(mTotalOMSCallsTime, 'f', 6),
           method).toUtf8().constData(), mpCommunicationLogFile);
  }

  if (MainWindow::instance()->isDebug())
    fflush(NULL);

  if (!ok) {
    QString msg = tr("OMSimulator server did not respond to '%1' (timeout or crash). Check the Messages window for Python errors.").arg(method);
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, msg, Helper::scriptingKind, Helper::errorLevel));
    QApplication::processEvents(QEventLoop::ExcludeUserInputEvents);
    return false;
  }

  QString status = reply["status"].toString();
  if (status == "failed") {
    QString error = reply["error"].toString();
    QString msg = error.isEmpty()
      ? tr("'%1' failed (no details from server).").arg(method)
      : tr("'%1' failed: %2").arg(method, error);
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, msg, Helper::scriptingKind, Helper::errorLevel));
    QApplication::processEvents(QEventLoop::ExcludeUserInputEvents);
    return false;
  }

  return true;
}

/*!
 * \brief OMSProxy::addBus
 * Adds a bus.
 * \param cref
 * \return
 */
bool OMSProxy::addBus(QString cref)
{
  QString command = "oms_addBus";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_addBus(cref.toUtf8().constData());
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::addConnection
 * Adds the connection
 * \param crefA
 * \param crefB
 * \return
 */
bool OMSProxy::addConnection(QString crefA, QString crefB, bool suppressUnitConversion)
{
  // QString command = "oms_addConnection";
  // qDebug() << "addConnection :" << crefA << "=>" << crefB;
  // QStringList args;
  // args << "\"" + crefA + "\"" << "\"" + crefB + "\"" << (suppressUnitConversion ? "true" : "false");
  // LOG_COMMAND(command, args);
  // oms_status_enu_t status = oms_addConnection(crefA.toUtf8().constData(), crefB.toUtf8().constData(), suppressUnitConversion);
  // logResponse(command, status, &commandTime);
  // return statusToBool(status);

    QStringList startConnector = crefA.split(".");
    QStringList endConnector = crefB.split(".");

    startConnector.removeFirst(); // remove "test"
    endConnector.removeFirst();  // remove "arun"

    QJsonObject obj, args_;
    obj["method"] = "addConnection";

    args_["crefA"] = QJsonArray::fromStringList(startConnector);
    args_["crefB"] = QJsonArray::fromStringList(endConnector);
    args_["suppressUnitConversion"] = suppressUnitConversion;
    obj["args"] = args_;

    qDebug() <<"addConnection json : " << QJsonDocument(obj).toJson(QJsonDocument::Compact);

    QJsonObject reply;
    return sendZmqCommand(obj, reply);
}

/*!
 * \brief OMSProxy::addConnector
 * Adds the connector.
 * \param cref
 * \param causality
 * \param type
 * \return
 */
bool OMSProxy::addConnector(QString cref, oms_causality_enu_t causality, oms_signal_type_enu_t type)
{
  qDebug() <<"addConnector: " << cref;
  QString command = "oms_addConnector";
  QStringList args;
  args << "\"" + cref + "\"" << QString::number(causality) << QString::number(type);
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_addConnector(cref.toUtf8().constData(), causality, type);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

bool OMSProxy::addConnector(QString cref, OMSModel::Causality causality, OMSModel::SignalType type)
{
  QStringList parts = cref.split(".");

  // Save connector name before removing
  QString connectorName = parts.last();

  parts.removeFirst(); // remove "test"
  parts.removeLast();  // remove "arun"

  QJsonObject obj, args_;
  obj["method"] = "addConnector";

  args_["cref"] = QJsonArray::fromStringList(parts);
  args_["name"] = connectorName;
  args_["causality"] = OMSModel::Connector::causalityToString(causality);
  args_["type"] = OMSModel::Connector::signalTypeToString(type);

  obj["args"] = args_;

  QJsonObject reply;
  return sendZmqCommand(obj, reply);
}
/*!
 * \brief OMSProxy::addConnectorToBus
 * Adds a connector to a bus.
 * \param busCref
 * \param connectorCref
 * \return
 */
bool OMSProxy::addConnectorToBus(QString busCref, QString connectorCref)
{
  QString command = "oms_addConnectorToBus";
  QStringList args;
  args << busCref << connectorCref;
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_addConnectorToBus(busCref.toUtf8().constData(), connectorCref.toUtf8().constData());
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::addSubModel
 * Adds the submodel to the system
 * \param busCref
 * \param connectorCref
 * \param type
 * \return
 */
bool OMSProxy::addSubModel(QString cref, QString fmuPath)
{
    qDebug() << "addSubModel Arun: " << cref;
  // QString command = "oms_addSubModel";
  // QStringList args;
  // args << "\"" + cref + "\"" << fmuPath;
  // LOG_COMMAND(command, args);
  // oms_status_enu_t status = oms_addSubModel(cref.toUtf8().constData(), fmuPath.toUtf8().constData());
  // logResponse(command, status, &commandTime);

  QStringList parts = cref.split(".");
  parts.removeFirst();
  QJsonObject obj, args_;
  obj["method"] = "addComponent";
  args_["cref"] = QJsonArray::fromStringList(parts);
  args_["source"] = fmuPath;
  args_["new_name"] = "resources/" + parts.last() + ".fmu";
  obj["args"] = args_;

  QJsonObject reply;
  return sendZmqCommand(obj, reply);
  //return statusToBool(status);
}

/*!
 * \brief OMSProxy::replaceSubModel
 * \Adds the submodel to the system
 * \param cref
 * \param fmupath
 * \param dryCount
 * \param count
 * \return
 */
bool OMSProxy::replaceSubModel(QString cref, QString fmuPath, bool dryCount, int *count)
{
  QString command = "oms_replaceSubModel";
  QStringList args;
  args << "\"" + cref + "\"" << fmuPath << QString::number(dryCount);
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_replaceSubModel(cref.toUtf8().constData(), fmuPath.toUtf8().constData(), dryCount, count);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::createElementGeometryUsingPosition
 * Creates the element geometry using position.
 * \param cref
 * \param position
 */
void OMSProxy::createElementGeometryUsingPosition(const QString &cref, QPointF position)
{
  qreal x = position.x();
  qreal y = position.y();

  OMSModel::ElementGeometry elementGeometry;

  elementGeometry.setX1(x - 10.0);
  elementGeometry.setY1(y - 10.0);
  elementGeometry.setX2(x + 10.0);
  elementGeometry.setY2(y + 10.0);
  elementGeometry.setRotation(0.0);
  setElementGeometry(cref, elementGeometry);
  //ssd_element_geometry_t elementGeometry;
  // elementGeometry.x1 = x - 10.0;
  // elementGeometry.y1 = y - 10.0;
  // elementGeometry.x2 = x + 10.0;
  // elementGeometry.y2 = y + 10.0;
  // elementGeometry.rotation = 0.0;
  // elementGeometry.iconSource = NULL;
  // elementGeometry.iconRotation = 0.0;
  // elementGeometry.iconFlip = false;
  // elementGeometry.iconFixedAspectRatio = false;
  // setElementGeometry(cref, &elementGeometry);
}

/*!
 * \brief OMSProxy::addSystem
 * Adds a system to a model.
 * \param cref
 * \param type
 * \return
 */
bool OMSProxy::addSystem(QString cref)
{
    qDebug() << "adding System: " << cref;
  // QString command = "oms_addSystem";
  // QStringList args;
  // args << "\"" + cref + "\"" << QString::number(type);
  // LOG_COMMAND(command, args);
  // oms_status_enu_t status = oms_addSystem(cref.toUtf8().constData(), type);
  // logResponse(command, status, &commandTime);
  // return statusToBool(status);
  QStringList parts = cref.split(".");
  parts.removeFirst(); // remove model name

  QJsonObject args;
  args["cref"] = QJsonArray::fromStringList(parts);
  //args["name"] = systemName;

  QJsonObject obj;
  obj["method"] = "addSystem";
  obj["args"] = args;

  QJsonObject reply;
  return sendZmqCommand(obj, reply);
}

/*!
 * \brief OMSProxy::deleteConnection
 * Deletes the connection
 * \param crefA
 * \param crefB
 * \return
 */
bool OMSProxy::deleteConnection(QString crefA, QString crefB)
{
  QString command = "oms_deleteConnection";
  QStringList args;
  args << "\"" + crefA + "\"" << "\"" + crefB + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_deleteConnection(crefA.toUtf8().constData(), crefB.toUtf8().constData());
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::deleteConnectorFromBus
 * Deletes a connector from a bus.
 * \param busCref
 * \param connectorCref
 * \return
 */
bool OMSProxy::deleteConnectorFromBus(QString busCref, QString connectorCref)
{
  QString command = "oms_deleteConnectorFromBus";
  QStringList args;
  args << busCref << connectorCref;
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_deleteConnectorFromBus(busCref.toUtf8().constData(), connectorCref.toUtf8().constData());
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::getBoolean
 * Gets the boolean variable value.
 * \param cref
 * \param value
 * \return
 */
bool OMSProxy::getBoolean(QString cref, bool *value)
{
  QString command = "oms_getBoolean";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_getBoolean(cref.toUtf8().constData(), value);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::getBus
 * Gets the bus.
 * \param cref
 * \param pBusConnector
 * \return
 */
bool OMSProxy::getBus(QString cref, oms_busconnector_t **pBusConnector)
{
  QString command = "oms_getBus";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_getBus(cref.toUtf8().constData(), pBusConnector);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::getComponentType
 * Get the component type.
 * \param cref
 * \param pType
 * \return
 */
bool OMSProxy::getComponentType(QString cref, oms_component_enu_t *pType)
{
  QString command = "oms_getComponentType";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_getComponentType(cref.toUtf8().constData(), pType);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::getConnections
 * Get the model connections
 * \param cref
 * \param pConnections
 * \return
 */
bool OMSProxy::getConnections(QString cref, oms_connection_t*** pConnections)
{
  QString command = "oms_getConnections";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_getConnections(cref.toUtf8().constData(), pConnections);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::getConnector
 * Gets the connector.
 * \param cref
 * \param pConnector
 * \return
 */
bool OMSProxy::getConnector(QString cref, oms_connector_t **pConnector)
{
  QString command = "oms_getConnector";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_getConnector(cref.toUtf8().constData(), pConnector);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::getElement
 * Gets the model element
 * \param cref
 * \param pElement
 * \return
 */
bool OMSProxy::getElement(QString cref, oms_element_t** pElement)
{
  QString command = "oms_getElement";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_getElement(cref.toUtf8().constData(), pElement);
  logResponse(command, status, &commandTime);

  return statusToBool(status);
}

/*!
 * \brief OMSProxy::getElements
 * Get the model elements
 * \param cref
 * \param pElements
 * \return
 */
bool OMSProxy::getElements(QString cref, oms_element_t*** pElements)
{
  QString command = "oms_getElements";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_getElements(cref.toUtf8().constData(), pElements);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

// bool OMSProxy::getElements(QString cref, oms_element_t*** pElements)
// {
//     QJsonObject obj;
//     obj["method"] = "getElements";

//     QJsonObject args;
//     args["cref"] = cref;
//     obj["args"] = args;

//     QJsonObject reply;
//     mpGuiRequestSocket->sendCommand(obj, reply);

//     QString status = reply["status"].toString();
//     if (status != "ok")
//         return false;

//     QJsonArray arr = reply["elements"].toArray();

//     qDebug() << "Qjson Reply elements :" << arr;

//     *pElements = jsonArrayToElements(arr);

//     return true;
// }

oms_element_t** OMSProxy::jsonArrayToElements(const QJsonArray &arr)
{
    int n = arr.size();

    oms_element_t **list =
        (oms_element_t**)calloc(n + 1, sizeof(oms_element_t*));

    for (int i = 0; i < n; ++i) {
        list[i] = jsonToElement(arr[i].toObject());
    }

    list[n] = nullptr;
    return list;
}

oms_element_t* OMSProxy::jsonToElement(const QJsonObject &obj)
{
    oms_element_t *e =
        (oms_element_t*)calloc(1, sizeof(oms_element_t));

    QString name = obj["name"].toString();
    e->name = strdup(name.toUtf8().constData());

    QString type = obj["type"].toString();

    if (type == "system")
        e->type = oms_element_system;
    else
        e->type = oms_element_component;

    e->elements =
        jsonArrayToElements(obj["elements"].toArray());

    // later:
    // e->connectors = ...
    // e->busconnectors = ...
    // e->geometry = ...

    return e;
}


bool OMSProxy::getElementsJson(QString cref, QJsonArray &elements)
{
  qDebug() << "GetElements via ZMQ";

  QJsonObject obj;
  obj["method"] = "getElements";

  QJsonObject args;
  args["cref"] = cref;
  obj["args"] = args;

  QJsonObject reply;
  if (!sendZmqCommand(obj, reply))
    return false;

  elements = reply["elements"].toArray();
  //qDebug().noquote() << "getElements reply:" << QJsonDocument(reply).toJson(QJsonDocument::Indented);
  qDebug() << "Qjson Reply elements :" << elements;
  return true;
}




/*!
 * \brief OMSProxy::getFixedStepSize
 * Gets the fixed step size.
 * \param cref
 * \param stepSize
 * \return
 */
bool OMSProxy::getFixedStepSize(QString cref, double *stepSize)
{
  QString command = "oms_getFixedStepSize";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_getFixedStepSize(cref.toUtf8().constData(), stepSize);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::getFMUInfo
 * Gets the FMU info.
 * \param cref
 * \param pFmuInfo
 * \return
 */
bool OMSProxy::getFMUInfo(QString cref, const oms_fmu_info_t** pFmuInfo)
{
  QString command = "oms_getFMUInfo";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_getFMUInfo(cref.toUtf8().constData(), pFmuInfo);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::getInteger
 * Gets the integer variable value.
 * \param cref
 * \param value
 * \return
 */
bool OMSProxy::getInteger(QString cref, int *value)
{
  QString command = "oms_getInteger";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_getInteger(cref.toUtf8().constData(), value);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::getModelState
 * Gets the model state.
 * \param cref
 * \param modelState
 * \return
 */
bool OMSProxy::getModelState(const QString &cref, oms_modelState_enu_t *modelState)
{
  QString command = "oms_getModelState";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_getModelState(cref.toUtf8().constData(), modelState);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::getReal
 * Gets the real variable value.
 * \param cref
 * \param value
 * \return
 */
bool OMSProxy::getReal(QString cref, double *value)
{
  QString command = "oms_getReal";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_getReal(cref.toUtf8().constData(), value);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::getSolver
 * Gets the solver.
 * \param cref
 * \param solver
 * \return
 */
bool OMSProxy::getSolver(QString cref, oms_solver_enu_t *solver)
{
  QString command = "oms_getSolver";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_getSolver(cref.toUtf8().constData(), solver);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::setStartTime
 * Get the start time from the model.
 * \param cref
 * \param startTime
 * \return
 */
bool OMSProxy::getStartTime(QString cref, double* startTime)
{
  QString command = "oms_getStartTime";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_getStartTime(cref.toUtf8().constData(), startTime);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::setStopTime
 * Get the stop time from the model.
 * \param cref
 * \param stopTime
 * \return
 */
bool OMSProxy::getStopTime(QString cref, double* stopTime)
{
  QString command = "oms_getStopTime";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_getStopTime(cref.toUtf8().constData(), stopTime);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::getFMUPath
 * Returns the submodel path.
 * \param cref
 * \param pPath
 * \return
 */
bool OMSProxy::getSubModelPath(QString cref, QString* pPath)
{
  QString command = "oms_getSubModelPath";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  char* path = NULL;
  oms_status_enu_t status = oms_getSubModelPath(cref.toUtf8().constData(), &path);
  *pPath = QString(path);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::getSystemType
 * Get the system type.
 * \param cref
 * \param pType
 * \return
 */
bool OMSProxy::getSystemType(QString cref, oms_system_enu_t *pType)
{
  // QString command = "oms_getSystemType";
  // QStringList args;
  // args << "\"" + cref + "\"";
  // LOG_COMMAND(command, args);
  // oms_status_enu_t status = oms_getSystemType(cref.toUtf8().constData(), pType);
  // logResponse(command, status, &commandTime);
  // return statusToBool(status);
   *pType = oms_system_none;
  return true;
}

/*!
 * \brief OMSProxy::getTolerance
 * Gets the tolerance.
 * \param cref
 * \param absoluteTolerance
 * \param relativeTolerance
 * \return
 */
bool OMSProxy::getTolerance(QString cref, double *absoluteTolerance, double *relativeTolerance)
{
  QString command = "oms_getTolerance";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_getTolerance(cref.toUtf8().constData(), absoluteTolerance, relativeTolerance);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::getVariableStepSize
 * Gets the variable step size.
 * \param cref
 * \param initialStepSize
 * \param minimumStepSize
 * \param maximumStepSize
 * \return
 */
bool OMSProxy::getVariableStepSize(QString cref, double *initialStepSize, double *minimumStepSize, double *maximumStepSize)
{
  QString command = "oms_getVariableStepSize";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_getVariableStepSize(cref.toUtf8().constData(), initialStepSize, minimumStepSize, maximumStepSize);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::instantiate
 * Instantiates the model and enter the instantiated state.
 * \param cref
 * \return
 */
bool OMSProxy::instantiate(QString cref)
{
  QString command = "oms_instantiate";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_instantiate(cref.toUtf8().constData());
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::initialize
 * Initializes a model.
 * \param cref
 * \return
 */
bool OMSProxy::initialize(QString cref)
{
  QString command = "oms_initialize";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_initialize(cref.toUtf8().constData());
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::exportSnapshot
 * Lists the contents of a model.
 * Since memory is allocated so we need to call free.
 * \param cref
 * \param pContents
 * \return
 */
bool OMSProxy::exportSnapshot(QString cref, QString *pContents)
{
  // QString command = "oms_exportSnapshot";
  // QString cref_ = cref + ":SystemStructure.ssd";
  // QStringList args;
  // args << "\"" + cref_ + "\"";
  // LOG_COMMAND(command, args);
  // char* contents = NULL;
  // oms_status_enu_t status = oms_exportSnapshot(cref_.toUtf8().constData(), &contents);
  // if (contents) {
  //   *pContents = QString(contents);
  //   free(contents);
  // }
  // logResponse(command, status, &commandTime);
  // return statusToBool(status);
  QJsonObject obj;
  obj["method"] = "exportSnapshot";
  QJsonObject reply;

  if (!sendZmqCommand(obj, reply))
    return false;

  QString xml = reply["xml"].toString();
  if (!xml.isEmpty())
    *pContents = xml;
  return true;
}

/*!
 * \brief OMSProxy::loadModel
 * Loads the model.
 * \param filename
 * \param pModelName
 * \return
 */
bool OMSProxy::loadModel(QString filename, QString* pModelName)
{
  QString command = "oms_importFile";
  QStringList args;
  args << filename;
  LOG_COMMAND(command, args);
  char* cref = NULL;
  oms_status_enu_t status = oms_importFile(filename.toUtf8().constData(), &cref);
  *pModelName = QString(cref);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::importSnapshot
 * Loads the snapshot of the model.
 * \param cref
 * \param snapshot
 * \param pNewCref
 * \return
 */
bool OMSProxy::importSnapshot(QString cref, QString snapshot, QString* pNewCref)
{
  QString command = "oms_importSnapshot";
  QStringList args;
  args << "\"" + cref + "\"" << "\"" + snapshot + "\"";
  LOG_COMMAND(command, args);
  char* new_cref = NULL;
  oms_status_enu_t status = oms_importSnapshot(cref.toUtf8().constData(), snapshot.toUtf8().constData(), &new_cref);
  if (new_cref)
    *pNewCref = QString(new_cref);
  else
    *pNewCref = cref;
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::newModel
 * \param cref
 * \return
 */
bool OMSProxy::newModel(QString cref, QString systemName)
{
  // QString command = "oms_newModel";
  // QStringList args;
  // args << "\"" + cref + "\"";
  // LOG_COMMAND(command, args);
  // oms_status_enu_t status = oms_newModel(cref.toUtf8().constData());
  // logResponse(command, status, &commandTime);

  QJsonObject obj, args_;
  obj["method"] = "newModel";
  args_["name"] = cref;
  args_["system_name"] = systemName;
  obj["args"] = args_;
  QJsonObject reply;
  return sendZmqCommand(obj, reply);
  //return statusToBool(status);
}

/*!
 * \brief OMSProxy::rename
 * Renames the OMSimulator model/elements.
 * \param cref
 * \param newCref
 * \return
 */
bool OMSProxy::rename(const QString &cref, const QString &newCref)
{
  QString command = "oms_rename";
  QStringList args;
  args << "\"" + cref + "\"" << "\"" + newCref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_rename(cref.toUtf8().constData(), newCref.toUtf8().constData());
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::omsDelete
 * \param cref
 * \return
 */
bool OMSProxy::omsDelete(QString cref)
{
  QString command = "oms_delete";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_delete(cref.toUtf8().constData());
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::saveModel
 * Saves the model.
 * \param cref
 * \param filename
 * \return
 */
bool OMSProxy::saveModel(QString cref, QString filename)
{
  QString command = "oms_export";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_export(cref.toUtf8().constData(), filename.toUtf8().constData());
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::setBoolean
 * Sets the boolean variable value.
 * \param cref
 * \param value
 * \return
 */
bool OMSProxy::setBoolean(QString cref, bool value)
{
  QString command = "oms_setBoolean";
  QStringList args;
  args << "\"" + cref + "\"" << (value ? "true" : "false");
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_setBoolean(cref.toUtf8().constData(), value);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::setBusGeometry
 * Sets the bus geometry.
 * \param cref
 * \param pGeometry
 * \return
 */
bool OMSProxy::setBusGeometry(QString cref, const ssd_connector_geometry_t* pGeometry)
{
  QString command = "oms_setBusGeometry";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_setBusGeometry(cref.toUtf8().constData(), pGeometry);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::setCommandLineOption
 * Sets the command line option.
 * \param cmd
 * \return
 */
bool OMSProxy::setCommandLineOption(QString cmd)
{
  QString command = "oms_setCommandLineOption";
  QStringList args;
  args << cmd;
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_setCommandLineOption(cmd.toUtf8().constData());
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::setConnectionGeometry
 * Sets the connection geometry.
 * \param crefA
 * \param crefB
 * \param pGeometry
 * \return
 */
bool OMSProxy::setConnectionGeometry(QString crefA, QString crefB, const ssd_connection_geometry_t *pGeometry)
{
  qDebug() << "setConnectionGeometry :" << crefA << crefB;
  QString command = "oms_setConnectionGeometry";
  QStringList args;
  args << "\"" + crefA + "\"" << "\"" + crefB + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_setConnectionGeometry(crefA.toUtf8().constData(), crefB.toUtf8().constData(), pGeometry);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

bool OMSProxy::setConnectionGeometry(QString crefA, QString crefB, const OMSModel::ConnectionGeometry &geometry)
{
  qDebug() << "setConnectionGeometry omsModel:" << crefA << crefB;

  QStringList conA = crefA.split(".");
  conA.removeFirst();

  QStringList conB = crefB.split(".");
  conB.removeFirst();

  // QJsonArray points;
  // for (const QPointF &point : geometry.getPoints()) {
  //   QJsonObject pointObject;
  //   pointObject["x"] = point.x();
  //   pointObject["y"] = point.y();
  //   points.append(pointObject);
  // }

  QJsonArray pointsX;
  QJsonArray pointsY;

  //const OMSModel::ConnectionGeometry &connectionGeometry = geometry;

  for (double x : geometry.getPointsX()) {
    pointsX.append(x);
  }

  for (double y : geometry.getPointsY()) {
    pointsY.append(y);
  }

  QJsonObject geometryObject;
  geometryObject["pointsX"] = pointsX;
  geometryObject["pointsY"] = pointsY;

  QJsonObject args;
  args["crefA"] = QJsonArray::fromStringList(conA);
  args["crefB"] = QJsonArray::fromStringList(conB);
  args["geometry"] = geometryObject;

  QJsonObject obj;
  obj["method"] = "setConnectionGeometry";
  obj["args"] = args;

  QJsonObject reply;
  return sendZmqCommand(obj, reply);
}

/*!
 * \brief OMSProxy::setConnectorGeometry
 * Sets the connector geometry.
 * \param cref
 * \param pGeometry
 * \return
 */
bool OMSProxy::setConnectorGeometry(QString cref, const ssd_connector_geometry_t* pGeometry)
{
  qDebug() << "setConnectorGemetry:" << cref;
  QString command = "oms_setConnectorGeometry";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_setConnectorGeometry(cref.toUtf8().constData(), pGeometry);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

bool OMSProxy::setConnectorGeometry(QString cref, const OMSModel::ConnectorGeometry &geometry)
{
  qDebug() << "setConnectorGeometry:" << cref
           << "x:" << geometry.getX()
           << "y:" << geometry.getY();

  QStringList parts = cref.split(".");
  parts.removeFirst(); // remove model name, e.g. "test"

  QJsonObject geometryObject;
  geometryObject["x"] = geometry.getX();
  geometryObject["y"] = geometry.getY();

  QJsonObject args;
  args["cref"] = QJsonArray::fromStringList(parts);
  args["geometry"] = geometryObject;

  QJsonObject obj;
  obj["method"] = "setConnectorGeometry";
  obj["args"] = args;

  QJsonObject reply;
  return sendZmqCommand(obj, reply);
}

/*!
 * \brief OMSProxy::setElementGeometry
 * Sets the element geometry
 * \param cref
 * \param pGeometry
 * \return
 */
bool OMSProxy::setElementGeometry(QString cref, const ssd_element_geometry_t* pGeometry)
{
  QString command = "oms_setElementGeometry";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_setElementGeometry(cref.toUtf8().constData(), pGeometry);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

bool OMSProxy::setElementGeometry(QString cref, const OMSModel::ElementGeometry &geometry)
{
  qDebug() << "setElementGeometry:" << cref;

  QStringList parts = cref.split(".");
  parts.removeFirst();

  QJsonObject geometryObject;
  geometryObject["x1"] = geometry.getX1();
  geometryObject["y1"] = geometry.getY1();
  geometryObject["x2"] = geometry.getX2();
  geometryObject["y2"] = geometry.getY2();
  geometryObject["rotation"] = geometry.getRotation();
  geometryObject["iconSource"] = geometry.getIconSource();
  geometryObject["iconRotation"] = geometry.getIconRotation();
  geometryObject["iconFlip"] = geometry.getIconFlip();
  geometryObject["iconFixedAspectRatio"] = geometry.getIconFixedAspectRatio();

  QJsonObject args;
  args["cref"] = QJsonArray::fromStringList(parts);
  args["geometry"] = geometryObject;

  QJsonObject obj;
  obj["method"] = "setElementGeometry";
  obj["args"] = args;

  QJsonObject reply;
  return sendZmqCommand(obj, reply);
}

/*!
 * \brief OMSProxy::setCommunicationInterval
 * Set the fixed step size for the simulation.
 * \param cref
 * \param stepSize
 * \return
 */
bool OMSProxy::setFixedStepSize(QString cref, double stepSize)
{
  QString command = "oms_setFixedStepSize";
  QStringList args;
  args << "\"" + cref + "\"" << QString::number(stepSize);
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_setFixedStepSize(cref.toUtf8().constData(), stepSize);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::setLogFile
 * Sets the log file.
 * \param filename
 */
void OMSProxy::setLogFile(QString filename)
{
  QString command = "oms_setLogFile";
  QStringList args;
  args << "\"" + filename + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_setLogFile(filename.toUtf8().constData());
  logResponse(command, status, &commandTime);
}

/*!
 * \brief OMSProxy::setLoggingCallback
 * Sets the logging callback.
 */
void OMSProxy::setLoggingCallback()
{
  QString command = "oms_setLoggingCallback";
  QStringList args;
  LOG_COMMAND(command, args);
  oms_setLoggingCallback(loggingCallback);
  logResponse(command, oms_status_ok, &commandTime);
}

/*!
 * \brief OMSProxy::setLoggingInterval
 * Sets the logging interval.
 * \param cref
 * \param loggingInterval
 * \return
 */
bool OMSProxy::setLoggingInterval(QString cref, double loggingInterval)
{
  QString command = "oms_setLoggingInterval";
  QStringList args;
  args << "\"" + cref + "\"" << QString::number(loggingInterval);
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_setLoggingInterval(cref.toUtf8().constData(), loggingInterval);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::setDebugLogging
 * Sets the logging level.
 * \param logLevel
 */
void OMSProxy::setLoggingLevel(int logLevel)
{
  QString command = "oms_setLoggingLevel";
  QStringList args;
  args << QString::number(logLevel);
  LOG_COMMAND(command, args);
  oms_setLoggingLevel(logLevel);
  logResponse(command, oms_status_ok, &commandTime);
}

/*!
 * \brief OMSProxy::setInteger
 * Sets the integer variable value.
 * \param cref
 * \param value
 * \return
 */
bool OMSProxy::setInteger(QString cref, int value)
{
  QString command = "oms_setInteger";
  QStringList args;
  args << "\"" + cref + "\"" << QString::number(value);
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_setInteger(cref.toUtf8().constData(), value);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::setReal
 * Sets the real variable value.
 * \param cref
 * \param value
 * \return
 */
bool OMSProxy::setReal(QString cref, double value)
{
  QString command = "oms_setReal";
  QStringList args;
  args << "\"" + cref + "\"" << QString::number(value);
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_setReal(cref.toUtf8().constData(), value);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::setResultFile
 * Set the result file for the simulation.
 * \param cref
 * \param filename
 * \param bufferSize
 * \return
 */
bool OMSProxy::setResultFile(QString cref, QString filename, int bufferSize)
{
  QString command = "oms_setResultFile";
  QStringList args;
  args << "\"" + cref + "\"" << "\"" + filename + "\"" << QString::number(bufferSize);
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_setResultFile(cref.toUtf8().constData(), filename.toUtf8().constData(), bufferSize);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

bool OMSProxy::getResultFile(QString cref, char **pFilename, int *pBufferSize)
{
  QString command = "oms_getResultFile";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_getResultFile(cref.toUtf8().constData(), pFilename, pBufferSize);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::setSolver
 * Sets the solver.
 * \param cref
 * \param solver
 * \return
 */
bool OMSProxy::setSolver(QString cref, oms_solver_enu_t solver)
{
  QString command = "oms_setSolver";
  QStringList args;
  args << "\"" + cref + "\"" << "\"" + QString::number(solver) + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_setSolver(cref.toUtf8().constData(), solver);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::setStartTime
 * Set the start time of the simulation.
 * \param cref
 * \param startTime
 * \return
 */
bool OMSProxy::setStartTime(QString cref, double startTime)
{
  QString command = "oms_setStartTime";
  QStringList args;
  args << "\"" + cref + "\"" << QString::number(startTime);
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_setStartTime(cref.toUtf8().constData(), startTime);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::setStopTime
 * Set the stop time of the simulation.
 * \param cref
 * \param stopTime
 * \return
 */
bool OMSProxy::setStopTime(QString cref, double stopTime)
{
  QString command = "oms_setStopTime";
  QStringList args;
  args << "\"" + cref + "\"" << QString::number(stopTime);
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_setStopTime(cref.toUtf8().constData(), stopTime);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::setTempDirectory
 * Sets the temp directory.
 * \param path
 */
void OMSProxy::setTempDirectory(QString path)
{
  QString command = "oms_setTempDirectory";
  QStringList args;
  args << "\"" + path + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_setTempDirectory(path.toUtf8().constData());
  logResponse(command, status, &commandTime);
}

/*!
 * \brief OMSProxy::setTolerance
 * Sets the tolerance.
 * \param cref
 * \param tolerance
 * \return
 */
bool OMSProxy::setTolerance(QString cref, double absoluteTolerance, double relativeTolerance)
{
  QString command = "oms_setTolerance";
  QStringList args;
  args << "\"" + cref + "\"" << QString::number(absoluteTolerance) << QString::number(relativeTolerance);
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_setTolerance(cref.toUtf8().constData(), absoluteTolerance, relativeTolerance);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::setVariableStepSize
 * Sets the variable step size.
 * \param cref
 * \param initialStepSize
 * \param minimumStepSize
 * \param maximumStepSize
 * \return
 */
bool OMSProxy::setVariableStepSize(QString cref, double initialStepSize, double minimumStepSize, double maximumStepSize)
{
  QString command = "oms_setVariableStepSize";
  QStringList args;
  args << "\"" + cref + "\"" << QString::number(initialStepSize) << QString::number(minimumStepSize) << QString::number(maximumStepSize);
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_setVariableStepSize(cref.toUtf8().constData(), initialStepSize, minimumStepSize, maximumStepSize);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::setWorkingDirectory
 * Sets the working directory.
 * \param path
 */
void OMSProxy::setWorkingDirectory(QString path)
{
  QString command = "oms_setWorkingDirectory";
  QStringList args;
  args << "\"" + path + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_setWorkingDirectory(path.toUtf8().constData());
  logResponse(command, status, &commandTime);
}

/*!
 * \brief OMSProxy::terminate
 * Terminates the model.
 * \param cref
 * \return
 */
bool OMSProxy::terminate(QString cref)
{
  QString command = "oms_terminate";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_terminate(cref.toUtf8().constData());
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}
