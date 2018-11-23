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

#include "SystemSimulationInformationDialog.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Modeling/Commands.h"

#include <QGridLayout>
#include <QMessageBox>

/*!
 * \class SystemSimulationInformationDialog
 * \brief A dialog for system simulation information.
 */
/*!
 * \brief SystemSimulationInformationDialog::SystemSimulationInformationDialog
 * \param pGraphicsView
 */
SystemSimulationInformationDialog::SystemSimulationInformationDialog(GraphicsView *pGraphicsView)
  : QDialog(pGraphicsView)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName, Helper::systemSimulationInformation));
  mpGraphicsView = pGraphicsView;
  // set heading
  mpHeading = Utilities::getHeadingLabel(Helper::systemSimulationInformation);
  // set separator line
  mpHorizontalLine = Utilities::getHeadingLine();
  // fixed step size
  mpFixedStepSizeLabel = new Label(tr("Fixed Step Size:"));
  mpFixedStepSizeTextBox = new QLineEdit;
  // tolerance
  mpToleranceLabel = new Label("Tolerance:");
  mpToleranceTextBox = new QLineEdit;
  // buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(setSystemSimulationInformation()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // add buttons to the button box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // set the layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->addWidget(mpHeading, 0, 0, 1, 2);
  pMainLayout->addWidget(mpHorizontalLine, 1, 0, 1, 2);
  pMainLayout->addWidget(mpFixedStepSizeLabel, 2, 0);
  pMainLayout->addWidget(mpFixedStepSizeTextBox, 2, 1);
  pMainLayout->addWidget(mpToleranceLabel, 3, 0);
  pMainLayout->addWidget(mpToleranceTextBox, 3, 1);
  pMainLayout->addWidget(mpButtonBox, 5, 0, 1, 2, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
 * \brief SystemSimulationInformationDialog::setSystemSimulationInformation
 * Sets the simulation information of the system.
 */
void SystemSimulationInformationDialog::setSystemSimulationInformation()
{
  if (mpFixedStepSizeTextBox->text().isEmpty()) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          GUIMessages::getMessage(GUIMessages::ENTER_VALUE).arg("Fixed Step Size"), Helper::ok);
    return;
  }

  SystemSimulationInformationCommand *pSystemSimulationInformationCommand;
  pSystemSimulationInformationCommand = new SystemSimulationInformationCommand(mpFixedStepSizeTextBox->text(),
                                                                               mpGraphicsView->getModelWidget()->getLibraryTreeItem());
  mpGraphicsView->getModelWidget()->getUndoStack()->push(pSystemSimulationInformationCommand);
  if (!pSystemSimulationInformationCommand->isFailed()) {
    mpGraphicsView->getModelWidget()->updateModelText();
    accept();
  }
}

