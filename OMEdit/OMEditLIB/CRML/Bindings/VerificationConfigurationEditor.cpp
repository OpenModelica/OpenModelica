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

#include "VerificationConfigurationEditor.h"
#include "ModelIndexBuilder.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"
#include "OMC/OMCProxy.h"
#include "Options/OptionsDialog.h"
#include "Util/Helper.h"
#include "Util/Utilities.h"

#include <QApplication>
#include <QDialogButtonBox>
#include <QDir>
#include <QFileDialog>
#include <QFormLayout>
#include <QHBoxLayout>
#include <QHeaderView>
#include <QLineEdit>
#include <QListWidget>
#include <QMessageBox>
#include <QProcess>
#include <QPushButton>
#include <QTabWidget>
#include <QTableWidget>
#include <QVBoxLayout>

using namespace CRMLBindings;

namespace {
enum SetColumns {SetName, SetClass, SetTargets, SetStatus, SetConfidence};
enum VariableColumns {VariableName, VariableObservers, VariableRole, VariableStatus, VariableConfidence};
enum InputColumns {InputObserver, InputName, InputType, InputBoundTo, InputStatus, InputConfidence};
enum InstanceColumns {InstanceName, InstanceTargets, InstanceStatus, InstanceConfidence};
enum ResultColumns {ResultRequirement, ResultElement, ResultValue, ResultLine};

QTableWidgetItem *readOnlyItem(const QString &text)
{
  QTableWidgetItem *pItem = new QTableWidgetItem(text);
  pItem->setFlags(pItem->flags() & ~Qt::ItemIsEditable);
  return pItem;
}

QString cellText(QTableWidget *pTable, int row, int column)
{
  QTableWidgetItem *pItem = pTable->item(row, column);
  return pItem ? pItem->text().trimmed() : QString();
}

QStringList splitList(const QString &text)
{
  QStringList items;
  for (const QString &item : text.split(',', Qt::SkipEmptyParts)) {
    if (!item.trimmed().isEmpty()) {
      items.append(item.trimmed());
    }
  }
  return items;
}

QColor statusColor(Status status)
{
  switch (status) {
    case Status::Valid: return QColor(0, 150, 0);
    case Status::Ambiguous: return QColor(220, 130, 0);
    case Status::Missing: return QColor(200, 0, 0);
  }
  return QColor(200, 0, 0);
}
} // namespace

