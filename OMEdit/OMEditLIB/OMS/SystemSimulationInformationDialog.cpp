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

#include "SystemSimulationInformationDialog.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/Commands.h"
#include "OMS/OMSProxy.h"
#include "OMS/OMSModel.h"
#include "Util/Helper.h"

#include <QGridLayout>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QGroupBox>
#include <QHeaderView>
#include <QMessageBox>


SolverSettingsDialog::SolverSettingsDialog(const QString &solverName, const QString &method, const QJsonObject &solverSettings, QWidget *pParent)
  : QDialog(pParent), mMethod(method)
{
  setWindowTitle(tr("SolverSettings - %1 (%2)").arg(solverName, method));

  QDoubleValidator *pDoubleValidator = new QDoubleValidator(this);

  // fixed step size
  mpFixedStepSizeLabel = new Label(tr("Fixed Step Size:"));
  mpFixedStepSizeTextBox = new QLineEdit;
  mpFixedStepSizeTextBox->setValidator(pDoubleValidator);
  mpFixedStepSizeTextBox->setText(solverSettings["fixedStepSize"].toString());
  // initial step size
  mpInitialStepSizeLabel = new Label(tr("Initial Step Size:"));
  mpInitialStepSizeTextBox = new QLineEdit;
  mpInitialStepSizeTextBox->setValidator(pDoubleValidator);
  //if (solverSettings.contains("initialStepSize"))
  mpInitialStepSizeTextBox->setText(solverSettings["initialStepSize"].toString());
  // minimum step size
  mpMinimumStepSizeLabel = new Label(tr("Minimum Step Size:"));
  mpMinimumStepSizeTextBox = new QLineEdit;
  mpMinimumStepSizeTextBox->setValidator(pDoubleValidator);
  mpMinimumStepSizeTextBox->setText(solverSettings["minimumStepSize"].toString());
  // maximum step size
  mpMaximumStepSizeLabel = new Label(tr("Maximum Step Size:"));
  mpMaximumStepSizeTextBox = new QLineEdit;
  mpMaximumStepSizeTextBox->setValidator(pDoubleValidator);
  mpMaximumStepSizeTextBox->setText(solverSettings["maximumStepSize"].toString());
  // relative tolerance
  mpRelativeToleranceLabel = new Label("Relative Tolerance:");
  mpRelativeToleranceTextBox = new QLineEdit;
  mpRelativeToleranceTextBox->setValidator(pDoubleValidator);
  mpRelativeToleranceTextBox->setText(solverSettings["relativeTolerance"].toString());

  if (SystemSimulationInformationWidget::isVariableStepSizeSolver(mMethod)) {
    mpFixedStepSizeTextBox->setEnabled(false);
  } else {
    mpInitialStepSizeTextBox->setEnabled(false);
    mpMinimumStepSizeTextBox->setEnabled(false);
    mpMaximumStepSizeTextBox->setEnabled(false);
  }

  // set the layout
  QGridLayout *pMainLayout = new QGridLayout;
  int row = 0;
  pMainLayout->addWidget(mpFixedStepSizeLabel, row, 0);
  pMainLayout->addWidget(mpFixedStepSizeTextBox, row++, 1);
  pMainLayout->addWidget(mpInitialStepSizeLabel, row, 0);
  pMainLayout->addWidget(mpInitialStepSizeTextBox, row++, 1);
  pMainLayout->addWidget(mpMinimumStepSizeLabel, row, 0);
  pMainLayout->addWidget(mpMinimumStepSizeTextBox, row++, 1);
  pMainLayout->addWidget(mpMaximumStepSizeLabel, row, 0);
  pMainLayout->addWidget(mpMaximumStepSizeTextBox, row++, 1);
  pMainLayout->addWidget(mpRelativeToleranceLabel, row, 0);
  pMainLayout->addWidget(mpRelativeToleranceTextBox, row++, 1);

  QDialogButtonBox *pButtons = new QDialogButtonBox(QDialogButtonBox::Ok | QDialogButtonBox::Cancel);
  connect(pButtons, &QDialogButtonBox::accepted, this, &QDialog::accept);
  connect(pButtons, &QDialogButtonBox::rejected, this, &QDialog::reject);
  pMainLayout->addWidget(pButtons, row, 0, 1, 2);
  setLayout(pMainLayout);
}

