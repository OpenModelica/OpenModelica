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

WCSCSystemSimulationInformation::WCSCSystemSimulationInformation()
{
  mDescription = oms_solver_none;
  mFixedStepSize = 0.0;
  mInitialStepSize = 0.0;
  mMinimumStepSize = 0.0;
  mMaximumStepSize = 0.0;
  mAbsoluteTolerance = 0.0;
  mRelativeTolerance = 0.0;
}

SystemSimulationInformationWidget::SystemSimulationInformationWidget(ModelWidget *pModelWidget)
  : QWidget(pModelWidget)
{
  mpModelWidget = pModelWidget;

  QIntValidator *pIntValidator = new QIntValidator(this);
  QDoubleValidator *pDoubleValidator = new QDoubleValidator(this);

  if (mpModelWidget->getLibraryTreeItem()->isTLMSystem()) {
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
  }

  if (mpModelWidget->getLibraryTreeItem()->isWCSystem() || mpModelWidget->getLibraryTreeItem()->isSCSystem()) {
    // solver
    mpSolverLabel = new Label(tr("Solver:"));
    mpSolverComboBox = new QComboBox;
    // fixed step size
    mpFixedStepSizeLabel = new Label(tr("Fixed Step Size:"));
    mpFixedStepSizeTextBox = new QLineEdit;
    mpFixedStepSizeTextBox->setValidator(pDoubleValidator);

    double fixedStepSize;
    if (OMSProxy::instance()->getFixedStepSize(mpModelWidget->getLibraryTreeItem()->getNameStructure(), &fixedStepSize)) {
      mpFixedStepSizeTextBox->setText(QString::number(fixedStepSize));
    }
    // initial step size
    mpInitialStepSizeLabel = new Label(tr("Initial Step Size:"));
    mpInitialStepSizeTextBox = new QLineEdit;
    mpInitialStepSizeTextBox->setValidator(pDoubleValidator);
    // minimum step size
    mpMinimumStepSizeLabel = new Label(tr("Minimum Step Size:"));
    mpMinimumStepSizeTextBox = new QLineEdit;
    mpMinimumStepSizeTextBox->setValidator(pDoubleValidator);
    // maximum step size
    mpMaximumStepSizeLabel = new Label(tr("Maximum Step Size:"));
    mpMaximumStepSizeTextBox = new QLineEdit;
    mpMaximumStepSizeTextBox->setValidator(pDoubleValidator);

    double initialStepSize, minimumStepSize, maximumStepSize;
    if (OMSProxy::instance()->getVariableStepSize(mpModelWidget->getLibraryTreeItem()->getNameStructure(),
                                                  &initialStepSize, &minimumStepSize, &maximumStepSize)) {
      mpInitialStepSizeTextBox->setText(QString::number(initialStepSize));
      mpMinimumStepSizeTextBox->setText(QString::number(minimumStepSize));
      mpMaximumStepSizeTextBox->setText(QString::number(maximumStepSize));
    }
    // absolute tolerance
    mpAbsoluteToleranceLabel = new Label("Absolute Tolerance:");
    mpAbsoluteToleranceTextBox = new QLineEdit;
    mpAbsoluteToleranceTextBox->setValidator(pDoubleValidator);
    // relative tolerance
    mpRelativeToleranceLabel = new Label("Relative Tolerance:");
    mpRelativeToleranceTextBox = new QLineEdit;
    mpRelativeToleranceTextBox->setValidator(pDoubleValidator);

    double absoluteTolerance, relativeTolerance;
    if (OMSProxy::instance()->getTolerance(mpModelWidget->getLibraryTreeItem()->getNameStructure(), &absoluteTolerance, &relativeTolerance)) {
      mpAbsoluteToleranceTextBox->setText(QString::number(absoluteTolerance));
      mpRelativeToleranceTextBox->setText(QString::number(relativeTolerance));
    }
  }

  if (mpModelWidget->getLibraryTreeItem()->isWCSystem()) { // oms_system_wc
    mpSolverComboBox->addItem("oms-ma", oms_solver_wc_ma);
    mpSolverComboBox->addItem("oms-mav", oms_solver_wc_mav);
    mpSolverComboBox->addItem("oms-mav-2", oms_solver_wc_mav2);
  } else if (mpModelWidget->getLibraryTreeItem()->isSCSystem()) { // oms_system_sc
    mpSolverComboBox->addItem("cvode", oms_solver_sc_cvode);
    mpSolverComboBox->addItem("explicit-euler", oms_solver_sc_explicit_euler);
  }

  if (mpModelWidget->getLibraryTreeItem()->isWCSystem()
      || mpModelWidget->getLibraryTreeItem()->isSCSystem()) {
    oms_solver_enu_t solver;
    if (OMSProxy::instance()->getSolver(mpModelWidget->getLibraryTreeItem()->getNameStructure(), &solver)) {
      int currentIndex = mpSolverComboBox->findData(solver);
      if (currentIndex > -1) {
        mpSolverComboBox->setCurrentIndex(currentIndex);
      }
    }
    // update based on selected solver
    connect(mpSolverComboBox, SIGNAL(currentIndexChanged(int)), SLOT(solverChanged(int)));
    solverChanged(mpSolverComboBox->currentIndex());
  }
  // set the layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  int row = 0;
  if (mpModelWidget->getLibraryTreeItem()->isTLMSystem()) {
    pMainLayout->addWidget(mpIpAddressLabel, row, 0);
    pMainLayout->addWidget(mpIpAddressTextBox, row++, 1);
    pMainLayout->addWidget(mpManagerPortLabel, row, 0);
    pMainLayout->addWidget(mpManagerPortTextBox, row++, 1);
    pMainLayout->addWidget(mpMonitorPortLabel, row, 0);
    pMainLayout->addWidget(mpMonitorPortTextBox, row++, 1);
  } else if (mpModelWidget->getLibraryTreeItem()->isWCSystem() || mpModelWidget->getLibraryTreeItem()->isSCSystem()) {
    pMainLayout->addWidget(mpSolverLabel, row, 0);
    pMainLayout->addWidget(mpSolverComboBox, row++, 1);
    pMainLayout->addWidget(mpFixedStepSizeLabel, row, 0);
    pMainLayout->addWidget(mpFixedStepSizeTextBox, row++, 1);
    pMainLayout->addWidget(mpInitialStepSizeLabel, row, 0);
    pMainLayout->addWidget(mpInitialStepSizeTextBox, row++, 1);
    pMainLayout->addWidget(mpMinimumStepSizeLabel, row, 0);
    pMainLayout->addWidget(mpMinimumStepSizeTextBox, row++, 1);
    pMainLayout->addWidget(mpMaximumStepSizeLabel, row, 0);
    pMainLayout->addWidget(mpMaximumStepSizeTextBox, row++, 1);
    pMainLayout->addWidget(mpAbsoluteToleranceLabel, row, 0);
    pMainLayout->addWidget(mpAbsoluteToleranceTextBox, row++, 1);
    pMainLayout->addWidget(mpRelativeToleranceLabel, row, 0);
    pMainLayout->addWidget(mpRelativeToleranceTextBox, row++, 1);
  }
  setLayout(pMainLayout);
}

