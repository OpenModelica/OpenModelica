/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
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
 * @author Volker Waurich <volker.waurich@tu-dresden.de>
 */

#include "FMUSettingsDialog.h"



/*!
 * \class FMUSettingsDialog
 * \brief widget for FMU-simulation settings.
 */
FMUSettingsDialog::FMUSettingsDialog(QWidget *pParent, VisualizerFMU* fmuVisualizer)
  : QDialog(pParent),
    fmu(fmuVisualizer),
    stepSize(0.001),
    renderFreq(0.1),
    solver(Solver::EULER_FORWARD)
{
  //create dialog
  mpSettingsDialog = new QDialog;
  mpSettingsDialog->setWindowTitle("FMU-Simulation Settings");
  mpSettingsDialog->setWindowIcon(QIcon(":/Resources/icons/animation.svg"));
  //the layouts
  QVBoxLayout *mainLayout = new QVBoxLayout;
  QGridLayout *settingsLayOut = new QGridLayout;
  //the widgets
  mpButtonBox = new QDialogButtonBox(QDialogButtonBox::Ok | QDialogButtonBox::Cancel);
  QLabel *solverLabel = new QLabel(tr("Solver"));
  mpSolverComboBox = new QComboBox(mpSettingsDialog);
  mpSolverComboBox->addItem(QString("Explicit Euler"));
  QLabel *stepsizeLabel = new QLabel(tr("Step Size [s]"));
  mpStepsizeLineEdit = new QLineEdit(QString::number(stepSize));
  QLabel *handleEventsLabel = new QLabel(tr("Process Events in FMU"));
  mpHandleEventsCheck = new QCheckBox();
  mpHandleEventsCheck->setCheckState(Qt::Checked);
  //assemble
  mpSettingsDialog->setLayout(mainLayout);
  mainLayout->addLayout(settingsLayOut);
  settingsLayOut->addWidget(solverLabel,0,0);
  settingsLayOut->addWidget(mpSolverComboBox,0,1);
  settingsLayOut->addWidget(stepsizeLabel,1,0);
  settingsLayOut->addWidget(mpStepsizeLineEdit,1,1);
  settingsLayOut->addWidget(handleEventsLabel,2,0);
  settingsLayOut->addWidget(mpHandleEventsCheck,2,1);
  mainLayout->addWidget(mpButtonBox);
  //connections
  QObject::connect(mpButtonBox, SIGNAL(accepted()), this,SLOT(saveSimSettings()));
  QObject::connect(mpButtonBox, SIGNAL(rejected()), mpSettingsDialog,SLOT(close()));

  mpSettingsDialog->exec();
}

FMUSettingsDialog::~FMUSettingsDialog()
{
  if (mpSettingsDialog)
    delete mpSettingsDialog;
  if (mpStepsizeLineEdit)
    delete mpStepsizeLineEdit;
  if (mpHandleEventsCheck)
    delete mpHandleEventsCheck;
  if (mpSolverComboBox)
    delete mpSolverComboBox;
  if (mpButtonBox)
    delete mpButtonBox;
}

/*!
 * \brief FMUSettingsDialog::saveSimSettings
 */
void FMUSettingsDialog::saveSimSettings()
{
  //step size
  bool isFloat = true;
  double stepSize = mpStepsizeLineEdit->text().toFloat(&isFloat);
  if (!isFloat) {
    stepSize = 0.0001;
  };
  //handle events
  bool handleEvents = true;
  if (!mpHandleEventsCheck->isChecked()){
    handleEvents = false;
  };
  //solver
  QString s = mpSolverComboBox->currentText();
  if (0 == s.compare(QString("explicit euler")))
  {
    Solver solver = Solver::EULER_FORWARD;
  }
  //store in FMU simulator
  fmu->setSimulationSettings(stepSize, solver, handleEvents);
  mpSettingsDialog->close();
}
