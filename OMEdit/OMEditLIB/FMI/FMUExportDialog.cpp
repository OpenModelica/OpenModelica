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

#include "FMUExportDialog.h"
#include "FMIGuideDialog.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"
#include "OMC/OMCProxy.h"
#include "Options/OptionsDialog.h"
#include "Util/Helper.h"
#include "Util/Utilities.h"

#include <QCheckBox>
#include <QComboBox>
#include <QDialogButtonBox>
#include <QDir>
#include <QGridLayout>
#include <QGroupBox>
#include <QJsonArray>
#include <QJsonObject>
#include <QLineEdit>
#include <QPushButton>
#include <QSettings>

/*!
 * \brief wasmFMUPlatforms
 * A WebAssembly FMU can carry a native binary for each platform that has an FMU loader in the installation,
 * lib/<platform>/omc/fmu-loader.*. omc takes the name of that directory as the name of the platform.
 */
static QStringList wasmFMUPlatforms()
{
  QStringList platforms;
  const QDir libDirectory(QString("%1/lib").arg(Helper::OpenModelicaHome));
  foreach (const QString &platform, libDirectory.entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name)) {
    const QDir omcDirectory(libDirectory.filePath(platform + "/omc"));
    if (!omcDirectory.entryList(QStringList("fmu-loader.*"), QDir::Files).isEmpty()) {
      platforms.append(platform);
    }
  }
  return platforms;
}

/*!
 * \brief FMUExportDialog::FMUExportDialog
 * \param pLibraryTreeItem - the model to export.
 * \param pParent
 */
