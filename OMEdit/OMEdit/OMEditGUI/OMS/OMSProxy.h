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
#include "Modeling/MessagesWidget.h"

#include <QObject>
#include <QTime>

class OMSProxy : public QObject
{
  Q_OBJECT
private:
  // the only class that is allowed to create and destroy
  friend class MainWindow;

  static void create();
  static void destroy();
  OMSProxy();
  ~OMSProxy();

  static OMSProxy *mpInstance;

  FILE *mpCommunicationLogFile;
  double mTotalOMSCallsTime;

  void logCommand(QTime *commandTime, QString command);
  void logResponse(QString command, oms_status_enu_t status, QTime *responseTime);
public:
  static OMSProxy* instance() {return mpInstance;}

  static QString getSystemTypeString(oms_system_enu_t type);
  static QString getSystemTypeShortString(oms_system_enu_t type);
  static QString getFMUKindString(oms_fmi_kind_enu_t kind);
  static QString getSignalTypeString(oms_signal_type_enu_t type);
  static QString getCausalityString(oms_causality_enu_t causality);
  static QString getInterpolationString(oms_tlm_interpolation_t interpolation);

  bool statusToBool(oms_status_enu_t status);
  void emitLogGUIMessage(MessageItem messageItem) {emit logGUIMessage(messageItem);}

  bool addBus(QString cref);
  bool addConnection(QString crefA, QString crefB);
  bool addConnector(QString cref, oms_causality_enu_t causality, oms_signal_type_enu_t type);
  bool addConnectorToBus(QString busCref, QString connectorCref);
  bool addConnectorToTLMBus(QString busCref, QString connectorCref, QString type);
  bool addSubModel(QString cref, QString fmuPath);
  bool addSystem(QString cref, oms_system_enu_t type);
  bool addTLMBus(QString cref, oms_tlm_domain_t domain, int dimensions, const oms_tlm_interpolation_t interpolation);
  bool addTLMConnection(QString crefA, QString crefB, double delay, double alpha, double linearimpedance, double angularimpedance);
  bool cancelSimulation_asynchronous(QString cref);
  bool deleteConnection(QString crefA, QString crefB);
  bool deleteConnectorFromBus(QString busCref, QString connectorCref);
  bool deleteConnectorFromTLMBus(QString busCref, QString connectorCref);
  bool getBoolean(QString signal, bool* value);
  bool getBus(QString cref, oms_busconnector_t **pBusConnector);
  bool getComponentType(QString cref, oms_component_enu_t *pType);
  bool getConnections(QString cref, oms_connection_t ***pConnections);
  bool getConnector(QString cref, oms_connector_t **pConnector);
  bool getElement(QString cref, oms_element_t **pElement);
  bool getElements(QString cref, oms_element_t ***pElements);
  bool getFixedStepSize(QString cref, double* stepSize);
  bool getFMUInfo(QString cref, const oms_fmu_info_t** pFmuInfo);
  bool getInteger(QString signal, int* value);
  bool getReal(QString cref, double* value);
  bool getSolver(QString cref, oms_solver_enu_t* solver);
  bool getStartTime(QString cref, double* startTime);
  bool getStopTime(QString cref, double* stopTime);
  bool getSubModelPath(QString cref, QString* pPath);
  bool getSystemType(QString cref, oms_system_enu_t *pType);
  bool getTLMBus(QString cref, oms_tlmbusconnector_t **pTLMBusConnector);
  bool getTLMVariableTypes(oms_tlm_domain_t domain, const int dimensions, const oms_tlm_interpolation_t interpolation,
                           char ***types, char ***descriptions);
  bool getTolerance(QString cref, double* absoluteTolerance, double* relativeTolerance);
  bool getVariableStepSize(QString cref, double* initialStepSize, double* minimumStepSize, double* maximumStepSize);
  bool instantiate(QString cref);
  bool initialize(QString cref);
  bool list(QString cref, QString *pContents);
  bool loadModel(QString filename, QString* pModelName);
  bool newModel(QString cref);
  bool omsDelete(QString cref);
  bool saveModel(QString cref, QString filename);
  bool setBoolean(QString signal, bool value);
  bool setBusGeometry(QString cref, const ssd_connector_geometry_t* pGeometry);
  bool setCommandLineOption(QString cmd);
  bool setConnectionGeometry(QString crefA, QString crefB, const ssd_connection_geometry_t *pGeometry);
  bool setConnectorGeometry(QString cref, const ssd_connector_geometry_t* pGeometry);
  bool setElementGeometry(QString cref, const ssd_element_geometry_t* pGeometry);
  bool setFixedStepSize(QString cref, double stepSize);
  void setLogFile(QString filename);
  void setLoggingCallback();
  bool setLoggingInterval(QString cref, double loggingInterval);
  void setLoggingLevel(int logLevel);
  bool setInteger(QString signal, int value);
  bool setReal(QString cref, double value);
  bool setResultFile(QString cref, QString filename, int bufferSize);
  bool setSignalFilter(QString cref, QString regex);
  bool setSolver(QString cref, oms_solver_enu_t solver);
  bool setStartTime(QString cref, double startTime);
  bool setStopTime(QString cref, double stopTime);
  void setTempDirectory(QString path);
  bool setTLMBusGeometry(QString cref, const ssd_connector_geometry_t* pGeometry);
  bool setTLMConnectionParameters(QString crefA, QString crefB, const oms_tlm_connection_parameters_t *pParameters);
  bool setTLMSocketData(QString cref, QString address, int managerPort, int monitorPort);
  bool setTolerance(QString cref, double absoluteTolerance, double relativeTolerance);
  bool setVariableStepSize(QString cref, double initialStepSize, double minimumStepSize, double maximumStepSize);
  void setWorkingDirectory(QString path);
  bool simulate_asynchronous(QString cref);
  bool terminate(QString cref);

  bool parseString(QString contents, QString* pModelName);
  bool loadString(QString contents, QString* pModelName);
signals:
  void logGUIMessage(MessageItem messageItem);
};

#endif // OMSPROXY_H
