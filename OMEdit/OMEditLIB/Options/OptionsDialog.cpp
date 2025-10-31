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
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#include "OptionsDialog.h"
#include "OptionsDefaults.h"
#include "MainWindow.h"
#include "OMC/OMCProxy.h"
#include "OMS/OMSProxy.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/ItemDelegate.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Modeling/MessagesWidget.h"
#include "Plotting/PlotWindowContainer.h"
#include "Plotting/VariablesWidget.h"
#include "Debugger/StackFrames/StackFramesWidget.h"
#include "Editors/HTMLEditor.h"
#include "Simulation/TranslationFlagsWidget.h"
#include <limits>

#include <QStringBuilder>
#include <QMessageBox>
#include <QColorDialog>
#include <QButtonGroup>

/*!
 * \class OptionsDialog
 * \brief Creates an interface with options like Modelica Text, Pen Styles, Libraries etc.
 */

OptionsDialog *OptionsDialog::mpInstance = 0;

/*!
 * \brief OptionsDialog::create
 */
void OptionsDialog::create()
{
  if (!mpInstance) {
    mpInstance = new OptionsDialog;
  }
}

/*!
 * \brief OptionsDialog::destroy
 */
void OptionsDialog::destroy()
{
  mpInstance->deleteLater();
  mpInstance = 0;
}

/*!
 * \brief OptionsDialog::OptionsDialog
 * \param pParent
 */
OptionsDialog::OptionsDialog(QWidget *pParent)
  : QDialog(pParent), mpSettings(Utilities::getApplicationSettings())
{
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName, Helper::options));
  setModal(true);
  mDetectChange = false;
  mpGeneralSettingsPage = new GeneralSettingsPage(this);
  mpLibrariesPage = new LibrariesPage(this);
  mpTextEditorPage = new TextEditorPage(this);
  mpModelicaEditorPage = new ModelicaEditorPage(this);
  connect(mpTextEditorPage->getFontFamilyComboBox(), SIGNAL(currentFontChanged(QFont)), mpModelicaEditorPage, SIGNAL(updatePreview()));
  connect(mpTextEditorPage->getFontSizeSpinBox(), SIGNAL(valueChanged(double)), mpModelicaEditorPage, SIGNAL(updatePreview()));
  mpMOSEditorPage = new MOSEditorPage(this);
  connect(mpTextEditorPage->getFontFamilyComboBox(), SIGNAL(currentFontChanged(QFont)), mpMOSEditorPage, SIGNAL(updatePreview()));
  connect(mpTextEditorPage->getFontSizeSpinBox(), SIGNAL(valueChanged(double)), mpMOSEditorPage, SIGNAL(updatePreview()));
  mpMetaModelicaEditorPage = new MetaModelicaEditorPage(this);
  connect(mpTextEditorPage->getFontFamilyComboBox(), SIGNAL(currentFontChanged(QFont)), mpMetaModelicaEditorPage, SIGNAL(updatePreview()));
  connect(mpTextEditorPage->getFontSizeSpinBox(), SIGNAL(valueChanged(double)), mpMetaModelicaEditorPage, SIGNAL(updatePreview()));
  mpOMSimulatorEditorPage = new OMSimulatorEditorPage(this);
  connect(mpTextEditorPage->getFontFamilyComboBox(), SIGNAL(currentFontChanged(QFont)), mpOMSimulatorEditorPage, SIGNAL(updatePreview()));
  connect(mpTextEditorPage->getFontSizeSpinBox(), SIGNAL(valueChanged(double)), mpOMSimulatorEditorPage, SIGNAL(updatePreview()));
  mpCRMLEditorPage = new CRMLEditorPage(this);
  connect(mpTextEditorPage->getFontFamilyComboBox(), SIGNAL(currentFontChanged(QFont)), mpCRMLEditorPage, SIGNAL(updatePreview()));
  connect(mpTextEditorPage->getFontSizeSpinBox(), SIGNAL(valueChanged(double)), mpCRMLEditorPage, SIGNAL(updatePreview()));
  mpCEditorPage = new CEditorPage(this);
  connect(mpTextEditorPage->getFontFamilyComboBox(), SIGNAL(currentFontChanged(QFont)), mpCEditorPage, SIGNAL(updatePreview()));
  connect(mpTextEditorPage->getFontSizeSpinBox(), SIGNAL(valueChanged(double)), mpCEditorPage, SIGNAL(updatePreview()));
  mpHTMLEditorPage = new HTMLEditorPage(this);
  connect(mpTextEditorPage->getFontFamilyComboBox(), SIGNAL(currentFontChanged(QFont)), mpHTMLEditorPage, SIGNAL(updatePreview()));
  connect(mpTextEditorPage->getFontSizeSpinBox(), SIGNAL(valueChanged(double)), mpHTMLEditorPage, SIGNAL(updatePreview()));
  mpGraphicalViewsPage = new GraphicalViewsPage(this);
  mpSimulationPage = new SimulationPage(this);
  mpMessagesPage = new MessagesPage(this);
  mpNotificationsPage = new NotificationsPage(this);
  mpLineStylePage = new LineStylePage(this);
  mpFillStylePage = new FillStylePage(this);
  mpPlottingPage = new PlottingPage(this);
  mpFigaroPage = new FigaroPage(this);
  mpCRMLPage = new CRMLPage(this);
  mpDebuggerPage = new DebuggerPage(this);
  mpFMIPage = new FMIPage(this);
  mpOMSimulatorPage = new OMSimulatorPage(this);
  mpSensitivityOptimizationPage = new SensitivityOptimizationPage(this);
  mpTraceabilityPage = new TraceabilityPage(this);
  // Get the settings.
  // Don't read the settings in case we are running the testsuite. We want default OMEdit.
  if (!MainWindow::instance()->isTestsuiteRunning()) {
    readSettings();
  }
  // set up the Options Dialog
  setUpDialog();
}

//! Reads the settings from omedit.ini file.
void OptionsDialog::readSettings()
{
  mpSettings->sync();
  readGeneralSettings();
  readLibrariesSettings();
  readTextEditorSettings();
  readModelicaEditorSettings();
  emit modelicaEditorSettingsChanged();
  mpModelicaEditorPage->emitUpdatePreview();
  readMOSEditorSettings();
  emit mosEditorSettingsChanged();
  mpMOSEditorPage->emitUpdatePreview();
  readMetaModelicaEditorSettings();
  emit metaModelicaEditorSettingsChanged();
  mpMetaModelicaEditorPage->emitUpdatePreview();
  readOMSimulatorEditorSettings();
  emit omsimulatorEditorSettingsChanged();
  mpOMSimulatorEditorPage->emitUpdatePreview();
  readCRMLEditorSettings();
  emit crmlEditorSettingsChanged();
  mpCRMLEditorPage->emitUpdatePreview();
  readCEditorSettings();
  emit cEditorSettingsChanged();
  mpCEditorPage->emitUpdatePreview();
  readHTMLEditorSettings();
  emit HTMLEditorSettingsChanged();
  mpHTMLEditorPage->emitUpdatePreview();
  readGraphicalViewsSettings();
  readSimulationSettings();
  readMessagesSettings();
  readNotificationsSettings();
  readLineStyleSettings();
  readFillStyleSettings();
  readPlottingSettings();
  readFigaroSettings();
  readCRMLSettings();
  readDebuggerSettings();
  readFMISettings();
  readOMSimulatorSettings();
  readSensitivityOptimizationSettings();
  readTraceabilitySettings();
}

//! Reads the General section settings from omedit.ini
void OptionsDialog::readGeneralSettings()
{
  // read the language option
  if (mpSettings->contains("language")) {
    /* Handle locale stored both as variant and as QString */
    QLocale locale = QLocale(mpSettings->value("language").toString());
    int currentIndex = mpGeneralSettingsPage->getLanguageComboBox()->findData(locale.name() == "C" ? mpSettings->value("language") : QVariant(locale), Qt::UserRole, Qt::MatchExactly);
    if (currentIndex > -1) {
      mpGeneralSettingsPage->getLanguageComboBox()->setCurrentIndex(currentIndex);
    }
  } else {
    mpGeneralSettingsPage->getLanguageComboBox()->setCurrentIndex(0);
  }
  // read the working directory
  if (mpSettings->contains("workingDirectory")) {
    const QString workingDirectory = mpSettings->value("workingDirectory").toString();
    if (!workingDirectory.isEmpty() && !MainWindow::instance()->getOMCProxy()->changeDirectory(workingDirectory).isEmpty()) {
      mpGeneralSettingsPage->setWorkingDirectory(workingDirectory);
    }
  } else {
    mpGeneralSettingsPage->setWorkingDirectory("");
  }
  // read toolbar icon size
  if (mpSettings->contains("toolbarIconSize")) {
    mpGeneralSettingsPage->getToolbarIconSizeSpinBox()->setValue(mpSettings->value("toolbarIconSize").toInt());
  } else {
    mpGeneralSettingsPage->getToolbarIconSizeSpinBox()->setValue(OptionsDefaults::GeneralSettings::toolBarIconSize);
  }
  // read the user customizations
  if (mpSettings->contains("userCustomizations")) {
    mpGeneralSettingsPage->setPreserveUserCustomizations(mpSettings->value("userCustomizations").toBool());
  } else {
    mpGeneralSettingsPage->setPreserveUserCustomizations(OptionsDefaults::GeneralSettings::preserveUserCustomizations);
  }
  // read the terminal command
  if (mpSettings->contains("terminalCommand")) {
    mpGeneralSettingsPage->setTerminalCommand(mpSettings->value("terminalCommand").toString());
  } else {
    mpGeneralSettingsPage->setTerminalCommand(OptionsDefaults::GeneralSettings::terminalCommand);
  }
  // read the terminal command arguments
  if (mpSettings->contains("terminalCommandArgs")) {
    mpGeneralSettingsPage->setTerminalCommandArguments(mpSettings->value("terminalCommandArgs").toString());
  } else {
    mpGeneralSettingsPage->setTerminalCommandArguments(OptionsDefaults::GeneralSettings::terminalCommandArguments);
  }
  // read hide variable browser
  if (mpSettings->contains("hideVariablesBrowser")) {
    mpGeneralSettingsPage->getHideVariablesBrowserCheckBox()->setChecked(mpSettings->value("hideVariablesBrowser").toBool());
  } else {
    mpGeneralSettingsPage->getHideVariablesBrowserCheckBox()->setChecked(OptionsDefaults::GeneralSettings::hideVariablesBrowser);
  }
  // read activate access annotations
  if (mpSettings->contains("activateAccessAnnotations")) {
    bool ok;
    int currentIndex = mpGeneralSettingsPage->getActivateAccessAnnotationsComboBox()->findData(mpSettings->value("activateAccessAnnotations").toInt(&ok));
    if (currentIndex > -1 && ok) {
      mpGeneralSettingsPage->getActivateAccessAnnotationsComboBox()->setCurrentIndex(currentIndex);
    }
  } else {
    mpGeneralSettingsPage->getActivateAccessAnnotationsComboBox()->setCurrentIndex(OptionsDefaults::GeneralSettings::activateAccessAnnotationsIndex);
  }
  // read create a backup file
  if (mpSettings->contains("createBackupFile")) {
    mpGeneralSettingsPage->getCreateBackupFileCheckbox()->setChecked(mpSettings->value("createBackupFile").toBool());
  } else {
    mpGeneralSettingsPage->getCreateBackupFileCheckbox()->setChecked(OptionsDefaults::GeneralSettings::createBackupFile);
  }
  // read nfAPINoise
  if (mpSettings->contains("simulation/nfAPINoise")) {
    mpGeneralSettingsPage->getDisplayNFAPIErrorsWarningsCheckBox()->setChecked(mpSettings->value("simulation/nfAPINoise").toBool());
  } else {
    mpGeneralSettingsPage->getDisplayNFAPIErrorsWarningsCheckBox()->setChecked(OptionsDefaults::GeneralSettings::displayNFAPIErrorsWarnings);
  }
  // read enable CRML support
  if (mpSettings->contains("enableCRMLSupport")) {
    mpGeneralSettingsPage->getEnableCRMLSupportCheckBox()->setChecked(mpSettings->value("enableCRMLSupport").toBool());
  } else {
    mpGeneralSettingsPage->getEnableCRMLSupportCheckBox()->setChecked(OptionsDefaults::GeneralSettings::enableCRMLSupport);
  }
  MainWindow::instance()->setCRMLEnabled(mpGeneralSettingsPage->getEnableCRMLSupportCheckBox()->isChecked());
  // read library icon size
  if (mpSettings->contains("libraryIconSize")) {
    mpGeneralSettingsPage->getLibraryIconSizeSpinBox()->setValue(mpSettings->value("libraryIconSize").toInt());
  } else {
    mpGeneralSettingsPage->getLibraryIconSizeSpinBox()->setValue(OptionsDefaults::GeneralSettings::libraryIconSize);
  }
  // read the max. text length to draw on a library icon
  if (mpSettings->contains("libraryIconMaxTextLength")) {
    mpGeneralSettingsPage->getLibraryIconTextLengthSpinBox()->setValue(mpSettings->value("libraryIconMaxTextLength").toInt());
  } else {
    mpGeneralSettingsPage->getLibraryIconTextLengthSpinBox()->setValue(OptionsDefaults::GeneralSettings::libraryIconMaximumTextLength);
  }
  // read show protected classes
  if (mpSettings->contains("showProtectedClasses")) {
    mpGeneralSettingsPage->setShowProtectedClasses(mpSettings->value("showProtectedClasses").toBool());
  } else {
    mpGeneralSettingsPage->setShowProtectedClasses(OptionsDefaults::GeneralSettings::showProtectedClasses);
  }
  // read show hidden classes
  if (mpSettings->contains("showHiddenClasses")) {
    mpGeneralSettingsPage->setShowHiddenClasses(mpSettings->value("showHiddenClasses").toBool());
  } else {
    mpGeneralSettingsPage->setShowHiddenClasses(OptionsDefaults::GeneralSettings::showHiddenClasses);
  }
  // read synchronize with ModelWidget
  if (mpSettings->contains("synchronizeWithModelWidget")) {
    mpGeneralSettingsPage->getSynchronizeWithModelWidgetCheckBox()->setChecked(mpSettings->value("synchronizeWithModelWidget").toBool());
  } else {
    mpGeneralSettingsPage->getSynchronizeWithModelWidgetCheckBox()->setChecked(OptionsDefaults::GeneralSettings::synchronizeWithModelWidget);
  }
  // read auto save
  if (mpSettings->contains("autoSave/enable")) {
    mpGeneralSettingsPage->getEnableAutoSaveGroupBox()->setChecked(mpSettings->value("autoSave/enable").toBool());
  } else {
    mpGeneralSettingsPage->getEnableAutoSaveGroupBox()->setChecked(OptionsDefaults::GeneralSettings::enableAutoSave);
  }
  // read auto save interval
  if (mpSettings->contains("autoSave/interval")) {
    mpGeneralSettingsPage->getAutoSaveIntervalSpinBox()->setValue(mpSettings->value("autoSave/interval").toInt());
  } else {
    mpGeneralSettingsPage->getAutoSaveIntervalSpinBox()->setValue(OptionsDefaults::GeneralSettings::autoSaveInterval);
  }
  // read welcome page
  if (mpSettings->contains("welcomePage/view")) {
    mpGeneralSettingsPage->setWelcomePageView(mpSettings->value("welcomePage/view").toInt());
  } else {
    mpGeneralSettingsPage->setWelcomePageView(OptionsDefaults::GeneralSettings::welcomePageView);
  }
  // read show latest news
  if (mpSettings->contains("welcomePage/showLatestNews")) {
    mpGeneralSettingsPage->getShowLatestNewsCheckBox()->setChecked(mpSettings->value("welcomePage/showLatestNews").toBool());
  } else {
    mpGeneralSettingsPage->getShowLatestNewsCheckBox()->setChecked(OptionsDefaults::GeneralSettings::showLatestNews);
  }
  // recent files size
  if (mpSettings->contains("welcomePage/recentFilesSize")) {
    mpGeneralSettingsPage->getRecentFilesAndLatestNewsSizeSpinBox()->setValue(mpSettings->value("welcomePage/recentFilesSize").toInt());
  } else {
    mpGeneralSettingsPage->getRecentFilesAndLatestNewsSizeSpinBox()->setValue(OptionsDefaults::GeneralSettings::recentFilesAndLatestNewsSize);
  }
}

//! Reads the Libraries section settings from omedit.ini
void OptionsDialog::readLibrariesSettings()
{
  // read ModelicaPath
  if (mpSettings->contains("modelicaPath-1")) {
    const QString modelicaPath = mpSettings->value("modelicaPath-1").toString();
    if (!modelicaPath.isEmpty() && MainWindow::instance()->getOMCProxy()->setModelicaPath(modelicaPath)) {
      mpLibrariesPage->getModelicaPathTextBox()->setText(modelicaPath);
    }
  } else {
    mpLibrariesPage->getModelicaPathTextBox()->clear();
  }
  // read load latest Modelica
  if (mpSettings->contains("loadLatestModelica")) {
    mpLibrariesPage->getLoadLatestModelicaCheckbox()->setChecked(mpSettings->value("loadLatestModelica").toBool());
  } else {
    mpLibrariesPage->getLoadLatestModelicaCheckbox()->setChecked(OptionsDefaults::Libraries::loadLatestModelica);
  }
  // read the system libraries
  int i = 0;
  while(i < mpLibrariesPage->getSystemLibrariesTree()->topLevelItemCount()) {
    qDeleteAll(mpLibrariesPage->getSystemLibrariesTree()->topLevelItem(i)->takeChildren());
    delete mpLibrariesPage->getSystemLibrariesTree()->topLevelItem(i);
    i = 0;   //Restart iteration
  }
  // read the settings and add libraries
  mpSettings->beginGroup("libraries");
  QStringList systemLibraries = mpSettings->childKeys();
  foreach (QString systemLibrary, systemLibraries) {
    QStringList values;
    values << systemLibrary << mpSettings->value(systemLibrary).toString();
    mpLibrariesPage->getSystemLibrariesTree()->addTopLevelItem(new QTreeWidgetItem(values));
  }
  mpSettings->endGroup();
  // read user libraries
  i = 0;
  while(i < mpLibrariesPage->getUserLibrariesTree()->topLevelItemCount()) {
    qDeleteAll(mpLibrariesPage->getUserLibrariesTree()->topLevelItem(i)->takeChildren());
    delete mpLibrariesPage->getUserLibrariesTree()->topLevelItem(i);
    i = 0;   //Restart iteration
  }
  // read the settings and add libraries
  mpSettings->beginGroup("userlibraries");
  QStringList userLibraries = mpSettings->childKeys();
  foreach (QString userLibrary, userLibraries) {
    QStringList values;
    values << QUrl::fromPercentEncoding(userLibrary.toUtf8()) << mpSettings->value(userLibrary).toString();
    mpLibrariesPage->getUserLibrariesTree()->addTopLevelItem(new QTreeWidgetItem(values));
  }
  mpSettings->endGroup();
}

/*!
 * \brief OptionsDialog::readTextEditorSettings
 * Reads the Text editor settings from omedit.ini
 */
void OptionsDialog::readTextEditorSettings()
{
  int index;
  if (mpSettings->contains("textEditor/lineEnding")) {
    index = mpTextEditorPage->getLineEndingComboBox()->findData(mpSettings->value("textEditor/lineEnding").toInt());
  } else {
    index = mpTextEditorPage->getLineEndingComboBox()->findData(OptionsDefaults::TextEditor::lineEnding);
  }
  if (index > -1) {
    mpTextEditorPage->getLineEndingComboBox()->setCurrentIndex(index);
  }

  if (mpSettings->contains("textEditor/bom")) {
    index = mpTextEditorPage->getBOMComboBox()->findData(mpSettings->value("textEditor/bom").toInt());
  } else {
    index = mpTextEditorPage->getBOMComboBox()->findData(OptionsDefaults::TextEditor::bom);
  }
  if (index > -1) {
    mpTextEditorPage->getBOMComboBox()->setCurrentIndex(index);
  }

  if (mpSettings->contains("textEditor/tabPolicy")) {
    index = mpTextEditorPage->getTabPolicyComboBox()->findData(mpSettings->value("textEditor/tabPolicy").toInt());
  } else {
    index = mpTextEditorPage->getTabPolicyComboBox()->findData(OptionsDefaults::TextEditor::tabPolicy);
  }
  if (index > -1) {
    mpTextEditorPage->getTabPolicyComboBox()->setCurrentIndex(index);
  }

  if (mpSettings->contains("textEditor/tabSize")) {
    mpTextEditorPage->getTabSizeSpinBox()->setValue(mpSettings->value("textEditor/tabSize").toInt());
  } else {
    mpTextEditorPage->getTabSizeSpinBox()->setValue(OptionsDefaults::TextEditor::tabSize);
  }

  if (mpSettings->contains("textEditor/indentSize")) {
    mpTextEditorPage->getIndentSpinBox()->setValue(mpSettings->value("textEditor/indentSize").toInt());
  } else {
    mpTextEditorPage->getIndentSpinBox()->setValue(OptionsDefaults::TextEditor::indentSize);
  }

  if (mpSettings->contains("textEditor/enableSyntaxHighlighting")) {
    mpTextEditorPage->getSyntaxHighlightingGroupBox()->setChecked(mpSettings->value("textEditor/enableSyntaxHighlighting").toBool());
  } else {
    mpTextEditorPage->getSyntaxHighlightingGroupBox()->setChecked(OptionsDefaults::TextEditor::syntaxHighlighting);
  }

  if (mpSettings->contains("textEditor/enableCodeFolding")) {
    mpTextEditorPage->getCodeFoldingCheckBox()->setChecked(mpSettings->value("textEditor/enableCodeFolding").toBool());
  } else {
    mpTextEditorPage->getCodeFoldingCheckBox()->setChecked(OptionsDefaults::TextEditor::codeFolding);
  }

  if (mpSettings->contains("textEditor/matchParenthesesCommentsQuotes")) {
    mpTextEditorPage->getMatchParenthesesCommentsQuotesCheckBox()->setChecked(mpSettings->value("textEditor/matchParenthesesCommentsQuotes").toBool());
  } else {
    mpTextEditorPage->getMatchParenthesesCommentsQuotesCheckBox()->setChecked(OptionsDefaults::TextEditor::matchParenthesesCommentsQuotes);
  }

  if (mpSettings->contains("textEditor/enableLineWrapping")) {
    mpTextEditorPage->getLineWrappingCheckbox()->setChecked(mpSettings->value("textEditor/enableLineWrapping").toBool());
  } else {
    mpTextEditorPage->getLineWrappingCheckbox()->setChecked(OptionsDefaults::TextEditor::lineWrapping);
  }
  // select font family item
  if (mpSettings->contains("textEditor/fontFamily")) {
    index = mpTextEditorPage->getFontFamilyComboBox()->findText(mpSettings->value("textEditor/fontFamily").toString(), Qt::MatchExactly);
  } else {
    index = mpTextEditorPage->getFontFamilyComboBox()->findText(Helper::monospacedFontInfo.family(), Qt::MatchExactly);
  }
  if (index > -1) {
    mpTextEditorPage->getFontFamilyComboBox()->setCurrentIndex(index);
  }
  // select font size item
  if (mpSettings->contains("textEditor/fontSize")) {
    mpTextEditorPage->getFontSizeSpinBox()->setValue(mpSettings->value("textEditor/fontSize").toDouble());
  } else {
    mpTextEditorPage->getFontSizeSpinBox()->setValue(Helper::monospacedFontInfo.pointSize());
  }

  if (mpSettings->contains("textEditor/enableAutocomplete")) {
    mpTextEditorPage->getAutoCompleteCheckBox()->setChecked(mpSettings->value("textEditor/enableAutocomplete").toBool());
  } else {
    mpTextEditorPage->getAutoCompleteCheckBox()->setChecked(OptionsDefaults::TextEditor::autocomplete);
  }
}

/*!
 * \brief OptionsDialog::readModelicaEditorSettings
 * Reads the ModelicaEditor settings from omedit.ini
 */
void OptionsDialog::readModelicaEditorSettings()
{
  if (mpSettings->contains("modelicaEditor/preserveTextIndentation")) {
    mpModelicaEditorPage->getPreserveTextIndentationCheckBox()->setChecked(mpSettings->value("modelicaEditor/preserveTextIndentation").toBool());
  } else {
    mpModelicaEditorPage->getPreserveTextIndentationCheckBox()->setChecked(OptionsDefaults::ModelicaEditor::preserveTextIndentation);
  }

  if (mpSettings->contains("modelicaEditor/textRuleColor")) {
    mpModelicaEditorPage->setColor("Text", QColor(mpSettings->value("modelicaEditor/textRuleColor").toUInt()));
  } else {
    mpModelicaEditorPage->setColor("Text", OptionsDefaults::ModelicaEditor::textRuleColor);
  }

  if (mpSettings->contains("modelicaEditor/numberRuleColor")) {
    mpModelicaEditorPage->setColor("Number", QColor(mpSettings->value("modelicaEditor/numberRuleColor").toUInt()));
  } else {
    mpModelicaEditorPage->setColor("Number", OptionsDefaults::ModelicaEditor::numberRuleColor);
  }

  if (mpSettings->contains("modelicaEditor/keywordRuleColor")) {
    mpModelicaEditorPage->setColor("Keyword", QColor(mpSettings->value("modelicaEditor/keywordRuleColor").toUInt()));
  } else {
    mpModelicaEditorPage->setColor("Keyword", OptionsDefaults::ModelicaEditor::keywordRuleColor);
  }

  if (mpSettings->contains("modelicaEditor/typeRuleColor")) {
    mpModelicaEditorPage->setColor("Type", QColor(mpSettings->value("modelicaEditor/typeRuleColor").toUInt()));
  } else {
    mpModelicaEditorPage->setColor("Type", OptionsDefaults::ModelicaEditor::typeRuleColor);
  }

  if (mpSettings->contains("modelicaEditor/functionRuleColor")) {
    mpModelicaEditorPage->setColor("Function", QColor(mpSettings->value("modelicaEditor/functionRuleColor").toUInt()));
  } else {
    mpModelicaEditorPage->setColor("Function", OptionsDefaults::ModelicaEditor::functionRuleColor);
  }

  if (mpSettings->contains("modelicaEditor/quotesRuleColor")) {
    mpModelicaEditorPage->setColor("Quotes", QColor(mpSettings->value("modelicaEditor/quotesRuleColor").toUInt()));
  } else {
    mpModelicaEditorPage->setColor("Quotes", OptionsDefaults::ModelicaEditor::quotesRuleColor);
  }

  if (mpSettings->contains("modelicaEditor/commentRuleColor")) {
    mpModelicaEditorPage->setColor("Comment", QColor(mpSettings->value("modelicaEditor/commentRuleColor").toUInt()));
  } else {
    mpModelicaEditorPage->setColor("Comment", OptionsDefaults::ModelicaEditor::commentRuleColor);
  }
}

/*!
 * \brief OptionsDialog::readMOSEditorSettings
 * Reads the MOSEditor settings from omedit.ini
 */
void OptionsDialog::readMOSEditorSettings()
{
  if (mpSettings->contains("mosEditor/textRuleColor")) {
    mpMOSEditorPage->setColor("Text", QColor(mpSettings->value("mosEditor/textRuleColor").toUInt()));
  } else {
    mpMOSEditorPage->setColor("Text", OptionsDefaults::ModelicaEditor::textRuleColor);
  }

  if (mpSettings->contains("mosEditor/numberRuleColor")) {
    mpMOSEditorPage->setColor("Number", QColor(mpSettings->value("mosEditor/numberRuleColor").toUInt()));
  } else {
    mpMOSEditorPage->setColor("Number", OptionsDefaults::MOSEditor::numberRuleColor);
  }

  if (mpSettings->contains("mosEditor/keywordRuleColor")) {
    mpMOSEditorPage->setColor("Keyword", QColor(mpSettings->value("mosEditor/keywordRuleColor").toUInt()));
  } else {
    mpMOSEditorPage->setColor("Keyword", OptionsDefaults::MOSEditor::keywordRuleColor);
  }

  if (mpSettings->contains("mosEditor/typeRuleColor")) {
    mpMOSEditorPage->setColor("Type", QColor(mpSettings->value("mosEditor/typeRuleColor").toUInt()));
  } else {
    mpMOSEditorPage->setColor("Type", OptionsDefaults::MOSEditor::typeRuleColor);
  }

  if (mpSettings->contains("mosEditor/quotesRuleColor")) {
    mpMOSEditorPage->setColor("Quotes", QColor(mpSettings->value("mosEditor/quotesRuleColor").toUInt()));
  } else {
    mpMOSEditorPage->setColor("Quotes", OptionsDefaults::MOSEditor::quotesRuleColor);
  }

  if (mpSettings->contains("mosEditor/commentRuleColor")) {
    mpMOSEditorPage->setColor("Comment", QColor(mpSettings->value("mosEditor/commentRuleColor").toUInt()));
  } else {
    mpMOSEditorPage->setColor("Comment", OptionsDefaults::MOSEditor::commentRuleColor);
  }
}

/*!
 * \brief OptionsDialog::readMetaModelicaEditorSettings
 * Reads the MetaModelicaEditor settings from omedit.ini
 */
void OptionsDialog::readMetaModelicaEditorSettings()
{
  if (mpSettings->contains("metaModelicaEditor/textRuleColor")) {
    mpMetaModelicaEditorPage->setColor("Text", QColor(mpSettings->value("metaModelicaEditor/textRuleColor").toUInt()));
  } else {
    mpMetaModelicaEditorPage->setColor("Text", OptionsDefaults::ModelicaEditor::textRuleColor);
  }

  if (mpSettings->contains("metaModelicaEditor/numberRuleColor")) {
    mpMetaModelicaEditorPage->setColor("Number", QColor(mpSettings->value("metaModelicaEditor/numberRuleColor").toUInt()));
  } else {
    mpMetaModelicaEditorPage->setColor("Number", OptionsDefaults::MetaModelicaEditor::numberRuleColor);
  }

  if (mpSettings->contains("metaModelicaEditor/keywordRuleColor")) {
    mpMetaModelicaEditorPage->setColor("Keyword", QColor(mpSettings->value("metaModelicaEditor/keywordRuleColor").toUInt()));
  } else {
    mpMetaModelicaEditorPage->setColor("Keyword", OptionsDefaults::MetaModelicaEditor::keywordRuleColor);
  }

  if (mpSettings->contains("metaModelicaEditor/typeRuleColor")) {
    mpMetaModelicaEditorPage->setColor("Type", QColor(mpSettings->value("metaModelicaEditor/typeRuleColor").toUInt()));
  } else {
    mpMetaModelicaEditorPage->setColor("Type", OptionsDefaults::MetaModelicaEditor::typeRuleColor);
  }

  if (mpSettings->contains("metaModelicaEditor/quotesRuleColor")) {
    mpMetaModelicaEditorPage->setColor("Quotes", QColor(mpSettings->value("metaModelicaEditor/quotesRuleColor").toUInt()));
  } else {
    mpMetaModelicaEditorPage->setColor("Quotes", OptionsDefaults::MetaModelicaEditor::quotesRuleColor);
  }

  if (mpSettings->contains("metaModelicaEditor/commentRuleColor")) {
    mpMetaModelicaEditorPage->setColor("Comment", QColor(mpSettings->value("metaModelicaEditor/commentRuleColor").toUInt()));
  } else {
    mpMetaModelicaEditorPage->setColor("Comment", OptionsDefaults::MetaModelicaEditor::commentRuleColor);
  }
}

/*!
 * \brief OptionsDialog::readOMSimulatorEditorSettings
 * Reads the OMSimulatorEditor settings from omedit.ini
 */
void OptionsDialog::readOMSimulatorEditorSettings()
{
  if (mpSettings->contains("omsimulatorEditor/textRuleColor")) {
    mpOMSimulatorEditorPage->setColor("Text", QColor(mpSettings->value("omsimulatorEditor/textRuleColor").toUInt()));
  } else {
    mpOMSimulatorEditorPage->setColor("Text", OptionsDefaults::ModelicaEditor::textRuleColor);
  }

  if (mpSettings->contains("omsimulatorEditor/tagRuleColor")) {
    mpOMSimulatorEditorPage->setColor("Tag", QColor(mpSettings->value("omsimulatorEditor/tagRuleColor").toUInt()));
  } else {
    mpOMSimulatorEditorPage->setColor("Tag", OptionsDefaults::OMSimulatorEditor::tagRuleColor);
  }

  if (mpSettings->contains("omsimulatorEditor/elementsRuleColor")) {
    mpOMSimulatorEditorPage->setColor("Element", QColor(mpSettings->value("omsimulatorEditor/elementsRuleColor").toUInt()));
  } else {
    mpOMSimulatorEditorPage->setColor("Element", OptionsDefaults::OMSimulatorEditor::elementRuleColor);
  }

  if (mpSettings->contains("omsimulatorEditor/quotesRuleColor")) {
    mpOMSimulatorEditorPage->setColor("Quotes", QColor(mpSettings->value("omsimulatorEditor/quotesRuleColor").toUInt()));
  } else {
    mpOMSimulatorEditorPage->setColor("Quotes", OptionsDefaults::OMSimulatorEditor::quotesRuleColor);
  }

  if (mpSettings->contains("omsimulatorEditor/commentRuleColor")) {
    mpOMSimulatorEditorPage->setColor("Comment", QColor(mpSettings->value("omsimulatorEditor/commentRuleColor").toUInt()));
  } else {
    mpOMSimulatorEditorPage->setColor("Comment", OptionsDefaults::OMSimulatorEditor::commentRuleColor);
  }
}

/*!
 * \brief OptionsDialog::readCRMLEditorSettings
 * Reads the CRMLEditor settings from omedit.ini
 */
void OptionsDialog::readCRMLEditorSettings()
{
  if (mpSettings->contains("crmlEditor/textRuleColor")) {
    mpCRMLEditorPage->setColor("Text", QColor(mpSettings->value("crmlEditor/textRuleColor").toUInt()));
  } else {
    mpCRMLEditorPage->setColor("Text", OptionsDefaults::ModelicaEditor::textRuleColor);
  }

  if (mpSettings->contains("crmlEditor/numberRuleColor")) {
    mpCRMLEditorPage->setColor("Number", QColor(mpSettings->value("crmlEditor/numberRuleColor").toUInt()));
  } else {
    mpCRMLEditorPage->setColor("Number", OptionsDefaults::CRMLEditor::numberRuleColor);
  }

  if (mpSettings->contains("crmlEditor/keywordRuleColor")) {
    mpCRMLEditorPage->setColor("Keyword", QColor(mpSettings->value("crmlEditor/keywordRuleColor").toUInt()));
  } else {
    mpCRMLEditorPage->setColor("Keyword", OptionsDefaults::CRMLEditor::keywordRuleColor);
  }

  if (mpSettings->contains("crmlEditor/typeRuleColor")) {
    mpCRMLEditorPage->setColor("Type", QColor(mpSettings->value("crmlEditor/typeRuleColor").toUInt()));
  } else {
    mpCRMLEditorPage->setColor("Type", OptionsDefaults::CRMLEditor::typeRuleColor);
  }

  if (mpSettings->contains("crmlEditor/quotesRuleColor")) {
    mpCRMLEditorPage->setColor("Quotes", QColor(mpSettings->value("crmlEditor/quotesRuleColor").toUInt()));
  } else {
    mpCRMLEditorPage->setColor("Quotes", OptionsDefaults::CRMLEditor::quotesRuleColor);
  }

  if (mpSettings->contains("crmlEditor/commentRuleColor")) {
    mpCRMLEditorPage->setColor("Comment", QColor(mpSettings->value("crmlEditor/commentRuleColor").toUInt()));
  } else {
    mpCRMLEditorPage->setColor("Comment", OptionsDefaults::CRMLEditor::commentRuleColor);
  }
}

/*!
 * \brief OptionsDialog::readCEditorSettings
 * Reads the CEditor settings from omedit.ini
 */
void OptionsDialog::readCEditorSettings()
{
  if (mpSettings->contains("cEditor/textRuleColor")) {
    mpCEditorPage->setColor("Text", QColor(mpSettings->value("cEditor/textRuleColor").toUInt()));
  } else {
    mpCEditorPage->setColor("Text", OptionsDefaults::ModelicaEditor::textRuleColor);
  }

  if (mpSettings->contains("cEditor/numberRuleColor")) {
    mpCEditorPage->setColor("Number", QColor(mpSettings->value("cEditor/numberRuleColor").toUInt()));
  } else {
    mpCEditorPage->setColor("Number", OptionsDefaults::CEditor::numberRuleColor);
  }

  if (mpSettings->contains("cEditor/keywordRuleColor")) {
    mpCEditorPage->setColor("Keyword", QColor(mpSettings->value("cEditor/keywordRuleColor").toUInt()));
  } else {
    mpCEditorPage->setColor("Keyword", OptionsDefaults::CEditor::keywordRuleColor);
  }

  if (mpSettings->contains("cEditor/typeRuleColor")) {
    mpCEditorPage->setColor("Type", QColor(mpSettings->value("cEditor/typeRuleColor").toUInt()));
  } else {
    mpCEditorPage->setColor("Type", OptionsDefaults::CEditor::typeRuleColor);
  }

  if (mpSettings->contains("cEditor/quotesRuleColor")) {
    mpCEditorPage->setColor("Quotes", QColor(mpSettings->value("cEditor/quotesRuleColor").toUInt()));
  } else {
    mpCEditorPage->setColor("Quotes", OptionsDefaults::CEditor::quotesRuleColor);
  }

  if (mpSettings->contains("cEditor/commentRuleColor")) {
    mpCEditorPage->setColor("Comment", QColor(mpSettings->value("cEditor/commentRuleColor").toUInt()));
  } else {
    mpCEditorPage->setColor("Comment", OptionsDefaults::CEditor::commentRuleColor);
  }
}

/*!
 * \brief OptionsDialog::readHTMLEditorSettings
 * Reads the HTMLEditor settings from omedit.ini
 */
void OptionsDialog::readHTMLEditorSettings()
{
  if (mpSettings->contains("HTMLEditor/textRuleColor")) {
    mpHTMLEditorPage->setColor("Text", QColor(mpSettings->value("HTMLEditor/textRuleColor").toUInt()));
  } else {
    mpHTMLEditorPage->setColor("Text", OptionsDefaults::ModelicaEditor::textRuleColor);
  }

  if (mpSettings->contains("HTMLEditor/tagRuleColor")) {
    mpHTMLEditorPage->setColor("Tag", QColor(mpSettings->value("HTMLEditor/tagRuleColor").toUInt()));
  } else {
    mpHTMLEditorPage->setColor("Tag", OptionsDefaults::HTMLEditor::tagRuleColor);
  }

  if (mpSettings->contains("HTMLEditor/quotesRuleColor")) {
    mpHTMLEditorPage->setColor("Quotes", QColor(mpSettings->value("HTMLEditor/quotesRuleColor").toUInt()));
  } else {
    mpHTMLEditorPage->setColor("Quotes", OptionsDefaults::HTMLEditor::quotesRuleColor);
  }

  if (mpSettings->contains("HTMLEditor/commentRuleColor")) {
    mpHTMLEditorPage->setColor("Comment", QColor(mpSettings->value("HTMLEditor/commentRuleColor").toUInt()));
  } else {
    mpHTMLEditorPage->setColor("Comment", OptionsDefaults::HTMLEditor::commentRuleColor);
  }
}

//! Reads the GraphicsViews section settings from omedit.ini
void OptionsDialog::readGraphicalViewsSettings()
{
  // read the modeling view mode
  if (mpSettings->contains("modeling/viewmode")) {
    mpGraphicalViewsPage->setModelingViewMode(mpSettings->value("modeling/viewmode").toString());
  } else {
    mpGraphicalViewsPage->setModelingViewMode(Helper::tabbed);
  }
  // read the default view
  if (mpSettings->contains("defaultView")) {
    mpGraphicalViewsPage->setDefaultView(mpSettings->value("defaultView").toString());
  } else {
    mpGraphicalViewsPage->setDefaultView(Helper::diagramViewForSettings);
  }
  // read move connectors together
  if (mpSettings->contains("modeling/moveConnectorsTogether")) {
    mpGraphicalViewsPage->getMoveConnectorsTogetherCheckBox()->setChecked(mpSettings->value("modeling/moveConnectorsTogether").toBool());
  } else {
    mpGraphicalViewsPage->getMoveConnectorsTogetherCheckBox()->setChecked(OptionsDefaults::GraphicalViewsPage::moveConnectorsTogether);
  }
}

//! Reads the Simulation section settings from omedit.ini
void OptionsDialog::readSimulationSettings()
{
  SimulationOptions simulationOptions;
  int currentIndex;
  if (mpSettings->contains("simulation/matchingAlgorithm")) {
    currentIndex = mpSimulationPage->getTranslationFlagsWidget()->getMatchingAlgorithmComboBox()->findText(mpSettings->value("simulation/matchingAlgorithm").toString(), Qt::MatchExactly);
  } else {
    currentIndex = mpSimulationPage->getTranslationFlagsWidget()->getMatchingAlgorithmComboBox()->findText(simulationOptions.getMatchingAlgorithm(), Qt::MatchExactly);
  }
  if (currentIndex > -1) {
    mpSimulationPage->getTranslationFlagsWidget()->getMatchingAlgorithmComboBox()->setCurrentIndex(currentIndex);
  }
  mMatchingAlgorithm = mpSimulationPage->getTranslationFlagsWidget()->getMatchingAlgorithmComboBox()->currentText();

  if (mpSettings->contains("simulation/indexReductionMethod")) {
    currentIndex = mpSimulationPage->getTranslationFlagsWidget()->getIndexReductionMethodComboBox()->findText(mpSettings->value("simulation/indexReductionMethod").toString(), Qt::MatchExactly);
  } else {
    currentIndex = mpSimulationPage->getTranslationFlagsWidget()->getIndexReductionMethodComboBox()->findText(simulationOptions.getIndexReductionMethod(), Qt::MatchExactly);
  }
  if (currentIndex > -1) {
    mpSimulationPage->getTranslationFlagsWidget()->getIndexReductionMethodComboBox()->setCurrentIndex(currentIndex);
  }
  mIndexReductionMethod = mpSimulationPage->getTranslationFlagsWidget()->getIndexReductionMethodComboBox()->currentText();
  // read initialization
  if (mpSettings->contains("simulation/initialization")) {
    mpSimulationPage->getTranslationFlagsWidget()->getInitializationCheckBox()->setChecked(mpSettings->value("simulation/initialization").toBool());
  } else {
    mpSimulationPage->getTranslationFlagsWidget()->getInitializationCheckBox()->setChecked(simulationOptions.getInitialization());
  }
  mInitialization = mpSimulationPage->getTranslationFlagsWidget()->getInitializationCheckBox()->isChecked();
  // read evaluate all parameters
  if (mpSettings->contains("simulation/evaluateAllParameters")) {
    mpSimulationPage->getTranslationFlagsWidget()->getEvaluateAllParametersCheckBox()->setChecked(mpSettings->value("simulation/evaluateAllParameters").toBool());
  } else {
    mpSimulationPage->getTranslationFlagsWidget()->getEvaluateAllParametersCheckBox()->setChecked(simulationOptions.getEvaluateAllParameters());
  }
  mEvaluateAllParameters = mpSimulationPage->getTranslationFlagsWidget()->getEvaluateAllParametersCheckBox()->isChecked();
  // read NLS analytic jacobian
  if (mpSettings->contains("simulation/NLSanalyticJacobian")) {
    mpSimulationPage->getTranslationFlagsWidget()->getNLSanalyticJacobianCheckBox()->setChecked(mpSettings->value("simulation/NLSanalyticJacobian").toBool());
  } else {
    mpSimulationPage->getTranslationFlagsWidget()->getNLSanalyticJacobianCheckBox()->setChecked(simulationOptions.getNLSanalyticJacobian());
  }
  mNLSanalyticJacobian = mpSimulationPage->getTranslationFlagsWidget()->getNLSanalyticJacobianCheckBox()->isChecked();
  // read parmodauto
  if (mpSettings->contains("simulation/parmodauto")) {
    mpSimulationPage->getTranslationFlagsWidget()->getParmodautoCheckBox()->setChecked(mpSettings->value("simulation/parmodauto").toBool());
  } else {
    mpSimulationPage->getTranslationFlagsWidget()->getParmodautoCheckBox()->setChecked(simulationOptions.getParmodauto());
  }
  mParmodauto = mpSimulationPage->getTranslationFlagsWidget()->getParmodautoCheckBox()->isChecked();
  // read old instantiation
  if (mpSettings->contains("simulation/newInst")) {
    mpSimulationPage->getTranslationFlagsWidget()->getOldInstantiationCheckBox()->setChecked(!mpSettings->value("simulation/newInst").toBool());
  } else {
    mpSimulationPage->getTranslationFlagsWidget()->getOldInstantiationCheckBox()->setChecked(simulationOptions.getOldInstantiation());
  }
  mOldInstantiation = !mpSimulationPage->getTranslationFlagsWidget()->getOldInstantiationCheckBox()->isChecked();
  // read enable FMU import
  if (mpSettings->contains("simulation/enableFMUImport")) {
    mpSimulationPage->getTranslationFlagsWidget()->getEnableFMUImportCheckBox()->setChecked(mpSettings->value("simulation/enableFMUImport").toBool());
  } else {
    mpSimulationPage->getTranslationFlagsWidget()->getEnableFMUImportCheckBox()->setChecked(simulationOptions.getEnableFMUImport());
  }
  mEnableFMUImport = mpSimulationPage->getTranslationFlagsWidget()->getEnableFMUImportCheckBox()->isChecked();
  // read additional translation flags
  if (mpSettings->contains("simulation/OMCFlags")) {
    mpSimulationPage->getTranslationFlagsWidget()->getAdditionalTranslationFlagsTextBox()->setText(mpSettings->value("simulation/OMCFlags").toString());
  } else {
    mpSimulationPage->getTranslationFlagsWidget()->getAdditionalTranslationFlagsTextBox()->setText(simulationOptions.getAdditionalSimulationFlags());
  }
  mAdditionalTranslationFlags = mpSimulationPage->getTranslationFlagsWidget()->getAdditionalTranslationFlagsTextBox()->text();
  // read target language
  if (mpSettings->contains("simulation/targetLanguage")) {
    currentIndex = mpSimulationPage->getTargetLanguageComboBox()->findText(mpSettings->value("simulation/targetLanguage").toString(), Qt::MatchExactly);
  } else {
    currentIndex = mpSimulationPage->getTargetLanguageComboBox()->findText(simulationOptions.getTargetLanguage(), Qt::MatchExactly);
  }
  if (currentIndex > -1) {
    mpSimulationPage->getTargetLanguageComboBox()->setCurrentIndex(currentIndex);
  }
  // read target compiler
  if (mpSettings->contains("simulation/targetCompiler")) {
    currentIndex = mpSimulationPage->getTargetBuildComboBox()->findData(mpSettings->value("simulation/targetCompiler"), Qt::UserRole, Qt::MatchExactly);
  } else {
    currentIndex = mpSimulationPage->getTargetBuildComboBox()->findData(OptionsDefaults::Simulation::targetBuild, Qt::UserRole, Qt::MatchExactly);
  }
  if (currentIndex > -1) {
    mpSimulationPage->getTargetBuildComboBox()->setCurrentIndex(currentIndex);
  }

  if (mpSettings->contains("simulation/compiler")) {
    mpSimulationPage->getCompilerComboBox()->lineEdit()->setText(mpSettings->value("simulation/compiler").toString());
  } else {
    mpSimulationPage->getCompilerComboBox()->lineEdit()->setText(OptionsDefaults::Simulation::cCompiler);
  }

  if (mpSettings->contains("simulation/cxxCompiler")) {
    mpSimulationPage->getCXXCompilerComboBox()->lineEdit()->setText(mpSettings->value("simulation/cxxCompiler").toString());
  } else {
    mpSimulationPage->getCXXCompilerComboBox()->lineEdit()->setText(OptionsDefaults::Simulation::cxxCompiler);
  }

#ifdef Q_OS_WIN
  if (mpSettings->contains("simulation/useStaticLinking")) {
    mpSimulationPage->getUseStaticLinkingCheckBox()->setChecked(mpSettings->value("simulation/useStaticLinking").toBool());
  } else {
    mpSimulationPage->getUseStaticLinkingCheckBox()->setChecked(OptionsDefaults::Simulation::useStaticLinking);
  }
#endif

  if (mpSettings->contains("simulation/postCompilationCommand")) {
    mpSimulationPage->setPostCompilationCommand(mpSettings->value("simulation/postCompilationCommand").toString());
  } else {
    mpSimulationPage->setPostCompilationCommand(OptionsDefaults::Simulation::postCompilationCommand);
  }

  if (mpSettings->contains("simulation/ignoreCommandLineOptionsAnnotation")) {
    mpSimulationPage->getIgnoreCommandLineOptionsAnnotationCheckBox()->setChecked(mpSettings->value("simulation/ignoreCommandLineOptionsAnnotation").toBool());
  } else {
    mpSimulationPage->getIgnoreCommandLineOptionsAnnotationCheckBox()->setChecked(OptionsDefaults::Simulation::ignoreCommandLineOptionsAnnotation);
  }

  if (mpSettings->contains("simulation/ignoreSimulationFlagsAnnotation")) {
    mpSimulationPage->getIgnoreSimulationFlagsAnnotationCheckBox()->setChecked(mpSettings->value("simulation/ignoreSimulationFlagsAnnotation").toBool());
  } else {
    mpSimulationPage->getIgnoreSimulationFlagsAnnotationCheckBox()->setChecked(OptionsDefaults::Simulation::ignoreSimulationFlagsAnnotation);
  }

  if (mpSettings->contains("simulation/saveClassBeforeSimulation")) {
    mpSimulationPage->getSaveClassBeforeSimulationCheckBox()->setChecked(mpSettings->value("simulation/saveClassBeforeSimulation").toBool());
  } else {
    mpSimulationPage->getSaveClassBeforeSimulationCheckBox()->setChecked(OptionsDefaults::Simulation::saveClassBeforeSimulation);
  }

  if (mpSettings->contains("simulation/switchToPlottingPerspectiveAfterSimulation")) {
    mpSimulationPage->getSwitchToPlottingPerspectiveCheckBox()->setChecked(mpSettings->value("simulation/switchToPlottingPerspectiveAfterSimulation").toBool());
  } else {
    mpSimulationPage->getSwitchToPlottingPerspectiveCheckBox()->setChecked(OptionsDefaults::Simulation::switchToPlottingPerspective);
  }

  if (mpSettings->contains("simulation/closeSimulationOutputWidgetsBeforeSimulation")) {
    mpSimulationPage->getCloseSimulationOutputWidgetsBeforeSimulationCheckBox()->setChecked(mpSettings->value("simulation/closeSimulationOutputWidgetsBeforeSimulation").toBool());
  } else {
    mpSimulationPage->getCloseSimulationOutputWidgetsBeforeSimulationCheckBox()->setChecked(OptionsDefaults::Simulation::closeSimulationOutputWidgetsBeforeSimulation);
  }

  if (mpSettings->contains("simulation/deleteIntermediateCompilationFiles")) {
    mpSimulationPage->getDeleteIntermediateCompilationFilesCheckBox()->setChecked(mpSettings->value("simulation/deleteIntermediateCompilationFiles").toBool());
  } else {
    mpSimulationPage->getDeleteIntermediateCompilationFilesCheckBox()->setChecked(OptionsDefaults::Simulation::deleteIntermediateCompilationFiles);
  }

  if (mpSettings->contains("simulation/deleteEntireSimulationDirectory")) {
    mpSimulationPage->getDeleteEntireSimulationDirectoryCheckBox()->setChecked(mpSettings->value("simulation/deleteEntireSimulationDirectory").toBool());
  } else {
    mpSimulationPage->getDeleteEntireSimulationDirectoryCheckBox()->setChecked(OptionsDefaults::Simulation::deleteEntireSimulationDirectory);
  }

  if (mpSettings->contains("simulation/outputMode")) {
    mpSimulationPage->setOutputMode(mpSettings->value("simulation/outputMode").toString());
  } else {
    mpSimulationPage->setOutputMode(Helper::structuredOutput);
  }

  if (mpSettings->contains("simulation/displayLimit")) {
    mpSimulationPage->getDisplayLimitSpinBox()->setValue(mpSettings->value("simulation/displayLimit").toInt());
  } else {
    mpSimulationPage->getDisplayLimitSpinBox()->setValue(OptionsDefaults::Simulation::displayLimit);
  }
}
//! Reads the Messages section settings from omedit.ini
void OptionsDialog::readMessagesSettings()
{
  // read output size
  if (mpSettings->contains("messages/outputSize")) {
    mpMessagesPage->getOutputSizeSpinBox()->setValue(mpSettings->value("messages/outputSize").toInt());
  } else {
    mpMessagesPage->getOutputSizeSpinBox()->setValue(OptionsDefaults::Messages::outputSize);
  }
  // read reset messages number
  if (mpSettings->contains("messages/resetMessagesNumber")) {
    mpMessagesPage->getResetMessagesNumberBeforeSimulationCheckBox()->setChecked(mpSettings->value("messages/resetMessagesNumber").toBool());
  } else {
    mpMessagesPage->getResetMessagesNumberBeforeSimulationCheckBox()->setChecked(OptionsDefaults::Messages::resetMessagesNumberBeforeSimulation);
  }
  // read clear message browser
  if (mpSettings->contains("messages/clearMessagesBrowser")) {
    mpMessagesPage->getClearMessagesBrowserBeforeSimulationCheckBox()->setChecked(mpSettings->value("messages/clearMessagesBrowser").toBool());
  } else {
    mpMessagesPage->getClearMessagesBrowserBeforeSimulationCheckBox()->setChecked(OptionsDefaults::Messages::clearMessagesBrowserBeforeSimulation);
  }
  // read enlarge message browser
  if (mpSettings->contains("messages/enlargeMessagesBrowser")) {
    mpMessagesPage->getEnlargeMessageBrowserCheckBox()->setChecked(mpSettings->value("messages/enlargeMessagesBrowser").toBool());
  } else {
    mpMessagesPage->getEnlargeMessageBrowserCheckBox()->setChecked(OptionsDefaults::Messages::enlargeMessageBrowserCheckBox);
  }
  // read font family
  QTextBrowser textBrowser;
  if (mpSettings->contains("messages/fontFamily")) {
    // select font family item
    int currentIndex = mpMessagesPage->getFontFamilyComboBox()->findText(mpSettings->value("messages/fontFamily").toString(), Qt::MatchExactly);
    mpMessagesPage->getFontFamilyComboBox()->setCurrentIndex(currentIndex);
  } else {
    int currentIndex = mpMessagesPage->getFontFamilyComboBox()->findText(textBrowser.font().family(), Qt::MatchExactly);
    mpMessagesPage->getFontFamilyComboBox()->setCurrentIndex(currentIndex);
  }
  // read font size
  if (mpSettings->contains("messages/fontSize")) {
    mpMessagesPage->getFontSizeSpinBox()->setValue(mpSettings->value("messages/fontSize").toDouble());
  } else {
    mpMessagesPage->getFontSizeSpinBox()->setValue(textBrowser.font().pointSize());
  }
  // read notification color
  if (mpSettings->contains("messages/notificationColor")) {
    QColor color = QColor(mpSettings->value("messages/notificationColor").toUInt());
    if (color.isValid()) {
      mpMessagesPage->setNotificationColor(color);
      mpMessagesPage->setNotificationPickColorButtonIcon();
    }
  } else {
    mpMessagesPage->setNotificationColor(OptionsDefaults::Messages::notificationColor);
    mpMessagesPage->setNotificationPickColorButtonIcon();
  }
  // read warning color
  if (mpSettings->contains("messages/warningColor")) {
    QColor color = QColor(mpSettings->value("messages/warningColor").toUInt());
    if (color.isValid()) {
      mpMessagesPage->setWarningColor(color);
      mpMessagesPage->setWarningPickColorButtonIcon();
    }
  } else {
    mpMessagesPage->setWarningColor(OptionsDefaults::Messages::warningColor);
    mpMessagesPage->setWarningPickColorButtonIcon();
  }
  // read error color
  if (mpSettings->contains("messages/errorColor")) {
    QColor color = QColor(mpSettings->value("messages/errorColor").toUInt());
    if (color.isValid()) {
      mpMessagesPage->setErrorColor(color);
      mpMessagesPage->setErrorPickColorButtonIcon();
    }
  } else {
    mpMessagesPage->setErrorColor(OptionsDefaults::Messages::errorColor);
    mpMessagesPage->setErrorPickColorButtonIcon();
  }
}

//! Reads the Notifications section settings from omedit.ini
void OptionsDialog::readNotificationsSettings()
{
  if (mpSettings->contains("notifications/promptQuitApplication")) {
    mpNotificationsPage->getQuitApplicationCheckBox()->setChecked(mpSettings->value("notifications/promptQuitApplication").toBool());
  } else {
    mpNotificationsPage->getQuitApplicationCheckBox()->setChecked(OptionsDefaults::Notification::quitApplication);
  }

  if (mpSettings->contains("notifications/itemDroppedOnItself")) {
    mpNotificationsPage->getItemDroppedOnItselfCheckBox()->setChecked(mpSettings->value("notifications/itemDroppedOnItself").toBool());
  } else {
    mpNotificationsPage->getItemDroppedOnItselfCheckBox()->setChecked(OptionsDefaults::Notification::itemDroppedOnItself);
  }

  if (mpSettings->contains("notifications/replaceableIfPartial")) {
    mpNotificationsPage->getReplaceableIfPartialCheckBox()->setChecked(mpSettings->value("notifications/replaceableIfPartial").toBool());
  } else {
    mpNotificationsPage->getReplaceableIfPartialCheckBox()->setChecked(OptionsDefaults::Notification::replaceableIfPartial);
  }

  if (mpSettings->contains("notifications/innerModelNameChanged")) {
    mpNotificationsPage->getInnerModelNameChangedCheckBox()->setChecked(mpSettings->value("notifications/innerModelNameChanged").toBool());
  } else {
    mpNotificationsPage->getInnerModelNameChangedCheckBox()->setChecked(OptionsDefaults::Notification::innerModelNameChanged);
  }

  if (mpSettings->contains("notifications/saveModelForBitmapInsertion")) {
    mpNotificationsPage->getSaveModelForBitmapInsertionCheckBox()->setChecked(mpSettings->value("notifications/saveModelForBitmapInsertion").toBool());
  } else {
    mpNotificationsPage->getSaveModelForBitmapInsertionCheckBox()->setChecked(OptionsDefaults::Notification::saveModelForBitmapInsertion);
  }

  if (mpSettings->contains("notifications/alwaysAskForDraggedComponentName")) {
    mpNotificationsPage->getAlwaysAskForDraggedComponentName()->setChecked(mpSettings->value("notifications/alwaysAskForDraggedComponentName").toBool());
  } else {
    mpNotificationsPage->getAlwaysAskForDraggedComponentName()->setChecked(OptionsDefaults::Notification::alwaysAskForDraggedComponentName);
  }

  if (mpSettings->contains("notifications/alwaysAskForTextEditorError")) {
    mpNotificationsPage->getAlwaysAskForTextEditorErrorCheckBox()->setChecked(mpSettings->value("notifications/alwaysAskForTextEditorError").toBool());
  } else {
    mpNotificationsPage->getAlwaysAskForTextEditorErrorCheckBox()->setChecked(OptionsDefaults::Notification::alwaysAskForTextEditorError);
  }
}

//! Reads the LineStyle section settings from omedit.ini
void OptionsDialog::readLineStyleSettings()
{
  if (mpSettings->contains("linestyle/color")) {
    QColor color = QColor(mpSettings->value("linestyle/color").toUInt());
    if (color.isValid()) {
      mpLineStylePage->setLineColor(color);
      mpLineStylePage->setLinePickColorButtonIcon();
    }
  } else {
    mpLineStylePage->setLineColor(OptionsDefaults::LineStyle::color);
    mpLineStylePage->setLinePickColorButtonIcon();
  }

  if (mpSettings->contains("linestyle/pattern")) {
    mpLineStylePage->setLinePattern(mpSettings->value("linestyle/pattern").toString());
  } else {
    mpLineStylePage->setLinePattern(OptionsDefaults::LineStyle::pattern);
  }

  if (mpSettings->contains("linestyle/thickness")) {
    mpLineStylePage->setLineThickness(mpSettings->value("linestyle/thickness").toDouble());
  } else {
    mpLineStylePage->setLineThickness(OptionsDefaults::LineStyle::thickness);
  }

  if (mpSettings->contains("linestyle/startArrow")) {
    mpLineStylePage->setLineStartArrow(mpSettings->value("linestyle/startArrow").toString());
  } else {
    mpLineStylePage->setLineStartArrow(OptionsDefaults::LineStyle::startArrow);
  }

  if (mpSettings->contains("linestyle/endArrow")) {
    mpLineStylePage->setLineEndArrow(mpSettings->value("linestyle/endArrow").toString());
  } else {
    mpLineStylePage->setLineEndArrow(OptionsDefaults::LineStyle::endArrow);
  }

  if (mpSettings->contains("linestyle/arrowSize")) {
    mpLineStylePage->setLineArrowSize(mpSettings->value("linestyle/arrowSize").toDouble());
  } else {
    mpLineStylePage->setLineArrowSize(OptionsDefaults::LineStyle::arrowSize);
  }

  if (mpSettings->contains("linestyle/smooth")) {
    mpLineStylePage->setLineSmooth(mpSettings->value("linestyle/smooth").toBool());
  } else {
    mpLineStylePage->setLineSmooth(OptionsDefaults::LineStyle::smooth);
  }
}

//! Reads the FillStyle section settings from omedit.ini
void OptionsDialog::readFillStyleSettings()
{
  if (mpSettings->contains("fillstyle/color")) {
    QColor color = QColor(mpSettings->value("fillstyle/color").toUInt());
    if (color.isValid()) {
      mpFillStylePage->setFillColor(color);
      mpFillStylePage->setFillPickColorButtonIcon();
    }
  } else {
    mpFillStylePage->setFillColor(OptionsDefaults::FillStyle::color);
    mpFillStylePage->setFillPickColorButtonIcon();
  }

  if (mpSettings->contains("fillstyle/pattern")) {
    mpFillStylePage->setFillPattern(mpSettings->value("fillstyle/pattern").toString());
  } else {
    mpFillStylePage->setFillPattern(OptionsDefaults::FillStyle::pattern);
  }
}

//! Reads the Plotting section settings from omedit.ini
void OptionsDialog::readPlottingSettings()
{
  // read the auto scale
  if (mpSettings->contains("plotting/autoScale")) {
    mpPlottingPage->getAutoScaleCheckBox()->setChecked(mpSettings->value("plotting/autoScale").toBool());
  } else {
    mpPlottingPage->getAutoScaleCheckBox()->setChecked(OptionsDefaults::Plotting::autoScale);
  }
  // read the prefix units
  if (mpSettings->contains("plotting/prefixUnits")) {
    mpPlottingPage->getPrefixUnitsCheckbox()->setChecked(mpSettings->value("plotting/prefixUnits").toBool());
  } else {
    mpPlottingPage->getPrefixUnitsCheckbox()->setChecked(OptionsDefaults::Plotting::prefixUnits);
  }
  // read the plotting view mode
  if (mpSettings->contains("plotting/viewmode")) {
    mpPlottingPage->setPlottingViewMode(mpSettings->value("plotting/viewmode").toString());
  } else {
    mpPlottingPage->setPlottingViewMode(Helper::tabbed);
  }
  // read curve pattern
  if (mpSettings->contains("curvestyle/pattern")) {
    mpPlottingPage->setCurvePattern(mpSettings->value("curvestyle/pattern").toInt());
  } else {
    mpPlottingPage->setCurvePattern(OptionsDefaults::Plotting::curvePattern);
  }
  // read curve thickness
  if (mpSettings->contains("curvestyle/thickness")) {
    mpPlottingPage->setCurveThickness(mpSettings->value("curvestyle/thickness").toDouble());
  } else {
    mpPlottingPage->setCurveThickness(OptionsDefaults::Plotting::curveThickness);
  }

  if (mpSettings->contains("variableFilter/interval")) {
    mpPlottingPage->getFilterIntervalSpinBox()->setValue(mpSettings->value("variableFilter/interval").toInt());
  } else {
    mpPlottingPage->getFilterIntervalSpinBox()->setValue(OptionsDefaults::Plotting::variableFilterInterval);
  }

  if (mpSettings->contains("plotting/titleFontSize")) {
    mpPlottingPage->getTitleFontSizeSpinBox()->setValue(mpSettings->value("plotting/titleFontSize").toDouble());
  } else {
    mpPlottingPage->getTitleFontSizeSpinBox()->setValue(OptionsDefaults::Plotting::titleFontSize);
  }

  if (mpSettings->contains("plotting/verticalAxisTitleFontSize")) {
    mpPlottingPage->getVerticalAxisTitleFontSizeSpinBox()->setValue(mpSettings->value("plotting/verticalAxisTitleFontSize").toDouble());
  } else {
    mpPlottingPage->getVerticalAxisTitleFontSizeSpinBox()->setValue(OptionsDefaults::Plotting::verticalAxisTitleFontSize);
  }

  if (mpSettings->contains("plotting/verticalAxisNumbersFontSize")) {
    mpPlottingPage->getVerticalAxisNumbersFontSizeSpinBox()->setValue(mpSettings->value("plotting/verticalAxisNumbersFontSize").toDouble());
  } else {
    mpPlottingPage->getVerticalAxisNumbersFontSizeSpinBox()->setValue(OptionsDefaults::Plotting::verticalAxisNumbersFontSize);
  }

  if (mpSettings->contains("plotting/horizontalAxisTitleFontSize")) {
    mpPlottingPage->getHorizontalAxisTitleFontSizeSpinBox()->setValue(mpSettings->value("plotting/horizontalAxisTitleFontSize").toDouble());
  } else {
    mpPlottingPage->getHorizontalAxisTitleFontSizeSpinBox()->setValue(OptionsDefaults::Plotting::horizontalAxisTitleFontSize);
  }

  if (mpSettings->contains("plotting/horizontalAxisNumbersFontSize")) {
    mpPlottingPage->getHorizontalAxisNumbersFontSizeSpinBox()->setValue(mpSettings->value("plotting/horizontalAxisNumbersFontSize").toDouble());
  } else {
    mpPlottingPage->getHorizontalAxisNumbersFontSizeSpinBox()->setValue(OptionsDefaults::Plotting::horizontalAxisNumbersFontSize);
  }

  if (mpSettings->contains("plotting/footerFontSize")) {
    mpPlottingPage->getFooterFontSizeSpinBox()->setValue(mpSettings->value("plotting/footerFontSize").toDouble());
  } else {
    mpPlottingPage->getFooterFontSizeSpinBox()->setValue(QApplication::font().pointSize());
  }

  if (mpSettings->contains("plotting/legendFontSize")) {
    mpPlottingPage->getLegendFontSizeSpinBox()->setValue(mpSettings->value("plotting/legendFontSize").toDouble());
  } else {
    mpPlottingPage->getLegendFontSizeSpinBox()->setValue(QApplication::font().pointSize());
  }
}

//! Reads the Fiagro section settings from omedit.ini
void OptionsDialog::readFigaroSettings()
{
  if (mpSettings->contains("figaro/databasefile")) {
    mpFigaroPage->getFigaroDatabaseFileTextBox()->setText(mpSettings->value("figaro/databasefile").toString());
  } else {
    mpFigaroPage->getFigaroDatabaseFileTextBox()->setText(OptionsDefaults::Figaro::databaseFile);
  }

  if (mpSettings->contains("figaro/options")) {
    mpFigaroPage->getFigaroOptionsTextBox()->setText(mpSettings->value("figaro/options").toString());
  } else {
    mpFigaroPage->getFigaroOptionsTextBox()->setText(OptionsDefaults::Figaro::options);
  }

  if (mpSettings->contains("figaro/process") && !mpSettings->value("figaro/process").toString().isEmpty()) {
    mpFigaroPage->getFigaroProcessTextBox()->setText(mpSettings->value("figaro/process").toString());
  } else {
    mpFigaroPage->getFigaroProcessTextBox()->setText(OptionsDefaults::Figaro::process);
  }
}

/*!
 * \brief OptionsDialog::readCRMLSettings
 * Reads the CRML section settings from omedit.ini
 */
void OptionsDialog::readCRMLSettings()
{
  if (mpSettings->contains("crml/compilerjar")) {
    mpCRMLPage->getCompilerJarTextBox()->setText(mpSettings->value("crml/compilerjar").toString());
  } else {
    mpCRMLPage->getCompilerJarTextBox()->setText(OptionsDefaults::CRML::compilerJar);
  }

  if (mpSettings->contains("crml/commandlineparameters")) {
    mpCRMLPage->getCompilerCommandLineOptionsTextBox()->setText(mpSettings->value("crml/commandlineparameters").toString());
  }

  if (mpSettings->contains("crml/process") && !mpSettings->value("crml/process").toString().isEmpty()) {
    mpCRMLPage->getCompilerProcessTextBox()->setText(mpSettings->value("crml/process").toString());
  } else {
    mpCRMLPage->getCompilerProcessTextBox()->setText(OptionsDefaults::CRML::process);
  }

  if (mpSettings->contains("crml/modelicaLibraries")) {
    mpCRMLPage->getModelicaLibraries()->setItems(mpSettings->value("crml/modelicaLibraries").toStringList());
  } else {
    mpCRMLPage->getModelicaLibraries()->setItems({});
  }
}

/*!
  Reads the Debugger section settings from omedit.ini
  */
void OptionsDialog::readDebuggerSettings()
{
  if (mpSettings->contains("algorithmicDebugger/GDBPath")) {
    mpDebuggerPage->setGDBPath(mpSettings->value("algorithmicDebugger/GDBPath").toString());
  } else {
    mpDebuggerPage->setGDBPath("");
  }

  if (mpSettings->contains("algorithmicDebugger/GDBCommandTimeout")) {
    mpDebuggerPage->getGDBCommandTimeoutSpinBox()->setValue(mpSettings->value("algorithmicDebugger/GDBCommandTimeout").toInt());
  } else {
    mpDebuggerPage->getGDBCommandTimeoutSpinBox()->setValue(OptionsDefaults::Debugger::GDBCommandTimeout);
  }

  if (mpSettings->contains("algorithmicDebugger/GDBOutputLimit")) {
    mpDebuggerPage->getGDBOutputLimitSpinBox()->setValue(mpSettings->value("algorithmicDebugger/GDBOutputLimit").toInt());
  } else {
    mpDebuggerPage->getGDBOutputLimitSpinBox()->setValue(OptionsDefaults::Debugger::GDBOutputLimit);
  }

  if (mpSettings->contains("algorithmicDebugger/displayCFrames")) {
    mpDebuggerPage->getDisplayCFramesCheckBox()->setChecked(mpSettings->value("algorithmicDebugger/displayCFrames").toBool());
  } else {
    mpDebuggerPage->getDisplayCFramesCheckBox()->setChecked(OptionsDefaults::Debugger::displayCFrames);
  }

  if (mpSettings->contains("algorithmicDebugger/displayUnknownFrames")) {
    mpDebuggerPage->getDisplayUnknownFramesCheckBox()->setChecked(mpSettings->value("algorithmicDebugger/displayUnknownFrames").toBool());
  } else {
    mpDebuggerPage->getDisplayUnknownFramesCheckBox()->setChecked(OptionsDefaults::Debugger::displayUnknownFrames);
  }

  if (mpSettings->contains("algorithmicDebugger/clearOutputOnNewRun")) {
    mpDebuggerPage->getClearOutputOnNewRunCheckBox()->setChecked(mpSettings->value("algorithmicDebugger/clearOutputOnNewRun").toBool());
  } else {
    mpDebuggerPage->getClearOutputOnNewRunCheckBox()->setChecked(OptionsDefaults::Debugger::clearOutputOnNewRun);
  }

  if (mpSettings->contains("algorithmicDebugger/clearLogOnNewRun")) {
    mpDebuggerPage->getClearLogOnNewRunCheckBox()->setChecked(mpSettings->value("algorithmicDebugger/clearLogOnNewRun").toBool());
  } else {
    mpDebuggerPage->getClearLogOnNewRunCheckBox()->setChecked(OptionsDefaults::Debugger::clearLogOnNewRun);
  }

  if (mpSettings->contains("transformationalDebugger/alwaysShowTransformationalDebugger")) {
    mpDebuggerPage->getAlwaysShowTransformationsCheckBox()->setChecked(mpSettings->value("transformationalDebugger/alwaysShowTransformationalDebugger").toBool());
  } else {
    mpDebuggerPage->getAlwaysShowTransformationsCheckBox()->setChecked(OptionsDefaults::Debugger::alwaysShowTransformationalDebugger);
  }

  if (mpSettings->contains("transformationalDebugger/generateOperations")) {
    mpDebuggerPage->getGenerateOperationsCheckBox()->setChecked(mpSettings->value("transformationalDebugger/generateOperations").toBool());
  } else {
    mpDebuggerPage->getGenerateOperationsCheckBox()->setChecked(OptionsDefaults::Debugger::generateOperations);
  }
}

/*!
 * \brief OptionsDialog::readFMISettings
 * Reads the FMI section settings from omedit.ini
 */
void OptionsDialog::readFMISettings()
{
  if (mpSettings->contains("FMIExport/Version")) {
    mpFMIPage->setFMIExportVersion(mpSettings->value("FMIExport/Version").toString());
  } else {
    mpFMIPage->setFMIExportVersion(OptionsDefaults::FMI::version);
  }

  if (mpSettings->contains("FMIExport/Type")) {
    mpFMIPage->setFMIExportType(mpSettings->value("FMIExport/Type").toString());
  } else {
    mpFMIPage->setFMIExportType(OptionsDefaults::FMI::type);
  }

  if (mpSettings->contains("FMIExport/FMUName")) {
    mpFMIPage->getFMUNameTextBox()->setText(mpSettings->value("FMIExport/FMUName").toString());
  } else {
    mpFMIPage->getFMUNameTextBox()->setText(OptionsDefaults::FMI::FMUName);
  }

  if (mpSettings->contains("FMIExport/MoveFMU")) {
    mpFMIPage->getMoveFMUTextBox()->setText(mpSettings->value("FMIExport/MoveFMU").toString());
  } else {
    mpFMIPage->getMoveFMUTextBox()->setText(OptionsDefaults::FMI::moveFMU);
  }

  // read platforms
  if (mpSettings->contains("FMIExport/Platforms")) {
    QStringList platforms = mpSettings->value("FMIExport/Platforms").toStringList();
    int i = 0;
    while (QLayoutItem* pLayoutItem = mpFMIPage->getPlatformsGroupBox()->layout()->itemAt(i)) {
      if (dynamic_cast<QCheckBox*>(pLayoutItem->widget())) {
        QCheckBox *pPlatformCheckBox = dynamic_cast<QCheckBox*>(pLayoutItem->widget());
        if (platforms.contains(pPlatformCheckBox->property(Helper::fmuPlatformNamePropertyId).toString())) {
          pPlatformCheckBox->setChecked(true);
          platforms.removeOne(pPlatformCheckBox->property(Helper::fmuPlatformNamePropertyId).toString());
        } else {
          pPlatformCheckBox->setChecked(false);
        }
      } else if (dynamic_cast<QLineEdit*>(pLayoutItem->widget())) { // custom platforms
        QLineEdit *pPlatformTextBox = dynamic_cast<QLineEdit*>(pLayoutItem->widget());
        pPlatformTextBox->setText(platforms.join(","));
      }
      i++;
    }
  }
  // read the solver for co-simulation
  int currentIndex;
  if (mpSettings->contains("FMIExport/solver")) {
    currentIndex = mpFMIPage->getSolverForCoSimulationComboBox()->findData(mpSettings->value("FMIExport/solver").toString());
  } else {
    currentIndex = mpFMIPage->getSolverForCoSimulationComboBox()->findData(OptionsDefaults::FMI::solver);
  }
  if (currentIndex > -1) {
    mpFMIPage->getSolverForCoSimulationComboBox()->setCurrentIndex(currentIndex);
  }
  // read model description filter
  if (mpSettings->contains("FMIExport/ModelDescriptionFilter")) {
    currentIndex = mpFMIPage->getModelDescriptionFiltersComboBox()->findText(mpSettings->value("FMIExport/ModelDescriptionFilter").toString());
  } else {
    currentIndex = mpFMIPage->getModelDescriptionFiltersComboBox()->findText(OptionsDefaults::FMI::modelDescriptionFilter);
  }
  if (currentIndex > -1) {
    mpFMIPage->getModelDescriptionFiltersComboBox()->setCurrentIndex(currentIndex);
  }
  // read include resources
  if (mpSettings->contains("FMIExport/IncludeResources")) {
    mpFMIPage->getIncludeResourcesCheckBox()->setChecked(mpSettings->value("FMIExport/IncludeResources").toBool());
  } else {
    mpFMIPage->getIncludeResourcesCheckBox()->setChecked(OptionsDefaults::FMI::includeResources);
  }
  // read include source code
  if (mpSettings->contains("FMIExport/IncludeSourceCode")) {
    mpFMIPage->getIncludeSourceCodeCheckBox()->setChecked(mpSettings->value("FMIExport/IncludeSourceCode").toBool());
  } else {
    mpFMIPage->getIncludeSourceCodeCheckBox()->setChecked(OptionsDefaults::FMI::includeSourceCode);
  }
  // read generate debug symbols
  if (mpSettings->contains("FMIExport/GenerateDebugSymbols")) {
    mpFMIPage->getGenerateDebugSymbolsCheckBox()->setChecked(mpSettings->value("FMIExport/GenerateDebugSymbols").toBool());
  } else {
    mpFMIPage->getGenerateDebugSymbolsCheckBox()->setChecked(OptionsDefaults::FMI::generateDebugSymbols);
  }
  // read delete FMU directory
  if (mpSettings->contains("FMIImport/DeleteFMUDirectoyAndModel")) {
    mpFMIPage->getDeleteFMUDirectoryAndModelCheckBox()->setChecked(mpSettings->value("FMIImport/DeleteFMUDirectoyAndModel").toBool());
  } else {
    mpFMIPage->getDeleteFMUDirectoryAndModelCheckBox()->setChecked(OptionsDefaults::FMI::deleteFMUDirectoyAndModel);
  }
}

/*!
 * \brief OptionsDialog::readOMSimulatorSettings
 * Reads the OMSimulator settings from omedit.ini
 */
void OptionsDialog::readOMSimulatorSettings()
{
  // read command line options
  if (mpSettings->contains("OMSimulator/commandLineOptions")) {
    mpOMSimulatorPage->getCommandLineOptionsTextBox()->setText(mpSettings->value("OMSimulator/commandLineOptions").toString());
  } else {
    mpOMSimulatorPage->getCommandLineOptionsTextBox()->setText(OptionsDefaults::OMSimulator::commandLineOptions);
  }
  // read logging level
  int index;
  if (mpSettings->contains("OMSimulator/loggingLevel")) {
    index = mpOMSimulatorPage->getLoggingLevelComboBox()->findData(mpSettings->value("OMSimulator/loggingLevel").toInt());
  } else {
    index = mpOMSimulatorPage->getLoggingLevelComboBox()->findData(OptionsDefaults::OMSimulator::loggingLevel);
  }
  if (index > -1) {
    mpOMSimulatorPage->getLoggingLevelComboBox()->setCurrentIndex(index);
  }
}

/*!
 * \brief OptionsDialog::readSensitivityOptimizationSettings
 * Reads the Sensitivity and Optimization settings from omedit.ini
 */
void OptionsDialog::readSensitivityOptimizationSettings()
{
  // read OMSens backend
  if (mpSettings->contains("OMSens/backend")) {
    mpSensitivityOptimizationPage->getOMSensBackendPathTextBox()->setText(mpSettings->value("OMSens/backend").toString());
  }
  // read python
  if (mpSettings->contains("OMSens/python")) {
    mpSensitivityOptimizationPage->getPythonTextBox()->setText(mpSettings->value("OMSens/python").toString());
  } else {
    mpSensitivityOptimizationPage->getPythonTextBox()->setText(OptionsDefaults::SensitivityOptimization::python);
  }
}

/*!
 * \brief OptionsDialog::readTraceabilitySettings
 * Reads the  Traceability settings from omedit.ini
 */
void OptionsDialog::readTraceabilitySettings()
{
  // read traceability checkbox
  if (mpSettings->contains("traceability/Traceability")) {
    mpTraceabilityPage->getTraceabilityGroupBox()->setChecked(mpSettings->value("traceability/Traceability").toBool());
  } else {
    mpTraceabilityPage->getTraceabilityGroupBox()->setChecked(OptionsDefaults::Traceability::traceability);
  }
  // read user name
  if (mpSettings->contains("traceability/UserName")) {
    mpTraceabilityPage->getUserName()->setText(mpSettings->value("traceability/UserName").toString());
  } else {
    mpTraceabilityPage->getUserName()->setText(OptionsDefaults::Traceability::username);
  }
  // read Email
  if (mpSettings->contains("traceability/Email")) {
    mpTraceabilityPage->getEmail()->setText(mpSettings->value("traceability/Email").toString());
  } else {
    mpTraceabilityPage->getEmail()->setText(OptionsDefaults::Traceability::email);
  }
  // read Git repository
  if (mpSettings->contains("traceability/GitRepository")) {
    mpTraceabilityPage->getGitRepository()->setText(mpSettings->value("traceability/GitRepository").toString());
  } else {
    mpTraceabilityPage->getGitRepository()->setText(OptionsDefaults::Traceability::gitRepository);
  }
  // read the  traceability daemon IP-adress
  if (mpSettings->contains("traceability/IPAdress")) {
    mpTraceabilityPage->getTraceabilityDaemonIpAdress()->setText(mpSettings->value("traceability/IPAdress").toString());
  } else {
    mpTraceabilityPage->getTraceabilityDaemonIpAdress()->setText(OptionsDefaults::Traceability::ipAdress);
  }
  // read the traceability daemon Port
  if (mpSettings->contains("traceability/Port")) {
    mpTraceabilityPage->getTraceabilityDaemonPort()->setText(mpSettings->value("traceability/Port").toString());
  } else {
    mpTraceabilityPage->getTraceabilityDaemonPort()->setText(OptionsDefaults::Traceability::port);
  }
}

//! Saves the General section settings to omedit.ini
void OptionsDialog::saveGeneralSettings()
{
  // save Language option
  if (mpGeneralSettingsPage->getLanguageComboBox()->currentIndex() == 0) {
    mpSettings->remove("language");
  } else {
    mpSettings->setValue("language", mpGeneralSettingsPage->getLanguageComboBox()->itemData(mpGeneralSettingsPage->getLanguageComboBox()->currentIndex()).toLocale().name());
  }
  // save working directory
  const QString workingDirectory = mpGeneralSettingsPage->getWorkingDirectory();
  if (workingDirectory.isEmpty() || workingDirectory.compare(OptionsDefaults::GeneralSettings::workingDirectory) == 0) {
    mpSettings->remove("workingDirectory");
    MainWindow::instance()->getOMCProxy()->changeDirectory(OptionsDefaults::GeneralSettings::workingDirectory);
  } else if (!MainWindow::instance()->getOMCProxy()->changeDirectory(workingDirectory).isEmpty()) {
    mpSettings->setValue("workingDirectory", workingDirectory);
  }
  // save toolbar icon size
  int toolBarIconSize = mpGeneralSettingsPage->getToolbarIconSizeSpinBox()->value();
  if (toolBarIconSize == OptionsDefaults::GeneralSettings::toolBarIconSize) {
    mpSettings->remove("toolbarIconSize");
  } else {
    mpSettings->setValue("toolbarIconSize", toolBarIconSize);
  }
  // save user customizations
  bool preserveUserCustomizations = mpGeneralSettingsPage->getPreserveUserCustomizations();
  if (preserveUserCustomizations == OptionsDefaults::GeneralSettings::preserveUserCustomizations) {
    mpSettings->remove("userCustomizations");
  } else {
    mpSettings->setValue("userCustomizations", preserveUserCustomizations);
  }
  // save terminal command
  QString terminalCommand = mpGeneralSettingsPage->getTerminalCommand();
  if (terminalCommand.compare(OptionsDefaults::GeneralSettings::terminalCommand) == 0) {
    mpSettings->remove("terminalCommand");
  } else {
    mpSettings->setValue("terminalCommand", terminalCommand);
  }
  // save terminal command arguments
  QString terminalCommandArguments = mpGeneralSettingsPage->getTerminalCommandArguments();
  if (terminalCommandArguments.compare(OptionsDefaults::GeneralSettings::terminalCommandArguments) == 0) {
    mpSettings->remove("terminalCommandArgs");
  } else {
    mpSettings->setValue("terminalCommandArgs", terminalCommandArguments);
  }
  // save hide variable browser
  bool hideVariablesBrowser = mpGeneralSettingsPage->getHideVariablesBrowserCheckBox()->isChecked();
  if (hideVariablesBrowser == OptionsDefaults::GeneralSettings::hideVariablesBrowser) {
    mpSettings->remove("hideVariablesBrowser");
  } else {
    mpSettings->setValue("hideVariablesBrowser", hideVariablesBrowser);
  }
  // save activate access annotations
  int activateAccessAnnotationIndex = mpGeneralSettingsPage->getActivateAccessAnnotationsComboBox()->itemData(mpGeneralSettingsPage->getActivateAccessAnnotationsComboBox()->currentIndex()).toInt();
  if (activateAccessAnnotationIndex == OptionsDefaults::GeneralSettings::activateAccessAnnotationsIndex) {
    mpSettings->remove("activateAccessAnnotations");
  } else {
    mpSettings->setValue("activateAccessAnnotations", activateAccessAnnotationIndex);
  }
  // save create backup file
  bool createBackupFile = mpGeneralSettingsPage->getCreateBackupFileCheckbox()->isChecked();
  if (createBackupFile == OptionsDefaults::GeneralSettings::createBackupFile) {
    mpSettings->remove("createBackupFile");
  } else {
    mpSettings->setValue("createBackupFile", createBackupFile);
  }
  // save enable CRML support
  bool enableCRMLSupport = mpGeneralSettingsPage->getEnableCRMLSupportCheckBox()->isChecked();
  if (enableCRMLSupport == OptionsDefaults::GeneralSettings::enableCRMLSupport) {
    mpSettings->remove("enableCRMLSupport");
  } else {
    mpSettings->setValue("enableCRMLSupport", enableCRMLSupport);
  }
  // save library icon size
  int libraryIconSize = mpGeneralSettingsPage->getLibraryIconSizeSpinBox()->value();
  if (libraryIconSize == OptionsDefaults::GeneralSettings::libraryIconSize) {
    mpSettings->remove("libraryIconSize");
  } else {
    mpSettings->setValue("libraryIconSize", libraryIconSize);
  }
  // save the max. text length to show on a library icon
  int libraryIconMaximumTextLength = mpGeneralSettingsPage->getLibraryIconTextLengthSpinBox()->value();
  if (libraryIconMaximumTextLength == OptionsDefaults::GeneralSettings::libraryIconMaximumTextLength) {
    mpSettings->remove("libraryIconMaxTextLength");
  } else {
    mpSettings->setValue("libraryIconMaxTextLength", libraryIconMaximumTextLength);
  }
  // save show protected classes
  bool showProtectedClasses = mpGeneralSettingsPage->getShowProtectedClasses();
  if (showProtectedClasses == OptionsDefaults::GeneralSettings::showProtectedClasses) {
    mpSettings->remove("showProtectedClasses");
  } else {
    mpSettings->setValue("showProtectedClasses", showProtectedClasses);
  }
  // save show hidden classes
  bool showHiddenClasses = mpGeneralSettingsPage->getShowHiddenClasses();
  if (showHiddenClasses == OptionsDefaults::GeneralSettings::showHiddenClasses) {
    mpSettings->remove("showHiddenClasses");
  } else {
    mpSettings->setValue("showHiddenClasses", showHiddenClasses);
  }
  // show/hide the protected classes
  MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->showHideProtectedClasses();
  // save synchronize with ModelWidget
  bool synchronizeWithModelWidget = mpGeneralSettingsPage->getSynchronizeWithModelWidgetCheckBox()->isChecked();
  if (synchronizeWithModelWidget == OptionsDefaults::GeneralSettings::synchronizeWithModelWidget) {
    mpSettings->remove("synchronizeWithModelWidget");
  } else {
    mpSettings->setValue("synchronizeWithModelWidget", synchronizeWithModelWidget);
  }
  MainWindow::instance()->getLibraryWidget()->getTreeSearchFilters()->getScrollToActiveButton()->setVisible(!synchronizeWithModelWidget);
  // save auto save
  bool enableAutoSave = mpGeneralSettingsPage->getEnableAutoSaveGroupBox()->isChecked();
  if (enableAutoSave == OptionsDefaults::GeneralSettings::enableAutoSave) {
    mpSettings->remove("autoSave/enable");
  } else {
    mpSettings->setValue("autoSave/enable", enableAutoSave);
  }
  int autoSaveInterval = mpGeneralSettingsPage->getAutoSaveIntervalSpinBox()->value();
  if (autoSaveInterval == OptionsDefaults::GeneralSettings::autoSaveInterval) {
    mpSettings->remove("autoSave/interval");
  } else {
    mpSettings->setValue("autoSave/interval", autoSaveInterval);
  }
  MainWindow::instance()->getAutoSaveTimer()->setInterval(autoSaveInterval * 1000);
  MainWindow::instance()->toggleAutoSave();
  // save welcome page
  int welcomePageView = mpGeneralSettingsPage->getWelcomePageView();
  switch (welcomePageView) {
    case 2:
      MainWindow::instance()->getWelcomePageWidget()->getSplitter()->setOrientation(Qt::Vertical);
      break;
    case 1:
    default:
      MainWindow::instance()->getWelcomePageWidget()->getSplitter()->setOrientation(Qt::Horizontal);
      break;
  }
  if (welcomePageView == OptionsDefaults::GeneralSettings::welcomePageView) {
    mpSettings->remove("welcomePage/view");
  } else {
    mpSettings->setValue("welcomePage/view", welcomePageView);
  }
  bool showLatestNews = mpGeneralSettingsPage->getShowLatestNewsCheckBox()->isChecked();
  int recentFilesSize = mpSettings->value("welcomePage/recentFilesSize").toInt();
  int recentFilesAndLatestNewsSize = mpGeneralSettingsPage->getRecentFilesAndLatestNewsSizeSpinBox()->value();
  if ((MainWindow::instance()->getWelcomePageWidget()->getLatestNewsFrame()->isHidden() && showLatestNews) || recentFilesSize != recentFilesAndLatestNewsSize) {
    MainWindow::instance()->getWelcomePageWidget()->getLatestNewsFrame()->show();
    MainWindow::instance()->getWelcomePageWidget()->addLatestNewsListItems();
  } else if (!showLatestNews) {
    MainWindow::instance()->getWelcomePageWidget()->getLatestNewsFrame()->hide();
  }
  if (showLatestNews == OptionsDefaults::GeneralSettings::showLatestNews) {
    mpSettings->remove("welcomePage/showLatestNews");
  } else {
    mpSettings->setValue("welcomePage/showLatestNews", showLatestNews);
  }
  // recent files size
  if (recentFilesAndLatestNewsSize == OptionsDefaults::GeneralSettings::recentFilesAndLatestNewsSize) {
    mpSettings->remove("welcomePage/recentFilesSize");
  } else {
    mpSettings->setValue("welcomePage/recentFilesSize", recentFilesAndLatestNewsSize);
  }
  MainWindow::instance()->updateRecentFileActionsAndList();
}

/*!
 * \brief OptionsDialog::saveNFAPISettings
 */
void OptionsDialog::saveNFAPISettings()
{
  // save nfAPINoise
  bool displayNFAPIErrorsWarnings = mpGeneralSettingsPage->getDisplayNFAPIErrorsWarningsCheckBox()->isChecked();
  if (displayNFAPIErrorsWarnings == OptionsDefaults::GeneralSettings::displayNFAPIErrorsWarnings) {
    mpSettings->remove("simulation/nfAPINoise");
  } else {
    mpSettings->setValue("simulation/nfAPINoise", displayNFAPIErrorsWarnings);
  }
  if (displayNFAPIErrorsWarnings) {
    MainWindow::instance()->getOMCProxy()->setCommandLineOptions("-d=nfAPINoise");
  }
}

//! Saves the Libraries section settings to omedit.ini
void OptionsDialog::saveLibrariesSettings()
{
  // save ModelicaPath
  const QString modelicaPath = mpLibrariesPage->getModelicaPathTextBox()->text();
  if (modelicaPath.isEmpty() || modelicaPath.compare(Helper::ModelicaPath) == 0) {
    mpSettings->remove("modelicaPath-1");
    MainWindow::instance()->getOMCProxy()->setModelicaPath(Helper::ModelicaPath);
  } else if (MainWindow::instance()->getOMCProxy()->setModelicaPath(modelicaPath)) {
    mpSettings->setValue("modelicaPath-1", modelicaPath);
  }
  // save load latest Modelica
  bool loadLatestModelica = mpLibrariesPage->getLoadLatestModelicaCheckbox()->isChecked();
  if (loadLatestModelica == OptionsDefaults::Libraries::loadLatestModelica) {
    mpSettings->remove("loadLatestModelica");
  } else {
    mpSettings->setValue("loadLatestModelica", loadLatestModelica);
  }
  // read the settings and add system libraries
  mpSettings->beginGroup("libraries");
  foreach (QString lib, mpSettings->childKeys()) {
    mpSettings->remove(lib);
  }
  QTreeWidgetItemIterator systemLibrariesIterator(mpLibrariesPage->getSystemLibrariesTree());
  while (*systemLibrariesIterator) {
    QTreeWidgetItem *pItem = dynamic_cast<QTreeWidgetItem*>(*systemLibrariesIterator);
    mpSettings->setValue(pItem->text(0), pItem->text(1));
    ++systemLibrariesIterator;
  }
  mpSettings->endGroup();
  // read the settings and add user libraries
  mpSettings->beginGroup("userlibraries");
  foreach (QString lib, mpSettings->childKeys()) {
    mpSettings->remove(lib);
  }
  QTreeWidgetItemIterator userLibrariesIterator(mpLibrariesPage->getUserLibrariesTree());
  while (*userLibrariesIterator) {
    QTreeWidgetItem *pItem = dynamic_cast<QTreeWidgetItem*>(*userLibrariesIterator);
    mpSettings->setValue(QUrl::toPercentEncoding(pItem->text(0)), pItem->text(1));
    ++userLibrariesIterator;
  }
  mpSettings->endGroup();
}

/*!
 * \brief OptionsDialog::saveTextEditorSettings
 * Saves the TextEditor settings to omedit.ini
 */
void OptionsDialog::saveTextEditorSettings()
{
  int lineEnding = mpTextEditorPage->getLineEndingComboBox()->itemData(mpTextEditorPage->getLineEndingComboBox()->currentIndex()).toInt();
  if (lineEnding == OptionsDefaults::TextEditor::lineEnding) {
    mpSettings->remove("textEditor/lineEnding");
  } else {
    mpSettings->setValue("textEditor/lineEnding", lineEnding);
  }

  int bom = mpTextEditorPage->getBOMComboBox()->itemData(mpTextEditorPage->getBOMComboBox()->currentIndex()).toInt();
  if (bom == OptionsDefaults::TextEditor::bom) {
    mpSettings->remove("textEditor/bom");
  } else {
    mpSettings->setValue("textEditor/bom", bom);
  }

  int tabPolicy = mpTextEditorPage->getTabPolicyComboBox()->itemData(mpTextEditorPage->getTabPolicyComboBox()->currentIndex()).toInt();
  if (tabPolicy == OptionsDefaults::TextEditor::tabPolicy) {
    mpSettings->remove("textEditor/tabPolicy");
  } else {
    mpSettings->setValue("textEditor/tabPolicy", tabPolicy);
  }

  int tabSize = mpTextEditorPage->getTabSizeSpinBox()->value();
  if (tabSize == OptionsDefaults::TextEditor::tabSize) {
    mpSettings->remove("textEditor/tabSize");
  } else {
    mpSettings->setValue("textEditor/tabSize", tabSize);
  }

  int indentSize = mpTextEditorPage->getIndentSpinBox()->value();
  if (indentSize == OptionsDefaults::TextEditor::indentSize) {
    mpSettings->remove("textEditor/indentSize");
  } else {
    mpSettings->setValue("textEditor/indentSize", indentSize);
  }

  bool syntaxHighlighting = mpTextEditorPage->getSyntaxHighlightingGroupBox()->isChecked();
  if (syntaxHighlighting == OptionsDefaults::TextEditor::syntaxHighlighting) {
    mpSettings->remove("textEditor/enableSyntaxHighlighting");
  } else {
    mpSettings->setValue("textEditor/enableSyntaxHighlighting", syntaxHighlighting);
  }

  bool codeFolding = mpTextEditorPage->getCodeFoldingCheckBox()->isChecked();
  if (codeFolding == OptionsDefaults::TextEditor::codeFolding) {
    mpSettings->remove("textEditor/enableCodeFolding");
  } else {
    mpSettings->setValue("textEditor/enableCodeFolding", codeFolding);
  }

  bool matchParenthesesCommentsQuotes = mpTextEditorPage->getMatchParenthesesCommentsQuotesCheckBox()->isChecked();
  if (matchParenthesesCommentsQuotes == OptionsDefaults::TextEditor::matchParenthesesCommentsQuotes) {
    mpSettings->remove("textEditor/matchParenthesesCommentsQuotes");
  } else {
    mpSettings->setValue("textEditor/matchParenthesesCommentsQuotes", matchParenthesesCommentsQuotes);
  }

  bool lineWrapping = mpTextEditorPage->getLineWrappingCheckbox()->isChecked();
  if (lineWrapping == OptionsDefaults::TextEditor::lineWrapping) {
    mpSettings->remove("textEditor/enableLineWrapping");
  } else {
    mpSettings->setValue("textEditor/enableLineWrapping", lineWrapping);
  }

  QString fontFamily = mpTextEditorPage->getFontFamilyComboBox()->currentFont().family();
  if (fontFamily == Helper::monospacedFontInfo.family()) {
    mpSettings->remove("textEditor/fontFamily");
  } else {
    mpSettings->setValue("textEditor/fontFamily", fontFamily);
  }

  double fontSize = mpTextEditorPage->getFontSizeSpinBox()->value();
  if (qFuzzyCompare(fontSize, (double)Helper::monospacedFontInfo.pointSize())) {
    mpSettings->remove("textEditor/fontSize");
  } else {
    mpSettings->setValue("textEditor/fontSize", fontSize);
  }

  bool autocomplete = mpTextEditorPage->getAutoCompleteCheckBox()->isChecked();
  if (autocomplete == OptionsDefaults::TextEditor::autocomplete) {
    mpSettings->remove("textEditor/enableAutocomplete");
  } else {
    mpSettings->setValue("textEditor/enableAutocomplete", autocomplete);
  }
}

/*!
 * \brief OptionsDialog::saveModelicaEditorSettings
 * Saves the ModelicaEditor settings to omedit.ini
 */
void OptionsDialog::saveModelicaEditorSettings()
{
  bool preserveTextIndentation = mpModelicaEditorPage->getPreserveTextIndentationCheckBox()->isChecked();
  if (preserveTextIndentation == OptionsDefaults::ModelicaEditor::preserveTextIndentation) {
    mpSettings->remove("modelicaEditor/preserveTextIndentation");
  } else {
    mpSettings->setValue("modelicaEditor/preserveTextIndentation", preserveTextIndentation);
  }

  QColor textRuleColor = mpModelicaEditorPage->getColor("Text");
  if (textRuleColor == OptionsDefaults::ModelicaEditor::textRuleColor) {
    mpSettings->remove("modelicaEditor/textRuleColor");
  } else {
    mpSettings->setValue("modelicaEditor/textRuleColor", textRuleColor.rgba());
  }

  QColor numberRuleColor = mpModelicaEditorPage->getColor("Number");
  if (numberRuleColor == OptionsDefaults::ModelicaEditor::numberRuleColor) {
    mpSettings->remove("modelicaEditor/numberRuleColor");
  } else {
    mpSettings->setValue("modelicaEditor/numberRuleColor", numberRuleColor.rgba());
  }

  QColor keywordRuleColor = mpModelicaEditorPage->getColor("Keyword");
  if (keywordRuleColor == OptionsDefaults::ModelicaEditor::keywordRuleColor) {
    mpSettings->remove("modelicaEditor/keywordRuleColor");
  } else {
    mpSettings->setValue("modelicaEditor/keywordRuleColor", keywordRuleColor.rgba());
  }

  QColor typeRuleColor = mpModelicaEditorPage->getColor("Type");
  if (typeRuleColor == OptionsDefaults::ModelicaEditor::typeRuleColor) {
    mpSettings->remove("modelicaEditor/typeRuleColor");
  } else {
    mpSettings->setValue("modelicaEditor/typeRuleColor", typeRuleColor.rgba());
  }

  QColor functionRuleColor = mpModelicaEditorPage->getColor("Function");
  if (functionRuleColor == OptionsDefaults::ModelicaEditor::functionRuleColor) {
    mpSettings->remove("modelicaEditor/functionRuleColor");
  } else {
    mpSettings->setValue("modelicaEditor/functionRuleColor", functionRuleColor.rgba());
  }

  QColor quotesRuleColor = mpModelicaEditorPage->getColor("Quotes");
  if (quotesRuleColor == OptionsDefaults::ModelicaEditor::quotesRuleColor) {
    mpSettings->remove("modelicaEditor/quotesRuleColor");
  } else {
    mpSettings->setValue("modelicaEditor/quotesRuleColor", quotesRuleColor.rgba());
  }

  QColor commentRuleColor = mpModelicaEditorPage->getColor("Comment");
  if (commentRuleColor == OptionsDefaults::ModelicaEditor::commentRuleColor) {
    mpSettings->remove("modelicaEditor/commentRuleColor");
  } else {
    mpSettings->setValue("modelicaEditor/commentRuleColor", commentRuleColor.rgba());
  }
}

/*!
 * \brief OptionsDialog::saveMOSEditorSettings
 * Saves the MOSEditor settings to omedit.ini
 */
void OptionsDialog::saveMOSEditorSettings()
{
  QColor textRuleColor = mpMOSEditorPage->getColor("Text");
  if (textRuleColor == OptionsDefaults::ModelicaEditor::textRuleColor) {
    mpSettings->remove("mosEditor/textRuleColor");
  } else {
    mpSettings->setValue("mosEditor/textRuleColor", textRuleColor.rgba());
  }

  QColor numberRuleColor = mpMOSEditorPage->getColor("Number");
  if (numberRuleColor == OptionsDefaults::MOSEditor::numberRuleColor) {
    mpSettings->remove("mosEditor/numberRuleColor");
  } else {
    mpSettings->setValue("mosEditor/numberRuleColor", numberRuleColor.rgba());
  }

  QColor keywordRuleColor = mpMOSEditorPage->getColor("Keyword");
  if (keywordRuleColor == OptionsDefaults::MOSEditor::keywordRuleColor) {
    mpSettings->remove("mosEditor/keywordRuleColor");
  } else {
    mpSettings->setValue("mosEditor/keywordRuleColor", keywordRuleColor.rgba());
  }

  QColor typeRuleColor = mpMOSEditorPage->getColor("Type");
  if (typeRuleColor == OptionsDefaults::MOSEditor::typeRuleColor) {
    mpSettings->remove("mosEditor/typeRuleColor");
  } else {
    mpSettings->setValue("mosEditor/typeRuleColor", typeRuleColor.rgba());
  }

  QColor quotesRuleColor = mpMOSEditorPage->getColor("Quotes");
  if (quotesRuleColor == OptionsDefaults::MOSEditor::quotesRuleColor) {
    mpSettings->remove("mosEditor/quotesRuleColor");
  } else {
    mpSettings->setValue("mosEditor/quotesRuleColor", quotesRuleColor.rgba());
  }

  QColor commentRuleColor = mpMOSEditorPage->getColor("Comment");
  if (commentRuleColor == OptionsDefaults::MOSEditor::commentRuleColor) {
    mpSettings->remove("mosEditor/commentRuleColor");
  } else {
    mpSettings->setValue("mosEditor/commentRuleColor", commentRuleColor.rgba());
  }
}

/*!
 * \brief OptionsDialog::saveMetaModelicaEditorSettings
 * Saves the MetaModelicaEditor settings to omedit.ini
 */
void OptionsDialog::saveMetaModelicaEditorSettings()
{
  QColor textRuleColor = mpMetaModelicaEditorPage->getColor("Text");
  if (textRuleColor == OptionsDefaults::ModelicaEditor::textRuleColor) {
    mpSettings->remove("metaModelicaEditor/textRuleColor");
  } else {
    mpSettings->setValue("metaModelicaEditor/textRuleColor", textRuleColor.rgba());
  }

  QColor numberRuleColor = mpMetaModelicaEditorPage->getColor("Number");
  if (numberRuleColor == OptionsDefaults::MetaModelicaEditor::numberRuleColor) {
    mpSettings->remove("metaModelicaEditor/numberRuleColor");
  } else {
    mpSettings->setValue("metaModelicaEditor/numberRuleColor", numberRuleColor.rgba());
  }

  QColor keywordRuleColor = mpMetaModelicaEditorPage->getColor("Keyword");
  if (keywordRuleColor == OptionsDefaults::MetaModelicaEditor::keywordRuleColor) {
    mpSettings->remove("metaModelicaEditor/keywordRuleColor");
  } else {
    mpSettings->setValue("metaModelicaEditor/keywordRuleColor", keywordRuleColor.rgba());
  }

  QColor typeRuleColor = mpMetaModelicaEditorPage->getColor("Type");
  if (typeRuleColor == OptionsDefaults::MetaModelicaEditor::typeRuleColor) {
    mpSettings->remove("metaModelicaEditor/typeRuleColor");
  } else {
    mpSettings->setValue("metaModelicaEditor/typeRuleColor", typeRuleColor.rgba());
  }

  QColor quotesRuleColor = mpMetaModelicaEditorPage->getColor("Quotes");
  if (quotesRuleColor == OptionsDefaults::MetaModelicaEditor::quotesRuleColor) {
    mpSettings->remove("metaModelicaEditor/quotesRuleColor");
  } else {
    mpSettings->setValue("metaModelicaEditor/quotesRuleColor", quotesRuleColor.rgba());
  }

  QColor commentRuleColor = mpMetaModelicaEditorPage->getColor("Comment");
  if (commentRuleColor == OptionsDefaults::MetaModelicaEditor::commentRuleColor) {
    mpSettings->remove("metaModelicaEditor/commentRuleColor");
  } else {
    mpSettings->setValue("metaModelicaEditor/commentRuleColor", commentRuleColor.rgba());
  }
}

/*!
 * \brief OptionsDialog::saveOMSimulatorEditorSettings
 * Saves the OMSimulatorEditor settings to omedit.ini
 */
void OptionsDialog::saveOMSimulatorEditorSettings()
{
  QColor textRuleColor = mpOMSimulatorEditorPage->getColor("Text");
  if (textRuleColor == OptionsDefaults::ModelicaEditor::textRuleColor) {
    mpSettings->remove("omsimulatorEditor/textRuleColor");
  } else {
    mpSettings->setValue("omsimulatorEditor/textRuleColor", textRuleColor.rgba());
  }

  QColor tagRuleColor = mpOMSimulatorEditorPage->getColor("Tag");
  if (tagRuleColor == OptionsDefaults::OMSimulatorEditor::tagRuleColor) {
    mpSettings->remove("omsimulatorEditor/tagRuleColor");
  } else {
    mpSettings->setValue("omsimulatorEditor/tagRuleColor", tagRuleColor.rgba());
  }

  QColor elementRuleColor = mpOMSimulatorEditorPage->getColor("Element");
  if (elementRuleColor == OptionsDefaults::OMSimulatorEditor::elementRuleColor) {
    mpSettings->remove("omsimulatorEditor/elementsRuleColor");
  } else {
    mpSettings->setValue("omsimulatorEditor/elementsRuleColor", elementRuleColor.rgba());
  }

  QColor quotesRuleColor = mpOMSimulatorEditorPage->getColor("Quotes");
  if (quotesRuleColor == OptionsDefaults::OMSimulatorEditor::quotesRuleColor) {
    mpSettings->remove("omsimulatorEditor/quotesRuleColor");
  } else {
    mpSettings->setValue("omsimulatorEditor/quotesRuleColor", quotesRuleColor.rgba());
  }

  QColor commentRuleColor = mpOMSimulatorEditorPage->getColor("Comment");
  if (commentRuleColor == OptionsDefaults::OMSimulatorEditor::commentRuleColor) {
    mpSettings->remove("omsimulatorEditor/commentRuleColor");
  } else {
    mpSettings->setValue("omsimulatorEditor/commentRuleColor", commentRuleColor.rgba());
  }
}

/*!
 * \brief OptionsDialog::saveCRMLEditorSettings
 * Saves the CRMLEditor settings to omedit.ini
 */
void OptionsDialog::saveCRMLEditorSettings()
{
  QColor textRuleColor = mpCRMLEditorPage->getColor("Text");
  if (textRuleColor == OptionsDefaults::ModelicaEditor::textRuleColor) {
    mpSettings->remove("crmlEditor/textRuleColor");
  } else {
    mpSettings->setValue("crmlEditor/textRuleColor", textRuleColor.rgba());
  }

  QColor numberRuleColor = mpCRMLEditorPage->getColor("Number");
  if (numberRuleColor == OptionsDefaults::CRMLEditor::numberRuleColor) {
    mpSettings->remove("crmlEditor/numberRuleColor");
  } else {
    mpSettings->setValue("crmlEditor/numberRuleColor", numberRuleColor.rgba());
  }

  QColor keywordRuleColor = mpCRMLEditorPage->getColor("Keyword");
  if (keywordRuleColor == OptionsDefaults::CRMLEditor::keywordRuleColor) {
    mpSettings->remove("crmlEditor/keywordRuleColor");
  } else {
    mpSettings->setValue("crmlEditor/keywordRuleColor", keywordRuleColor.rgba());
  }

  QColor typeRuleColor = mpCRMLEditorPage->getColor("Type");
  if (typeRuleColor == OptionsDefaults::CRMLEditor::typeRuleColor) {
    mpSettings->remove("crmlEditor/typeRuleColor");
  } else {
    mpSettings->setValue("crmlEditor/typeRuleColor", typeRuleColor.rgba());
  }

  QColor quotesRuleColor = mpCRMLEditorPage->getColor("Quotes");
  if (quotesRuleColor == OptionsDefaults::CRMLEditor::quotesRuleColor) {
    mpSettings->remove("crmlEditor/quotesRuleColor");
  } else {
    mpSettings->setValue("crmlEditor/quotesRuleColor", quotesRuleColor.rgba());
  }

  QColor commentRuleColor = mpCRMLEditorPage->getColor("Comment");
  if (commentRuleColor == OptionsDefaults::CRMLEditor::commentRuleColor) {
    mpSettings->remove("crmlEditor/commentRuleColor");
  } else {
    mpSettings->setValue("crmlEditor/commentRuleColor", commentRuleColor.rgba());
  }
}

/*!
 * \brief OptionsDialog::saveCEditorSettings
 * Saves the CEditor settings to omedit.ini
 */
void OptionsDialog::saveCEditorSettings()
{
  QColor textRuleColor = mpMetaModelicaEditorPage->getColor("Text");
  if (textRuleColor == OptionsDefaults::ModelicaEditor::textRuleColor) {
    mpSettings->remove("cEditor/textRuleColor");
  } else {
    mpSettings->setValue("cEditor/textRuleColor", textRuleColor.rgba());
  }

  QColor numberRuleColor = mpCEditorPage->getColor("Number");
  if (numberRuleColor == OptionsDefaults::CEditor::numberRuleColor) {
    mpSettings->remove("cEditor/numberRuleColor");
  } else {
    mpSettings->setValue("cEditor/numberRuleColor", numberRuleColor.rgba());
  }

  QColor keywordRuleColor = mpCEditorPage->getColor("Keyword");
  if (keywordRuleColor == OptionsDefaults::CEditor::keywordRuleColor) {
    mpSettings->remove("cEditor/keywordRuleColor");
  } else {
    mpSettings->setValue("cEditor/keywordRuleColor", keywordRuleColor.rgba());
  }

  QColor typeRuleColor = mpCEditorPage->getColor("Type");
  if (typeRuleColor == OptionsDefaults::CEditor::typeRuleColor) {
    mpSettings->remove("cEditor/typeRuleColor");
  } else {
    mpSettings->setValue("cEditor/typeRuleColor", typeRuleColor.rgba());
  }

  QColor quotesRuleColor = mpCEditorPage->getColor("Quotes");
  if (quotesRuleColor == OptionsDefaults::CEditor::quotesRuleColor) {
    mpSettings->remove("cEditor/quotesRuleColor");
  } else {
    mpSettings->setValue("cEditor/quotesRuleColor", quotesRuleColor.rgba());
  }

  QColor commentRuleColor = mpCEditorPage->getColor("Comment");
  if (commentRuleColor == OptionsDefaults::CEditor::commentRuleColor) {
    mpSettings->remove("cEditor/commentRuleColor");
  } else {
    mpSettings->setValue("cEditor/commentRuleColor", commentRuleColor.rgba());
  }
}

/*!
 * \brief OptionsDialog::saveHTMLEditorSettings
 * Saves the HTMLEditor settings to omedit.ini
 */
void OptionsDialog::saveHTMLEditorSettings()
{
  QColor textRuleColor = mpHTMLEditorPage->getColor("Text");
  if (textRuleColor == OptionsDefaults::ModelicaEditor::textRuleColor) {
    mpSettings->remove("HTMLEditor/textRuleColor");
  } else {
    mpSettings->setValue("HTMLEditor/textRuleColor", textRuleColor.rgba());
  }

  QColor tagRuleColor = mpHTMLEditorPage->getColor("Tag");
  if (tagRuleColor == OptionsDefaults::HTMLEditor::tagRuleColor) {
    mpSettings->remove("HTMLEditor/tagRuleColor");
  } else {
    mpSettings->setValue("HTMLEditor/tagRuleColor", tagRuleColor.rgba());
  }

  QColor quotesRuleColor = mpHTMLEditorPage->getColor("Quotes");
  if (quotesRuleColor == OptionsDefaults::HTMLEditor::quotesRuleColor) {
    mpSettings->remove("HTMLEditor/quotesRuleColor");
  } else {
    mpSettings->setValue("HTMLEditor/quotesRuleColor", quotesRuleColor.rgba());
  }

  QColor commentRuleColor = mpHTMLEditorPage->getColor("Comment");
  if (commentRuleColor == OptionsDefaults::HTMLEditor::commentRuleColor) {
    mpSettings->remove("HTMLEditor/commentRuleColor");
  } else {
    mpSettings->setValue("HTMLEditor/commentRuleColor", commentRuleColor.rgba());
  }
}

//! Saves the GraphicsViews section settings to omedit.ini
void OptionsDialog::saveGraphicalViewsSettings()
{
  // save modeling view mode
  QString modelingViewMode = mpGraphicalViewsPage->getModelingViewMode();
  if (modelingViewMode.compare(Helper::tabbed) == 0) {
    mpSettings->remove("modeling/viewmode");
    MainWindow::instance()->getModelWidgetContainer()->setViewMode(QMdiArea::TabbedView);
  } else {
    mpSettings->setValue("modeling/viewmode", modelingViewMode);
    MainWindow::instance()->getModelWidgetContainer()->setViewMode(QMdiArea::SubWindowView);
    ModelWidget *pModelWidget = MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidget();
    if (pModelWidget) {
      pModelWidget->show();
      pModelWidget->setWindowState(Qt::WindowMaximized);
    }
  }
  // save default view
  QString defaultView = mpGraphicalViewsPage->getDefaultView();
  if (defaultView.compare(Helper::diagramViewForSettings) == 0) {
    mpSettings->remove("defaultView");
  } else {
    mpSettings->setValue("defaultView", defaultView);
  }
  // save move connectors together
  bool moveConnectorsTogether = mpGraphicalViewsPage->getMoveConnectorsTogetherCheckBox()->isChecked();
  if (moveConnectorsTogether == OptionsDefaults::GraphicalViewsPage::moveConnectorsTogether) {
    mpSettings->remove("modeling/moveConnectorsTogether");
  } else {
    mpSettings->setValue("modeling/moveConnectorsTogether", moveConnectorsTogether);
  }
}

//! Saves the Simulation section settings to omedit.ini
void OptionsDialog::saveSimulationSettings()
{
  // clear command line options before saving new ones
  MainWindow::instance()->getOMCProxy()->clearCommandLineOptions();
  bool changed = false;
  SimulationOptions simulationOptions;
  // save matching algorithm
  QString matchingAlgorithm = mpSimulationPage->getTranslationFlagsWidget()->getMatchingAlgorithmComboBox()->currentText();
  if (mMatchingAlgorithm.compare(matchingAlgorithm) != 0) {
    mMatchingAlgorithm = matchingAlgorithm;
    changed = true;
  }
  if (matchingAlgorithm.compare(simulationOptions.getMatchingAlgorithm()) == 0) {
    mpSettings->remove("simulation/matchingAlgorithm");
  } else {
    mpSettings->setValue("simulation/matchingAlgorithm", matchingAlgorithm);
  }
  // save index reduction
  QString indexReduction = mpSimulationPage->getTranslationFlagsWidget()->getIndexReductionMethodComboBox()->currentText();
  if (mIndexReductionMethod.compare(indexReduction) != 0) {
    mIndexReductionMethod = indexReduction;
    changed = true;
  }
  if (indexReduction.compare(simulationOptions.getIndexReductionMethod()) == 0) {
    mpSettings->remove("simulation/indexReductionMethod");
  } else {
    mpSettings->setValue("simulation/indexReductionMethod", indexReduction);
  }
  // save initialization
  bool initialization = mpSimulationPage->getTranslationFlagsWidget()->getInitializationCheckBox()->isChecked();
  if (mInitialization != initialization) {
    mInitialization = initialization;
    changed = true;
  }
  if (initialization == simulationOptions.getInitialization()) {
    mpSettings->remove("simulation/initialization");
  } else {
    mpSettings->setValue("simulation/initialization", initialization);
  }
  // save evaluate all parameters
  bool evaluateAllParameters = mpSimulationPage->getTranslationFlagsWidget()->getEvaluateAllParametersCheckBox()->isChecked();
  if (mEvaluateAllParameters != evaluateAllParameters) {
    mEvaluateAllParameters = evaluateAllParameters;
    changed = true;
  }
  if (evaluateAllParameters == simulationOptions.getEvaluateAllParameters()) {
    mpSettings->remove("simulation/evaluateAllParameters");
  } else {
    mpSettings->setValue("simulation/evaluateAllParameters", evaluateAllParameters);
  }
  // save NLS analytic jacobian
  bool NLSanalyticJacobian = mpSimulationPage->getTranslationFlagsWidget()->getNLSanalyticJacobianCheckBox()->isChecked();
  if (mNLSanalyticJacobian != NLSanalyticJacobian) {
    mNLSanalyticJacobian = NLSanalyticJacobian;
    changed = true;
  }
  if (NLSanalyticJacobian == simulationOptions.getNLSanalyticJacobian()) {
    mpSettings->remove("simulation/NLSanalyticJacobian");
  } else {
    mpSettings->setValue("simulation/NLSanalyticJacobian", NLSanalyticJacobian);
  }
  // save parmodauto
  bool parmodauto = mpSimulationPage->getTranslationFlagsWidget()->getParmodautoCheckBox()->isChecked();
  if (mParmodauto != parmodauto) {
    mParmodauto = parmodauto;
    changed = true;
  }
  if (parmodauto == simulationOptions.getParmodauto()) {
    mpSettings->remove("simulation/parmodauto");
  } else {
    mpSettings->setValue("simulation/parmodauto", parmodauto);
  }
  // save old instantiation
  bool newInst = !mpSimulationPage->getTranslationFlagsWidget()->getOldInstantiationCheckBox()->isChecked();
  if (mOldInstantiation != newInst) {
    mOldInstantiation = newInst;
    changed = true;
  }
  if (newInst == !simulationOptions.getOldInstantiation()) {
    mpSettings->remove("simulation/newInst");
  } else {
    mpSettings->setValue("simulation/newInst", newInst);
  }
  // save enable FMU Import
  bool enableFMUImport = mpSimulationPage->getTranslationFlagsWidget()->getEnableFMUImportCheckBox()->isChecked();
  if (mEnableFMUImport != enableFMUImport) {
    mEnableFMUImport = enableFMUImport;
    changed = true;
  }
  if (enableFMUImport == simulationOptions.getEnableFMUImport()) {
    mpSettings->remove("simulation/enableFMUImport");
  } else {
    mpSettings->setValue("simulation/enableFMUImport", enableFMUImport);
  }
  // save command line options
  QString additionalFlags = mpSimulationPage->getTranslationFlagsWidget()->getAdditionalTranslationFlagsTextBox()->text();
  if (mpSimulationPage->getTranslationFlagsWidget()->applyFlags()) {
    if (mAdditionalTranslationFlags.compare(additionalFlags) != 0) {
      mAdditionalTranslationFlags = additionalFlags;
      changed = true;
    }
    if (additionalFlags.compare(simulationOptions.getAdditionalTranslationFlags()) == 0) {
      mpSettings->remove("simulation/OMCFlags");
    } else {
      mpSettings->setValue("simulation/OMCFlags", additionalFlags);
    }
  } else {
    mpSimulationPage->getTranslationFlagsWidget()->getAdditionalTranslationFlagsTextBox()->setText(mAdditionalTranslationFlags);
  }
  // save global simulation settings.
  saveGlobalSimulationSettings();
  saveNFAPISettings();
  // save class before simulation.
  bool saveClassBeforeSimulation = mpSimulationPage->getSaveClassBeforeSimulationCheckBox()->isChecked();
  if (saveClassBeforeSimulation == OptionsDefaults::Simulation::saveClassBeforeSimulation) {
    mpSettings->remove("simulation/saveClassBeforeSimulation");
  } else {
    mpSettings->setValue("simulation/saveClassBeforeSimulation", saveClassBeforeSimulation);
  }

  bool switchToPlottingPerspective = mpSimulationPage->getSwitchToPlottingPerspectiveCheckBox()->isChecked();
  if (switchToPlottingPerspective == OptionsDefaults::Simulation::switchToPlottingPerspective) {
    mpSettings->remove("simulation/switchToPlottingPerspectiveAfterSimulation");
  } else {
    mpSettings->setValue("simulation/switchToPlottingPerspectiveAfterSimulation", switchToPlottingPerspective);
  }

  bool closeSimulationOutputWidgetsBeforeSimulation = mpSimulationPage->getCloseSimulationOutputWidgetsBeforeSimulationCheckBox()->isChecked();
  if (closeSimulationOutputWidgetsBeforeSimulation == OptionsDefaults::Simulation::closeSimulationOutputWidgetsBeforeSimulation) {
    mpSettings->remove("simulation/closeSimulationOutputWidgetsBeforeSimulation");
  } else {
    mpSettings->setValue("simulation/closeSimulationOutputWidgetsBeforeSimulation", closeSimulationOutputWidgetsBeforeSimulation);
  }

  bool deleteIntermediateCompilationFiles = mpSimulationPage->getDeleteIntermediateCompilationFilesCheckBox()->isChecked();
  if (deleteIntermediateCompilationFiles == OptionsDefaults::Simulation::deleteIntermediateCompilationFiles) {
    mpSettings->remove("simulation/deleteIntermediateCompilationFiles");
  } else {
    mpSettings->setValue("simulation/deleteIntermediateCompilationFiles", deleteIntermediateCompilationFiles);
  }

  bool deleteEntireSimulationDirectory = mpSimulationPage->getDeleteEntireSimulationDirectoryCheckBox()->isChecked();
  if (deleteEntireSimulationDirectory == OptionsDefaults::Simulation::deleteEntireSimulationDirectory) {
    mpSettings->remove("simulation/deleteEntireSimulationDirectory");
  } else {
    mpSettings->setValue("simulation/deleteEntireSimulationDirectory", deleteEntireSimulationDirectory);
  }

  QString outputMode = mpSimulationPage->getOutputMode();
  if (outputMode == Helper::structuredOutput) {
    mpSettings->remove("simulation/outputMode");
  } else {
    mpSettings->setValue("simulation/outputMode", outputMode);
  }

  int displayLimit = mpSimulationPage->getDisplayLimitSpinBox()->value();
  if (displayLimit == OptionsDefaults::Simulation::displayLimit) {
    mpSettings->remove("simulation/displayLimit");
  } else {
    mpSettings->setValue("simulation/displayLimit", displayLimit);
  }

  if (mDetectChange && changed) {
    DiscardLocalTranslationFlagsDialog *pDiscardLocalTranslationFlagsDialog = new DiscardLocalTranslationFlagsDialog(this);
    pDiscardLocalTranslationFlagsDialog->exec();
  }
}

/*!
 * \brief OptionsDialog::saveGlobalSimulationSettings
 * This function is just added so that SimulationDialog can set the global
 * simulatin settings in the SimulationDialog::translateModel()
 */
void OptionsDialog::saveGlobalSimulationSettings()
{
  SimulationOptions simulationOptions;
  // save target language
  QString targetLanguage = mpSimulationPage->getTargetLanguageComboBox()->currentText();
  if (targetLanguage.compare(simulationOptions.getTargetLanguage()) == 0) {
    mpSettings->remove("simulation/targetLanguage");
  } else {
    mpSettings->setValue("simulation/targetLanguage", targetLanguage);
  }
  MainWindow::instance()->getOMCProxy()->setCommandLineOptions(QString("--simCodeTarget=%1").arg(targetLanguage));
  // save target build
  QString target = mpSimulationPage->getTargetBuildComboBox()->itemData(mpSimulationPage->getTargetBuildComboBox()->currentIndex()).toString();
  if (target.compare(OptionsDefaults::Simulation::targetBuild) == 0) {
    mpSettings->remove("simulation/targetCompiler");
  } else {
    mpSettings->setValue("simulation/targetCompiler", target);
  }
  MainWindow::instance()->getOMCProxy()->setCommandLineOptions(QString("--target=%1").arg(target));
  // save compiler
  QString compiler = mpSimulationPage->getCompilerComboBox()->lineEdit()->text();
  if (compiler.isEmpty() || compiler.compare(OptionsDefaults::Simulation::cCompiler) == 0) {
    mpSettings->remove("simulation/compiler");
  } else {
    mpSettings->setValue("simulation/compiler", compiler);
  }
  if (compiler.isEmpty()) {
    compiler = mpSimulationPage->getCompilerComboBox()->lineEdit()->placeholderText();
  }
  MainWindow::instance()->getOMCProxy()->setCompiler(compiler);
  // save cxxcompiler
  QString cxxCompiler = mpSimulationPage->getCXXCompilerComboBox()->lineEdit()->text();
  if (cxxCompiler.isEmpty() || cxxCompiler.compare(OptionsDefaults::Simulation::cxxCompiler) == 0) {
    mpSettings->remove("simulation/cxxCompiler");
  } else {
    mpSettings->setValue("simulation/cxxCompiler", cxxCompiler);
  }
  if (cxxCompiler.isEmpty()) {
    cxxCompiler = mpSimulationPage->getCXXCompilerComboBox()->lineEdit()->placeholderText();
  }
  MainWindow::instance()->getOMCProxy()->setCXXCompiler(cxxCompiler);
#ifdef Q_OS_WIN
  // static linking
  bool useStaticLinking = mpSimulationPage->getUseStaticLinkingCheckBox()->isChecked();
  if (useStaticLinking == OptionsDefaults::Simulation::useStaticLinking) {
    mpSettings->remove("simulation/useStaticLinking");
  } else {
    mpSettings->setValue("simulation/useStaticLinking", useStaticLinking);
  }
#endif
  // post compilation command
  const QString postCompilationCommand = mpSimulationPage->getPostCompilationCommand();
  if (postCompilationCommand == OptionsDefaults::Simulation::postCompilationCommand) {
    mpSettings->remove("simulation/postCompilationCommand");
  } else {
    mpSettings->setValue("simulation/postCompilationCommand", postCompilationCommand);
  }
  // save ignore command line options
  bool ignoreCommandLineOptionsAnnotation = mpSimulationPage->getIgnoreCommandLineOptionsAnnotationCheckBox()->isChecked();
  if (ignoreCommandLineOptionsAnnotation == OptionsDefaults::Simulation::ignoreCommandLineOptionsAnnotation) {
    mpSettings->remove("simulation/ignoreCommandLineOptionsAnnotation");
  } else {
    mpSettings->setValue("simulation/ignoreCommandLineOptionsAnnotation", ignoreCommandLineOptionsAnnotation);
  }
  if (mpSimulationPage->getIgnoreCommandLineOptionsAnnotationCheckBox()->isChecked()) {
    MainWindow::instance()->getOMCProxy()->setCommandLineOptions("+ignoreCommandLineOptionsAnnotation=true");
  } else {
    MainWindow::instance()->getOMCProxy()->setCommandLineOptions("+ignoreCommandLineOptionsAnnotation=false");
  }
  // save ignore simulation flags
  bool ignoreSimulationFlagsAnnotation = mpSimulationPage->getIgnoreSimulationFlagsAnnotationCheckBox()->isChecked();
  if (ignoreSimulationFlagsAnnotation == OptionsDefaults::Simulation::ignoreSimulationFlagsAnnotation) {
    mpSettings->remove("simulation/ignoreSimulationFlagsAnnotation");
  } else {
    mpSettings->setValue("simulation/ignoreSimulationFlagsAnnotation", ignoreSimulationFlagsAnnotation);
  }
  if (mpSimulationPage->getIgnoreSimulationFlagsAnnotationCheckBox()->isChecked()) {
    MainWindow::instance()->getOMCProxy()->setCommandLineOptions("+ignoreSimulationFlagsAnnotation=true");
  } else {
    MainWindow::instance()->getOMCProxy()->setCommandLineOptions("+ignoreSimulationFlagsAnnotation=false");
  }
}

//! Saves the Messages section settings to omedit.ini
void OptionsDialog::saveMessagesSettings()
{
  // save output size
  int outputSize = mpMessagesPage->getOutputSizeSpinBox()->value();
  if (outputSize == OptionsDefaults::Messages::outputSize) {
    mpSettings->remove("messages/outputSize");
  } else {
    mpSettings->setValue("messages/outputSize", outputSize);
  }
  // save reset messages number
  bool resetMessagesNumberBeforeSimulation = mpMessagesPage->getResetMessagesNumberBeforeSimulationCheckBox()->isChecked();
  if (resetMessagesNumberBeforeSimulation == OptionsDefaults::Messages::resetMessagesNumberBeforeSimulation) {
    mpSettings->remove("messages/resetMessagesNumber");
  } else {
    mpSettings->setValue("messages/resetMessagesNumber", resetMessagesNumberBeforeSimulation);
  }
  // save clear message browser
  bool clearMessagesBrowserBeforeSimulation = mpMessagesPage->getClearMessagesBrowserBeforeSimulationCheckBox()->isChecked();
  if (clearMessagesBrowserBeforeSimulation == OptionsDefaults::Messages::clearMessagesBrowserBeforeSimulation) {
    mpSettings->remove("messages/clearMessagesBrowser");
  } else {
    mpSettings->setValue("messages/clearMessagesBrowser", clearMessagesBrowserBeforeSimulation);
  }
  // save enlarge message browser
  bool enlargeMessagesBrowserBeforeSimulation = mpMessagesPage->getEnlargeMessageBrowserCheckBox()->isChecked();
  if (enlargeMessagesBrowserBeforeSimulation == OptionsDefaults::Messages::enlargeMessageBrowserCheckBox) {
    mpSettings->remove("messages/enlargeMessagesBrowser");
  } else {
    mpSettings->setValue("messages/enlargeMessagesBrowser", enlargeMessagesBrowserBeforeSimulation);
  }
  // save font
  QTextBrowser textBrowser;
  QString fontFamily = mpMessagesPage->getFontFamilyComboBox()->currentFont().family();
  if (fontFamily.compare(textBrowser.font().family()) == 0) {
    mpSettings->remove("messages/fontFamily");
  } else {
    mpSettings->setValue("messages/fontFamily", fontFamily);
  }
  double fontSize = mpMessagesPage->getFontSizeSpinBox()->value();
  if (qFuzzyCompare(fontSize, (double)textBrowser.font().pointSize())) {
    mpSettings->remove("messages/fontSize");
  } else {
    mpSettings->setValue("messages/fontSize", fontSize);
  }
  // save notification color
  QColor notificationColor = mpMessagesPage->getNotificationColor();
  if (notificationColor == OptionsDefaults::Messages::notificationColor) {
    mpSettings->remove("messages/notificationColor");
  } else {
    mpSettings->setValue("messages/notificationColor", notificationColor.rgba());
  }
  // save warning color
  QColor warningColor = mpMessagesPage->getWarningColor();
  if (warningColor == OptionsDefaults::Messages::warningColor) {
    mpSettings->remove("messages/warningColor");
  } else {
    mpSettings->setValue("messages/warningColor", warningColor.rgba());
  }
  // save error color
  QColor errorColor = mpMessagesPage->getErrorColor();
  if (errorColor == OptionsDefaults::Messages::errorColor) {
    mpSettings->remove("messages/errorColor");
  } else {
    mpSettings->setValue("messages/errorColor", errorColor.rgba());
  }
  // apply the above settings to Messages
  MessagesWidget::instance()->applyMessagesSettings();
}

//! Saves the Notifications section settings to omedit.ini
void OptionsDialog::saveNotificationsSettings()
{
  bool quitApplication = mpNotificationsPage->getQuitApplicationCheckBox()->isChecked();
  if (quitApplication == OptionsDefaults::Notification::quitApplication) {
    mpSettings->remove("notifications/promptQuitApplication");
  } else {
    mpSettings->setValue("notifications/promptQuitApplication", quitApplication);
  }

  bool itemDroppedOnItself = mpNotificationsPage->getItemDroppedOnItselfCheckBox()->isChecked();
  if (itemDroppedOnItself == OptionsDefaults::Notification::itemDroppedOnItself) {
    mpSettings->remove("notifications/itemDroppedOnItself");
  } else {
    mpSettings->setValue("notifications/itemDroppedOnItself", itemDroppedOnItself);
  }

  bool replaceableIfPartial = mpNotificationsPage->getReplaceableIfPartialCheckBox()->isChecked();
  if (replaceableIfPartial == OptionsDefaults::Notification::replaceableIfPartial) {
    mpSettings->remove("notifications/replaceableIfPartial");
  } else {
    mpSettings->setValue("notifications/replaceableIfPartial", replaceableIfPartial);
  }

  bool innerModelNameChanged = mpNotificationsPage->getInnerModelNameChangedCheckBox()->isChecked();
  if (innerModelNameChanged == OptionsDefaults::Notification::innerModelNameChanged) {
    mpSettings->remove("notifications/innerModelNameChanged");
  } else {
    mpSettings->setValue("notifications/innerModelNameChanged", innerModelNameChanged);
  }

  bool saveModelForBitmapInsertion = mpNotificationsPage->getSaveModelForBitmapInsertionCheckBox()->isChecked();
  if (saveModelForBitmapInsertion == OptionsDefaults::Notification::saveModelForBitmapInsertion) {
    mpSettings->remove("notifications/saveModelForBitmapInsertion");
  } else {
    mpSettings->setValue("notifications/saveModelForBitmapInsertion", saveModelForBitmapInsertion);
  }

  bool alwaysAskForDraggedComponentName = mpNotificationsPage->getAlwaysAskForDraggedComponentName()->isChecked();
  if (alwaysAskForDraggedComponentName == OptionsDefaults::Notification::alwaysAskForDraggedComponentName) {
    mpSettings->remove("notifications/alwaysAskForDraggedComponentName");
  } else {
    mpSettings->setValue("notifications/alwaysAskForDraggedComponentName", alwaysAskForDraggedComponentName);
  }

  bool alwaysAskForTextEditorError = mpNotificationsPage->getAlwaysAskForTextEditorErrorCheckBox()->isChecked();
  if (alwaysAskForTextEditorError == OptionsDefaults::Notification::alwaysAskForTextEditorError) {
    mpSettings->remove("notifications/alwaysAskForTextEditorError");
  } else {
    mpSettings->setValue("notifications/alwaysAskForTextEditorError", alwaysAskForTextEditorError);
  }
}

//! Saves the LineStyle section settings to omedit.ini
void OptionsDialog::saveLineStyleSettings()
{
  QColor color = mpLineStylePage->getLineColor();
  if (color == OptionsDefaults::LineStyle::color) {
    mpSettings->remove("linestyle/color");
  } else {
    mpSettings->setValue("linestyle/color", color.rgba());
  }

  QString pattern = mpLineStylePage->getLinePattern();
  if (pattern == OptionsDefaults::LineStyle::pattern) {
    mpSettings->remove("linestyle/pattern");
  } else {
    mpSettings->setValue("linestyle/pattern", pattern);
  }

  double thickness = mpLineStylePage->getLineThickness();
  if (thickness == OptionsDefaults::LineStyle::thickness) {
    mpSettings->remove("linestyle/thickness");
  } else {
    mpSettings->setValue("linestyle/thickness", thickness);
  }

  QString startArrow = mpLineStylePage->getLineStartArrow();
  if (startArrow == OptionsDefaults::LineStyle::startArrow) {
    mpSettings->remove("linestyle/startArrow");
  } else {
    mpSettings->setValue("linestyle/startArrow", startArrow);
  }

  QString endArrow = mpLineStylePage->getLineEndArrow();
  if (endArrow == OptionsDefaults::LineStyle::endArrow) {
    mpSettings->remove("linestyle/endArrow");
  } else {
    mpSettings->setValue("linestyle/endArrow", endArrow);
  }

  double arrowSize = mpLineStylePage->getLineArrowSize();
  if (arrowSize == OptionsDefaults::LineStyle::arrowSize) {
    mpSettings->remove("linestyle/arrowSize");
  } else {
    mpSettings->setValue("linestyle/arrowSize", arrowSize);
  }

  bool smooth = mpLineStylePage->getLineSmooth();
  if (smooth == OptionsDefaults::LineStyle::smooth) {
    mpSettings->remove("linestyle/smooth");
  } else {
    mpSettings->setValue("linestyle/smooth", smooth);
  }
}

//! Saves the FillStyle section settings to omedit.ini
void OptionsDialog::saveFillStyleSettings()
{
  QColor color = mpFillStylePage->getFillColor();
  if (color == OptionsDefaults::FillStyle::color) {
    mpSettings->remove("fillstyle/color");
  } else {
    mpSettings->setValue("fillstyle/color", color.rgba());
  }

  QString pattern = mpFillStylePage->getFillPattern();
  if (pattern == OptionsDefaults::FillStyle::pattern) {
    mpSettings->remove("fillstyle/pattern");
  } else {
    mpSettings->setValue("fillstyle/pattern", pattern);
  }
}

//! Saves the Plotting section settings to omedit.ini
void OptionsDialog::savePlottingSettings()
{
  // save the auto scale
  bool autoScale = mpPlottingPage->getAutoScaleCheckBox()->isChecked();
  if (autoScale == OptionsDefaults::Plotting::autoScale) {
    mpSettings->remove("plotting/autoScale");
  } else {
    mpSettings->setValue("plotting/autoScale", autoScale);
  }
  // save the prefix units
  bool prefixUnits = mpPlottingPage->getPrefixUnitsCheckbox()->isChecked();
  if (prefixUnits == OptionsDefaults::Plotting::prefixUnits) {
    mpSettings->remove("plotting/prefixUnits");
  } else {
    mpSettings->setValue("plotting/prefixUnits", prefixUnits);
  }
  // save plotting view mode
  QString plottingViewMode = mpPlottingPage->getPlottingViewMode();
  if (mpPlottingPage->getPlottingViewMode().compare(Helper::tabbed) == 0) {
    mpSettings->remove("plotting/viewmode");
    MainWindow::instance()->getPlotWindowContainer()->setViewMode(QMdiArea::TabbedView);
  } else {
    mpSettings->setValue("plotting/viewmode", plottingViewMode);
    MainWindow::instance()->getPlotWindowContainer()->setViewMode(QMdiArea::SubWindowView);
    OMPlot::PlotWindow *pPlotWindow = MainWindow::instance()->getPlotWindowContainer()->getCurrentWindow();
    if (pPlotWindow) {
      pPlotWindow->show();
      pPlotWindow->setWindowState(Qt::WindowMaximized);
    }
  }
  // save curve pattern
  int curvePattern = mpPlottingPage->getCurvePattern();
  if (curvePattern == OptionsDefaults::Plotting::curvePattern) {
    mpSettings->remove("curvestyle/pattern");
  } else {
    mpSettings->setValue("curvestyle/pattern", curvePattern);
  }
  // save curve thickness
  double curveThickness = mpPlottingPage->getCurveThickness();
  if (qFuzzyCompare(curveThickness, OptionsDefaults::Plotting::curveThickness)) {
    mpSettings->remove("curvestyle/thickness");
  } else {
    mpSettings->setValue("curvestyle/thickness", curveThickness);
  }
  // save variable filter interval
  int variableFilterInterval = mpPlottingPage->getFilterIntervalSpinBox()->value();
  if (variableFilterInterval == OptionsDefaults::Plotting::variableFilterInterval) {
    mpSettings->remove("variableFilter/interval");
  } else {
    mpSettings->setValue("variableFilter/interval", variableFilterInterval);
  }
  MainWindow::instance()->getVariablesWidget()->getTreeSearchFilters()->getFilterTimer()->setInterval(mpPlottingPage->getFilterIntervalSpinBox()->value() * 1000);
  // save plot font sizes
  double titleFontSize = mpPlottingPage->getTitleFontSizeSpinBox()->value();
  if (qFuzzyCompare(titleFontSize, OptionsDefaults::Plotting::titleFontSize)) {
    mpSettings->remove("plotting/titleFontSize");
  } else {
    mpSettings->setValue("plotting/titleFontSize", titleFontSize);
  }

  double verticalAxisTitleFontSize = mpPlottingPage->getVerticalAxisTitleFontSizeSpinBox()->value();
  if (qFuzzyCompare(verticalAxisTitleFontSize, OptionsDefaults::Plotting::verticalAxisTitleFontSize)) {
    mpSettings->remove("plotting/verticalAxisTitleFontSize");
  } else {
    mpSettings->setValue("plotting/verticalAxisTitleFontSize", verticalAxisTitleFontSize);
  }

  double verticalAxisNumbersFontSize = mpPlottingPage->getVerticalAxisNumbersFontSizeSpinBox()->value();
  if (qFuzzyCompare(verticalAxisNumbersFontSize, OptionsDefaults::Plotting::verticalAxisNumbersFontSize)) {
    mpSettings->remove("plotting/verticalAxisNumbersFontSize");
  } else {
    mpSettings->setValue("plotting/verticalAxisNumbersFontSize", verticalAxisNumbersFontSize);
  }

  double horizontalAxisTitleFontSize = mpPlottingPage->getHorizontalAxisTitleFontSizeSpinBox()->value();
  if (qFuzzyCompare(horizontalAxisTitleFontSize, OptionsDefaults::Plotting::horizontalAxisTitleFontSize)) {
    mpSettings->remove("plotting/horizontalAxisTitleFontSize");
  } else {
    mpSettings->setValue("plotting/horizontalAxisTitleFontSize", horizontalAxisTitleFontSize);
  }

  double horizontalAxisNumbersFontSize = mpPlottingPage->getHorizontalAxisNumbersFontSizeSpinBox()->value();
  if (qFuzzyCompare(horizontalAxisNumbersFontSize, OptionsDefaults::Plotting::horizontalAxisNumbersFontSize)) {
    mpSettings->remove("plotting/horizontalAxisNumbersFontSize");
  } else {
    mpSettings->setValue("plotting/horizontalAxisNumbersFontSize", horizontalAxisNumbersFontSize);
  }

  double footerFontSize = mpPlottingPage->getFooterFontSizeSpinBox()->value();
  if (qFuzzyCompare(footerFontSize, (double)QApplication::font().pointSize())) {
    mpSettings->remove("plotting/footerFontSize");
  } else {
    mpSettings->setValue("plotting/footerFontSize", footerFontSize);
  }

  double legendFontSize = mpPlottingPage->getLegendFontSizeSpinBox()->value();
  if (qFuzzyCompare(legendFontSize, (double)QApplication::font().pointSize())) {
    mpSettings->remove("plotting/legendFontSize");
  } else {
    mpSettings->setValue("plotting/legendFontSize", legendFontSize);
  }
}

//! Saves the Figaro section settings to omedit.ini
void OptionsDialog::saveFigaroSettings()
{
  QString databaseFile = mpFigaroPage->getFigaroDatabaseFileTextBox()->text();
  if (databaseFile.compare(OptionsDefaults::Figaro::databaseFile) == 0) {
    mpSettings->remove("figaro/databasefile");
  } else {
    mpSettings->setValue("figaro/databasefile", databaseFile);
  }

  QString options = mpFigaroPage->getFigaroOptionsTextBox()->text();
  if (options.compare(OptionsDefaults::Figaro::options) == 0) {
    mpSettings->remove("figaro/options");
  } else {
    mpSettings->setValue("figaro/options", options);
  }

  QString process = mpFigaroPage->getFigaroProcessTextBox()->text();
  if (process.compare(OptionsDefaults::Figaro::process) == 0) {
    mpSettings->remove("figaro/process");
  } else {
    mpSettings->setValue("figaro/process", process);
  }
}

/*!
 * \brief OptionsDialog::saveCRMLSettings
 * Saves the CRML section settings to omedit.ini
 */
void OptionsDialog::saveCRMLSettings()
{
  QString compilerJar = mpCRMLPage->getCompilerJarTextBox()->text();
  if (compilerJar.compare(OptionsDefaults::CRML::compilerJar) == 0) {
    mpSettings->remove("crml/compilerjar");
  } else {
    mpSettings->setValue("crml/compilerjar", compilerJar);
  }

  QString commandLineOptions = mpCRMLPage->getCompilerCommandLineOptionsTextBox()->text();
  if (commandLineOptions.isEmpty()) {
    mpSettings->remove("crml/commandlineparameters");
  } else {
    mpSettings->setValue("crml/commandlineparameters", commandLineOptions);
  }

  QString process = mpCRMLPage->getCompilerProcessTextBox()->text();
  if (process.compare(OptionsDefaults::CRML::process) == 0) {
    mpSettings->remove("crml/process");
  } else {
    mpSettings->setValue("crml/process", process);
  }

  QStringList modelicaLibraries = mpCRMLPage->getModelicaLibraries()->items();
  if (modelicaLibraries.isEmpty()) {
    mpSettings->remove("crml/modelicaLibraries");
  } else {
    mpSettings->setValue("crml/modelicaLibraries", modelicaLibraries);
  }
}

/*!
  Saves the Debugger section settings to omedit.ini
  */
void OptionsDialog::saveDebuggerSettings()
{
  mpSettings->beginGroup("algorithmicDebugger");
  const QString GDBPath = mpDebuggerPage->getGDBPath();
  if (GDBPath.isEmpty() || GDBPath.compare(Utilities::getGDBPath()) == 0) {
    mpSettings->remove("GDBPath");
  } else {
    mpSettings->setValue("GDBPath", GDBPath);
  }

  int GDBCommandTimeout = mpDebuggerPage->getGDBCommandTimeoutSpinBox()->value();
  if (GDBCommandTimeout == OptionsDefaults::Debugger::GDBCommandTimeout) {
    mpSettings->remove("GDBCommandTimeout");
  } else {
    mpSettings->setValue("GDBCommandTimeout", GDBCommandTimeout);
  }

  int GDBOutputLimit = mpDebuggerPage->getGDBOutputLimitSpinBox()->value();
  if (GDBOutputLimit == OptionsDefaults::Debugger::GDBOutputLimit) {
    mpSettings->remove("GDBOutputLimit");
  } else {
    mpSettings->setValue("GDBOutputLimit", GDBOutputLimit);
  }

  bool displayCFrames = mpDebuggerPage->getDisplayCFramesCheckBox()->isChecked();
  if (displayCFrames == OptionsDefaults::Debugger::displayCFrames) {
    mpSettings->remove("displayCFrames");
  } else {
    mpSettings->setValue("displayCFrames", displayCFrames);
  }

  bool displayUnknownFrames = mpDebuggerPage->getDisplayUnknownFramesCheckBox()->isChecked();
  if (displayUnknownFrames == OptionsDefaults::Debugger::displayUnknownFrames) {
    mpSettings->remove("displayUnknownFrames");
  } else {
    mpSettings->setValue("displayUnknownFrames", displayUnknownFrames);
  }
  MainWindow::instance()->getStackFramesWidget()->getStackFramesTreeWidget()->updateStackFrames();

  bool clearOutputOnNewRun = mpDebuggerPage->getClearOutputOnNewRunCheckBox()->isChecked();
  if (clearOutputOnNewRun == OptionsDefaults::Debugger::clearOutputOnNewRun) {
    mpSettings->remove("clearOutputOnNewRun");
  } else {
    mpSettings->setValue("clearOutputOnNewRun", clearOutputOnNewRun);
  }

  bool clearLogOnNewRun = mpDebuggerPage->getClearLogOnNewRunCheckBox()->isChecked();
  if (clearLogOnNewRun == OptionsDefaults::Debugger::clearLogOnNewRun) {
    mpSettings->remove("clearLogOnNewRun");
  } else {
    mpSettings->setValue("clearLogOnNewRun", clearLogOnNewRun);
  }
  mpSettings->endGroup();

  mpSettings->beginGroup("transformationalDebugger");
  bool alwaysShowTransformationalDebugger = mpDebuggerPage->getAlwaysShowTransformationsCheckBox()->isChecked();
  if (alwaysShowTransformationalDebugger == OptionsDefaults::Debugger::alwaysShowTransformationalDebugger) {
    mpSettings->remove("alwaysShowTransformationalDebugger");
  } else {
    mpSettings->setValue("alwaysShowTransformationalDebugger", alwaysShowTransformationalDebugger);
  }

  bool generateOperations = mpDebuggerPage->getGenerateOperationsCheckBox()->isChecked();
  if (generateOperations == OptionsDefaults::Debugger::generateOperations) {
    mpSettings->remove("generateOperations");
  } else {
    mpSettings->setValue("generateOperations", generateOperations);
  }
  mpSettings->endGroup();
}

/*!
 * \brief OptionsDialog::saveFMISettings
 * Saves the FMI section settings to omedit.ini
 */
void OptionsDialog::saveFMISettings()
{
  QString version = mpFMIPage->getFMIExportVersion();
  if (version.compare(OptionsDefaults::FMI::version) == 0) {
    mpSettings->remove("FMIExport/Version");
  } else {
    mpSettings->setValue("FMIExport/Version", version);
  }

  QString type = mpFMIPage->getFMIExportType();
  if (type.compare(OptionsDefaults::FMI::type) == 0) {
    mpSettings->remove("FMIExport/Type");
  } else {
    mpSettings->setValue("FMIExport/Type", type);
  }

  QString FMUName = mpFMIPage->getFMUNameTextBox()->text();
  if (FMUName.compare(OptionsDefaults::FMI::FMUName) == 0) {
    mpSettings->remove("FMIExport/FMUName");
  } else {
    mpSettings->setValue("FMIExport/FMUName", FMUName);
  }

  QString moveFMU = mpFMIPage->getMoveFMUTextBox()->text();
  if (moveFMU.compare(OptionsDefaults::FMI::moveFMU) == 0) {
    mpSettings->remove("FMIExport/MoveFMU");
  } else {
    mpSettings->setValue("FMIExport/MoveFMU", moveFMU);
  }
  // save platforms
  QStringList platforms;
  int i = 0;
  while (QLayoutItem* pLayoutItem = mpFMIPage->getPlatformsGroupBox()->layout()->itemAt(i)) {
    if (dynamic_cast<QCheckBox*>(pLayoutItem->widget())) {
      QCheckBox *pPlatformCheckBox = dynamic_cast<QCheckBox*>(pLayoutItem->widget());
      if (pPlatformCheckBox->isChecked()) {
        platforms.append(pPlatformCheckBox->property(Helper::fmuPlatformNamePropertyId).toString());
      }
    } else if (dynamic_cast<QLineEdit*>(pLayoutItem->widget())) { // custom platforms
      QLineEdit *pPlatformTextBox = dynamic_cast<QLineEdit*>(pLayoutItem->widget());
      if (!pPlatformTextBox->text().isEmpty()) {
        platforms.append(pPlatformTextBox->text().split(","));
      }
    }
    i++;
  }
  mpSettings->setValue("FMIExport/Platforms", platforms);

  QString solver = mpFMIPage->getSolverForCoSimulationComboBox()->itemData(mpFMIPage->getSolverForCoSimulationComboBox()->currentIndex()).toString();
  if (solver.compare(OptionsDefaults::FMI::solver) == 0) {
    mpSettings->remove("FMIExport/solver");
  } else {
    mpSettings->setValue("FMIExport/solver", solver);
  }

  QString modelDescriptionFilter = mpFMIPage->getModelDescriptionFiltersComboBox()->currentText();
  if (modelDescriptionFilter.compare(OptionsDefaults::FMI::modelDescriptionFilter) == 0) {
    mpSettings->remove("FMIExport/ModelDescriptionFilter");
  } else {
    mpSettings->setValue("FMIExport/ModelDescriptionFilter", modelDescriptionFilter);
  }

  bool includeResources = mpFMIPage->getIncludeResourcesCheckBox()->isChecked();
  if (includeResources == OptionsDefaults::FMI::includeResources) {
    mpSettings->remove("FMIExport/IncludeResources");
  } else {
    mpSettings->setValue("FMIExport/IncludeResources", includeResources);
  }

  bool includeSourceCode = mpFMIPage->getIncludeSourceCodeCheckBox()->isChecked();
  if (includeSourceCode == OptionsDefaults::FMI::includeSourceCode) {
    mpSettings->remove("FMIExport/IncludeSourceCode");
  } else {
    mpSettings->setValue("FMIExport/IncludeSourceCode", includeSourceCode);
  }

  bool generateDebugSymbols = mpFMIPage->getGenerateDebugSymbolsCheckBox()->isChecked();
  if (generateDebugSymbols == OptionsDefaults::FMI::generateDebugSymbols) {
    mpSettings->remove("FMIExport/GenerateDebugSymbols");
  } else {
    mpSettings->setValue("FMIExport/GenerateDebugSymbols", generateDebugSymbols);
  }

  bool deleteFMUDirectoyAndModel = mpFMIPage->getDeleteFMUDirectoryAndModelCheckBox()->isChecked();
  if (deleteFMUDirectoyAndModel == OptionsDefaults::FMI::deleteFMUDirectoyAndModel) {
    mpSettings->remove("FMIExport/DeleteFMUDirectoyAndModel");
  } else {
    mpSettings->setValue("FMIExport/DeleteFMUDirectoyAndModel", deleteFMUDirectoyAndModel);
  }
}

/*!
 * \brief OptionsDialog::saveOMSimulatorSettings
 * Saves the OMSimulator settings in omedit.ini
 */
void OptionsDialog::saveOMSimulatorSettings()
{
  // set command line options
  QString commandLineOptions = mpOMSimulatorPage->getCommandLineOptionsTextBox()->text();
  if (commandLineOptions.compare(OptionsDefaults::OMSimulator::commandLineOptions) == 0) {
    mpSettings->remove("OMSimulator/commandLineOptions");
  } else {
    mpSettings->setValue("OMSimulator/commandLineOptions", commandLineOptions);
  }
  // first clear all the command line options and then set the new
  OMSProxy::instance()->setCommandLineOption("--clearAllOptions");
  OMSProxy::instance()->setCommandLineOption(mpOMSimulatorPage->getCommandLineOptionsTextBox()->text());
  // set working directory
  const QString workingDirectory = mpGeneralSettingsPage->getWorkingDirectory();
  if (workingDirectory.isEmpty()) {
    OMSProxy::instance()->setWorkingDirectory(OptionsDefaults::GeneralSettings::workingDirectory);
  } else {
    OMSProxy::instance()->setWorkingDirectory(workingDirectory);
  }
  // set logging level
  int loggingLevel = mpOMSimulatorPage->getLoggingLevelComboBox()->itemData(mpOMSimulatorPage->getLoggingLevelComboBox()->currentIndex()).toInt();
  if (loggingLevel == OptionsDefaults::OMSimulator::loggingLevel) {
    mpSettings->remove("OMSimulator/loggingLevel");
  } else {
    mpSettings->setValue("OMSimulator/loggingLevel", loggingLevel);
  }
  OMSProxy::instance()->setLoggingLevel(loggingLevel);
}

/*!
 * \brief OptionsDialog::saveSensitivityOptimizationSettings
 * Saves the Sensitivity and Optimization settings in omedit.ini
 */
void OptionsDialog::saveSensitivityOptimizationSettings()
{
  // set OMSens backend path
  QString backendPath = mpSensitivityOptimizationPage->getOMSensBackendPathTextBox()->text();
  if (backendPath.isEmpty()) {
    mpSettings->remove("OMSens/backend");
  } else {
    mpSettings->setValue("OMSens/backend", backendPath);
  }
  // set python
  QString python = mpSensitivityOptimizationPage->getPythonTextBox()->text();
  if (python.compare(OptionsDefaults::SensitivityOptimization::python) == 0) {
    mpSettings->remove("OMSens/python");
  } else {
    mpSettings->setValue("OMSens/python", python);
  }
}

/*!
 * \brief OptionsDialog::saveTraceabilitySettings
 * Saves the traceability settings in omedit.ini
 */
void OptionsDialog::saveTraceabilitySettings()
{
  // save traceability checkBox
  bool traceability = mpTraceabilityPage->getTraceabilityGroupBox()->isChecked();
  if (traceability == OptionsDefaults::Traceability::traceability) {
    mpSettings->remove("traceability/Traceability");
  } else {
    mpSettings->setValue("traceability/Traceability", traceability);
  }
  // save user name
  QString username = mpTraceabilityPage->getUserName()->text();
  if (username.compare(OptionsDefaults::Traceability::username) == 0) {
    mpSettings->remove("traceability/UserName");
  } else {
    mpSettings->setValue("traceability/UserName", username);
  }
  // save email
  QString email = mpTraceabilityPage->getEmail()->text();
  if (email.compare(OptionsDefaults::Traceability::email) == 0) {
    mpSettings->remove("traceability/Email");
  } else {
    mpSettings->setValue("traceability/Email", email);
  }
  // save Git repository
  QString gitRepository = mpTraceabilityPage->getGitRepository()->text();
  if (gitRepository.compare(OptionsDefaults::Traceability::gitRepository) == 0) {
    mpSettings->remove("traceability/GitRepository");
  } else {
    mpSettings->setValue("traceability/GitRepository", gitRepository);
  }
  // save the traceability daemon IP-Adress
  QString ipAdress = mpTraceabilityPage->getTraceabilityDaemonIpAdress()->text();
  if (ipAdress.compare(OptionsDefaults::Traceability::ipAdress) == 0) {
    mpSettings->remove("traceability/IPAdress");
  } else {
    mpSettings->setValue("traceability/IPAdress", ipAdress);
  }
  // save the traceability daemon port
  QString port = mpTraceabilityPage->getTraceabilityDaemonPort()->text();
  if (port.compare(OptionsDefaults::Traceability::port) == 0) {
    mpSettings->remove("traceability/Port");
  } else {
    mpSettings->setValue("traceability/Port", port);
  }
}
//! Sets up the Options Widget dialog
void OptionsDialog::setUpDialog()
{
  mpOptionsList = new QListWidget;
  mpOptionsList->setItemDelegate(new ItemDelegate(mpOptionsList));
  mpOptionsList->setViewMode(QListView::ListMode);
  mpOptionsList->setMovement(QListView::Static);
  mpOptionsList->setIconSize(QSize(24, 24));
  mpOptionsList->setCurrentRow(0, QItemSelectionModel::Select);
  connect(mpOptionsList, SIGNAL(currentItemChanged(QListWidgetItem*,QListWidgetItem*)), SLOT(changePage(QListWidgetItem*,QListWidgetItem*)));
  // add items to options list
  addListItems();
  // get maximum width for options list
  mpOptionsList->setSizePolicy(QSizePolicy::MinimumExpanding, QSizePolicy::Expanding);
  int width = mpOptionsList->sizeHintForColumn(0) + mpOptionsList->frameWidth() * 2 + 20;
  if (mpOptionsList->verticalScrollBar()->isVisible()) {
    width += mpOptionsList->verticalScrollBar()->width();
  }
  mpOptionsList->setMaximumWidth(width);
  // create pages
  createPages();
  mpChangesEffectLabel = new Label(tr("* The changes will take effect after restart."));
  mpChangesEffectLabel->setElideMode(Qt::ElideMiddle);
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(saveSettings()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  mpResetButton = new QPushButton(Helper::reset);
  mpResetButton->setAutoDefault(false);
  connect(mpResetButton, SIGNAL(clicked()), SLOT(reset()));
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpResetButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  QHBoxLayout *horizontalLayout = new QHBoxLayout;
  horizontalLayout->addWidget(mpOptionsList);
  horizontalLayout->addWidget(mpPagesWidget);
  // Create a layout
  QGridLayout *mainLayout = new QGridLayout;
  mainLayout->addLayout(horizontalLayout, 0, 0, 1, 2);
  mainLayout->addWidget(mpChangesEffectLabel, 1, 0);
  mainLayout->addWidget(mpButtonBox, 1, 1, Qt::AlignRight);
  setLayout(mainLayout);
}

//! Adds items to the list view of Options Widget
void OptionsDialog::addListItems()
{
  // General Settings Item
  QListWidgetItem *pGeneralSettingsItem = new QListWidgetItem(mpOptionsList);
  pGeneralSettingsItem->setIcon(QIcon(":/Resources/icons/general.svg"));
  pGeneralSettingsItem->setText(tr("General"));
  mpOptionsList->item(0)->setSelected(true);
  // Libraries Item
  QListWidgetItem *pLibrariesItem = new QListWidgetItem(mpOptionsList);
  pLibrariesItem->setIcon(QIcon(":/Resources/icons/libraries.svg"));
  pLibrariesItem->setText(Helper::libraries);
  // Text Editor Item
  QListWidgetItem *pTextEditorItem = new QListWidgetItem(mpOptionsList);
  pTextEditorItem->setIcon(QIcon(":/Resources/icons/modeltext.svg"));
  pTextEditorItem->setText(tr("Text Editor"));
  // Modelica Editor Item
  QListWidgetItem *pModelicaEditorItem = new QListWidgetItem(mpOptionsList);
  pModelicaEditorItem->setIcon(QIcon(":/Resources/icons/modeltext.svg"));
  pModelicaEditorItem->setText(tr("Modelica Editor"));
  // MOS Editor Item
  QListWidgetItem *pMOSEditorItem = new QListWidgetItem(mpOptionsList);
  pMOSEditorItem->setIcon(QIcon(":/Resources/icons/modeltext.svg"));
  pMOSEditorItem->setText(tr("Modelica Script Editor"));
  // MetaModelica Editor Item
  QListWidgetItem *pMetaModelicaEditorItem = new QListWidgetItem(mpOptionsList);
  pMetaModelicaEditorItem->setIcon(QIcon(":/Resources/icons/modeltext.svg"));
  pMetaModelicaEditorItem->setText(tr("MetaModelica Editor"));
  // SSP Editor Item
  QListWidgetItem *pOMSimulatorEditorItem = new QListWidgetItem(mpOptionsList);
  pOMSimulatorEditorItem->setIcon(QIcon(":/Resources/icons/modeltext.svg"));
  pOMSimulatorEditorItem->setText(tr("SSP Editor"));
  // CRML Editor Item
  QListWidgetItem *pCRMLEditorItem = new QListWidgetItem(mpOptionsList);
  pCRMLEditorItem->setIcon(QIcon(":/Resources/icons/modeltext.svg"));
  pCRMLEditorItem->setText(tr("CRML Editor"));
  // C/C++ Editor Item
  QListWidgetItem *pCEditorItem = new QListWidgetItem(mpOptionsList);
  pCEditorItem->setIcon(QIcon(":/Resources/icons/modeltext.svg"));
  pCEditorItem->setText(tr("C/C++ Editor"));
  // HTML Editor Item
  QListWidgetItem *pHTMLEditorItem = new QListWidgetItem(mpOptionsList);
  pHTMLEditorItem->setIcon(QIcon(":/Resources/icons/modeltext.svg"));
  pHTMLEditorItem->setText(tr("HTML Editor"));
  // Graphical Views Item
  QListWidgetItem *pGraphicalViewsItem = new QListWidgetItem(mpOptionsList);
  pGraphicalViewsItem->setIcon(QIcon(":/Resources/icons/modeling.png"));
  pGraphicalViewsItem->setText(tr("Graphical Views"));
  // Simulation Item
  QListWidgetItem *pSimulationItem = new QListWidgetItem(mpOptionsList);
  pSimulationItem->setIcon(QIcon(":/Resources/icons/simulate.svg"));
  pSimulationItem->setText(Helper::simulation);
  // Messages Item
  QListWidgetItem *pMessagesItem = new QListWidgetItem(mpOptionsList);
  pMessagesItem->setIcon(QIcon(":/Resources/icons/messages.svg"));
  pMessagesItem->setText(tr("Messages"));
  // Notifications Item
  QListWidgetItem *pNotificationsItem = new QListWidgetItem(mpOptionsList);
  pNotificationsItem->setIcon(QIcon(":/Resources/icons/notificationicon.svg"));
  pNotificationsItem->setText(tr("Notifications"));
  // Pen Style Item
  QListWidgetItem *pLineStyleItem = new QListWidgetItem(mpOptionsList);
  pLineStyleItem->setIcon(QIcon(":/Resources/icons/linestyle.svg"));
  pLineStyleItem->setText(Helper::lineStyle);
  // Brush Style Item
  QListWidgetItem *pFillStyleItem = new QListWidgetItem(mpOptionsList);
  pFillStyleItem->setIcon(QIcon(":/Resources/icons/fillstyle.svg"));
  pFillStyleItem->setText(Helper::fillStyle);
  // Plotting Item
  QListWidgetItem *pPlottingItem = new QListWidgetItem(mpOptionsList);
  pPlottingItem->setIcon(QIcon(":/Resources/icons/omplot.png"));
  pPlottingItem->setText(tr("Plotting"));
  // Figaro Item
  QListWidgetItem *pFigaroItem = new QListWidgetItem(mpOptionsList);
  pFigaroItem->setIcon(QIcon(":/Resources/icons/console.svg"));
  pFigaroItem->setText(Helper::figaro);
  // CRML Item
  QListWidgetItem *pCRMLItem = new QListWidgetItem(mpOptionsList);
  pCRMLItem->setIcon(QIcon(":/Resources/icons/crml-icon.svg"));
  pCRMLItem->setText(Helper::crml);
  // Debugger Item
  QListWidgetItem *pDebuggerItem = new QListWidgetItem(mpOptionsList);
  pDebuggerItem->setIcon(QIcon(":/Resources/icons/debugger.svg"));
  pDebuggerItem->setText(tr("Debugger"));
  // FMI Item
  QListWidgetItem *pFMIItem = new QListWidgetItem(mpOptionsList);
  pFMIItem->setIcon(QIcon(":/Resources/icons/fmi.svg"));
  pFMIItem->setText(tr("FMI"));
  // OMSimulator Item
  QListWidgetItem *pOMSimulatorItem = new QListWidgetItem(mpOptionsList);
  pOMSimulatorItem->setIcon(QIcon(":/Resources/icons/ssp-icon.svg"));
  pOMSimulatorItem->setText(tr("OMSimulator/SSP"));
  // Sensitivity Optimization Item
  QListWidgetItem *pSensitivityOptimizationItem = new QListWidgetItem(mpOptionsList);
  pSensitivityOptimizationItem->setText(Helper::sensitivityOptimization);
  // Traceability Item
  QListWidgetItem *pTraceabilityItem = new QListWidgetItem(mpOptionsList);
  pTraceabilityItem->setIcon(QIcon(":/Resources/icons/traceability.svg"));
  pTraceabilityItem->setText(tr("Traceability"));
}

//! Creates pages for the Options Widget. The pages are created as stacked widget and are mapped with mpOptionsList.
void OptionsDialog::createPages()
{
  mpPagesWidget = new QStackedWidget;
  addPage(mpGeneralSettingsPage);
  addPage(mpLibrariesPage);
  addPage(mpTextEditorPage);
  addPage(mpModelicaEditorPage);
  addPage(mpMOSEditorPage);
  addPage(mpMetaModelicaEditorPage);
  addPage(mpOMSimulatorEditorPage);
  addPage(mpCRMLEditorPage);
  addPage(mpCEditorPage);
  addPage(mpHTMLEditorPage);
  addPage(mpGraphicalViewsPage);
  addPage(mpSimulationPage);
  addPage(mpMessagesPage);
  addPage(mpNotificationsPage);
  addPage(mpLineStylePage);
  addPage(mpFillStylePage);
  addPage(mpPlottingPage);
  addPage(mpFigaroPage);
  addPage(mpCRMLPage);
  addPage(mpDebuggerPage);
  addPage(mpFMIPage);
  addPage(mpOMSimulatorPage);
  addPage(mpSensitivityOptimizationPage);
  addPage(mpTraceabilityPage);
}

void OptionsDialog::addPage(QWidget* pPage)
{
  QScrollArea *pScrollArea = new QScrollArea;
  pScrollArea->setWidgetResizable(true);
  pScrollArea->setWidget(pPage);
  mpPagesWidget->addWidget(pScrollArea);
}

/*!
  Saves the OptionsDialog geometry to omedit.ini file.
  */
void OptionsDialog::saveDialogGeometry()
{
  /* save the window geometry. */
  if (mpGeneralSettingsPage->getPreserveUserCustomizations()) {
    mpSettings->setValue("OptionsDialog/geometry", saveGeometry());
  }
}

/*!
 * \brief OptionsDialog::show
 * Reimplementation of QDialog::show method.
 */
void OptionsDialog::show()
{
  /* restore the window geometry. */
  if (mpGeneralSettingsPage->getPreserveUserCustomizations()) {
    restoreGeometry(mpSettings->value("OptionsDialog/geometry").toByteArray());
  }
  setVisible(true);
}

/*!
 * \brief OptionsDialog::getTabSettings
 * Returns a TabSettings
 * \return
 */
TabSettings OptionsDialog::getTabSettings()
{
  TabSettings tabSettings;
  tabSettings.setTabPolicy(mpTextEditorPage->getTabPolicyComboBox()->itemData(mpTextEditorPage->getTabPolicyComboBox()->currentIndex()).toInt());
  tabSettings.setTabSize(mpTextEditorPage->getTabSizeSpinBox()->value());
  tabSettings.setIndentSize(mpTextEditorPage->getIndentSpinBox()->value());
  return tabSettings;
}

/*!
 * \brief OptionsDialog::changePage
 * Change the page in Options Widget when the mpOptionsList currentItemChanged Signal is raised.
 * \param current
 * \param previous
 */
void OptionsDialog::changePage(QListWidgetItem *current, QListWidgetItem *previous)
{
  if (!current) {
    current = previous;
  }
  mpPagesWidget->setCurrentIndex(mpOptionsList->row(current));
}

//! Reimplementation of QWidget's reject function. If user reject the settings then set them back to original.
void OptionsDialog::reject()
{
  // read the old settings from the file
  readSettings();
  saveDialogGeometry();
  QDialog::reject();
}

//! Saves the settings to omedit.ini file.
void OptionsDialog::saveSettings()
{
  saveGeneralSettings();
  saveLibrariesSettings();
  saveTextEditorSettings();
  saveModelicaEditorSettings();
  emit modelicaEditorSettingsChanged();
  saveMOSEditorSettings();
  emit mosEditorSettingsChanged();
  saveMetaModelicaEditorSettings();
  emit metaModelicaEditorSettingsChanged();
  saveOMSimulatorEditorSettings();
  emit omsimulatorEditorSettingsChanged();
  saveCRMLEditorSettings();
  emit crmlEditorSettingsChanged();
  saveCEditorSettings();
  emit cEditorSettingsChanged();
  saveHTMLEditorSettings();
  emit HTMLEditorSettingsChanged();
  saveGraphicalViewsSettings();
  mDetectChange = true;
  saveSimulationSettings();
  mDetectChange = false;
  saveMessagesSettings();
  saveNotificationsSettings();
  saveLineStyleSettings();
  saveFillStyleSettings();
  savePlottingSettings();
  saveFigaroSettings();
  saveCRMLSettings();
  saveDebuggerSettings();
  saveFMISettings();
  saveOMSimulatorSettings();
  saveSensitivityOptimizationSettings();
  saveTraceabilitySettings();
  // emit the signal so that all text editors can set settings & line wrapping mode
  emit textSettingsChanged();
  mpSettings->sync();
  saveDialogGeometry();
  accept();
}

void OptionsDialog::reset()
{
  const QString title = tr("Reset to default");
  const QString text0 = tr("Are you sure that you want to reset OMEdit? This operation cannot be undone. ");
  const QString textWithLink = tr(("Please back up your settings "
                                   + QString("<a href='%1'>file</a>").arg(mpSettings->fileName())
                                   + " before proceeding, restart to have the changes take effect.").toUtf8().constData());
  const QString text = text0 + textWithLink;
  QMessageBox* pResetMessageBox = new QMessageBox();
  pResetMessageBox->setTextFormat(Qt::RichText);
  pResetMessageBox->setWindowTitle(title);
  pResetMessageBox->setText(text);
  const QMessageBox::StandardButton reply = pResetMessageBox->question(this, title, text, QMessageBox::Ok | QMessageBox::Cancel);
  if (reply == QMessageBox::Ok) {
    mpSettings->clear();
    mpSettings->sync();
    accept();
    destroy();
  }
  delete pResetMessageBox;
}

CodeColorsWidget::CodeColorsWidget(QWidget *pParent)
  : QWidget(pParent)
{
  // colors groupbox
  mpColorsGroupBox = new QGroupBox(Helper::Colors);
  // Item color label and pick color button
  mpItemColorLabel = new Label(tr("Item Color:"));
  mpItemColorPickButton = new QPushButton(Helper::pickColor);
  mpItemColorPickButton->setAutoDefault(false);
  connect(mpItemColorPickButton, SIGNAL(clicked()), SLOT(pickColor()));
  // Items list
  mpItemsLabel = new Label(tr("Items:"));
  mpItemsListWidget = new QListWidget;
  mpItemsListWidget->setItemDelegate(new ItemDelegate(mpItemsListWidget));
  mpItemsListWidget->setMaximumHeight(90);
  // text (black)
  new ListWidgetItem("Text", OptionsDefaults::ModelicaEditor::textRuleColor, mpItemsListWidget);
  // make first item in the list selected
  mpItemsListWidget->setCurrentRow(0, QItemSelectionModel::Select);
  // preview textbox
  mpPreviewLabel = new Label(tr("Preview:"));
  mpPreviewPlainTextEdit = new PreviewPlainTextEdit;
#if QT_VERSION >= QT_VERSION_CHECK(5, 10, 0)
  mpPreviewPlainTextEdit->setTabStopDistance((qreal)Helper::tabWidth);
#else // QT_VERSION_CHECK
  mpPreviewPlainTextEdit->setTabStopWidth(Helper::tabWidth);
#endif // QT_VERSION_CHECK
  // set colors groupbox layout
  QGridLayout *pColorsGroupBoxLayout = new QGridLayout;
  pColorsGroupBoxLayout->addWidget(mpItemsLabel, 1, 0);
  pColorsGroupBoxLayout->addWidget(mpItemColorLabel, 1, 1);
  pColorsGroupBoxLayout->addWidget(mpItemsListWidget, 2, 0);
  pColorsGroupBoxLayout->addWidget(mpItemColorPickButton, 2, 1, Qt::AlignTop);
  pColorsGroupBoxLayout->addWidget(mpPreviewLabel, 3, 0, 1, 2);
  pColorsGroupBoxLayout->addWidget(mpPreviewPlainTextEdit, 4, 0, 1, 2);
  mpColorsGroupBox->setLayout(pColorsGroupBoxLayout);
  // set the layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->addWidget(mpColorsGroupBox);
  setLayout(pMainLayout);
}

/*!
 * \brief CodeColorsWidget::pickColor
 * Picks a color for one of the Text Settings rules.
 * This method is called when mpColorPickButton clicked SIGNAL raised.
 */
void CodeColorsWidget::pickColor()
{
  QListWidgetItem *pItem = mpItemsListWidget->currentItem();
  ListWidgetItem *pListWidgetItem = dynamic_cast<ListWidgetItem*>(pItem);
  if (!pListWidgetItem) {
    return;
  }
  QColor color = QColorDialog::getColor(pListWidgetItem->getColor());
  if (!color.isValid()) {
    return;
  }
  pListWidgetItem->setColor(color);
  pListWidgetItem->setForeground(color);
  emit colorUpdated();
}

//! @class GeneralSettingsPage
//! @brief Creates an interface for genaral settings.

//! Constructor
//! @param pOptionsDialog is the pointer to OptionsDialog
GeneralSettingsPage::GeneralSettingsPage(OptionsDialog *pOptionsDialog)
  : QWidget(pOptionsDialog)
{
  mpOptionsDialog = pOptionsDialog;
  mpGeneralSettingsGroupBox = new QGroupBox(Helper::general);
  // Language Option
  mpLanguageLabel = new Label(tr("Language: *"));
  mpLanguageComboBox = new ComboBox;
  mpLanguageComboBox->addItem(tr("Auto Detected"), "");
  QMap<QString, QLocale> languagesMap = Utilities::supportedLanguages();
  QStringList keys(languagesMap.keys());
  /* Slow sorting, but works using regular Qt functions */
  keys.sort();
  foreach (const QString &key, keys) {
    QLocale locale = languagesMap[key];
    mpLanguageComboBox->addItem(key, locale);
  }
  // Working Directory
  mpWorkingDirectoryLabel = new Label(Helper::workingDirectory);
  OptionsDefaults::GeneralSettings::workingDirectory = MainWindow::instance()->getOMCProxy()->changeDirectory();
  mpWorkingDirectoryTextBox = new QLineEdit;
  mpWorkingDirectoryTextBox->setPlaceholderText(OptionsDefaults::GeneralSettings::workingDirectory);
  mpWorkingDirectoryBrowseButton = new QPushButton(Helper::browse);
  mpWorkingDirectoryBrowseButton->setAutoDefault(false);
  connect(mpWorkingDirectoryBrowseButton, SIGNAL(clicked()), SLOT(selectWorkingDirectory()));
  // toolbar icon size
  mpToolbarIconSizeLabel = new Label(tr("Toolbar Icon Size: *"));
  mpToolbarIconSizeSpinBox = new SpinBox;
  mpToolbarIconSizeSpinBox->setMinimum(16); // icons smaller than 16.......naaaaahhhh!!!!!
  mpToolbarIconSizeSpinBox->setValue(OptionsDefaults::GeneralSettings::toolBarIconSize);
  // Store Customizations Option
  mpPreserveUserCustomizations = new QCheckBox(tr("Preserve User's GUI Customizations"));
  mpPreserveUserCustomizations->setChecked(OptionsDefaults::GeneralSettings::preserveUserCustomizations);
  // terminal command
  mpTerminalCommandLabel = new Label(tr("Terminal Command:"));
  mpTerminalCommandTextBox = new QLineEdit;
  mpTerminalCommandTextBox->setText(OptionsDefaults::GeneralSettings::terminalCommand);
  mpTerminalCommandBrowseButton = new QPushButton(Helper::browse);
  mpTerminalCommandBrowseButton->setAutoDefault(false);
  connect(mpTerminalCommandBrowseButton, SIGNAL(clicked()), SLOT(selectTerminalCommand()));
  // terminal command args
  mpTerminalCommandArgumentsLabel = new Label(tr("Terminal Command Arguments:"));
  mpTerminalCommandArgumentsTextBox = new QLineEdit;
  // autohide variable browser checkbox
  mpHideVariablesBrowserCheckBox = new QCheckBox(tr("Autohide Variable Browser"));
  mpHideVariablesBrowserCheckBox->setToolTip(tr("Automatically hide the variable browser when switching away from plotting perspective."));
  mpHideVariablesBrowserCheckBox->setChecked(OptionsDefaults::GeneralSettings::hideVariablesBrowser);
  // activate access annotation
  mpActivateAccessAnnotationsLabel = new Label(tr("Activate Access Annotations *"));
  mpActivateAccessAnnotationsComboBox = new ComboBox;
  QStringList activateAccessAnnotationsDescriptions;
  activateAccessAnnotationsDescriptions << tr("Activates the access annotations even for the non-encrypted libraries.")
                      << tr("Activates the access annotations even if the .mol contains a non-encrypted library.")
                      << tr("Deactivates access annotations except for encrypted libraries.");
  mpActivateAccessAnnotationsComboBox->addItem(tr("Always"), GeneralSettingsPage::Always);
  mpActivateAccessAnnotationsComboBox->addItem(tr("When loading .mol file(s)"), GeneralSettingsPage::Loading);
  mpActivateAccessAnnotationsComboBox->addItem(tr("Never"), GeneralSettingsPage::Never);
  mpActivateAccessAnnotationsComboBox->setCurrentIndex(OptionsDefaults::GeneralSettings::activateAccessAnnotationsIndex);
  Utilities::setToolTip(mpActivateAccessAnnotationsComboBox, tr("Options for handling of access annotations"), activateAccessAnnotationsDescriptions);
  // create backup file
  mpCreateBackupFileCheckbox = new QCheckBox(tr("Create a model.bak-mo backup file when deleting a model."));
  mpCreateBackupFileCheckbox->setChecked(OptionsDefaults::GeneralSettings::createBackupFile);
  /* Display errors/warnings when new instantiation fails in evaluating graphical annotations */
  mpDisplayNFAPIErrorsWarningsCheckBox = new QCheckBox(tr("Display errors/warnings when instantiating the graphical annotations"));
  // Enable CRML support
  mpEnableCRMLSupportCheckBox = new QCheckBox(tr("Enable CRML Support *"));
  mpEnableCRMLSupportCheckBox->setChecked(OptionsDefaults::GeneralSettings::enableCRMLSupport);
  // set the layout of general settings group
  QGridLayout *pGeneralSettingsLayout = new QGridLayout;
  pGeneralSettingsLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pGeneralSettingsLayout->addWidget(mpLanguageLabel, 0, 0);
  pGeneralSettingsLayout->addWidget(mpLanguageComboBox, 0, 1, 1, 2);
  pGeneralSettingsLayout->addWidget(mpWorkingDirectoryLabel, 1, 0);
  pGeneralSettingsLayout->addWidget(mpWorkingDirectoryTextBox, 1, 1);
  pGeneralSettingsLayout->addWidget(mpWorkingDirectoryBrowseButton, 1, 2);
  pGeneralSettingsLayout->addWidget(mpToolbarIconSizeLabel, 2, 0);
  pGeneralSettingsLayout->addWidget(mpToolbarIconSizeSpinBox, 2, 1, 1, 2);
  pGeneralSettingsLayout->addWidget(mpPreserveUserCustomizations, 3, 0, 1, 3);
  pGeneralSettingsLayout->addWidget(mpTerminalCommandLabel, 4, 0);
  pGeneralSettingsLayout->addWidget(mpTerminalCommandTextBox, 4, 1);
  pGeneralSettingsLayout->addWidget(mpTerminalCommandBrowseButton, 4, 2);
  pGeneralSettingsLayout->addWidget(mpTerminalCommandArgumentsLabel, 5, 0);
  pGeneralSettingsLayout->addWidget(mpTerminalCommandArgumentsTextBox, 5, 1, 1, 2);
  pGeneralSettingsLayout->addWidget(mpHideVariablesBrowserCheckBox, 6, 0, 1, 3);
  pGeneralSettingsLayout->addWidget(mpActivateAccessAnnotationsLabel, 7, 0);
  pGeneralSettingsLayout->addWidget(mpActivateAccessAnnotationsComboBox, 7, 1, 1, 2);
  pGeneralSettingsLayout->addWidget(mpCreateBackupFileCheckbox, 8, 0, 1, 3);
  pGeneralSettingsLayout->addWidget(mpDisplayNFAPIErrorsWarningsCheckBox, 9, 0, 1, 3);
  pGeneralSettingsLayout->addWidget(mpEnableCRMLSupportCheckBox, 10, 0, 1, 3);
  mpGeneralSettingsGroupBox->setLayout(pGeneralSettingsLayout);
  // Library Browser group box
  mpLibraryBrowserGroupBox = new QGroupBox(tr("Library Browser"));
  // library icon size
  mpLibraryIconSizeLabel = new Label(tr("Library Icon Size: *"));
  mpLibraryIconSizeSpinBox = new SpinBox;
  mpLibraryIconSizeSpinBox->setMinimum(16);
  mpLibraryIconSizeSpinBox->setValue(OptionsDefaults::GeneralSettings::libraryIconSize);
  // library icon max. text length, value is set later
  mpLibraryIconTextLengthLabel = new Label(tr("Max. Library Icon Text Length to Show: *"));
  mpLibraryIconTextLengthSpinBox = new SpinBox;
  mpLibraryIconTextLengthSpinBox->setMinimum(0);
  mpLibraryIconTextLengthSpinBox->setValue(OptionsDefaults::GeneralSettings::libraryIconMaximumTextLength);
  // show protected classes
  mpShowProtectedClasses = new QCheckBox(tr("Show Protected Classes"));
  // show hidden classes
  mpShowHiddenClasses = new QCheckBox(tr("Show Hidden Classes if not encrypted"));
  // synchronize library browser with ModelWidget
  mpSynchronizeWithModelWidgetCheckBox = new QCheckBox(tr("Synchronize with Model Widget"));
  mpSynchronizeWithModelWidgetCheckBox->setChecked(OptionsDefaults::GeneralSettings::synchronizeWithModelWidget);
  // Library browser group box layout
  QGridLayout *pLibraryBrowserLayout = new QGridLayout;
  pLibraryBrowserLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pLibraryBrowserLayout->setColumnStretch(1, 1);
  pLibraryBrowserLayout->addWidget(mpLibraryIconSizeLabel, 0, 0);
  pLibraryBrowserLayout->addWidget(mpLibraryIconSizeSpinBox, 0, 1);
  pLibraryBrowserLayout->addWidget(mpLibraryIconTextLengthLabel, 1, 0);
  pLibraryBrowserLayout->addWidget(mpLibraryIconTextLengthSpinBox, 1, 1);
  pLibraryBrowserLayout->addWidget(mpShowProtectedClasses, 2, 0, 1, 2);
  pLibraryBrowserLayout->addWidget(mpShowHiddenClasses, 3, 0, 1, 2);
  pLibraryBrowserLayout->addWidget(mpSynchronizeWithModelWidgetCheckBox, 4, 0, 1, 2);
  mpLibraryBrowserGroupBox->setLayout(pLibraryBrowserLayout);
  // Auto Save
  mpEnableAutoSaveGroupBox = new QGroupBox(tr("Enable Auto Save"));
  mpEnableAutoSaveGroupBox->setToolTip("Auto save feature is experimental. If you encounter unexpected crashes then disable it.");
  mpEnableAutoSaveGroupBox->setCheckable(true);
  mpEnableAutoSaveGroupBox->setChecked(OptionsDefaults::GeneralSettings::enableAutoSave);
  mpAutoSaveIntervalLabel = new Label(tr("Auto Save Interval:"));
  mpAutoSaveIntervalSpinBox = new SpinBox;
  mpAutoSaveIntervalSpinBox->setSuffix(tr(" seconds"));
  mpAutoSaveIntervalSpinBox->setRange(60, std::numeric_limits<int>::max());
  mpAutoSaveIntervalSpinBox->setSingleStep(30);
  mpAutoSaveIntervalSpinBox->setValue(OptionsDefaults::GeneralSettings::autoSaveInterval);
  mpAutoSaveSecondsLabel = new Label;
  connect(mpAutoSaveIntervalSpinBox, SIGNAL(valueChanged(int)), SLOT(autoSaveIntervalValueChanged(int)));
  // calculate the auto save interval seconds.
  autoSaveIntervalValueChanged(mpAutoSaveIntervalSpinBox->value());
  // Auto Save layout
  QGridLayout *pAutoSaveGridLayout = new QGridLayout;
  pAutoSaveGridLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pAutoSaveGridLayout->addWidget(mpAutoSaveIntervalLabel, 0, 0);
  pAutoSaveGridLayout->addWidget(mpAutoSaveIntervalSpinBox, 0, 1);
  pAutoSaveGridLayout->addWidget(mpAutoSaveSecondsLabel, 0, 2);
  mpEnableAutoSaveGroupBox->setLayout(pAutoSaveGridLayout);
  // Welcome Page
  mpWelcomePageGroupBox = new QGroupBox(tr("Welcome Page"));
  mpHorizontalViewRadioButton = new QRadioButton(tr("Horizontal View"));
  mpHorizontalViewRadioButton->setChecked(true);
  mpVerticalViewRadioButton = new QRadioButton(tr("Vertical View"));
  QButtonGroup *pWelcomePageViewButtons = new QButtonGroup(this);
  pWelcomePageViewButtons->addButton(mpHorizontalViewRadioButton);
  pWelcomePageViewButtons->addButton(mpVerticalViewRadioButton);
  // plotting view radio buttons layout
  QHBoxLayout *pWelcomePageViewButtonsLayout = new QHBoxLayout;
  pWelcomePageViewButtonsLayout->addWidget(mpHorizontalViewRadioButton);
  pWelcomePageViewButtonsLayout->addWidget(mpVerticalViewRadioButton);
  // Show/hide latest news checkbox
  mpShowLatestNewsCheckBox = new QCheckBox(tr("Show Latest News && Events"));
  mpShowLatestNewsCheckBox->setChecked(OptionsDefaults::GeneralSettings::showLatestNews);
  // Recent files and latest news size
  Label *pRecentFilesAndLatestNewsSizeLabel = new Label(tr("Recent Files and Latest News & Events Size:"));
  mpRecentFilesAndLatestNewsSizeSpinBox = new SpinBox;
  mpRecentFilesAndLatestNewsSizeSpinBox->setValue(OptionsDefaults::GeneralSettings::recentFilesAndLatestNewsSize);
  // Welcome Page layout
  QGridLayout *pWelcomePageGridLayout = new QGridLayout;
  pWelcomePageGridLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pWelcomePageGridLayout->setColumnStretch(1, 1);
  pWelcomePageGridLayout->addLayout(pWelcomePageViewButtonsLayout, 0, 0, 1, 2, Qt::AlignLeft);
  pWelcomePageGridLayout->addWidget(mpShowLatestNewsCheckBox, 1, 0, 1, 2);
  pWelcomePageGridLayout->addWidget(pRecentFilesAndLatestNewsSizeLabel, 2, 0);
  pWelcomePageGridLayout->addWidget(mpRecentFilesAndLatestNewsSizeSpinBox, 2, 1);
  mpWelcomePageGroupBox->setLayout(pWelcomePageGridLayout);
  // set the layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addWidget(mpGeneralSettingsGroupBox);
  pMainLayout->addWidget(mpLibraryBrowserGroupBox);
  pMainLayout->addWidget(mpEnableAutoSaveGroupBox);
  pMainLayout->addWidget(mpWelcomePageGroupBox);
  setLayout(pMainLayout);
}

/*!
 * \brief GeneralSettingsPage::getWorkingDirectory
 * Returns the working directory.
 * \return
 */
QString GeneralSettingsPage::getWorkingDirectory()
{
  if (mpWorkingDirectoryTextBox->text().isEmpty()) {
    return mpWorkingDirectoryTextBox->placeholderText();
  } else {
    return mpWorkingDirectoryTextBox->text();
  }
}

/*!
 * \brief GeneralSettingsPage::getWelcomePageView
 * Returns the WelcomePageWidget orientation.
 * \return
 */
int GeneralSettingsPage::getWelcomePageView()
{
  if (mpHorizontalViewRadioButton->isChecked()) {
    return 1;
  } else if (mpVerticalViewRadioButton->isChecked()) {
    return 2;
  } else {
    return 0;
  }
}

/*!
 * \brief GeneralSettingsPage::setWelcomePageView
 * Sets the WelcomePageWidget orientation.
 * \param view
 */
void GeneralSettingsPage::setWelcomePageView(int view)
{
  switch (view) {
    case 2:
      mpVerticalViewRadioButton->setChecked(true);
      break;
    case 1:
    default:
      mpHorizontalViewRadioButton->setChecked(true);
      break;
  }
}

/*!
 * \brief GeneralSettingsPage::selectWorkingDirectory
 * Slot activated when mpWorkingDirectoryBrowseButton clicked signal is raised.
 * Allows user to choose a new working directory.
 */
void GeneralSettingsPage::selectWorkingDirectory()
{
  mpWorkingDirectoryTextBox->setText(StringHandler::getExistingDirectory(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::chooseDirectory), NULL));
}

/*!
 * \brief GeneralSettingsPage::selectTerminalCommand
 * Slot activated when mpTerminalCommandBrowseButton clicked signal is raised.
 * Allows user to select a new terminal command.
 */
void GeneralSettingsPage::selectTerminalCommand()
{
  mpTerminalCommandTextBox->setText(StringHandler::getOpenFileName(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::chooseFile), NULL, NULL, NULL));
}

/*!
 * \brief GeneralSettingsPage::autoSaveIntervalValueChanged
 * Slot activated when mpAutoSaveIntervalSpinBox valueChanged signal is raised.
 * \param value
 */
void GeneralSettingsPage::autoSaveIntervalValueChanged(int value)
{
  mpAutoSaveSecondsLabel->setText(tr("(%1 minute(s))").arg((double)value/60));
}

//! @class LibrariesPage
//! @brief Creates an interface for Libraries settings.

//! Constructor
//! @param pOptionsDialog is the pointer to OptionsDialog
LibrariesPage::LibrariesPage(OptionsDialog *pOptionsDialog)
  : QWidget(pOptionsDialog)
{
  mpOptionsDialog = pOptionsDialog;
  // MODELICAPATH
  QGroupBox *pModelicaPathGroupBox = new QGroupBox(Helper::general);
  mpModelicaPathLabel = new Label("MODELICAPATH");
  mpModelicaPathTextBox = new QLineEdit;
  mpModelicaPathTextBox->setPlaceholderText(Helper::ModelicaPath);
  mpModelicaPathTextBox->setToolTip(Helper::modelicaPathTip);
  mpModelicaPathBrowseButton = new QPushButton(Helper::browse);
  mpModelicaPathBrowseButton->setAutoDefault(false);
  connect(mpModelicaPathBrowseButton, SIGNAL(clicked()), SLOT(selectModelicaPath()));
  // general groupbox layout
  QGridLayout *pGeneralGroupBoxGridLayout = new QGridLayout;
  pGeneralGroupBoxGridLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pGeneralGroupBoxGridLayout->addWidget(mpModelicaPathLabel, 0, 0);
  pGeneralGroupBoxGridLayout->addWidget(mpModelicaPathTextBox, 0, 1);
  pGeneralGroupBoxGridLayout->addWidget(mpModelicaPathBrowseButton, 0, 2);
  pModelicaPathGroupBox->setLayout(pGeneralGroupBoxGridLayout);
  // system libraries groupbox
  mpSystemLibrariesGroupBox = new QGroupBox(tr("System libraries loaded automatically on startup *"));
  // system libraries note
  mpSystemLibrariesNoteLabel = new Label(tr("The system libraries are read from the MODELICAPATH and are always read-only."));
  mpSystemLibrariesNoteLabel->setElideMode(Qt::ElideMiddle);
  // load latest Modeica checkbox
  mpLoadLatestModelicaCheckbox = new QCheckBox(tr("Load latest Modelica version on startup"));
  mpLoadLatestModelicaCheckbox->setChecked(OptionsDefaults::Libraries::loadLatestModelica);
  // system libraries tree
  mpSystemLibrariesTree = new QTreeWidget;
  mpSystemLibrariesTree->setItemDelegate(new ItemDelegate(mpSystemLibrariesTree));
  mpSystemLibrariesTree->setIndentation(0);
  mpSystemLibrariesTree->setColumnCount(2);
  mpSystemLibrariesTree->setTextElideMode(Qt::ElideMiddle);
  QStringList systemLabels;
  systemLabels << tr("Name") << Helper::version;
  mpSystemLibrariesTree->setHeaderLabels(systemLabels);
  connect(mpSystemLibrariesTree, SIGNAL(itemDoubleClicked(QTreeWidgetItem*,int)), SLOT(openEditSystemLibrary()));
  // system libraries buttons
  mpAddSystemLibraryButton = new QPushButton(Helper::add);
  mpAddSystemLibraryButton->setAutoDefault(false);
  connect(mpAddSystemLibraryButton, SIGNAL(clicked()), SLOT(openAddSystemLibrary()));
  mpEditSystemLibraryButton = new QPushButton(Helper::edit);
  mpEditSystemLibraryButton->setAutoDefault(false);
  connect(mpEditSystemLibraryButton, SIGNAL(clicked()), SLOT(openEditSystemLibrary()));
  mpRemoveSystemLibraryButton = new QPushButton(Helper::remove);
  mpRemoveSystemLibraryButton->setAutoDefault(false);
  connect(mpRemoveSystemLibraryButton, SIGNAL(clicked()), SLOT(removeSystemLibrary()));
  // system libraries button box
  mpSystemLibrariesButtonBox = new QDialogButtonBox(Qt::Vertical);
  mpSystemLibrariesButtonBox->addButton(mpAddSystemLibraryButton, QDialogButtonBox::ActionRole);
  mpSystemLibrariesButtonBox->addButton(mpEditSystemLibraryButton, QDialogButtonBox::ActionRole);
  mpSystemLibrariesButtonBox->addButton(mpRemoveSystemLibraryButton, QDialogButtonBox::ActionRole);
  // system libraries groupbox layout
  QGridLayout *pSystemLibrariesLayout = new QGridLayout;
  pSystemLibrariesLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pSystemLibrariesLayout->addWidget(mpSystemLibrariesNoteLabel, 0, 0, 1, 2);
  pSystemLibrariesLayout->addWidget(mpLoadLatestModelicaCheckbox, 1, 0, 1, 2);
  pSystemLibrariesLayout->addWidget(mpSystemLibrariesTree, 2, 0);
  pSystemLibrariesLayout->addWidget(mpSystemLibrariesButtonBox, 2, 1);
  mpSystemLibrariesGroupBox->setLayout(pSystemLibrariesLayout);
  // user libraries groupbox
  mpUserLibrariesGroupBox = new QGroupBox(tr("User libraries loaded automatically on startup *"));
  // user libraries tree
  mpUserLibrariesTree = new QTreeWidget;
  mpUserLibrariesTree->setItemDelegate(new ItemDelegate(mpUserLibrariesTree));
  mpUserLibrariesTree->setIndentation(0);
  mpUserLibrariesTree->setColumnCount(2);
  mpUserLibrariesTree->setTextElideMode(Qt::ElideMiddle);
  QStringList userLabels;
  userLabels << tr("Path") << tr("Encoding");
  mpUserLibrariesTree->setHeaderLabels(userLabels);
  connect(mpUserLibrariesTree, SIGNAL(itemDoubleClicked(QTreeWidgetItem*,int)), SLOT(openEditUserLibrary()));
  // user libraries buttons
  mpAddUserLibraryButton = new QPushButton(Helper::add);
  mpAddUserLibraryButton->setAutoDefault(false);
  connect(mpAddUserLibraryButton, SIGNAL(clicked()), SLOT(openAddUserLibrary()));
  mpEditUserLibraryButton = new QPushButton(Helper::edit);
  mpEditUserLibraryButton->setAutoDefault(false);
  connect(mpEditUserLibraryButton, SIGNAL(clicked()), SLOT(openEditUserLibrary()));
  mpRemoveUserLibraryButton = new QPushButton(Helper::remove);
  mpRemoveUserLibraryButton->setAutoDefault(false);
  connect(mpRemoveUserLibraryButton, SIGNAL(clicked()), SLOT(removeUserLibrary()));
  // user libraries button box
  mpUserLibrariesButtonBox = new QDialogButtonBox(Qt::Vertical);
  mpUserLibrariesButtonBox->addButton(mpAddUserLibraryButton, QDialogButtonBox::ActionRole);
  mpUserLibrariesButtonBox->addButton(mpEditUserLibraryButton, QDialogButtonBox::ActionRole);
  mpUserLibrariesButtonBox->addButton(mpRemoveUserLibraryButton, QDialogButtonBox::ActionRole);
  // user libraries groupbox layout
  QGridLayout *pUserLibrariesLayout = new QGridLayout;
  pUserLibrariesLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pUserLibrariesLayout->addWidget(mpUserLibrariesTree, 0, 0);
  pUserLibrariesLayout->addWidget(mpUserLibrariesButtonBox, 0, 1);
  mpUserLibrariesGroupBox->setLayout(pUserLibrariesLayout);
  // main layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->addWidget(pModelicaPathGroupBox);
  pMainLayout->addWidget(mpSystemLibrariesGroupBox);
  pMainLayout->addWidget(mpUserLibrariesGroupBox);
  setLayout(pMainLayout);
}

/*!
 * \brief LibrariesPage::selectModelicaPath
 * Slot activated when mpModelicaPathBrowseButton clicked signal is raised.
 * Allows user to choose a new Modelica Path.
 */
void LibrariesPage::selectModelicaPath()
{
  mpModelicaPathTextBox->setText(StringHandler::getExistingDirectory(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::chooseDirectory), NULL));
}

//! Slot activated when mpAddSystemLibraryButton clicked signal is raised.
//! Creates an instance of AddLibraryWidget and show it.
void LibrariesPage::openAddSystemLibrary()
{
  AddSystemLibraryDialog *pAddSystemLibraryWidget = new AddSystemLibraryDialog(this);
  pAddSystemLibraryWidget->exec();
}

//! Slot activated when mpRemoveSystemLibraryButton clicked signal is raised.
//! Removes the selected tree item
void LibrariesPage::removeSystemLibrary()
{
  if (mpSystemLibrariesTree->selectedItems().size() > 0) {
    mpSystemLibrariesTree->removeItemWidget(mpSystemLibrariesTree->selectedItems().at(0), 0);
    delete mpSystemLibrariesTree->selectedItems().at(0);
  }
}

//! Slot activated when mpEditSystemLibraryButton clicked signal is raised.
//! Opens the AddLibraryWidget in edit mode and pass it the selected tree item.
void LibrariesPage::openEditSystemLibrary()
{
  if (mpSystemLibrariesTree->selectedItems().size() > 0) {
    AddSystemLibraryDialog *pAddSystemLibraryWidget = new AddSystemLibraryDialog(this, true);
    int currentIndex = pAddSystemLibraryWidget->getNameComboBox()->findText(mpSystemLibrariesTree->selectedItems().at(0)->text(0), Qt::MatchExactly);
    if (currentIndex > -1) {
      pAddSystemLibraryWidget->getNameComboBox()->setCurrentIndex(currentIndex);
      pAddSystemLibraryWidget->getVersionsComboBox()->lineEdit()->setText(mpSystemLibrariesTree->selectedItems().at(0)->text(1));
    }
    pAddSystemLibraryWidget->exec();
  }
}

//! Slot activated when mpAddUserLibraryButton clicked signal is raised.
//! Creates an instance of AddLibraryWidget and show it.
void LibrariesPage::openAddUserLibrary()
{
  AddUserLibraryDialog *pAddUserLibraryWidget = new AddUserLibraryDialog(this);
  pAddUserLibraryWidget->exec();
}

//! Slot activated when mpRemoveUserLibraryButton clicked signal is raised.
//! Removes the selected tree item
void LibrariesPage::removeUserLibrary()
{
  if (mpUserLibrariesTree->selectedItems().size() > 0) {
    mpUserLibrariesTree->removeItemWidget(mpUserLibrariesTree->selectedItems().at(0), 0);
    delete mpUserLibrariesTree->selectedItems().at(0);
  }
}

//! Slot activated when mpEditUserLibraryButton clicked signal is raised.
//! Opens the AddLibraryWidget in edit mode and pass it the selected tree item.
void LibrariesPage::openEditUserLibrary()
{
  if (mpUserLibrariesTree->selectedItems().size() > 0) {
    AddUserLibraryDialog *pAddUserLibraryWidget = new AddUserLibraryDialog(this);
    pAddUserLibraryWidget->setWindowTitle(QString("%1 - %2").arg(Helper::applicationName, tr("Edit User Library")));
    pAddUserLibraryWidget->mEditFlag = true;
    pAddUserLibraryWidget->mpPathTextBox->setText(mpUserLibrariesTree->selectedItems().at(0)->text(0));
    int currentIndex = pAddUserLibraryWidget->mpEncodingComboBox->findData(mpUserLibrariesTree->selectedItems().at(0)->text(1));
    if (currentIndex > -1) {
      pAddUserLibraryWidget->mpEncodingComboBox->setCurrentIndex(currentIndex);
    }
    pAddUserLibraryWidget->exec();
  }
}


/*!
 * \class AddSystemLibraryDialog
 * \brief Creates an interface for Adding new System Libraries.
 */
/*!
 * \brief AddSystemLibraryDialog::AddSystemLibraryDialog
 * \param pLibrariesPage is the pointer to LibrariesPage
 */
AddSystemLibraryDialog::AddSystemLibraryDialog(LibrariesPage *pLibrariesPage, bool editFlag)
  : QDialog(pLibrariesPage), mpLibrariesPage(pLibrariesPage), mEditFlag(editFlag)
{
  if (mEditFlag) {
    setWindowTitle(QString("%1 - %2").arg(Helper::applicationName, tr("Edit System Library")));
  } else {
    setWindowTitle(QString("%1 - %2").arg(Helper::applicationName, tr("Add System Library")));
  }
  setAttribute(Qt::WA_DeleteOnClose);
  setMinimumWidth(300);
  mpNameLabel = new Label(Helper::name);
  mpNameComboBox = new QComboBox;
  connect(mpNameComboBox, SIGNAL(currentIndexChanged(int)), SLOT(getLibraryVersions(int)));
  mpValueLabel = new Label(Helper::version + ":");
  mpVersionsComboBox = new QComboBox;
  mpVersionsComboBox->setEditable(true);
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(addSystemLibrary()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // install library button
  mpInstallLibraryButton = new QPushButton(Helper::installLibrary);
  mpInstallLibraryButton->setAutoDefault(false);
  connect(mpInstallLibraryButton, SIGNAL(clicked()), SLOT(openInstallLibraryDialog()));
  // add buttons
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // layout
  QGridLayout *mainLayout = new QGridLayout;
  mainLayout->setAlignment(Qt::AlignTop);
  mainLayout->addWidget(mpNameLabel, 0, 0);
  mainLayout->addWidget(mpNameComboBox, 0, 1);
  mainLayout->addWidget(mpValueLabel, 1, 0);
  mainLayout->addWidget(mpVersionsComboBox, 1, 1);
  mainLayout->addWidget(mpInstallLibraryButton, 2, 0, Qt::AlignLeft);
  mainLayout->addWidget(mpButtonBox, 2, 1, Qt::AlignRight);
  setLayout(mainLayout);

  getSystemLibraries();
}

/*!
 * \brief AddSystemLibraryDialog::nameExists
 * Returns tree if the name exists in the tree's first column.
 * \param pItem
 * \return
 */
bool AddSystemLibraryDialog::nameExists(QTreeWidgetItem *pItem)
{
  QTreeWidgetItemIterator it(mpLibrariesPage->getSystemLibrariesTree());
  while (*it) {
    QTreeWidgetItem *pChildItem = dynamic_cast<QTreeWidgetItem*>(*it);
    // edit case
    if (pItem) {
      if (pChildItem != pItem) {
        if (pChildItem->text(0).compare(mpNameComboBox->currentText()) == 0) {
          return true;
        }
      }
    } else { // add case
      if (pChildItem->text(0).compare(mpNameComboBox->currentText()) == 0) {
        return true;
      }
    }
    ++it;
  }
  return false;
}

/*!
 * \brief AddSystemLibraryDialog::getSystemLibraries
 * Gets the system libraries and add them to the combobox.
 */
void AddSystemLibraryDialog::getSystemLibraries()
{
  mpNameComboBox->clear();
  mpNameComboBox->addItems(MainWindow::instance()->getOMCProxy()->getAvailableLibraries());
  getLibraryVersions(mpNameComboBox->currentIndex());
}

/*!
 * \brief AddSystemLibraryDialog::getLibraryVersions
 * Gets the library versions and add them to the combobox.
 * \param index
 */
void AddSystemLibraryDialog::getLibraryVersions(int index)
{
  const QString library = mpNameComboBox->itemText(index);
  mpVersionsComboBox->clear();
  if (!library.isEmpty()) {
    mpVersionsComboBox->addItems(MainWindow::instance()->getOMCProxy()->getAvailableLibraryVersions(library));
  }
}

/*!
 * \brief AddSystemLibraryDialog::addSystemLibrary
 * Slot activated when mpOkButton clicked signal is raised.
 *  Add/Edit the system library in the tree.
 */
void AddSystemLibraryDialog::addSystemLibrary()
{
  // if name text box is empty show error and return
  if (mpNameComboBox->currentText().isEmpty()) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), GUIMessages::getMessage(GUIMessages::ENTER_NAME).arg(Helper::library), QMessageBox::Ok);
    return;
  }
  // if value text box is empty show error and return
  QString version;
  if (mpVersionsComboBox->lineEdit()->text().isEmpty()) {
    version = "default";
  } else {
    version = mpVersionsComboBox->lineEdit()->text();
  }
  // if user is adding a new library
  if (!mEditFlag) {
    if (nameExists()) {
      QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), GUIMessages::getMessage(GUIMessages::ITEM_ALREADY_EXISTS), QMessageBox::Ok);
      return;
    }
    QStringList values;
    values << mpNameComboBox->currentText() << version;
    mpLibrariesPage->getSystemLibrariesTree()->addTopLevelItem(new QTreeWidgetItem(values));
  } else if (mEditFlag) { // if user is editing old library
    QTreeWidgetItem *pItem = mpLibrariesPage->getSystemLibrariesTree()->selectedItems().at(0);
    if (nameExists(pItem)) {
      QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), GUIMessages::getMessage(GUIMessages::ITEM_ALREADY_EXISTS), QMessageBox::Ok);
      return;
    }
    pItem->setText(0, mpNameComboBox->currentText());
    pItem->setText(1, version);
  }
  accept();
}

/*!
 * \brief AddSystemLibraryDialog::openInstallLibraryDialog
 * Opens the InstallLibraryDialog and allows the user to install a library.
 * If the library is installed then reload the system libraries.
 */
void AddSystemLibraryDialog::openInstallLibraryDialog()
{
  if (MainWindow::instance()->openInstallLibraryDialog()) {
    getSystemLibraries();
  }
}

/*!
 * \class AddUserLibraryDialog
 * \brief Creates an interface for Adding new User Libraries.
 */
/*!
 * \brief AddUserLibraryDialog::AddUserLibraryDialog
 * \param pLibrariesPage is the pointer to LibrariesPage
 */
AddUserLibraryDialog::AddUserLibraryDialog(LibrariesPage *pLibrariesPage)
  : QDialog(pLibrariesPage), mEditFlag(false)
{
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName, tr("Add User Library")));
  setAttribute(Qt::WA_DeleteOnClose);
  mpLibrariesPage = pLibrariesPage;
  mpPathLabel = new Label(Helper::path);
  mpPathTextBox = new QLineEdit;
  mpPathBrowseButton = new QPushButton(Helper::browse);
  mpPathBrowseButton->setAutoDefault(false);
  connect(mpPathBrowseButton, SIGNAL(clicked()), SLOT(browseUserLibraryPath()));
  mpEncodingLabel = new Label(Helper::encoding);
  mpEncodingComboBox = new QComboBox;
  StringHandler::fillEncodingComboBox(mpEncodingComboBox);
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(addUserLibrary()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // add buttons
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  QGridLayout *mainLayout = new QGridLayout;
  mainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  mainLayout->addWidget(mpPathLabel, 0, 0);
  mainLayout->addWidget(mpPathTextBox, 0, 1);
  mainLayout->addWidget(mpPathBrowseButton, 0, 2);
  mainLayout->addWidget(mpEncodingLabel, 1, 0);
  mainLayout->addWidget(mpEncodingComboBox, 1, 1, 1, 2);
  mainLayout->addWidget(mpButtonBox, 2, 0, 1, 3, Qt::AlignRight);
  setLayout(mainLayout);
}

/*!
 * \brief AddUserLibraryDialog::pathExists
 * Returns tree if the name exists in the tree's first column.
 * \param pItem
 * \return
 */
bool AddUserLibraryDialog::pathExists(QTreeWidgetItem *pItem)
{
  QTreeWidgetItemIterator it(mpLibrariesPage->getUserLibrariesTree());
  while (*it) {
    QTreeWidgetItem *pChildItem = dynamic_cast<QTreeWidgetItem*>(*it);
    // edit case
    if (pItem) {
      if (pChildItem != pItem) {
        if (pChildItem->text(0).compare(mpPathTextBox->text()) == 0) {
          return true;
        }
      }
    } else { // add case
      if (pChildItem->text(0).compare(mpPathTextBox->text()) == 0) {
        return true;
      }
    }
    ++it;
  }
  return false;
}

/*!
 * \brief AddUserLibraryDialog::browseUserLibraryPath
 * Slot activated when mpPathBrowseButton clicked signal is raised.
 * Add/Edit the user library in the tree.
 */
void AddUserLibraryDialog::browseUserLibraryPath()
{
  mpPathTextBox->setText(StringHandler::getOpenFileName(this, QString("%1 - %2").arg(Helper::applicationName, Helper::chooseFile), NULL, Helper::omFileTypes, NULL));
}

/*!
 * \brief AddUserLibraryDialog::addUserLibrary
 * Slot activated when mpOkButton clicked signal is raised.
 * Add/Edit the user library in the tree.
 */
void AddUserLibraryDialog::addUserLibrary()
{
  // if path text box is empty show error and return
  if (mpPathTextBox->text().isEmpty()) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), tr("Please enter the file path."), QMessageBox::Ok);
    return;
  }
  // if user is adding a new library
  if (!mEditFlag) {
    if (pathExists()) {
      QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), GUIMessages::getMessage(GUIMessages::ITEM_ALREADY_EXISTS), QMessageBox::Ok);
      return;
    }
    QStringList values;
    values << mpPathTextBox->text() << mpEncodingComboBox->itemData(mpEncodingComboBox->currentIndex()).toString();
    mpLibrariesPage->getUserLibrariesTree()->addTopLevelItem(new QTreeWidgetItem(values));
  } else if (mEditFlag) { // if user is editing old library
    QTreeWidgetItem *pItem = mpLibrariesPage->getUserLibrariesTree()->selectedItems().at(0);
    if (pathExists(pItem))
    {
      QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), GUIMessages::getMessage(GUIMessages::ITEM_ALREADY_EXISTS), QMessageBox::Ok);
      return;
    }
    pItem->setText(0, mpPathTextBox->text());
    pItem->setText(1, mpEncodingComboBox->itemData(mpEncodingComboBox->currentIndex()).toString());
  }
  accept();
}

/*!
 * \class TextEditorPage
 * \brief Creates an interface for Text Editor settings.
 */
/*!
 * \brief TextEditorPage::TextEditorPage
 * \param pOptionsDialog is the pointer to OptionsDialog
 */
TextEditorPage::TextEditorPage(OptionsDialog *pOptionsDialog)
  : QWidget(pOptionsDialog)
{
  mpOptionsDialog = pOptionsDialog;
  // format groupbox
  mpFormatGroupBox = new QGroupBox(tr("Format"));
  // line ending
  mpLineEndingLabel = new Label(tr("Line Ending:"));
  mpLineEndingComboBox = new ComboBox;
  mpLineEndingComboBox->addItem(tr("Windows (CRLF)"), Utilities::CRLFLineEnding);
  mpLineEndingComboBox->addItem(tr("Unix (LF)"), Utilities::LFLineEnding);
  mpLineEndingComboBox->setCurrentIndex(OptionsDefaults::TextEditor::lineEnding);
  // Byte Order Mark BOM
  mpBOMLabel = new Label(tr("Byte Order Mark (BOM):"));
  mpBOMComboBox = new ComboBox;
  QStringList bomDescriptions;
  bomDescriptions << tr("Always add a BOM when saving a file.")
                  << tr("Save the file with a BOM if it already had one when it was loaded.")
                  << tr("Never write a BOM, possibly deleting a pre-existing one.");
  mpBOMComboBox->addItem(tr("Always Add"), Utilities::AlwaysAddBom);
  mpBOMComboBox->addItem(tr("Keep If Already Present"), Utilities::KeepBom);
  mpBOMComboBox->addItem(tr("Always Delete"), Utilities::AlwaysDeleteBom);
  mpBOMComboBox->setCurrentIndex(OptionsDefaults::TextEditor::bom);
  Utilities::setToolTip(mpBOMComboBox, tr("Note that BOMs are uncommon and treated incorrectly by some editors, so it usually makes little sense to add any"), bomDescriptions);
  // set format groupbox layout
  QGridLayout *pFormatGroupBoxLayout = new QGridLayout;
  pFormatGroupBoxLayout->addWidget(mpLineEndingLabel, 0, 0);
  pFormatGroupBoxLayout->setColumnStretch(1, 1);
  pFormatGroupBoxLayout->addWidget(mpLineEndingComboBox, 0, 1);
  pFormatGroupBoxLayout->addWidget(mpBOMLabel, 1, 0);
  pFormatGroupBoxLayout->addWidget(mpBOMComboBox, 1, 1);
  mpFormatGroupBox->setLayout(pFormatGroupBoxLayout);
  // tabs and indentation groupbox
  mpTabsAndIndentation = new QGroupBox(tr("Tabs and Indentation"));
  // tab policy
  mpTabPolicyLabel = new Label(tr("Tab Policy:"));
  mpTabPolicyComboBox = new ComboBox;
  mpTabPolicyComboBox->addItem(tr("Spaces Only"), 0);
  mpTabPolicyComboBox->addItem(tr("Tabs Only"), 1);
  // tab size
  mpTabSizeLabel = new Label(tr("Tab Size:"));
  mpTabSizeSpinBox = new SpinBox;
  mpTabSizeSpinBox->setRange(1, 20);
  mpTabSizeSpinBox->setValue(OptionsDefaults::TextEditor::tabSize);
  // indent size
  mpIndentSizeLabel = new Label(tr("Indent Size:"));
  mpIndentSpinBox = new SpinBox;
  mpIndentSpinBox->setRange(1, 20);
  mpIndentSpinBox->setValue(OptionsDefaults::TextEditor::indentSize);
  // set tabs & indentation groupbox layout
  QGridLayout *pTabsAndIndentationGroupBoxLayout = new QGridLayout;
  pTabsAndIndentationGroupBoxLayout->addWidget(mpTabPolicyLabel, 0, 0);
  pTabsAndIndentationGroupBoxLayout->setColumnStretch(1, 1);
  pTabsAndIndentationGroupBoxLayout->addWidget(mpTabPolicyComboBox, 0, 1);
  pTabsAndIndentationGroupBoxLayout->addWidget(mpTabSizeLabel, 1, 0);
  pTabsAndIndentationGroupBoxLayout->addWidget(mpTabSizeSpinBox, 1, 1);
  pTabsAndIndentationGroupBoxLayout->addWidget(mpIndentSizeLabel, 2, 0);
  pTabsAndIndentationGroupBoxLayout->addWidget(mpIndentSpinBox, 2, 1);
  mpTabsAndIndentation->setLayout(pTabsAndIndentationGroupBoxLayout);
  // syntax highlight and text wrapping groupbox
  mpSyntaxHighlightAndTextWrappingGroupBox = new QGroupBox(tr("Syntax Highlight and Text Wrapping"));
  // syntax highlighting groupbox
  mpSyntaxHighlightingGroupBox = new QGroupBox(tr("Enable Syntax Highlighting"));
  mpSyntaxHighlightingGroupBox->setCheckable(true);
  mpSyntaxHighlightingGroupBox->setChecked(OptionsDefaults::TextEditor::syntaxHighlighting);
  // code folding checkbox
  mpCodeFoldingCheckBox = new QCheckBox(tr("Enable Code Folding"));
  mpCodeFoldingCheckBox->setChecked(OptionsDefaults::TextEditor::codeFolding);
  // match parenthesis within comments and quotes
  mpMatchParenthesesCommentsQuotesCheckBox = new QCheckBox(tr("Match Parentheses within Comments and Quotes"));
  // set Syntax Highlighting groupbox layout
  QGridLayout *pSyntaxHighlightingGroupBoxLayout = new QGridLayout;
  pSyntaxHighlightingGroupBoxLayout->addWidget(mpCodeFoldingCheckBox, 0, 0);
  pSyntaxHighlightingGroupBoxLayout->addWidget(mpMatchParenthesesCommentsQuotesCheckBox, 1, 0);
  mpSyntaxHighlightingGroupBox->setLayout(pSyntaxHighlightingGroupBoxLayout);
  // line wrap checkbox
  mpLineWrappingCheckbox = new QCheckBox(tr("Enable Line Wrapping"));
  mpLineWrappingCheckbox->setChecked(OptionsDefaults::TextEditor::lineWrapping);
  // set Syntax Highlight & Text Wrapping groupbox layout
  QGridLayout *pSyntaxHighlightAndTextWrappingGroupBoxLayout = new QGridLayout;
  pSyntaxHighlightAndTextWrappingGroupBoxLayout->addWidget(mpSyntaxHighlightingGroupBox, 0, 0);
  pSyntaxHighlightAndTextWrappingGroupBoxLayout->addWidget(mpLineWrappingCheckbox, 1, 0);
  mpSyntaxHighlightAndTextWrappingGroupBox->setLayout(pSyntaxHighlightAndTextWrappingGroupBoxLayout);
  // AutoCompleter group box
  mpAutoCompleteGroupBox = new QGroupBox(tr("Autocomplete"));
  // autocompleter checkbox
  mpAutoCompleteCheckBox = new QCheckBox(tr("Enable Autocomplete"));
  mpAutoCompleteCheckBox->setChecked(OptionsDefaults::TextEditor::autocomplete);
  QGridLayout *pAutoCompleteGroupBoxLayout = new QGridLayout;
  pAutoCompleteGroupBoxLayout->addWidget(mpAutoCompleteCheckBox,0,0);
  mpAutoCompleteGroupBox->setLayout(pAutoCompleteGroupBoxLayout);
  // font groupbox
  mpFontGroupBox = new QGroupBox(tr("Font"));
  // font family combobox
  mpFontFamilyLabel = new Label(Helper::fontFamily);
  mpFontFamilyComboBox = new QFontComboBox;
  int currentIndex;
  currentIndex = mpFontFamilyComboBox->findText(Helper::monospacedFontInfo.family(), Qt::MatchExactly);
  mpFontFamilyComboBox->setCurrentIndex(currentIndex);
  // font size combobox
  mpFontSizeLabel = new Label(Helper::fontSize);
  mpFontSizeSpinBox = new DoubleSpinBox;
  mpFontSizeSpinBox->setRange(6, std::numeric_limits<double>::max());
  mpFontSizeSpinBox->setSingleStep(1);
  mpFontSizeSpinBox->setValue(Helper::monospacedFontInfo.pointSizeF());
  // set font groupbox layout
  QGridLayout *pFontGroupBoxLayout = new QGridLayout;
  pFontGroupBoxLayout->addWidget(mpFontFamilyLabel, 0, 0);
  pFontGroupBoxLayout->addWidget(mpFontSizeLabel, 0, 1);
  pFontGroupBoxLayout->addWidget(mpFontFamilyComboBox, 1, 0);
  pFontGroupBoxLayout->addWidget(mpFontSizeSpinBox, 1, 1);
  mpFontGroupBox->setLayout(pFontGroupBoxLayout);
  // set the layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addWidget(mpFormatGroupBox);
  pMainLayout->addWidget(mpTabsAndIndentation);
  pMainLayout->addWidget(mpSyntaxHighlightAndTextWrappingGroupBox);
  pMainLayout->addWidget(mpAutoCompleteGroupBox);
  pMainLayout->addWidget(mpFontGroupBox);
  setLayout(pMainLayout);
}

/*!
 * \class ModelicaEditorPage
 * \brief Creates an interface for Modelica Text settings.
 */
/*!
 * \brief ModelicaEditorPage::ModelicaEditorPage
 * \param pOptionsDialog is the pointer to OptionsDialog
 */
ModelicaEditorPage::ModelicaEditorPage(OptionsDialog *pOptionsDialog)
  : QWidget(pOptionsDialog)
{
  mpOptionsDialog = pOptionsDialog;
  // preserve text indentation
  mpPreserveTextIndentationCheckBox = new QCheckBox(tr("Preserve Text Indentation"));
  mpPreserveTextIndentationCheckBox->setChecked(OptionsDefaults::ModelicaEditor::preserveTextIndentation);
  // code colors widget
  mpCodeColorsWidget = new CodeColorsWidget(this);
  connect(mpCodeColorsWidget, SIGNAL(colorUpdated()), SIGNAL(updatePreview()));
  // Add items to list
  // number (purple)
  new ListWidgetItem("Number", OptionsDefaults::ModelicaEditor::numberRuleColor, mpCodeColorsWidget->getItemsListWidget());
  // keyword (dark red)
  new ListWidgetItem("Keyword", OptionsDefaults::ModelicaEditor::keywordRuleColor, mpCodeColorsWidget->getItemsListWidget());
  // type (red)
  new ListWidgetItem("Type", OptionsDefaults::ModelicaEditor::typeRuleColor, mpCodeColorsWidget->getItemsListWidget());
  // function (blue)
  new ListWidgetItem("Function", OptionsDefaults::ModelicaEditor::functionRuleColor, mpCodeColorsWidget->getItemsListWidget());
  // Quotes (dark green)
  new ListWidgetItem("Quotes", OptionsDefaults::ModelicaEditor::quotesRuleColor, mpCodeColorsWidget->getItemsListWidget());
  // comment (dark green)
  new ListWidgetItem("Comment", OptionsDefaults::ModelicaEditor::commentRuleColor, mpCodeColorsWidget->getItemsListWidget());
  // preview text
  QString previewText;
  previewText.append("class HelloWorld /* block\n"
                     "comment */\n"
                     "\tReal x(start = 1); // Line comment\n"
                     "\tparameter Real a = 1.573;\n"
                     "\tString str = \"a\\\"bc\n"
                     "123\";\n"
                     "equation\n"
                     "\tder(x) = - a * x;\n"
                     "end HelloWorld;\n");
  mpCodeColorsWidget->getPreviewPlainTextEdit()->setPlainText(previewText);
  // highlight preview textbox
  ModelicaHighlighter *pModelicaTextHighlighter = new ModelicaHighlighter(this, mpCodeColorsWidget->getPreviewPlainTextEdit());
  connect(this, SIGNAL(updatePreview()), pModelicaTextHighlighter, SLOT(settingsChanged()));
  connect(mpOptionsDialog->getTextEditorPage()->getSyntaxHighlightingGroupBox(), SIGNAL(toggled(bool)), pModelicaTextHighlighter, SLOT(settingsChanged()));
  connect(mpOptionsDialog->getTextEditorPage()->getMatchParenthesesCommentsQuotesCheckBox(), SIGNAL(toggled(bool)), pModelicaTextHighlighter, SLOT(settingsChanged()));
  connect(mpOptionsDialog->getTextEditorPage()->getLineWrappingCheckbox(), SIGNAL(toggled(bool)), this, SLOT(setLineWrapping(bool)));
  // set the layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->addWidget(mpPreserveTextIndentationCheckBox);
  pMainLayout->addWidget(mpCodeColorsWidget);
  setLayout(pMainLayout);
}

/*!
 * \brief ModelicaEditorPage::setColor
 * Sets the color of an item.
 * \param item
 * \param color
 */
void ModelicaEditorPage::setColor(QString item, QColor color)
{
  QList<QListWidgetItem*> items = mpCodeColorsWidget->getItemsListWidget()->findItems(item, Qt::MatchExactly);
  if (items.size() > 0) {
    ListWidgetItem *pListWidgetItem = dynamic_cast<ListWidgetItem*>(items.at(0));
    if (pListWidgetItem) {
      pListWidgetItem->setColor(color);
      pListWidgetItem->setForeground(color);
    }
  }
}

/*!
 * \brief ModelicaEditorPage::getColor
 * Returns the color of an item.
 * \param item
 * \return
 */
QColor ModelicaEditorPage::getColor(QString item)
{
  QList<QListWidgetItem*> items = mpCodeColorsWidget->getItemsListWidget()->findItems(item, Qt::MatchExactly);
  if (items.size() > 0) {
    ListWidgetItem *pListWidgetItem = dynamic_cast<ListWidgetItem*>(items.at(0));
    if (pListWidgetItem) {
      return pListWidgetItem->getColor();
    }
  }
  return QColor(0, 0, 0);
}

/*!
 * \brief ModelicaEditorPage::setLineWrapping
 * Slot activated when mpLineWrappingCheckbox toggled SIGNAL is raised.
 * Sets the mpPreviewPlainTextBox line wrapping mode.
 */
void ModelicaEditorPage::setLineWrapping(bool enabled)
{
  if (enabled) {
    mpCodeColorsWidget->getPreviewPlainTextEdit()->setLineWrapMode(QPlainTextEdit::WidgetWidth);
  } else {
    mpCodeColorsWidget->getPreviewPlainTextEdit()->setLineWrapMode(QPlainTextEdit::NoWrap);
  }
}

/*!
 * \class MetaModelicaEditorPage
 * \brief Creates an interface for MetaModelica Text settings.
 */
/*!
 * \brief MetaModelicaEditorPage::MetaModelicaEditorPage
 * \param pOptionsDialog is the pointer to OptionsDialog
 */
MetaModelicaEditorPage::MetaModelicaEditorPage(OptionsDialog *pOptionsDialog)
  : QWidget(pOptionsDialog)
{
  mpOptionsDialog = pOptionsDialog;
  // code colors widget
  mpCodeColorsWidget = new CodeColorsWidget(this);
  connect(mpCodeColorsWidget, SIGNAL(colorUpdated()), SIGNAL(updatePreview()));
  // Add items to list
  // number (purple)
  new ListWidgetItem("Number", OptionsDefaults::MetaModelicaEditor::numberRuleColor, mpCodeColorsWidget->getItemsListWidget());
  // keyword (dark red)
  new ListWidgetItem("Keyword", OptionsDefaults::MetaModelicaEditor::keywordRuleColor, mpCodeColorsWidget->getItemsListWidget());
  // type (red)
  new ListWidgetItem("Type", OptionsDefaults::MetaModelicaEditor::typeRuleColor, mpCodeColorsWidget->getItemsListWidget());
  // Quotes (dark green)
  new ListWidgetItem("Quotes", OptionsDefaults::MetaModelicaEditor::quotesRuleColor, mpCodeColorsWidget->getItemsListWidget());
  // comment (dark green)
  new ListWidgetItem("Comment", OptionsDefaults::MetaModelicaEditor::commentRuleColor, mpCodeColorsWidget->getItemsListWidget());
  // preview text
  QString previewText;
  previewText.append("function HelloWorld /* block\n"
                     "comment */\n"
                     "\tinput Integer request; // Line comment\n"
                     "\toutput String str;\n"
                     "algorithm\n"
                     "\tstr := match (request)\n"
                     "\t\tcase (1) then \"Hi\";\n"
                     "\t\tcase (2) then \"Hey\";\n"
                     "\t\tcase (3) then \"Hello\";\n"
                     "\tend match;\n"
                     "end HelloWorld;\n");
  mpCodeColorsWidget->getPreviewPlainTextEdit()->setPlainText(previewText);
  // highlight preview textbox
  MetaModelicaHighlighter *pMetaModelicaHighlighter = new MetaModelicaHighlighter(this, mpCodeColorsWidget->getPreviewPlainTextEdit());
  connect(this, SIGNAL(updatePreview()), pMetaModelicaHighlighter, SLOT(settingsChanged()));
  connect(mpOptionsDialog->getTextEditorPage()->getSyntaxHighlightingGroupBox(), SIGNAL(toggled(bool)),
          pMetaModelicaHighlighter, SLOT(settingsChanged()));
  connect(mpOptionsDialog->getTextEditorPage()->getMatchParenthesesCommentsQuotesCheckBox(), SIGNAL(toggled(bool)),
          pMetaModelicaHighlighter, SLOT(settingsChanged()));
  connect(mpOptionsDialog->getTextEditorPage()->getLineWrappingCheckbox(), SIGNAL(toggled(bool)), this, SLOT(setLineWrapping(bool)));
  // set the layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->addWidget(mpCodeColorsWidget);
  setLayout(pMainLayout);
}

/*!
 * \brief MetaModelicaEditorPage::setColor
 * Sets the color of an item.
 * \param item
 * \param color
 */
void MetaModelicaEditorPage::setColor(QString item, QColor color)
{
  QList<QListWidgetItem*> items = mpCodeColorsWidget->getItemsListWidget()->findItems(item, Qt::MatchExactly);
  if (items.size() > 0) {
    ListWidgetItem *pListWidgetItem = dynamic_cast<ListWidgetItem*>(items.at(0));
    if (pListWidgetItem) {
      pListWidgetItem->setColor(color);
      pListWidgetItem->setForeground(color);
    }
  }
}

/*!
 * \brief MetaModelicaEditorPage::getColor
 * Returns the color of an item.
 * \param item
 * \return
 */
QColor MetaModelicaEditorPage::getColor(QString item)
{
  QList<QListWidgetItem*> items = mpCodeColorsWidget->getItemsListWidget()->findItems(item, Qt::MatchExactly);
  if (items.size() > 0) {
    ListWidgetItem *pListWidgetItem = dynamic_cast<ListWidgetItem*>(items.at(0));
    if (pListWidgetItem) {
      return pListWidgetItem->getColor();
    }
  }
  return QColor(0, 0, 0);
}

/*!
 * \brief MetaModelicaEditorPage::setLineWrapping
 * Slot activated when mpLineWrappingCheckbox toggled SIGNAL is raised.
 * Sets the mpPreviewPlainTextBox line wrapping mode.
 */
void MetaModelicaEditorPage::setLineWrapping(bool enabled)
{
  if (enabled) {
    mpCodeColorsWidget->getPreviewPlainTextEdit()->setLineWrapMode(QPlainTextEdit::WidgetWidth);
  } else {
    mpCodeColorsWidget->getPreviewPlainTextEdit()->setLineWrapMode(QPlainTextEdit::NoWrap);
  }
}

/*!
 * \class CRMLEditorPage
 * \brief Creates an interface for CRML Text settings.
 */
/*!
 * \brief CRMLEditorPage::CRMLEditorPage
 * \param pOptionsDialog is the pointer to OptionsDialog
 */
CRMLEditorPage::CRMLEditorPage(OptionsDialog *pOptionsDialog)
  : QWidget(pOptionsDialog)
{
  mpOptionsDialog = pOptionsDialog;
  // code colors widget
  mpCodeColorsWidget = new CodeColorsWidget(this);
  connect(mpCodeColorsWidget, SIGNAL(colorUpdated()), SIGNAL(updatePreview()));
  // Add items to list
  // number (purple)
  new ListWidgetItem("Number", OptionsDefaults::CRMLEditor::numberRuleColor, mpCodeColorsWidget->getItemsListWidget());
  // keyword (dark red)
  new ListWidgetItem("Keyword", OptionsDefaults::CRMLEditor::keywordRuleColor, mpCodeColorsWidget->getItemsListWidget());
  // type (red)
  new ListWidgetItem("Type", OptionsDefaults::CRMLEditor::typeRuleColor, mpCodeColorsWidget->getItemsListWidget());
  // Quotes (dark green)
  new ListWidgetItem("Quotes", OptionsDefaults::CRMLEditor::quotesRuleColor, mpCodeColorsWidget->getItemsListWidget());
  // comment (dark green)
  new ListWidgetItem("Comment", OptionsDefaults::CRMLEditor::commentRuleColor, mpCodeColorsWidget->getItemsListWidget());
  // preview text
  QString previewText;
  previewText.append("model HelloWorld is {\n"
                     "};\n");
  mpCodeColorsWidget->getPreviewPlainTextEdit()->setPlainText(previewText);
  // highlight preview textbox
  CRMLHighlighter *pCRMLHighlighter = new CRMLHighlighter(this, mpCodeColorsWidget->getPreviewPlainTextEdit());
  connect(this, SIGNAL(updatePreview()), pCRMLHighlighter, SLOT(settingsChanged()));
  connect(mpOptionsDialog->getTextEditorPage()->getSyntaxHighlightingGroupBox(), SIGNAL(toggled(bool)),
          pCRMLHighlighter, SLOT(settingsChanged()));
  connect(mpOptionsDialog->getTextEditorPage()->getMatchParenthesesCommentsQuotesCheckBox(), SIGNAL(toggled(bool)),
          pCRMLHighlighter, SLOT(settingsChanged()));
  connect(mpOptionsDialog->getTextEditorPage()->getLineWrappingCheckbox(), SIGNAL(toggled(bool)), this, SLOT(setLineWrapping(bool)));
  // set the layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->addWidget(mpCodeColorsWidget);
  setLayout(pMainLayout);
}

/*!
 * \brief CRMLEditorPage::setColor
 * Sets the color of an item.
 * \param item
 * \param color
 */
void CRMLEditorPage::setColor(QString item, QColor color)
{
  QList<QListWidgetItem*> items = mpCodeColorsWidget->getItemsListWidget()->findItems(item, Qt::MatchExactly);
  if (items.size() > 0) {
    ListWidgetItem *pListWidgetItem = dynamic_cast<ListWidgetItem*>(items.at(0));
    if (pListWidgetItem) {
      pListWidgetItem->setColor(color);
      pListWidgetItem->setForeground(color);
    }
  }
}

/*!
 * \brief CRMLEditorPage::getColor
 * Returns the color of an item.
 * \param item
 * \return
 */
QColor CRMLEditorPage::getColor(QString item)
{
  QList<QListWidgetItem*> items = mpCodeColorsWidget->getItemsListWidget()->findItems(item, Qt::MatchExactly);
  if (items.size() > 0) {
    ListWidgetItem *pListWidgetItem = dynamic_cast<ListWidgetItem*>(items.at(0));
    if (pListWidgetItem) {
      return pListWidgetItem->getColor();
    }
  }
  return QColor(0, 0, 0);
}

/*!
 * \brief CRMLEditorPage::setLineWrapping
 * Slot activated when mpLineWrappingCheckbox toggled SIGNAL is raised.
 * Sets the mpPreviewPlainTextBox line wrapping mode.
 */
void CRMLEditorPage::setLineWrapping(bool enabled)
{
  if (enabled) {
    mpCodeColorsWidget->getPreviewPlainTextEdit()->setLineWrapMode(QPlainTextEdit::WidgetWidth);
  } else {
    mpCodeColorsWidget->getPreviewPlainTextEdit()->setLineWrapMode(QPlainTextEdit::NoWrap);
  }
}

/*!
 * \class MOSEditorPage
 * \brief Creates an interface for MOS Text settings.
 */
/*!
 * \brief MOSEditorPage::MOSEditorPage
 * \param pOptionsDialog is the pointer to OptionsDialog
 */
MOSEditorPage::MOSEditorPage(OptionsDialog *pOptionsDialog)
  : QWidget(pOptionsDialog)
{
  mpOptionsDialog = pOptionsDialog;
  // code colors widget
  mpCodeColorsWidget = new CodeColorsWidget(this);
  connect(mpCodeColorsWidget, SIGNAL(colorUpdated()), SIGNAL(updatePreview()));
  // Add items to list
  // number (purple)
  new ListWidgetItem("Number", OptionsDefaults::MOSEditor::numberRuleColor, mpCodeColorsWidget->getItemsListWidget());
  // keyword (dark red)
  new ListWidgetItem("Keyword", OptionsDefaults::MOSEditor::keywordRuleColor, mpCodeColorsWidget->getItemsListWidget());
  // type (red)
  new ListWidgetItem("Type", OptionsDefaults::MOSEditor::typeRuleColor, mpCodeColorsWidget->getItemsListWidget());
  // Quotes (dark green)
  new ListWidgetItem("Quotes", OptionsDefaults::MOSEditor::quotesRuleColor, mpCodeColorsWidget->getItemsListWidget());
  // comment (dark green)
  new ListWidgetItem("Comment", OptionsDefaults::MOSEditor::commentRuleColor, mpCodeColorsWidget->getItemsListWidget());
  // preview text
  QString previewText;
  previewText.append("loadModel(Modelica); getErrorString();\n"
                     "simulate(Modelica.Electrical.Analog.Example.Resistor); getErrorString();\n"
                     "a := 1; getErrorString();\n"
                     "b := 2; getErrorString();\n"
                     "x := if true then a else b; getErrorString();\n");
  mpCodeColorsWidget->getPreviewPlainTextEdit()->setPlainText(previewText);
  // highlight preview textbox
  MOSHighlighter *pMOSHighlighter = new MOSHighlighter(this, mpCodeColorsWidget->getPreviewPlainTextEdit());
  connect(this, SIGNAL(updatePreview()), pMOSHighlighter, SLOT(settingsChanged()));
  connect(mpOptionsDialog->getTextEditorPage()->getSyntaxHighlightingGroupBox(), SIGNAL(toggled(bool)),
          pMOSHighlighter, SLOT(settingsChanged()));
  connect(mpOptionsDialog->getTextEditorPage()->getMatchParenthesesCommentsQuotesCheckBox(), SIGNAL(toggled(bool)),
          pMOSHighlighter, SLOT(settingsChanged()));
  connect(mpOptionsDialog->getTextEditorPage()->getLineWrappingCheckbox(), SIGNAL(toggled(bool)), this, SLOT(setLineWrapping(bool)));
  // set the layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->addWidget(mpCodeColorsWidget);
  setLayout(pMainLayout);
}

/*!
 * \brief MOSEditorPage::setColor
 * Sets the color of an item.
 * \param item
 * \param color
 */
void MOSEditorPage::setColor(QString item, QColor color)
{
  QList<QListWidgetItem*> items = mpCodeColorsWidget->getItemsListWidget()->findItems(item, Qt::MatchExactly);
  if (items.size() > 0) {
    ListWidgetItem *pListWidgetItem = dynamic_cast<ListWidgetItem*>(items.at(0));
    if (pListWidgetItem) {
      pListWidgetItem->setColor(color);
      pListWidgetItem->setForeground(color);
    }
  }
}

/*!
 * \brief MOSEditorPage::getColor
 * Returns the color of an item.
 * \param item
 * \return
 */
QColor MOSEditorPage::getColor(QString item)
{
  QList<QListWidgetItem*> items = mpCodeColorsWidget->getItemsListWidget()->findItems(item, Qt::MatchExactly);
  if (items.size() > 0) {
    ListWidgetItem *pListWidgetItem = dynamic_cast<ListWidgetItem*>(items.at(0));
    if (pListWidgetItem) {
      return pListWidgetItem->getColor();
    }
  }
  return QColor(0, 0, 0);
}

/*!
 * \brief MOSEditorPage::setLineWrapping
 * Slot activated when mpLineWrappingCheckbox toggled SIGNAL is raised.
 * Sets the mpPreviewPlainTextBox line wrapping mode.
 */
void MOSEditorPage::setLineWrapping(bool enabled)
{
  if (enabled) {
    mpCodeColorsWidget->getPreviewPlainTextEdit()->setLineWrapMode(QPlainTextEdit::WidgetWidth);
  } else {
    mpCodeColorsWidget->getPreviewPlainTextEdit()->setLineWrapMode(QPlainTextEdit::NoWrap);
  }
}

/*!
 * \class OMSimulatorEditorPage
 * \brief Creates an interface for OMS Text settings.
 */
/*!
 * \brief OMSimulatorEditorPage::OMSimulatorEditorPage
 * \param pOptionsDialog is the pointer to OptionsDialog
 */
OMSimulatorEditorPage::OMSimulatorEditorPage(OptionsDialog *pOptionsDialog)
  : QWidget(pOptionsDialog)
{
  mpOptionsDialog = pOptionsDialog;
  // code colors widget
  mpCodeColorsWidget = new CodeColorsWidget(this);
  connect(mpCodeColorsWidget, SIGNAL(colorUpdated()), SIGNAL(updatePreview()));
  // Add items to list
  // tag (blue)
  new ListWidgetItem("Tag", OptionsDefaults::OMSimulatorEditor::tagRuleColor, mpCodeColorsWidget->getItemsListWidget());
  // element (blue)
  new ListWidgetItem("Element", OptionsDefaults::OMSimulatorEditor::elementRuleColor, mpCodeColorsWidget->getItemsListWidget());
  // quotes (dark red)
  new ListWidgetItem("Quotes", OptionsDefaults::OMSimulatorEditor::quotesRuleColor, mpCodeColorsWidget->getItemsListWidget());
  // comment (dark green)
  new ListWidgetItem("Comment", OptionsDefaults::OMSimulatorEditor::commentRuleColor, mpCodeColorsWidget->getItemsListWidget());
  // preview textbox
  QString previewText;
  previewText.append("<!-- This is a comment. -->\n"
                     "<ssd:SystemStructureDescription name=\"model\">"
                     "\t<ssd:System name=\"model\">\n"
                     "\t\t<ssd:Component name=\"adder1\" type=\"application/x-fmu-sharedlibrary\" source=\"FMUs/adder.fmu\">\n"
                     "\t\t\t<ssd:ElementGeometry x1=\"40\" y1=\"20\" x2=\"60\" y2=\"40\" rotation=\"0\" iconRotation=\"0\" iconFlip=\"false\" iconFixedAspectRatio=\"false\" />\n"
                     "\t\t\t<ssd:Connectors />\n"
                     "\t\t</ssd:Component>\n"
                     "\t\t<ssd:Connections />\n"
                     "\t</ssd:System>\n"
                     "\t<ssd:DefaultExperiment startTime=\"0\" stopTime=\"5\" />\n"
                     "</ssd:SystemStructureDescription>");
  mpCodeColorsWidget->getPreviewPlainTextEdit()->setPlainText(previewText);
  // highlight preview textbox
  OMSimulatorHighlighter *pOMSimulatorHighlighter = new OMSimulatorHighlighter(this, mpCodeColorsWidget->getPreviewPlainTextEdit());
  connect(this, SIGNAL(updatePreview()), pOMSimulatorHighlighter, SLOT(settingsChanged()));
  connect(mpOptionsDialog->getTextEditorPage()->getSyntaxHighlightingGroupBox(), SIGNAL(toggled(bool)),
          pOMSimulatorHighlighter, SLOT(settingsChanged()));
  connect(mpOptionsDialog->getTextEditorPage()->getMatchParenthesesCommentsQuotesCheckBox(), SIGNAL(toggled(bool)),
          pOMSimulatorHighlighter, SLOT(settingsChanged()));
  connect(mpOptionsDialog->getTextEditorPage()->getLineWrappingCheckbox(), SIGNAL(toggled(bool)), this, SLOT(setLineWrapping(bool)));
  // set the layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->addWidget(mpCodeColorsWidget);
  setLayout(pMainLayout);
}

/*!
 * \brief OMSimulatorEditorPage::setColor
 * Sets the color of an item.
 * \param item
 * \param color
 */
void OMSimulatorEditorPage::setColor(QString item, QColor color)
{
  QList<QListWidgetItem*> items = mpCodeColorsWidget->getItemsListWidget()->findItems(item, Qt::MatchExactly);
  if (items.size() > 0) {
    ListWidgetItem *pListWidgetItem = dynamic_cast<ListWidgetItem*>(items.at(0));
    if (pListWidgetItem) {
      pListWidgetItem->setColor(color);
      pListWidgetItem->setForeground(color);
    }
  }
}

/*!
 * \brief OMSimulatorEditorPage::getColor
 * Returns the color of an item.
 * \param item
 * \return
 */
QColor OMSimulatorEditorPage::getColor(QString item)
{
  QList<QListWidgetItem*> items = mpCodeColorsWidget->getItemsListWidget()->findItems(item, Qt::MatchExactly);
  if (items.size() > 0) {
    ListWidgetItem *pListWidgetItem = dynamic_cast<ListWidgetItem*>(items.at(0));
    if (pListWidgetItem) {
      return pListWidgetItem->getColor();
    }
  }
  return QColor(0, 0, 0);
}

/*!
 * \brief OMSimulatorEditorPage::setLineWrapping
 * Slot activated when mpLineWrappingCheckbox toggled SIGNAL is raised.
 * Sets the mpPreviewPlainTextBox line wrapping mode.
 */
void OMSimulatorEditorPage::setLineWrapping(bool enabled)
{
  if (enabled) {
    mpCodeColorsWidget->getPreviewPlainTextEdit()->setLineWrapMode(QPlainTextEdit::WidgetWidth);
  } else {
    mpCodeColorsWidget->getPreviewPlainTextEdit()->setLineWrapMode(QPlainTextEdit::NoWrap);
  }
}

/*!
 * \class CEditorPage
 * \brief Creates an interface for C Text settings.
 */
/*!
 * \brief CEditorPage::CEditorPage
 * \param pOptionsDialog is the pointer to OptionsDialog
 */
CEditorPage::CEditorPage(OptionsDialog *pOptionsDialog)
  : QWidget(pOptionsDialog)
{
  mpOptionsDialog = pOptionsDialog;
  // code colors widget
  mpCodeColorsWidget = new CodeColorsWidget(this);
  connect(mpCodeColorsWidget, SIGNAL(colorUpdated()), SIGNAL(updatePreview()));
  // Add items to list
  // number (purple)
  new ListWidgetItem("Number", OptionsDefaults::CEditor::numberRuleColor, mpCodeColorsWidget->getItemsListWidget());
  // keyword (dark red)
  new ListWidgetItem("Keyword", OptionsDefaults::CEditor::keywordRuleColor, mpCodeColorsWidget->getItemsListWidget());
  // type (red)
  new ListWidgetItem("Type", OptionsDefaults::CEditor::typeRuleColor, mpCodeColorsWidget->getItemsListWidget());
  // Quotes (dark green)
  new ListWidgetItem("Quotes", OptionsDefaults::CEditor::quotesRuleColor, mpCodeColorsWidget->getItemsListWidget());
  // comment (dark green)
  new ListWidgetItem("Comment", OptionsDefaults::CEditor::commentRuleColor, mpCodeColorsWidget->getItemsListWidget());
  // preview text
  QString previewText;
  previewText.append("#include <stdio.h>\n"
                     "int main() { /* block\n"
                     "comment */\n"
                     "\tprintf(\"Hello World\"); // Line comment\n"
                     "return 0;\n"
                     "}\n");
  mpCodeColorsWidget->getPreviewPlainTextEdit()->setPlainText(previewText);
  // highlight preview textbox
  CHighlighter *pCHighlighter = new CHighlighter(this, mpCodeColorsWidget->getPreviewPlainTextEdit());
  connect(this, SIGNAL(updatePreview()), pCHighlighter, SLOT(settingsChanged()));
  connect(mpOptionsDialog->getTextEditorPage()->getSyntaxHighlightingGroupBox(), SIGNAL(toggled(bool)),
          pCHighlighter, SLOT(settingsChanged()));
  connect(mpOptionsDialog->getTextEditorPage()->getMatchParenthesesCommentsQuotesCheckBox(), SIGNAL(toggled(bool)),
          pCHighlighter, SLOT(settingsChanged()));
  connect(mpOptionsDialog->getTextEditorPage()->getLineWrappingCheckbox(), SIGNAL(toggled(bool)), this, SLOT(setLineWrapping(bool)));
  // set the layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->addWidget(mpCodeColorsWidget);
  setLayout(pMainLayout);
}

/*!
 * \brief CEditorPage::setColor
 * Sets the color of an item.
 * \param item
 * \param color
 */
void CEditorPage::setColor(QString item, QColor color)
{
  QList<QListWidgetItem*> items = mpCodeColorsWidget->getItemsListWidget()->findItems(item, Qt::MatchExactly);
  if (items.size() > 0) {
    ListWidgetItem *pListWidgetItem = dynamic_cast<ListWidgetItem*>(items.at(0));
    if (pListWidgetItem) {
      pListWidgetItem->setColor(color);
      pListWidgetItem->setForeground(color);
    }
  }
}

/*!
 * \brief CEditorPage::getColor
 * Returns the color of an item.
 * \param item
 * \return
 */
QColor CEditorPage::getColor(QString item)
{
  QList<QListWidgetItem*> items = mpCodeColorsWidget->getItemsListWidget()->findItems(item, Qt::MatchExactly);
  if (items.size() > 0) {
    ListWidgetItem *pListWidgetItem = dynamic_cast<ListWidgetItem*>(items.at(0));
    if (pListWidgetItem) {
      return pListWidgetItem->getColor();
    }
  }
  return QColor(0, 0, 0);
}

/*!
 * \brief CEditorPage::setLineWrapping
 * Slot activated when mpLineWrappingCheckbox toggled SIGNAL is raised.
 * Sets the mpPreviewPlainTextBox line wrapping mode.
 */
void CEditorPage::setLineWrapping(bool enabled)
{
  if (enabled) {
    mpCodeColorsWidget->getPreviewPlainTextEdit()->setLineWrapMode(QPlainTextEdit::WidgetWidth);
  } else {
    mpCodeColorsWidget->getPreviewPlainTextEdit()->setLineWrapMode(QPlainTextEdit::NoWrap);
  }
}

/*!
 * \class HTMLEditorPage
 * \brief Creates an interface for HTML Text settings.
 */
/*!
 * \brief HTMLEditorPage::HTMLEditorPage
 * \param pOptionsDialog is the pointer to OptionsDialog
 */
HTMLEditorPage::HTMLEditorPage(OptionsDialog *pOptionsDialog)
  : QWidget(pOptionsDialog)
{
  mpOptionsDialog = pOptionsDialog;
  // code colors widget
  mpCodeColorsWidget = new CodeColorsWidget(this);
  connect(mpCodeColorsWidget, SIGNAL(colorUpdated()), SIGNAL(updatePreview()));
  // Add items to list
  // tag (blue)
  new ListWidgetItem("Tag", OptionsDefaults::HTMLEditor::tagRuleColor, mpCodeColorsWidget->getItemsListWidget());
  // quotes (dark red)
  new ListWidgetItem("Quotes", OptionsDefaults::HTMLEditor::quotesRuleColor, mpCodeColorsWidget->getItemsListWidget());
  // comment (dark green)
  new ListWidgetItem("Comment", OptionsDefaults::HTMLEditor::commentRuleColor, mpCodeColorsWidget->getItemsListWidget());
  // preview textbox
  QString previewText;
  previewText.append("<!-- This is a comment. -->\n"
                     "<html>\n"
                     "\t<body>\n"
                     "\t\t<h1>OPENMODELICA</h1>\n"
                     "\t\t<p>OpenModelica is an open-source Modelica-based modeling and simulation environment"
                     " intended for industrial and academic usage. Its long-term development is supported by a"
                     " non-profit organization – the <a href=\"http://www.openmodelica.org\">Open Source Modelica Consortium (OSMC)</a></p>\n"
                     "\t</body>\n"
                     "</html>\n");
  mpCodeColorsWidget->getPreviewPlainTextEdit()->setPlainText(previewText);
  // highlight preview textbox
  HTMLHighlighter *pHTMLHighlighter = new HTMLHighlighter(this, mpCodeColorsWidget->getPreviewPlainTextEdit());
  connect(this, SIGNAL(updatePreview()), pHTMLHighlighter, SLOT(settingsChanged()));
  connect(mpOptionsDialog->getTextEditorPage()->getSyntaxHighlightingGroupBox(), SIGNAL(toggled(bool)),
          pHTMLHighlighter, SLOT(settingsChanged()));
  connect(mpOptionsDialog->getTextEditorPage()->getMatchParenthesesCommentsQuotesCheckBox(), SIGNAL(toggled(bool)),
          pHTMLHighlighter, SLOT(settingsChanged()));
  connect(mpOptionsDialog->getTextEditorPage()->getLineWrappingCheckbox(), SIGNAL(toggled(bool)), this, SLOT(setLineWrapping(bool)));
  // set the layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->addWidget(mpCodeColorsWidget);
  setLayout(pMainLayout);
}

/*!
 * \brief HTMLEditorPage::setColor
 * Sets the color of an item.
 * \param item
 * \param color
 */
void HTMLEditorPage::setColor(QString item, QColor color)
{
  QList<QListWidgetItem*> items = mpCodeColorsWidget->getItemsListWidget()->findItems(item, Qt::MatchExactly);
  if (items.size() > 0) {
    ListWidgetItem *pListWidgetItem = dynamic_cast<ListWidgetItem*>(items.at(0));
    if (pListWidgetItem) {
      pListWidgetItem->setColor(color);
      pListWidgetItem->setForeground(color);
    }
  }
}

/*!
 * \brief HTMLEditorPage::getColor
 * Returns the color of an item.
 * \param item
 * \return
 */
QColor HTMLEditorPage::getColor(QString item)
{
  QList<QListWidgetItem*> items = mpCodeColorsWidget->getItemsListWidget()->findItems(item, Qt::MatchExactly);
  if (items.size() > 0) {
    ListWidgetItem *pListWidgetItem = dynamic_cast<ListWidgetItem*>(items.at(0));
    if (pListWidgetItem) {
      return pListWidgetItem->getColor();
    }
  }
  return QColor(0, 0, 0);
}

/*!
 * \brief HTMLEditorPage::setLineWrapping
 * Slot activated when mpLineWrappingCheckbox toggled SIGNAL is raised.
 * Sets the mpPreviewPlainTextBox line wrapping mode.
 */
void HTMLEditorPage::setLineWrapping(bool enabled)
{
  if (enabled) {
    mpCodeColorsWidget->getPreviewPlainTextEdit()->setLineWrapMode(QPlainTextEdit::WidgetWidth);
  } else {
    mpCodeColorsWidget->getPreviewPlainTextEdit()->setLineWrapMode(QPlainTextEdit::NoWrap);
  }
}

GraphicalViewsPage::GraphicalViewsPage(OptionsDialog *pOptionsDialog)
  : QWidget(pOptionsDialog)
{
  mpOptionsDialog = pOptionsDialog;
  QGroupBox *pGeneralGroupBox = new QGroupBox(Helper::general);
  // Modeling View Mode
  QGroupBox *pModelingViewModeGroupBox = new QGroupBox(tr("Default Modeling View Mode"));
  mpModelingTabbedViewRadioButton = new QRadioButton(tr("Tabbed View"));
  mpModelingTabbedViewRadioButton->setChecked(true);
  mpModelingSubWindowViewRadioButton = new QRadioButton(tr("SubWindow View"));
  QButtonGroup *pModelingViewModeButtonGroup = new QButtonGroup(this);
  pModelingViewModeButtonGroup->addButton(mpModelingTabbedViewRadioButton);
  pModelingViewModeButtonGroup->addButton(mpModelingSubWindowViewRadioButton);
  // modeling view radio buttons layout
  QHBoxLayout *pModelingRadioButtonsLayout = new QHBoxLayout;
  pModelingRadioButtonsLayout->addWidget(mpModelingTabbedViewRadioButton);
  pModelingRadioButtonsLayout->addWidget(mpModelingSubWindowViewRadioButton);
  // set the layout of modeling view mode group
  QGridLayout *modelingViewModeLayout = new QGridLayout;
  modelingViewModeLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  modelingViewModeLayout->addLayout(pModelingRadioButtonsLayout, 0, 0);
  pModelingViewModeGroupBox->setLayout(modelingViewModeLayout);
  // Default View
  QGroupBox *pDefaultViewGroupBox = new QGroupBox(tr("Default View"));
  pDefaultViewGroupBox->setToolTip(tr("This settings will be used when no preferredView annotation is defined."));
  mpIconViewRadioButton = new QRadioButton(Helper::iconView);
  mpDiagramViewRadioButton = new QRadioButton(Helper::diagramView);
  mpDiagramViewRadioButton->setChecked(true);
  mpTextViewRadioButton = new QRadioButton(Helper::textView);
  mpDocumentationViewRadioButton = new QRadioButton(Helper::documentationView);
  QButtonGroup *pDefaultViewButtonGroup = new QButtonGroup(this);
  pDefaultViewButtonGroup->addButton(mpIconViewRadioButton);
  pDefaultViewButtonGroup->addButton(mpDiagramViewRadioButton);
  pDefaultViewButtonGroup->addButton(mpTextViewRadioButton);
  pDefaultViewButtonGroup->addButton(mpDocumentationViewRadioButton);
  // default view radio buttons layout
  QGridLayout *pDefaultViewRadioButtonsGridLayout = new QGridLayout;
  pDefaultViewRadioButtonsGridLayout->addWidget(mpIconViewRadioButton, 0, 0);
  pDefaultViewRadioButtonsGridLayout->addWidget(mpDiagramViewRadioButton, 0, 1);
  pDefaultViewRadioButtonsGridLayout->addWidget(mpTextViewRadioButton, 1, 0);
  pDefaultViewRadioButtonsGridLayout->addWidget(mpDocumentationViewRadioButton, 1, 1);
  // set the layout of default view group
  QGridLayout *pDefaultViewLayout = new QGridLayout;
  pDefaultViewLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pDefaultViewLayout->addLayout(pDefaultViewRadioButtonsGridLayout, 0, 0);
  pDefaultViewGroupBox->setLayout(pDefaultViewLayout);
  // move connectors together checkbox
  mpMoveConnectorsTogetherCheckBox = new QCheckBox(tr("Move connectors together on both icon and diagram layers"));
  mpMoveConnectorsTogetherCheckBox->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Preferred);
  // set the layout of general groupbox
  QGridLayout *pGeneralGroupBoxLayout = new QGridLayout;
  pGeneralGroupBoxLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pGeneralGroupBoxLayout->addWidget(pModelingViewModeGroupBox, 0, 0);
  pGeneralGroupBoxLayout->addWidget(pDefaultViewGroupBox, 1, 0);
  pGeneralGroupBoxLayout->addWidget(mpMoveConnectorsTogetherCheckBox, 2, 0);
  pGeneralGroupBox->setLayout(pGeneralGroupBoxLayout);
  // set Main Layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addWidget(pGeneralGroupBox);
  setLayout(pMainLayout);
}

/*!
 * \brief GraphicalViewsPage::setModelingViewMode
 * Sets the Modeling view mode.
 * \param value
 */
void GraphicalViewsPage::setModelingViewMode(QString value)
{
  if (value.compare(Helper::subWindow) == 0) {
    mpModelingSubWindowViewRadioButton->setChecked(true);
  } else {
    mpModelingTabbedViewRadioButton->setChecked(true);
  }
}

/*!
 * \brief GraphicalViewsPage::getModelingViewMode
 * Gets the Modeling view mode.
 * \return
 */
QString GraphicalViewsPage::getModelingViewMode()
{
  if (mpModelingSubWindowViewRadioButton->isChecked()) {
    return Helper::subWindow;
  } else {
    return Helper::tabbed;
  }
}

/*!
 * \brief GraphicalViewsPage::setDefaultView
 * Sets the default view.
 * \param value
 */
void GraphicalViewsPage::setDefaultView(QString value)
{
  if (value.compare(Helper::iconViewForSettings) == 0) {
    mpIconViewRadioButton->setChecked(true);
  } else if (value.compare(Helper::textViewForSettings) == 0) {
    mpTextViewRadioButton->setChecked(true);
  } else if (value.compare(Helper::documentationViewForSettings) == 0) {
    mpDocumentationViewRadioButton->setChecked(true);
  } else {
    mpDiagramViewRadioButton->setChecked(true);
  }
}

/*!
 * \brief GraphicalViewsPage::getDefaultView
 * Returns the default view as QString.
 * \return
 */
QString GraphicalViewsPage::getDefaultView()
{
  if (mpIconViewRadioButton->isChecked()) {
    return Helper::iconViewForSettings;
  } else if (mpTextViewRadioButton->isChecked()) {
    return Helper::textViewForSettings;
  } else if (mpDocumentationViewRadioButton->isChecked()) {
    return Helper::documentationViewForSettings;
  } else {
    return Helper::diagramViewForSettings;
  }
}

//! @class SimulationPage
//! @brief Creates an interface for simulation settings.

//! Constructor
//! @param pOptionsDialog is the pointer to OptionsDialog
SimulationPage::SimulationPage(OptionsDialog *pOptionsDialog)
  : QWidget(pOptionsDialog)
{
  mpOptionsDialog = pOptionsDialog;
  mpSimulationGroupBox = new QGroupBox(Helper::simulation);
  // Translation Flags
  mpTranslationFlagsGroupBox = new QGroupBox(Helper::translationFlags);
  mpTranslationFlagsWidget = new TranslationFlagsWidget(this);
  SimulationOptions simulationOptions;
  mpTranslationFlagsWidget->applySimulationOptions(simulationOptions);
  // Translation Flags layout
  QGridLayout *pTranslationFlagsGridLayout = new QGridLayout;
  pTranslationFlagsGridLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pTranslationFlagsGridLayout->addWidget(new Label("Global flags applied to the Simulation Setup dialog upon the first simulation of a model.\n"
                                                   "For subsequent simulations, you can change them locally using the Simulation Setup dialog."), 0, 0);
  pTranslationFlagsGridLayout->addWidget(mpTranslationFlagsWidget, 1, 0);
  mpTranslationFlagsGroupBox->setLayout(pTranslationFlagsGridLayout);
  // Target Language
  mpTargetLanguageLabel = new Label(tr("Target Language:"));
  OMCInterface::getConfigFlagValidOptions_res simCodeTarget = MainWindow::instance()->getOMCProxy()->getConfigFlagValidOptions("simCodeTarget");
  mpTargetLanguageComboBox = new ComboBox;
  mpTargetLanguageComboBox->addItems(simCodeTarget.validOptions);
  mpTargetLanguageComboBox->setCurrentIndex(mpTargetLanguageComboBox->findText("C"));
  Utilities::setToolTip(mpTargetLanguageComboBox, simCodeTarget.mainDescription, simCodeTarget.descriptions);
  // Target Build
  mpTargetBuildLabel = new Label(tr("Target Build:"));
  mpTargetBuildComboBox = new ComboBox;
#ifdef Q_OS_WIN
  mpTargetBuildComboBox->addItem("MinGW", "gcc");
  // We do not support any of the MSVC targets anymore
  // mpTargetBuildComboBox->addItem("Visual Studio (msvc)", "msvc");
  // mpTargetBuildComboBox->addItem("Visual Studio 2010 (msvc10)", "msvc10");
  // mpTargetBuildComboBox->addItem("Visual Studio 2012 (msvc12)", "msvc12");
  // mpTargetBuildComboBox->addItem("Visual Studio 2013 (msvc13)", "msvc13");
  // mpTargetBuildComboBox->addItem("Visual Studio 2015 (msvc15)", "msvc15");
  // mpTargetBuildComboBox->addItem("Visual Studio 2019 (msvc19)", "msvc19");
#else
  mpTargetBuildComboBox->addItem("GNU Make", "gcc");
#endif
  mpTargetBuildComboBox->addItem("vxworks69", "vxworks69");
  mpTargetBuildComboBox->addItem("debugrt", "debugrt");
  connect(mpTargetBuildComboBox, SIGNAL(currentIndexChanged(int)), SLOT(targetBuildChanged(int)));
  // C Compiler
  mpCompilerLabel = new Label(tr("C Compiler:"));
  mpCompilerComboBox = new ComboBox;
  mpCompilerComboBox->setEditable(true);
  mpCompilerComboBox->addItem("");
  mpCompilerComboBox->addItem("gcc");
#ifdef Q_OS_UNIX
  mpCompilerComboBox->addItem("clang");
#endif
  OptionsDefaults::Simulation::cCompiler = MainWindow::instance()->getOMCProxy()->getCompiler();
  mpCompilerComboBox->lineEdit()->setPlaceholderText(OptionsDefaults::Simulation::cCompiler);
  // CXX Compiler
  mpCXXCompilerLabel = new Label(tr("CXX Compiler:"));
  mpCXXCompilerComboBox = new ComboBox;
  mpCXXCompilerComboBox->setEditable(true);
  mpCXXCompilerComboBox->addItem("");
  mpCXXCompilerComboBox->addItem("g++");
#ifdef Q_OS_UNIX
  mpCXXCompilerComboBox->addItem("clang++");
#endif
  OptionsDefaults::Simulation::cxxCompiler = MainWindow::instance()->getOMCProxy()->getCXXCompiler();
  mpCXXCompilerComboBox->lineEdit()->setPlaceholderText(OptionsDefaults::Simulation::cxxCompiler);
#ifdef Q_OS_WIN
  mpUseStaticLinkingCheckBox = new QCheckBox(tr("Use static Linking"));
  mpUseStaticLinkingCheckBox->setToolTip(tr("Enables static linking for the simulation executable. Default is dynamic linking."));
#endif
  // post compilation command line edit
  mpPostCompilationCommandLineEdit = new QLineEdit;
  QLayout * mpPostCompilationCommandLayout = new QHBoxLayout;
  mpPostCompilationCommandLayout->addWidget(new Label(tr("Post compilation command:")));
  mpPostCompilationCommandLayout->addWidget(mpPostCompilationCommandLineEdit);
  // ignore command line options annotation checkbox
  mpIgnoreCommandLineOptionsAnnotationCheckBox = new QCheckBox(tr("Ignore __OpenModelica_commandLineOptions annotation"));
  // ignore simulation flags annotation checkbox
  mpIgnoreSimulationFlagsAnnotationCheckBox = new QCheckBox(tr("Ignore __OpenModelica_simulationFlags annotation"));
  /* save class before simulation checkbox */
  mpSaveClassBeforeSimulationCheckBox = new QCheckBox(tr("Save class before simulation"));
  mpSaveClassBeforeSimulationCheckBox->setToolTip(tr("Disabling this will effect the debugger functionality."));
  mpSaveClassBeforeSimulationCheckBox->setChecked(OptionsDefaults::Simulation::saveClassBeforeSimulation);
  /* switch to plotting perspective after simulation checkbox */
  mpSwitchToPlottingPerspectiveCheckBox = new QCheckBox(tr("Switch to plotting perspective after simulation"));
  mpSwitchToPlottingPerspectiveCheckBox->setChecked(OptionsDefaults::Simulation::switchToPlottingPerspective);
  /* Close completed SimulationOutputWidgets before simulation checkbox */
  mpCloseSimulationOutputWidgetsBeforeSimulationCheckBox = new QCheckBox(tr("Close completed simulation output windows before simulation"));
  mpCloseSimulationOutputWidgetsBeforeSimulationCheckBox->setChecked(OptionsDefaults::Simulation::closeSimulationOutputWidgetsBeforeSimulation);
  /* Delete intermediate compilation files checkbox */
  mpDeleteIntermediateCompilationFilesCheckBox = new QCheckBox(tr("Delete intermediate compilation files"));
  mpDeleteIntermediateCompilationFilesCheckBox->setChecked(OptionsDefaults::Simulation::deleteIntermediateCompilationFiles);
  /* Delete entire simulation directory checkbox */
  mpDeleteEntireSimulationDirectoryCheckBox = new QCheckBox(tr("Delete entire simulation directory of the model when OMEdit is closed"));
  // simulation output format
  mpOutputGroupBox = new QGroupBox(Helper::output);
  mpStructuredRadioButton = new QRadioButton(tr("Structured"));
  mpStructuredRadioButton->setToolTip(tr("Shows the simulation output in the form of tree structure."));
  mpStructuredRadioButton->setChecked(true);
  mpFormattedTextRadioButton = new QRadioButton(tr("Formatted Text"));
  mpFormattedTextRadioButton->setToolTip(tr("Shows the simulation output in the form of formatted text."));
  QButtonGroup *pOutputButtonGroup = new QButtonGroup(this);
  pOutputButtonGroup->addButton(mpStructuredRadioButton);
  pOutputButtonGroup->addButton(mpFormattedTextRadioButton);
  // output view buttons layout
  QHBoxLayout *pOutputRadioButtonsLayout = new QHBoxLayout;
  pOutputRadioButtonsLayout->addWidget(mpStructuredRadioButton);
  pOutputRadioButtonsLayout->addWidget(mpFormattedTextRadioButton);
  // display limit
  mpDisplayLimitLabel = new Label(tr("Display Limit:"));
  mpDisplayLimitSpinBox = new SpinBox;
  mpDisplayLimitSpinBox->setSuffix(" KB");
  mpDisplayLimitSpinBox->setRange(1, std::numeric_limits<int>::max());
  mpDisplayLimitSpinBox->setSingleStep(100);
  mpDisplayLimitSpinBox->setValue(OptionsDefaults::Simulation::displayLimit);
  mpDisplayLimitMBLabel = new Label;
  connect(mpDisplayLimitSpinBox, SIGNAL(valueChanged(int)), SLOT(displayLimitValueChanged(int)));
  // calculate the display limit in MBs.
  displayLimitValueChanged(mpDisplayLimitSpinBox->value());
  // set the layout of output view mode group
  QGridLayout *pOutputGroupGridLayout = new QGridLayout;
  pOutputGroupGridLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pOutputGroupGridLayout->addLayout(pOutputRadioButtonsLayout, 0, 0, 1, 3, Qt::AlignLeft);
  pOutputGroupGridLayout->addWidget(mpDisplayLimitLabel, 1, 0);
  pOutputGroupGridLayout->addWidget(mpDisplayLimitSpinBox, 1, 1);
  pOutputGroupGridLayout->addWidget(mpDisplayLimitMBLabel, 1, 2);
  mpOutputGroupBox->setLayout(pOutputGroupGridLayout);
  // set the layout of simulation group
  QGridLayout *pSimulationLayout = new QGridLayout;
  pSimulationLayout->setAlignment(Qt::AlignTop);
  int row = 0;
  pSimulationLayout->addWidget(mpTranslationFlagsGroupBox, row++, 0, 1, 2);
  pSimulationLayout->addWidget(mpTargetLanguageLabel, row, 0);
  pSimulationLayout->addWidget(mpTargetLanguageComboBox, row++, 1);
  pSimulationLayout->addWidget(mpTargetBuildLabel, row, 0);
  pSimulationLayout->addWidget(mpTargetBuildComboBox, row++, 1);
  pSimulationLayout->addWidget(mpCompilerLabel, row, 0);
  pSimulationLayout->addWidget(mpCompilerComboBox, row++, 1);
  pSimulationLayout->addWidget(mpCXXCompilerLabel, row, 0);
  pSimulationLayout->addWidget(mpCXXCompilerComboBox, row++, 1);
#ifdef Q_OS_WIN
  pSimulationLayout->addWidget(mpUseStaticLinkingCheckBox, row++, 0, 1, 2);
#endif
  pSimulationLayout->addLayout(mpPostCompilationCommandLayout, row++, 0, 1, 2);
  pSimulationLayout->addWidget(mpIgnoreCommandLineOptionsAnnotationCheckBox, row++, 0, 1, 2);
  pSimulationLayout->addWidget(mpIgnoreSimulationFlagsAnnotationCheckBox, row++, 0, 1, 2);
  pSimulationLayout->addWidget(mpSaveClassBeforeSimulationCheckBox, row++, 0, 1, 2);
  pSimulationLayout->addWidget(mpSwitchToPlottingPerspectiveCheckBox, row++, 0, 1, 2);
  pSimulationLayout->addWidget(mpCloseSimulationOutputWidgetsBeforeSimulationCheckBox, row++, 0, 1, 2);
  pSimulationLayout->addWidget(mpDeleteIntermediateCompilationFilesCheckBox, row++, 0, 1, 2);
  pSimulationLayout->addWidget(mpDeleteEntireSimulationDirectoryCheckBox, row++, 0, 1, 2);
  pSimulationLayout->addWidget(mpOutputGroupBox, row++, 0, 1, 2);
  mpSimulationGroupBox->setLayout(pSimulationLayout);
  // set the layout
  QVBoxLayout *pLayout = new QVBoxLayout;
  pLayout->setAlignment(Qt::AlignTop);
  pLayout->addWidget(mpSimulationGroupBox);
  setLayout(pLayout);
}

void SimulationPage::setOutputMode(QString value)
{
  if (value.compare(Helper::structuredOutput) == 0) {
    mpStructuredRadioButton->setChecked(true);
  } else {
    mpFormattedTextRadioButton->setChecked(true);
  }
}

QString SimulationPage::getOutputMode()
{
  if (mpStructuredRadioButton->isChecked()) {
    return Helper::structuredOutput;
  } else {
    return Helper::textOutput;
  }
}

/*!
 * \brief SimulationPage::targetBuildChanged
 * Enable/Disable the Compiler and CXX Compiler fields.
 * \param index
 */
void SimulationPage::targetBuildChanged(int index)
{
  if (mpTargetBuildComboBox->itemData(index).toString() == "gcc") {
    mpCompilerComboBox->setEnabled(true);
    mpCXXCompilerComboBox->setEnabled(true);
  } else {
    mpCompilerComboBox->setEnabled(false);
    mpCXXCompilerComboBox->setEnabled(false);
  }
}

/*!
 * \brief SimulationPage::displayLimitValueChanged
 * Slot activated when mpDisplayLimitSpinBox valueChanged SIGNAL is raised.
 * Shows the display limit is MBs.
 * 1 KB is 0,001 MB.
 * \param value
 */
void SimulationPage::displayLimitValueChanged(int value)
{
  mpDisplayLimitMBLabel->setText(QString("(%1 MB)").arg(value*0.001));
}

//! @class MessagesPage
//! @brief Creates an interface for MessagesWidget settings.

//! Constructor
//! @param pOptionsDialog is the pointer to OptionsDialog
MessagesPage::MessagesPage(OptionsDialog *pOptionsDialog)
  : QWidget(pOptionsDialog)
{
  mpOptionsDialog = pOptionsDialog;
  // general groupbox
  mpGeneralGroupBox = new QGroupBox(Helper::general);
  // output size
  mpOutputSizeLabel = new Label(tr("Output size:"));
  mpOutputSizeLabel->setToolTip(tr("Specifies the maximum number of rows the message browser may have. "
                                   "If there are more rows then the rows are removed from the beginning."));
  mpOutputSizeSpinBox = new SpinBox;
  mpOutputSizeSpinBox->setRange(0, std::numeric_limits<int>::max());
  mpOutputSizeSpinBox->setSingleStep(1000);
  mpOutputSizeSpinBox->setSuffix(" rows");
  mpOutputSizeSpinBox->setSpecialValueText(Helper::unlimited);
  // reset messages number before simulation
  mpResetMessagesNumberBeforeSimulationCheckBox = new QCheckBox(tr("Reset messages number before checking, instantiation, and simulation"));
  mpResetMessagesNumberBeforeSimulationCheckBox->setChecked(OptionsDefaults::Messages::resetMessagesNumberBeforeSimulation);
  // clear message browser before simulation
  mpClearMessagesBrowserBeforeSimulationCheckBox = new QCheckBox(tr("Clear message browser before checking, instantiation, and simulation"));
  // enlarge message browser on a new message
  mpEnlargeMessageBrowserCheckBox = new QCheckBox(tr("Do not automatically enlarge message browser when a new message is available"));
  // set general groupbox layout
  QGridLayout *pGeneralGroupBoxLayout = new QGridLayout;
  pGeneralGroupBoxLayout->setColumnStretch(1, 1);
  pGeneralGroupBoxLayout->addWidget(mpOutputSizeLabel, 0, 0);
  pGeneralGroupBoxLayout->addWidget(mpOutputSizeSpinBox, 0, 1);
  pGeneralGroupBoxLayout->addWidget(mpResetMessagesNumberBeforeSimulationCheckBox, 1, 0, 1, 2);
  pGeneralGroupBoxLayout->addWidget(mpClearMessagesBrowserBeforeSimulationCheckBox, 2, 0, 1, 2);
  pGeneralGroupBoxLayout->addWidget(mpEnlargeMessageBrowserCheckBox, 3, 0, 1, 2);
  mpGeneralGroupBox->setLayout(pGeneralGroupBoxLayout);
  // Font and Colors
  mpFontColorsGroupBox = new QGroupBox(Helper::Colors);
  // font family combobox
  mpFontFamilyLabel = new Label(Helper::fontFamily);
  mpFontFamilyComboBox = new QFontComboBox;
  QTextBrowser textBrowser;
  int currentIndex;
  currentIndex = mpFontFamilyComboBox->findText(textBrowser.font().family(), Qt::MatchExactly);
  mpFontFamilyComboBox->setCurrentIndex(currentIndex);
  // font size combobox
  mpFontSizeLabel = new Label(Helper::fontSize);
  mpFontSizeSpinBox = new DoubleSpinBox;
  mpFontSizeSpinBox->setRange(6, std::numeric_limits<double>::max());
  mpFontSizeSpinBox->setValue(textBrowser.font().pointSize());
  mpFontSizeSpinBox->setSingleStep(1);
  // Notification Color
  mpNotificationColorLabel = new Label(tr("Notification Color:"));
  mpNotificationColorButton = new QPushButton(Helper::pickColor);
  mpNotificationColorButton->setAutoDefault(false);
  connect(mpNotificationColorButton, SIGNAL(clicked()), SLOT(pickNotificationColor()));
  setNotificationColor(OptionsDefaults::Messages::notificationColor);
  setNotificationPickColorButtonIcon();
  // Warning Color
  mpWarningColorLabel = new Label(tr("Warning Color:"));
  mpWarningColorButton = new QPushButton(Helper::pickColor);
  mpWarningColorButton->setAutoDefault(false);
  connect(mpWarningColorButton, SIGNAL(clicked()), SLOT(pickWarningColor()));
  setWarningColor(OptionsDefaults::Messages::warningColor);
  setWarningPickColorButtonIcon();
  // Error Color
  mpErrorColorLabel = new Label(tr("Error Color:"));
  mpErrorColorButton = new QPushButton(Helper::pickColor);
  mpErrorColorButton->setAutoDefault(false);
  connect(mpErrorColorButton, SIGNAL(clicked()), SLOT(pickErrorColor()));
  setErrorColor(OptionsDefaults::Messages::errorColor);
  setErrorPickColorButtonIcon();
  // set the layout of FontColors group
  QGridLayout *pFontColorsLayout = new QGridLayout;
  pFontColorsLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pFontColorsLayout->setColumnStretch(1, 1);
  pFontColorsLayout->addWidget(mpFontFamilyLabel, 0, 0);
  pFontColorsLayout->addWidget(mpFontFamilyComboBox, 0, 1);
  pFontColorsLayout->addWidget(mpFontSizeLabel, 1, 0);
  pFontColorsLayout->addWidget(mpFontSizeSpinBox, 1, 1);
  pFontColorsLayout->addWidget(mpNotificationColorLabel, 2, 0);
  pFontColorsLayout->addWidget(mpNotificationColorButton, 2, 1);
  pFontColorsLayout->addWidget(mpWarningColorLabel, 3, 0);
  pFontColorsLayout->addWidget(mpWarningColorButton, 3, 1);
  pFontColorsLayout->addWidget(mpErrorColorLabel, 4, 0);
  pFontColorsLayout->addWidget(mpErrorColorButton, 4, 1);
  mpFontColorsGroupBox->setLayout(pFontColorsLayout);
  // set the layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setAlignment(Qt::AlignTop);
  pMainLayout->addWidget(mpGeneralGroupBox);
  pMainLayout->addWidget(mpFontColorsGroupBox);
  setLayout(pMainLayout);
}

void MessagesPage::setNotificationPickColorButtonIcon()
{
  QPixmap pixmap(Helper::iconSize);
  pixmap.fill(getNotificationColor());
  mpNotificationColorButton->setIcon(pixmap);
}

void MessagesPage::setWarningPickColorButtonIcon()
{
  QPixmap pixmap(Helper::iconSize);
  pixmap.fill(getWarningColor());
  mpWarningColorButton->setIcon(pixmap);
}

void MessagesPage::setErrorPickColorButtonIcon()
{
  QPixmap pixmap(Helper::iconSize);
  pixmap.fill(getErrorColor());
  mpErrorColorButton->setIcon(pixmap);
}

/*!
 * \brief MessagesPage::getColor
 * Returns the color based on the error type.
 * \param type
 * \return
 */
QColor MessagesPage::getColor(const StringHandler::SimulationMessageType type) const
{
  switch (type) {
    case StringHandler::OMEditInfo:
      return Qt::blue;
    case StringHandler::SMWarning:
      return getWarningColor();
    case StringHandler::Error:
    case StringHandler::Assert:
      return getErrorColor();
    case StringHandler::Debug:
    case StringHandler::Info:
    case StringHandler::Unknown:
    default:
      return getNotificationColor();
  }
}

void MessagesPage::pickNotificationColor()
{
  QColor color = QColorDialog::getColor(getNotificationColor());
  // if user press ESC
  if (!color.isValid()) {
    return;
  }
  setNotificationColor(color);
  setNotificationPickColorButtonIcon();
}

void MessagesPage::pickWarningColor()
{
  QColor color = QColorDialog::getColor(getWarningColor());
  // if user press ESC
  if (!color.isValid()) {
    return;
  }
  setWarningColor(color);
  setWarningPickColorButtonIcon();
}

void MessagesPage::pickErrorColor()
{
  QColor color = QColorDialog::getColor(getErrorColor());
  // if user press ESC
  if (!color.isValid()) {
    return;
  }
  setErrorColor(color);
  setErrorPickColorButtonIcon();
}

/*!
 * \class NotificationsPage
 * \brief Creates an interface for Notifications settings.
 */
/*!
 * \brief NotificationsPage::NotificationsPage
 * \param pOptionsDialog is the pointer to OptionsDialog
 */
NotificationsPage::NotificationsPage(OptionsDialog *pOptionsDialog)
  : QWidget(pOptionsDialog)
{
  mpOptionsDialog = pOptionsDialog;
  // create the notifications groupbox
  mpNotificationsGroupBox = new QGroupBox(tr("Notifications"));
  // create the exit application checkbox
  mpQuitApplicationCheckBox = new QCheckBox(tr("Always quit without prompt"));
  // create the item drop on itself checkbox
  mpItemDroppedOnItselfCheckBox = new QCheckBox(tr("Show item dropped on itself message"));
  mpItemDroppedOnItselfCheckBox->setChecked(OptionsDefaults::Notification::itemDroppedOnItself);
  // create the replaceable if partial checkbox
  mpReplaceableIfPartialCheckBox = new QCheckBox(tr("Show model is partial and component is added as replaceable message"));
  mpReplaceableIfPartialCheckBox->setChecked(OptionsDefaults::Notification::replaceableIfPartial);
  // create the inner model name changed checkbox
  mpInnerModelNameChangedCheckBox = new QCheckBox(tr("Show component is declared as inner message"));
  mpInnerModelNameChangedCheckBox->setChecked(OptionsDefaults::Notification::innerModelNameChanged);
  // create the save model for bitmap insertion checkbox
  mpSaveModelForBitmapInsertionCheckBox = new QCheckBox(tr("Show save model for bitmap insertion message"));
  mpSaveModelForBitmapInsertionCheckBox->setChecked(OptionsDefaults::Notification::saveModelForBitmapInsertion);
  // create the save model for bitmap insertion checkbox
  mpAlwaysAskForDraggedComponentName = new QCheckBox(tr("Always ask for the dragged/duplicated component name"));
  mpAlwaysAskForDraggedComponentName->setChecked(OptionsDefaults::Notification::alwaysAskForDraggedComponentName);
  // create the always ask for text editor error
  mpAlwaysAskForTextEditorErrorCheckBox = new QCheckBox(tr("Always ask for what to do with the text editor error"));
  mpAlwaysAskForTextEditorErrorCheckBox->setChecked(OptionsDefaults::Notification::alwaysAskForTextEditorError);
  // set the layout of notifications group
  QGridLayout *pNotificationsLayout = new QGridLayout;
  pNotificationsLayout->setAlignment(Qt::AlignTop);
  pNotificationsLayout->addWidget(mpQuitApplicationCheckBox, 0, 0, 1, 2);
  pNotificationsLayout->addWidget(mpItemDroppedOnItselfCheckBox, 1, 0, 1, 2);
  pNotificationsLayout->addWidget(mpReplaceableIfPartialCheckBox, 2, 0, 1, 2);
  pNotificationsLayout->addWidget(mpInnerModelNameChangedCheckBox, 3, 0, 1, 2);
  pNotificationsLayout->addWidget(mpSaveModelForBitmapInsertionCheckBox, 4, 0, 1, 2);
  pNotificationsLayout->addWidget(mpAlwaysAskForDraggedComponentName, 5, 0, 1, 2);
  pNotificationsLayout->addWidget(mpAlwaysAskForTextEditorErrorCheckBox, 6, 0, 1, 2);
  mpNotificationsGroupBox->setLayout(pNotificationsLayout);
  // set the layout
  QVBoxLayout *pLayout = new QVBoxLayout;
  pLayout->setAlignment(Qt::AlignTop);
  pLayout->addWidget(mpNotificationsGroupBox);
  setLayout(pLayout);
}

//! @class LineStylePage
//! @brief Creates an interface for line style settings.

//! Constructor
//! @param pOptionsDialog is the pointer to OptionsDialog
LineStylePage::LineStylePage(OptionsDialog *pOptionsDialog)
  : QWidget(pOptionsDialog)
{
  mpOptionsDialog = pOptionsDialog;
  mpLineStyleGroupBox = new QGroupBox(Helper::lineStyle);
  // Line Color
  mpLineColorLabel = new Label(Helper::color);
  mpLinePickColorButton = new QPushButton(Helper::pickColor);
  mpLinePickColorButton->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Preferred);
  mpLinePickColorButton->setAutoDefault(false);
  connect(mpLinePickColorButton, SIGNAL(clicked()), SLOT(linePickColor()));
  setLineColor(OptionsDefaults::LineStyle::color);
  setLinePickColorButtonIcon();
  // Line Pattern
  mpLinePatternLabel = new Label(Helper::pattern);
  mpLinePatternComboBox = StringHandler::getLinePatternComboBox();
  setLinePattern(OptionsDefaults::LineStyle::pattern);
  // Line Thickness
  mpLineThicknessLabel = new Label(Helper::thickness);
  mpLineThicknessSpinBox = new DoubleSpinBox;
  mpLineThicknessSpinBox->setRange(0, std::numeric_limits<double>::max());
  mpLineThicknessSpinBox->setValue(OptionsDefaults::LineStyle::thickness);
  mpLineThicknessSpinBox->setSingleStep(0.25);
  // Line Arrow
  mpLineStartArrowLabel = new Label(Helper::startArrow);
  mpLineStartArrowComboBox = StringHandler::getStartArrowComboBox();
  mpLineEndArrowLabel = new Label(Helper::endArrow);
  mpLineEndArrowComboBox = StringHandler::getEndArrowComboBox();
  mpLineArrowSizeLabel = new Label(Helper::arrowSize);
  mpLineArrowSizeSpinBox = new DoubleSpinBox;
  mpLineArrowSizeSpinBox->setRange(0, std::numeric_limits<double>::max());
  mpLineArrowSizeSpinBox->setValue(OptionsDefaults::LineStyle::arrowSize);
  mpLineArrowSizeSpinBox->setSingleStep(1);
  // Line smooth
  mpLineSmoothLabel = new Label(Helper::smooth);
  mpLineSmoothCheckBox = new QCheckBox(Helper::bezier);
  // set the layout
  QGridLayout *pLineStyleLayout = new QGridLayout;
  pLineStyleLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pLineStyleLayout->addWidget(mpLineColorLabel, 0, 0);
  pLineStyleLayout->addWidget(mpLinePickColorButton, 0, 1);
  pLineStyleLayout->addWidget(mpLinePatternLabel, 2, 0);
  pLineStyleLayout->addWidget(mpLinePatternComboBox, 2, 1);
  pLineStyleLayout->addWidget(mpLineThicknessLabel, 3, 0);
  pLineStyleLayout->addWidget(mpLineThicknessSpinBox, 3, 1);
  pLineStyleLayout->addWidget(mpLineStartArrowLabel, 4, 0);
  pLineStyleLayout->addWidget(mpLineStartArrowComboBox, 4, 1);
  pLineStyleLayout->addWidget(mpLineEndArrowLabel, 5, 0);
  pLineStyleLayout->addWidget(mpLineEndArrowComboBox, 5, 1);
  pLineStyleLayout->addWidget(mpLineArrowSizeLabel, 6, 0);
  pLineStyleLayout->addWidget(mpLineArrowSizeSpinBox, 6, 1);
  pLineStyleLayout->addWidget(mpLineSmoothLabel, 7, 0);
  pLineStyleLayout->addWidget(mpLineSmoothCheckBox, 7, 1);
  mpLineStyleGroupBox->setLayout(pLineStyleLayout);
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setAlignment(Qt::AlignTop);
  pMainLayout->addWidget(mpLineStyleGroupBox);
  setLayout(pMainLayout);
}

//! Sets the pen color
//! @param color to set.
void LineStylePage::setLineColor(QColor color)
{
  mLineColor = color;
}

//! Returns the pen color
QColor LineStylePage::getLineColor()
{
  return mLineColor;
}

void LineStylePage::setLinePickColorButtonIcon()
{
  QPixmap pixmap(Helper::iconSize);
  pixmap.fill(getLineColor());
  mpLinePickColorButton->setIcon(pixmap);
}

//! Sets the pen pattern
//! @param pattern to set.
void LineStylePage::setLinePattern(QString pattern)
{
  int index = mpLinePatternComboBox->findText(pattern, Qt::MatchExactly);
  if (index != -1)
    mpLinePatternComboBox->setCurrentIndex(index);
}

QString LineStylePage::getLinePattern()
{
  return mpLinePatternComboBox->currentText();
}

//! Sets the pen thickness
//! @param thickness to set.
void LineStylePage::setLineThickness(qreal thickness)
{
  if (thickness <= 0)
    thickness = 0.25;
  mpLineThicknessSpinBox->setValue(thickness);
}

//! Returns the pen thickness
qreal LineStylePage::getLineThickness()
{
  return mpLineThicknessSpinBox->value();
}

void LineStylePage::setLineStartArrow(QString startArrow)
{
  int index = mpLineStartArrowComboBox->findText(startArrow, Qt::MatchExactly);
  if (index != -1)
    mpLineStartArrowComboBox->setCurrentIndex(index);
}

QString LineStylePage::getLineStartArrow()
{
  return mpLineStartArrowComboBox->currentText();
}

void LineStylePage::setLineEndArrow(QString endArrow)
{
  int index = mpLineEndArrowComboBox->findText(endArrow, Qt::MatchExactly);
  if (index != -1)
    mpLineEndArrowComboBox->setCurrentIndex(index);
}

QString LineStylePage::getLineEndArrow()
{
  return mpLineEndArrowComboBox->currentText();
}

void LineStylePage::setLineArrowSize(qreal size)
{
  if (size <= 0)
    size = 3;
  mpLineArrowSizeSpinBox->setValue(size);
}

qreal LineStylePage::getLineArrowSize()
{
  return mpLineArrowSizeSpinBox->value();
}

//! Sets whether the pen used will be smooth (for splines) or not.
//! @param smooth
void LineStylePage::setLineSmooth(bool smooth)
{
  mpLineSmoothCheckBox->setChecked(smooth);
}

//! Returns the pen smooth
bool LineStylePage::getLineSmooth()
{
  return mpLineSmoothCheckBox->isChecked();
}

//! Opens the color picker dialog. The user selects the color and the color saved as a pen color.
void LineStylePage::linePickColor()
{
  QColor color = QColorDialog::getColor(getLineColor());
  // if user press ESC
  if (!color.isValid())
    return;
  setLineColor(color);
  setLinePickColorButtonIcon();
}

//! @class FillStylePage
//! @brief Creates an interface for fill style settings.

//! Constructor
//! @param pOptionsDialog is the pointer to OptionsDialog
FillStylePage::FillStylePage(OptionsDialog *pOptionsDialog)
  : QWidget(pOptionsDialog)
{
  mpOptionsDialog = pOptionsDialog;
  mpFillStyleGroupBox = new QGroupBox(Helper::fillStyle);
  // Fill Color
  mpFillColorLabel = new Label(Helper::color);
  mpFillPickColorButton = new QPushButton(Helper::pickColor);
  mpFillPickColorButton->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Preferred);
  mpFillPickColorButton->setAutoDefault(false);
  connect(mpFillPickColorButton, SIGNAL(clicked()), SLOT(fillPickColor()));
  setFillColor(OptionsDefaults::FillStyle::color);
  setFillPickColorButtonIcon();
  // Fill Pattern
  mpFillPatternLabel = new Label(Helper::pattern);
  mpFillPatternComboBox = StringHandler::getFillPatternComboBox();
  setFillPattern(OptionsDefaults::FillStyle::pattern);
  // set the layout
  QGridLayout *pFillStyleLayout = new QGridLayout;
  pFillStyleLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pFillStyleLayout->addWidget(mpFillColorLabel, 0, 0);
  pFillStyleLayout->addWidget(mpFillPickColorButton, 0, 1);
  pFillStyleLayout->addWidget(mpFillPatternLabel, 1, 0);
  pFillStyleLayout->addWidget(mpFillPatternComboBox, 1, 1);
  mpFillStyleGroupBox->setLayout(pFillStyleLayout);
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setAlignment(Qt::AlignTop);
  pMainLayout->addWidget(mpFillStyleGroupBox);
  setLayout(pMainLayout);
}

void FillStylePage::setFillColor(QColor color)
{
  mFillColor = color;
}

QColor FillStylePage::getFillColor()
{
  return mFillColor;
}

void FillStylePage::setFillPickColorButtonIcon()
{
  QPixmap pixmap(Helper::iconSize);
  pixmap.fill(getFillColor());
  mpFillPickColorButton->setIcon(pixmap);
}

void FillStylePage::setFillPattern(QString pattern)
{
  int index = mpFillPatternComboBox->findText(pattern, Qt::MatchExactly);
  if (index != -1)
    mpFillPatternComboBox->setCurrentIndex(index);
}

QString FillStylePage::getFillPattern()
{
  return mpFillPatternComboBox->currentText();
}

void FillStylePage::fillPickColor()
{
  QColor color = QColorDialog::getColor(getFillColor());
  // if user press ESC
  if (!color.isValid())
    return;
  setFillColor(color);
  setFillPickColorButtonIcon();
}

//! @class PlottingPage
//! @brief Creates an interface for curve style settings.

//! Constructor
//! @param pOptionsDialog is the pointer to OptionsDialog
PlottingPage::PlottingPage(OptionsDialog *pOptionsDialog)
  : QWidget(pOptionsDialog)
{
  mpOptionsDialog = pOptionsDialog;
  // general groupbox
  mpGeneralGroupBox = new QGroupBox(Helper::general);
  // auto scale
  mpAutoScaleCheckBox = new QCheckBox(tr("Auto Scale"));
  mpAutoScaleCheckBox->setChecked(OptionsDefaults::Plotting::autoScale);
  mpAutoScaleCheckBox->setToolTip(tr("Auto scale the plot to fit in view when variable is plotted."));
  // prefix units
  mpPrefixUnitsCheckbox = new QCheckBox(tr("Prefix Units"));
  mpPrefixUnitsCheckbox->setChecked(OptionsDefaults::Plotting::prefixUnits);
  mpPrefixUnitsCheckbox->setToolTip(tr("Automatically pick the right prefix for units."));
  // set general groupbox layout
  QGridLayout *pGeneralGroupBoxLayout = new QGridLayout;
  pGeneralGroupBoxLayout->addWidget(mpAutoScaleCheckBox, 0, 0);
  pGeneralGroupBoxLayout->addWidget(mpPrefixUnitsCheckbox, 1, 0);
  mpGeneralGroupBox->setLayout(pGeneralGroupBoxLayout);
  // Plotting View Mode
  mpPlottingViewModeGroupBox = new QGroupBox(tr("Default Plotting View Mode"));
  mpPlottingTabbedViewRadioButton = new QRadioButton(tr("Tabbed View"));
  mpPlottingTabbedViewRadioButton->setChecked(true);
  mpPlottingSubWindowViewRadioButton = new QRadioButton(tr("SubWindow View"));
  QButtonGroup *pPlottingViewModeButtonGroup = new QButtonGroup(this);
  pPlottingViewModeButtonGroup->addButton(mpPlottingTabbedViewRadioButton);
  pPlottingViewModeButtonGroup->addButton(mpPlottingSubWindowViewRadioButton);
  // plotting view radio buttons layout
  QHBoxLayout *pPlottingRadioButtonsLayout = new QHBoxLayout;
  pPlottingRadioButtonsLayout->addWidget(mpPlottingTabbedViewRadioButton);
  pPlottingRadioButtonsLayout->addWidget(mpPlottingSubWindowViewRadioButton);
  // set the layout of plotting view mode group
  QGridLayout *pPlottingViewModeLayout = new QGridLayout;
  pPlottingViewModeLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pPlottingViewModeLayout->addLayout(pPlottingRadioButtonsLayout, 0, 0);
  mpPlottingViewModeGroupBox->setLayout(pPlottingViewModeLayout);
  mpCurveStyleGroupBox = new QGroupBox(Helper::curveStyle);
  // Curve Pattern
  mpCurvePatternLabel = new Label(Helper::pattern);
  mpCurvePatternComboBox = new ComboBox;
  mpCurvePatternComboBox->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Preferred);
  mpCurvePatternComboBox->addItem("SolidLine", 1);
  mpCurvePatternComboBox->addItem("DashLine", 2);
  mpCurvePatternComboBox->addItem("DotLine", 3);
  mpCurvePatternComboBox->addItem("DashDotLine", 4);
  mpCurvePatternComboBox->addItem("DashDotDotLine", 5);
  mpCurvePatternComboBox->addItem("Sticks", 6);
  mpCurvePatternComboBox->addItem("Steps", 7);
  // Curve Thickness
  mpCurveThicknessLabel = new Label(Helper::thickness);
  mpCurveThicknessSpinBox = new DoubleSpinBox;
  mpCurveThicknessSpinBox->setRange(0, std::numeric_limits<double>::max());
  mpCurveThicknessSpinBox->setValue(OptionsDefaults::Plotting::curveThickness);
  mpCurveThicknessSpinBox->setSingleStep(1);
  // set the layout
  QGridLayout *pCurveStyleLayout = new QGridLayout;
  pCurveStyleLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pCurveStyleLayout->addWidget(new Label(tr("Curve styles are used for new curves. Use plot setup window to update the existing curves.")), 0, 0, 1, 2);
  pCurveStyleLayout->addWidget(mpCurvePatternLabel, 1, 0);
  pCurveStyleLayout->addWidget(mpCurvePatternComboBox, 1, 1);
  pCurveStyleLayout->addWidget(mpCurveThicknessLabel, 2, 0);
  pCurveStyleLayout->addWidget(mpCurveThicknessSpinBox, 2, 1);
  mpCurveStyleGroupBox->setLayout(pCurveStyleLayout);
  // variable filter interval
  mpVariableFilterGroupBox = new QGroupBox(tr("Variable Filter"));
  mpFilterIntervalHelpLabel = new Label(tr("Adds a delay, specified as Filter Interval, in filtering the variables.\n"
                                           "Set the value to 0 if you don't want any delay."));
  mpFilterIntervalLabel = new Label(tr("Filter Interval:"));
  mpFilterIntervalSpinBox = new SpinBox;
  mpFilterIntervalSpinBox->setSuffix(tr(" seconds"));
  mpFilterIntervalSpinBox->setRange(0, std::numeric_limits<int>::max());
  mpFilterIntervalSpinBox->setValue(OptionsDefaults::Plotting::variableFilterInterval);
  mpFilterIntervalSpinBox->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Preferred);
  // variable filter layout
  QGridLayout *pVariableFilterGridLayout = new QGridLayout;
  pVariableFilterGridLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pVariableFilterGridLayout->addWidget(mpFilterIntervalHelpLabel, 0, 0, 1, 2);
  pVariableFilterGridLayout->addWidget(mpFilterIntervalLabel, 1, 0);
  pVariableFilterGridLayout->addWidget(mpFilterIntervalSpinBox, 1, 1);
  mpVariableFilterGroupBox->setLayout(pVariableFilterGridLayout);
  // font size
  mpFontSizeGroupBox = new QGroupBox(tr("Font Size"));
  mpTitleFontSizeLabel = new Label(tr("Title:"));
  mpTitleFontSizeSpinBox = new DoubleSpinBox;
  mpTitleFontSizeSpinBox->setRange(6, std::numeric_limits<double>::max());
  mpTitleFontSizeSpinBox->setValue(OptionsDefaults::Plotting::titleFontSize);
  mpTitleFontSizeSpinBox->setSingleStep(1);
  mpTitleFontSizeSpinBox->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Preferred);
  mpVerticalAxisTitleFontSizeLabel = new Label(tr("Vertical Axis Title:"));
  mpVerticalAxisTitleFontSizeSpinBox = new DoubleSpinBox;
  mpVerticalAxisTitleFontSizeSpinBox->setRange(6, std::numeric_limits<double>::max());
  mpVerticalAxisTitleFontSizeSpinBox->setValue(OptionsDefaults::Plotting::verticalAxisTitleFontSize);
  mpVerticalAxisTitleFontSizeSpinBox->setSingleStep(1);
  mpVerticalAxisNumbersFontSizeLabel = new Label(tr("Vertical Axis Numbers:"));
  mpVerticalAxisNumbersFontSizeSpinBox = new DoubleSpinBox;
  mpVerticalAxisNumbersFontSizeSpinBox->setRange(6, std::numeric_limits<double>::max());
  mpVerticalAxisNumbersFontSizeSpinBox->setValue(OptionsDefaults::Plotting::verticalAxisNumbersFontSize);
  mpVerticalAxisNumbersFontSizeSpinBox->setSingleStep(1);
  mpHorizontalAxisTitleFontSizeLabel = new Label(tr("Horizontal Axis Title:"));
  mpHorizontalAxisTitleFontSizeSpinBox = new DoubleSpinBox;
  mpHorizontalAxisTitleFontSizeSpinBox->setRange(6, std::numeric_limits<double>::max());
  mpHorizontalAxisTitleFontSizeSpinBox->setValue(OptionsDefaults::Plotting::horizontalAxisTitleFontSize);
  mpHorizontalAxisTitleFontSizeSpinBox->setSingleStep(1);
  mpHorizontalAxisNumbersFontSizeLabel = new Label(tr("Horizontal Axis Numbers:"));
  mpHorizontalAxisNumbersFontSizeSpinBox = new DoubleSpinBox;
  mpHorizontalAxisNumbersFontSizeSpinBox->setRange(6, std::numeric_limits<double>::max());
  mpHorizontalAxisNumbersFontSizeSpinBox->setValue(OptionsDefaults::Plotting::horizontalAxisNumbersFontSize);
  mpHorizontalAxisNumbersFontSizeSpinBox->setSingleStep(1);
  mpFooterFontSizeLabel = new Label(tr("Footer:"));
  mpFooterFontSizeSpinBox = new DoubleSpinBox;
  mpFooterFontSizeSpinBox->setRange(6, std::numeric_limits<double>::max());
  mpFooterFontSizeSpinBox->setValue(QApplication::font().pointSize());
  mpFooterFontSizeSpinBox->setSingleStep(1);
  mpLegendFontSizeLabel = new Label(tr("Legend:"));
  mpLegendFontSizeSpinBox = new DoubleSpinBox;
  mpLegendFontSizeSpinBox->setRange(6, std::numeric_limits<double>::max());
  mpLegendFontSizeSpinBox->setValue(QApplication::font().pointSize());
  mpLegendFontSizeSpinBox->setSingleStep(1);
  // font size layout
  QGridLayout *pFontSizeGridLayout = new QGridLayout;
  pFontSizeGridLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pFontSizeGridLayout->addWidget(new Label(tr("Font sizes are used for new plot windows. Use plot setup window to update the existing plots.")), 0, 0, 1, 2);
  pFontSizeGridLayout->addWidget(mpTitleFontSizeLabel, 1, 0);
  pFontSizeGridLayout->addWidget(mpTitleFontSizeSpinBox, 1, 1);
  pFontSizeGridLayout->addWidget(mpVerticalAxisTitleFontSizeLabel, 2, 0);
  pFontSizeGridLayout->addWidget(mpVerticalAxisTitleFontSizeSpinBox, 2, 1);
  pFontSizeGridLayout->addWidget(mpVerticalAxisNumbersFontSizeLabel, 3, 0);
  pFontSizeGridLayout->addWidget(mpVerticalAxisNumbersFontSizeSpinBox, 3, 1);
  pFontSizeGridLayout->addWidget(mpHorizontalAxisTitleFontSizeLabel, 4, 0);
  pFontSizeGridLayout->addWidget(mpHorizontalAxisTitleFontSizeSpinBox, 4, 1);
  pFontSizeGridLayout->addWidget(mpHorizontalAxisNumbersFontSizeLabel, 5, 0);
  pFontSizeGridLayout->addWidget(mpHorizontalAxisNumbersFontSizeSpinBox, 5, 1);
  int index = 6;
#if QWT_VERSION > 0x060000
  pFontSizeGridLayout->addWidget(mpFooterFontSizeLabel, index, 0);
  pFontSizeGridLayout->addWidget(mpFooterFontSizeSpinBox, index++, 1);
#endif
  pFontSizeGridLayout->addWidget(mpLegendFontSizeLabel, index, 0);
  pFontSizeGridLayout->addWidget(mpLegendFontSizeSpinBox, index, 1);
  mpFontSizeGroupBox->setLayout(pFontSizeGridLayout);
  // main layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setAlignment(Qt::AlignTop);
  pMainLayout->addWidget(mpGeneralGroupBox);
  pMainLayout->addWidget(mpPlottingViewModeGroupBox);
  pMainLayout->addWidget(mpCurveStyleGroupBox);
  pMainLayout->addWidget(mpVariableFilterGroupBox);
  pMainLayout->addWidget(mpFontSizeGroupBox);
  setLayout(pMainLayout);
}


/*!
 * \brief PlottingPage::setPlottingViewMode
 * Sets the plotting view mode.
 * \param value
 */
void PlottingPage::setPlottingViewMode(QString value)
{
  if (value.compare(Helper::subWindow) == 0) {
    mpPlottingSubWindowViewRadioButton->setChecked(true);
  } else {
    mpPlottingTabbedViewRadioButton->setChecked(true);
  }
}

/*!
 * \brief PlottingPage::getPlottingViewMode
 * Gets the plotting view mode.
 * \return
 */
QString PlottingPage::getPlottingViewMode()
{
  if (mpPlottingSubWindowViewRadioButton->isChecked()) {
    return Helper::subWindow;
  } else {
    return Helper::tabbed;
  }
}

//! Sets the pen pattern
//! @param pattern to set.
void PlottingPage::setCurvePattern(int pattern)
{
  int index = mpCurvePatternComboBox->findData(pattern);
  if (index != -1)
    mpCurvePatternComboBox->setCurrentIndex(index);
}

int PlottingPage::getCurvePattern()
{
  return mpCurvePatternComboBox->itemData(mpCurvePatternComboBox->currentIndex()).toInt();
}

//! Sets the pen thickness
//! @param thickness to set.
void PlottingPage::setCurveThickness(qreal thickness)
{
  if (thickness <= 0)
    thickness = 1.0;
  mpCurveThicknessSpinBox->setValue(thickness);
}

//! Returns the pen thickness
qreal PlottingPage::getCurveThickness()
{
  return mpCurveThicknessSpinBox->value();
}

//! @class FigaroPage
//! @brief Creates an interface for Figaro settings.

//! Constructor
//! @param pOptionsDialog is the pointer to OptionsDialog
FigaroPage::FigaroPage(OptionsDialog *pOptionsDialog)
  : QWidget(pOptionsDialog)
{
  mpOptionsDialog = pOptionsDialog;
  mpFigaroGroupBox = new QGroupBox(Helper::figaro);
  // Figaro database file
  mpFigaroDatabaseFileLabel = new Label(tr("Figaro Library:"));
  mpFigaroDatabaseFileTextBox = new QLineEdit;
  mpBrowseFigaroDatabaseFileButton = new QPushButton(Helper::browse);
  mpBrowseFigaroDatabaseFileButton->setAutoDefault(false);
  connect(mpBrowseFigaroDatabaseFileButton, SIGNAL(clicked()), SLOT(browseFigaroLibraryFile()));
  // Figaro options file
  mpFigaroOptionsFileLabel = new Label(tr("Tree generation options:"));
  mpFigaroOptionsFileTextBox = new QLineEdit;
  mpBrowseFigaroOptionsFileButton = new QPushButton(Helper::browse);
  mpBrowseFigaroOptionsFileButton->setAutoDefault(false);
  connect(mpBrowseFigaroOptionsFileButton, SIGNAL(clicked()), SLOT(browseFigaroOptionsFile()));
  // figaro process
  mpFigaroProcessLabel = new Label(tr("Figaro Processor:"));
  OptionsDefaults::Figaro::process = QString(Helper::OpenModelicaHome).append("/share/jEdit4.5_VisualFigaro/VisualFigaro/figp.exe");
  mpFigaroProcessTextBox = new QLineEdit(OptionsDefaults::Figaro::process);
  mpBrowseFigaroProcessButton = new QPushButton(Helper::browse);
  mpBrowseFigaroProcessButton->setAutoDefault(false);
  connect(mpBrowseFigaroProcessButton, SIGNAL(clicked()), SLOT(browseFigaroProcessFile()));
  mpResetFigaroProcessButton = new QPushButton(Helper::reset);
  mpResetFigaroProcessButton->setToolTip(tr("Resets to default Figaro Processor path"));
  mpResetFigaroProcessButton->setAutoDefault(false);
  connect(mpResetFigaroProcessButton, SIGNAL(clicked()), SLOT(resetFigaroProcessPath()));
  // set the layout
  QGridLayout *pFigaroLayout = new QGridLayout;
  pFigaroLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pFigaroLayout->addWidget(mpFigaroDatabaseFileLabel, 0, 0);
  pFigaroLayout->addWidget(mpFigaroDatabaseFileTextBox, 0, 1, 1, 2);
  pFigaroLayout->addWidget(mpBrowseFigaroDatabaseFileButton, 0, 3);
  pFigaroLayout->addWidget(mpFigaroOptionsFileLabel, 1, 0);
  pFigaroLayout->addWidget(mpFigaroOptionsFileTextBox, 1, 1, 1, 2);
  pFigaroLayout->addWidget(mpBrowseFigaroOptionsFileButton, 1, 3);
  pFigaroLayout->addWidget(mpFigaroProcessLabel, 2, 0);
  pFigaroLayout->addWidget(mpFigaroProcessTextBox, 2, 1);
  pFigaroLayout->addWidget(mpBrowseFigaroProcessButton, 2, 2);
  pFigaroLayout->addWidget(mpResetFigaroProcessButton, 2, 3);
  mpFigaroGroupBox->setLayout(pFigaroLayout);
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setAlignment(Qt::AlignTop);
  pMainLayout->addWidget(mpFigaroGroupBox);
  setLayout(pMainLayout);
}

void FigaroPage::browseFigaroLibraryFile()
{
  mpFigaroDatabaseFileTextBox->setText(StringHandler::getOpenFileName(this, QString("%1 - %2").arg(Helper::applicationName, Helper::chooseFile), NULL, Helper::figaroFileTypes));
}

void FigaroPage::browseFigaroOptionsFile()
{
  mpFigaroOptionsFileTextBox->setText(StringHandler::getOpenFileName(this, QString("%1 - %2").arg(Helper::applicationName, Helper::chooseFile), NULL, Helper::xmlFileTypes));
}

void FigaroPage::browseFigaroProcessFile()
{
  mpFigaroProcessTextBox->setText(StringHandler::getOpenFileName(this, QString("%1 - %2").arg(Helper::applicationName, Helper::chooseFile)));
}

/*!
 * \brief FigaroPage::resetFigaroProcessPath
 * Resets the figaro process path to default.
 */
void FigaroPage::resetFigaroProcessPath()
{
  mpFigaroProcessTextBox->setText(OptionsDefaults::Figaro::process);
}

/*!
  \class DebuggerPage
  \brief Creates an interface for debugger settings.
  */
/*!
  \param pParent - pointer to OptionsDialog
  */
DebuggerPage::DebuggerPage(OptionsDialog *pOptionsDialog)
  : QWidget(pOptionsDialog)
{
  mpOptionsDialog = pOptionsDialog;
  mpAlgorithmicDebuggerGroupBox = new QGroupBox(Helper::algorithmicDebugger);
  // GDB Path
  mpGDBPathLabel = new Label(tr("GDB Path:"));
  mpGDBPathTextBox = new QLineEdit;
  mpGDBPathTextBox->setPlaceholderText(Utilities::getGDBPath());
  mpGDBPathBrowseButton = new QPushButton(Helper::browse);
  mpGDBPathBrowseButton->setAutoDefault(false);
  connect(mpGDBPathBrowseButton, SIGNAL(clicked()), SLOT(browseGDBPath()));
  /* GDB Command Timeout */
  mpGDBCommandTimeoutLabel = new Label(tr("GDB Command Timeout:"));
  mpGDBCommandTimeoutSpinBox = new SpinBox;
  mpGDBCommandTimeoutSpinBox->setSuffix(tr(" seconds"));
  mpGDBCommandTimeoutSpinBox->setRange(30, std::numeric_limits<int>::max());
  mpGDBCommandTimeoutSpinBox->setSingleStep(10);
  mpGDBCommandTimeoutSpinBox->setValue(OptionsDefaults::Debugger::GDBCommandTimeout);
  /* GDB Output limit */
  mpGDBOutputLimitLabel = new Label(tr("GDB Output Limit:"));
  mpGDBOutputLimitSpinBox = new SpinBox;
  mpGDBOutputLimitSpinBox->setSuffix(tr(" characters"));
  mpGDBOutputLimitSpinBox->setSpecialValueText(Helper::unlimited);
  mpGDBOutputLimitSpinBox->setRange(0, std::numeric_limits<int>::max());
  mpGDBOutputLimitSpinBox->setSingleStep(10);
  // Display C Frames
  mpDisplayCFramesCheckBox = new QCheckBox(tr("Display C frames"));
  mpDisplayCFramesCheckBox->setChecked(OptionsDefaults::Debugger::displayCFrames);
  // Display Unknown Frames
  mpDisplayUnknownFramesCheckBox = new QCheckBox(tr("Display unknown frames"));
  mpDisplayUnknownFramesCheckBox->setChecked(OptionsDefaults::Debugger::displayUnknownFrames);
  // clear output on new run
  mpClearOutputOnNewRunCheckBox = new QCheckBox(tr("Clear old output on a new run"));
  mpClearOutputOnNewRunCheckBox->setChecked(OptionsDefaults::Debugger::clearOutputOnNewRun);
  // clear log on new run
  mpClearLogOnNewRunCheckBox = new QCheckBox(tr("Clear old log on a new run"));
  mpClearLogOnNewRunCheckBox->setChecked(OptionsDefaults::Debugger::clearLogOnNewRun);
  /* set the debugger group box layout */
  QGridLayout *pDebuggerLayout = new QGridLayout;
  pDebuggerLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pDebuggerLayout->addWidget(mpGDBPathLabel, 0, 0);
  pDebuggerLayout->addWidget(mpGDBPathTextBox, 0, 1);
  pDebuggerLayout->addWidget(mpGDBPathBrowseButton, 0, 2);
  pDebuggerLayout->addItem(new QSpacerItem(1, 1), 1, 0);
  pDebuggerLayout->addWidget(new Label(tr("Default GDB path is used if above field is empty.")), 1, 1, 1, 2);
  pDebuggerLayout->addWidget(mpGDBCommandTimeoutLabel, 2, 0);
  pDebuggerLayout->addWidget(mpGDBCommandTimeoutSpinBox, 2, 1, 1, 2);
  pDebuggerLayout->addWidget(mpGDBOutputLimitLabel, 3, 0);
  pDebuggerLayout->addWidget(mpGDBOutputLimitSpinBox, 3, 1, 1, 2);
  pDebuggerLayout->addWidget(mpDisplayCFramesCheckBox, 4, 0, 1, 2);
  pDebuggerLayout->addWidget(mpDisplayUnknownFramesCheckBox, 5, 0, 1, 2);
  pDebuggerLayout->addWidget(mpClearOutputOnNewRunCheckBox, 6, 0, 1, 2);
  pDebuggerLayout->addWidget(mpClearLogOnNewRunCheckBox, 7, 0, 1, 2);
  mpAlgorithmicDebuggerGroupBox->setLayout(pDebuggerLayout);
  /* Transformational Debugger */
  mpTransformationalDebuggerGroupBox = new QGroupBox(Helper::transformationalDebugger);
  mpAlwaysShowTransformationsCheckBox = new QCheckBox(tr("Always show %1 after compilation").arg(Helper::transformationalDebugger));
  mpGenerateOperationsCheckBox = new QCheckBox(tr("Generate Operations"));
  mpGenerateOperationsCheckBox->setChecked(OptionsDefaults::Debugger::generateOperations);
  // set the layout of Transformational Debugger group
  QGridLayout *pTransformationalDebuggerLayout = new QGridLayout;
  pTransformationalDebuggerLayout->setAlignment(Qt::AlignTop);
  pTransformationalDebuggerLayout->addWidget(mpAlwaysShowTransformationsCheckBox, 0, 0);
  pTransformationalDebuggerLayout->addWidget(mpGenerateOperationsCheckBox, 1, 0);
  mpTransformationalDebuggerGroupBox->setLayout(pTransformationalDebuggerLayout);
  // set the layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setAlignment(Qt::AlignTop);
  pMainLayout->addWidget(mpAlgorithmicDebuggerGroupBox);
  pMainLayout->addWidget(mpTransformationalDebuggerGroupBox);
  setLayout(pMainLayout);
}

/*!
 * \brief DebuggerPage::setGDBPath
 * Sets the GDB path. Only set the path if its not empty.
 * \param path
 */
void DebuggerPage::setGDBPath(QString path)
{
  mpGDBPathTextBox->setText(path);
}

/*!
 * \brief DebuggerPage::getGDBPath
 * Returns the GDB path. If path is empty then return the default path which is stored in placeholderText.
 * \return
 */
QString DebuggerPage::getGDBPath()
{
  if (mpGDBPathTextBox->text().isEmpty()) {
    return mpGDBPathTextBox->placeholderText();
  } else {
    return mpGDBPathTextBox->text();
  }
}

/*!
 * \brief DebuggerPage::browseGDBPath
 * Browse a path for GDB.
 */
void DebuggerPage::browseGDBPath()
{
  QString GDBPath = StringHandler::getOpenFileName(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseFile), NULL, "", NULL);
  if (GDBPath.isEmpty()) {
    return;
  }
  mpGDBPathTextBox->setText(GDBPath);
}

/*!
 * \class DebuggerPage
 * \brief Creates an interface for debugger settings.
 */
/*!
 * \brief FMIPage::FMIPage
 * \param pParent - pointer to OptionsDialog
 */
FMIPage::FMIPage(OptionsDialog *pOptionsDialog)
  : QWidget(pOptionsDialog)
{
  mpOptionsDialog = pOptionsDialog;
  mpExportGroupBox = new QGroupBox(Helper::exportt);
  // FMI export version
  mpVersionGroupBox = new QGroupBox(Helper::version);
  mpVersion1RadioButton = new QRadioButton("1.0");
  mpVersion2RadioButton = new QRadioButton("2.0");
  mpVersion2RadioButton->setChecked(true);
  // set the version groupbox layout
  QVBoxLayout *pVersionLayout = new QVBoxLayout;
  pVersionLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pVersionLayout->addWidget(mpVersion1RadioButton);
  pVersionLayout->addWidget(mpVersion2RadioButton);
  mpVersionGroupBox->setLayout(pVersionLayout);
  // FMI export type
  mpTypeGroupBox = new QGroupBox(Helper::type);
  mpModelExchangeRadioButton = new QRadioButton(tr("Model Exchange"));
  mpCoSimulationRadioButton = new QRadioButton(tr("Co-Simulation"));
  mpModelExchangeCoSimulationRadioButton = new QRadioButton(tr("Model Exchange and Co-Simulation"));
  mpModelExchangeCoSimulationRadioButton->setChecked(true);
  // set the type groupbox layout
  QVBoxLayout *pTypeLayout = new QVBoxLayout;
  pTypeLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pTypeLayout->addWidget(mpModelExchangeRadioButton);
  pTypeLayout->addWidget(mpCoSimulationRadioButton);
  pTypeLayout->addWidget(mpModelExchangeCoSimulationRadioButton);
  mpTypeGroupBox->setLayout(pTypeLayout);
  // FMU name prefix
  mpFMUNameLabel = new Label(tr("FMU Name:"));
  mpFMUNameTextBox = new QLineEdit;
  mpFMUNameTextBox->setPlaceholderText("<default>");
  // Move FMU after build
  mpMoveFMULabel = new Label(tr("Move FMU:"));
  mpMoveFMUTextBox = new QLineEdit;
  mpMoveFMUTextBox->setPlaceholderText(tr("<directory name or full file name with placeholders>"));
  mpBrowseFMUDirectoryButton = new QPushButton(Helper::browse);
  mpBrowseFMUDirectoryButton->setAutoDefault(false);
  connect(mpBrowseFMUDirectoryButton, SIGNAL(clicked()), SLOT(selectFMUDirectory()));
  // placeholder count may change, don't invalidate translation
  mpMoveFMUTextBox->setToolTip(tr("Placeholders:\n") +
                               FMIPage::FMU_FULL_CLASS_NAME_DOTS_PLACEHOLDER + tr(" i.e.,") + " Modelica.Electrical.Analog.Examples.ChuaCircuit\n" +
                               FMIPage::FMU_FULL_CLASS_NAME_UNDERSCORES_PLACEHOLDER + tr(" i.e.,") + " Modelica_Electrical_Analog_Examples_ChuaCircuit\n" +
                               FMIPage::FMU_SHORT_CLASS_NAME_PLACEHOLDER + tr(" i.e.,") + " ChuaCircuit");
  // platforms
  mpPlatformsGroupBox = new QGroupBox(tr("Platforms"));
  Label *pPlatformNoteLabel = new Label(tr("Note: The list of platforms is created by searching for programs in the PATH matching pattern \"*-*-*-*cc\".\n"
                                           "In order to run docker platforms add docker to PATH.\n"
                                           "A source-code only FMU is generated if no platform is selected."));
  // set the type groupbox layout
  QVBoxLayout *pPlatformsLayout = new QVBoxLayout;
  pPlatformsLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pPlatformsLayout->addWidget(pPlatformNoteLabel);
  QCheckBox *pNativePlatformCheckBox = new QCheckBox("Native");
  pNativePlatformCheckBox->setChecked(true);
  pNativePlatformCheckBox->setProperty(Helper::fmuPlatformNamePropertyId, "static");
  pPlatformsLayout->addWidget(pNativePlatformCheckBox);
  // docker platforms
  QStringList dockerPlarforms;
  dockerPlarforms << "x86_64-linux-gnu docker run openmodelica/crossbuild"
                  << "i686-linux-gnu docker run openmodelica/crossbuild"
                  << "x86_64-w64-mingw32 docker run openmodelica/crossbuild"
                  << "i686-w64-mingw32 docker run openmodelica/crossbuild"
                  << "arm-linux-gnueabihf docker run openmodelica/crossbuild"
                  << "aarch64-linux-gnu docker run openmodelica/crossbuild";
  foreach (QString dockerPlarform, dockerPlarforms) {
    QCheckBox *pCheckBox = new QCheckBox(dockerPlarform);
    pCheckBox->setProperty(Helper::fmuPlatformNamePropertyId, dockerPlarform);
    pPlatformsLayout->addWidget(pCheckBox);
  }
#if defined(_WIN32)
  QStringList paths = QString(getenv("PATH")).split(";");
#else
  QStringList paths = QString(getenv("PATH")).split(":");
#endif
  QStringList nameFilters;
  nameFilters << "*-*-*-*cc";
  QStringList compilers;
  foreach (QString path, paths) {
    QDir dir(path);
    compilers << dir.entryList(nameFilters, QDir::Files | QDir::NoDotAndDotDot, QDir::Name);
  }
  foreach (QString compiler, compilers) {
    QString platformName = compiler.left(compiler.lastIndexOf('-'));
    QCheckBox *pCheckBox = new QCheckBox(QString("%1 (auto-detected)").arg(platformName));
    pCheckBox->setProperty(Helper::fmuPlatformNamePropertyId, platformName);
    pPlatformsLayout->addWidget(pCheckBox);
  }
  // custom platforms
  QLineEdit *pCustomPlatformsTextBox = new QLineEdit;
  QString customPlatformTip = tr("Comma separated list of additional platforms");
  pCustomPlatformsTextBox->setPlaceholderText(customPlatformTip);
  pCustomPlatformsTextBox->setToolTip(customPlatformTip);
  pPlatformsLayout->addWidget(pCustomPlatformsTextBox);
  mpPlatformsGroupBox->setLayout(pPlatformsLayout);
  // Solver for co-simulation
  mpSolverForCoSimulationComboBox = new ComboBox;
  mpSolverForCoSimulationComboBox->addItem(tr("Explicit Euler"), "");
  mpSolverForCoSimulationComboBox->addItem(tr("CVODE"), "cvode");
  // Model description filters
  OMCInterface::getConfigFlagValidOptions_res fmiFilters = MainWindow::instance()->getOMCProxy()->getConfigFlagValidOptions("fmiFilter");
  mpModelDescriptionFiltersComboBox = new ComboBox;
  mpModelDescriptionFiltersComboBox->addItems(fmiFilters.validOptions);
  mpModelDescriptionFiltersComboBox->setCurrentIndex(mpModelDescriptionFiltersComboBox->findText(OptionsDefaults::FMI::modelDescriptionFilter));
  Utilities::setToolTip(mpModelDescriptionFiltersComboBox, fmiFilters.mainDescription, fmiFilters.descriptions);
  connect(mpModelDescriptionFiltersComboBox, SIGNAL(currentIndexChanged(int)), SLOT(enableIncludeSourcesCheckBox(int)));
  // include resources checkbox
  mpIncludeResourcesCheckBox = new QCheckBox(tr("Include Modelica based resources via loadResource"));
  // include source code checkbox
  mpIncludeSourceCodeCheckBox = new QCheckBox(tr("Include Source Code (model description filter \"blackBox\" will override this, because black box FMUs do never contain their source code.)"));
  mpIncludeSourceCodeCheckBox->setChecked(OptionsDefaults::FMI::includeSourceCode);
  enableIncludeSourcesCheckBox(mpModelDescriptionFiltersComboBox->currentIndex());
  // generate debug symbols
  mpGenerateDebugSymbolsCheckBox = new QCheckBox(tr("Generate Debug Symbols"));
  // set the export group box layout
  QGridLayout *pExportLayout = new QGridLayout;
  pExportLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pExportLayout->addWidget(mpVersionGroupBox, 0, 0, 1, 3);
  pExportLayout->addWidget(mpTypeGroupBox, 1, 0, 1, 3);
  pExportLayout->addWidget(mpFMUNameLabel, 2, 0);
  pExportLayout->addWidget(mpFMUNameTextBox, 2, 1, 1, 2);
  pExportLayout->addWidget(mpMoveFMULabel, 3, 0);
  pExportLayout->addWidget(mpMoveFMUTextBox, 3, 1);
  pExportLayout->addWidget(mpBrowseFMUDirectoryButton, 3, 2);
  pExportLayout->addWidget(mpPlatformsGroupBox, 4, 0, 1, 3);
  pExportLayout->addWidget(new Label(tr("Solver for Co-Simulation:")), 5, 0);
  pExportLayout->addWidget(mpSolverForCoSimulationComboBox, 5, 1, 1, 2);
  pExportLayout->addWidget(new Label(tr("Model Description Filters:")), 6, 0);
  pExportLayout->addWidget(mpModelDescriptionFiltersComboBox, 6, 1, 1, 2);
  pExportLayout->addWidget(mpIncludeResourcesCheckBox, 7, 0, 1, 3);
  pExportLayout->addWidget(mpIncludeSourceCodeCheckBox, 8, 0, 1, 3);
  pExportLayout->addWidget(mpGenerateDebugSymbolsCheckBox, 9, 0, 1, 3);
  mpExportGroupBox->setLayout(pExportLayout);
  // import groupbox
  mpImportGroupBox = new QGroupBox(tr("Import"));
  mpDeleteFMUDirectoryAndModelCheckBox = new QCheckBox(tr("Delete FMU directory and generated model when OMEdit is closed"));
  // set the import group box layout
  QGridLayout *pImportLayout = new QGridLayout;
  pImportLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pImportLayout->addWidget(mpDeleteFMUDirectoryAndModelCheckBox, 0, 0);
  mpImportGroupBox->setLayout(pImportLayout);
  // set the layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setAlignment(Qt::AlignTop);
  pMainLayout->addWidget(mpExportGroupBox);
  pMainLayout->addWidget(mpImportGroupBox);
  setLayout(pMainLayout);
}

const QString FMIPage::FMU_FULL_CLASS_NAME_DOTS_PLACEHOLDER = "{Full.Name}";
const QString FMIPage::FMU_FULL_CLASS_NAME_UNDERSCORES_PLACEHOLDER = "{Full_Name}";
const QString FMIPage::FMU_SHORT_CLASS_NAME_PLACEHOLDER = "{shortName}";

/*!
 * \brief FMIPage::setFMIExportVersion
 * Sets the FMI export version
 * \param version
 */
void FMIPage::setFMIExportVersion(QString version)
{
  if (version == "1.0" || version == "1") {
    mpVersion1RadioButton->setChecked(true);
  } else {
    mpVersion2RadioButton->setChecked(true);
  }
}

/*!
 * \brief FMIPage::getFMIExportVersion
 * Gets the FMI export version
 * \return
 */
QString FMIPage::getFMIExportVersion()
{
  if (mpVersion1RadioButton->isChecked()) {
    return "1.0";
  } else {
    return "2.0";
  }
}

/*!
 * \brief FMIPage::setFMIExportType
 * Sets the FMI export type
 * \param type
 */
void FMIPage::setFMIExportType(QString type)
{
  if (type.compare("me") == 0) {
    mpModelExchangeRadioButton->setChecked(true);
  } else if (type.compare("cs") == 0) {
    mpCoSimulationRadioButton->setChecked(true);
  } else {
    mpModelExchangeCoSimulationRadioButton->setChecked(true);
  }
}

/*!
 * \brief FMIPage::getFMIExportType
 * Gets the FMI export type
 * \return
 */
QString FMIPage::getFMIExportType()
{
  if (mpModelExchangeRadioButton->isChecked()) {
    return "me";
  } else if (mpCoSimulationRadioButton->isChecked()) {
    return "cs";
  } else {
    return "me_cs";
  }
}

/*!
 * \brief FMIPage::getFMIFlags
 * Returns the FMI flags.
 * \return
 */
QString FMIPage::getFMIFlags()
{
  QStringList fmiFlags;
  QString solver = mpSolverForCoSimulationComboBox->itemData(mpSolverForCoSimulationComboBox->currentIndex()).toString();
  if (!solver.isEmpty()) {
    fmiFlags.append(QString("s:%1").arg(solver));
  }

  return fmiFlags.join(",");
}

/*!
 * \brief FMIPage::selectFMUDirectory
 * Selects the FMU directory.
 */
void FMIPage::selectFMUDirectory()
{
  mpMoveFMUTextBox->setText(StringHandler::getExistingDirectory(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::chooseDirectory), NULL));
}

/*!
 * \brief FMIPage::enableIncludeSourcesCheckBox
 * Enables/Disables the includes sources checkbox.
 * \param modelDescriptionFilter
 */
void FMIPage::enableIncludeSourcesCheckBox(int index)
{
  const QString modelDescriptionFilter = mpModelDescriptionFiltersComboBox->itemText(index);
  if (modelDescriptionFilter.compare(QStringLiteral("blackBox")) == 0) {
    mpIncludeSourceCodeCheckBox->setEnabled(false);
  } else {
    mpIncludeSourceCodeCheckBox->setEnabled(true);
  }
}

/*!
 * \class OMSimulatorPage
 * Creates an interface for OMSimulator settings.
 */
/*!
 * \brief OMSimulatorPage::OMSimulatorPage
 * \param pOptionsDialog
 */
OMSimulatorPage::OMSimulatorPage(OptionsDialog *pOptionsDialog)
  : QWidget(pOptionsDialog)
{
  mpOptionsDialog = pOptionsDialog;
  mpGeneralGroupBox = new QGroupBox(Helper::general);
  // command line options
  mpCommandLineOptionsLabel = new Label(tr("Command Line Options:"));
  mpCommandLineOptionsTextBox = new QLineEdit(OptionsDefaults::OMSimulator::commandLineOptions);
  mpCommandLineOptionsTextBox->setToolTip(tr("Space separated list of command line options e.g., --suppressPath=true --ignoreInitialUnknowns=true"));
  // logging level
  mpLoggingLevelLabel = new Label(tr("Logging Level:"));
  mpLoggingLevelComboBox = new ComboBox;
  mpLoggingLevelComboBox->addItem("default", QVariant(0));
  mpLoggingLevelComboBox->addItem("default+debug", QVariant(1));
  mpLoggingLevelComboBox->addItem("default+debug+trace", QVariant(2));
  // set the layout
  QGridLayout *pGeneralGroupBoxLayout = new QGridLayout;
  pGeneralGroupBoxLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pGeneralGroupBoxLayout->addWidget(mpCommandLineOptionsLabel, 0, 0);
  pGeneralGroupBoxLayout->addWidget(mpCommandLineOptionsTextBox, 0, 1);
  pGeneralGroupBoxLayout->addWidget(mpLoggingLevelLabel, 1, 0);
  pGeneralGroupBoxLayout->addWidget(mpLoggingLevelComboBox, 1, 1);
  mpGeneralGroupBox->setLayout(pGeneralGroupBoxLayout);
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setAlignment(Qt::AlignTop);
  pMainLayout->addWidget(mpGeneralGroupBox);
  setLayout(pMainLayout);
}

/*!
 * \class SensitivityOptimizationPage
 * Creates an interface for Sensitivity Optimization settings.
 */
/*!
 * \brief SensitivityOptimizationPage::SensitivityOptimizationPage
 * \param pOptionsDialog
 */
SensitivityOptimizationPage::SensitivityOptimizationPage(OptionsDialog *pOptionsDialog)
  : QWidget(pOptionsDialog)
{
  mpOptionsDialog = pOptionsDialog;
  mpGeneralGroupBox = new QGroupBox(Helper::general);
  Label *pInfoLabel = new Label(tr("Sensitivity Optimization relies on the OMSens Python package. "
                                   "Follow the installation instructions on the <a href=\"https://github.com/OpenModelica/OMSens\">OMSens GitHub page</a>.<br /><br />"
                                   "Set the OMSens backend to the directory where the OMSens Python package is installed.<br />"
                                   "Specify the Python executable you want to use for running OMSens scripts."));
  pInfoLabel->setWordWrap(true);
  pInfoLabel->setOpenExternalLinks(true);
  pInfoLabel->setTextInteractionFlags(Qt::TextBrowserInteraction);
  pInfoLabel->setToolTip("");
  // omsens backend
  mpOMSensBackendPathLabel = new Label(tr("OMSens Backend Path:"));
  mpOMSensBackendPathTextBox = new QLineEdit;
  mpOMSensBackendBrowseButton = new QPushButton(Helper::browse);
  mpOMSensBackendBrowseButton->setAutoDefault(false);
  connect(mpOMSensBackendBrowseButton, SIGNAL(clicked()), SLOT(browseOMSensBackendPath()));
  // python executable
  mpPythonLabel = new Label(tr("Python:"));
  mpPythonTextBox = new QLineEdit(OptionsDefaults::SensitivityOptimization::python);
  mpPythonBrowseButton = new QPushButton(Helper::browse);
  mpPythonBrowseButton->setAutoDefault(false);
  connect(mpPythonBrowseButton, SIGNAL(clicked()), SLOT(browsePythonExecutable()));
  // set the layout
  QGridLayout *pGeneralGroupBoxLayout = new QGridLayout;
  pGeneralGroupBoxLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pGeneralGroupBoxLayout->addWidget(pInfoLabel, 0, 0, 1, 3);
  pGeneralGroupBoxLayout->addWidget(mpOMSensBackendPathLabel, 1, 0);
  pGeneralGroupBoxLayout->addWidget(mpOMSensBackendPathTextBox, 1, 1);
  pGeneralGroupBoxLayout->addWidget(mpOMSensBackendBrowseButton, 1, 2);
  pGeneralGroupBoxLayout->addWidget(mpPythonLabel, 2, 0);
  pGeneralGroupBoxLayout->addWidget(mpPythonTextBox, 2, 1);
  pGeneralGroupBoxLayout->addWidget(mpPythonBrowseButton, 2, 2);
  mpGeneralGroupBox->setLayout(pGeneralGroupBoxLayout);
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setAlignment(Qt::AlignTop);
  pMainLayout->addWidget(mpGeneralGroupBox);
  setLayout(pMainLayout);
}

/*!
 * \brief SensitivityOptimizationPage::browseOMSensBackendPath
 * Browse OMSens backend path.
 */
void SensitivityOptimizationPage::browseOMSensBackendPath()
{
  mpOMSensBackendPathTextBox->setText(StringHandler::getExistingDirectory(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::chooseDirectory), NULL));
}

/*!
 * \brief SensitivityOptimizationPage::browsePythonExecutable
 * Browse Python executable.
 */
void SensitivityOptimizationPage::browsePythonExecutable()
{
  mpPythonTextBox->setText(StringHandler::getOpenFileName(this, QString("%1 - %2").arg(Helper::applicationName, Helper::chooseFile)));
}

/*!
 * \class TraceabilityPage
 * Creates an interface for Traceability settings.
 */
TraceabilityPage::TraceabilityPage(OptionsDialog *pOptionsDialog)
  : QWidget(pOptionsDialog)
{
  mpOptionsDialog = pOptionsDialog;
  mpTraceabilityGroupBox = new QGroupBox(tr("Traceability"));
  mpTraceabilityGroupBox->setCheckable(true);
  mpTraceabilityGroupBox->setChecked(false);
  // User name
  mpUserNameLabel = new Label(tr("User Name:"));
  mpUserNameTextBox = new QLineEdit;
  // Email
  mpEmailLabel = new Label(tr("Email:"));
  mpEmailTextBox = new QLineEdit;
  // Git repository
  mpGitRepositoryLabel = new Label(tr("Git Repository:"));
  mpGitRepositoryTextBox = new QLineEdit;
  mpBrowseGitRepositoryButton = new QPushButton(Helper::browse);
  mpBrowseGitRepositoryButton->setAutoDefault(false);
  connect(mpBrowseGitRepositoryButton, SIGNAL(clicked()), SLOT(browseGitRepository()));
  // Traceability Daemon Ip Adress
  mpTraceabilityDaemonIpAdressLabel = new Label(tr("Traceability Daemon IP Adress:"));
  mpTraceabilityDaemonIpAdressTextBox = new QLineEdit;
  // Traceability Daemon Port
  mpTraceabilityDaemonPortLabel = new Label(tr("Traceability Daemon Port:"));
  mpTraceabilityDaemonPortTextBox = new QLineEdit;
   // set the layout
  QGridLayout *pTraceabilityGroupBoxLayout = new QGridLayout;
  pTraceabilityGroupBoxLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pTraceabilityGroupBoxLayout->addWidget(mpUserNameLabel, 0, 0);
  pTraceabilityGroupBoxLayout->addWidget(mpUserNameTextBox, 0, 1);
  pTraceabilityGroupBoxLayout->addWidget(mpEmailLabel, 1, 0);
  pTraceabilityGroupBoxLayout->addWidget(mpEmailTextBox, 1, 1);
  pTraceabilityGroupBoxLayout->addWidget(mpGitRepositoryLabel, 2, 0);
  pTraceabilityGroupBoxLayout->addWidget(mpGitRepositoryTextBox, 2, 1);
  pTraceabilityGroupBoxLayout->addWidget(mpBrowseGitRepositoryButton, 2, 2);
  pTraceabilityGroupBoxLayout->addWidget(mpTraceabilityDaemonIpAdressLabel, 3, 0);
  pTraceabilityGroupBoxLayout->addWidget(mpTraceabilityDaemonIpAdressTextBox, 3, 1);
  pTraceabilityGroupBoxLayout->addWidget(mpTraceabilityDaemonPortLabel, 4, 0);
  pTraceabilityGroupBoxLayout->addWidget(mpTraceabilityDaemonPortTextBox, 4, 1);
  mpTraceabilityGroupBox->setLayout(pTraceabilityGroupBoxLayout);
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setAlignment(Qt::AlignTop);
  pMainLayout->addWidget(mpTraceabilityGroupBox);
  setLayout(pMainLayout);
}

/*!
 * \brief TraceabilityPage::browseFMUOutputDirectory
 * Browse FMU Output Directory.
 */
//void TraceabilityPage::browseFMUOutputDirectory()
//{
//  mpFMUOutputDirectoryTextBox->setText(StringHandler::getExistingDirectory(this, QString("%1 - %2").arg(Helper::applicationName)
//                                                                         .arg(Helper::chooseDirectory), NULL));
//}

/*!
 * \brief TraceabilityPage::browseFMUOutputDirectory
 * Browse FMU Output Directory.
 */
void TraceabilityPage::browseGitRepository()
{
  mpGitRepositoryTextBox->setText(StringHandler::getExistingDirectory(this, QString("%1 - %2").arg(Helper::applicationName)
                                                                         .arg(Helper::chooseDirectory), NULL));
}

/*!
 * \brief DiscardLocalTranslationFlagsDialog::DiscardLocalTranslationFlagsDialog
 * \param pParent
 */
DiscardLocalTranslationFlagsDialog::DiscardLocalTranslationFlagsDialog(QWidget *pParent)
  : QDialog(pParent)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName, tr("Discard Local Translation Flags")));
  setMinimumWidth(400);
  mpDescriptionLabel = new Label(tr("You just changed some global translation flags.\n\n"
                                    "The models listed below are currently open and have different local translation flags,"
                                    "that were selected with the Simulation Setup dialog.\n\n"
                                    "Select the models for which you want to discard the local translation flag and apply the new global flags (*)."
                                    "All other models will retain the current local settings until you close OMEdit.\n"));
  mpDescriptionLabel2 = new Label(tr("(*) If you discard local settings, the new global settings will first be applied, and then any further settings"
                                     "saved in the model annotations will be applied. This is the same behaviour you would get if you closed OMEdit,"
                                     "restarted it and reopened all models.\n"));
  mpDescriptionLabel->setWordWrap(true);
  mpDescriptionLabel2->setWordWrap(true);
  mpClassesWithLocalTranslationFlagsListWidget = new QListWidget;
  mpClassesWithLocalTranslationFlagsListWidget->setObjectName("ClassesWithLocalTranslationFlagsListWidget");
  mpClassesWithLocalTranslationFlagsListWidget->setItemDelegate(new ItemDelegate(mpClassesWithLocalTranslationFlagsListWidget));
  connect(mpClassesWithLocalTranslationFlagsListWidget, SIGNAL(itemDoubleClicked(QListWidgetItem*)), SLOT(showLocalTranslationFlags(QListWidgetItem*)));
  listLocalTranslationFlagsClasses(MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->getRootLibraryTreeItem());
  QCheckBox *pSelectUnSelectAll = new QCheckBox(tr("Select/Unselect All"));
  pSelectUnSelectAll->setChecked(true);
  connect(pSelectUnSelectAll, SIGNAL(toggled(bool)), SLOT(selectUnSelectAll(bool)));
  // Create the buttons
  // create the Yes button
  mpYesButton = new QPushButton(tr("Yes"));
  mpYesButton->setAutoDefault(true);
  connect(mpYesButton, SIGNAL(clicked()), SLOT(discardLocalTranslationFlags()));
  // create the No button
  mpNoButton = new QPushButton(tr("No"));
  mpNoButton->setAutoDefault(false);
  connect(mpNoButton, SIGNAL(clicked()), SLOT(reject()));
  // create buttons box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpYesButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpNoButton, QDialogButtonBox::ActionRole);
  // create a main layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->addWidget(mpDescriptionLabel);
  pMainLayout->addWidget(pSelectUnSelectAll);
  pMainLayout->addWidget(mpClassesWithLocalTranslationFlagsListWidget);
  pMainLayout->addWidget(mpDescriptionLabel2);
  pMainLayout->addWidget(mpButtonBox, 0, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
 * \brief DiscardLocalTranslationFlagsDialog::listLocalTranslationFlagsClasses
 * \param pLibraryTreeItem
 */
void DiscardLocalTranslationFlagsDialog::listLocalTranslationFlagsClasses(LibraryTreeItem *pLibraryTreeItem)
{
  for (int i = 0; i < pLibraryTreeItem->childrenSize(); i++) {
    LibraryTreeItem *pChildLibraryTreeItem = pLibraryTreeItem->child(i);
    if (pChildLibraryTreeItem && pChildLibraryTreeItem->isModelica() && !pChildLibraryTreeItem->isSystemLibrary()) {
      if (pChildLibraryTreeItem->mSimulationOptions.isValid()) {
        QListWidgetItem *pListItem = new QListWidgetItem(mpClassesWithLocalTranslationFlagsListWidget);
        pListItem->setCheckState(Qt::Checked);
        pListItem->setText(pChildLibraryTreeItem->getNameStructure());
      }
      listLocalTranslationFlagsClasses(pChildLibraryTreeItem);
    }
  }
}

/*!
 * \brief DiscardLocalTranslationFlagsDialog::selectUnSelectAll
 * Selects or unselect the models. \n
 * Slot activated when pSelectUnSelectAll toggled signal is raised.
 * \param checked
 */
void DiscardLocalTranslationFlagsDialog::selectUnSelectAll(bool checked)
{
  for (int i = 0; i < mpClassesWithLocalTranslationFlagsListWidget->count(); i++) {
    QListWidgetItem *pClassWithLocalTranslationFlags = mpClassesWithLocalTranslationFlagsListWidget->item(i);
    if (checked) {
      pClassWithLocalTranslationFlags->setCheckState(Qt::Checked);
    } else {
      pClassWithLocalTranslationFlags->setCheckState(Qt::Unchecked);
    }
  }
}

/*!
 * \brief DiscardLocalTranslationFlagsDialog::discardLocalTranslationFlags
 * Discards the local translation flags from the selected classes. \n
 * Slot activated when mpYesButton clicked signal is raised.
 */
void DiscardLocalTranslationFlagsDialog::discardLocalTranslationFlags()
{
  for (int i = 0; i < mpClassesWithLocalTranslationFlagsListWidget->count(); i++) {
    QListWidgetItem *pClassWithLocalTranslationFlags = mpClassesWithLocalTranslationFlagsListWidget->item(i);
    if (pClassWithLocalTranslationFlags->checkState() == Qt::Checked) {
      LibraryTreeItem *pLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(pClassWithLocalTranslationFlags->text());
      if (pLibraryTreeItem) {
        pLibraryTreeItem->mSimulationOptions.setIsValid(false);
        pLibraryTreeItem->mSimulationOptions.setDataReconciliationInitialized(false);
      }
    }
  }
  accept();
}

void DiscardLocalTranslationFlagsDialog::showLocalTranslationFlags(QListWidgetItem *pListWidgetItem)
{
  LibraryTreeItem *pLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(pListWidgetItem->text());
  if (pLibraryTreeItem) {
    QDialog *pLocalTranslationFlagsDialog = new QDialog;
    pLocalTranslationFlagsDialog->setWindowTitle(QString("%1 - Local Translation Flags - %2").arg(Helper::applicationName, pLibraryTreeItem->getNameStructure()));
    pLocalTranslationFlagsDialog->setAttribute(Qt::WA_DeleteOnClose);
    TranslationFlagsWidget *pTranslationFlagsWidget = new TranslationFlagsWidget;
    pTranslationFlagsWidget->applySimulationOptions(pLibraryTreeItem->mSimulationOptions);
    QPushButton *pOkButton = new QPushButton(Helper::ok);
    connect(pOkButton, SIGNAL(clicked()), pLocalTranslationFlagsDialog, SLOT(accept()));
    QVBoxLayout *pMainLayout = new QVBoxLayout;
    pMainLayout->addWidget(pTranslationFlagsWidget);
    pMainLayout->addWidget(pOkButton, 0, Qt::AlignRight);
    pLocalTranslationFlagsDialog->setLayout(pMainLayout);
    pLocalTranslationFlagsDialog->exec();
  }
}

/*!
 * \brief DiscardLocalTranslationFlagsDialog::exec
 * Reimplementation of exec.
 * \return
 */
int DiscardLocalTranslationFlagsDialog::exec()
{
  if (mpClassesWithLocalTranslationFlagsListWidget->count() == 0) {
    return 1;
  }
  return QDialog::exec();
}

/*!
 * \class CRMLPage
 * \brief Creates an interface for CRML settings.
 */
/*!
 * \brief CRMLPage::CRMLPage
 * \param pOptionsDialog is the pointer to OptionsDialog
 */
CRMLPage::CRMLPage(OptionsDialog *pOptionsDialog)
  : QWidget(pOptionsDialog)
{
  mpOptionsDialog = pOptionsDialog;
  mpCRMLGroupBox = new QGroupBox(Helper::crml);
  // CRML compiler jar file
  mpCompilerJarLabel = new Label(tr("Compiler Jar:"));
  mpCompilerJarTextBox = new QLineEdit(OptionsDefaults::CRML::compilerJar);
  mpBrowseCompilerJarButton = new QPushButton(Helper::browse);
  mpBrowseCompilerJarButton->setAutoDefault(false);
  connect(mpBrowseCompilerJarButton, SIGNAL(clicked()), SLOT(browseCompilerJar()));
  // CRML CommandLine arguments
  mpCompilerCommandLineOptionsLabel = new Label(tr("Compiler Arguments:"));
  mpCompilerCommandLineOptionsTextBox = new QLineEdit;
  // CRML Process
  mpCompilerProcessLabel = new Label(tr("Processor:"));
  mpCompilerProcessTextBox = new QLineEdit(OptionsDefaults::CRML::process);
  mpBrowseCompilerProcessButton = new QPushButton(Helper::browse);
  mpBrowseCompilerProcessButton->setAutoDefault(false);
  connect(mpBrowseCompilerProcessButton, SIGNAL(clicked()), SLOT(browseCompilerProcessFile()));
  mpResetCompilerProcessButton = new QPushButton(Helper::reset);
  mpResetCompilerProcessButton->setToolTip(tr("Resets to default Processor path"));
  mpResetCompilerProcessButton->setAutoDefault(false);
  connect(mpResetCompilerProcessButton, SIGNAL(clicked()), SLOT(resetCompilerProcessPath()));
  mpModelicaLibraries = new DirectoryOrFileSelector(false, tr("Modelica Library Paths:"), pOptionsDialog);
  // set the layout
  QGridLayout *pCRMLLayout = new QGridLayout;
  pCRMLLayout->addWidget(mpCompilerJarLabel, 0, 0);
  pCRMLLayout->addWidget(mpCompilerJarTextBox, 0, 1, 1, 2);
  pCRMLLayout->addWidget(mpBrowseCompilerJarButton, 0, 3);
  pCRMLLayout->addWidget(mpCompilerCommandLineOptionsLabel, 1, 0);
  pCRMLLayout->addWidget(mpCompilerCommandLineOptionsTextBox, 1, 1, 1, 3);
  pCRMLLayout->addWidget(mpCompilerProcessLabel, 2, 0);
  pCRMLLayout->addWidget(mpCompilerProcessTextBox, 2, 1);
  pCRMLLayout->addWidget(mpBrowseCompilerProcessButton, 2, 2);
  pCRMLLayout->addWidget(mpResetCompilerProcessButton, 2, 3);
  pCRMLLayout->addWidget(mpModelicaLibraries, 3, 0, 1, 4);
  mpCRMLGroupBox->setLayout(pCRMLLayout);
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setAlignment(Qt::AlignTop);
  pMainLayout->addWidget(mpCRMLGroupBox);
  setLayout(pMainLayout);
}

/*!
 * \brief CRMLPage::browseCompilerJar
 * Selects the compiler jar file.
 */
void CRMLPage::browseCompilerJar()
{
  mpCompilerJarTextBox->setText(StringHandler::getOpenFileName(this, QString("%1 - %2").arg(Helper::applicationName, Helper::chooseFile), NULL, Helper::jarFileTypes, NULL));
}

/*!
 * \brief CRMLPage::browseCompilerProcessFile
 * Selects the compiler process.
 */
void CRMLPage::browseCompilerProcessFile()
{
  mpCompilerProcessTextBox->setText(StringHandler::getOpenFileName(this, QString("%1 - %2").arg(Helper::applicationName, Helper::chooseFile)));
}

/*!
 * \brief CRMLPage::resetCRMLCompilerProcessPath
 * Resets the CRML process path to default.
 */
void CRMLPage::resetCompilerProcessPath()
{
  mpCompilerProcessTextBox->setText(OptionsDefaults::CRML::process);
}
