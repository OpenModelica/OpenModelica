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
#include "Util/Helper.h"
#include "Util/Utilities.h"

/*!
 * \class FMUSettingsDialog
 * \brief widget for FMU-simulation settings.
 */
/*!
 * \brief FMUSettingsDialog::FMUSettingsDialog
 * \param pParent
 * \param pVisualizerFMU
 */
FMUSettingsDialog::FMUSettingsDialog(QWidget *pParent, VisualizerFMU* pVisualizerFMU)
  : QDialog(pParent),
    mpVisualizerFMU(pVisualizerFMU),
    mStepSize(0.001),
    mRenderFreq(0.1)
{
  setAttribute(Qt::WA_DeleteOnClose);
  //create dialog
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName, tr("FMU-Simulation Settings")));
  //the widgets
  QLabel *solverLabel = new QLabel(tr("Solver"));
  mpSolverComboBox = new QComboBox();
  mpSolverComboBox->addItem(QString("Explicit Euler"), QVariant((int)Solver::EULER_FORWARD));
  Label *stepsizeLabel = new Label(tr("Step Size [s]"));
  mpStepSizeLineEdit = new QLineEdit(QString::number(mStepSize));
  Label *handleEventsLabel = new Label(tr("Process Events in FMU"));
  mpHandleEventsCheck = new QCheckBox();
  mpHandleEventsCheck->setCheckState(Qt::Checked);
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(saveSimSettings()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // create buttons box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  //connections
  QObject::connect(mpButtonBox, SIGNAL(accepted()), this, SLOT(saveSimSettings()));
  QObject::connect(mpButtonBox, SIGNAL(rejected()), this, SLOT(reject()));
  //assemble
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addWidget(solverLabel, 0, 0);
  pMainLayout->addWidget(mpSolverComboBox, 0, 1);
  pMainLayout->addWidget(stepsizeLabel, 1, 0);
  pMainLayout->addWidget(mpStepSizeLineEdit, 1, 1);
  pMainLayout->addWidget(handleEventsLabel, 2, 0);
  pMainLayout->addWidget(mpHandleEventsCheck, 2, 1);
  pMainLayout->addWidget(mpButtonBox, 3, 0, 1, 2, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
 * \brief FMUSettingsDialog::saveSimSettings
 */
void FMUSettingsDialog::saveSimSettings()
{
  //step size
  bool isFloat = true;
  double stepSize = mpStepSizeLineEdit->text().toFloat(&isFloat);
  if (!isFloat) {
    stepSize = 0.0001;
  }
  //handle events
  bool handleEvents = true;
  if (!mpHandleEventsCheck->isChecked()){
    handleEvents = false;
  };
  //store in FMU simulator
  mpVisualizerFMU->setSimulationSettings(stepSize, static_cast<Solver>(mpSolverComboBox->itemData(mpSolverComboBox->currentIndex()).toInt()),
                                         handleEvents);
  accept();
}
