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

#include "TranslationFlagsWidget.h"
#include "MainWindow.h"
#include "OMC/OMCProxy.h"
#include "Simulation/SimulationOptions.h"
#include "Util/Utilities.h"

#include <QDesktopServices>
#include <QMessageBox>
#include <QGridLayout>

/*!
 * \brief TranslationFlagsWidget::TranslationFlagsWidget
 * \param pParent
 */
TranslationFlagsWidget::TranslationFlagsWidget(QWidget *pParent)
  : QWidget(pParent)
{
  // Matching Algorithm
  mpMatchingAlgorithmLabel = new Label(tr("Matching Algorithm:"));
  OMCInterface::getAvailableMatchingAlgorithms_res matchingAlgorithms;
  matchingAlgorithms = MainWindow::instance()->getOMCProxy()->getAvailableMatchingAlgorithms();
  mpMatchingAlgorithmComboBox = new QComboBox;
  mpMatchingAlgorithmComboBox->addItems(matchingAlgorithms.allChoices);
  Utilities::setToolTip(mpMatchingAlgorithmComboBox, "Matching Algorithms", matchingAlgorithms.allComments);
  // Index Reduction Method
  mpIndexReductionMethodLabel = new Label(tr("Index Reduction Method:"));
  OMCInterface::getAvailableIndexReductionMethods_res indexReductionMethods;
  indexReductionMethods = MainWindow::instance()->getOMCProxy()->getAvailableIndexReductionMethods();
  mpIndexReductionMethodComboBox = new QComboBox;
  mpIndexReductionMethodComboBox->addItems(indexReductionMethods.allChoices);
  Utilities::setToolTip(mpIndexReductionMethodComboBox, "Index Reduction Methods", indexReductionMethods.allComments);
  mpInitializationCheckBox = new QCheckBox(tr("Show additional information from the initialization process"));
  mpEvaluateAllParametersCheckBox = new QCheckBox(tr("Evaluate all parameters (faster simulation, cannot change them at runtime)"));
  mpNLSanalyticJacobianCheckBox = new QCheckBox(tr("Enable analytical jacobian for non-linear strong components"));
  mpParmodautoCheckBox = new QCheckBox(tr("Enable parallelization of independent systems of equations (Experimental)"));
  mpEnableFMUImportCheckBox = new QCheckBox(tr("Enable FMU Import"));
  mpAdditionalTranslationFlagsLabel = new Label(tr("Additional Translation Flags:"));
  mpAdditionalTranslationFlagsLabel->setToolTip(Helper::translationFlagsTip);
  mpAdditionalTranslationFlagsTextBox = new QLineEdit;
  mpAdditionalTranslationFlagsTextBox->setToolTip(Helper::translationFlagsTip);
  mpTranslationFlagsHelpButton = new QToolButton;
  mpTranslationFlagsHelpButton->setIcon(QIcon(":/Resources/icons/link-external.svg"));
  mpTranslationFlagsHelpButton->setToolTip(tr("Translation flags help"));
  connect(mpTranslationFlagsHelpButton, SIGNAL(clicked()), SLOT(showTranslationFlagsHelp()));
  // create the layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->setAlignment(Qt::AlignTop);
  int row = 0;
  pMainLayout->addWidget(mpMatchingAlgorithmLabel, row, 0);
  pMainLayout->addWidget(mpMatchingAlgorithmComboBox, row++, 1, 1, 2);
  pMainLayout->addWidget(mpIndexReductionMethodLabel, row, 0);
  pMainLayout->addWidget(mpIndexReductionMethodComboBox, row++, 1, 1, 2);
  pMainLayout->addWidget(mpInitializationCheckBox, row++, 0, 1, 3);
  pMainLayout->addWidget(mpEvaluateAllParametersCheckBox, row++, 0, 1, 3);
  pMainLayout->addWidget(mpNLSanalyticJacobianCheckBox, row++, 0, 1, 3);
  pMainLayout->addWidget(mpParmodautoCheckBox, row++, 0, 1, 3);
  pMainLayout->addWidget(mpEnableFMUImportCheckBox, row++, 0, 1, 3);
  pMainLayout->addWidget(mpAdditionalTranslationFlagsLabel, row, 0);
  pMainLayout->addWidget(mpAdditionalTranslationFlagsTextBox, row, 1);
  pMainLayout->addWidget(mpTranslationFlagsHelpButton, row++, 2);
  setLayout(pMainLayout);
}

/*!
 * \brief TranslationFlagsWidget::applySimulationOptions
 * Apply the simulation options.
 * \param simulationOptions
 */