VerificationConfigurationEditor::VerificationConfigurationEditor(const QString &crmlFile, QWidget *pParent)
  : QDialog(pParent)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName, tr("CRML Verification Configuration")));
  resize(1000, 600);
  mConfiguration.mRequirementFile = crmlFile;
  if (!crmlFile.isEmpty()) {
    mConfiguration.mName = QFileInfo(crmlFile).completeBaseName() + "_Verification";
  }

  mpTabWidget = new QTabWidget;
  mpTabWidget->addTab(createModelsTab(), tr("Models"));
  mpSetBindingsTable = createTable({tr("External Set"), tr("Element Class"), tr("Targets (class collections or instances)"), tr("Status"), tr("Confidence")});
  mpTabWidget->addTab(mpSetBindingsTable, tr("Set Bindings"));
  mpVariableBindingsTable = createTable({tr("External Variable"), tr("Observers, in order (prefix - to disable)"), tr("Role"), tr("Status"), tr("Confidence")});
  mpTabWidget->addTab(mpVariableBindingsTable, tr("Variable Bindings"));
  mpInputBindingsTable = createTable({tr("Observer"), tr("Input"), tr("Type"), tr("Bound To (Class.variable)"), tr("Status"), tr("Confidence")});
  mpTabWidget->addTab(mpInputBindingsTable, tr("Input Bindings"));
  mpInstanceBindingsTable = createTable({tr("Instance"), tr("Bound Instances (instance or instance:role)"), tr("Status"), tr("Confidence")});
  mpInstanceBindingsTable->setObjectName("InstanceBindingsTable");
  mpTabWidget->addTab(mpInstanceBindingsTable, tr("Instance Bindings"));
  mpDiagnosticsListWidget = new QListWidget;
  mpDiagnosticsListWidget->setObjectName("DiagnosticsListWidget");
  mpTabWidget->addTab(mpDiagnosticsListWidget, tr("Diagnostics"));
  mpResultsTable = createTable({tr("Requirement"), tr("Element"), tr("Result"), tr("CRML Line")});
  mpResultsTable->setObjectName("ResultsTable");
  mpResultsTable->setEditTriggers(QAbstractItemView::NoEditTriggers);
  mpTabWidget->addTab(mpResultsTable, tr("Results"));

  QPushButton *pOpenButton = new QPushButton(tr("Open..."));
  connect(pOpenButton, SIGNAL(clicked()), SLOT(openConfiguration()));
  QPushButton *pSaveButton = new QPushButton(tr("Save..."));
  connect(pSaveButton, SIGNAL(clicked()), SLOT(saveConfiguration()));
  QPushButton *pDiscoverButton = new QPushButton(tr("Auto Discover Bindings"));
  pDiscoverButton->setObjectName("AutoDiscoverButton");
  connect(pDiscoverButton, SIGNAL(clicked()), SLOT(autoDiscover()));
  QPushButton *pValidateButton = new QPushButton(tr("Validate"));
  connect(pValidateButton, SIGNAL(clicked()), SLOT(validate()));
  mpGenerateButton = new QPushButton(tr("Generate Verification Model"));
  mpGenerateButton->setObjectName("GenerateButton");
  connect(mpGenerateButton, SIGNAL(clicked()), SLOT(generate()));
  mpSimulateButton = new QPushButton(tr("Simulate"));
  mpSimulateButton->setObjectName("SimulateButton");
  mpSimulateButton->setEnabled(false);
  connect(mpSimulateButton, SIGNAL(clicked()), SLOT(simulate()));
  mpPlotButton = new QPushButton(tr("Plot Results"));
  mpPlotButton->setEnabled(false);
  connect(mpPlotButton, SIGNAL(clicked()), SLOT(plotResults()));
  QPushButton *pCloseButton = new QPushButton(Helper::close);
  connect(pCloseButton, SIGNAL(clicked()), SLOT(close()));

  QHBoxLayout *pButtonsLayout = new QHBoxLayout;
  pButtonsLayout->addWidget(pOpenButton);
  pButtonsLayout->addWidget(pSaveButton);
  pButtonsLayout->addStretch();
  pButtonsLayout->addWidget(pDiscoverButton);
  pButtonsLayout->addWidget(pValidateButton);
  pButtonsLayout->addWidget(mpGenerateButton);
  pButtonsLayout->addWidget(mpSimulateButton);
  pButtonsLayout->addWidget(mpPlotButton);
  pButtonsLayout->addWidget(pCloseButton);
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->addWidget(mpTabWidget);
  pMainLayout->addLayout(pButtonsLayout);
  setLayout(pMainLayout);
  fillModelsTab();
}