FMUExportDialog::FMUExportDialog(LibraryTreeItem *pLibraryTreeItem, QWidget *pParent)
  : QDialog(pParent), mpLibraryTreeItem(pLibraryTreeItem), mpCustomPlatformsTextBox(0)
{
  const QString heading = tr("Export FMU");
  setWindowTitle(QString("%1 - %2 - %3").arg(Helper::applicationName, heading, pLibraryTreeItem->getNameStructure()));
  setAttribute(Qt::WA_DeleteOnClose);
  setMinimumWidth(520);
  FMIPage *pFMIPage = OptionsDialog::instance()->getFMIPage();
  mTargetLanguage = OptionsDialog::instance()->getSimulationPage()->getTargetLanguageComboBox()->currentText();
  mWasmTarget = mTargetLanguage == "wasm" || mTargetLanguage == "wasm-jit";
  QPushButton *pRecommendButton = new QPushButton(tr("Recommend Settings..."));
  pRecommendButton->setAutoDefault(false);
  pRecommendButton->setToolTip(tr("Answer questions about how the FMU is used and get the settings below"));
  connect(pRecommendButton, &QPushButton::clicked, this, &FMUExportDialog::recommendSettings);
  // version
  mpVersionComboBox = new QComboBox;
  if (!mWasmTarget) {
    mpVersionComboBox->addItem("1.0");
  }
  mpVersionComboBox->addItem("2.0");
  mpVersionComboBox->addItem("3.0");
  mpVersionComboBox->setCurrentText(pFMIPage->getFMIExportVersion());
  connect(mpVersionComboBox, QOverload<int>::of(&QComboBox::currentIndexChanged), this, &FMUExportDialog::updateControls);
  // interfaces
  const QString type = pFMIPage->getFMIExportType();
  mpModelExchangeCheckBox = new QCheckBox(tr("Model Exchange"));
  mpModelExchangeCheckBox->setChecked(type != "cs");
  connect(mpModelExchangeCheckBox, &QCheckBox::toggled, this, &FMUExportDialog::updateControls);
  mpCoSimulationCheckBox = new QCheckBox(tr("Co-Simulation"));
  mpCoSimulationCheckBox->setChecked(type != "me");
  connect(mpCoSimulationCheckBox, &QCheckBox::toggled, this, &FMUExportDialog::updateControls);
  // solver and filter, with the choices of the options page
  mpSolverComboBox = new QComboBox;
  ComboBox *pSolverComboBox = pFMIPage->getSolverForCoSimulationComboBox();
  for (int i = 0; i < pSolverComboBox->count(); i++) {
    mpSolverComboBox->addItem(pSolverComboBox->itemText(i), pSolverComboBox->itemData(i));
  }
  mpSolverComboBox->setCurrentIndex(pSolverComboBox->currentIndex());
  mpFilterComboBox = new QComboBox;
  ComboBox *pFilterComboBox = pFMIPage->getModelDescriptionFiltersComboBox();
  for (int i = 0; i < pFilterComboBox->count(); i++) {
    mpFilterComboBox->addItem(pFilterComboBox->itemText(i));
  }
  mpFilterComboBox->setCurrentIndex(pFilterComboBox->currentIndex());
  connect(mpFilterComboBox, QOverload<int>::of(&QComboBox::currentIndexChanged), this, &FMUExportDialog::updateControls);
  mpIncludeSourceCodeCheckBox = new QCheckBox(tr("Include Source Code"));
  mpIncludeSourceCodeCheckBox->setChecked(pFMIPage->getIncludeSourceCodeCheckBox()->isChecked());
  // DAE mode
  mDaeModeBefore = false;
  foreach (const QString &option, MainWindow::instance()->getOMCProxy()->getCommandLineOptions()) {
    if (option.startsWith("--daeMode") && !option.endsWith("=false")) {
      mDaeModeBefore = true;
    }
  }
  mpDaeModeCheckBox = new QCheckBox(tr("Export the residual form (--daeMode)"));
  mpDaeModeCheckBox->setChecked(mDaeModeBefore);
  connect(mpDaeModeCheckBox, &QCheckBox::toggled, this, &FMUExportDialog::updateControls);
  // platforms
  QSettings *pSettings = Utilities::getApplicationSettings();
  QStringList platforms = pSettings->contains("FMIExport/Platforms") ? pSettings->value("FMIExport/Platforms").toStringList()
                                                                       : QStringList("static");
  QGroupBox *pPlatformsGroupBox = new QGroupBox(tr("Platforms"));
  QVBoxLayout *pPlatformsLayout = new QVBoxLayout;
  bool wasmPlatforms = mWasmTarget;
#if defined(__EMSCRIPTEN__)
  wasmPlatforms = false; // the options page lists them already
#endif
  if (wasmPlatforms) {
    // the C platforms of the options page mean nothing to a WebAssembly FMU
    const QStringList loaders = wasmFMUPlatforms();
    pPlatformsLayout->addWidget(new Label(loaders.isEmpty()
                                          ? tr("The FMU contains the WebAssembly binary. This installation has no native FMU loader to add.")
                                          : tr("The FMU always contains the WebAssembly binary. A selected platform adds a native binary.")));
    foreach (const QString &platform, loaders) {
      QCheckBox *pPlatformCheckBox = new QCheckBox(platform);
      pPlatformCheckBox->setProperty(Helper::fmuPlatformNamePropertyId, platform);
      pPlatformCheckBox->setChecked(platforms.contains(platform));
      mPlatformCheckBoxes.append(pPlatformCheckBox);
      pPlatformsLayout->addWidget(pPlatformCheckBox);
    }
  } else {
    // the choices of the options page
    for (int i = 0; QLayoutItem *pLayoutItem = pFMIPage->getPlatformsGroupBox()->layout()->itemAt(i); i++) {
      if (QCheckBox *pCheckBox = qobject_cast<QCheckBox*>(pLayoutItem->widget())) {
        QCheckBox *pPlatformCheckBox = new QCheckBox(pCheckBox->text());
        const QString platform = pCheckBox->property(Helper::fmuPlatformNamePropertyId).toString();
        pPlatformCheckBox->setProperty(Helper::fmuPlatformNamePropertyId, platform);
        pPlatformCheckBox->setChecked(platforms.removeAll(platform) > 0);
        mPlatformCheckBoxes.append(pPlatformCheckBox);
        pPlatformsLayout->addWidget(pPlatformCheckBox);
      } else if (QLineEdit *pTextBox = qobject_cast<QLineEdit*>(pLayoutItem->widget())) {
        mpCustomPlatformsTextBox = new QLineEdit;
        mpCustomPlatformsTextBox->setPlaceholderText(pTextBox->placeholderText());
        pPlatformsLayout->addWidget(mpCustomPlatformsTextBox);
      }
    }
    if (mpCustomPlatformsTextBox) {
      mpCustomPlatformsTextBox->setText(platforms.join(","));
    }
#if !defined(__EMSCRIPTEN__)
    pPlatformsLayout->addWidget(new Label(tr("A source-code only FMU is generated if no platform is selected.")));
#endif
  }
  pPlatformsGroupBox->setLayout(pPlatformsLayout);
  // buttons
  mpSaveAsDefaultCheckBox = new QCheckBox(tr("Save as default"));
  mpSaveAsDefaultCheckBox->setToolTip(tr("Keep these settings, except the DAE mode, for the next export"));
  mpExportButton = new QPushButton(Helper::exportt);
  mpExportButton->setDefault(true);
  QDialogButtonBox *pButtonBox = new QDialogButtonBox;
  pButtonBox->addButton(mpExportButton, QDialogButtonBox::AcceptRole);
  pButtonBox->addButton(new QPushButton(Helper::cancel), QDialogButtonBox::RejectRole);
  connect(pButtonBox, &QDialogButtonBox::accepted, this, &FMUExportDialog::exportFMU);
  connect(pButtonBox, &QDialogButtonBox::rejected, this, &FMUExportDialog::reject);
  // layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignTop);
  int row = 0;
  pMainLayout->addWidget(Utilities::getHeadingLabel(heading), row++, 0, 1, 2);
  pMainLayout->addWidget(Utilities::getHeadingLine(), row++, 0, 1, 2);
  pMainLayout->addWidget(pRecommendButton, row++, 0, 1, 2, Qt::AlignLeft);
  pMainLayout->addWidget(new Label(tr("FMI Version:")), row, 0);
  pMainLayout->addWidget(mpVersionComboBox, row++, 1);
  pMainLayout->addWidget(new Label(tr("Interfaces:")), row, 0);
  pMainLayout->addWidget(mpModelExchangeCheckBox, row++, 1);
  pMainLayout->addWidget(mpCoSimulationCheckBox, row++, 1);
  pMainLayout->addWidget(new Label(tr("Solver for Co-Simulation:")), row, 0);
  pMainLayout->addWidget(mpSolverComboBox, row++, 1);
  pMainLayout->addWidget(new Label(tr("DAE Mode:")), row, 0);
  pMainLayout->addWidget(mpDaeModeCheckBox, row++, 1);
  pMainLayout->addWidget(new Label(tr("Model Description Filters:")), row, 0);
  pMainLayout->addWidget(mpFilterComboBox, row++, 1);
  pMainLayout->addWidget(new Label(tr("Source Code:")), row, 0);
  pMainLayout->addWidget(mpIncludeSourceCodeCheckBox, row++, 1);
  pMainLayout->addWidget(pPlatformsGroupBox, row++, 0, 1, 2);
  pMainLayout->addWidget(mpSaveAsDefaultCheckBox, row, 0);
  pMainLayout->addWidget(pButtonBox, row, 1, Qt::AlignRight);
  setLayout(pMainLayout);
  updateControls();
  mDefaults = choices();
}

