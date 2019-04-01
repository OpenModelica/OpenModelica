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

#ifndef TLMCOSIMULATIONTHREAD_H
#define TLMCOSIMULATIONTHREAD_H

#include "TLMCoSimulationOutputWidget.h"

#include <QThread>

class TLMCoSimulationOutputWidget;
class TLMCoSimulationThread : public QThread
{
  Q_OBJECT
public:
  TLMCoSimulationThread(TLMCoSimulationOutputWidget *pTLMCoSimulationOutputWidget);
  QProcess* getManagerProcess() {return mpManagerProcess;}
  void setIsManagerProcessRunning(bool isManagerProcessRunning) {mIsManagerProcessRunning = isManagerProcessRunning;}
  bool isManagerProcessRunning() {return mIsManagerProcessRunning;}
  QProcess* getMonitorProcess() {return mpMonitorProcess;}
  void setIsMonitorProcessRunning(bool isMonitorProcessRunning) {mIsMonitorProcessRunning = isMonitorProcessRunning;}
  bool isMonitorProcessRunning() {return mIsMonitorProcessRunning;}
protected:
  virtual void run();
private:
  QString mFileName;
  TLMCoSimulationOutputWidget *mpTLMCoSimulationOutputWidget;
  QProcess *mpManagerProcess;
  qint64 mManagerProcessId;
  bool mIsManagerProcessRunning;
  QProcess *mpMonitorProcess;
  bool mIsMonitorProcessRunning;
  QFile mProgressFile;
  QTimer *mpProgressFileTimer;

  void removeGeneratedFiles();
  void runManager();
  void runMonitor();
private slots:
  void managerProcessStarted();
  void readManagerStandardOutput();
  void readManagerStandardError();
  void managerProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
  void monitorProcessStarted();
  void readMonitorStandardOutput();
  void readMonitorStandardError();
  void monitorProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
  void progressFileChanged();
signals:
  void sendManagerStarted();
  void sendManagerOutput(QString, StringHandler::SimulationMessageType type);
  void sendManagerFinished(int, QProcess::ExitStatus);
  void sendMonitorStarted();
  void sendMonitorOutput(QString, StringHandler::SimulationMessageType type);
  void sendMonitorFinished(int, QProcess::ExitStatus);
  void sendManagerProgress(int);
};

#endif // TLMCOSIMULATIONTHREAD_H
