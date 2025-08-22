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

SystemSimulationInformationWidget::SystemSimulationInformationWidget(ModelWidget *pModelWidget)
  : QWidget(pModelWidget)
{
  mpModelWidget = pModelWidget;

  QIntValidator *pIntValidator = new QIntValidator(this);
  QDoubleValidator *pDoubleValidator = new QDoubleValidator(this);

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
    if (OMSProxy::instance()->getVariableStepSize(mpModelWidget->getLibraryTreeItem()->getNameStructure(), &initialStepSize, &minimumStepSize, &maximumStepSize)) {
      mpInitialStepSizeTextBox->setText(QString::number(initialStepSize));
      mpMinimumStepSizeTextBox->setText(QString::number(minimumStepSize));
      mpMaximumStepSizeTextBox->setText(QString::number(maximumStepSize));
    }
#ifdef OMS_HAS_ABSOLUTETOLERANCE
    // absolute tolerance
    mpAbsoluteToleranceLabel = new Label("Absolute Tolerance:");
    mpAbsoluteToleranceTextBox = new QLineEdit;
    mpAbsoluteToleranceTextBox->setValidator(pDoubleValidator);
#endif
    // relative tolerance
    mpRelativeToleranceLabel = new Label("Relative Tolerance:");
    mpRelativeToleranceTextBox = new QLineEdit;
    mpRelativeToleranceTextBox->setValidator(pDoubleValidator);

#ifdef OMS_HAS_ABSOLUTETOLERANCE
    double absoluteTolerance, relativeTolerance;
    if (OMSProxy::instance()->getTolerance(mpModelWidget->getLibraryTreeItem()->getNameStructure(), &absoluteTolerance, &relativeTolerance)) {
      mpAbsoluteToleranceTextBox->setText(QString::number(absoluteTolerance));
      mpRelativeToleranceTextBox->setText(QString::number(relativeTolerance));
    }
#else
    double relativeTolerance;
    if (OMSProxy::instance()->getTolerance(mpModelWidget->getLibraryTreeItem()->getNameStructure(),&relativeTolerance)) {
      mpRelativeToleranceTextBox->setText(QString::number(relativeTolerance));
    }
#endif
  }

  if (mpModelWidget->getLibraryTreeItem()->isWCSystem()) { // oms_system_wc
    mpSolverComboBox->addItem("oms-ma", oms_solver_wc_ma);
    mpSolverComboBox->addItem("oms-mav", oms_solver_wc_mav);
    mpSolverComboBox->addItem("oms-mav-2", oms_solver_wc_mav2);
  } else if (mpModelWidget->getLibraryTreeItem()->isSCSystem()) { // oms_system_sc
    mpSolverComboBox->addItem("cvode", oms_solver_sc_cvode);
    mpSolverComboBox->addItem("explicit-euler", oms_solver_sc_explicit_euler);
  }

  if (mpModelWidget->getLibraryTreeItem()->isWCSystem() || mpModelWidget->getLibraryTreeItem()->isSCSystem()) {
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
  if (mpModelWidget->getLibraryTreeItem()->isWCSystem() || mpModelWidget->getLibraryTreeItem()->isSCSystem()) {
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
#ifdef OMS_HAS_ABSOLUTETOLERANCE
    pMainLayout->addWidget(mpAbsoluteToleranceLabel, row, 0);
    pMainLayout->addWidget(mpAbsoluteToleranceTextBox, row++, 1);
#endif
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
 * \param pushOnStack
 * \return
 */
bool SystemSimulationInformationWidget::setSystemSimulationInformation(bool pushOnStack)
{
  if (mpModelWidget->getLibraryTreeItem()->isWCSystem() || mpModelWidget->getLibraryTreeItem()->isSCSystem()) {
    oms_solver_enu_t solver = (oms_solver_enu_t)mpSolverComboBox->itemData(mpSolverComboBox->currentIndex()).toInt();
    switch (solver) {
      case oms_solver_wc_mav:
      case oms_solver_wc_mav2:
      case oms_solver_sc_cvode:
        if (mpInitialStepSizeTextBox->text().isEmpty()) {
          QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                                GUIMessages::getMessage(GUIMessages::ENTER_VALUE).arg("Initial Step Size"), QMessageBox::Ok);
          return false;
        }
        if (mpMinimumStepSizeTextBox->text().isEmpty()) {
          QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                                GUIMessages::getMessage(GUIMessages::ENTER_VALUE).arg("Minimum Step Size"), QMessageBox::Ok);
          return false;
        }
        if (mpMaximumStepSizeTextBox->text().isEmpty()) {
          QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                                GUIMessages::getMessage(GUIMessages::ENTER_VALUE).arg("Maximum Step Size"), QMessageBox::Ok);
          return false;
        }
        break;
      case oms_solver_wc_ma:
      case oms_solver_sc_explicit_euler:
      default:
        if (mpFixedStepSizeTextBox->text().isEmpty()) {
          QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                                GUIMessages::getMessage(GUIMessages::ENTER_VALUE).arg("Fixed Step Size"), QMessageBox::Ok);
          return false;
        }
        break;
    }
