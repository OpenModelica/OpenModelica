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

#ifndef TLMCOSIMULATIONOPTIONS_H
#define TLMCOSIMULATIONOPTIONS_H

#include <QString>
#include <QStringList>

class TLMCoSimulationOptions
{
public:
  TLMCoSimulationOptions() {
    setIsValid(true);
    setClassName("");
    setFileName("");
    setManagerProcess("");
    setServerPort("11111");
    setMonitorPort("");
    setManagerDebugMode(false);
    setMonitorProcess("");
    setNumberOfSteps(1000);
    setTimeStepSize(0);
    setMonitorDebugMode(false);
  }

  void setIsValid(bool isValid) {mValid = isValid;}
  bool isValid() {return mValid;}
  void setClassName(QString className) {mClassName = className;}
  QString getClassName() {return mClassName;}
  void setFileName(QString fileName) {mFileName = fileName;}
  QString getFileName() {return mFileName;}
  QString getTLMPluginPath() {return mTLMPluginPath;}
  void setTLMPluginPath(const QString &tlmPluginPath) {mTLMPluginPath = tlmPluginPath;}
  QString getManagerProcess() {return mManagerProcess;}
  void setManagerProcess(const QString &managerProcess) {mManagerProcess = managerProcess;}
  void setServerPort(QString serverPort) {mServerPort = serverPort;}
  QString getServerPort() {return mServerPort;}
  void setMonitorPort(QString monitorPort) {mMonitorPort = monitorPort;}
  QString getMonitorPort() {return mMonitorPort;}
  void setManagerDebugMode(bool managerDebugMode) {mManagerDebugMode = managerDebugMode;}
  bool getManagerDebugMode() {return mManagerDebugMode;}
  QString getMonitorProcess() {return mMonitorProcess;}
  void setMonitorProcess(const QString &monitorProcess) {mMonitorProcess = monitorProcess;}
  void setNumberOfSteps(int numberOfSteps) {mNumberOfSteps = numberOfSteps;}
  int getNumberOfSteps() {return mNumberOfSteps;}
  void setTimeStepSize(double timeStepSize) {mTimeStepSize = timeStepSize;}
  double getTimeStepSize() {return mTimeStepSize;}
  void setMonitorDebugMode(bool monitorDebugMode) {mMonitorDebugMode = monitorDebugMode;}
  bool getMonitorDebugMode() {return mMonitorDebugMode;}
  void setManagerArgs(QStringList managerArgs) {mManagerArgs = managerArgs;}
  QStringList getManagerArgs() {return mManagerArgs;}
  void setMonitorArgs(QStringList monitorArgs) {mMonitorArgs = monitorArgs;}
  QStringList getMonitorArgs() {return mMonitorArgs;}

private:
  bool mValid;
  QString mClassName;
  QString mFileName;
  QString mTLMPluginPath;
  QString mManagerProcess;
  QString mServerPort;
  QString mMonitorPort;
  bool mManagerDebugMode;
  QString mMonitorProcess;
  int mNumberOfSteps;
  double mTimeStepSize;
  bool mMonitorDebugMode;
  QStringList mManagerArgs;
  QStringList mMonitorArgs;
};

#endif // TLMCOSIMULATIONOPTIONS_H
