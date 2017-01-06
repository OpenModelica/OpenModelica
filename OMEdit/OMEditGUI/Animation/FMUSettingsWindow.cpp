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

#include "FMUSettingsWindow.h"



/*!
 * \class FMUSettingsWindow
 * \brief widget for FMu-simulation settings.
 */

FMUSettingsWindow::FMUSettingsWindow(QWidget *pParent, VisualizerFMU* fmuVisualizer)
  : QMainWindow(pParent),
    fmu(fmuVisualizer),
    stepSize(0.001),
    renderFreq(0.1),
    solver(Solver::EULER_FORWARD)
{
  //create dialog
  mpSettingsDialog = new QDialog;
  mpSettingsDialog->setWindowTitle("Visualization settings");
  mpSettingsDialog->setWindowIcon(QIcon(":/Resources/icons/animation.svg"));
  //the layouts
  QVBoxLayout *mainLayout = new QVBoxLayout;
  QHBoxLayout *buttonLayout = new QHBoxLayout;
  QHBoxLayout *visualizationLayout = new QHBoxLayout;
  QVBoxLayout *visLeftLayout = new QVBoxLayout;
  QVBoxLayout *visRightLayout = new QVBoxLayout;
  QHBoxLayout *simulationLayout = new QHBoxLayout;
  QVBoxLayout *simLeftLayout = new QVBoxLayout;
  QVBoxLayout *simRightLayout = new QVBoxLayout;
  //the widgets
  QLabel *visualizationHeading = new QLabel(tr("Visualization Settings"));
  QLabel *freqLabel = new QLabel(tr("Render Frequency [s]"));
  mpRenderFreqLineEdit = new QLineEdit(QString::number(renderFreq));
  mpOkButton = new QPushButton(tr("OK"));
  //solver settings
  QLabel *simulationHeading = new QLabel(tr("FMU-Simulation Settings"));
  QLabel *solverLabel = new QLabel(tr("solver"));
  mpSolverComboBox = new QComboBox(mpSettingsDialog);
  mpSolverComboBox->addItem(QString("explicit euler"));
  QLabel *stepsizeLabel = new QLabel(tr("step size [s]"));
  mpStepsizeLineEdit = new QLineEdit(QString::number(stepSize));
  QLabel *handleEventsLabel = new QLabel(tr("Process Events in FMU"));
  mpHandleEventsCheck = new QCheckBox();
  mpHandleEventsCheck->setCheckState(Qt::Checked);
  //assemble
  mpSettingsDialog->setLayout(mainLayout);
  //mainLayout->addWidget(visualizationHeading);
  //mainLayout->addLayout(visualizationLayout);
  visualizationLayout->addLayout(visLeftLayout);
  visualizationLayout->addLayout(visRightLayout);
  visLeftLayout->addWidget(freqLabel);
  visRightLayout->addWidget(mpRenderFreqLineEdit);
  mainLayout->addWidget(simulationHeading);
  mainLayout->addLayout(simulationLayout);
  simulationLayout->addLayout(simLeftLayout);
  simulationLayout->addLayout(simRightLayout);

  simLeftLayout->addWidget(solverLabel);
  simRightLayout->addWidget(mpSolverComboBox);
  simLeftLayout->addWidget(stepsizeLabel);
  simRightLayout->addWidget(mpStepsizeLineEdit);
  simLeftLayout->addWidget(handleEventsLabel);
  simRightLayout->addWidget(mpHandleEventsCheck);

  mainLayout->addLayout(buttonLayout);
  buttonLayout->addWidget(mpOkButton);

  //connections
  QObject::connect(mpOkButton, SIGNAL(clicked()), this,SLOT(saveSimSettings()));

  mpSettingsDialog->show();
}

FMUSettingsWindow::~FMUSettingsWindow()
{
  if (mpRenderFreqLineEdit)
    delete mpRenderFreqLineEdit;
  if (mpStepsizeLineEdit)
    delete mpStepsizeLineEdit;
  if (mpHandleEventsCheck)
    delete mpHandleEventsCheck;
  if (mpSolverComboBox)
    delete mpSolverComboBox;
  if (mpOkButton)
    delete mpOkButton;
}

/*!
 * \brief FMUSettingsWindow::saveSimSettings
 */
void FMUSettingsWindow::saveSimSettings()
{
  //step size and render freq
  bool isFloat = true;
  double stepSize = mpStepsizeLineEdit->text().toFloat(&isFloat);
  if (!isFloat) {
    stepSize = 0.0001;
  };
  double renderFreq = mpRenderFreqLineEdit->text().toFloat(&isFloat);
  if (!isFloat) {
    stepSize = 0.1;
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