QJsonObject SolverSettingsDialog::getSolverSettings() const
{
  const QMap<QString, QLineEdit*> keyToWidget = {
    {"fixedStepSize",      mpFixedStepSizeTextBox},
    {"initialStepSize",    mpInitialStepSizeTextBox},
    {"minimumStepSize",    mpMinimumStepSizeTextBox},
    {"maximumStepSize",    mpMaximumStepSizeTextBox},
    {"relativeTolerance",  mpRelativeToleranceTextBox},
  };

  QJsonObject solverSettings;
  for (const QString &key : SystemSimulationInformationWidget::solverSettingsKeys(mMethod)) {
    QLineEdit *pLineEditWidget = keyToWidget.value(key, nullptr);
    solverSettings[key] = pLineEditWidget ? pLineEditWidget->text() : "";
  }
  return solverSettings;
}

// ---------------------------------------------------------------------------
// SystemSimulationInformationWidget
// ---------------------------------------------------------------------------

SystemSimulationInformationWidget::SystemSimulationInformationWidget(ModelWidget *pModelWidget)
  : QWidget(pModelWidget)
{
  mpModelWidget = pModelWidget;

  // --- Solver configurations table: Name | Method | Parameters ---
  mpSolversTable = new QTableWidget(0, 2, this);
  mpSolversTable->setHorizontalHeaderLabels({tr("Name"), tr("Method")});
  mpSolversTable->horizontalHeader()->setSectionResizeMode(QHeaderView::Stretch);
  mpSolversTable->setSelectionBehavior(QAbstractItemView::SelectRows);
  mpSolversTable->setSelectionMode(QAbstractItemView::SingleSelection);

  mpAddSolverButton    = new QPushButton(tr("Add"));
  mpRemoveSolverButton = new QPushButton(tr("Remove"));
  mpEditSolverButton   = new QPushButton(tr("Edit"));
  connect(mpAddSolverButton,    &QPushButton::clicked, this, &SystemSimulationInformationWidget::addSolver);
  connect(mpRemoveSolverButton, &QPushButton::clicked, this, &SystemSimulationInformationWidget::removeSolver);
  connect(mpEditSolverButton,   &QPushButton::clicked, this, &SystemSimulationInformationWidget::editSolverParameters);

  QHBoxLayout *pSolverButtonsLayout = new QHBoxLayout;
  pSolverButtonsLayout->addWidget(mpAddSolverButton);
  pSolverButtonsLayout->addWidget(mpRemoveSolverButton);
  pSolverButtonsLayout->addWidget(mpEditSolverButton);
  pSolverButtonsLayout->addStretch();

  QGroupBox *pSolversGroup = new QGroupBox(tr("Solver Configurations"));
  QVBoxLayout *pSolversGroupLayout = new QVBoxLayout;
  pSolversGroupLayout->addWidget(mpSolversTable);
  pSolversGroupLayout->addLayout(pSolverButtonsLayout);
  pSolversGroup->setLayout(pSolversGroupLayout);

  // --- Component assignments table: Component | Solver ---
  mpAssignmentsTable = new QTableWidget(0, 2, this);
  mpAssignmentsTable->setHorizontalHeaderLabels({tr("Component"), tr("Solver")});
  mpAssignmentsTable->horizontalHeader()->setSectionResizeMode(QHeaderView::Stretch);
  mpAssignmentsTable->setEditTriggers(QAbstractItemView::NoEditTriggers);

  QGroupBox *pAssignmentsGroup = new QGroupBox(tr("Component Assignments"));
  QVBoxLayout *pAssignmentsGroupLayout = new QVBoxLayout;
  pAssignmentsGroupLayout->addWidget(mpAssignmentsTable);
  pAssignmentsGroup->setLayout(pAssignmentsGroupLayout);

  // Fetch current settings and populate
  QJsonObject settings;
  if (OMSProxy::instance()->getSolverSettings(mpModelWidget->getLibraryTreeItem()->getNameStructure(), settings)) {
    const QJsonArray solvers = settings["solvers"].toArray();

    // Populate solvers table
    for (const QJsonValue &sv : solvers) {
      QJsonObject s = sv.toObject();
      // Solver settings are stored flat in the solver object — extract all fields except name/method
      QJsonObject solverParams;
      for (auto it = s.constBegin(); it != s.constEnd(); ++it) {
        if (it.key() != "name" && it.key() != "method")
          solverParams[it.key()] = it.value();
      }
      addSolverRow(s["name"].toString(), s["method"].toString("oms-ma"), solverParams);
    }

    // Populate assignments table — iterate root system's children (the actual FMU components)
    const QJsonObject assignments = settings["assignments"].toObject();
    LibraryTreeItem *pRootItem = mpModelWidget->getLibraryTreeItem();
    populateComponentAssignments(pRootItem, solvers, assignments);
  }

  // Main layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->addWidget(pSolversGroup);
  pMainLayout->addWidget(pAssignmentsGroup);
  setLayout(pMainLayout);
}