/*!
 * \brief SystemSimulationInformationWidget::solverChanged
 * Slot activated when mpSolverComboBox currentIndexChanged SIGNAL is raised.
 * Enables the step size controls based on the selected solver.
 * \param index
 */
void SystemSimulationInformationWidget::solverChanged(int index)
{
  oms_solver_enu_t solver = (oms_solver_enu_t)mpSolverComboBox->itemData(index).toInt();

  switch (solver) {
    case oms_solver_wc_mav:
    case oms_solver_wc_mav2:
    case oms_solver_sc_cvode:
      mpInitialStepSizeTextBox->setEnabled(true);
      mpMinimumStepSizeTextBox->setEnabled(true);
      mpMaximumStepSizeTextBox->setEnabled(true);
      mpFixedStepSizeTextBox->setEnabled(false);
      break;
    case oms_solver_wc_ma:
    case oms_solver_sc_explicit_euler:
    default:
      mpInitialStepSizeTextBox->setEnabled(false);
      mpMinimumStepSizeTextBox->setEnabled(false);
      mpMaximumStepSizeTextBox->setEnabled(false);
      mpFixedStepSizeTextBox->setEnabled(true);
      break;
  }
}

/*!
 * \brief SystemSimulationInformationWidget::setSystemSimulationInformation
 * Sets the simulation information of the system.
 * \return
 */
