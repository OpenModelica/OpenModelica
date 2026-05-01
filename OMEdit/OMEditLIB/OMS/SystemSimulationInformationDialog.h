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

#ifndef SYSTEMSIMULATIONINFORMATIONDIALOG_H
#define SYSTEMSIMULATIONINFORMATIONDIALOG_H

#include "OMSimulator/OMSimulator.h"

#include <QDialog>
#include <QLineEdit>
#include <QComboBox>
#include <QDialogButtonBox>

class ModelWidget;
class Label;

class SystemSimulationInformationWidget : public QWidget
{
  Q_OBJECT
public:
  SystemSimulationInformationWidget(ModelWidget *pModelWidget);
  bool setSystemSimulationInformation(bool pushOnStack);
private:
  ModelWidget *mpModelWidget;
  // TLM system simulation information
  Label *mpIpAddressLabel;
  QLineEdit *mpIpAddressTextBox;
  Label *mpManagerPortLabel;
  QLineEdit *mpManagerPortTextBox;
  Label *mpMonitorPortLabel;
  QLineEdit *mpMonitorPortTextBox;
  // WC/SC system simulation information
  Label *mpSolverLabel;
  QComboBox *mpSolverComboBox;
  Label *mpFixedStepSizeLabel;
  QLineEdit *mpFixedStepSizeTextBox;
  Label *mpInitialStepSizeLabel;
  QLineEdit *mpInitialStepSizeTextBox;
  Label *mpMinimumStepSizeLabel;
  QLineEdit *mpMinimumStepSizeTextBox;
  Label *mpMaximumStepSizeLabel;
  QLineEdit *mpMaximumStepSizeTextBox;
  Label *mpRelativeToleranceLabel;
  QLineEdit *mpRelativeToleranceTextBox;
private slots:
  void solverChanged(int index);
};

class SystemSimulationInformationDialog : public QDialog
{
  Q_OBJECT
public:
  SystemSimulationInformationDialog(ModelWidget *pModelWidget);
private:
  Label *mpHeading;
  QFrame *mpHorizontalLine;
  SystemSimulationInformationWidget *mpSystemSimulationInformationWidget;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
private slots:
  void setSystemSimulationInformation();
};

#endif // SYSTEMSIMULATIONINFORMATIONDIALOG_H