void TranslationFlagsWidget::applySimulationOptions(const SimulationOptions &simulationOptions)
{
  int currentIndex = mpMatchingAlgorithmComboBox->findText(simulationOptions.getMatchingAlgorithm());
  if (currentIndex > -1) {
    mpMatchingAlgorithmComboBox->setCurrentIndex(currentIndex);
  }
  currentIndex = mpIndexReductionMethodComboBox->findText(simulationOptions.getIndexReductionMethod());
  if (currentIndex > -1) {
    mpIndexReductionMethodComboBox->setCurrentIndex(currentIndex);
  }
  mpInitializationCheckBox->setChecked(simulationOptions.getInitialization());
  mpEvaluateAllParametersCheckBox->setChecked(simulationOptions.getEvaluateAllParameters());
  mpNLSanalyticJacobianCheckBox->setChecked(simulationOptions.getNLSanalyticJacobian());
  mpParmodautoCheckBox->setChecked(simulationOptions.getParmodauto());
  mpEnableFMUImportCheckBox->setChecked(simulationOptions.getEnableFMUImport());
  mpAdditionalTranslationFlagsTextBox->setText(simulationOptions.getAdditionalTranslationFlags());
}

/*!
 * \brief TranslationFlagsWidget::createSimulationOptions
 * Creates a SimulationOptions instance from the control values.
 * \param pSimulationOptions
 */
void TranslationFlagsWidget::createSimulationOptions(SimulationOptions *pSimulationOptions)
{
  pSimulationOptions->setMatchingAlgorithm(mpMatchingAlgorithmComboBox->currentText());
  pSimulationOptions->setIndexReductionMethod(mpIndexReductionMethodComboBox->currentText());
  pSimulationOptions->setInitialization(mpInitializationCheckBox->isChecked());
  pSimulationOptions->setEvaluateAllParameters(mpEvaluateAllParametersCheckBox->isChecked());
  pSimulationOptions->setNLSanalyticJacobian(mpNLSanalyticJacobianCheckBox->isChecked());
  pSimulationOptions->setParmodauto(mpParmodautoCheckBox->isChecked());
  pSimulationOptions->setEnableFMUImport(mpEnableFMUImportCheckBox->isChecked());
  pSimulationOptions->setAdditionalTranslationFlags(mpAdditionalTranslationFlagsTextBox->text());
}

/*!
 * \brief TranslationFlagsWidget::applyFlags
 * Sets the flags.
 * \return
 */
bool TranslationFlagsWidget::applyFlags()
{
  if (!MainWindow::instance()->getOMCProxy()->setCommandLineOptions(commandLineOptions())) {
    return false;
  }
  return true;
}

/*!
 * \brief TranslationFlagsWidget::commandLineOptions
 * Returns the flags as command line options string.
 * \return
 */
QString TranslationFlagsWidget::commandLineOptions()
{
  QStringList configFlags;
  // matching algorithm
  configFlags.append(QString("--matchingAlgorithm=%1").arg(mpMatchingAlgorithmComboBox->currentText()));
  // index reduction method
  configFlags.append(QString("--indexReductionMethod=%1").arg(mpIndexReductionMethodComboBox->currentText()));

  QStringList debugFlags;
  // initialization
  if (mpInitializationCheckBox->isChecked()) {
    debugFlags.append("initialization");
  }
  // evaluate all parameters
  if (mpEvaluateAllParametersCheckBox->isChecked()) {
    debugFlags.append("evaluateAllParameters");
  }
  // NLS analytic jacobian
  if (mpNLSanalyticJacobianCheckBox->isChecked()) {
    debugFlags.append("NLSanalyticJacobian");
  }
  // parmodauto
  if (mpParmodautoCheckBox->isChecked()) {
    configFlags.append("--parmodauto");
  }
  // enable FMU Import
  if (mpEnableFMUImportCheckBox->isChecked()) {
    configFlags.append("--allowNonStandardModelica=reinitInAlgorithms");
  }

  QStringList commandLineOptions;
  commandLineOptions.append(configFlags);
  if (!debugFlags.isEmpty()) {
    commandLineOptions.append(QString("-d=%1").arg(debugFlags.join(",")));
  }
  // set command line options set manually by user. This can override above options.
  if (!mpAdditionalTranslationFlagsTextBox->text().isEmpty()) {
    commandLineOptions.append(mpAdditionalTranslationFlagsTextBox->text());
  }

  return commandLineOptions.join(" ");
}

/*!
 * \brief TranslationFlagsWidget::showTranslationFlagsHelp
 * Slot activated when mpTranslationFlagsHelpButton clicked signal is raised.\n
 * Opens the omchelptext.html page of OpenModelica users guide.
 */
void TranslationFlagsWidget::showTranslationFlagsHelp()
{
  QUrl omcHelpTextPath(QString("https://openmodelica.org/doc/OpenModelicaUsersGuide/%1/omchelptext.html").arg(Helper::OpenModelicaUsersGuideVersion));
  QDesktopServices::openUrl(omcHelpTextPath);
}
