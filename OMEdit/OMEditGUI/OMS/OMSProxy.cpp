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
 * \brief OMSProxy::setLogFile
 * Sets the log file.
 * \param filename
 */
void OMSProxy::setLogFile(QString filename)
{
  oms_setLogFile(filename.toStdString().c_str());
}

/*!
 * \brief OMSProxy::setTempDirectory
 * Sets the temp directory.
 * \param path
 */
void OMSProxy::setTempDirectory(QString path)
{
  oms_setTempDirectory(path.toStdString().c_str());
}

/*!
 * \brief OMSProxy::setWorkingDirectory
 * Sets the working directory.
 * \param path
 */
void OMSProxy::setWorkingDirectory(QString path)
{
  oms_setWorkingDirectory(path.toStdString().c_str());
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
 * \brief OMSProxy::setDebugLogging
 * Sets the logging level.
 * \param logLevel
 */
void OMSProxy::setLoggingLevel(int logLevel)
{
  oms2_setLoggingLevel(logLevel);
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
 * Renames the model.
 * \param identOld
 * \param identNew
 * \return
 */
bool OMSProxy::renameModel(QString identOld, QString identNew)
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
 * \brief OMSProxy::saveModel
 * Saves the model.
 * \param filename
 * \param ident
 * \return
 */
bool OMSProxy::saveModel(QString filename, QString ident)
{
  oms_status_enu_t status = oms2_saveModel(filename.toStdString().c_str(), ident.toStdString().c_str());
  return statusToBool(status);
}

/*!
 * \brief OMSProxy::getElement
 * Gets the model element
 * \param cref
 * \param element
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
 * Returns the FMU path.
 * \param cref
 * \param fmuPath
 * \return
 */
bool OMSProxy::getFMUPath(QString cref, QString* fmuPath)
{
  char* path = NULL;
  oms_status_enu_t status = oms2_getFMUPath(cref.toStdString().c_str(), &path);
  *fmuPath = QString(path);
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
 * \param connection
 * \return
 */
bool OMSProxy::updateConnection(QString cref, QString conA, QString conB, const oms_connection_t *connection)
{
  oms_status_enu_t status = oms2_updateConnection(cref.toStdString().c_str(), conA.toStdString().c_str(),
                                                  conB.toStdString().c_str(), connection);
  return statusToBool(status);
}