void SystemSimulationInformationWidget::populateComponentAssignments(LibraryTreeItem *pLibraryTreeItem, const QJsonArray &solvers, const QJsonObject &assignments)
{
  if (!pLibraryTreeItem || !pLibraryTreeItem->getOMSModelElement()) {
    return;
  }

  if (pLibraryTreeItem->isComponentElement()) {
    const QString displayName = pLibraryTreeItem->getName();
    int row = mpAssignmentsTable->rowCount();
    mpAssignmentsTable->insertRow(row);

    QTableWidgetItem *pComponentItem = new QTableWidgetItem(displayName);
    pComponentItem->setData(Qt::UserRole, displayName);
    pComponentItem->setToolTip(pLibraryTreeItem->getNameStructure());
    mpAssignmentsTable->setItem(row, 0, pComponentItem);

    QComboBox *pSolverCombo = new QComboBox;
    pSolverCombo->addItem(tr("(none)"), "");

    for (const QJsonValue &sv : solvers) {
      const QString solverName = sv.toObject()["name"].toString();
      pSolverCombo->addItem(solverName, solverName);
    }

    const QString assigned = assignments.value(displayName).toString();
    int sidx = pSolverCombo->findData(assigned);
    if (sidx > -1)
      pSolverCombo->setCurrentIndex(sidx);

    mpAssignmentsTable->setCellWidget(row, 1, pSolverCombo);
  }
  // recurse the subsystems
  for (int i = 0; i < pLibraryTreeItem->childrenSize(); ++i) {
    populateComponentAssignments(pLibraryTreeItem->childAt(i), solvers, assignments);
  }
}

bool SystemSimulationInformationWidget::isVariableStepSizeSolver(const QString &method)
{
  return method == "oms-mav" || method == "oms-mav-2" || method == "cvode";
}

QStringList SystemSimulationInformationWidget::variableStepSizeSolverKeys()
{
  return {"initialStepSize", "minimumStepSize", "maximumStepSize", "relativeTolerance"};
}

QStringList SystemSimulationInformationWidget::fixedStepSizeSolverKeys()
{
  return {"fixedStepSize", "relativeTolerance"};
}

QStringList SystemSimulationInformationWidget::solverSettingsKeys(const QString &method)
{
  return isVariableStepSizeSolver(method) ? variableStepSizeSolverKeys() : fixedStepSizeSolverKeys();
}

/*!
 * Fetch step-size and tolerance defaults for a solver from the Python server.
 * For a new (unnamed) solver pass an empty solverName — the server returns the
 * model-level defaults.  For an existing solver pass its name so the server can
 * return its persisted values.
 */
