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
#include "OMSSimulationDialog.h"
#include "OMSSimulationOutputWidget.h"
#include "Util/Utilities.h"

#define LOG_COMMAND(command,args) \
  QTime commandTime; \
  commandTime.start(); \
  command = QString("%1(%2)").arg(command, args.join(",")); \
  logCommand(&commandTime, command);

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
  emit OMSProxy::instance()->emitLogGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                           QString(message), Helper::scriptingKind, level));

//  qDebug() << "loggingCallback" << type << message;
}

void simulateCallback(const char* ident, double time, oms_status_enu_t status)
{
//  qDebug() << "simulateCallback" << ident << time << status;
  QList<OMSSimulationOutputWidget*> OMSSimulationOutputWidgetList;
  OMSSimulationOutputWidgetList = MainWindow::instance()->getOMSSimulationDialog()->getOMSSimulationOutputWidgetsList();
  foreach (OMSSimulationOutputWidget *pOMSSimulationOutputWidget, OMSSimulationOutputWidgetList) {
    if (pOMSSimulationOutputWidget->isSimulationRunning()
        && pOMSSimulationOutputWidget->getOMSSimulationOptions().getModelName().compare(QString(ident)) == 0) {
      pOMSSimulationOutputWidget->simulateCallback(ident, time, status);
      break;
    }
  }
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
  oms3_setLoggingCallback(0);
  mpInstance->deleteLater();
}

/*!
 * \brief OMSProxy::OMSProxy
 */
