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
 * RCS: $Id: DebuggerMainWindow.h 22009 2014-08-26 23:13:38Z hudson $
 *
 */

#ifndef DEBUGGERMAINWINDOW_H
#define DEBUGGERMAINWINDOW_H

#include <QSettings>

#include "MainWindow.h"
#include "GDBAdapter.h"
#include "StackFramesWidget.h"
#include "LocalsWidget.h"
#include "BreakpointsWidget.h"
#include "Utilities.h"
#include "DebuggerSourceEditor.h"
#include "ProcessListModel.h"

class GDBAdapter;
class StackFramesWidget;
class LocalsWidget;
class BreakpointsWidget;
class GDBLoggerWidget;
class TargetOutputWidget;
class DebuggerConfigurationsDialog;
class DebuggerSourceEditor;
class InfoBar;

class DebuggerMainWindow : public QMainWindow
{
  Q_OBJECT
public:
  DebuggerMainWindow(MainWindow *pMainWindow = 0);
  void restoreWindows();
  void closeEvent(QCloseEvent *event);
  void readFileAndNavigateToLine(QString fileName, QString lineNumber);
  MainWindow* getMainWindow() {return mpMainWindow;}
  GDBAdapter* getGDBAdapter() {return mpGDBAdapter;}
  StackFramesWidget* getStackFramesWidget() {return mpStackFramesWidget;}
  LocalsWidget* getLocalsWidget() {return mpLocalsWidget;}
  BreakpointsWidget* getBreakpointsWidget() {return mpBreakpointsWidget;}
  GDBLoggerWidget* getGDBLoggerWidget() {return mpGDBLoggerWidget;}
  TargetOutputWidget *getTargetOutputWidget() {return mpTargetOutputWidget;}
  Label* getDebuggerSourceEditorFileLabel() {return mpDebuggerSourceEditorFileLabel;}
  InfoBar* getDebuggerSourceEditorInfoBar() {return mpDebuggerSourceEditorInfoBar;}
  DebuggerSourceEditor* getDebuggerSourceEditor() {return mpDebuggerSourceEditor;}
private:
  void createActions();
  void createMenus();

  MainWindow *mpMainWindow;
  GDBAdapter *mpGDBAdapter;
  StackFramesWidget *mpStackFramesWidget;
  QDockWidget *mpStackFramesDockWidget;
  BreakpointsWidget *mpBreakpointsWidget;
  QDockWidget *mpBreakpointsDockWidget;
  LocalsWidget *mpLocalsWidget;
  QDockWidget *mpLocalsDockWidget;
  GDBLoggerWidget *mpGDBLoggerWidget;
  QDockWidget *mpGDBLoggerDockWidget;
  TargetOutputWidget *mpTargetOutputWidget;
  QDockWidget *mpTargetOutputDockWidget;
  Label *mpDebuggerSourceEditorFileLabel;
  InfoBar *mpDebuggerSourceEditorInfoBar;
  DebuggerSourceEditor *mpDebuggerSourceEditor;
  QAction *mpDebugConfigurationsAction;
  QAction *mpAttachDebuggerToRunningProcessAction;
public slots:
  void handleGDBProcessFinished();
  void showConfigureDialog();
  void showAttachToProcessDialog();
};

class DebuggerConfigurationPage : public QWidget
{
  Q_OBJECT
private:
  DebuggerConfiguration mDebuggerConfiguration;
  QListWidgetItem *mpConfigurationListWidgetItem;
  DebuggerConfigurationsDialog *mpDebuggerConfigurationsDialog;
  Label *mpNameLabel;
  QLineEdit *mpNameTextBox;
  Label *mpProgramLabel;
  QLineEdit *mpProgramTextBox;
  QPushButton *mpProgramBrowseButton;
  Label *mpWorkingDirectoryLabel;
  QLineEdit *mpWorkingDirectoryTextBox;
  QPushButton *mpWorkingDirectoryBrowseButton;
  Label *mpGDBPathLabel;
  QLineEdit *mpGDBPathTextBox;
  QPushButton *mpGDBPathBrowseButton;
  Label *mpArgumentsLabel;
  QPlainTextEdit *mpArgumentsTextBox;
  QPushButton *mpApplyButton;
  QPushButton *mpResetButton;
  QDialogButtonBox *mpButtonBox;
public:
  DebuggerConfigurationPage(DebuggerConfiguration debuggerConfiguration, QListWidgetItem *pListWidgetItem,
                            DebuggerConfigurationsDialog *pDebuggerConfigurationsDialog);
  DebuggerConfiguration getDebuggerConfiguration() {return mDebuggerConfiguration;}
  bool configurationExists(QString configurationKeyToCheck);
public slots:
  void browseProgramFile();
  void browseWorkingDirectory();
  void browseGDBPath();
  bool saveDebugConfiguration();
  void resetDebugConfiguration();
};

class DebuggerConfigurationsDialog : public QDialog
{
  Q_OBJECT
public:
  enum { MaxDebugConfigurations = 10 };
  DebuggerConfigurationsDialog(DebuggerMainWindow *pDebuggerMainWindow);
  QString getUniqueName(QString name = QString("New_configuration"), int number = 1);
  void readConfigurations();
private:
  DebuggerMainWindow *mpDebuggerMainWindow;
  QAction *mpNewConfigurationAction;
  QAction *mpRemoveConfigurationAction;
  QToolButton *mpNewToolButton;
  QToolButton *mpDeleteToolButton;
  QStatusBar *mpStatusBar;
  QListWidget *mpConfigurationsListWidget;
  QStackedWidget *mpConfigurationPagesWidget;
  QSplitter *mpConfigurationsSplitter;
  QPushButton *mpSaveButton;
  QPushButton *mpSaveAndDebugButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpConfigurationsButtonBox;

  bool saveAllConfigurationsHelper();
public slots:
  void newConfiguration();
  void removeConfiguration();
  void changeConfigurationPage(QListWidgetItem *current, QListWidgetItem *previous);
  void saveAllConfigurations();
  void saveAllConfigurationsAndDebugConfiguration();
};

#endif // DEBUGGERMAINWINDOW_H