QJsonObject SystemSimulationInformationWidget::fetchDefaultSolverSettings(const QString &solverName)
{
  const QString cref = mpModelWidget->getLibraryTreeItem()->getNameStructure();
  QJsonObject solverSettings;

  double relativeTolerance;
  if (OMSProxy::instance()->getTolerance(cref, relativeTolerance))
    solverSettings["relativeTolerance"] = QString::number(relativeTolerance);

  double initialStepSize , minimumStepSize, maximumStepSize;
  if (OMSProxy::instance()->getVariableStepSize(cref, solverName, initialStepSize, minimumStepSize, maximumStepSize)) {
    solverSettings["initialStepSize"] = QString::number(initialStepSize);
    solverSettings["minimumStepSize"] = QString::number(minimumStepSize);
    solverSettings["maximumStepSize"] = QString::number(maximumStepSize);
  }

  double fixedStepSize;
  if (OMSProxy::instance()->getFixedStepSize(cref, fixedStepSize))
    solverSettings["fixedStepSize"] = QString::number(fixedStepSize);

  return solverSettings;
}

void SystemSimulationInformationWidget::addSolver()
{
  const QString defaultMethod = "oms-ma";
  const QString newName = QString("solver%1").arg(mpSolversTable->rowCount() + 1);
  // Fetch model-level defaults and add the row directly — user can Edit afterwards
  QJsonObject defaultSolverSettings = fetchDefaultSolverSettings(defaultMethod);
  addSolverRow(newName, defaultMethod, defaultSolverSettings);
  populateSolverCombos();
}

void SystemSimulationInformationWidget::addSolverRow(const QString &name, const QString &method, const QJsonObject &params)
{
  const int row = mpSolversTable->rowCount();
  mpSolversTable->insertRow(row);

  QTableWidgetItem *pNameItem = new QTableWidgetItem(name);
  pNameItem->setData(Qt::UserRole, params);
  mpSolversTable->setItem(row, 0, pNameItem);

  QComboBox *pMethodCombo = new QComboBox;
  pMethodCombo->addItem("oms-ma", "oms-ma");
  pMethodCombo->addItem("oms-mav", "oms-mav");
  pMethodCombo->addItem("oms-mav-2", "oms-mav-2");
  pMethodCombo->addItem("euler", "euler");
  pMethodCombo->addItem("cvode", "cvode");
  int index = pMethodCombo->findData(method);
  if (index > -1) {
    pMethodCombo->setCurrentIndex(index);
  }
  mpSolversTable->setCellWidget(row, 1, pMethodCombo);
}

void SystemSimulationInformationWidget::editSolverParameters()
{
  const int row = mpSolversTable->currentRow();
  if (row < 0)
    return;

  QTableWidgetItem *pNameItem = mpSolversTable->item(row, 0);
  QComboBox *pMethodCombo = qobject_cast<QComboBox*>(mpSolversTable->cellWidget(row, 1));
  if (!pNameItem || !pMethodCombo)
    return;

  const QString solverName = pNameItem->text();
  const QString solverMethod = pMethodCombo->currentData().toString();
  // Use the stored params for editing — they reflect what the user last set.
  QJsonObject solverSettings = pNameItem->data(Qt::UserRole).toJsonObject();
  // Fill in any keys required by the current method that are missing (e.g. when
  // the user switched from a fixed-step to a variable-step solver in the table
  // before opening Edit — the stored params won't have initialStepSize etc.).
  const QJsonObject defaults = fetchDefaultSolverSettings(solverName);
  for (auto it = defaults.constBegin(); it != defaults.constEnd(); ++it) {
    if (!solverSettings.contains(it.key()) || solverSettings[it.key()].toString().isEmpty())
      solverSettings[it.key()] = it.value();
  }

  SolverSettingsDialog pSolverSettingsDialog(solverName, solverMethod, solverSettings, this);
  if (pSolverSettingsDialog.exec() == QDialog::Accepted) {
    pNameItem->setData(Qt::UserRole, pSolverSettingsDialog.getSolverSettings());
  }
}

