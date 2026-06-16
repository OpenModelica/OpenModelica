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
  if (mpInstance) {
    delete mpInstance;
    mpInstance = 0;
  }
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
  mpGuiProcess = new QProcess(this);
  // connect signals
  connect(mpGuiProcess, &QProcess::started, this, &OMSProxy::guiProcessStarted);
  connect(mpGuiProcess, &QProcess::errorOccurred, this, &OMSProxy::guiProcessError);
  connect(mpGuiProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, &OMSProxy::guiProcessFinished);
  connect(mpGuiProcess, &QProcess::readyReadStandardOutput, this, &OMSProxy::readGuiServerStandardOutput);
  connect(mpGuiProcess, &QProcess::readyReadStandardError, this, &OMSProxy::readGuiServerStandardError);
  QString endpoint = mpGuiRequestSocket->endPoint();
  QStringList args(QString("%1/share/OMSimulator/scripts/OMSimulatorGuiServer.py").arg(Helper::OpenModelicaHome));
  args << "--endpoint-rep" << endpoint;
  // start the executable
  QString process;
#if defined(_WIN32)
  process = QString("python");
  QProcessEnvironment processEnvironment = QProcessEnvironment::systemEnvironment();
  QString OMHOME = QString(Helper::OpenModelicaHome);
  processEnvironment.insert("PYTHONPATH",  OMHOME + "/bin;" + OMHOME + "/lib/omc;" + processEnvironment.value("PYTHONPATH"));
  processEnvironment.insert("PATH",  OMHOME + "/bin;" + OMHOME + "/lib;" + processEnvironment.value("PATH"));
  mpGuiProcess->setProcessEnvironment(processEnvironment);
#else
  process = QString("%1/bin/OMSimulatorPython3").arg(Helper::OpenModelicaHome);
#endif
  mpGuiProcess->start(process, args);
}

void OMSProxy::guiProcessStarted()
{
  mServerReady = true;
  MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
    tr("OMSimulator Python GUI server started at %1.").arg(mpGuiRequestSocket->endPoint()),
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
    emit logGUIMessage(MessageItem(MessageItem::Modelica, output, Helper::scriptingKind, Helper::notificationLevel));
  }
}

