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
#include "Modeling/MessagesWidget.h"
#include "MainWindow.h"
#include "OMSSimulationDialog.h"
#include "OMSSimulationOutputWidget.h"
#include "Util/Utilities.h"

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
  MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                        QString(message), Helper::scriptingKind, level));
//  qDebug() << type << message;
}

void simulateCallback(const char* ident, double time, oms_status_enu_t status)
{
  //qDebug() << "simulateCallback" << ident << time << status;
  QList<OMSSimulationOutputWidget*> OMSSimulationOutputWidgetList;
  OMSSimulationOutputWidgetList = MainWindow::instance()->getOMSSimulationDialog()->getOMSSimulationOutputWidgetsList();
  foreach (OMSSimulationOutputWidget *pOMSSimulationOutputWidget, OMSSimulationOutputWidgetList) {
    if (pOMSSimulationOutputWidget->isSimulationRunning()
        && pOMSSimulationOutputWidget->getOMSSimulationOptions().getCompositeModelName().compare(QString(ident)) == 0) {
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
  oms2_setLoggingCallback(0);
  mpInstance->deleteLater();
}

/*!
 * \brief OMSProxy::OMSProxy
 */
OMSProxy::OMSProxy()
{
  // OMSimulator global settings
  setLogFile(QString(Utilities::tempDirectory() + "/omsllog.txt").toStdString().c_str());
  setTempDirectory(Utilities::tempDirectory().toStdString().c_str());
  oms2_setLoggingCallback(loggingCallback);
}

/*!
 * \brief OMSProxy::getElementTypeString
 * Returns the oms_element_type_enu_t as string.
 * \param type
 * \return
 */
QString OMSProxy::getElementTypeString(oms_element_type_enu_t type)
{
  switch (type) {
    case oms_component_tlm:
      return "TLM model";
    case oms_component_fmi:
      return "FMI model";
    case oms_component_fmu_old:
      return "FMU";
    case oms_component_table_old:
      return "Table";
    case oms_component_port:
      return "Port";
    case oms_component_none_old:
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
 * \brief OMSProxy::newFMIModel
 * Creates a new FMI model.
 * \param ident
 * \return
 */
bool OMSProxy::newFMIModel(QString ident)
{
  oms_status_enu_t status = oms2_newFMIModel(ident.toStdString().c_str());
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::newTLMModel
 * Creates a new TLM model.
 * \param ident
 * \return
 */
bool OMSProxy::newTLMModel(QString ident)
{
  oms_status_enu_t status = oms2_newTLMModel(ident.toStdString().c_str());
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::unloadModel
 * Unloads the model.
 * \param ident
 * \return
 */
bool OMSProxy::unloadModel(QString ident)
{
  oms_status_enu_t status = oms2_unloadModel(ident.toStdString().c_str());
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
 * \brief OMSProxy::loadModel
 * Loads the model.
 * \param filename
 * \param pModelName
 * \return
 */
bool OMSProxy::loadModel(QString filename, QString* pModelName)
{
  char* ident = NULL;
  oms_status_enu_t status = oms2_loadModel(filename.toStdString().c_str(), &ident);
  *pModelName = QString(ident);
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
 * \brief OMSProxy::saveModel
 * Saves the model.
 * \param ident
 * \param filename
 * \return
 */
bool OMSProxy::saveModel(QString ident, QString filename)
{
  oms_status_enu_t status = oms2_saveModel(ident.toStdString().c_str(), filename.toStdString().c_str());
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::listModel
 * Lists the contents of a composite model.
 * Since memory is allocated in oms2_listModel so we need to call free.
 * \param ident
 * \param pContents
 * \return
 */
bool OMSProxy::listModel(QString ident, QString *pContents)
{
  char* contents = NULL;
  oms_status_enu_t status = oms2_listModel(ident.toStdString().c_str(), &contents);
  if (contents) {
    *pContents = QString(contents);
    free(contents);
  }
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
  oms_status_enu_t status = oms2_getElement(cref.toStdString().c_str(), pElement);
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
  oms_status_enu_t status = oms2_setElementGeometry(cref.toStdString().c_str(), pGeometry);
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
  oms_status_enu_t status = oms2_getElements(cref.toStdString().c_str(), pElements);
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
  char* path = NULL;
  oms_status_enu_t status = oms2_getSubModelPath(cref.toStdString().c_str(), &path);
  *pPath = QString(path);
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
  oms_status_enu_t status = oms2_getFMUInfo(cref.toStdString().c_str(), pFmuInfo);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::setConnectorGeometry
 * Sets the connector geometry.
 * \param connector
 * \param pGeometry
 * \return
 */
bool OMSProxy::setConnectorGeometry(QString connector, const ssd_connector_geometry_t* pGeometry)
{
  oms_status_enu_t status = oms2_setConnectorGeometry(connector.toStdString().c_str(), pGeometry);
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
  oms_status_enu_t status = oms2_getConnections(cref.toStdString().c_str(), pConnections);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::addConnection
 * Adds the connection
 * \param cref
 * \param conA
 * \param conB
 * \return
 */
bool OMSProxy::addConnection(QString cref, QString conA, QString conB)
{
  oms_status_enu_t status = oms2_addConnection(cref.toStdString().c_str(), conA.toStdString().c_str(), conB.toStdString().c_str());
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::deleteConnection
 * Deletes the connection
 * \param cref
 * \param conA
 * \param conB
 * \return
 */
bool OMSProxy::deleteConnection(QString cref, QString conA, QString conB)
{
  oms_status_enu_t status = oms2_deleteConnection(cref.toStdString().c_str(), conA.toStdString().c_str(), conB.toStdString().c_str());
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::updateConnection
 * Updates the connection
 * \param cref
 * \param conA
 * \param conB
 * \param pConnection
 * \return
 */
bool OMSProxy::updateConnection(QString cref, QString conA, QString conB, const oms_connection_t* pConnection)
{
  oms_status_enu_t status = oms2_updateConnection(cref.toStdString().c_str(), conA.toStdString().c_str(),
                                                  conB.toStdString().c_str(), pConnection);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::initialize
 * Initializes a composite model (works for both FMI and TLM).
 * \param ident
 * \return
 */
bool OMSProxy::initialize(QString ident)
{
  oms_status_enu_t status = oms2_initialize(ident.toStdString().c_str());
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::simulate_asynchronous
 * Starts the asynchronous simulation.
 * \param ident
 * \param terminate
 * \return
 */
bool OMSProxy::simulate_asynchronous(QString ident/*, int* terminate*/)
{
  oms_status_enu_t status = oms2_simulate_asynchronous(ident.toStdString().c_str(), /*terminate,*/ simulateCallback);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::reset
 * Reset the composite model after a simulation run.
 * \param ident
 * \return
 */
bool OMSProxy::reset(QString ident)
{
  oms_status_enu_t status = oms2_reset(ident.toStdString().c_str());
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::setDebugLogging
 * Sets the logging level.
 * \param logLevel
 */
void OMSProxy::setLoggingLevel(int logLevel)
{
  oms2_setLoggingLevel(logLevel);
}

/*!
 * \brief OMSProxy::setLogFile
 * Sets the log file.
 * \param filename
 */
void OMSProxy::setLogFile(QString filename)
{
  oms2_setLogFile(filename.toStdString().c_str());
}

/*!
 * \brief OMSProxy::setTempDirectory
 * Sets the temp directory.
 * \param path
 */
void OMSProxy::setTempDirectory(QString path)
{
  oms2_setTempDirectory(path.toStdString().c_str());
}

/*!
 * \brief OMSProxy::setWorkingDirectory
 * Sets the working directory.
 * \param path
 */
void OMSProxy::setWorkingDirectory(QString path)
{
  oms2_setWorkingDirectory(path.toStdString().c_str());
}

/*!
 * \brief OMSProxy::getReal
 * Gets the real variable value.
 * \param signal
 * \param value
 * \return
 */
bool OMSProxy::getReal(QString signal, double *value)
{
  oms_status_enu_t status = oms2_getReal(signal.toStdString().c_str(), value);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::setReal
 * Sets the real variable value.
 * \param signal
 * \param value
 * \return
 */
bool OMSProxy::setReal(QString signal, double value)
{
  oms_status_enu_t status = oms2_setReal(signal.toStdString().c_str(), value);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::getRealParameter
 * Gets the real parameter value.
 * \param signal
 * \param pValue
 * \return
 */
bool OMSProxy::getRealParameter(QString signal, double* pValue)
{
  oms_status_enu_t status = oms2_getRealParameter(signal.toStdString().c_str(), pValue);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::setRealParameter
 * Sets the real parameter value.
 * \param signal
 * \param value
 * \return
 */
bool OMSProxy::setRealParameter(const char* signal, double value)
{
  oms_status_enu_t status = oms2_setRealParameter(signal, value);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::getInteger
 * Gets the integer variable value.
 * \param signal
 * \param value
 * \return
 */
bool OMSProxy::getInteger(QString signal, int *value)
{
  oms_status_enu_t status = oms2_getInteger(signal.toStdString().c_str(), value);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::setInteger
 * Sets the integer variable value.
 * \param signal
 * \param value
 * \return
 */
bool OMSProxy::setInteger(QString signal, int value)
{
  oms_status_enu_t status = oms2_setInteger(signal.toStdString().c_str(), value);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::getIntegerParameter
 * Gets the integer parameter value.
 * \param signal
 * \param pValue
 * \return
 */
bool OMSProxy::getIntegerParameter(QString signal, int* pValue)
{
  oms_status_enu_t status = oms2_getIntegerParameter(signal.toStdString().c_str(), pValue);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::setIntegerParameter
 * Sets the integer parameter value.
 * \param signal
 * \param value
 * \return
 */
bool OMSProxy::setIntegerParameter(const char* signal, int value)
{
  oms_status_enu_t status = oms2_setIntegerParameter(signal, value);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::getBoolean
 * Gets the boolean variable value.
 * \param signal
 * \param value
 * \return
 */
bool OMSProxy::getBoolean(QString signal, bool *value)
{
  oms_status_enu_t status = oms2_getBoolean(signal.toStdString().c_str(), value);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::setBoolean
 * Sets the boolean variable value.
 * \param signal
 * \param value
 * \return
 */
bool OMSProxy::setBoolean(QString signal, bool value)
{
  oms_status_enu_t status = oms2_setBoolean(signal.toStdString().c_str(), value);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::getBooleanParameter
 * Gets the boolean parameter value.
 * \param signal
 * \param pValue
 * \return
 */
bool OMSProxy::getBooleanParameter(QString signal, bool* pValue)
{
  oms_status_enu_t status = oms2_getBooleanParameter(signal.toStdString().c_str(), pValue);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::setBooleanParameter
 * Sets the boolean parameter value.
 * \param signal
 * \param value
 * \return
 */
bool OMSProxy::setBooleanParameter(const char* signal, bool value)
{
  oms_status_enu_t status = oms2_setBooleanParameter(signal, value);
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
  oms_status_enu_t status = oms2_getStartTime(cref.toStdString().c_str(), startTime);
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
  oms_status_enu_t status = oms2_setStartTime(cref.toStdString().c_str(), startTime);
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
  oms_status_enu_t status = oms2_getStopTime(cref.toStdString().c_str(), stopTime);
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
  oms_status_enu_t status = oms2_setStopTime(cref.toStdString().c_str(), stopTime);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::setCommunicationInterval
 * Set the communication interval of the simulation.
 * \param cref
 * \param communicationInterval
 * \return
 */
bool OMSProxy::setCommunicationInterval(QString cref, double communicationInterval)
{
  oms_status_enu_t status = oms2_setCommunicationInterval(cref.toStdString().c_str(), communicationInterval);
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::setResultFile
 * Set the result file of the simulation.
 * \param cref
 * \param filename
 * \return
 */
bool OMSProxy::setResultFile(QString cref, QString filename)
{
  oms_status_enu_t status = oms2_setResultFile(cref.toStdString().c_str(), filename.toStdString().c_str(), 1);
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
 * otherwise 0. It can be used to check for composite models, sub-models such
 * as FMUs, and solver instances.
 * \param cref
 * \return
 */
bool OMSProxy::exists(QString cref)
{
  return oms2_exists(cref.toStdString().c_str());
}