FMUExportDialog::Choices FMUExportDialog::choices() const
{
  Choices choices;
  choices.version = mpVersionComboBox->currentText();
  choices.type = mpModelExchangeCheckBox->isChecked() && mpCoSimulationCheckBox->isChecked() ? "me_cs"
                 : (mpCoSimulationCheckBox->isChecked() ? "cs" : "me");
  choices.solver = mpSolverComboBox->currentIndex();
  choices.filter = mpFilterComboBox->currentIndex();
  choices.includeSourceCode = mpIncludeSourceCodeCheckBox->isChecked();
  foreach (QCheckBox *pPlatformCheckBox, mPlatformCheckBoxes) {
    if (pPlatformCheckBox->isChecked()) {
      choices.platforms.append(pPlatformCheckBox->property(Helper::fmuPlatformNamePropertyId).toString());
    }
  }
  if (mpCustomPlatformsTextBox && !mpCustomPlatformsTextBox->text().isEmpty()) {
    choices.platforms.append(mpCustomPlatformsTextBox->text().split(","));
  }
  return choices;
}

/*!
 * \brief FMUExportDialog::updateControls
 * FMI 1.0 is Model Exchange without DAE mode. In DAE mode, IDA is the solver. A black box has no source code.
 */
void FMUExportDialog::updateControls()
{
  const bool fmi1 = mpVersionComboBox->currentText() == "1.0";
  if (fmi1) {
    mpModelExchangeCheckBox->setChecked(true);
    mpCoSimulationCheckBox->setChecked(false);
    mpDaeModeCheckBox->setChecked(false);
  }
  mpCoSimulationCheckBox->setEnabled(!fmi1);
  mpDaeModeCheckBox->setEnabled(!fmi1);
  mpSolverComboBox->setEnabled(mpCoSimulationCheckBox->isChecked() && !mpDaeModeCheckBox->isChecked());
  mpIncludeSourceCodeCheckBox->setEnabled(!mWasmTarget && mpFilterComboBox->currentText() != "blackBox");
  mpExportButton->setEnabled(mpModelExchangeCheckBox->isChecked() || mpCoSimulationCheckBox->isChecked());
}

