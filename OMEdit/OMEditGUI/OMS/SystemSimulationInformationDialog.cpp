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

TLMSystemSimulationInformation::TLMSystemSimulationInformation()
{
  mIpAddress = "";
  mManagerPort = 0;
  mMonitorPort = 0;
}

WCSystemSimulationInformation::WCSystemSimulationInformation()
{
  mFixedStepSize = 0.0;
  mTolerance = 0.0;
}

SCSystemSimulationInformation::SCSystemSimulationInformation()
{
  mDescription = "";
  mAbsoluteTolerance = 0.0;
  mRelativeTolerance = 0.0;
  mMinimumStepSize = 0.0;
  mMaximumStepSize = 0.0;
  mInitialStepSize = 0.0;
}

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
  mpGraphicsView = pGraphicsView;
  setWindowTitle(QString("%1 - %2 - %3").arg(Helper::applicationName, Helper::systemSimulationInformation,
                                             mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getName()));
  setAttribute(Qt::WA_DeleteOnClose);
  // set heading
  mpHeading = Utilities::getHeadingLabel(QString("%1 - %2").arg(Helper::systemSimulationInformation,
                                                                mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getName()));
  // set separator line
  mpHorizontalLine = Utilities::getHeadingLine();

  QIntValidator *pIntValidator = new QIntValidator(this);
  QDoubleValidator *pDoubleValidator = new QDoubleValidator(this);

  if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isTLMSystem()) {
    // IP address
    mpIpAddressLabel = new Label(tr("IP Adress:"));
    mpIpAddressTextBox = new QLineEdit("127.0.1.1");
    // manager port
    mpManagerPortLabel = new Label(tr("Manager Port:"));
    mpManagerPortTextBox = new QLineEdit("11117");
    mpManagerPortTextBox->setValidator(pIntValidator);
    // monitor port
    mpMonitorPortLabel = new Label(tr("Monitor Port:"));
    mpMonitorPortTextBox = new QLineEdit("12117");
    mpMonitorPortTextBox->setValidator(pIntValidator);
  } else if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isWCSystem()) {
    // fixed step size
    mpFixedStepSizeLabel = new Label(tr("Fixed Step Size:"));
    mpFixedStepSizeTextBox = new QLineEdit;
    mpFixedStepSizeTextBox->setValidator(pDoubleValidator);
    // tolerance
    mpToleranceLabel = new Label("Tolerance:");
    mpToleranceTextBox = new QLineEdit;
    mpToleranceTextBox->setValidator(pDoubleValidator);
  } else { // oms_system_sc

  }
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
  int row = 2;
  if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isTLMSystem()) {
    pMainLayout->addWidget(mpIpAddressLabel, row, 0);
    pMainLayout->addWidget(mpIpAddressTextBox, row++, 1);
    pMainLayout->addWidget(mpManagerPortLabel, row, 0);
    pMainLayout->addWidget(mpManagerPortTextBox, row++, 1);
    pMainLayout->addWidget(mpMonitorPortLabel, row, 0);
    pMainLayout->addWidget(mpMonitorPortTextBox, row++, 1);
  } else if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isWCSystem()) {
    pMainLayout->addWidget(mpFixedStepSizeLabel, row, 0);
    pMainLayout->addWidget(mpFixedStepSizeTextBox, row++, 1);
    pMainLayout->addWidget(mpToleranceLabel, row, 0);
    pMainLayout->addWidget(mpToleranceTextBox, row++, 1);
  } else { // oms_system_sc

  }
  pMainLayout->addWidget(mpButtonBox, row++, 0, 1, 2, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
 * \brief SystemSimulationInformationDialog::setSystemSimulationInformation
 * Sets the simulation information of the system.
 */
void SystemSimulationInformationDialog::setSystemSimulationInformation()
{
  if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isTLMSystem()) {
    if (mpIpAddressTextBox->text().isEmpty()) {
      QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                            GUIMessages::getMessage(GUIMessages::ENTER_VALUE).arg("IP Address"), Helper::ok);
      return;
    }
    if (mpManagerPortTextBox->text().isEmpty()) {
      QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                            GUIMessages::getMessage(GUIMessages::ENTER_VALUE).arg("Manager Port"), Helper::ok);
      return;
    }
    if (mpMonitorPortTextBox->text().isEmpty()) {
      QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                            GUIMessages::getMessage(GUIMessages::ENTER_VALUE).arg("Monitor Port"), Helper::ok);
      return;
    }
  } else if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isWCSystem()) {
    if (mpFixedStepSizeTextBox->text().isEmpty()) {
      QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                            GUIMessages::getMessage(GUIMessages::ENTER_VALUE).arg("Fixed Step Size"), Helper::ok);
      return;
    }
  } else { // oms_system_sc

  }

  TLMSystemSimulationInformation tlmSystemSimulationInformation;
  WCSystemSimulationInformation wcSystemSimulationInformation;
  SCSystemSimulationInformation scSystemSimulationInformation;

  if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isTLMSystem()) {
    tlmSystemSimulationInformation.mIpAddress = mpIpAddressTextBox->text();
    tlmSystemSimulationInformation.mManagerPort = mpManagerPortTextBox->text().toInt();
    tlmSystemSimulationInformation.mMonitorPort = mpMonitorPortTextBox->text().toInt();
  } else if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isWCSystem()) {
    wcSystemSimulationInformation.mFixedStepSize = mpFixedStepSizeTextBox->text().toDouble();
    wcSystemSimulationInformation.mTolerance = mpToleranceTextBox->text().toDouble();
  } else { // oms_system_sc

  }
  // system simulation information command
  SystemSimulationInformationCommand *pSystemSimulationInformationCommand;
  pSystemSimulationInformationCommand = new SystemSimulationInformationCommand(&tlmSystemSimulationInformation, &wcSystemSimulationInformation,
                                                                               &scSystemSimulationInformation,
                                                                               mpGraphicsView->getModelWidget()->getLibraryTreeItem());
  mpGraphicsView->getModelWidget()->getUndoStack()->push(pSystemSimulationInformationCommand);
  if (!pSystemSimulationInformationCommand->isFailed()) {
    mpGraphicsView->getModelWidget()->updateModelText();
    accept();
  }
}