bool SystemSimulationInformationWidget::setSystemSimulationInformation()
{
  if (mpModelWidget->getLibraryTreeItem()->isTLMSystem()) {
    if (mpIpAddressTextBox->text().isEmpty()) {
      QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                            GUIMessages::getMessage(GUIMessages::ENTER_VALUE).arg("IP Address"), Helper::ok);
      return false;
    }
    if (mpManagerPortTextBox->text().isEmpty()) {
      QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                            GUIMessages::getMessage(GUIMessages::ENTER_VALUE).arg("Manager Port"), Helper::ok);
      return false;
    }
    if (mpMonitorPortTextBox->text().isEmpty()) {
      QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                            GUIMessages::getMessage(GUIMessages::ENTER_VALUE).arg("Monitor Port"), Helper::ok);
      return false;
    }
  } else if (mpModelWidget->getLibraryTreeItem()->isWCSystem()
             || mpModelWidget->getLibraryTreeItem()->isSCSystem()) {

    oms_solver_enu_t solver = (oms_solver_enu_t)mpSolverComboBox->itemData(mpSolverComboBox->currentIndex()).toInt();
    switch (solver) {
      case oms_solver_wc_mav:
      case oms_solver_wc_mav2:
      case oms_solver_sc_cvode:
        if (mpInitialStepSizeTextBox->text().isEmpty()) {
          QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                                GUIMessages::getMessage(GUIMessages::ENTER_VALUE).arg("Initial Step Size"), Helper::ok);
          return false;
        }
        if (mpMinimumStepSizeTextBox->text().isEmpty()) {
          QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                                GUIMessages::getMessage(GUIMessages::ENTER_VALUE).arg("Minimum Step Size"), Helper::ok);
          return false;
        }
        if (mpMaximumStepSizeTextBox->text().isEmpty()) {
          QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                                GUIMessages::getMessage(GUIMessages::ENTER_VALUE).arg("Maximum Step Size"), Helper::ok);
          return false;
        }
        break;
      case oms_solver_wc_ma:
      case oms_solver_sc_explicit_euler:
      default:
        if (mpFixedStepSizeTextBox->text().isEmpty()) {
          QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                                GUIMessages::getMessage(GUIMessages::ENTER_VALUE).arg("Fixed Step Size"), Helper::ok);
          return false;
        }
        break;
    }

    if (mpAbsoluteToleranceTextBox->text().isEmpty()) {
      QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                            GUIMessages::getMessage(GUIMessages::ENTER_VALUE).arg("Absolute Tolerance"), Helper::ok);
      return false;
    }

    if (mpRelativeToleranceTextBox->text().isEmpty()) {
      QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                            GUIMessages::getMessage(GUIMessages::ENTER_VALUE).arg("Relative Tolerance"), Helper::ok);
      return false;
    }
  }

  TLMSystemSimulationInformation tlmSystemSimulationInformation;
  WCSCSystemSimulationInformation wcscSystemSimulationInformation;

  if (mpModelWidget->getLibraryTreeItem()->isTLMSystem()) {
    tlmSystemSimulationInformation.mIpAddress = mpIpAddressTextBox->text();
    tlmSystemSimulationInformation.mManagerPort = mpManagerPortTextBox->text().toInt();
    tlmSystemSimulationInformation.mMonitorPort = mpMonitorPortTextBox->text().toInt();
  } else if (mpModelWidget->getLibraryTreeItem()->isWCSystem() || mpModelWidget->getLibraryTreeItem()->isSCSystem()) {
    wcscSystemSimulationInformation.mDescription = (oms_solver_enu_t)mpSolverComboBox->itemData(mpSolverComboBox->currentIndex()).toInt();
    wcscSystemSimulationInformation.mFixedStepSize = mpFixedStepSizeTextBox->text().toDouble();
    wcscSystemSimulationInformation.mInitialStepSize = mpInitialStepSizeTextBox->text().toDouble();
    wcscSystemSimulationInformation.mMinimumStepSize = mpMinimumStepSizeTextBox->text().toDouble();
    wcscSystemSimulationInformation.mMaximumStepSize = mpMaximumStepSizeTextBox->text().toDouble();
    wcscSystemSimulationInformation.mAbsoluteTolerance = mpAbsoluteToleranceTextBox->text().toDouble();
    wcscSystemSimulationInformation.mRelativeTolerance = mpRelativeToleranceTextBox->text().toDouble();
  }
  // system simulation information command
  SystemSimulationInformationCommand *pSystemSimulationInformationCommand;
  pSystemSimulationInformationCommand = new SystemSimulationInformationCommand(&tlmSystemSimulationInformation,
                                                                               &wcscSystemSimulationInformation,
                                                                               mpModelWidget->getLibraryTreeItem());
  mpModelWidget->getUndoStack()->push(pSystemSimulationInformationCommand);
  if (!pSystemSimulationInformationCommand->isFailed()) {
    mpModelWidget->updateModelText();
    return true;
  }
  return false;
}

/*!
 * \class SystemSimulationInformationDialog
 * \brief A dialog for system simulation information.
 */
/*!
 * \brief SystemSimulationInformationDialog::SystemSimulationInformationDialog
 * \param pModelWidget
 */
SystemSimulationInformationDialog::SystemSimulationInformationDialog(ModelWidget *pModelWidget)
  : QDialog(pModelWidget)
{
  setWindowTitle(QString("%1 - %2 - %3").arg(Helper::applicationName, Helper::systemSimulationInformation,
                                             pModelWidget->getLibraryTreeItem()->getName()));
  setAttribute(Qt::WA_DeleteOnClose);
  // set heading
  mpHeading = Utilities::getHeadingLabel(QString("%1 - %2").arg(Helper::systemSimulationInformation,
                                                                pModelWidget->getLibraryTreeItem()->getName()));
  // set separator line
  mpHorizontalLine = Utilities::getHeadingLine();
  // system simulation information widget
  mpSystemSimulationInformationWidget = new SystemSimulationInformationWidget(pModelWidget);
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
  pMainLayout->addWidget(mpSystemSimulationInformationWidget, 2, 0, 1, 2);
  pMainLayout->addWidget(mpButtonBox, 3, 0, 1, 2, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
 * \brief SystemSimulationInformationDialog::setSystemSimulationInformation
 * Sets the simulation information of the system.
 */
void SystemSimulationInformationDialog::setSystemSimulationInformation()
{
  if (mpSystemSimulationInformationWidget->setSystemSimulationInformation()) {
    accept();
  }
}