/*!
 * \brief FMUExportDialog::recommendSettings
 * Shows the settings guide and takes its recommendation. The guide gets what this dialog can export.
 */
void FMUExportDialog::recommendSettings()
{
  QJsonArray versions, solvers, filters;
  for (int i = 0; i < mpVersionComboBox->count(); i++) {
    versions.append(mpVersionComboBox->itemText(i));
  }
  for (int i = 0; i < mpSolverComboBox->count(); i++) {
    if (!mpSolverComboBox->itemData(i).toString().isEmpty()) {
      solvers.append(mpSolverComboBox->itemData(i).toString());
    }
  }
  solvers.append("ida");
  for (int i = 0; i < mpFilterComboBox->count(); i++) {
    filters.append(mpFilterComboBox->itemText(i));
  }
  QJsonObject offers{{"interface", QJsonArray{"me", "cs"}}, {"fmiVersion", versions}, {"fmiType", QJsonArray{"me", "cs", "me_cs"}},
                     {"csSolver", solvers}, {"fmiFilter", filters}};
  if (mWasmTarget) {
    offers.insert("platforms", QJsonArray{"wasm"});
    offers.insert("fmiSources", QJsonArray{"false"});
    offers.insert("csStepping", QJsonArray{"substep"});
  } else {
    offers.insert("platforms", QJsonArray{"static", "cross", "source"});
    offers.insert("fmiSources", QJsonArray{"false", "slim"});
  }
  // Named by what limits the offer, for "Not available in ...".
#if defined(__EMSCRIPTEN__)
  const QString name = tr("%1 in the web browser").arg(Helper::applicationName);
#elif defined(OMC_RUST_ABI)
  const QString name = tr("%1 with the target language %2").arg(Helper::applicationName, mTargetLanguage);
#else
  const QString name = tr("this build of %1").arg(Helper::applicationName);
#endif
  const QJsonObject host{{"name", name}, {"offers", offers},
                         {"applies", QJsonArray{"fmiVersion", "fmiType", "daeMode", "csSolver", "fmiFilter", "fmiSources", "platforms"}}};
  FMIGuideDialog *pFMIGuideDialog = new FMIGuideDialog(host, this);
  if (pFMIGuideDialog->exec() == QDialog::Accepted) {
    const QJsonObject values = pFMIGuideDialog->values();
    mpVersionComboBox->setCurrentText(values.value("fmiVersion").toString());
    const QString type = values.value("fmiType").toString();
    mpModelExchangeCheckBox->setChecked(type != "cs");
    mpCoSimulationCheckBox->setChecked(type != "me");
    mpDaeModeCheckBox->setChecked(values.value("daeMode").toString() == "on");
    const int solver = mpSolverComboBox->findData(values.value("csSolver").toString());
    if (solver > -1) {
      mpSolverComboBox->setCurrentIndex(solver);
    }
    const int filter = mpFilterComboBox->findText(values.value("fmiFilter").toString());
    if (filter > -1) {
      mpFilterComboBox->setCurrentIndex(filter);
    }
    mpIncludeSourceCodeCheckBox->setChecked(values.value("fmiSources").toString() != "false");
    // A cross compiled FMU needs the platform of the target, which the guide does not know.
    const QString platforms = values.value("platforms").toString();
    if (platforms == "static" || platforms == "source") {
      foreach (QCheckBox *pPlatformCheckBox, mPlatformCheckBoxes) {
        pPlatformCheckBox->setChecked(platforms == "static" && pPlatformCheckBox->property(Helper::fmuPlatformNamePropertyId).toString() == "static");
      }
      if (mpCustomPlatformsTextBox) {
        mpCustomPlatformsTextBox->clear();
      }
    }
    updateControls();
  }
  delete pFMIGuideDialog;
}

