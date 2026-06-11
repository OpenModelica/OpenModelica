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

#ifndef OMSPROXY_H
#define OMSPROXY_H

#include "OMSimulator/OMSimulator.h"
#include "Modeling/MessagesWidget.h"
#include "OMS/OMSModel.h"
#include <QObject>
#include <QElapsedTimer>

class GuiRequestSocket : public QObject
{
public:
  GuiRequestSocket();
  ~GuiRequestSocket();
  QString endPoint() const { return mEndPoint; }
  bool isConnected() const { return mSocketConnected; }
  bool sendCommand(const QJsonObject &obj, QJsonObject &reply);
private:
  void* mpContext;
  void* mpSocket;
  QString mEndPoint;
  bool mSocketConnected;
};

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

  void logCommand(QString command);
  void logResponse(QString command, oms_status_enu_t status, QElapsedTimer *responseTime);

  GuiRequestSocket* mpGuiRequestSocket;
  QProcess* mpGuiProcess;
  void startGuiServer();
  bool mServerReady;
private slots:
  void guiProcessStarted();
  void guiProcessError(QProcess::ProcessError error);
  void guiProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
  void readGuiServerStandardOutput();
  void readGuiServerStandardError();
public:
  static OMSProxy* instance() {return mpInstance;}

  bool statusToBool(oms_status_enu_t status);
  void emitLogGUIMessage(MessageItem messageItem) {emit logGUIMessage(messageItem);}
  bool sendZmqCommand(const QJsonObject &obj, QJsonObject &reply);

  bool addConnection(QString crefA, QString crefB, bool suppressUnitConversion = false);
  bool addConnector(QString cref, OMSModel::Causality causality, OMSModel::SignalType type);
  bool addSubModel(QString cref, QString fmuPath);
  bool replaceSubModel(QString cref, QString fmuPath, bool dryCount, int* count);
  void createElementGeometryUsingPosition(const QString &cref, QPointF position);
  bool addSystem(QString cref);
  bool deleteConnection(QString crefA, QString crefB);
  bool getBoolean(QString signal, bool &value);
  bool getElementsJson(QString cref, QJsonArray &elements);
  bool getFixedStepSize(QString cref, double& stepSize);
  bool getInteger(QString signal, int &value);
  bool getModelState(const QString &cref, oms_modelState_enu_t* modelState);
  bool getReal(QString cref, double &value);
  bool getSolverSettings(const QString &cref, QJsonObject &settings);
  bool setSolverSettings(const QString &cref, const QJsonObject &settings);
  bool setSolver(const QString &cref, const QString &solverName);
  bool getStartTime(QString cref, double& startTime);
  bool getStopTime(QString cref, double& stopTime);
  bool getSubModelPath(QString cref, QString* pPath);
  bool getTolerance(QString cref, double& relativeTolerance);
  bool getVariableStepSize(QString cref, QString solverName, double& initialStepSize, double& minimumStepSize, double& maximumStepSize);
  bool instantiate(QString cref);
  bool initialize(QString cref);
  bool exportSnapshot(QString cref, QString &pContents);
  bool loadModel(QString filename, QString &pModelName);
  bool importSnapshot(QString cref, QString snapshot, QString& pNewCref, QString& pNewRootCref);
  bool newModel(QString cref, QString systemName);
  bool rename(const QString &cref, const QString &newCref);
  bool omsDelete(QString cref);
  bool saveModel(QString cref, QString filename);
  bool setBoolean(QString signal, bool value);
  bool setCommandLineOption(QString cmd);
  bool setConnectionGeometry(QString crefA, QString crefB, const OMSModel::ConnectionGeometry &geometry);
  bool setConnectorGeometry(QString cref, const OMSModel::ConnectorGeometry &geometry);
  bool setElementGeometry(QString cref, const OMSModel::ElementGeometry &geometry);
  bool setFixedStepSize(QString cref, double stepSize);
  void setLogFile(QString filename);
  void setLoggingCallback();
  bool setLoggingInterval(QString cref, double loggingInterval);
  void setLoggingLevel(int logLevel);
  bool setInteger(QString signal, int value);
  bool setReal(QString cref, double value);
  bool setResultFile(QString cref, QString fileName, int bufferSize);
  bool getResultFile(QString cref, QString& fileName, int& bufferSize);
  // setSolver(const QString&, const QString&) declared above with getSolverSettings
  bool setStartTime(QString cref, double startTime);
  bool setStopTime(QString cref, double stopTime);
  void setTempDirectory(QString path);
  bool setTolerance(QString cref, double relativeTolerance);
  bool setVariableStepSize(QString cref, double initialStepSize, double minimumStepSize, double maximumStepSize);
  void setWorkingDirectory(QString path);
  bool terminate(QString cref);
signals:
  void logGUIMessage(MessageItem messageItem);
};

#endif // OMSPROXY_H