QWidget *VerificationConfigurationEditor::createModelsTab()
{
  mpNameTextBox = new QLineEdit;
  mpNameTextBox->setObjectName("NameTextBox");
  mpRequirementTextBox = new QLineEdit;
  QPushButton *pBrowseRequirementButton = new QPushButton(Helper::browse);
  connect(pBrowseRequirementButton, SIGNAL(clicked()), SLOT(browseRequirement()));
  mpArchitectureTextBox = new QLineEdit;
  mpArchitectureTextBox->setObjectName("ArchitectureTextBox");
  mpArchitectureTextBox->setPlaceholderText(tr("Optional architecture.json; without it the sets bind to behaviour instances"));
  QPushButton *pBrowseArchitectureButton = new QPushButton(Helper::browse);
  connect(pBrowseArchitectureButton, SIGNAL(clicked()), SLOT(browseArchitecture()));
  mpBehaviourTextBox = new QLineEdit;
  mpBehaviourTextBox->setObjectName("BehaviourTextBox");
  mpBehaviourTextBox->setPlaceholderText(tr("Modelica class name of the behaviour model"));
  mpObserversTextBox = new QLineEdit;
  mpObserversTextBox->setObjectName("ObserversTextBox");
  mpObserversTextBox->setPlaceholderText(tr("Modelica packages that contain the observers, separated by commas"));
  QPushButton *pLoadButton = new QPushButton(tr("Load Models"));
  connect(pLoadButton, SIGNAL(clicked()), SLOT(loadModels()));

  QHBoxLayout *pRequirementLayout = new QHBoxLayout;
  pRequirementLayout->addWidget(mpRequirementTextBox);
  pRequirementLayout->addWidget(pBrowseRequirementButton);
  QHBoxLayout *pArchitectureLayout = new QHBoxLayout;
  pArchitectureLayout->addWidget(mpArchitectureTextBox);
  pArchitectureLayout->addWidget(pBrowseArchitectureButton);
  QFormLayout *pFormLayout = new QFormLayout;
  pFormLayout->addRow(tr("Name:"), mpNameTextBox);
  pFormLayout->addRow(tr("Requirement model (CRML):"), pRequirementLayout);
  pFormLayout->addRow(tr("Architecture model:"), pArchitectureLayout);
  pFormLayout->addRow(tr("Behaviour model:"), mpBehaviourTextBox);
  pFormLayout->addRow(tr("Observer libraries:"), mpObserversTextBox);
  pFormLayout->addRow(QString(), pLoadButton);
  QWidget *pWidget = new QWidget;
  pWidget->setLayout(pFormLayout);
  return pWidget;
}

QTableWidget *VerificationConfigurationEditor::createTable(const QStringList &headers)
{
  QTableWidget *pTable = new QTableWidget(0, headers.size());
  pTable->setHorizontalHeaderLabels(headers);
  pTable->horizontalHeader()->setStretchLastSection(false);
  pTable->horizontalHeader()->setSectionResizeMode(QHeaderView::Interactive);
  pTable->verticalHeader()->hide();
  pTable->setSelectionBehavior(QAbstractItemView::SelectRows);
  return pTable;
}

void VerificationConfigurationEditor::readModelsTab()
{
  mConfiguration.mName = mpNameTextBox->text().trimmed();
  mConfiguration.mRequirementFile = mpRequirementTextBox->text().trimmed();
  mConfiguration.mArchitectureFile = mpArchitectureTextBox->text().trimmed();
  mConfiguration.mBehaviourModel = mpBehaviourTextBox->text().trimmed();
  mConfiguration.mObserverLibraries = splitList(mpObserversTextBox->text());
}

void VerificationConfigurationEditor::fillModelsTab()
{
  mpNameTextBox->setText(mConfiguration.mName);
  mpRequirementTextBox->setText(mConfiguration.mRequirementFile);
  mpArchitectureTextBox->setText(mConfiguration.mArchitectureFile);
  mpBehaviourTextBox->setText(mConfiguration.mBehaviourModel);
  mpObserversTextBox->setText(mConfiguration.mObserverLibraries.join(", "));
}

void VerificationConfigurationEditor::setStatusItem(QTableWidget *pTable, int row, int column, Status status, double confidence)
{
  QTableWidgetItem *pStatusItem = readOnlyItem(statusToString(status));
  pStatusItem->setForeground(statusColor(status));
  pTable->setItem(row, column, pStatusItem);
  pTable->setItem(row, column + 1, readOnlyItem(QString("%1%").arg(qRound(confidence*100))));
}