void OMSProxy::readGuiServerStandardError()
{
  QString error = QString::fromUtf8(mpGuiProcess->readAllStandardError()).trimmed();
  if (!error.isEmpty()) {
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
  if (mpCommunicationLogFile) {
    fputs(QString("%1 %2\n").arg(command, QTime::currentTime().toString("hh:mm:ss:zzz")).toUtf8().constData(), mpCommunicationLogFile);
  }
}

void OMSProxy::logResponse(QString method, QString status, QElapsedTimer *responseTime)
{
  if (mpCommunicationLogFile) {
    double elapsed = responseTime->elapsed() / 1000.0;
    mTotalOMSCallsTime += elapsed;
    fputs(QString("%1 %2\n").arg(status, QTime::currentTime().toString("hh:mm:ss:zzz")).toUtf8().constData(), mpCommunicationLogFile);
    fputs(QString("#s#; %1; %2; '%3'\n\n")
      .arg(QString::number(elapsed, 'f', 6),
           QString::number(mTotalOMSCallsTime, 'f', 6),
           method).toUtf8().constData(), mpCommunicationLogFile);
  }
}

/*!
 * \brief OMSProxy::sendZmqCommand
 * Centralized helper for all ZMQ JSON commands: logs the command and reply to the
 * communication log file, checks for errors, and posts a message to the GUI
 * message widget on failure. Returns true only when the server replies with status "ok".
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

  logCommand(QString("zmq(%1)").arg(QString(QJsonDocument(obj).toJson(QJsonDocument::Compact))));

  bool ok = mpGuiRequestSocket->sendCommand(obj, reply);
  QString status = ok ? reply["status"].toString() : "timeout";
  logResponse(method, status, &commandTime);

  if (MainWindow::instance()->isDebug())
    fflush(NULL);

  if (!ok) {
    QString msg = tr("OMSimulator server did not respond to '%1' (timeout or crash). Check the Messages window for Python errors.").arg(method);
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, msg, Helper::scriptingKind, Helper::errorLevel));
    QApplication::processEvents(QEventLoop::ExcludeUserInputEvents);
    return false;
  }

  status = reply["status"].toString();
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
 * \brief OMSProxy::getVersion
 * Returns the OMSimulator version string from the Python server.
 * \return version string (e.g. "OMSimulator v3.0.0").
 */
QString OMSProxy::getVersion()
{
  QJsonObject obj, reply;
  obj["method"] = "getVersion";
  if (!sendZmqCommand(obj, reply))
    return QString("OMSimulator");
  return reply["version"].toString();
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
  QStringList startConnector = crefA.split(".");
  QStringList endConnector = crefB.split(".");

  startConnector.removeFirst();
  endConnector.removeFirst();

  QJsonObject obj, args;
  obj["method"] = "addConnection";
  obj["model"]  = crefA.split('.').first();

  args["crefA"] = QJsonArray::fromStringList(startConnector);
  args["crefB"] = QJsonArray::fromStringList(endConnector);
  args["suppressUnitConversion"] = suppressUnitConversion;
  obj["args"] = args;

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
bool OMSProxy::addConnector(QString cref, OMSModel::Causality causality, OMSModel::SignalType type)
{
  QStringList parts = cref.split(".");

  // Save connector name before removing
  QString connectorName = parts.last();

  parts.removeFirst();
  parts.removeLast();

  QJsonObject obj, args;
  obj["method"] = "addConnector";
  obj["model"]  = cref.split('.').first();

  args["cref"] = QJsonArray::fromStringList(parts);
  args["name"] = connectorName;
  args["causality"] = OMSModel::Connector::causalityToString(causality);
  args["type"] = OMSModel::Connector::signalTypeToString(type);

  obj["args"] = args;

  QJsonObject reply;
  return sendZmqCommand(obj, reply);
}

/*!
 * \brief OMSProxy::addSubModel
 * Adds the submodel to the system
 * \param cref
 * \param fmuPath
 * \return
 */
bool OMSProxy::addSubModel(QString cref, QString fmuPath)
{
  QStringList parts = cref.split(".");
  parts.removeFirst();
  QJsonObject obj, args;
  obj["method"] = "addComponent";
  obj["model"]  = cref.split('.').first();
  args["cref"] = QJsonArray::fromStringList(parts);
  args["source"] = fmuPath;
  args["new_name"] = "resources/" + parts.last() + ".fmu";
  obj["args"] = args;

  QJsonObject reply;
  return sendZmqCommand(obj, reply);
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
// bool OMSProxy::replaceSubModel(QString cref, QString fmuPath, bool dryCount, int *count)
// {
//   QString command = "oms_replaceSubModel";
//   QStringList args;
//   args << "\"" + cref + "\"" << fmuPath << QString::number(dryCount);
//   LOG_COMMAND(command, args);
//   oms_status_enu_t status = oms_replaceSubModel(cref.toUtf8().constData(), fmuPath.toUtf8().constData(), dryCount, count);
//   logResponse(command, status, &commandTime);
//   return statusToBool(status);
// }

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
}

/*!
 * \brief OMSProxy::addSystem
 * Adds a system to a model.
 * \param cref
 * \return
 */
bool OMSProxy::addSystem(QString cref)
{
  QStringList parts = cref.split(".");
  parts.removeFirst(); // remove model name

  QJsonObject args;
  args["cref"] = QJsonArray::fromStringList(parts);

  QJsonObject obj;
  obj["method"] = "addSystem";
  obj["model"]  = cref.split('.').first();
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
  QStringList startConnector = crefA.split(".");
  QStringList endConnector = crefB.split(".");

  startConnector.removeFirst();
  endConnector.removeFirst();

  QJsonObject obj, args;
  obj["method"] = "deleteConnection";
  obj["model"]  = crefA.split('.').first();

  args["crefA"] = QJsonArray::fromStringList(startConnector);
  args["crefB"] = QJsonArray::fromStringList(endConnector);
  obj["args"] = args;

  QJsonObject reply;
  return sendZmqCommand(obj, reply);
}

/*!
 * \brief OMSProxy::getBoolean
 * Gets the boolean variable value.
 * \param cref
 * \param value
 * \return
 */
bool OMSProxy::getBoolean(QString cref, bool &value)
{
  QStringList parts = cref.split('.');
  QJsonObject obj, args;
  obj["method"] = "getValue";
  obj["model"]  = parts.first();
  parts.removeFirst();
  args["cref"]  = QJsonArray::fromStringList(parts);
  obj["args"]   = args;

  QJsonObject reply;
  if (!sendZmqCommand(obj, reply))
    return false;

  value = reply["value"].toString().toLower() == "true" || reply["value"].toString() == "1";
  return true;
}

/*!
 * \brief OMSProxy::getElementsJson
 * Gets the ssp elements
 * \param cref
 * \param elements
 * \return
 */

bool OMSProxy::getElementsJson(QString cref, QJsonArray &elements)
{
  QJsonObject obj;
  obj["method"] = "getElements";
  obj["model"]  = cref.split('.').first();

  QJsonObject args;
  args["cref"] = cref;
  obj["args"] = args;

  QJsonObject reply;
  if (!sendZmqCommand(obj, reply))
    return false;

  elements = reply["elements"].toArray();
  //qDebug().noquote() << "getElements reply:" << QJsonDocument(reply).toJson(QJsonDocument::Indented);
  return true;
}

/*!
 * \brief OMSProxy::getFixedStepSize
 * Gets the fixed step size.
 * \param cref
 * \param stepSize
 * \return
 */
bool OMSProxy::getFixedStepSize(QString cref, double& stepSize)
{
  QJsonObject obj;
  obj["method"] = "getFixedStepSize";
  obj["model"]  = cref.split('.').first();
  QJsonObject reply;
  if (!sendZmqCommand(obj, reply))
    return false;

  stepSize = reply["value"].toString().toDouble();
  return true;
}

/*!
 * \brief OMSProxy::setFixedStepSize
 * Set the fixed step size for the simulation.
 * \param cref
 * \param stepSize
 * \return
 */
bool OMSProxy::setFixedStepSize(QString cref, double stepSize)
{
  QJsonObject obj, args;
  obj["method"] = "setFixedStepSize";
  obj["model"]  = cref.split('.').first();
  args["value"] = stepSize;
  obj["args"] = args;

  QJsonObject reply;
  return sendZmqCommand(obj, reply);
}

/*!
 * \brief OMSProxy::getInteger
 * Gets the integer variable value.
 * \param cref
 * \param value
 * \return
 */
bool OMSProxy::getInteger(QString cref, int &value)
{
  QStringList parts = cref.split('.');
  QJsonObject obj, args;
  obj["method"] = "getValue";
  obj["model"]  = parts.first();
  parts.removeFirst();
  args["cref"]  = QJsonArray::fromStringList(parts);
  obj["args"]   = args;

  QJsonObject reply;
  if (!sendZmqCommand(obj, reply))
    return false;

  value = reply["value"].toString().toInt();
  return true;
}

/*!
 * \brief OMSProxy::getReal
 * Gets the real variable value.
 * \param cref
 * \param value
 * \return
 */
bool OMSProxy::getReal(QString cref, double &value)
{
  QStringList parts = cref.split('.');
  QJsonObject obj, args;
  obj["method"] = "getValue";
  obj["model"]  = parts.first();
  parts.removeFirst();
  args["cref"]  = QJsonArray::fromStringList(parts);
  obj["args"]   = args;

  QJsonObject reply;
  if (!sendZmqCommand(obj, reply))
    return false;
  value = reply["value"].toString().toDouble();
  return true;
}

/*!
 * \brief OMSProxy::getSolver
 * Gets the solver.
 * \param cref
 * \param solver
 * \return
 */
bool OMSProxy::getSolverSettings(const QString &cref, QJsonObject &settings)
{
  QJsonObject obj;
  obj["method"] = "getSolverSettings";
  obj["model"]  = cref.split('.').first();
  QJsonObject reply;
  if (!sendZmqCommand(obj, reply))
    return false;
  settings["solvers"] = reply["solvers"].toArray();
  settings["assignments"] = reply["assignments"].toObject();
  return true;
}

bool OMSProxy::setSolverSettings(const QString &cref, const QJsonObject &settings)
{
  QJsonObject obj, args;
  obj["method"] = "setSolverSettings";
  obj["model"]  = cref.split('.').first();
  args["solvers"] = settings["solvers"];
  args["assignments"] = settings["assignments"];
  obj["args"]  = args;
  QJsonObject reply;
  return sendZmqCommand(obj, reply);
}

bool OMSProxy::setSolver(const QString &cref, const QString &solverName)
{
  QStringList parts = cref.split('.');
  QJsonObject obj, args;
  obj["method"] = "setSolver";
  obj["model"]  = parts.first();
  parts.removeFirst();
  args["cref"]   = QJsonArray::fromStringList(parts);
  args["solver"] = solverName;
  obj["args"]    = args;
  QJsonObject reply;
  return sendZmqCommand(obj, reply);
}

/*!
 * \brief OMSProxy::getStartTime
 * Get the start time from the model.
 * \param cref
 * \param startTime
 * \return
 */
bool OMSProxy::getStartTime(QString cref, double& startTime)
{
  QJsonObject obj;
  obj["method"] = "getStartTime";
  obj["model"]  = cref.split('.').first();
  QJsonObject reply;
  if (!sendZmqCommand(obj, reply))
    return false;
  startTime = reply["value"].toString().toDouble();
  return true;
}

/*!
 * \brief OMSProxy::getStopTime
 * Get the stop time sfrom the model.
 * \param cref
 * \param stopTime
 * \return
 */
bool OMSProxy::getStopTime(QString cref, double& stopTime)
{
  QJsonObject obj;
  obj["method"] = "getStopTime";
  obj["model"]  = cref.split('.').first();
  QJsonObject reply;
  if (!sendZmqCommand(obj, reply))
    return false;
  stopTime = reply["value"].toString().toDouble();
  return true;
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
  QJsonObject obj, args;
  obj["method"] = "getSubModelPath";
  obj["model"]  = cref.split('.').first();
  args["cref"]  = cref;
  obj["args"]   = args;
  QJsonObject reply;
  if (!sendZmqCommand(obj, reply))
    return false;
  *pPath = reply["path"].toString();
  return true;
}


/*!
 * \brief OMSProxy::getTolerance
 * Gets the tolerance.
 * \param cref
 * \param relativeTolerance
 * \return
 */
bool OMSProxy::getTolerance(QString cref, double &relativeTolerance)
{
  QJsonObject obj;
  obj["method"] = "getTolerance";
  obj["model"]  = cref.split('.').first();
  QJsonObject reply;
  if (!sendZmqCommand(obj, reply))
    return false;

  relativeTolerance = reply["value"].toString().toDouble();
  return true;
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
bool OMSProxy::getVariableStepSize(QString cref, QString solverName, double& initialStepSize, double& minimumStepSize, double& maximumStepSize)
{
  QJsonObject obj, args;
  obj["method"] = "getVariableStepSize";
  obj["model"]  = cref.split('.').first();
  args["solver"] = solverName;
  obj["args"] = args;
  QJsonObject reply;
  if (!sendZmqCommand(obj, reply))
    return false;
  initialStepSize = reply["initialStepSize"].toString().toDouble();
  minimumStepSize = reply["minimumStepSize"].toString().toDouble();
  maximumStepSize = reply["maximumStepSize"].toString().toDouble();

  return true;
}

/*!
 * \brief OMSProxy::exportSnapshot
 * Lists the contents of a model.
 * \param cref
 * \param pContents
 * \return
 */
bool OMSProxy::exportSnapshot(QString cref, QString &pContents)
{
  QJsonObject obj;
  obj["method"] = "exportSnapshot";
  obj["model"]  = cref.split('.').first();
  QJsonObject reply;

  if (!sendZmqCommand(obj, reply))
    return false;

  QString xml = reply["xml"].toString();
  if (!xml.isEmpty())
    pContents = xml;
  return true;
}

/*!
 * \brief OMSProxy::loadModel
 * Loads the model.
 * \param filename
 * \param pModelName
 * \return
 */
bool OMSProxy::loadModel(QString filename, QString& pModelName)
{
  QJsonObject obj, args;
  obj["method"] = "importFile";
  args["file"] = filename;
  obj["args"] = args;
  QJsonObject reply;

  if (!sendZmqCommand(obj, reply))
    return false;

  QString modelName = reply["modelName"].toString();
  if (!modelName.isEmpty())
    pModelName = modelName;

  return true;
}

/*!
 * \brief OMSProxy::importSnapshot
 * Loads the snapshot of the model.
 * \param cref
 * \param snapshot
 * \param pNewCref
 * \return
 */
bool OMSProxy::importSnapshot(QString cref, QString snapshot, QString& pNewCref, QString& pNewRootCref)
{
  QJsonObject obj, args;
  obj["method"] = "importSnapshot";
  obj["model"]  = cref.split('.').first();
  args["snapshot"] = snapshot;
  obj["args"] = args;
  QJsonObject reply;
  if (!sendZmqCommand(obj, reply))
    return false;
  // pNewCref receives the (possibly renamed) model name — used by redoInternal to keep mModelName correct.
  QString newModelName = reply["modelName"].toString();
  pNewCref = newModelName.isEmpty() ? cref : newModelName;
  // pNewRootCref receives the root system name — used by text-editor callers to build newEditedCref.
  pNewRootCref = reply["rootCref"].toString();
  return true;
}

/*!
 * \brief OMSProxy::newModel
 * \param cref
 * \param systemName
 * \return
 */
bool OMSProxy::newModel(QString cref, QString systemName)
{
  QJsonObject obj, args;
  obj["method"] = "newModel";
  obj["model"]  = cref;
  args["name"]  = cref;
  args["system_name"] = systemName;
  obj["args"] = args;

  QJsonObject reply;
  return sendZmqCommand(obj, reply);
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
  QStringList parts = cref.split('.');
  const QString modelName = parts.first();
  parts.removeFirst();
  QJsonObject obj, argsObj;
  obj["method"] = "rename";
  obj["model"]  = modelName;
  argsObj["cref"]    = QJsonArray::fromStringList(parts);
  argsObj["newName"] = newCref;
  obj["args"] = argsObj;

  QJsonObject reply;
  return sendZmqCommand(obj, reply);
}

/*!
 * \brief OMSProxy::omsDelete
 * \param cref
 * \return
 */
bool OMSProxy::omsDelete(QString cref)
{
  QStringList parts = cref.split('.');
  QJsonObject obj, args;
  obj["method"] = "delete";
  obj["model"]  = parts.first();
  parts.removeFirst();
  args["cref"] = QJsonArray::fromStringList(parts);
  obj["args"] = args;
  QJsonObject reply;
  return sendZmqCommand(obj, reply);
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
  QJsonObject obj, args;
  obj["method"] = "export";
  obj["model"]  = cref.split('.').first();
  args["file"] = filename;
  obj["args"] = args;
  QJsonObject reply;
  return sendZmqCommand(obj, reply);
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
  QStringList parts = cref.split('.');
  QJsonObject obj, args;
  obj["method"] = "setValue";
  obj["model"]  = parts.first();
  parts.removeFirst();
  args["cref"]  = QJsonArray::fromStringList(parts);
  args["value"] = value ? QString("true") : QString("false");
  obj["args"]   = args;
  QJsonObject reply;
  return sendZmqCommand(obj, reply);
}

/*!
 * \brief OMSProxy::setConnectionGeometry
 * Sets the connection geometry.
 * \param crefA
 * \param crefB
 * \param pGeometry
 * \return
 */
bool OMSProxy::setConnectionGeometry(QString crefA, QString crefB, const OMSModel::ConnectionGeometry &geometry)
{
  QStringList conA = crefA.split(".");
  conA.removeFirst();

  QStringList conB = crefB.split(".");
  conB.removeFirst();

  QJsonArray pointsX;
  QJsonArray pointsY;

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
  obj["model"]  = crefA.split('.').first();
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
bool OMSProxy::setConnectorGeometry(QString cref, const OMSModel::ConnectorGeometry &pGeometry)
{
  QStringList parts = cref.split(".");
  parts.removeFirst(); // remove model name, e.g. "test"

  QJsonObject geometryObject;
  geometryObject["x"] = pGeometry.getX();
  geometryObject["y"] = pGeometry.getY();

  QJsonObject args;
  args["cref"] = QJsonArray::fromStringList(parts);
  args["geometry"] = geometryObject;

  QJsonObject obj;
  obj["method"] = "setConnectorGeometry";
  obj["model"]  = cref.split('.').first();
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
bool OMSProxy::setElementGeometry(QString cref, const OMSModel::ElementGeometry &pGeometry)
{
  QStringList parts = cref.split(".");
  parts.removeFirst();

  QJsonObject geometryObject;
  geometryObject["x1"] = pGeometry.getX1();
  geometryObject["y1"] = pGeometry.getY1();
  geometryObject["x2"] = pGeometry.getX2();
  geometryObject["y2"] = pGeometry.getY2();
  geometryObject["rotation"] = pGeometry.getRotation();
  geometryObject["iconSource"] = pGeometry.getIconSource();
  geometryObject["iconRotation"] = pGeometry.getIconRotation();
  geometryObject["iconFlip"] = pGeometry.getIconFlip();
  geometryObject["iconFixedAspectRatio"] = pGeometry.getIconFixedAspectRatio();

  QJsonObject args;
  args["cref"] = QJsonArray::fromStringList(parts);
  args["geometry"] = geometryObject;

  QJsonObject obj;
  obj["method"] = "setElementGeometry";
  obj["model"]  = cref.split('.').first();
  obj["args"] = args;

  QJsonObject reply;
  return sendZmqCommand(obj, reply);
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
  QStringList parts = cref.split('.');
  QJsonObject obj, args;
  obj["method"] = "setLoggingInterval";
  obj["model"]  = parts.first();
  parts.removeFirst();
  args["cref"]  = QJsonArray::fromStringList(parts);
  args["loggingInterval"] = QString::number(loggingInterval);
  obj["args"]   = args;
  QJsonObject reply;
  return sendZmqCommand(obj, reply);
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
  QStringList parts = cref.split('.');
  QJsonObject obj, args;
  obj["method"] = "setValue";
  obj["model"]  = parts.first();
  parts.removeFirst();
  args["cref"]  = QJsonArray::fromStringList(parts);
  args["value"] = QString::number(value);
  obj["args"]   = args;
  QJsonObject reply;
  return sendZmqCommand(obj, reply);
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
  QStringList parts = cref.split('.');
  QJsonObject obj, args;
  obj["method"] = "setValue";
  obj["model"]  = parts.first();
  parts.removeFirst();
  args["cref"]  = QJsonArray::fromStringList(parts);
  args["value"] = QString::number(value);
  obj["args"]   = args;
  QJsonObject reply;
  return sendZmqCommand(obj, reply);
}

/*!
 * \brief OMSProxy::setResultFile
 * Set the result file for the simulation.
 * \param cref
 * \param filename
 * \param bufferSize
 * \return
 */
bool OMSProxy::setResultFile(QString cref, QString fileName, int bufferSize)
{
  QJsonObject obj, args;
  obj["method"] = "setResultFile";
  obj["model"]  = cref.split('.').first();
  args["fileName"]  = fileName;
  args["bufferSize"] = bufferSize;
  obj["args"] = args;
  QJsonObject reply;
  return sendZmqCommand(obj, reply);
}

bool OMSProxy::getResultFile(QString cref, QString& fileName, int& bufferSize)
{
  QJsonObject obj, args;
  obj["method"] = "getResultFile";
  obj["model"]  = cref.split('.').first();
  args["fileName"]  = fileName;
  args["bufferSize"] = bufferSize;
  obj["args"] = args;
  QJsonObject reply;
  if (!sendZmqCommand(obj, reply))
    return false;
  fileName = reply["fileName"].toString();
  bufferSize = reply["bufferSize"].toInt();
  return true;

}

/*!
 * \brief OMSProxy::setS
 * Sets the solver.
 * \param cref
 * \param solver
 * \return
 */
// setSolver(const QString&, const QString&) implemented above with getSolverSettings/setSolverSettings

/*!
 * \brief OMSProxy::setStartTime
 * Set the start time of the simulation.
 * \param cref
 * \param startTime
 * \return
 */
bool OMSProxy::setStartTime(QString cref, double startTime)
{
  QJsonObject obj, args;
  obj["method"] = "setStartTime";
  obj["model"]  = cref.split('.').first();
  args["value"] = startTime;
  obj["args"] = args;

  QJsonObject reply;
  return sendZmqCommand(obj, reply);
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
  QJsonObject obj, args;
  obj["method"] = "setStopTime";
  obj["model"]  = cref.split('.').first();
  args["value"] = stopTime;
  obj["args"] = args;

  QJsonObject reply;
  return sendZmqCommand(obj, reply);
}

/*!
 * \brief OMSProxy::setTolerance
 * Sets the tolerance.
 * \param cref
 * \param tolerance
 * \return
 */
bool OMSProxy::setTolerance(QString cref, double relativeTolerance)
{
  QJsonObject obj, args;
  obj["method"] = "setTolerance";
  obj["model"]  = cref.split('.').first();
  args["value"] = relativeTolerance;
  obj["args"] = args;

  QJsonObject reply;
  return sendZmqCommand(obj, reply);
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
  QJsonObject obj, args;
  obj["method"] = "setTolerance";
  obj["model"]  = cref.split('.').first();
  args["initialStepSize"] = initialStepSize;
  args["minimumStepSize"] = minimumStepSize;
  args["maximumStepSize"] = maximumStepSize;
  obj["args"] = args;

  QJsonObject reply;
  return sendZmqCommand(obj, reply);
}

// /*!
//  * \brief OMSProxy::setWorkingDirectory
//  * Sets the working directory.
//  * \param path
//  */
// void OMSProxy::setWorkingDirectory(QString path)
// {
//   QJsonObject obj, args;
//   obj["method"] = "setWorkingDirectory";
//   args["path"] = path;
//   obj["args"] = args;
//   QJsonObject reply;
//   sendZmqCommand(obj, reply);
// }
