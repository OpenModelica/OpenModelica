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
#ifndef OMSSIMULATIONPROCESSTHREAD_H
#define OMSSIMULATIONPROCESSTHREAD_H

#include "OMS/OMSSimulationOutputWidget.h"
#include "Util/StringHandler.h"

#include <QThread>

class OMSSimulationSubscriberThread : public QThread
{
  Q_OBJECT
public:
  OMSSimulationSubscriberThread(QObject *parent = 0);
  ~OMSSimulationSubscriberThread();
  void setIsFinished(bool isFinished) {mIsFinished = isFinished;}
  QString getEndPoint() const {return mEndPoint;}
  QString getBindError() const {return mBindError;}
private:
  void *mpContext;
  void *mpSubscriberSocket;
  bool mIsFinished;
  QString mEndPoint;
  QString mBindError;
protected:
  virtual void run() override;
signals:
  void sendProgressJson(QString progressJson);
};

class OMSSimulationProcessThread : public QThread
{
  Q_OBJECT
public:
  OMSSimulationProcessThread(const QString &fileName, QObject *parent = 0);
  ~OMSSimulationProcessThread();
  QProcess* getSimulationProcess() {return mpSimulationProcess;}
  void setSimulationProcessKilled(bool killed) {mIsSimulationProcessKilled = killed;}
  bool isSimulationProcessKilled() {return mIsSimulationProcessKilled;}
  bool isSimulationProcessRunning() {return mIsSimulationProcessRunning;}
protected:
  virtual void run() override;
private:
  QString mFileName;
  QProcess *mpSimulationProcess;
  bool mIsSimulationProcessKilled;
  bool mIsSimulationProcessRunning;
  OMSSimulationSubscriberThread *mpOMSSimulationSubscriberThread;
private slots:
  void simulationProcessStarted();
  void readSimulationStandardOutput();
  void readSimulationStandardError();
  void simulationProcessError(QProcess::ProcessError error);
  void simulationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
signals:
  void sendSimulationStarted();
  void sendSimulationOutput(QString, StringHandler::SimulationMessageType type, bool);
  void sendProgressJson(QString);
  void sendSimulationFinished(int, QProcess::ExitStatus);
};

#endif // OMSSIMULATIONPROCESSTHREAD_H