void VerificationConfigurationEditor::fillTables()
{
  mpSetBindingsTable->setRowCount(0);
  for (const SetBinding &binding : std::as_const(mConfiguration.mSetBindings)) {
    int row = mpSetBindingsTable->rowCount();
    mpSetBindingsTable->insertRow(row);
    QTableWidgetItem *pNameItem = readOnlyItem(binding.mSet);
    pNameItem->setData(Qt::UserRole, binding.mId);
    mpSetBindingsTable->setItem(row, SetName, pNameItem);
    const CrmlVariable *pSet = mExternals.findSet(binding.mSet);
    mpSetBindingsTable->setItem(row, SetClass, readOnlyItem(pSet ? pSet->mType : QString()));
    QStringList targets;
    for (const SetTarget &target : binding.mTargets) {
      targets.append(target.mName);
    }
    mpSetBindingsTable->setItem(row, SetTargets, new QTableWidgetItem(targets.join(", ")));
    setStatusItem(mpSetBindingsTable, row, SetStatus, binding.mStatus, binding.mConfidence);
  }

  mpVariableBindingsTable->setRowCount(0);
  for (const VariableBinding &binding : std::as_const(mConfiguration.mVariableBindings)) {
    int row = mpVariableBindingsTable->rowCount();
    mpVariableBindingsTable->insertRow(row);
    QTableWidgetItem *pNameItem = readOnlyItem(binding.key());
    pNameItem->setData(Qt::UserRole, binding.mId);
    mpVariableBindingsTable->setItem(row, VariableName, pNameItem);
    QStringList observers;
    for (const ObserverCandidate &candidate : binding.mObservers) {
      observers.append((candidate.mEnabled ? QString() : QString("-")) + candidate.mObserver);
    }
    mpVariableBindingsTable->setItem(row, VariableObservers, new QTableWidgetItem(observers.join(", ")));
    mpVariableBindingsTable->setItem(row, VariableRole, new QTableWidgetItem(binding.mRole));
    setStatusItem(mpVariableBindingsTable, row, VariableStatus, binding.mStatus, binding.mConfidence);
  }

  mpInputBindingsTable->setRowCount(0);
  for (const InputBinding &binding : std::as_const(mConfiguration.mInputBindings)) {
    const Observer *pObserver = mIndex.findObserver(binding.mObserver);
    QList<ModelicaVariable> inputs = pObserver ? pObserver->mInputs : QList<ModelicaVariable>();
    for (const InputMapping &mapping : binding.mInputs) {
      if (!pObserver || !pObserver->findInput(mapping.mInput)) {
        ModelicaVariable unknown;
        unknown.mName = mapping.mInput;
        inputs.append(unknown);
      }
    }
    for (const ModelicaVariable &input : std::as_const(inputs)) {
      int row = mpInputBindingsTable->rowCount();
      mpInputBindingsTable->insertRow(row);
      QTableWidgetItem *pObserverItem = readOnlyItem(binding.mObserver);
      pObserverItem->setData(Qt::UserRole, binding.mId);
      mpInputBindingsTable->setItem(row, InputObserver, pObserverItem);
      mpInputBindingsTable->setItem(row, InputName, readOnlyItem(input.mName));
      QString type = input.mType + (input.mDims.isEmpty() ? QString() : "[" + input.mDims.join(", ") + "]");
      if (input.mHasDefault) {
        type += tr(" (has default)");
      }
      mpInputBindingsTable->setItem(row, InputType, readOnlyItem(type));
      const InputMapping *pMapping = binding.findInput(input.mName);
      mpInputBindingsTable->setItem(row, InputBoundTo, new QTableWidgetItem(pMapping ? pMapping->mClass + "." + pMapping->mVariable : QString()));
      setStatusItem(mpInputBindingsTable, row, InputStatus, binding.mStatus, binding.mConfidence);
    }
  }

  mpInstanceBindingsTable->setRowCount(0);
  for (const InstanceBinding &binding : std::as_const(mConfiguration.mInstanceBindings)) {
    int row = mpInstanceBindingsTable->rowCount();
    mpInstanceBindingsTable->insertRow(row);
    QTableWidgetItem *pNameItem = readOnlyItem(binding.mInstance.isEmpty() ? mExternals.mModel : binding.mInstance);
    pNameItem->setData(Qt::UserRole, binding.mId);
    pNameItem->setData(Qt::UserRole + 1, binding.mInstance);
    mpInstanceBindingsTable->setItem(row, InstanceName, pNameItem);
    QStringList targets;
    for (const InstanceTarget &target : binding.mTargets) {
      targets.append(target.mRole.isEmpty() ? target.mInstance : target.mInstance + ":" + target.mRole);
    }
    mpInstanceBindingsTable->setItem(row, InstanceTargets, new QTableWidgetItem(targets.join(", ")));
    setStatusItem(mpInstanceBindingsTable, row, InstanceStatus, binding.mStatus, binding.mConfidence);
  }
  for (QTableWidget *pTable : {mpSetBindingsTable, mpVariableBindingsTable, mpInputBindingsTable, mpInstanceBindingsTable}) {
    pTable->resizeColumnsToContents();
  }
}