void SystemSimulationInformationWidget::removeSolver()
{
  const int row = mpSolversTable->currentRow();
  if (row < 0)
    return;
  mpSolversTable->removeRow(row);
  populateSolverCombos();
}

void SystemSimulationInformationWidget::populateSolverCombos()
{
  // Collect current solver names from the table
  QStringList solverNames;
  for (int r = 0; r < mpSolversTable->rowCount(); ++r) {
    QTableWidgetItem *item = mpSolversTable->item(r, 0);
    if (item)
      solverNames << item->text();
  }

  // Rebuild assignment combos, preserving the current selection
  for (int r = 0; r < mpAssignmentsTable->rowCount(); ++r) {
    QComboBox *pCombo = qobject_cast<QComboBox*>(mpAssignmentsTable->cellWidget(r, 1));
    if (!pCombo)
      continue;
    const QString current = pCombo->currentData().toString();
    pCombo->clear();
    pCombo->addItem(tr("(none)"), "");
    for (const QString &name : solverNames)
      pCombo->addItem(name, name);
    int idx = pCombo->findData(current);
    if (idx > -1)
      pCombo->setCurrentIndex(idx);
  }
}

// ---------------------------------------------------------------------------

bool SystemSimulationInformationWidget::setSystemSimulationInformation(bool pushOnStack)
{
  // Validate — every solver row must have a non-empty name
  for (int r = 0; r < mpSolversTable->rowCount(); ++r) {
    QTableWidgetItem *nameItem = mpSolversTable->item(r, 0);
    if (!nameItem || nameItem->text().trimmed().isEmpty()) {
      QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), tr("Solver name in row %1 is empty.").arg(r + 1), QMessageBox::Ok);
      return false;
    }
  }

  // Build solvers array
  QJsonArray solversArray;
  for (int r = 0; r < mpSolversTable->rowCount(); ++r) {
    QTableWidgetItem *pNameItem = mpSolversTable->item(r, 0);
    QComboBox *pMethodCombo = qobject_cast<QComboBox*>(mpSolversTable->cellWidget(r, 1));
    if (!pNameItem)
      continue;
    QJsonObject solver;
    solver["name"] = pNameItem->text().trimmed();
    solver["method"] = pMethodCombo ? pMethodCombo->currentData().toString() : "oms-ma";
    // Append only the relevant step-size fields for the chosen method
    const QJsonObject solverSettings = pNameItem->data(Qt::UserRole).toJsonObject();
    for (const QString &key : solverSettingsKeys(solver["method"].toString())) {
      if (solverSettings.contains(key))
        solver[key] = solverSettings[key];
    }
    solversArray.append(solver);
  }

  // Build assignments dict
  QJsonObject assignmentsObj;
  for (int r = 0; r < mpAssignmentsTable->rowCount(); ++r) {
    QComboBox *pSolverCombo = qobject_cast<QComboBox*>(mpAssignmentsTable->cellWidget(r, 1));
    if (!pSolverCombo)
      continue;
    const QString solverName = pSolverCombo->currentData().toString();
    if (!solverName.isEmpty())
      assignmentsObj[mpAssignmentsTable->item(r, 0)->toolTip()] = solverName;
  }

  QJsonObject args;
  args["solvers"]     = solversArray;
  args["assignments"] = assignmentsObj;

  const QString cref = mpModelWidget->getLibraryTreeItem()->getNameStructure();
  if (!OMSProxy::instance()->setSolverSettings(cref, args)) {
    return false;
  }

  if (pushOnStack) {
    mpModelWidget->createOMSimulatorUndoCommand(QString("System %1 simulation information").arg(cref));
    mpModelWidget->updateModelText();
  }
  return true;
}

// ---------------------------------------------------------------------------
// SystemSimulationInformationDialog
// ---------------------------------------------------------------------------

/*!
 * \class SystemSimulationInformationDialog
 * \brief A dialog for system simulation information.
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

void SystemSimulationInformationDialog::setSystemSimulationInformation()
{
  if (mpSystemSimulationInformationWidget->setSystemSimulationInformation(true)) {
    accept();
  }
}
