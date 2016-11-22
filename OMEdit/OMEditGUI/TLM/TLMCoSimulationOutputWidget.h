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

#ifndef TLMCOSIMULATIONOUTPUTWIDGET_H
#define TLMCOSIMULATIONOUTPUTWIDGET_H

#include <QWidget>
#include <QProgressBar>
#include <QPushButton>
#include <QPlainTextEdit>
#include <QDateTime>
#include <QProcess>

#include "TLMCoSimulationOptions.h"
#include "Util/StringHandler.h"

class Label;
class TLMCoSimulationThread;

class TLMCoSimulationOutputWidget : public QWidget
{
  Q_OBJECT
public:
  TLMCoSimulationOutputWidget(QWidget *pParent = 0);
  ~TLMCoSimulationOutputWidget();
  TLMCoSimulationOptions getTLMCoSimulationOptions() {return mTLMCoSimulationOptions;}
  void showTLMCoSimulationOutputWidget(TLMCoSimulationOptions tlmCoSimulationOptions);
  void clear();
private:
  TLMCoSimulationOptions mTLMCoSimulationOptions;
  Label *mpProgressLabel;
  QProgressBar *mpProgressBar;
  Label *mpManagerOutputLabel;
  QPushButton *mpStopManagerButton;
  QPushButton *mpOpenManagerLogFileButton;
  QPlainTextEdit *mpManagerOutputTextBox;
  Label *mpMonitorOutputLabel;
  QPushButton *mpStopMonitorButton;
  QPushButton *mpOpenMonitorLogFileButton;
  QPlainTextEdit *mpMonitorOutputTextBox;
  TLMCoSimulationThread *mpTLMCoSimulationProcessThread;
  QDateTime mResultFileLastModifiedDateTime;
public slots:
  void stopManager();
  void openManagerLogFile();
  void stopMonitor();
  void openMonitorLogFile();
  void managerProcessStarted();
  void writeManagerOutput(QString output, StringHandler::SimulationMessageType type);
  void managerProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
  void monitorProcessStarted();
  void writeMonitorOutput(QString output, StringHandler::SimulationMessageType type);
  void monitorProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
};

#endif // TLMCOSIMULATIONOUTPUTWIDGET_H