/*!
 * \brief VerificationConfigurationEditor::readTables
 * Reads the edited tables back into the configuration. The rows keep the binding id in Qt::UserRole.
 */
bool VerificationConfigurationEditor::readTables()
{
  readModelsTab();
  for (int row = 0; row < mpSetBindingsTable->rowCount(); ++row) {
    QString id = mpSetBindingsTable->item(row, SetName)->data(Qt::UserRole).toString();
    for (SetBinding &binding : mConfiguration.mSetBindings) {
      if (binding.mId != id) continue;
      binding.mTargets.clear();
      for (const QString &name : splitList(cellText(mpSetBindingsTable, row, SetTargets))) {
        SetTarget target;
        target.mKind = (mArchitecture.findType(name) || mIndex.findClass(name)) ? SetTarget::Collection : SetTarget::Instance;
        target.mName = name;
        binding.mTargets.append(target);
      }
    }
  }
  for (int row = 0; row < mpVariableBindingsTable->rowCount(); ++row) {
    QString id = mpVariableBindingsTable->item(row, VariableName)->data(Qt::UserRole).toString();
    for (VariableBinding &binding : mConfiguration.mVariableBindings) {
      if (binding.mId != id) continue;
      binding.mObservers.clear();
      for (QString name : splitList(cellText(mpVariableBindingsTable, row, VariableObservers))) {
        ObserverCandidate candidate;
        candidate.mEnabled = !name.startsWith('-');
        candidate.mObserver = candidate.mEnabled ? name : name.mid(1).trimmed();
        binding.mObservers.append(candidate);
      }
      binding.mRole = cellText(mpVariableBindingsTable, row, VariableRole);
    }
  }
  QSet<QString> readInputBindings;
  for (int row = 0; row < mpInputBindingsTable->rowCount(); ++row) {
    QString id = mpInputBindingsTable->item(row, InputObserver)->data(Qt::UserRole).toString();
    for (InputBinding &binding : mConfiguration.mInputBindings) {
      if (binding.mId != id) continue;
      if (!readInputBindings.contains(id)) {
        binding.mInputs.clear();
        readInputBindings.insert(id);
      }
      QString boundTo = cellText(mpInputBindingsTable, row, InputBoundTo);
      if (boundTo.isEmpty()) continue;
      InputMapping mapping;
      mapping.mInput = cellText(mpInputBindingsTable, row, InputName);
      mapping.mClass = boundTo.section('.', 0, -2);
      mapping.mVariable = boundTo.section('.', -1);
      mapping.mSource = mArchitecture.findType(mapping.mClass) ? InputMapping::Architecture : InputMapping::Behaviour;
      binding.mInputs.append(mapping);
    }
  }
  for (int row = 0; row < mpInstanceBindingsTable->rowCount(); ++row) {
    QString id = mpInstanceBindingsTable->item(row, InstanceName)->data(Qt::UserRole).toString();
    for (InstanceBinding &binding : mConfiguration.mInstanceBindings) {
      if (binding.mId != id) continue;
      binding.mTargets.clear();
      for (const QString &item : splitList(cellText(mpInstanceBindingsTable, row, InstanceTargets))) {
        InstanceTarget target;
        target.mInstance = item.section(':', 0, 0).trimmed();
        target.mRole = item.section(':', 1).trimmed();
        binding.mTargets.append(target);
      }
    }
  }
  return true;
}

