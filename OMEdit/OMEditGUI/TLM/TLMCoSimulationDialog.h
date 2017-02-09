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

#ifndef TLMCOSIMULATIONDIALOG_H
#define TLMCOSIMULATIONDIALOG_H

#include "TLMCoSimulationOptions.h"

#include <QDialog>
#include <QLineEdit>
#include <QPushButton>
#include <QGroupBox>
#include <QCheckBox>
#include <QDialogButtonBox>

class LibraryTreeItem;
class Label;
class TLMCoSimulationOutputWidget;
class TLMCoSimulationDialog : public QDialog
{
  Q_OBJECT
public:
  TLMCoSimulationDialog(QWidget *pParent = 0);
  ~TLMCoSimulationDialog();
  void show(LibraryTreeItem *pLibraryTreeItem);
  void simulationProcessFinished(TLMCoSimulationOptions tlmCoSimulationOptions, QDateTime resultFileLastModifiedDateTime);
  bool isTLMCoSimulationRunning() {return mIsTLMCoSimulationRunning;}
  void setIsTLMCoSimulationRunning(bool isTLMCoSimulationRunning) {mIsTLMCoSimulationRunning = isTLMCoSimulationRunning;}
private:
  LibraryTreeItem *mpLibraryTreeItem;
  bool mIsTLMCoSimulationRunning;
  Label *mpHeadingLabel;
  QFrame *mpHorizontalLine;
  Label *mpTLMPluginPathLabel;
  QLineEdit *mpTLMPluginPathTextBox;
  QPushButton *mpBrowseTLMPluginPathButton;
  QGroupBox *mpTLMManagerGroupBox;
  Label *mpManagerProcessLabel;
  QLineEdit *mpManagerProcessTextBox;
  QPushButton *mpBrowseManagerProcessButton;
  Label *mpServerPortLabel;
  QLineEdit *mpServerPortTextBox;
  Label *mpMonitorPortLabel;
  QLineEdit *mpMonitorPortTextBox;
  QCheckBox *mpManagerDebugModeCheckBox;
  QGroupBox *mpTLMMonitorGroupBox;
  Label *mpMonitorProcessLabel;
  QLineEdit *mpMonitorProcessTextBox;
  QPushButton *mpBrowseMonitorProcessButton;
  Label *mpNumberOfStepsLabel;
  QLineEdit *mpNumberOfStepsTextBox;
  Label *mpTimeStepSizeLabel;
  QLineEdit *mpTimeStepSizeTextBox;
  QCheckBox *mpMonitorDebugModeCheckBox;
  QPushButton *mpShowTLMCoSimulationOutputWindowButton;
  QPushButton *mpRunButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
  TLMCoSimulationOutputWidget *mpTLMCoSimulationOutputWidget;

  bool validate();
  TLMCoSimulationOptions createTLMCoSimulationOptions();
private slots:
  void browseTLMPluginPath();
  void browseManagerProcess();
  void browseMonitorProcess();
  void showTLMCoSimulationOutputWindow();
  void runTLMCoSimulation();
};

class GraphicsView;
class CompositeModelSimulationParamsDialog : public QDialog
{
  Q_OBJECT
public:
  CompositeModelSimulationParamsDialog(GraphicsView *pGraphicsView);
private:
  GraphicsView *mpGraphicsView;
  LibraryTreeItem *mpLibraryTreeItem;
  Label *mpSimulationParamsHeading;
  QFrame *mpHorizontalLine;
  Label *mpStartTimeLabel;
  QLineEdit *mpStartTimeTextBox;
  Label *mpStopTimeLabel;
  QLineEdit *mpStopTimeTextBox;
  QPushButton *mpSaveButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
  QString mOldStartTime;
  QString mOldStopTime;
  bool validateSimulationParams();
private slots:
  void saveSimulationParams();
};

#endif // TLMCOSIMULATIONDIALOG_H