#ifdef OMS_HAS_ABSOLUTETOLERANCE
    if (mpAbsoluteToleranceTextBox->text().isEmpty()) {
      QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                            GUIMessages::getMessage(GUIMessages::ENTER_VALUE).arg("Absolute Tolerance"), QMessageBox::Ok);
      return false;
    }
#endif

    if (mpRelativeToleranceTextBox->text().isEmpty()) {
      QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                            GUIMessages::getMessage(GUIMessages::ENTER_VALUE).arg("Relative Tolerance"), QMessageBox::Ok);
      return false;
    }
  }

  LibraryTreeItem *pLibraryTreeItem = mpModelWidget->getLibraryTreeItem();
  const QString cref = pLibraryTreeItem->getNameStructure();
  if (pLibraryTreeItem->isWCSystem() || pLibraryTreeItem->isSCSystem()) {
    // set solver
    oms_solver_enu_t solver = (oms_solver_enu_t)mpSolverComboBox->itemData(mpSolverComboBox->currentIndex()).toInt();
    if (!OMSProxy::instance()->setSolver(cref, solver)) {
      return false;
    }
    // set step size
    switch (solver) {
      case oms_solver_wc_mav:
      case oms_solver_wc_mav2:
      case oms_solver_sc_cvode:
        if (!OMSProxy::instance()->setVariableStepSize(cref, mpInitialStepSizeTextBox->text().toDouble(), mpMinimumStepSizeTextBox->text().toDouble(),
                                                       mpMaximumStepSizeTextBox->text().toDouble())) {
          return false;
        }
        break;
      case oms_solver_wc_ma:
      case oms_solver_sc_explicit_euler:
      default:
        if (!OMSProxy::instance()->setFixedStepSize(cref, mpFixedStepSizeTextBox->text().toDouble())) {
          return false;
        }
        break;
    }
    // set tolerance
#ifdef OMS_HAS_ABSOLUTETOLERANCE
    if (!OMSProxy::instance()->setTolerance(cref, mpAbsoluteToleranceTextBox->text().toDouble(), mpRelativeToleranceTextBox->text().toDouble())) {
#else
    if (!OMSProxy::instance()->setTolerance(cref, mpRelativeToleranceTextBox->text().toDouble())) {
#endif
      return false;
    }

  }
  // push on stack
  if (pushOnStack) {
    mpModelWidget->createOMSimulatorUndoCommand(QString("System %1 simulation information").arg(cref));
    mpModelWidget->updateModelText();
  }
  return true;
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
  setWindowTitle(QString("%1 - %2 - %3").arg(Helper::applicationName, Helper::systemSimulationInformation, pModelWidget->getLibraryTreeItem()->getName()));
  setAttribute(Qt::WA_DeleteOnClose);
  // set heading
  mpHeading = Utilities::getHeadingLabel(QString("%1 - %2").arg(Helper::systemSimulationInformation, pModelWidget->getLibraryTreeItem()->getName()));
  // set separator line
  mpHorizontalLine = Utilities::getHeadingLine();
  // system simulation information widget
  mpSystemSimulationInformationWidget = new SystemSimulationInformationWidget(pModelWidget);
  // buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  mpOkButton->setEnabled(!pModelWidget->getLibraryTreeItem()->isSystemLibrary());
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
  if (mpSystemSimulationInformationWidget->setSystemSimulationInformation(true)) {
    accept();
  }
}
