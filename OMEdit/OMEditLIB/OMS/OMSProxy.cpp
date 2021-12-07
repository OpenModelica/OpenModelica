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

#include "OMSProxy.h"
#include "Util/Helper.h"
#include "MainWindow.h"
#include "Util/Utilities.h"

#include <QTime>

#define LOG_COMMAND(command,args) \
  QElapsedTimer commandTime; \
  commandTime.start(); \
  command = QString("%1(%2)").arg(command, args.join(",")); \
  logCommand(command);

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
}

OMSProxy::~OMSProxy()
{
  if (mpCommunicationLogFile) {
    fclose(mpCommunicationLogFile);
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
    case oms_system_tlm:
      return Helper::systemTLM;
    case oms_system_wc:
      return Helper::systemWC;
    case oms_system_sc:
      return Helper::systemSC;
    default:
      // should never be reached
      return "";
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
    case oms_system_tlm:
      return "TLM";
    case oms_system_wc:
      return "WC";
    case oms_system_sc:
      return "SC";
    default:
      // should never be reached
      return "";
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
 * \brief OMSProxy::getInterpolationString
 * Returns the oms_tlm_interpolation_t as string.
 * \param interpolation
 * \return
 */
QString OMSProxy::getInterpolationString(oms_tlm_interpolation_t interpolation)
{
  switch (interpolation) {
    case oms_tlm_no_interpolation:
      return "No interpolation";
    case oms_tlm_coarse_grained:
      return "Coarse grained";
    case oms_tlm_fine_grained:
      return "Fine grained";
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
bool OMSProxy::addConnection(QString crefA, QString crefB)
{
  QString command = "oms_addConnection";
  QStringList args;
  args << "\"" + crefA + "\"" << "\"" + crefB + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_addConnection(crefA.toUtf8().constData(), crefB.toUtf8().constData());
  logResponse(command, status, &commandTime);
  return statusToBool(status);
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
  QString command = "oms_addConnector";
  QStringList args;
  args << "\"" + cref + "\"" << QString::number(causality) << QString::number(type);
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_addConnector(cref.toUtf8().constData(), causality, type);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
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
 * \brief OMSProxy::addConnectorToTLMBus
 * Adds a connector to a tlm bus.
 * \param busCref
 * \param connectorCref
 * \param type
 * \return
 */
bool OMSProxy::addConnectorToTLMBus(QString busCref, QString connectorCref, QString type)
{
  QString command = "oms_addConnectorToTLMBus";
  QStringList args;
  args << busCref << connectorCref << type;
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_addConnectorToTLMBus(busCref.toUtf8().constData(), connectorCref.toUtf8().constData(),
                                                     type.toUtf8().constData());
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
  QString command = "oms_addSubModel";
  QStringList args;
  args << "\"" + cref + "\"" << fmuPath;
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_addSubModel(cref.toUtf8().constData(), fmuPath.toUtf8().constData());
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

  ssd_element_geometry_t elementGeometry;
  elementGeometry.x1 = x - 10.0;
  elementGeometry.y1 = y - 10.0;
  elementGeometry.x2 = x + 10.0;
  elementGeometry.y2 = y + 10.0;
  elementGeometry.rotation = 0.0;
  elementGeometry.iconSource = NULL;
  elementGeometry.iconRotation = 0.0;
  elementGeometry.iconFlip = false;
  elementGeometry.iconFixedAspectRatio = false;
  setElementGeometry(cref, &elementGeometry);
}

bool OMSProxy::addExternalTLMModel(QString cref, QString startScript, QString modelPath)
{
    QString command = "oms_addExternalModel";
    QStringList args;
    args << "\"" + cref + "\"" << modelPath << "\"" << startScript;
    LOG_COMMAND(command, args);
    oms_status_enu_t status = oms_addExternalModel(cref.toUtf8().constData(), modelPath.toUtf8().constData(), startScript.toUtf8().constData());
    logResponse(command, status, &commandTime);
    return statusToBool(status);
}

/*!
 * \brief OMSProxy::addSystem
 * Adds a system to a model.
 * \param cref
 * \param type
 * \return
 */
bool OMSProxy::addSystem(QString cref, oms_system_enu_t type)
{
  QString command = "oms_addSystem";
  QStringList args;
  args << "\"" + cref + "\"" << QString::number(type);
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_addSystem(cref.toUtf8().constData(), type);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::addTLMBus
 * Adds a tlm bus.
 * \param cref
 * \param domain
 * \param dimensions
 * \param interpolation
 * \return
 */
bool OMSProxy::addTLMBus(QString cref, oms_tlm_domain_t domain, int dimensions, const oms_tlm_interpolation_t interpolation)
{
  QString command = "oms_addTLMBus";
  QStringList args;
  args << "\"" + cref + "\"" << QString::number(domain) << QString::number(dimensions) << QString::number(interpolation);
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_addTLMBus(cref.toUtf8().constData(), domain, dimensions, interpolation);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::addTLMConnection
 * Adds a TLM connection.
 * \param crefA
 * \param crefB
 * \param delay
 * \param alpha
 * \param linearimpedance
 * \param angularimpedance
 * \return
 */
bool OMSProxy::addTLMConnection(QString crefA, QString crefB, double delay, double alpha, double linearimpedance, double angularimpedance)
{
  QString command = "oms_addTLMConnection";
  QStringList args;
  args << "\"" + crefA + "\"" << "\"" + crefB + "\"" << QString::number(delay) << QString::number(alpha)
       << QString::number(linearimpedance) << QString::number(angularimpedance);
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_addTLMConnection(crefA.toUtf8().constData(), crefB.toUtf8().constData(), delay, alpha,
                                                 linearimpedance, angularimpedance);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
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
 * \brief OMSProxy::deleteConnectorFromTLMBus
 * Deletes a connector from a tlm bus.
 * \param busCref
 * \param connectorCref
 * \return
 */
bool OMSProxy::deleteConnectorFromTLMBus(QString busCref, QString connectorCref)
{
  QString command = "oms_deleteConnectorFromTLMBus";
  QStringList args;
  args << busCref << connectorCref;
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_deleteConnectorFromTLMBus(busCref.toUtf8().constData(), connectorCref.toUtf8().constData());
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
 * \brief OMSProxy::getFMUInfo
 * Gets the FMU info.
 * \param cref
 * \param pFmuInfo
 * \return
 */
bool OMSProxy::getExternalTLMModelInfo(QString cref, const oms_external_tlm_model_info_t** pExternalTLMModelInfo)
{
  QString command = "getExternalTLMModelInfo";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_getExternalModelInfo(cref.toUtf8().constData(), pExternalTLMModelInfo);
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
  QString command = "oms_getSystemType";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_getSystemType(cref.toUtf8().constData(), pType);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::getTLMBus
 * Gets the bus.
 * \param cref
 * \param pTLMBusConnector
 * \return
 */
bool OMSProxy::getTLMBus(QString cref, oms_tlmbusconnector_t **pTLMBusConnector)
{
  QString command = "oms_getTLMBus";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_getTLMBus(cref.toUtf8().constData(), pTLMBusConnector);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::getTLMVariableTypes
 * Gets the TLM variables types based on the domain, dimensions and interpoation.
 * \param domain
 * \param dimensions
 * \param interpolation
 * \param types
 * \param descriptions
 * \return
 */
bool OMSProxy::getTLMVariableTypes(oms_tlm_domain_t domain, const int dimensions, const oms_tlm_interpolation_t interpolation,
                                   char ***types, char ***descriptions)
{
  QString command = "oms_getTLMVariableTypes";
  QStringList args;
  args << QString::number(domain) << QString::number(dimensions) << QString::number(interpolation);
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_getTLMVariableTypes(domain, dimensions, interpolation, types, descriptions);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
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
 * Initializes a model (works for both FMI and TLM).
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
  QString command = "oms_exportSnapshot";
  QString cref_ = cref + ":SystemStructure.ssd";
  QStringList args;
  args << "\"" + cref_ + "\"";
  LOG_COMMAND(command, args);
  char* contents = NULL;
  oms_status_enu_t status = oms_exportSnapshot(cref_.toUtf8().constData(), &contents);
  if (contents) {
    *pContents = QString(contents);
    free(contents);
  }
  logResponse(command, status, &commandTime);
  return statusToBool(status);
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
bool OMSProxy::newModel(QString cref)
{
  QString command = "oms_newModel";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_newModel(cref.toUtf8().constData());
  logResponse(command, status, &commandTime);
  return statusToBool(status);
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
  QString command = "oms_setConnectionGeometry";
  QStringList args;
  args << "\"" + crefA + "\"" << "\"" + crefB + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_setConnectionGeometry(crefA.toUtf8().constData(), crefB.toUtf8().constData(), pGeometry);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
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
  QString command = "oms_setConnectorGeometry";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_setConnectorGeometry(cref.toUtf8().constData(), pGeometry);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
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
 * \brief OMSProxy::setTLMBusGeometry
 * Sets the tlm bus geometry.
 * \param cref
 * \param pGeometry
 * \return
 */
bool OMSProxy::setTLMBusGeometry(QString cref, const ssd_connector_geometry_t* pGeometry)
{
  QString command = "oms_setTLMBusGeometry";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_setTLMBusGeometry(cref.toUtf8().constData(), pGeometry);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::setTLMConnectionParameters
 * Sets the TLM parameters of a connection.
 * \param crefA
 * \param crefB
 * \param pParameters
 * \return
 */
bool OMSProxy::setTLMConnectionParameters(QString crefA, QString crefB, const oms_tlm_connection_parameters_t *pParameters)
{
  QString command = "oms_setTLMConnectionParameters";
  QStringList args;
  args << "\"" + crefA + "\"" << "\"" + crefB + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_setTLMConnectionParameters(crefA.toUtf8().constData(), crefB.toUtf8().constData(), pParameters);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::setTLMSocketData
 * Sets the TLM system socket data.
 * \param cref
 * \param address
 * \param managerPort
 * \param monitorPort
 * \return
 */
bool OMSProxy::setTLMSocketData(QString cref, QString address, int managerPort, int monitorPort)
{
  QString command = "oms_setTLMSocketData";
  QStringList args;
  args << "\"" + cref + "\"" << address << QString::number(managerPort) << QString::number(monitorPort);
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms_setTLMSocketData(cref.toUtf8().constData(), address.toUtf8().constData(), managerPort, monitorPort);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
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