void VerificationConfigurationEditor::showDiagnostics(const QList<Diagnostic> &diagnostics)
{
  mpDiagnosticsListWidget->clear();
  int errors = 0;
  for (const Diagnostic &d : diagnostics) {
    QListWidgetItem *pItem = new QListWidgetItem(d.toString());
    if (d.mSeverity == Diagnostic::Error) {
      pItem->setForeground(statusColor(Status::Missing));
      ++errors;
    } else if (d.mSeverity == Diagnostic::Warning) {
      pItem->setForeground(statusColor(Status::Ambiguous));
    }
    mpDiagnosticsListWidget->addItem(pItem);
  }
  if (diagnostics.isEmpty()) {
    mpDiagnosticsListWidget->addItem(tr("All bindings are valid."));
  }
  mpTabWidget->setTabText(mpTabWidget->indexOf(mpDiagnosticsListWidget), errors > 0 ? tr("Diagnostics (%1 errors)").arg(errors) : tr("Diagnostics"));
}

void VerificationConfigurationEditor::browseRequirement()
{
  QString fileName = StringHandler::getOpenFileName(this, QString("%1 - %2").arg(Helper::applicationName, Helper::chooseFile), nullptr, "CRML Files (*.crml)", nullptr);
  if (!fileName.isEmpty()) {
    mpRequirementTextBox->setText(fileName);
    if (mpNameTextBox->text().isEmpty()) {
      mpNameTextBox->setText(QFileInfo(fileName).completeBaseName() + "_Verification");
    }
  }
}

void VerificationConfigurationEditor::browseArchitecture()
{
  QString fileName = StringHandler::getOpenFileName(this, QString("%1 - %2").arg(Helper::applicationName, Helper::chooseFile), nullptr, "Architecture Files (*.json)", nullptr);
  if (!fileName.isEmpty()) {
    mpArchitectureTextBox->setText(fileName);
  }
}

QString VerificationConfigurationEditor::outputDirectory() const
{
  QString directory = mConfigurationFile.isEmpty() ? QString("%1/crml-bindings/%2").arg(Utilities::tempDirectory(), mConfiguration.mName)
                                                   : QFileInfo(mConfigurationFile).absolutePath();
  QDir().mkpath(directory);
  return directory;
}

/*!
 * \brief VerificationConfigurationEditor::translateRequirement
 * Runs the CRML compiler with --externals-json and reads the externals and the translated Modelica model.
 */
bool VerificationConfigurationEditor::translateRequirement(QString *pError)
{
#if QT_CONFIG(process)
  CRMLPage *pCRMLPage = OptionsDialog::instance()->getCRMLPage();
  QString directory = QString("%1/crml-bindings/%2/translation").arg(Utilities::tempDirectory(), mConfiguration.mName);
  QDir(directory).removeRecursively();
  QDir().mkpath(directory);
  QStringList args = {"-jar", pCRMLPage->getCompilerJarTextBox()->text()};
  args.append(pCRMLPage->getCompilerCommandLineOptionsTextBox()->text().split(' ', Qt::SkipEmptyParts));
  args << "--externals-json" << "-o" << directory << mConfiguration.mRequirementFile;
  QProcess process;
  process.setWorkingDirectory(directory);
  process.setProcessChannelMode(QProcess::MergedChannels);
  process.start(pCRMLPage->getCompilerProcessTextBox()->text(), args);
  if (!process.waitForFinished(120000) || process.exitCode() != 0) {
    *pError = tr("The CRML compiler failed: %1").arg(QString::fromLocal8Bit(process.readAll()).right(2000));
    return false;
  }
  QString stem = QFileInfo(mConfiguration.mRequirementFile).completeBaseName();
  QString jsonFile = QString("%1/%2/%2_externals.json").arg(directory, stem);
  QString moFile = QString("%1/%2/%2.mo").arg(directory, stem);
  QJsonObject json;
  if (!QFile::exists(jsonFile)) {
    *pError = tr("The CRML compiler wrote no %1. It needs the --externals-json option.").arg(jsonFile);
    return false;
  }
  if (!readJsonFile(jsonFile, json, pError) || !mExternals.fromJson(json, pError)) {
    return false;
  }
  QFile file(moFile);
  if (!file.open(QIODevice::ReadOnly)) {
    *pError = tr("The CRML compiler could not translate %1 to Modelica: %2").arg(mConfiguration.mRequirementFile, QString::fromLocal8Bit(process.readAll()).right(2000));
    return false;
  }
  mTranslatedRequirement = QString::fromUtf8(file.readAll());
  return true;
#else
  *pError = tr("The CRML bindings need the CRML compiler, which cannot run here.");
  return false;
#endif
}