/*!
 * \brief FMUExportDialog::writeToOptions
 * Puts the choices on the FMI page of the options and saves them.
 */
void FMUExportDialog::writeToOptions(const Choices &choices)
{
  FMIPage *pFMIPage = OptionsDialog::instance()->getFMIPage();
  pFMIPage->setFMIExportVersion(choices.version);
  pFMIPage->setFMIExportType(choices.type);
  pFMIPage->getSolverForCoSimulationComboBox()->setCurrentIndex(choices.solver);
  pFMIPage->getModelDescriptionFiltersComboBox()->setCurrentIndex(choices.filter);
  pFMIPage->getIncludeSourceCodeCheckBox()->setChecked(choices.includeSourceCode);
  // a platform without a check box on the page goes into its text box
  QStringList platforms = choices.platforms;
  for (int i = 0; QLayoutItem *pLayoutItem = pFMIPage->getPlatformsGroupBox()->layout()->itemAt(i); i++) {
    if (QCheckBox *pCheckBox = qobject_cast<QCheckBox*>(pLayoutItem->widget())) {
      pCheckBox->setChecked(platforms.removeAll(pCheckBox->property(Helper::fmuPlatformNamePropertyId).toString()) > 0);
    } else if (QLineEdit *pTextBox = qobject_cast<QLineEdit*>(pLayoutItem->widget())) {
      pTextBox->setText(platforms.join(","));
    }
  }
  OptionsDialog::instance()->saveFMIExportDefaults();
}

/*!
 * \brief FMUExportDialog::exportFMU
 * The export reads the options. Without "Save as default" they get their values back after the export.
 */
void FMUExportDialog::exportFMU()
{
  LibraryTreeItem *pLibraryTreeItem = mpLibraryTreeItem;
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  const bool saveAsDefault = mpSaveAsDefaultCheckBox->isChecked();
  const bool daeMode = mpDaeModeCheckBox->isChecked();
  const bool daeModeBefore = mDaeModeBefore;
  const Choices defaults = mDefaults;

  writeToOptions(choices());
  if (daeMode != daeModeBefore) {
    pOMCProxy->setCommandLineOptions(QString("--daeMode=%1").arg(daeMode ? "true" : "false"));
  }
  accept();
  MainWindow::instance()->exportModelFMU(pLibraryTreeItem);
  if (daeMode != daeModeBefore) {
    pOMCProxy->setCommandLineOptions(QString("--daeMode=%1").arg(daeModeBefore ? "true" : "false"));
  }
  if (!saveAsDefault) {
    writeToOptions(defaults);
  }
}
