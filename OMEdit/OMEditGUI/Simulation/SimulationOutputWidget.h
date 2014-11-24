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
 *
 * @author Adeel Asghar <adeel.asghar@liu.se>
 *
 * RCS: $Id$
 *
 */

#ifndef SIMULATIONOUTPUTWIDGET_H
#define SIMULATIONOUTPUTWIDGET_H

#include "MainWindow.h"
#include "SimulationDialog.h"
#include "SimulationProcessThread.h"

class SimulationOptions;
class SimulationProcessThread;

struct SimulationMessage
{
  QString mStream;
  QString mType;
  QString mText;
  int mLevel;
  QString mIndex;
  QList<SimulationMessage> mChildren;

  SimulationMessage() {mStream = ""; mType = ""; mText = ""; mIndex = "";}
};

class SimulationOutputWidget : public QWidget
{
  Q_OBJECT
public:
  SimulationOutputWidget(SimulationOptions simulationOptions, MainWindow *pMainWindow);
  SimulationOptions getSimulationOptions() {return mSimulationOptions;}
  MainWindow* getMainWindow() {return mpMainWindow;}
  QTabWidget* getGeneratedFilesTabWidget() {return mpGeneratedFilesTabWidget;}
  QTextBrowser* getSimulationOutputTextBrowser() {return mpSimulationOutputTextBrowser;}
  QPlainTextEdit* getCompilationOutputTextBox() {return mpCompilationOutputTextBox;}
  SimulationProcessThread* getSimulationProcessThread() {return mpSimulationProcessThread;}
  void addGeneratedFileTab(QString fileName);
private:
  SimulationOptions mSimulationOptions;
  MainWindow *mpMainWindow;
  Label *mpProgressLabel;
  QProgressBar *mpProgressBar;
  QPushButton *mpCancelButton;
  QTabWidget *mpGeneratedFilesTabWidget;
  QTextBrowser *mpSimulationOutputTextBrowser;
  QPlainTextEdit *mpCompilationOutputTextBox;
  bool mIsCancelled;
  SimulationProcessThread *mpSimulationProcessThread;
  QDateTime mResultFileLastModifiedDateTime;

  QList<SimulationMessage> parseXMLLogOutput(QString output);
  SimulationMessage parseXMLLogMessageTag(QDomNode messageNode, int level);
  void writeSimulationMessage(SimulationMessage &simulationMessage);
public slots:
  void compilationProcessStarted();
  void writeCompilationOutput(QString output, QColor color);
  void compilationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
  void simulationProcessStarted();
  void writeSimulationOutput(QString output, QColor color, bool textFormat = false);
  void simulationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
  void GDBProcessStarted();
  void GDBProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
  void cancelCompilationOrSimulation();
  void openTransformationBrowser(QUrl url);
};

#endif // SIMULATIONOUTPUTWIDGET_H