void VerificationConfigurationEditor::loadModels()
{
  readModelsTab();
  mModelsLoaded = false;
  QString error;
  QApplication::setOverrideCursor(Qt::WaitCursor);
  bool ok = translateRequirement(&error);
  if (ok) {
    mArchitecture = ArchitectureModel();
    if (!mConfiguration.mArchitectureFile.isEmpty()) {
      QJsonObject json;
      ok = readJsonFile(mConfiguration.mArchitectureFile, json, &error) && mArchitecture.fromJson(json, &error);
    }
  }
  if (ok) {
    // the verification model needs the CRMLtoModelica library of the CRML options
    LibraryWidget *pLibraryWidget = MainWindow::instance()->getLibraryWidget();
    for (QString path : OptionsDialog::instance()->getCRMLPage()->getModelicaLibraries()->items()) {
      path = path.replace("\\", "/");
      if (QFile::exists(path) && !pLibraryWidget->getLibraryTreeModel()->getLibraryTreeItemFromFile(path, 1)) {
        pLibraryWidget->openFile(path, Helper::utf8, false, true);
      }
    }
    ok = buildModelIndex(MainWindow::instance()->getOMCProxy(), mConfiguration.mBehaviourModel, mConfiguration.mObserverLibraries, mIndex, &error);
  }
  QApplication::restoreOverrideCursor();
  if (!ok) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), error);
    return;
  }
  mModelsLoaded = true;
  Diagnostic info;
  info.mSeverity = Diagnostic::Info;
  info.mCode = "VI001";
  info.mMessage = tr("Loaded %1 (%2 external sets, %3 classes), %4 behaviour instances and %5 observers.")
                  .arg(mExternals.mModel).arg(mExternals.mSets.size()).arg(mExternals.mClasses.size())
                  .arg(mIndex.mInstances.size()).arg(mIndex.mObservers.size());
  showDiagnostics({info});
  fillTables();
}

bool VerificationConfigurationEditor::ensureModelsLoaded()
{
  if (!mModelsLoaded) {
    loadModels();
  }
  return mModelsLoaded;
}

void VerificationConfigurationEditor::autoDiscover()
{
  readTables();
  if (!ensureModelsLoaded()) {
    return;
  }
  BindingDiscovery(mExternals, mArchitecture, mIndex).discover(mConfiguration);
  fillTables();
  validate();
}

void VerificationConfigurationEditor::validate()
{
  readTables();
  if (!ensureModelsLoaded()) {
    return;
  }
  mResolution = BindingEngine(mConfiguration, mExternals, mArchitecture, mIndex).resolve();
  BindingEngine::updateStatus(mConfiguration, mResolution);
  fillTables();
  showDiagnostics(mResolution.mDiagnostics);
}

void VerificationConfigurationEditor::generate()
{
  validate();
  if (!mModelsLoaded) {
    return;
  }
  if (mResolution.hasErrors()) {
    mpTabWidget->setCurrentWidget(mpDiagnosticsListWidget);
    QMessageBox::warning(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                         tr("The verification model is generated only when all bindings are valid. See the diagnostics."));
    return;
  }
  VerificationGenerator generator(mConfiguration, mExternals, mIndex, mResolution);
  QString text = generator.generate(mTranslatedRequirement);
  QString fileName = QString("%1/%2.mo").arg(outputDirectory(), generator.packageName());
  QFile file(fileName);
  if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), tr("Cannot write %1.").arg(fileName));
    return;
  }
  file.write(text.toUtf8());
  file.close();
  LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
  if (LibraryTreeItem *pItem = pLibraryTreeModel->findLibraryTreeItem(generator.packageName())) {
    pLibraryTreeModel->unloadClass(pItem, false);
  }
  MainWindow::instance()->getLibraryWidget()->openFile(fileName, Helper::utf8, false, true);
  mVerificationModel = generator.verificationModel();
  mStatusVariables = generator.statusVariables();
  mpSimulateButton->setEnabled(true);
  Diagnostic info;
  info.mSeverity = Diagnostic::Info;
  info.mCode = "VI002";
  info.mMessage = tr("Generated %1 in %2.").arg(mVerificationModel, fileName);
  QList<Diagnostic> diagnostics = mResolution.mDiagnostics;
  diagnostics.prepend(info);
  showDiagnostics(diagnostics);
}

