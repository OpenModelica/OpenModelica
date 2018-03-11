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

#ifndef DEBUGGERCONFIGURATIONSDIALOG_H
#define DEBUGGERCONFIGURATIONSDIALOG_H

#include "Util/Utilities.h"

#include <QDialog>
#include <QDialogButtonBox>
#include <QStatusBar>
#include <QStackedWidget>
#include <QSplitter>

class DebuggerConfigurationsDialog;
class Label;

class DebuggerConfigurationPage : public QWidget
{
  Q_OBJECT
private:
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
  DebuggerConfiguration mDebuggerConfiguration;

  DebuggerConfigurationPage(DebuggerConfiguration debuggerConfiguration, QListWidgetItem *pListWidgetItem,
                            DebuggerConfigurationsDialog *pDebuggerConfigurationsDialog);
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
  DebuggerConfigurationsDialog(QWidget *pParent = 0);
  QString getUniqueName(QString name = QString("New_configuration"), int number = 1);
  void readConfigurations();
  DebuggerConfigurationPage* getDebuggerConfigurationPage(QString configurationName);
  void runConfiguration(DebuggerConfigurationPage* pDebuggerConfigurationPage);
private:
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
signals:
  void debuggerLaunched();
public slots:
  void newConfiguration();
  void removeConfiguration();
  void changeConfigurationPage(QListWidgetItem *current, QListWidgetItem *previous);
  void saveAllConfigurations();
  void saveAllConfigurationsAndDebugConfiguration();
};

#endif // DEBUGGERCONFIGURATIONSDIALOG_H
