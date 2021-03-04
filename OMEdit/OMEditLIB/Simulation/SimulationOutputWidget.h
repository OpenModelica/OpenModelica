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

#ifndef SIMULATIONOUTPUTWIDGET_H
#define SIMULATIONOUTPUTWIDGET_H

#include "SimulationOptions.h"
#include "Util/StringHandler.h"

#include <QTreeView>
#include <QPlainTextEdit>
#include <QProgressBar>
#include <QPushButton>
#include <QTextBrowser>
#include <QProcess>
#include <QDateTime>
#include <QTcpServer>

class Label;
class OutputPlainTextEdit;
class SimulationOutputHandler;
class SimulationOutputWidget;
class SimulationMessage;
class ArchivedSimulationItem;

class SimulationOutputTree : public QTreeView
{
  Q_OBJECT
private:
  SimulationOutputWidget *mpSimulationOutputWidget;
  QAction *mpSelectAllAction;
  QAction *mpCopyAction;
  QAction *mpExpandAllAction;
  QAction *mpCollapseAllAction;
public:
  SimulationOutputTree(SimulationOutputWidget *pSimulationOutputWidget);
  SimulationOutputWidget* getSimulationOutputWidget() {return mpSimulationOutputWidget;}
  int getDepth(const QModelIndex &index) const;
public slots:
  void showContextMenu(QPoint point);
  void callLayoutChanged(int logicalIndex, int oldSize, int newSize);
  void selectAllMessages();
  void copyMessages();
protected:
  virtual void keyPressEvent(QKeyEvent *event) override;
};

class SimulationOutputWidget : public QWidget
{
  Q_OBJECT
public:
  enum SocketState {
    NotConnected,
    Connected,
    Disconnected
  };
  SimulationOutputWidget(SimulationOptions simulationOptions, QWidget *pParent = 0);
  ~SimulationOutputWidget();
  SimulationOptions getSimulationOptions() {return mSimulationOptions;}
  QProgressBar* getProgressBar() {return mpProgressBar;}
  QTabWidget* getGeneratedFilesTabWidget() {return mpGeneratedFilesTabWidget;}
  bool isOutputStructured() {return mIsOutputStructured;}
  SimulationOutputTree* getSimulationOutputTree() {return mpSimulationOutputTree;}
  QTcpServer* getTcpServer() {return mpTcpServer;}
  QProcess* getCompilationProcess() {return mpCompilationProcess;}
  void setCompilationProcessKilled(bool killed) {mIsCompilationProcessKilled = killed;}
  bool isCompilationProcessKilled() {return mIsCompilationProcessKilled;}
  bool isCompilationProcessRunning() {return mIsCompilationProcessRunning;}
  QProcess* getSimulationProcess() {return mpSimulationProcess;}
  void setSimulationProcessKilled(bool killed) {mIsSimulationProcessKilled = killed;}
  bool isSimulationProcessKilled() {return mIsSimulationProcessKilled;}
  bool isSimulationProcessRunning() {return mIsSimulationProcessRunning;}
  void addGeneratedFileTab(QString fileName);
  void writeSimulationMessage(SimulationMessage *pSimulationMessage);
  void embeddedServerInitialized();
private:
  SimulationOptions mSimulationOptions;
  Label *mpProgressLabel;
  QProgressBar *mpProgressBar;
  QPushButton *mpCancelButton;
  QToolButton *mpOpenTransformationalDebuggerButton;
  QPushButton *mpOpenOutputFileButton;
  QTabWidget *mpGeneratedFilesTabWidget;
  QList<QString> mGeneratedFilesList;
  QList<QString> mGeneratedAlgLoopFilesList;
  OutputPlainTextEdit *mpCompilationOutputTextBox;
  QString mSimulationStandardOutput;
  QString mSimulationStandardError;
  SimulationOutputHandler *mpSimulationOutputHandler;
  bool mIsOutputStructured;
  QTextBrowser *mpSimulationOutputTextBrowser;
  SimulationOutputTree *mpSimulationOutputTree;
  ArchivedSimulationItem *mpArchivedSimulationItem;
  QTcpServer *mpTcpServer;
  QTcpSocket *mpTcpSocket;
  SocketState mSocketState;
  QProcess *mpCompilationProcess;
  bool mIsCompilationProcessKilled;
  bool mIsCompilationProcessRunning;
  QProcess *mpSimulationProcess;
  bool mIsSimulationProcessKilled;
  bool mIsSimulationProcessRunning;
  QDateTime mResultFileLastModifiedDateTime;

  void compileModel();
  void runSimulationExecutable();
  void writeCompilationOutput(QString output, QColor color);
  void compilationProcessFinishedHelper(int exitCode, QProcess::ExitStatus exitStatus);
  void deleteIntermediateCompilationFiles();
  void writeSimulationOutput(QString output, StringHandler::SimulationMessageType type, bool textFormat);
  void simulationProcessFinishedHelper();
private slots:
  void cancelCompilationOrSimulation();
  void openTransformationalDebugger();
  void openSimulationLogFile();
  void createSimulationProgressSocket();
  void readSimulationProgress();
  void socketDisconnected();
  void compilationProcessStarted();
  void readCompilationStandardOutput();
  void readCompilationStandardError();
  void compilationProcessError(QProcess::ProcessError error);
  void compilationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
  void simulationProcessStarted();
  void readSimulationStandardOutput();
  void readSimulationStandardError();
  void simulationProcessError(QProcess::ProcessError error);
  void simulationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
public slots:
  void openTransformationBrowser(QUrl url);
signals:
  void simulationFinished();
};

#endif // SIMULATIONOUTPUTWIDGET_H