void VerificationConfigurationEditor::simulate()
{
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  QString directory = outputDirectory();
  QString previousDirectory = pOMCProxy->changeDirectory();
  pOMCProxy->changeDirectory(directory);
  QApplication::setOverrideCursor(Qt::WaitCursor);
  pOMCProxy->sendCommand(QString("simulate(%1)").arg(mVerificationModel));
  mResultFile = QString("%1/%2_res.mat").arg(directory, mVerificationModel);
  pOMCProxy->sendCommand(QString("readSimulationResultSize(\"%1\")").arg(mResultFile));
  bool ok = pOMCProxy->getResult().toInt() > 0;
  QString error = pOMCProxy->getErrorString();
  mpResultsTable->setRowCount(0);
  if (ok) {
    pOMCProxy->sendCommand(QString("readSimulationResult(\"%1\", {time})").arg(mResultFile));
    QString stopTime = pOMCProxy->getResult().section(',', -1).remove('}').trimmed();
    for (const RequirementStatusVariable &status : std::as_const(mStatusVariables)) {
      pOMCProxy->sendCommand(QString("val(%1.y, %2, \"%3\")").arg(status.mComponent, stopTime, mResultFile));
      RequirementResult result = requirementResultFromBoolean4(qRound(pOMCProxy->getResult().toDouble()));
      int row = mpResultsTable->rowCount();
      mpResultsTable->insertRow(row);
      mpResultsTable->setItem(row, ResultRequirement, readOnlyItem(status.mRequirement));
      mpResultsTable->setItem(row, ResultElement, readOnlyItem(status.mElement));
      QTableWidgetItem *pResultItem = readOnlyItem(requirementResultToString(result));
      pResultItem->setForeground(result == RequirementResult::Satisfied ? statusColor(Status::Valid)
                                 : (result == RequirementResult::Violated ? statusColor(Status::Missing) : statusColor(Status::Ambiguous)));
      mpResultsTable->setItem(row, ResultValue, pResultItem);
      mpResultsTable->setItem(row, ResultLine, readOnlyItem(QString::number(status.mLine)));
    }
    mpResultsTable->resizeColumnsToContents();
    mpTabWidget->setCurrentWidget(mpResultsTable);
  }
  pOMCProxy->changeDirectory(previousDirectory);
  QApplication::restoreOverrideCursor();
  mpPlotButton->setEnabled(ok);
  if (!ok) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), tr("The simulation of %1 failed.\n%2").arg(mVerificationModel, error));
  }
}

void VerificationConfigurationEditor::plotResults()
{
  MainWindow::instance()->openResultFile(mResultFile);
}

void VerificationConfigurationEditor::openConfiguration()
{
  QString fileName = StringHandler::getOpenFileName(this, QString("%1 - %2").arg(Helper::applicationName, Helper::chooseFile), nullptr,
                                                    "CRML Verification Configuration (*.crmlbind.json)", nullptr);
  if (fileName.isEmpty()) {
    return;
  }
  QString error;
  VerificationConfiguration configuration;
  if (!configuration.load(fileName, &error)) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), error);
    return;
  }
  mConfiguration = configuration;
  mConfigurationFile = fileName;
  mModelsLoaded = false;
  fillModelsTab();
  fillTables();
  validate();
}

void VerificationConfigurationEditor::saveConfiguration()
{
  readTables();
  QString fileName = StringHandler::getSaveFileName(this, QString("%1 - %2").arg(Helper::applicationName, Helper::saveFile), nullptr,
                                                    "CRML Verification Configuration (*.crmlbind.json)", nullptr, "crmlbind.json",
                                                    &mConfiguration.mName);
  if (fileName.isEmpty()) {
    return;
  }
  QString error;
  if (!mConfiguration.save(fileName, &error)) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), error);
    return;
  }
  mConfigurationFile = fileName;
}
