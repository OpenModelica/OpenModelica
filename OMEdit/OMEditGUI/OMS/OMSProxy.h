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

#ifndef OMSPROXY_H
#define OMSPROXY_H

#include "OMSimulator.h"

#include <QObject>

class OMSProxy : public QObject
{
  Q_OBJECT
private:
  // the only class that is allowed to create and destroy
  friend class MainWindow;

  static void create();
  static void destroy();
  OMSProxy();

  static OMSProxy *mpInstance;
public:
  static OMSProxy* instance() {return mpInstance;}

  static QString getSystemTypeString(oms_system_enu_t type);
  static QString getFMUKindString(oms_fmi_kind_enu_t kind);
  static QString getSignalTypeString(oms_signal_type_enu_t type);
  static QString getCausalityString(oms_causality_enu_t causality);

  bool statusToBool(oms_status_enu_t status);

  bool newModel(QString cref);
  bool omsDelete(QString cref);
  bool addSystem(QString cref, oms_system_enu_t type);
  bool getSystemType(QString cref, oms_system_enu_t *pType);
  bool addConnector(QString cref, oms_causality_enu_t causality, oms_signal_type_enu_t type);
  bool getConnector(QString cref, oms_connector_t** pConnector);
  bool addBus(QString cref);
  bool getBus(QString cref, oms3_busconnector_t** pBusConnector);
  bool addConnectorToBus(QString busCref, QString connectorCref);
  bool addTLMBus(QString cref, QString domain, int dimensions, const oms_tlm_interpolation_t interpolation);
  bool getTLMBus(QString cref, oms3_tlmbusconnector_t** pTLMBusConnector);
  bool addConnectorToTLMBus(QString busCref, QString connectorCref, QString type);

  bool newFMIModel(QString ident);
  bool newTLMModel(QString ident);
  bool unloadModel(QString ident);
  bool addFMU(QString modelIdent, QString fmuPath, QString fmuIdent);
  bool addTable(QString modelIdent, QString tablePath, QString tableIdent);
  bool deleteSubModel(QString modelIdent, QString subModelIdent);
  bool rename(QString identOld, QString identNew);
  bool loadModel(QString filename, QString* pModelName);
  bool parseString(QString contents, QString* pModelName);
  bool loadString(QString contents, QString* pModelName);
  bool saveModel(QString cref, QString filename);
  bool list(QString ident, QString *pContents);
  bool getElement(QString cref, oms3_element_t **pElement);
  bool setElementGeometry(QString cref, const ssd_element_geometry_t* pGeometry);
  bool getElements(QString cref, oms3_element_t ***pElements);
  bool getSubModelPath(QString cref, QString* pPath);
  bool getFMUInfo(QString cref, const oms_fmu_info_t** pFmuInfo);
  bool setConnectorGeometry(QString cref, const ssd_connector_geometry_t* pGeometry);
  bool setBusGeometry(QString cref, const ssd_connector_geometry_t* pGeometry);
  bool setTLMBusGeometry(QString cref, const ssd_connector_geometry_t* pGeometry);
  bool getConnections(QString cref, oms_connection_t*** pConnections);
  bool addConnection(QString cref, QString conA, QString conB);
  bool deleteConnection(QString cref, QString conA, QString conB);
  bool updateConnection(QString cref, QString conA, QString conB, const oms_connection_t* pConnection);
  bool initialize(QString ident);
  bool simulate_asynchronous(QString ident/*, int* terminate*/);
  bool reset(QString ident);
  void setLoggingLevel(int logLevel);
  void setLogFile(QString filename);
  void setTempDirectory(QString path);
  void setWorkingDirectory(QString path);
  bool getReal(QString signal, double* value);
  bool setReal(QString signal, double value);
  bool getRealParameter(QString signal, double* pValue);
  bool setRealParameter(const char* signal, double value);
  bool getInteger(QString signal, int* value);
  bool setInteger(QString signal, int value);
  bool getIntegerParameter(QString signal, int* pValue);
  bool setIntegerParameter(const char* signal, int value);
  bool getBoolean(QString signal, bool* value);
  bool setBoolean(QString signal, bool value);
  bool getBooleanParameter(QString signal, bool* pValue);
  bool setBooleanParameter(const char* signal, bool value);
  bool getStartTime(QString cref, double* startTime);
  bool setStartTime(QString cref, double startTime);
  bool getStopTime(QString cref, double* stopTime);
  bool setStopTime(QString cref, double stopTime);
  bool setCommunicationInterval(QString cref, double communicationInterval);
  bool setResultFile(QString cref, QString filename);
  bool setMasterAlgorithm(QString cref, QString masterAlgorithm);
  bool exists(QString cref);
};

#endif // OMSPROXY_H