OMSProxy::OMSProxy()
{
  /* create a file to write OMSimulator communication log */
  QString communicationLogFilePath = QString("%1omscommunication.log").arg(Utilities::tempDirectory());
  mpCommunicationLogFile = fopen(communicationLogFilePath.toStdString().c_str(), "w");
  mTotalOMSCallsTime = 0.0;
  // OMSimulator global settings
  setCommandLineOption("--suppressPath=true");
  setLogFile(QString(Utilities::tempDirectory() + "/omslog.txt").toStdString().c_str());
  setTempDirectory(Utilities::tempDirectory().toStdString().c_str());
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
 * \param commandTime - the command start time
 */
void OMSProxy::logCommand(QTime *commandTime, QString command)
{
  // write the log to communication log file
  if (mpCommunicationLogFile) {
    fputs(QString("%1 %2\n").arg(command, commandTime->currentTime().toString("hh:mm:ss:zzz")).toStdString().c_str(), mpCommunicationLogFile);
  }
}

/*!
 * \brief OMSProxy::logResponse
 * Writes the response to the omscommunication.log file.
 * \param response - the response to write
 * \param status - execution status of the command
 * \param responseTime - the response end time
 */
void OMSProxy::logResponse(QString command, oms_status_enu_t status, QTime *responseTime)
{
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
    fputs(QString("%1 %2\n").arg(status).arg(responseTime->currentTime().toString("hh:mm:ss:zzz")).toStdString().c_str(), mpCommunicationLogFile);
    mTotalOMSCallsTime += (double)responseTime->elapsed() / 1000;
    fputs(QString("#s#; %1; %2; \'%3\'\n\n").arg(QString::number((double)responseTime->elapsed() / 1000)).arg(QString::number(mTotalOMSCallsTime)).arg(firstLine).toStdString().c_str(),  mpCommunicationLogFile);
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
  QString command = "oms3_addBus";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_addBus(cref.toStdString().c_str());
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
  QString command = "oms3_addConnection";
  QStringList args;
  args << "\"" + crefA + "\"" << "\"" + crefB + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_addConnection(crefA.toStdString().c_str(), crefB.toStdString().c_str());
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
  QString command = "oms3_addConnector";
  QStringList args;
  args << "\"" + cref + "\"" << QString::number(causality) << QString::number(type);
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_addConnector(cref.toStdString().c_str(), causality, type);
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
  QString command = "oms3_addConnectorToBus";
  QStringList args;
  args << busCref << connectorCref;
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_addConnectorToBus(busCref.toStdString().c_str(), connectorCref.toStdString().c_str());
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
  QString command = "oms3_addConnectorToTLMBus";
  QStringList args;
  args << busCref << connectorCref << type;
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_addConnectorToTLMBus(busCref.toStdString().c_str(), connectorCref.toStdString().c_str(),
                                                      type.toStdString().c_str());
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
  QString command = "oms3_addSubModel";
  QStringList args;
  args << "\"" + cref + "\"" << fmuPath;
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_addSubModel(cref.toStdString().c_str(), fmuPath.toStdString().c_str());
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
  QString command = "oms3_addSystem";
  QStringList args;
  args << "\"" + cref + "\"" << QString::number(type);
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_addSystem(cref.toStdString().c_str(), type);
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
  QString command = "oms3_addTLMBus";
  QStringList args;
  args << "\"" + cref + "\"" << QString::number(domain) << QString::number(dimensions) << QString::number(interpolation);
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_addTLMBus(cref.toStdString().c_str(), domain, dimensions, interpolation);
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
  QString command = "oms3_addTLMConnection";
  QStringList args;
  args << "\"" + crefA + "\"" << "\"" + crefB + "\"" << QString::number(delay) << QString::number(alpha)
       << QString::number(linearimpedance) << QString::number(angularimpedance);
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_addTLMConnection(crefA.toStdString().c_str(), crefB.toStdString().c_str(), delay, alpha,
                                                  linearimpedance, angularimpedance);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::cancelSimulation_asynchronous
 * Cancels the current model asynchronous simulation.
 * \param cref
 * \return
 */
bool OMSProxy::cancelSimulation_asynchronous(QString cref)
{
  QString command = "oms3_cancelSimulation_asynchronous";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_cancelSimulation_asynchronous(cref.toStdString().c_str());
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
  QString command = "oms3_deleteConnection";
  QStringList args;
  args << "\"" + crefA + "\"" << "\"" + crefB + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_deleteConnection(crefA.toStdString().c_str(), crefB.toStdString().c_str());
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
  QString command = "oms3_deleteConnectorFromBus";
  QStringList args;
  args << busCref << connectorCref;
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_deleteConnectorFromBus(busCref.toStdString().c_str(), connectorCref.toStdString().c_str());
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
  QString command = "oms3_deleteConnectorFromTLMBus";
  QStringList args;
  args << busCref << connectorCref;
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_deleteConnectorFromTLMBus(busCref.toStdString().c_str(), connectorCref.toStdString().c_str());
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
  QString command = "oms3_getBoolean";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_getBoolean(cref.toStdString().c_str(), value);
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
bool OMSProxy::getBus(QString cref, oms3_busconnector_t **pBusConnector)
{
  QString command = "oms3_getBus";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_getBus(cref.toStdString().c_str(), pBusConnector);
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
  QString command = "oms3_getComponentType";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_getComponentType(cref.toStdString().c_str(), pType);
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
bool OMSProxy::getConnections(QString cref, oms3_connection_t*** pConnections)
{
  QString command = "oms3_getConnections";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_getConnections(cref.toStdString().c_str(), pConnections);
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
  QString command = "oms3_getConnector";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_getConnector(cref.toStdString().c_str(), pConnector);
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
bool OMSProxy::getElement(QString cref, oms3_element_t** pElement)
{
  QString command = "oms3_getElement";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_getElement(cref.toStdString().c_str(), pElement);
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
bool OMSProxy::getElements(QString cref, oms3_element_t*** pElements)
{
  QString command = "oms3_getElements";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_getElements(cref.toStdString().c_str(), pElements);
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
  QString command = "oms3_getFMUInfo";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_getFMUInfo(cref.toStdString().c_str(), pFmuInfo);
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
  QString command = "oms3_getInteger";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_getInteger(cref.toStdString().c_str(), value);
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
  QString command = "oms3_getReal";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_getReal(cref.toStdString().c_str(), value);
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
  QString command = "oms3_getStartTime";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_getStartTime(cref.toStdString().c_str(), startTime);
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
  QString command = "oms3_getStopTime";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_getStopTime(cref.toStdString().c_str(), stopTime);
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
  QString command = "oms3_getSubModelPath";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  char* path = NULL;
  oms_status_enu_t status = oms3_getSubModelPath(cref.toStdString().c_str(), &path);
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
  QString command = "oms3_getSystemType";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_getSystemType(cref.toStdString().c_str(), pType);
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
bool OMSProxy::getTLMBus(QString cref, oms3_tlmbusconnector_t **pTLMBusConnector)
{
  QString command = "oms3_getTLMBus";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_getTLMBus(cref.toStdString().c_str(), pTLMBusConnector);
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
  QString command = "oms3_getTLMVariableTypes";
  QStringList args;
  args << QString::number(domain) << QString::number(dimensions) << QString::number(interpolation);
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_getTLMVariableTypes(domain, dimensions, interpolation, types, descriptions);
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
  QString command = "oms3_instantiate";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_instantiate(cref.toStdString().c_str());
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
  QString command = "oms3_initialize";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_initialize(cref.toStdString().c_str());
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::list
 * Lists the contents of a model.
 * Since memory is allocated so we need to call free.
 * \param cref
 * \param pContents
 * \return
 */
bool OMSProxy::list(QString cref, QString *pContents)
{
  QString command = "oms3_list";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  char* contents = NULL;
  oms_status_enu_t status = oms3_list(cref.toStdString().c_str(), &contents);
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
  QString command = "oms3_import";
  QStringList args;
  args << filename;
  LOG_COMMAND(command, args);
  char* cref = NULL;
  oms_status_enu_t status = oms3_import(filename.toStdString().c_str(), &cref);
  *pModelName = QString(cref);
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
  QString command = "oms3_newModel";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_newModel(cref.toStdString().c_str());
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
  oms_status_enu_t status = oms3_delete(cref.toStdString().c_str());
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
  QString command = "oms3_export";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_export(cref.toStdString().c_str(), filename.toStdString().c_str());
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
  QString command = "oms3_setBoolean";
  QStringList args;
  args << "\"" + cref + "\"" << (value ? "true" : "false");
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_setBoolean(cref.toStdString().c_str(), value);
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
  QString command = "oms3_setBusGeometry";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_setBusGeometry(cref.toStdString().c_str(), pGeometry);
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
  QString command = "oms3_setCommandLineOption";
  QStringList args;
  args << cmd;
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_setCommandLineOption(cmd.toStdString().c_str());
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
  QString command = "oms3_setConnectionGeometry";
  QStringList args;
  args << "\"" + crefA + "\"" << "\"" + crefB + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_setConnectionGeometry(crefA.toStdString().c_str(), crefB.toStdString().c_str(), pGeometry);
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
  QString command = "oms3_setConnectorGeometry";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_setConnectorGeometry(cref.toStdString().c_str(), pGeometry);
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
  QString command = "oms3_setFixedStepSize";
  QStringList args;
  args << "\"" + cref + "\"" << QString::number(stepSize);
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_setFixedStepSize(cref.toStdString().c_str(), stepSize);
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
  QString command = "oms3_setElementGeometry";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_setElementGeometry(cref.toStdString().c_str(), pGeometry);
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
  QString command = "oms3_setLogFile";
  QStringList args;
  args << "\"" + filename + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_setLogFile(filename.toStdString().c_str());
  logResponse(command, status, &commandTime);
}

/*!
 * \brief OMSProxy::setLoggingCallback
 * Sets the logging callback.
 */
void OMSProxy::setLoggingCallback()
{
  QString command = "oms3_setLoggingCallback";
  QStringList args;
  LOG_COMMAND(command, args);
  oms3_setLoggingCallback(loggingCallback);
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
  QString command = "oms3_setLoggingInterval";
  QStringList args;
  args << "\"" + cref + "\"" << QString::number(loggingInterval);
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_setLoggingInterval(cref.toStdString().c_str(), loggingInterval);
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
  QString command = "oms3_setLoggingLevel";
  QStringList args;
  args << QString::number(logLevel);
  LOG_COMMAND(command, args);
  oms3_setLoggingLevel(logLevel);
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
  QString command = "oms3_setInteger";
  QStringList args;
  args << "\"" + cref + "\"" << QString::number(value);
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_setInteger(cref.toStdString().c_str(), value);
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
  QString command = "oms3_setReal";
  QStringList args;
  args << "\"" + cref + "\"" << QString::number(value);
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_setReal(cref.toStdString().c_str(), value);
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
  QString command = "oms3_setResultFile";
  QStringList args;
  args << "\"" + cref + "\"" << "\"" + filename + "\"" << QString::number(bufferSize);
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_setResultFile(cref.toStdString().c_str(), filename.toStdString().c_str(), bufferSize);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::setSignalFilter
 * Sets the signal filter.
 * \param cref
 * \param regex
 * \return
 */
bool OMSProxy::setSignalFilter(QString cref, QString regex)
{
  QString command = "oms3_setSignalFilter";
  QStringList args;
  args << "\"" + cref + "\"" << "\"" + regex + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_setSignalFilter(cref.toStdString().c_str(), regex.toStdString().c_str());
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
  QString command = "oms3_setStartTime";
  QStringList args;
  args << "\"" + cref + "\"" << QString::number(startTime);
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_setStartTime(cref.toStdString().c_str(), startTime);
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
  QString command = "oms3_setStopTime";
  QStringList args;
  args << "\"" + cref + "\"" << QString::number(stopTime);
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_setStopTime(cref.toStdString().c_str(), stopTime);
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
  QString command = "oms3_setTempDirectory";
  QStringList args;
  args << "\"" + path + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_setTempDirectory(path.toStdString().c_str());
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
  QString command = "oms3_setTLMBusGeometry";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_setTLMBusGeometry(cref.toStdString().c_str(), pGeometry);
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
bool OMSProxy::setTLMConnectionParameters(QString crefA, QString crefB, const oms3_tlm_connection_parameters_t *pParameters)
{
  QString command = "oms3_setTLMConnectionParameters";
  QStringList args;
  args << "\"" + crefA + "\"" << "\"" + crefB + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_setTLMConnectionParameters(crefA.toStdString().c_str(), crefB.toStdString().c_str(), pParameters);
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
  QString command = "oms3_setTLMSocketData";
  QStringList args;
  args << "\"" + cref + "\"" << address << QString::number(managerPort) << QString::number(monitorPort);
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_setTLMSocketData(cref.toStdString().c_str(), address.toStdString().c_str(), managerPort, monitorPort);
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
bool OMSProxy::setTolerance(QString cref, double tolerance)
{
  QString command = "oms3_setTolerance";
  QStringList args;
  args << "\"" + cref + "\"" << QString::number(tolerance);
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_setTolerance(cref.toStdString().c_str(), tolerance);
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
  QString command = "oms3_setWorkingDirectory";
  QStringList args;
  args << "\"" + path + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_setWorkingDirectory(path.toStdString().c_str());
  logResponse(command, status, &commandTime);
}

/*!
 * \brief OMSProxy::simulate_asynchronous
 * Starts the asynchronous simulation.
 * \param cref
 * \return
 */
bool OMSProxy::simulate_asynchronous(QString cref)
{
  QString command = "oms3_simulate_asynchronous";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_simulate_asynchronous(cref.toStdString().c_str(), simulateCallback);
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::terminate
 * Terminates the model.
 * \param cref
 * \return
 */
bool OMSProxy::terminate(QString cref)
{
  QString command = "oms3_terminate";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  oms_status_enu_t status = oms3_terminate(cref.toStdString().c_str());
  logResponse(command, status, &commandTime);
  return statusToBool(status);
}




/*!
 * \brief OMSProxy::addFMU
 * Adds the FMU to the model
 * \param modelIdent
 * \param fmuPath
 * \param fmuIdent
 * \return
 */
bool OMSProxy::addFMU(QString modelIdent, QString fmuPath, QString fmuIdent)
{
  oms_status_enu_t status = oms2_addFMU(modelIdent.toStdString().c_str(), fmuPath.toStdString().c_str(), fmuIdent.toStdString().c_str());
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::addTable
 * Adds the table to the model
 * \param modelIdent
 * \param fmuPath
 * \param fmuIdent
 * \return
 */
bool OMSProxy::addTable(QString modelIdent, QString tablePath, QString tableIdent)
{
  oms_status_enu_t status = oms2_addTable(modelIdent.toStdString().c_str(), tablePath.toStdString().c_str(), tableIdent.toStdString().c_str());
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::deleteSubModel
 * Deletes the submodel from the model
 * \param modelIdent
 * \param subModelIdent
 * \return
 */
bool OMSProxy::deleteSubModel(QString modelIdent, QString subModelIdent)
{
  oms_status_enu_t status = oms2_deleteSubModel(modelIdent.toStdString().c_str(), subModelIdent.toStdString().c_str());
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::renameModel
 * Renames a model or a FMU.
 * \param identOld
 * \param identNew
 * \return
 */
bool OMSProxy::rename(QString identOld, QString identNew)
{
  oms_status_enu_t status = oms2_rename(identOld.toStdString().c_str(), identNew.toStdString().c_str());
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::parseString
 * Parses a model string and returns a model name.
 * \param contents
 * \param pModelName
 * \return
 */
bool OMSProxy::parseString(QString contents, QString *pModelName)
{
  char* ident = NULL;
  oms_status_enu_t status = oms2_parseString(contents.toStdString().c_str(), &ident);
  if (ident) {
    *pModelName = QString(ident);
    free(ident);
  }
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::loadString
 * Loads the model from a string.
 * \param contents
 * \param pModelName
 * \return
 */
bool OMSProxy::loadString(QString contents, QString* pModelName)
{
  char* ident = NULL;
  oms_status_enu_t status = oms2_loadString(contents.toStdString().c_str(), &ident);
  *pModelName = QString(ident);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::setMasterAlgorithm
 * Set master algorithm variant that shall be used (default: "standard").
 *
 * Supported master algorithms: "standard"
 *
 * Experimental master algorithms (no stable API!): "pctpl", "pmrchannela", "pmrchannelcv", "pmrchannelm"
 *
 * \param cref
 * \param masterAlgorithm
 * \return
 */
bool OMSProxy::setMasterAlgorithm(QString cref, QString masterAlgorithm)
{
  oms_status_enu_t status = oms2_setMasterAlgorithm(cref.toStdString().c_str(), masterAlgorithm.toStdString().c_str());
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::exists
 * This function returns 1 if a given cref exists in the scope,
 * otherwise 0. It can be used to check for models, sub-models such
 * as FMUs, and solver instances.
 * \param cref
 * \return
 */
bool OMSProxy::exists(QString cref)
{
  return oms2_exists(cref.toStdString().c_str());
}

/*!
 * \brief OMSProxy::reset
 * Reset the model after a simulation run.
 * \param ident
 * \return
 */
bool OMSProxy::reset(QString ident)
{
  oms_status_enu_t status = oms2_reset(ident.toStdString().c_str());
  return statusToBool(status);
}
