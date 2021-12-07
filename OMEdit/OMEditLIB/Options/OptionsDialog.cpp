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
  mpMetaModelicaEditorPage = new MetaModelicaEditorPage(this);
  connect(mpTextEditorPage->getFontFamilyComboBox(), SIGNAL(currentFontChanged(QFont)), mpMetaModelicaEditorPage, SIGNAL(updatePreview()));
  connect(mpTextEditorPage->getFontSizeSpinBox(), SIGNAL(valueChanged(double)), mpMetaModelicaEditorPage, SIGNAL(updatePreview()));
  mpCompositeModelEditorPage = new CompositeModelEditorPage(this);
  connect(mpTextEditorPage->getFontFamilyComboBox(), SIGNAL(currentFontChanged(QFont)), mpCompositeModelEditorPage, SIGNAL(updatePreview()));
  connect(mpTextEditorPage->getFontSizeSpinBox(), SIGNAL(valueChanged(double)), mpCompositeModelEditorPage, SIGNAL(updatePreview()));
  mpOMSimulatorEditorPage = new OMSimulatorEditorPage(this);
  connect(mpTextEditorPage->getFontFamilyComboBox(), SIGNAL(currentFontChanged(QFont)), mpOMSimulatorEditorPage, SIGNAL(updatePreview()));
  connect(mpTextEditorPage->getFontSizeSpinBox(), SIGNAL(valueChanged(double)), mpOMSimulatorEditorPage, SIGNAL(updatePreview()));
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
  mpDebuggerPage = new DebuggerPage(this);
  mpFMIPage = new FMIPage(this);
  mpTLMPage = new TLMPage(this);
  mpOMSimulatorPage = new OMSimulatorPage(this);
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
  readMetaModelicaEditorSettings();
  emit metaModelicaEditorSettingsChanged();
  mpMetaModelicaEditorPage->emitUpdatePreview();
  readCompositeModelEditorSettings();
  emit compositeModelEditorSettingsChanged();
  mpCompositeModelEditorPage->emitUpdatePreview();
  readOMSimulatorEditorSettings();
  emit omsimulatorEditorSettingsChanged();
  mpOMSimulatorEditorPage->emitUpdatePreview();
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
  readDebuggerSettings();
  readFMISettings();
  readTLMSettings();
  readOMSimulatorSettings();
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
  }
  // read the working directory
  if (mpSettings->contains("workingDirectory")) {
    mpGeneralSettingsPage->setWorkingDirectory(mpSettings->value("workingDirectory").toString());
  }
  // read toolbar icon size
  if (mpSettings->contains("toolbarIconSize")) {
    mpGeneralSettingsPage->getToolbarIconSizeSpinBox()->setValue(mpSettings->value("toolbarIconSize").toInt());
  }
  // read the user customizations
  if (mpSettings->contains("userCustomizations")) {
    mpGeneralSettingsPage->setPreserveUserCustomizations(mpSettings->value("userCustomizations").toBool());
  }
  // read the terminal command
  if (mpSettings->contains("terminalCommand")) {
    mpGeneralSettingsPage->setTerminalCommand(mpSettings->value("terminalCommand").toString());
  }
  // read the terminal command arguments
  if (mpSettings->contains("terminalCommandArgs")) {
    mpGeneralSettingsPage->setTerminalCommandArguments(mpSettings->value("terminalCommandArgs").toString());
  }
  // read hide variables browser
  if (mpSettings->contains("hideVariablesBrowser")) {
    mpGeneralSettingsPage->getHideVariablesBrowserCheckBox()->setChecked(mpSettings->value("hideVariablesBrowser").toBool());
  }
  // read activate access annotations
  if (mpSettings->contains("activateAccessAnnotations")) {
    bool ok;
    int currentIndex = mpGeneralSettingsPage->getActivateAccessAnnotationsComboBox()->findData(mpSettings->value("activateAccessAnnotations").toInt(&ok));
    if (currentIndex > -1 && ok) {
      mpGeneralSettingsPage->getActivateAccessAnnotationsComboBox()->setCurrentIndex(currentIndex);
    }
  }
  // read create a backup file
  if (mpSettings->contains("createBackupFile")) {
    mpGeneralSettingsPage->getCreateBackupFileCheckbox()->setChecked(mpSettings->value("createBackupFile").toBool());
  }
  // read nfAPINoise
  if (mpSettings->contains("simulation/nfAPINoise")) {
    mpGeneralSettingsPage->getDisplayNFAPIErrorsWarningsCheckBox()->setChecked(mpSettings->value("simulation/nfAPINoise").toBool());
  }
  // read library icon size
  if (mpSettings->contains("libraryIconSize")) {
    mpGeneralSettingsPage->getLibraryIconSizeSpinBox()->setValue(mpSettings->value("libraryIconSize").toInt());
  }
  // read the max. text length to draw on a library icon
  if (mpSettings->contains("libraryIconMaxTextLength")) {
    ShapeAnnotation::maxTextLengthToShowOnLibraryIcon = mpSettings->value("libraryIconMaxTextLength").toInt(); // set cached value
  }
  mpGeneralSettingsPage->getLibraryIconTextLengthSpinBox()->setValue(ShapeAnnotation::maxTextLengthToShowOnLibraryIcon);
  // read show protected classes
  if (mpSettings->contains("showProtectedClasses")) {
    mpGeneralSettingsPage->setShowProtectedClasses(mpSettings->value("showProtectedClasses").toBool());
  }
  // read show hidden classes
  if (mpSettings->contains("showHiddenClasses")) {
    mpGeneralSettingsPage->setShowHiddenClasses(mpSettings->value("showHiddenClasses").toBool());
  }
  // read synchronize with ModelWidget
  if (mpSettings->contains("synchronizeWithModelWidget")) {
    mpGeneralSettingsPage->getSynchronizeWithModelWidgetCheckBox()->setChecked(mpSettings->value("synchronizeWithModelWidget").toBool());
  }
  // read auto save
  if (mpSettings->contains("autoSave/enable")) {
    mpGeneralSettingsPage->getEnableAutoSaveGroupBox()->setChecked(mpSettings->value("autoSave/enable").toBool());
  }
  if (mpSettings->contains("autoSave/interval")) {
    mpGeneralSettingsPage->getAutoSaveIntervalSpinBox()->setValue(mpSettings->value("autoSave/interval").toInt());
  }
  // read welcome page
  if (mpSettings->contains("welcomePage/view")) {
    mpGeneralSettingsPage->setWelcomePageView(mpSettings->value("welcomePage/view").toInt());
  }
  if (mpSettings->contains("welcomePage/showLatestNews")) {
    mpGeneralSettingsPage->getShowLatestNewsCheckBox()->setChecked(mpSettings->value("welcomePage/showLatestNews").toBool());
  }
  // recent files size
  if (mpSettings->contains("welcomePage/recentFilesSize")) {
    mpGeneralSettingsPage->getRecentFilesAndLatestNewsSizeSpinBox()->setValue(mpSettings->value("welcomePage/recentFilesSize").toInt());
  }
  // replaceable support
  if (mpSettings->contains("replaceableSupport")) {
    mpGeneralSettingsPage->setReplaceableSupport(mpSettings->value("replaceableSupport").toBool());
  }
  // read nfAPI
  if (mpSettings->contains("simulation/nfAPI")) {
    mpGeneralSettingsPage->getEnableNewInstantiationAPICheckBox()->setChecked(mpSettings->value("simulation/nfAPI").toBool());
  }
}

//! Reads the Libraries section settings from omedit.ini
void OptionsDialog::readLibrariesSettings()
{
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
  // read the forceModelicaLoad
  if (mpSettings->contains("forceModelicaLoad")) {
    mpLibrariesPage->getForceModelicaLoadCheckBox()->setChecked(mpSettings->value("forceModelicaLoad").toBool());
  }
  // read load OpenModelica library on startup
  if (mpSettings->contains("loadOpenModelicaOnStartup")) {
    mpLibrariesPage->getLoadOpenModelicaLibraryCheckBox()->setChecked(mpSettings->value("loadOpenModelicaOnStartup").toBool());
  }
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
    if (index > -1) {
      mpTextEditorPage->getLineEndingComboBox()->setCurrentIndex(index);
    }
  }
  if (mpSettings->contains("textEditor/bom")) {
    index = mpTextEditorPage->getBOMComboBox()->findData(mpSettings->value("textEditor/bom").toInt());
    if (index > -1) {
      mpTextEditorPage->getBOMComboBox()->setCurrentIndex(index);
    }
  }
  if (mpSettings->contains("textEditor/tabPolicy")) {
    index = mpTextEditorPage->getTabPolicyComboBox()->findData(mpSettings->value("textEditor/tabPolicy").toInt());
    if (index > -1) {
      mpTextEditorPage->getTabPolicyComboBox()->setCurrentIndex(index);
    }
  }
  if (mpSettings->contains("textEditor/tabSize")) {
    mpTextEditorPage->getTabSizeSpinBox()->setValue(mpSettings->value("textEditor/tabSize").toInt());
  }
  if (mpSettings->contains("textEditor/indentSize")) {
    mpTextEditorPage->getIndentSpinBox()->setValue(mpSettings->value("textEditor/indentSize").toInt());
  }
  if (mpSettings->contains("textEditor/enableSyntaxHighlighting")) {
    mpTextEditorPage->getSyntaxHighlightingGroupBox()->setChecked(mpSettings->value("textEditor/enableSyntaxHighlighting").toBool());
  }
  if (mpSettings->contains("textEditor/enableCodeFolding")) {
    mpTextEditorPage->getCodeFoldingCheckBox()->setChecked(mpSettings->value("textEditor/enableCodeFolding").toBool());
  }
  if (mpSettings->contains("textEditor/matchParenthesesCommentsQuotes")) {
    mpTextEditorPage->getMatchParenthesesCommentsQuotesCheckBox()->setChecked(mpSettings->value("textEditor/matchParenthesesCommentsQuotes").toBool());
  }
  if (mpSettings->contains("textEditor/enableLineWrapping")) {
    mpTextEditorPage->getLineWrappingCheckbox()->setChecked(mpSettings->value("textEditor/enableLineWrapping").toBool());
  }
  if (mpSettings->contains("textEditor/fontFamily")) {
    // select font family item
    index = mpTextEditorPage->getFontFamilyComboBox()->findText(mpSettings->value("textEditor/fontFamily").toString(), Qt::MatchExactly);
    if (index > -1) {
      mpTextEditorPage->getFontFamilyComboBox()->setCurrentIndex(index);
    }
  }
  if (mpSettings->contains("textEditor/fontSize")) {
    // select font size item
    mpTextEditorPage->getFontSizeSpinBox()->setValue(mpSettings->value("textEditor/fontSize").toDouble());
  }
  if (mpSettings->contains("textEditor/enableAutocomplete")) {
    mpTextEditorPage->getAutoCompleteCheckBox()->setChecked(mpSettings->value("textEditor/enableAutocomplete").toBool());
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
  }
  if (mpSettings->contains("modelicaEditor/textRuleColor")) {
    mpModelicaEditorPage->setColor("Text", QColor(mpSettings->value("modelicaEditor/textRuleColor").toUInt()));
  }
  if (mpSettings->contains("modelicaEditor/keywordRuleColor")) {
    mpModelicaEditorPage->setColor("Keyword", QColor(mpSettings->value("modelicaEditor/keywordRuleColor").toUInt()));
  }
  if (mpSettings->contains("modelicaEditor/typeRuleColor")) {
    mpModelicaEditorPage->setColor("Type", QColor(mpSettings->value("modelicaEditor/typeRuleColor").toUInt()));
  }
  if (mpSettings->contains("modelicaEditor/functionRuleColor")) {
    mpModelicaEditorPage->setColor("Function", QColor(mpSettings->value("modelicaEditor/functionRuleColor").toUInt()));
  }
  if (mpSettings->contains("modelicaEditor/quotesRuleColor")) {
    mpModelicaEditorPage->setColor("Quotes", QColor(mpSettings->value("modelicaEditor/quotesRuleColor").toUInt()));
  }
  if (mpSettings->contains("modelicaEditor/commentRuleColor")) {
    mpModelicaEditorPage->setColor("Comment", QColor(mpSettings->value("modelicaEditor/commentRuleColor").toUInt()));
  }
  if (mpSettings->contains("modelicaEditor/numberRuleColor")) {
    mpModelicaEditorPage->setColor("Number", QColor(mpSettings->value("modelicaEditor/numberRuleColor").toUInt()));
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
  }
  if (mpSettings->contains("metaModelicaEditor/keywordRuleColor")) {
    mpMetaModelicaEditorPage->setColor("Keyword", QColor(mpSettings->value("metaModelicaEditor/keywordRuleColor").toUInt()));
  }
  if (mpSettings->contains("metaModelicaEditor/typeRuleColor")) {
    mpMetaModelicaEditorPage->setColor("Type", QColor(mpSettings->value("metaModelicaEditor/typeRuleColor").toUInt()));
  }
  if (mpSettings->contains("metaModelicaEditor/quotesRuleColor")) {
    mpMetaModelicaEditorPage->setColor("Quotes", QColor(mpSettings->value("metaModelicaEditor/quotesRuleColor").toUInt()));
  }
  if (mpSettings->contains("metaModelicaEditor/commentRuleColor")) {
    mpMetaModelicaEditorPage->setColor("Comment", QColor(mpSettings->value("metaModelicaEditor/commentRuleColor").toUInt()));
  }
  if (mpSettings->contains("metaModelicaEditor/numberRuleColor")) {
    mpMetaModelicaEditorPage->setColor("Number", QColor(mpSettings->value("metaModelicaEditor/numberRuleColor").toUInt()));
  }
}

/*!
 * \brief OptionsDialog::readCompositeModelEditorSettings
 * Reads the CompositeModelEditor settings from omedit.ini
 */
void OptionsDialog::readCompositeModelEditorSettings()
{
  if (mpSettings->contains("compositeModelEditor/textRuleColor")) {
    mpCompositeModelEditorPage->setColor("Text", QColor(mpSettings->value("compositeModelEditor/textRuleColor").toUInt()));
  }
  if (mpSettings->contains("compositeModelEditor/commentRuleColor")) {
    mpCompositeModelEditorPage->setColor("Comment", QColor(mpSettings->value("compositeModelEditor/commentRuleColor").toUInt()));
  }
  if (mpSettings->contains("compositeModelEditor/tagRuleColor")) {
    mpCompositeModelEditorPage->setColor("Tag", QColor(mpSettings->value("compositeModelEditor/tagRuleColor").toUInt()));
  }
  if (mpSettings->contains("compositeModelEditor/quotesRuleColor")) {
    mpCompositeModelEditorPage->setColor("Quotes", QColor(mpSettings->value("compositeModelEditor/quotesRuleColor").toUInt()));
  }
  if (mpSettings->contains("compositeModelEditor/elementsRuleColor")) {
    mpCompositeModelEditorPage->setColor("Element", QColor(mpSettings->value("compositeModelEditor/elementsRuleColor").toUInt()));
  }
}

/*!
 * \brief OptionsDialog::readOMSCompositeModelEditorSettings
 * Reads the OMSCompositeModelEditor settings from omedit.ini
 */
void OptionsDialog::readOMSimulatorEditorSettings()
{
  if (mpSettings->contains("omsimulatorEditor/textRuleColor")) {
    mpOMSimulatorEditorPage->setColor("Text", QColor(mpSettings->value("omsimulatorEditor/textRuleColor").toUInt()));
  }
  if (mpSettings->contains("omsimulatorEditor/commentRuleColor")) {
    mpOMSimulatorEditorPage->setColor("Comment", QColor(mpSettings->value("omsimulatorEditor/commentRuleColor").toUInt()));
  }
  if (mpSettings->contains("omsimulatorEditor/tagRuleColor")) {
    mpOMSimulatorEditorPage->setColor("Tag", QColor(mpSettings->value("omsimulatorEditor/tagRuleColor").toUInt()));
  }
  if (mpSettings->contains("omsimulatorEditor/quotesRuleColor")) {
    mpOMSimulatorEditorPage->setColor("Quotes", QColor(mpSettings->value("omsimulatorEditor/quotesRuleColor").toUInt()));
  }
  if (mpSettings->contains("omsimulatorEditor/elementsRuleColor")) {
    mpOMSimulatorEditorPage->setColor("Element", QColor(mpSettings->value("omsimulatorEditor/elementsRuleColor").toUInt()));
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
  }
  if (mpSettings->contains("cEditor/keywordRuleColor")) {
    mpCEditorPage->setColor("Keyword", QColor(mpSettings->value("cEditor/keywordRuleColor").toUInt()));
  }
  if (mpSettings->contains("cEditor/typeRuleColor")) {
    mpCEditorPage->setColor("Type", QColor(mpSettings->value("cEditor/typeRuleColor").toUInt()));
  }
  if (mpSettings->contains("cEditor/quotesRuleColor")) {
    mpCEditorPage->setColor("Quotes", QColor(mpSettings->value("cEditor/quotesRuleColor").toUInt()));
  }
  if (mpSettings->contains("cEditor/commentRuleColor")) {
    mpCEditorPage->setColor("Comment", QColor(mpSettings->value("cEditor/commentRuleColor").toUInt()));
  }
  if (mpSettings->contains("cEditor/numberRuleColor")) {
    mpCEditorPage->setColor("Number", QColor(mpSettings->value("cEditor/numberRuleColor").toUInt()));
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
  }
  if (mpSettings->contains("HTMLEditor/commentRuleColor")) {
    mpHTMLEditorPage->setColor("Comment", QColor(mpSettings->value("HTMLEditor/commentRuleColor").toUInt()));
  }
  if (mpSettings->contains("HTMLEditor/tagRuleColor")) {
    mpHTMLEditorPage->setColor("Tag", QColor(mpSettings->value("HTMLEditor/tagRuleColor").toUInt()));
  }
  if (mpSettings->contains("HTMLEditor/quotesRuleColor")) {
    mpHTMLEditorPage->setColor("Quotes", QColor(mpSettings->value("HTMLEditor/quotesRuleColor").toUInt()));
  }
}

//! Reads the GraphicsViews section settings from omedit.ini
void OptionsDialog::readGraphicalViewsSettings()
{
  // read the modeling view mode
  if (mpSettings->contains("modeling/viewmode")) {
    mpGraphicalViewsPage->setModelingViewMode(mpSettings->value("modeling/viewmode").toString());
  }
  // read the default view
  if (mpSettings->contains("defaultView")) {
    mpGraphicalViewsPage->setDefaultView(mpSettings->value("defaultView").toString());
  }
  // read move connectors together
  if (mpSettings->contains("modeling/moveConnectorsTogether")) {
    mpGraphicalViewsPage->getMoveConnectorsTogetherCheckBox()->setChecked(mpSettings->value("modeling/moveConnectorsTogether").toBool());
  }
  if (mpSettings->contains("iconView/extentLeft"))
    mpGraphicalViewsPage->setIconViewExtentLeft(mpSettings->value("iconView/extentLeft").toDouble());
  if (mpSettings->contains("iconView/extentBottom"))
    mpGraphicalViewsPage->setIconViewExtentBottom(mpSettings->value("iconView/extentBottom").toDouble());
  if (mpSettings->contains("iconView/extentRight"))
    mpGraphicalViewsPage->setIconViewExtentRight(mpSettings->value("iconView/extentRight").toDouble());
  if (mpSettings->contains("iconView/extentTop"))
    mpGraphicalViewsPage->setIconViewExtentTop(mpSettings->value("iconView/extentTop").toDouble());
  if (mpSettings->contains("iconView/gridHorizontal"))
    mpGraphicalViewsPage->setIconViewGridHorizontal(mpSettings->value("iconView/gridHorizontal").toDouble());
  if (mpSettings->contains("iconView/gridVertical"))
    mpGraphicalViewsPage->setIconViewGridVertical(mpSettings->value("iconView/gridVertical").toDouble());
  if (mpSettings->contains("iconView/scaleFactor"))
    mpGraphicalViewsPage->setIconViewScaleFactor(mpSettings->value("iconView/scaleFactor").toDouble());
  if (mpSettings->contains("iconView/preserveAspectRatio"))
    mpGraphicalViewsPage->setIconViewPreserveAspectRation(mpSettings->value("iconView/preserveAspectRatio").toBool());
  if (mpSettings->contains("DiagramView/extentLeft"))
    mpGraphicalViewsPage->setDiagramViewExtentLeft(mpSettings->value("DiagramView/extentLeft").toDouble());
  if (mpSettings->contains("DiagramView/extentBottom"))
    mpGraphicalViewsPage->setDiagramViewExtentBottom(mpSettings->value("DiagramView/extentBottom").toDouble());
  if (mpSettings->contains("DiagramView/extentRight"))
    mpGraphicalViewsPage->setDiagramViewExtentRight(mpSettings->value("DiagramView/extentRight").toDouble());
  if (mpSettings->contains("DiagramView/extentTop"))
    mpGraphicalViewsPage->setDiagramViewExtentTop(mpSettings->value("DiagramView/extentTop").toDouble());
  if (mpSettings->contains("DiagramView/gridHorizontal"))
    mpGraphicalViewsPage->setDiagramViewGridHorizontal(mpSettings->value("DiagramView/gridHorizontal").toDouble());
  if (mpSettings->contains("DiagramView/gridVertical"))
    mpGraphicalViewsPage->setDiagramViewGridVertical(mpSettings->value("DiagramView/gridVertical").toDouble());
  if (mpSettings->contains("DiagramView/scaleFactor"))
    mpGraphicalViewsPage->setDiagramViewScaleFactor(mpSettings->value("DiagramView/scaleFactor").toDouble());
  if (mpSettings->contains("DiagramView/preserveAspectRatio"))
    mpGraphicalViewsPage->setDiagramViewPreserveAspectRation(mpSettings->value("DiagramView/preserveAspectRatio").toBool());
}

//! Reads the Simulation section settings from omedit.ini
void OptionsDialog::readSimulationSettings()
{
  if (mpSettings->contains("simulation/matchingAlgorithm")) {
    int currentIndex = mpSimulationPage->getTranslationFlagsWidget()->getMatchingAlgorithmComboBox()->findText(mpSettings->value("simulation/matchingAlgorithm").toString(), Qt::MatchExactly);
    if (currentIndex > -1) {
      mpSimulationPage->getTranslationFlagsWidget()->getMatchingAlgorithmComboBox()->setCurrentIndex(currentIndex);
    }
  }
  if (mpSettings->contains("simulation/indexReductionMethod")) {
    int currentIndex = mpSimulationPage->getTranslationFlagsWidget()->getIndexReductionMethodComboBox()->findText(mpSettings->value("simulation/indexReductionMethod").toString(), Qt::MatchExactly);
    if (currentIndex > -1) {
      mpSimulationPage->getTranslationFlagsWidget()->getIndexReductionMethodComboBox()->setCurrentIndex(currentIndex);
    }
  }
  // read initialization
  if (mpSettings->contains("simulation/initialization")) {
    mpSimulationPage->getTranslationFlagsWidget()->getInitializationCheckBox()->setChecked(mpSettings->value("simulation/initialization").toBool());
  }
  // read evaluate all parameters
  if (mpSettings->contains("simulation/evaluateAllParameters")) {
    mpSimulationPage->getTranslationFlagsWidget()->getEvaluateAllParametersCheckBox()->setChecked(mpSettings->value("simulation/evaluateAllParameters").toBool());
  }
  // read NLS analytic jacobian
  if (mpSettings->contains("simulation/NLSanalyticJacobian")) {
    mpSimulationPage->getTranslationFlagsWidget()->getNLSanalyticJacobianCheckBox()->setChecked(mpSettings->value("simulation/NLSanalyticJacobian").toBool());
  }
  // save parmodauto
  if (mpSettings->contains("simulation/parmodauto")) {
    mpSimulationPage->getTranslationFlagsWidget()->getParmodautoCheckBox()->setChecked(mpSettings->value("simulation/parmodauto").toBool());
  }
  // save old instantiation
  if (mpSettings->contains("simulation/newInst")) {
    mpSimulationPage->getTranslationFlagsWidget()->getOldInstantiationCheckBox()->setChecked(!mpSettings->value("simulation/newInst").toBool());
  }
  if (mpSettings->contains("simulation/OMCFlags")) {
    mpSimulationPage->getTranslationFlagsWidget()->getAdditionalTranslationFlagsTextBox()->setText(mpSettings->value("simulation/OMCFlags").toString());
  }
  if (mpSettings->contains("simulation/targetLanguage")) {
    int currentIndex = mpSimulationPage->getTargetLanguageComboBox()->findText(mpSettings->value("simulation/targetLanguage").toString(), Qt::MatchExactly);
    if (currentIndex > -1) {
      mpSimulationPage->getTargetLanguageComboBox()->setCurrentIndex(currentIndex);
    }
  }
  if (mpSettings->contains("simulation/targetCompiler")) {
    int currentIndex = mpSimulationPage->getTargetBuildComboBox()->findData(mpSettings->value("simulation/targetCompiler"), Qt::UserRole, Qt::MatchExactly);
    if (currentIndex > -1) {
      mpSimulationPage->getTargetBuildComboBox()->setCurrentIndex(currentIndex);
    }
  }
  if (mpSettings->contains("simulation/compiler")) {
    mpSimulationPage->getCompilerComboBox()->lineEdit()->setText(mpSettings->value("simulation/compiler").toString());
  }
  if (mpSettings->contains("simulation/cxxCompiler")) {
    mpSimulationPage->getCXXCompilerComboBox()->lineEdit()->setText(mpSettings->value("simulation/cxxCompiler").toString());
  }
#ifdef Q_OS_WIN
  if (mpSettings->contains("simulation/useStaticLinking")) {
    mpSimulationPage->getUseStaticLinkingCheckBox()->setChecked(mpSettings->value("simulation/useStaticLinking").toBool());
  }
#endif
  if (mpSettings->contains("simulation/ignoreCommandLineOptionsAnnotation")) {
    mpSimulationPage->getIgnoreCommandLineOptionsAnnotationCheckBox()->setChecked(mpSettings->value("simulation/ignoreCommandLineOptionsAnnotation").toBool());
  }
  if (mpSettings->contains("simulation/ignoreSimulationFlagsAnnotation")) {
    mpSimulationPage->getIgnoreSimulationFlagsAnnotationCheckBox()->setChecked(mpSettings->value("simulation/ignoreSimulationFlagsAnnotation").toBool());
  }
  if (mpSettings->contains("simulation/saveClassBeforeSimulation")) {
    mpSimulationPage->getSaveClassBeforeSimulationCheckBox()->setChecked(mpSettings->value("simulation/saveClassBeforeSimulation").toBool());
  }
  if (mpSettings->contains("simulation/switchToPlottingPerspectiveAfterSimulation")) {
    mpSimulationPage->getSwitchToPlottingPerspectiveCheckBox()->setChecked(mpSettings->value("simulation/switchToPlottingPerspectiveAfterSimulation").toBool());
  }
  if (mpSettings->contains("simulation/closeSimulationOutputWidgetsBeforeSimulation")) {
    mpSimulationPage->getCloseSimulationOutputWidgetsBeforeSimulationCheckBox()->setChecked(mpSettings->value("simulation/closeSimulationOutputWidgetsBeforeSimulation").toBool());
  }
  if (mpSettings->contains("simulation/deleteIntermediateCompilationFiles")) {
    mpSimulationPage->getDeleteIntermediateCompilationFilesCheckBox()->setChecked(mpSettings->value("simulation/deleteIntermediateCompilationFiles").toBool());
  }
  if (mpSettings->contains("simulation/deleteEntireSimulationDirectory")) {
    mpSimulationPage->getDeleteEntireSimulationDirectoryCheckBox()->setChecked(mpSettings->value("simulation/deleteEntireSimulationDirectory").toBool());
  }
  if (mpSettings->contains("simulation/outputMode")) {
    mpSimulationPage->setOutputMode(mpSettings->value("simulation/outputMode").toString());
  }
  if (mpSettings->contains("simulation/displayLimit")) {
    mpSimulationPage->getDisplayLimitSpinBox()->setValue(mpSettings->value("simulation/displayLimit").toInt());
  }
}
//! Reads the Messages section settings from omedit.ini
void OptionsDialog::readMessagesSettings()
{
  // read output size
  if (mpSettings->contains("messages/outputSize")) {
    mpMessagesPage->getOutputSizeSpinBox()->setValue(mpSettings->value("messages/outputSize").toInt());
  }
  if (mpSettings->contains("messages/resetMessagesNumber")) {
    mpMessagesPage->getResetMessagesNumberBeforeSimulationCheckBox()->setChecked(mpSettings->value("messages/resetMessagesNumber").toBool());
  }
  if (mpSettings->contains("messages/clearMessagesBrowser")) {
    mpMessagesPage->getClearMessagesBrowserBeforeSimulationCheckBox()->setChecked(mpSettings->value("messages/clearMessagesBrowser").toBool());
  }
  // read font family
  if (mpSettings->contains("messages/fontFamily")) {
    int currentIndex;
    // select font family item
    currentIndex = mpMessagesPage->getFontFamilyComboBox()->findText(mpSettings->value("messages/fontFamily").toString(), Qt::MatchExactly);
    mpMessagesPage->getFontFamilyComboBox()->setCurrentIndex(currentIndex);
  }
  // read font size
  if (mpSettings->contains("messages/fontSize")) {
    mpMessagesPage->getFontSizeSpinBox()->setValue(mpSettings->value("messages/fontSize").toDouble());
  }
  // read notification color
  if (mpSettings->contains("messages/notificationColor")) {
    QColor color = QColor(mpSettings->value("messages/notificationColor").toUInt());
    if (color.isValid()) {
      mpMessagesPage->setNotificationColor(color);
      mpMessagesPage->setNotificationPickColorButtonIcon();
    }
  }
  // read warning color
  if (mpSettings->contains("messages/warningColor")) {
    QColor color = QColor(mpSettings->value("messages/warningColor").toUInt());
    if (color.isValid()) {
      mpMessagesPage->setWarningColor(color);
      mpMessagesPage->setWarningPickColorButtonIcon();
    }
  }
  // read error color
  if (mpSettings->contains("messages/errorColor")) {
    QColor color = QColor(mpSettings->value("messages/errorColor").toUInt());
    if (color.isValid()) {
      mpMessagesPage->setErrorColor(color);
      mpMessagesPage->setErrorPickColorButtonIcon();
    }
  }
}

//! Reads the Notifications section settings from omedit.ini
void OptionsDialog::readNotificationsSettings()
{
  if (mpSettings->contains("notifications/promptQuitApplication")) {
    mpNotificationsPage->getQuitApplicationCheckBox()->setChecked(mpSettings->value("notifications/promptQuitApplication").toBool());
  }
  if (mpSettings->contains("notifications/itemDroppedOnItself")) {
    mpNotificationsPage->getItemDroppedOnItselfCheckBox()->setChecked(mpSettings->value("notifications/itemDroppedOnItself").toBool());
  }
  if (mpSettings->contains("notifications/replaceableIfPartial")) {
    mpNotificationsPage->getReplaceableIfPartialCheckBox()->setChecked(mpSettings->value("notifications/replaceableIfPartial").toBool());
  }
  if (mpSettings->contains("notifications/innerModelNameChanged")) {
    mpNotificationsPage->getInnerModelNameChangedCheckBox()->setChecked(mpSettings->value("notifications/innerModelNameChanged").toBool());
  }
  if (mpSettings->contains("notifications/saveModelForBitmapInsertion")) {
    mpNotificationsPage->getSaveModelForBitmapInsertionCheckBox()->setChecked(mpSettings->value("notifications/saveModelForBitmapInsertion").toBool());
  }
  if (mpSettings->contains("notifications/alwaysAskForDraggedComponentName")) {
    mpNotificationsPage->getAlwaysAskForDraggedComponentName()->setChecked(mpSettings->value("notifications/alwaysAskForDraggedComponentName").toBool());
  }
  if (mpSettings->contains("notifications/alwaysAskForTextEditorError")) {
    mpNotificationsPage->getAlwaysAskForTextEditorErrorCheckBox()->setChecked(mpSettings->value("notifications/alwaysAskForTextEditorError").toBool());
  }
  if (mpSettings->contains("notifications/promptOldFrontend")) {
    bool ok;
    int currentIndex = mpNotificationsPage->getOldFrontendComboBox()->findData(mpSettings->value("notifications/promptOldFrontend").toInt(&ok));
    if (currentIndex > -1 && ok) {
      mpNotificationsPage->getOldFrontendComboBox()->setCurrentIndex(currentIndex);
    }
  }
}

//! Reads the LineStyle section settings from omedit.ini
void OptionsDialog::readLineStyleSettings()
{
  if (mpSettings->contains("linestyle/color"))
  {
    QColor color = QColor(mpSettings->value("linestyle/color").toUInt());
    if (color.isValid())
    {
      mpLineStylePage->setLineColor(color);
      mpLineStylePage->setLinePickColorButtonIcon();
    }
  }
  if (mpSettings->contains("linestyle/pattern"))
    mpLineStylePage->setLinePattern(mpSettings->value("linestyle/pattern").toString());
  if (mpSettings->contains("linestyle/thickness"))
    mpLineStylePage->setLineThickness(mpSettings->value("linestyle/thickness").toFloat());
  if (mpSettings->contains("linestyle/startArrow"))
    mpLineStylePage->setLineStartArrow(mpSettings->value("linestyle/startArrow").toString());
  if (mpSettings->contains("linestyle/endArrow"))
    mpLineStylePage->setLineEndArrow(mpSettings->value("linestyle/endArrow").toString());
  if (mpSettings->contains("linestyle/arrowSize"))
    mpLineStylePage->setLineArrowSize(mpSettings->value("linestyle/arrowSize").toFloat());
  if (mpSettings->contains("linestyle/smooth"))
    mpLineStylePage->setLineSmooth(mpSettings->value("linestyle/smooth").toBool());
}

//! Reads the FillStyle section settings from omedit.ini
void OptionsDialog::readFillStyleSettings()
{
  if (mpSettings->contains("fillstyle/color"))
  {
    QColor color = QColor(mpSettings->value("fillstyle/color").toUInt());
    if (color.isValid())
    {
      mpFillStylePage->setFillColor(color);
      mpFillStylePage->setFillPickColorButtonIcon();
    }
  }
  if (mpSettings->contains("fillstyle/pattern"))
    mpFillStylePage->setFillPattern(mpSettings->value("fillstyle/pattern").toString());
}

//! Reads the Plotting section settings from omedit.ini
void OptionsDialog::readPlottingSettings()
{
  // read the auto scale
  if (mpSettings->contains("plotting/autoScale")) {
    mpPlottingPage->getAutoScaleCheckBox()->setChecked(mpSettings->value("plotting/autoScale").toBool());
  }
  // read the prefix units
  if (mpSettings->contains("plotting/prefixUnits")) {
    mpPlottingPage->getPrefixUnitsCheckbox()->setChecked(mpSettings->value("plotting/prefixUnits").toBool());
  }
  // read the plotting view mode
  if (mpSettings->contains("plotting/viewmode")) {
    mpPlottingPage->setPlottingViewMode(mpSettings->value("plotting/viewmode").toString());
  }
  if (mpSettings->contains("curvestyle/pattern")) {
    mpPlottingPage->setCurvePattern(mpSettings->value("curvestyle/pattern").toInt());
  }
  if (mpSettings->contains("curvestyle/thickness")) {
    mpPlottingPage->setCurveThickness(mpSettings->value("curvestyle/thickness").toFloat());
  }
  if (mpSettings->contains("variableFilter/interval")) {
    mpPlottingPage->getFilterIntervalSpinBox()->setValue(mpSettings->value("variableFilter/interval").toInt());
  }
  if (mpSettings->contains("plotting/titleFontSize")) {
    mpPlottingPage->getTitleFontSizeSpinBox()->setValue(mpSettings->value("plotting/titleFontSize").toDouble());
  }
  if (mpSettings->contains("plotting/verticalAxisTitleFontSize")) {
    mpPlottingPage->getVerticalAxisTitleFontSizeSpinBox()->setValue(mpSettings->value("plotting/verticalAxisTitleFontSize").toDouble());
  }
  if (mpSettings->contains("plotting/verticalAxisNumbersFontSize")) {
    mpPlottingPage->getVerticalAxisNumbersFontSizeSpinBox()->setValue(mpSettings->value("plotting/verticalAxisNumbersFontSize").toDouble());
  }
  if (mpSettings->contains("plotting/horizontalAxisTitleFontSize")) {
    mpPlottingPage->getHorizontalAxisTitleFontSizeSpinBox()->setValue(mpSettings->value("plotting/horizontalAxisTitleFontSize").toDouble());
  }
  if (mpSettings->contains("plotting/horizontalAxisNumbersFontSize")) {
    mpPlottingPage->getHorizontalAxisNumbersFontSizeSpinBox()->setValue(mpSettings->value("plotting/horizontalAxisNumbersFontSize").toDouble());
  }
  if (mpSettings->contains("plotting/footerFontSize")) {
    mpPlottingPage->getFooterFontSizeSpinBox()->setValue(mpSettings->value("plotting/footerFontSize").toDouble());
  }
  if (mpSettings->contains("plotting/legendFontSize")) {
    mpPlottingPage->getLegendFontSizeSpinBox()->setValue(mpSettings->value("plotting/legendFontSize").toDouble());
  }
}

//! Reads the Fiagro section settings from omedit.ini
void OptionsDialog::readFigaroSettings()
{
  if (mpSettings->contains("figaro/databasefile")) {
    mpFigaroPage->getFigaroDatabaseFileTextBox()->setText(mpSettings->value("figaro/databasefile").toString());
  }
  if (mpSettings->contains("figaro/options")) {
    mpFigaroPage->getFigaroOptionsTextBox()->setText(mpSettings->value("figaro/options").toString());
  }
  if (mpSettings->contains("figaro/process") && !mpSettings->value("figaro/process").toString().isEmpty()) {
    mpFigaroPage->getFigaroProcessTextBox()->setText(mpSettings->value("figaro/process").toString());
  }
}

/*!
  Reads the Debugger section settings from omedit.ini
  */
void OptionsDialog::readDebuggerSettings()
{
  if (mpSettings->contains("algorithmicDebugger/GDBPath")) {
    mpDebuggerPage->setGDBPath(mpSettings->value("algorithmicDebugger/GDBPath").toString());
  }
  if (mpSettings->contains("algorithmicDebugger/GDBCommandTimeout")) {
    mpDebuggerPage->getGDBCommandTimeoutSpinBox()->setValue(mpSettings->value("algorithmicDebugger/GDBCommandTimeout").toInt());
  }
  if (mpSettings->contains("algorithmicDebugger/GDBOutputLimit")) {
    mpDebuggerPage->getGDBOutputLimitSpinBox()->setValue(mpSettings->value("algorithmicDebugger/GDBOutputLimit").toInt());
  }
  if (mpSettings->contains("algorithmicDebugger/displayCFrames")) {
    mpDebuggerPage->getDisplayCFramesCheckBox()->setChecked(mpSettings->value("algorithmicDebugger/displayCFrames").toBool());
  }
  if (mpSettings->contains("algorithmicDebugger/displayUnknownFrames")) {
    mpDebuggerPage->getDisplayUnknownFramesCheckBox()->setChecked(mpSettings->value("algorithmicDebugger/displayUnknownFrames").toBool());
  }
  if (mpSettings->contains("algorithmicDebugger/clearOutputOnNewRun")) {
    mpDebuggerPage->getClearOutputOnNewRunCheckBox()->setChecked(mpSettings->value("algorithmicDebugger/clearOutputOnNewRun").toBool());
  }
  if (mpSettings->contains("algorithmicDebugger/clearLogOnNewRun")) {
    mpDebuggerPage->getClearLogOnNewRunCheckBox()->setChecked(mpSettings->value("algorithmicDebugger/clearLogOnNewRun").toBool());
  }
  if (mpSettings->contains("transformationalDebugger/alwaysShowTransformationalDebugger")) {
    mpDebuggerPage->getAlwaysShowTransformationsCheckBox()->setChecked(mpSettings->value("transformationalDebugger/alwaysShowTransformationalDebugger").toBool());
  }
  if (mpSettings->contains("transformationalDebugger/generateOperations")) {
    mpDebuggerPage->getGenerateOperationsCheckBox()->setChecked(mpSettings->value("transformationalDebugger/generateOperations").toBool());
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
  }
  if (mpSettings->contains("FMIExport/Type")) {
    mpFMIPage->setFMIExportType(mpSettings->value("FMIExport/Type").toString());
  }
  if (mpSettings->contains("FMIExport/FMUName")) {
    mpFMIPage->getFMUNameTextBox()->setText(mpSettings->value("FMIExport/FMUName").toString());
  }
  if (mpSettings->contains("FMIExport/MoveFMU")) {
    mpFMIPage->getMoveFMUTextBox()->setText(mpSettings->value("FMIExport/MoveFMU").toString());
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
  if (mpSettings->contains("FMIExport/solver")) {
    int currentIndex = mpFMIPage->getSolverForCoSimulationComboBox()->findData(mpSettings->value("FMIExport/solver").toString());
    if (currentIndex > -1) {
      mpFMIPage->getSolverForCoSimulationComboBox()->setCurrentIndex(currentIndex);
    }
  }
  // read model description filter
  if (mpSettings->contains("FMIExport/ModelDescriptionFilter")) {
    int currentIndex = mpFMIPage->getModelDescriptionFiltersComboBox()->findText(mpSettings->value("FMIExport/ModelDescriptionFilter").toString());
    if (currentIndex > -1) {
      mpFMIPage->getModelDescriptionFiltersComboBox()->setCurrentIndex(currentIndex);
    }
  }
  // read include resources
  if (mpSettings->contains("FMIExport/IncludeResources")) {
    mpFMIPage->getIncludeResourcesCheckBox()->setChecked(mpSettings->value("FMIExport/IncludeResources").toBool());
  }
  // read include source code
  if (mpSettings->contains("FMIExport/IncludeSourceCode")) {
    mpFMIPage->getIncludeSourceCodeCheckBox()->setChecked(mpSettings->value("FMIExport/IncludeSourceCode").toBool());
  }
  // read generate debug symbols
  if (mpSettings->contains("FMIExport/GenerateDebugSymbols")) {
    mpFMIPage->getGenerateDebugSymbolsCheckBox()->setChecked(mpSettings->value("FMIExport/GenerateDebugSymbols").toBool());
  }
  // read delete FMU directory
  if (mpSettings->contains("FMIImport/DeleteFMUDirectoyAndModel")) {
    mpFMIPage->getDeleteFMUDirectoryAndModelCheckBox()->setChecked(mpSettings->value("FMIImport/DeleteFMUDirectoyAndModel").toBool());
  }
}

/*!
 * \brief OptionsDialog::readTLMSettings
 * Reads the TLM settings from omedit.ini
 */
void OptionsDialog::readTLMSettings()
{
  // read TLM Path
  if (mpSettings->contains("TLM/PluginPath")) {
    mpTLMPage->getTLMPluginPathTextBox()->setText(mpSettings->value("TLM/PluginPath").toString());
  }
  // read the TLM Manager Process
  if (mpSettings->contains("TLM/ManagerProcess")) {
    mpTLMPage->getTLMManagerProcessTextBox()->setText(mpSettings->value("TLM/ManagerProcess").toString());
  }
  // read TLM Monitor Process
  if (mpSettings->contains("TLM/MonitorProcess")) {
    mpTLMPage->getTLMMonitorProcessTextBox()->setText(mpSettings->value("TLM/MonitorProcess").toString());
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
  }
  // read logging level
  int index;
  if (mpSettings->contains("OMSimulator/loggingLevel")) {
    index = mpOMSimulatorPage->getLoggingLevelComboBox()->findData(mpSettings->value("OMSimulator/loggingLevel").toInt());
    if (index > -1) {
      mpOMSimulatorPage->getLoggingLevelComboBox()->setCurrentIndex(index);
    }
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
  }
  // read user name
  if (mpSettings->contains("traceability/UserName")) {
    mpTraceabilityPage->getUserName()->setText(mpSettings->value("traceability/UserName").toString());
  }
  // read Email
  if (mpSettings->contains("traceability/Email")) {
    mpTraceabilityPage->getEmail()->setText(mpSettings->value("traceability/Email").toString());
  }
  // read Git repository
  if (mpSettings->contains("traceability/GitRepository")) {
    mpTraceabilityPage->getGitRepository()->setText(mpSettings->value("traceability/GitRepository").toString());
  }
  // read the  traceability daemon IP-adress
  if (mpSettings->contains("traceability/IPAdress")) {
    mpTraceabilityPage->getTraceabilityDaemonIpAdress()->setText(mpSettings->value("traceability/IPAdress").toString());
  }
  // read the traceability daemon Port
  if (mpSettings->contains("traceability/Port")) {
    mpTraceabilityPage->getTraceabilityDaemonPort()->setText(mpSettings->value("traceability/Port").toString());
  }
}

//! Saves the General section settings to omedit.ini
void OptionsDialog::saveGeneralSettings()
{
  // save Language option
  QString language;
  if (mpGeneralSettingsPage->getLanguageComboBox()->currentIndex() == 0) {
    language = QLocale::system().name();
  } else {
    language = mpGeneralSettingsPage->getLanguageComboBox()->itemData(mpGeneralSettingsPage->getLanguageComboBox()->currentIndex()).toLocale().name();
  }
  mpSettings->setValue("language", language);
  // save working directory
  MainWindow::instance()->getOMCProxy()->changeDirectory(mpGeneralSettingsPage->getWorkingDirectory());
  mpGeneralSettingsPage->setWorkingDirectory(MainWindow::instance()->getOMCProxy()->changeDirectory());
  mpSettings->setValue("workingDirectory", mpGeneralSettingsPage->getWorkingDirectory());
  // save toolbar icon size
  mpSettings->setValue("toolbarIconSize", mpGeneralSettingsPage->getToolbarIconSizeSpinBox()->value());
  // save user customizations
  mpSettings->setValue("userCustomizations", mpGeneralSettingsPage->getPreserveUserCustomizations());
  // save terminal command
  mpSettings->setValue("terminalCommand", mpGeneralSettingsPage->getTerminalCommand());
  // save terminal command arguments
  mpSettings->setValue("terminalCommandArgs", mpGeneralSettingsPage->getTerminalCommandArguments());
  // save hide variables browser
  mpSettings->setValue("hideVariablesBrowser", mpGeneralSettingsPage->getHideVariablesBrowserCheckBox()->isChecked());
  // save activate access annotations
  mpSettings->setValue("activateAccessAnnotations", mpGeneralSettingsPage->getActivateAccessAnnotationsComboBox()->itemData(mpGeneralSettingsPage->getActivateAccessAnnotationsComboBox()->currentIndex()).toInt());
  // save create backup file
  mpSettings->setValue("createBackupFile", mpGeneralSettingsPage->getCreateBackupFileCheckbox()->isChecked());
  // save library icon size
  mpSettings->setValue("libraryIconSize", mpGeneralSettingsPage->getLibraryIconSizeSpinBox()->value());
  // save the max. text length to show on a library icon
  mpSettings->setValue("libraryIconMaxTextLength", mpGeneralSettingsPage->getLibraryIconTextLengthSpinBox()->value());
  // save show protected classes
  mpSettings->setValue("showProtectedClasses", mpGeneralSettingsPage->getShowProtectedClasses());
  // save show hidden classes
  mpSettings->setValue("showHiddenClasses", mpGeneralSettingsPage->getShowHiddenClasses());
  // show/hide the protected classes
  MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->showHideProtectedClasses();
  // save synchronize with ModelWidget
  mpSettings->setValue("synchronizeWithModelWidget", mpGeneralSettingsPage->getSynchronizeWithModelWidgetCheckBox()->isChecked());
  MainWindow::instance()->getLibraryWidget()->getTreeSearchFilters()->getScrollToActiveButton()->setVisible(!mpGeneralSettingsPage->getSynchronizeWithModelWidgetCheckBox()->isChecked());
  // save auto save
  mpSettings->setValue("autoSave/enable", mpGeneralSettingsPage->getEnableAutoSaveGroupBox()->isChecked());
  mpSettings->setValue("autoSave/interval", mpGeneralSettingsPage->getAutoSaveIntervalSpinBox()->value());
  MainWindow::instance()->getAutoSaveTimer()->setInterval(mpGeneralSettingsPage->getAutoSaveIntervalSpinBox()->value() * 1000);
  MainWindow::instance()->toggleAutoSave();
  // save welcome page
  switch (mpGeneralSettingsPage->getWelcomePageView()) {
    case 2:
      MainWindow::instance()->getWelcomePageWidget()->getSplitter()->setOrientation(Qt::Vertical);
      break;
    case 1:
    default:
      MainWindow::instance()->getWelcomePageWidget()->getSplitter()->setOrientation(Qt::Horizontal);
      break;
  }
  mpSettings->setValue("welcomePage/view", mpGeneralSettingsPage->getWelcomePageView());
  bool showLatestNews = mpGeneralSettingsPage->getShowLatestNewsCheckBox()->isChecked();
  int recentFilesSize = mpSettings->value("welcomePage/recentFilesSize").toInt();
  if ((MainWindow::instance()->getWelcomePageWidget()->getLatestNewsFrame()->isHidden() && showLatestNews) || recentFilesSize != mpGeneralSettingsPage->getRecentFilesAndLatestNewsSizeSpinBox()->value()) {
    MainWindow::instance()->getWelcomePageWidget()->getLatestNewsFrame()->show();
    MainWindow::instance()->getWelcomePageWidget()->addLatestNewsListItems();
  } else if (!showLatestNews) {
    MainWindow::instance()->getWelcomePageWidget()->getLatestNewsFrame()->hide();
  }
  mpSettings->setValue("welcomePage/showLatestNews", showLatestNews);
  // recent files size
  mpSettings->setValue("welcomePage/recentFilesSize", mpGeneralSettingsPage->getRecentFilesAndLatestNewsSizeSpinBox()->value());
  MainWindow::instance()->updateRecentFileActionsAndList();
  // save replaceable support
  mpSettings->setValue("replaceableSupport", mpGeneralSettingsPage->getReplaceableSupport());
  saveNFAPISettings();
}

/*!
 * \brief OptionsDialog::saveNFAPISettings
 */
void OptionsDialog::saveNFAPISettings()
{
  // save nfAPINoise
  mpSettings->setValue("simulation/nfAPINoise", mpGeneralSettingsPage->getDisplayNFAPIErrorsWarningsCheckBox()->isChecked());
  if (mpGeneralSettingsPage->getDisplayNFAPIErrorsWarningsCheckBox()->isChecked()) {
    MainWindow::instance()->getOMCProxy()->setCommandLineOptions("-d=nfAPINoise");
  }
  // save nfAPI
  mpSettings->setValue("simulation/nfAPI", mpGeneralSettingsPage->getEnableNewInstantiationAPICheckBox()->isChecked());
  if (mpGeneralSettingsPage->getEnableNewInstantiationAPICheckBox()->isChecked()) {
    MainWindow::instance()->getOMCProxy()->setCommandLineOptions("-d=nfAPI");
  }
}

//! Saves the Libraries section settings to omedit.ini
void OptionsDialog::saveLibrariesSettings()
{
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
  mpSettings->setValue("forceModelicaLoad", mpLibrariesPage->getForceModelicaLoadCheckBox()->isChecked());
  mpSettings->setValue("loadOpenModelicaOnStartup", mpLibrariesPage->getLoadOpenModelicaLibraryCheckBox()->isChecked());
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
  mpSettings->setValue("textEditor/lineEnding", mpTextEditorPage->getLineEndingComboBox()->itemData(mpTextEditorPage->getLineEndingComboBox()->currentIndex()).toInt());
  mpSettings->setValue("textEditor/bom", mpTextEditorPage->getBOMComboBox()->itemData(mpTextEditorPage->getBOMComboBox()->currentIndex()).toInt());
  mpSettings->setValue("textEditor/tabPolicy", mpTextEditorPage->getTabPolicyComboBox()->itemData(mpTextEditorPage->getTabPolicyComboBox()->currentIndex()).toInt());
  mpSettings->setValue("textEditor/tabSize", mpTextEditorPage->getTabSizeSpinBox()->value());
  mpSettings->setValue("textEditor/indentSize", mpTextEditorPage->getIndentSpinBox()->value());
  mpSettings->setValue("textEditor/enableSyntaxHighlighting", mpTextEditorPage->getSyntaxHighlightingGroupBox()->isChecked());
  mpSettings->setValue("textEditor/enableCodeFolding", mpTextEditorPage->getCodeFoldingCheckBox()->isChecked());
  mpSettings->setValue("textEditor/matchParenthesesCommentsQuotes", mpTextEditorPage->getMatchParenthesesCommentsQuotesCheckBox()->isChecked());
  mpSettings->setValue("textEditor/enableLineWrapping", mpTextEditorPage->getLineWrappingCheckbox()->isChecked());
  mpSettings->setValue("textEditor/fontFamily", mpTextEditorPage->getFontFamilyComboBox()->currentFont().family());
  mpSettings->setValue("textEditor/fontSize", mpTextEditorPage->getFontSizeSpinBox()->value());
  mpSettings->setValue("textEditor/enableAutocomplete", mpTextEditorPage->getAutoCompleteCheckBox()->isChecked());
}

/*!
 * \brief OptionsDialog::saveModelicaEditorSettings
 * Saves the ModelicaEditor settings to omedit.ini
 */
void OptionsDialog::saveModelicaEditorSettings()
{
  mpSettings->setValue("modelicaEditor/preserveTextIndentation", mpModelicaEditorPage->getPreserveTextIndentationCheckBox()->isChecked());
  mpSettings->setValue("modelicaEditor/textRuleColor", mpModelicaEditorPage->getColor("Text").rgba());
  mpSettings->setValue("modelicaEditor/keywordRuleColor", mpModelicaEditorPage->getColor("Keyword").rgba());
  mpSettings->setValue("modelicaEditor/typeRuleColor", mpModelicaEditorPage->getColor("Type").rgba());
  mpSettings->setValue("modelicaEditor/functionRuleColor", mpModelicaEditorPage->getColor("Function").rgba());
  mpSettings->setValue("modelicaEditor/quotesRuleColor", mpModelicaEditorPage->getColor("Quotes").rgba());
  mpSettings->setValue("modelicaEditor/commentRuleColor", mpModelicaEditorPage->getColor("Comment").rgba());
  mpSettings->setValue("modelicaEditor/numberRuleColor", mpModelicaEditorPage->getColor("Number").rgba());
}

/*!
 * \brief OptionsDialog::saveMetaModelicaEditorSettings
 * Saves the MetaModelicaEditor settings to omedit.ini
 */
void OptionsDialog::saveMetaModelicaEditorSettings()
{
  mpSettings->setValue("metaModelicaEditor/textRuleColor", mpMetaModelicaEditorPage->getColor("Text").rgba());
  mpSettings->setValue("metaModelicaEditor/keywordRuleColor", mpMetaModelicaEditorPage->getColor("Keyword").rgba());
  mpSettings->setValue("metaModelicaEditor/typeRuleColor", mpMetaModelicaEditorPage->getColor("Type").rgba());
  mpSettings->setValue("metaModelicaEditor/quotesRuleColor", mpMetaModelicaEditorPage->getColor("Quotes").rgba());
  mpSettings->setValue("metaModelicaEditor/commentRuleColor", mpMetaModelicaEditorPage->getColor("Comment").rgba());
  mpSettings->setValue("metaModelicaEditor/numberRuleColor", mpMetaModelicaEditorPage->getColor("Number").rgba());
}

/*!
 * \brief OptionsDialog::saveCompositeModelEditorSettings
 * Saves the CompositeModelEditor settings to omedit.ini
 */
void OptionsDialog::saveCompositeModelEditorSettings()
{
  mpSettings->setValue("compositeModelEditor/textRuleColor", mpCompositeModelEditorPage->getColor("Text").rgba());
  mpSettings->setValue("compositeModelEditor/commentRuleColor", mpCompositeModelEditorPage->getColor("Comment").rgba());
  mpSettings->setValue("compositeModelEditor/tagRuleColor", mpCompositeModelEditorPage->getColor("Tag").rgba());
  mpSettings->setValue("compositeModelEditor/quotesRuleColor", mpCompositeModelEditorPage->getColor("Quotes").rgba());
  mpSettings->setValue("compositeModelEditor/elementsRuleColor", mpCompositeModelEditorPage->getColor("Element").rgba());
}

/*!
 * \brief OptionsDialog::saveOMSimulatorEditorSettings
 * Saves the OMSimulatorEditor settings to omedit.ini
 */
void OptionsDialog::saveOMSimulatorEditorSettings()
{
  mpSettings->setValue("omsimulatorEditor/textRuleColor", mpOMSimulatorEditorPage->getColor("Text").rgba());
  mpSettings->setValue("omsimulatorEditor/commentRuleColor", mpOMSimulatorEditorPage->getColor("Comment").rgba());
  mpSettings->setValue("omsimulatorEditor/tagRuleColor", mpOMSimulatorEditorPage->getColor("Tag").rgba());
  mpSettings->setValue("omsimulatorEditor/quotesRuleColor", mpOMSimulatorEditorPage->getColor("Quotes").rgba());
  mpSettings->setValue("omsimulatorEditor/elementsRuleColor", mpOMSimulatorEditorPage->getColor("Element").rgba());
}

/*!
 * \brief OptionsDialog::saveCEditorSettings
 * Saves the CEditor settings to omedit.ini
 */
void OptionsDialog::saveCEditorSettings()
{
  mpSettings->setValue("cEditor/textRuleColor", mpCEditorPage->getColor("Text").rgba());
  mpSettings->setValue("cEditor/keywordRuleColor", mpCEditorPage->getColor("Keyword").rgba());
  mpSettings->setValue("cEditor/typeRuleColor", mpCEditorPage->getColor("Type").rgba());
  mpSettings->setValue("cEditor/quotesRuleColor", mpCEditorPage->getColor("Quotes").rgba());
  mpSettings->setValue("cEditor/commentRuleColor", mpCEditorPage->getColor("Comment").rgba());
  mpSettings->setValue("cEditor/numberRuleColor", mpCEditorPage->getColor("Number").rgba());
}

/*!
 * \brief OptionsDialog::saveHTMLEditorSettings
 * Saves the HTMLEditor settings to omedit.ini
 */
void OptionsDialog::saveHTMLEditorSettings()
{
  mpSettings->setValue("HTMLEditor/textRuleColor", mpHTMLEditorPage->getColor("Text").rgba());
  mpSettings->setValue("HTMLEditor/commentRuleColor", mpHTMLEditorPage->getColor("Comment").rgba());
  mpSettings->setValue("HTMLEditor/tagRuleColor", mpHTMLEditorPage->getColor("Tag").rgba());
  mpSettings->setValue("HTMLEditor/quotesRuleColor", mpHTMLEditorPage->getColor("Quotes").rgba());
}

//! Saves the GraphicsViews section settings to omedit.ini
void OptionsDialog::saveGraphicalViewsSettings()
{
  // save modeling view mode
  mpSettings->setValue("modeling/viewmode", mpGraphicalViewsPage->getModelingViewMode());
  if (mpGraphicalViewsPage->getModelingViewMode().compare(Helper::subWindow) == 0) {
    MainWindow::instance()->getModelWidgetContainer()->setViewMode(QMdiArea::SubWindowView);
    ModelWidget *pModelWidget = MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidget();
    if (pModelWidget) {
      pModelWidget->show();
      pModelWidget->setWindowState(Qt::WindowMaximized);
    }
  } else {
    MainWindow::instance()->getModelWidgetContainer()->setViewMode(QMdiArea::TabbedView);
  }
  // save move connectors together
  mpSettings->setValue("modeling/moveConnectorsTogether", mpGraphicalViewsPage->getMoveConnectorsTogetherCheckBox()->isChecked());
  // save default view
  mpSettings->setValue("defaultView", mpGraphicalViewsPage->getDefaultView());
  mpSettings->setValue("iconView/extentLeft", mpGraphicalViewsPage->getIconViewExtentLeft());
  mpSettings->setValue("iconView/extentBottom", mpGraphicalViewsPage->getIconViewExtentBottom());
  mpSettings->setValue("iconView/extentRight", mpGraphicalViewsPage->getIconViewExtentRight());
  mpSettings->setValue("iconView/extentTop", mpGraphicalViewsPage->getIconViewExtentTop());
  mpSettings->setValue("iconView/gridHorizontal", mpGraphicalViewsPage->getIconViewGridHorizontal());
  mpSettings->setValue("iconView/gridVertical", mpGraphicalViewsPage->getIconViewGridVertical());
  mpSettings->setValue("iconView/scaleFactor", mpGraphicalViewsPage->getIconViewScaleFactor());
  mpSettings->setValue("iconView/preserveAspectRatio", mpGraphicalViewsPage->getIconViewPreserveAspectRation());
  mpSettings->setValue("DiagramView/extentLeft", mpGraphicalViewsPage->getDiagramViewExtentLeft());
  mpSettings->setValue("DiagramView/extentBottom", mpGraphicalViewsPage->getDiagramViewExtentBottom());
  mpSettings->setValue("DiagramView/extentRight", mpGraphicalViewsPage->getDiagramViewExtentRight());
  mpSettings->setValue("DiagramView/extentTop", mpGraphicalViewsPage->getDiagramViewExtentTop());
  mpSettings->setValue("DiagramView/gridHorizontal", mpGraphicalViewsPage->getDiagramViewGridHorizontal());
  mpSettings->setValue("DiagramView/gridVertical", mpGraphicalViewsPage->getDiagramViewGridVertical());
  mpSettings->setValue("DiagramView/scaleFactor", mpGraphicalViewsPage->getDiagramViewScaleFactor());
  mpSettings->setValue("DiagramView/preserveAspectRatio", mpGraphicalViewsPage->getDiagramViewPreserveAspectRation());
}

//! Saves the Simulation section settings to omedit.ini
void OptionsDialog::saveSimulationSettings()
{
  // clear command line options before saving new ones
  MainWindow::instance()->getOMCProxy()->clearCommandLineOptions();
  bool changed = false;
  // save matching algorithm
  QString matchingAlgorithm = mpSimulationPage->getTranslationFlagsWidget()->getMatchingAlgorithmComboBox()->currentText();
  if (mpSettings->contains("simulation/matchingAlgorithm")) {
    if (mpSettings->value("simulation/matchingAlgorithm").toString().compare(matchingAlgorithm) != 0) {
      changed = true;
    }
  }
  mpSettings->setValue("simulation/matchingAlgorithm", matchingAlgorithm);
  // save index reduction
  QString indexReduction = mpSimulationPage->getTranslationFlagsWidget()->getIndexReductionMethodComboBox()->currentText();
  if (mpSettings->contains("simulation/indexReductionMethod")) {
    if (mpSettings->value("simulation/indexReductionMethod").toString().compare(indexReduction) != 0) {
      changed = true;
    }
  }
  mpSettings->setValue("simulation/indexReductionMethod", mpSimulationPage->getTranslationFlagsWidget()->getIndexReductionMethodComboBox()->currentText());
  // save initialization
  bool initialization = mpSimulationPage->getTranslationFlagsWidget()->getInitializationCheckBox()->isChecked();
  if (mpSettings->contains("simulation/initialization")) {
    if (mpSettings->value("simulation/initialization").toBool() != initialization) {
      changed = true;
    }
  }
  mpSettings->setValue("simulation/initialization", initialization);
  // save evaluate all parameters
  bool evaluateAllParameters = mpSimulationPage->getTranslationFlagsWidget()->getEvaluateAllParametersCheckBox()->isChecked();
  if (mpSettings->contains("simulation/evaluateAllParameters")) {
    if (mpSettings->value("simulation/evaluateAllParameters").toBool() != evaluateAllParameters) {
      changed = true;
    }
  }
  mpSettings->setValue("simulation/evaluateAllParameters", evaluateAllParameters);
  // save NLS analytic jacobian
  bool NLSanalyticJacobian = mpSimulationPage->getTranslationFlagsWidget()->getNLSanalyticJacobianCheckBox()->isChecked();
  if (mpSettings->contains("simulation/NLSanalyticJacobian")) {
    if (mpSettings->value("simulation/NLSanalyticJacobian").toBool() != NLSanalyticJacobian) {
      changed = true;
    }
  }
  mpSettings->setValue("simulation/NLSanalyticJacobian", NLSanalyticJacobian);
  // save parmodauto
  bool parmodauto = mpSimulationPage->getTranslationFlagsWidget()->getParmodautoCheckBox()->isChecked();
  if (mpSettings->contains("simulation/parmodauto")) {
    if (mpSettings->value("simulation/parmodauto").toBool() != parmodauto) {
      changed = true;
    }
  }
  mpSettings->setValue("simulation/parmodauto", parmodauto);
  // save old instantiation
  bool newInst = !mpSimulationPage->getTranslationFlagsWidget()->getOldInstantiationCheckBox()->isChecked();
  if (mpSettings->contains("simulation/newInst")) {
    if (mpSettings->value("simulation/newInst").toBool() != newInst) {
      changed = true;
    }
  }
  mpSettings->setValue("simulation/newInst", newInst);
  // save command line options
  QString additionalFlags = mpSimulationPage->getTranslationFlagsWidget()->getAdditionalTranslationFlagsTextBox()->text();
  if (mpSimulationPage->getTranslationFlagsWidget()->applyFlags()) {
    if (mpSettings->contains("simulation/OMCFlags")) {
      if (mpSettings->value("simulation/OMCFlags").toString().compare(additionalFlags) != 0) {
        changed = true;
      }
    }
    mpSettings->setValue("simulation/OMCFlags", additionalFlags);
  } else {
    mpSimulationPage->getTranslationFlagsWidget()->getAdditionalTranslationFlagsTextBox()->setText(mpSettings->value("simulation/OMCFlags").toString());
  }
  // save global simulation settings.
  saveGlobalSimulationSettings();
  // save class before simulation.
  mpSettings->setValue("simulation/saveClassBeforeSimulation", mpSimulationPage->getSaveClassBeforeSimulationCheckBox()->isChecked());
  mpSettings->setValue("simulation/switchToPlottingPerspectiveAfterSimulation", mpSimulationPage->getSwitchToPlottingPerspectiveCheckBox()->isChecked());
  mpSettings->setValue("simulation/closeSimulationOutputWidgetsBeforeSimulation", mpSimulationPage->getCloseSimulationOutputWidgetsBeforeSimulationCheckBox()->isChecked());
  mpSettings->setValue("simulation/deleteIntermediateCompilationFiles", mpSimulationPage->getDeleteIntermediateCompilationFilesCheckBox()->isChecked());
  mpSettings->setValue("simulation/deleteEntireSimulationDirectory", mpSimulationPage->getDeleteEntireSimulationDirectoryCheckBox()->isChecked());
  mpSettings->setValue("simulation/outputMode", mpSimulationPage->getOutputMode());
  mpSettings->setValue("simulation/displayLimit", mpSimulationPage->getDisplayLimitSpinBox()->value());

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
  // save target language
  mpSettings->setValue("simulation/targetLanguage", mpSimulationPage->getTargetLanguageComboBox()->currentText());
  MainWindow::instance()->getOMCProxy()->setCommandLineOptions(QString("--simCodeTarget=%1").arg(mpSimulationPage->getTargetLanguageComboBox()->currentText()));
  // save target build
  QString target = mpSimulationPage->getTargetBuildComboBox()->itemData(mpSimulationPage->getTargetBuildComboBox()->currentIndex()).toString();
  mpSettings->setValue("simulation/targetCompiler", target);
  MainWindow::instance()->getOMCProxy()->setCommandLineOptions(QString("--target=%1").arg(target));
  // save compiler
  QString compiler = mpSimulationPage->getCompilerComboBox()->lineEdit()->text();
  mpSettings->setValue("simulation/compiler", compiler);
  if (compiler.isEmpty()) {
    compiler = mpSimulationPage->getCompilerComboBox()->lineEdit()->placeholderText();
  }
  MainWindow::instance()->getOMCProxy()->setCompiler(compiler);
  // save cxxcompiler
  QString cxxCompiler = mpSimulationPage->getCXXCompilerComboBox()->lineEdit()->text();
  mpSettings->setValue("simulation/cxxCompiler", cxxCompiler);
  if (cxxCompiler.isEmpty()) {
    cxxCompiler = mpSimulationPage->getCXXCompilerComboBox()->lineEdit()->placeholderText();
  }
  MainWindow::instance()->getOMCProxy()->setCXXCompiler(cxxCompiler);
#ifdef Q_OS_WIN
  // static linking
  mpSettings->setValue("simulation/useStaticLinking", mpSimulationPage->getUseStaticLinkingCheckBox()->isChecked());
#endif
  // save ignore command line options
  mpSettings->setValue("simulation/ignoreCommandLineOptionsAnnotation", mpSimulationPage->getIgnoreCommandLineOptionsAnnotationCheckBox()->isChecked());
  if (mpSimulationPage->getIgnoreCommandLineOptionsAnnotationCheckBox()->isChecked()) {
    MainWindow::instance()->getOMCProxy()->setCommandLineOptions("+ignoreCommandLineOptionsAnnotation=true");
  } else {
    MainWindow::instance()->getOMCProxy()->setCommandLineOptions("+ignoreCommandLineOptionsAnnotation=false");
  }
  // save ignore simulation flags
  mpSettings->setValue("simulation/ignoreSimulationFlagsAnnotation", mpSimulationPage->getIgnoreSimulationFlagsAnnotationCheckBox()->isChecked());
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
  mpSettings->setValue("messages/outputSize", mpMessagesPage->getOutputSizeSpinBox()->value());
  // save reset messages number
  mpSettings->setValue("messages/resetMessagesNumber", mpMessagesPage->getResetMessagesNumberBeforeSimulationCheckBox()->isChecked());
  // save clear messages browser
  mpSettings->setValue("messages/clearMessagesBrowser", mpMessagesPage->getClearMessagesBrowserBeforeSimulationCheckBox()->isChecked());
  // save font
  mpSettings->setValue("messages/fontFamily", mpMessagesPage->getFontFamilyComboBox()->currentFont().family());
  mpSettings->setValue("messages/fontSize", mpMessagesPage->getFontSizeSpinBox()->value());
  // save notification color
  mpSettings->setValue("messages/notificationColor", mpMessagesPage->getNotificationColor().rgba());
  // save warning color
  mpSettings->setValue("messages/warningColor", mpMessagesPage->getWarningColor().rgba());
  // save error color
  mpSettings->setValue("messages/errorColor", mpMessagesPage->getErrorColor().rgba());
  // apply the above settings to Messages
  MessagesWidget::instance()->applyMessagesSettings();
}

//! Saves the Notifications section settings to omedit.ini
void OptionsDialog::saveNotificationsSettings()
{
  mpSettings->setValue("notifications/promptQuitApplication", mpNotificationsPage->getQuitApplicationCheckBox()->isChecked());
  mpSettings->setValue("notifications/itemDroppedOnItself", mpNotificationsPage->getItemDroppedOnItselfCheckBox()->isChecked());
  mpSettings->setValue("notifications/replaceableIfPartial", mpNotificationsPage->getReplaceableIfPartialCheckBox()->isChecked());
  mpSettings->setValue("notifications/innerModelNameChanged", mpNotificationsPage->getInnerModelNameChangedCheckBox()->isChecked());
  mpSettings->setValue("notifications/saveModelForBitmapInsertion", mpNotificationsPage->getSaveModelForBitmapInsertionCheckBox()->isChecked());
  mpSettings->setValue("notifications/alwaysAskForDraggedComponentName", mpNotificationsPage->getAlwaysAskForDraggedComponentName()->isChecked());
  mpSettings->setValue("notifications/alwaysAskForTextEditorError", mpNotificationsPage->getAlwaysAskForTextEditorErrorCheckBox()->isChecked());
  mpSettings->setValue("notifications/promptOldFrontend", mpNotificationsPage->getOldFrontendComboBox()->itemData(mpNotificationsPage->getOldFrontendComboBox()->currentIndex()).toInt());
}

//! Saves the LineStyle section settings to omedit.ini
void OptionsDialog::saveLineStyleSettings()
{
  mpSettings->setValue("linestyle/color", mpLineStylePage->getLineColor().rgba());
  mpSettings->setValue("linestyle/pattern", mpLineStylePage->getLinePattern());
  mpSettings->setValue("linestyle/thickness", mpLineStylePage->getLineThickness());
  mpSettings->setValue("linestyle/startArrow", mpLineStylePage->getLineStartArrow());
  mpSettings->setValue("linestyle/endArrow", mpLineStylePage->getLineEndArrow());
  mpSettings->setValue("linestyle/arrowSize", mpLineStylePage->getLineArrowSize());
  mpSettings->setValue("linestyle/smooth", mpLineStylePage->getLineSmooth());
}

//! Saves the FillStyle section settings to omedit.ini
void OptionsDialog::saveFillStyleSettings()
{
  mpSettings->setValue("fillstyle/color", mpFillStylePage->getFillColor().rgba());
  mpSettings->setValue("fillstyle/pattern", mpFillStylePage->getFillPattern());
}

//! Saves the Plotting section settings to omedit.ini
void OptionsDialog::savePlottingSettings()
{
  // save the auto scale
  mpSettings->setValue("plotting/autoScale", mpPlottingPage->getAutoScaleCheckBox()->isChecked());
  // save the prefix units
  mpSettings->setValue("plotting/prefixUnits", mpPlottingPage->getPrefixUnitsCheckbox()->isChecked());
  // save plotting view mode
  mpSettings->setValue("plotting/viewmode", mpPlottingPage->getPlottingViewMode());
  if (mpPlottingPage->getPlottingViewMode().compare(Helper::subWindow) == 0) {
    MainWindow::instance()->getPlotWindowContainer()->setViewMode(QMdiArea::SubWindowView);
    OMPlot::PlotWindow *pPlotWindow = MainWindow::instance()->getPlotWindowContainer()->getCurrentWindow();
    if (pPlotWindow) {
      pPlotWindow->show();
      pPlotWindow->setWindowState(Qt::WindowMaximized);
    }
  } else {
    MainWindow::instance()->getPlotWindowContainer()->setViewMode(QMdiArea::TabbedView);
  }

  mpSettings->setValue("curvestyle/pattern", mpPlottingPage->getCurvePattern());
  mpSettings->setValue("curvestyle/thickness", mpPlottingPage->getCurveThickness());
  // save variable filter interval
  mpSettings->setValue("variableFilter/interval", mpPlottingPage->getFilterIntervalSpinBox()->value());
  MainWindow::instance()->getVariablesWidget()->getTreeSearchFilters()->getFilterTimer()->setInterval(mpPlottingPage->getFilterIntervalSpinBox()->value() * 1000);
  // save plot font sizes
  mpSettings->setValue("plotting/titleFontSize", mpPlottingPage->getTitleFontSizeSpinBox()->value());
  mpSettings->setValue("plotting/verticalAxisTitleFontSize", mpPlottingPage->getVerticalAxisTitleFontSizeSpinBox()->value());
  mpSettings->setValue("plotting/verticalAxisNumbersFontSize", mpPlottingPage->getVerticalAxisNumbersFontSizeSpinBox()->value());
  mpSettings->setValue("plotting/horizontalAxisTitleFontSize", mpPlottingPage->getHorizontalAxisTitleFontSizeSpinBox()->value());
  mpSettings->setValue("plotting/horizontalAxisNumbersFontSize", mpPlottingPage->getHorizontalAxisNumbersFontSizeSpinBox()->value());
  mpSettings->setValue("plotting/footerFontSize", mpPlottingPage->getFooterFontSizeSpinBox()->value());
  mpSettings->setValue("plotting/legendFontSize", mpPlottingPage->getLegendFontSizeSpinBox()->value());
}

//! Saves the Figaro section settings to omedit.ini
void OptionsDialog::saveFigaroSettings()
{
  mpSettings->setValue("figaro/databasefile", mpFigaroPage->getFigaroDatabaseFileTextBox()->text());
  mpSettings->setValue("figaro/options", mpFigaroPage->getFigaroOptionsTextBox()->text());
  mpSettings->setValue("figaro/process", mpFigaroPage->getFigaroProcessTextBox()->text());
}

/*!
  Saves the Debugger section settings to omedit.ini
  */
void OptionsDialog::saveDebuggerSettings()
{
  mpSettings->beginGroup("algorithmicDebugger");
  mpSettings->setValue("GDBPath", mpDebuggerPage->getGDBPathForSettings());
  mpSettings->setValue("GDBCommandTimeout", mpDebuggerPage->getGDBCommandTimeoutSpinBox()->value());
  mpSettings->setValue("GDBOutputLimit", mpDebuggerPage->getGDBOutputLimitSpinBox()->value());
  mpSettings->setValue("displayCFrames", mpDebuggerPage->getDisplayCFramesCheckBox()->isChecked());
  mpSettings->setValue("displayUnknownFrames", mpDebuggerPage->getDisplayUnknownFramesCheckBox()->isChecked());
  MainWindow::instance()->getStackFramesWidget()->getStackFramesTreeWidget()->updateStackFrames();
  mpSettings->setValue("clearOutputOnNewRun", mpDebuggerPage->getClearOutputOnNewRunCheckBox()->isChecked());
  mpSettings->setValue("clearLogOnNewRun", mpDebuggerPage->getClearLogOnNewRunCheckBox()->isChecked());
  mpSettings->endGroup();
  mpSettings->beginGroup("transformationalDebugger");
  mpSettings->setValue("alwaysShowTransformationalDebugger", mpDebuggerPage->getAlwaysShowTransformationsCheckBox()->isChecked());
  mpSettings->setValue("generateOperations", mpDebuggerPage->getGenerateOperationsCheckBox()->isChecked());
  if (mpDebuggerPage->getGenerateOperationsCheckBox()->isChecked()) {
    MainWindow::instance()->getOMCProxy()->setCommandLineOptions("-d=infoXmlOperations");
  }
  mpSettings->endGroup();
}

/*!
 * \brief OptionsDialog::saveFMISettings
 * Saves the FMI section settings to omedit.ini
 */
void OptionsDialog::saveFMISettings()
{
  mpSettings->setValue("FMIExport/Version", mpFMIPage->getFMIExportVersion());
  mpSettings->setValue("FMIExport/Type", mpFMIPage->getFMIExportType());
  mpSettings->setValue("FMIExport/FMUName", mpFMIPage->getFMUNameTextBox()->text());
  mpSettings->setValue("FMIExport/MoveFMU", mpFMIPage->getMoveFMUTextBox()->text());
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
  mpSettings->setValue("FMIExport/solver", mpFMIPage->getSolverForCoSimulationComboBox()->itemData(mpFMIPage->getSolverForCoSimulationComboBox()->currentIndex()).toString());
  mpSettings->setValue("FMIExport/ModelDescriptionFilter", mpFMIPage->getModelDescriptionFiltersComboBox()->currentText());
  mpSettings->setValue("FMIExport/IncludeResources", mpFMIPage->getIncludeResourcesCheckBox()->isChecked());
  mpSettings->setValue("FMIExport/IncludeSourceCode", mpFMIPage->getIncludeSourceCodeCheckBox()->isChecked());
  mpSettings->setValue("FMIExport/GenerateDebugSymbols", mpFMIPage->getGenerateDebugSymbolsCheckBox()->isChecked());
  mpSettings->setValue("FMIImport/DeleteFMUDirectoyAndModel", mpFMIPage->getDeleteFMUDirectoryAndModelCheckBox()->isChecked());
}

/*!
 * \brief OptionsDialog::saveTLMSettings
 * Saves the TLM settings in omedit.ini
 */
void OptionsDialog::saveTLMSettings()
{
  // read TLM Path
  mpSettings->setValue("TLM/PluginPath", mpTLMPage->getTLMPluginPathTextBox()->text());
  // save the TLM Manager Process
  mpSettings->setValue("TLM/ManagerProcess", mpTLMPage->getTLMManagerProcessTextBox()->text());
  // save the TLM Monitor Process
  mpSettings->setValue("TLM/MonitorProcess", mpTLMPage->getTLMMonitorProcessTextBox()->text());
}

/*!
 * \brief OptionsDialog::saveOMSimulatorSettings
 * Saves the OMSimulator settings in omedit.ini
 */
void OptionsDialog::saveOMSimulatorSettings()
{
  // set command line options
  mpSettings->setValue("OMSimulator/commandLineOptions", mpOMSimulatorPage->getCommandLineOptionsTextBox()->text());
  // first clear all the command line options and then set the new
  OMSProxy::instance()->setCommandLineOption("--clearAllOptions");
  OMSProxy::instance()->setCommandLineOption(mpOMSimulatorPage->getCommandLineOptionsTextBox()->text());
  // set working directory
  OMSProxy::instance()->setWorkingDirectory(mpGeneralSettingsPage->getWorkingDirectory());
  // set logging level
  mpSettings->setValue("OMSimulator/loggingLevel", mpOMSimulatorPage->getLoggingLevelComboBox()->itemData(mpOMSimulatorPage->getLoggingLevelComboBox()->currentIndex()).toInt());
  OMSProxy::instance()->setLoggingLevel(mpOMSimulatorPage->getLoggingLevelComboBox()->itemData(mpOMSimulatorPage->getLoggingLevelComboBox()->currentIndex()).toInt());
}

/*!
 * \brief OptionsDialog::saveTraceabilitySettings
 * Saves the traceability settings in omedit.ini
 */
void OptionsDialog::saveTraceabilitySettings()
{
  // save traceability checkBox
  mpSettings->setValue("traceability/Traceability", mpTraceabilityPage->getTraceabilityGroupBox()->isChecked());
  // save user name
  mpSettings->setValue("traceability/UserName", mpTraceabilityPage->getUserName()->text());
  // save email
  mpSettings->setValue("traceability/Email", mpTraceabilityPage->getEmail()->text());
  // save Git repository
  mpSettings->setValue("traceability/GitRepository", mpTraceabilityPage->getGitRepository()->text());
  // save the traceability daemon IP-Adress
  mpSettings->setValue("traceability/IPAdress", mpTraceabilityPage->getTraceabilityDaemonIpAdress()->text());
  // save the traceability daemon port
  mpSettings->setValue("traceability/Port", mpTraceabilityPage->getTraceabilityDaemonPort()->text());
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
  mpPagesWidgetScrollArea = new QScrollArea;
  mpPagesWidgetScrollArea->setWidgetResizable(true);
  mpPagesWidgetScrollArea->setWidget(mpPagesWidget);
  horizontalLayout->addWidget(mpPagesWidgetScrollArea);
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
  // MetaModelica Editor Item
  QListWidgetItem *pMetaModelicaEditorItem = new QListWidgetItem(mpOptionsList);
  pMetaModelicaEditorItem->setIcon(QIcon(":/Resources/icons/modeltext.svg"));
  pMetaModelicaEditorItem->setText(tr("MetaModelica Editor"));
  // CompositeModel Editor Item
  QListWidgetItem *pCompositeModelEditorItem = new QListWidgetItem(mpOptionsList);
  pCompositeModelEditorItem->setIcon(QIcon(":/Resources/icons/modeltext.svg"));
  pCompositeModelEditorItem->setText(tr("CompositeModel Editor"));
  // SSP Editor Item
  QListWidgetItem *pOMSimulatorEditorItem = new QListWidgetItem(mpOptionsList);
  pOMSimulatorEditorItem->setIcon(QIcon(":/Resources/icons/modeltext.svg"));
  pOMSimulatorEditorItem->setText(tr("SSP Editor"));
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
  // Debugger Item
  QListWidgetItem *pDebuggerItem = new QListWidgetItem(mpOptionsList);
  pDebuggerItem->setIcon(QIcon(":/Resources/icons/debugger.svg"));
  pDebuggerItem->setText(tr("Debugger"));
  // FMI Item
  QListWidgetItem *pFMIItem = new QListWidgetItem(mpOptionsList);
  pFMIItem->setIcon(QIcon(":/Resources/icons/fmi.svg"));
  pFMIItem->setText(tr("FMI"));
  // TLM Item
  QListWidgetItem *pTLMItem = new QListWidgetItem(mpOptionsList);
  pTLMItem->setIcon(QIcon(":/Resources/icons/tlm-icon.svg"));
  pTLMItem->setText(tr("OMTLMSimulator"));
  // OMSimulator Item
  QListWidgetItem *pOMSimulatorItem = new QListWidgetItem(mpOptionsList);
  pOMSimulatorItem->setIcon(QIcon(":/Resources/icons/tlm-icon.svg"));
  pOMSimulatorItem->setText(tr("OMSimulator/SSP"));
  // Traceability Item
  QListWidgetItem *pTraceabilityItem = new QListWidgetItem(mpOptionsList);
  pTraceabilityItem->setIcon(QIcon(":/Resources/icons/traceability.svg"));
  pTraceabilityItem->setText(tr("Traceability"));
}

//! Creates pages for the Options Widget. The pages are created as stacked widget and are mapped with mpOptionsList.
void OptionsDialog::createPages()
{
  mpPagesWidget = new QStackedWidget;
  mpPagesWidget->setContentsMargins(5, 2, 5, 2);
  mpPagesWidget->addWidget(mpGeneralSettingsPage);
  mpPagesWidget->addWidget(mpLibrariesPage);
  mpPagesWidget->addWidget(mpTextEditorPage);
  mpPagesWidget->addWidget(mpModelicaEditorPage);
  mpPagesWidget->addWidget(mpMetaModelicaEditorPage);
  mpPagesWidget->addWidget(mpCompositeModelEditorPage);
  mpPagesWidget->addWidget(mpOMSimulatorEditorPage);
  mpPagesWidget->addWidget(mpCEditorPage);
  mpPagesWidget->addWidget(mpHTMLEditorPage);
  mpPagesWidget->addWidget(mpGraphicalViewsPage);
  mpPagesWidget->addWidget(mpSimulationPage);
  mpPagesWidget->addWidget(mpMessagesPage);
  mpPagesWidget->addWidget(mpNotificationsPage);
  mpPagesWidget->addWidget(mpLineStylePage);
  mpPagesWidget->addWidget(mpFillStylePage);
  mpPagesWidget->addWidget(mpPlottingPage);
  mpPagesWidget->addWidget(mpFigaroPage);
  mpPagesWidget->addWidget(mpDebuggerPage);
  mpPagesWidget->addWidget(mpFMIPage);
  mpPagesWidget->addWidget(mpTLMPage);
  mpPagesWidget->addWidget(mpOMSimulatorPage);
  mpPagesWidget->addWidget(mpTraceabilityPage);
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
  /* ticket:4345 reset the scrollbars to top */
  mpPagesWidgetScrollArea->verticalScrollBar()->setValue(0);
  mpPagesWidgetScrollArea->horizontalScrollBar()->setValue(0);
}

//! Reimplementation of QWidget's reject function. If user reject the settings then set them back to original.
void OptionsDialog::reject()
{
  // read the old settings from the file
  readSettings();
  saveDialogGeometry();
  QDialog::reject();
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

//! Saves the settings to omedit.ini file.
void OptionsDialog::saveSettings()
{
  saveGeneralSettings();
  saveLibrariesSettings();
  saveTextEditorSettings();
  saveModelicaEditorSettings();
  emit modelicaEditorSettingsChanged();
  saveMetaModelicaEditorSettings();
  emit metaModelicaEditorSettingsChanged();
  saveCompositeModelEditorSettings();
  emit compositeModelEditorSettingsChanged();
  saveOMSimulatorEditorSettings();
  emit omsimulatorEditorSettingsChanged();
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
  saveDebuggerSettings();
  saveFMISettings();
  saveTLMSettings();
  saveOMSimulatorSettings();
  saveTraceabilitySettings();
  // emit the signal so that all text editors can set settings & line wrapping mode
  emit textSettingsChanged();
  mpSettings->sync();
  saveDialogGeometry();
  accept();
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
  mpLanguageComboBox = new QComboBox;
  mpLanguageComboBox->addItem(tr("Auto Detected"), "");
  /* Slow sorting, but works using regular Qt functions */
  QMap<QString, QLocale> map;
  map.insert(tr("Chinese").append(" (zh_CN)"), QLocale(QLocale::Chinese));
  map.insert(tr("English").append(" (en)"), QLocale(QLocale::English));
  map.insert(tr("French").append(" (fr)"), QLocale(QLocale::French));
  map.insert(tr("German").append(" (de)"), QLocale(QLocale::German));
  map.insert(tr("Italian").append(" (it)"), QLocale(QLocale::Italian));
  map.insert(tr("Japanese").append(" (ja)"), QLocale(QLocale::Japanese));
  map.insert(tr("Romanian").append(" (ro)"), QLocale(QLocale::Romanian));
  map.insert(tr("Russian").append(" (ru)"), QLocale(QLocale::Russian));
  map.insert(tr("Spanish").append(" (es)"), QLocale(QLocale::Spanish));
  map.insert(tr("Swedish").append(" (sv)"), QLocale(QLocale::Swedish));
  QStringList keys(map.keys());
  keys.sort();
  foreach (const QString &key, keys) {
    QLocale locale = map[key];
    mpLanguageComboBox->addItem(key, locale);
  }
  // Working Directory
  mpWorkingDirectoryLabel = new Label(Helper::workingDirectory);
  mpWorkingDirectoryTextBox = new QLineEdit(MainWindow::instance()->getOMCProxy()->changeDirectory());
  mpWorkingDirectoryBrowseButton = new QPushButton(Helper::browse);
  mpWorkingDirectoryBrowseButton->setAutoDefault(false);
  connect(mpWorkingDirectoryBrowseButton, SIGNAL(clicked()), SLOT(selectWorkingDirectory()));
  // toolbar icon size
  mpToolbarIconSizeLabel = new Label(tr("Toolbar Icon Size: *"));
  mpToolbarIconSizeSpinBox = new QSpinBox;
  mpToolbarIconSizeSpinBox->setMinimum(16); // icons smaller than 16.......naaaaahhhh!!!!!
  mpToolbarIconSizeSpinBox->setValue(24);
  // Store Customizations Option
  mpPreserveUserCustomizations = new QCheckBox(tr("Preserve User's GUI Customizations"));
  mpPreserveUserCustomizations->setChecked(true);
  // terminal command
  mpTerminalCommandLabel = new Label(tr("Terminal Command:"));
  mpTerminalCommandTextBox = new QLineEdit;
#ifdef Q_OS_WIN32
  mpTerminalCommandTextBox->setText("cmd.exe");
#elif defined(Q_OS_MAC)
  mpTerminalCommandTextBox->setText("");
#else
  mpTerminalCommandTextBox->setText("x-terminal-emulator");
#endif
  mpTerminalCommandBrowseButton = new QPushButton(Helper::browse);
  mpTerminalCommandBrowseButton->setAutoDefault(false);
  connect(mpTerminalCommandBrowseButton, SIGNAL(clicked()), SLOT(selectTerminalCommand()));
  // terminal command args
  mpTerminalCommandArgumentsLabel = new Label(tr("Terminal Command Arguments:"));
  mpTerminalCommandArgumentsTextBox = new QLineEdit;
  // hide variables browser checkbox
  mpHideVariablesBrowserCheckBox = new QCheckBox(tr("Hide Variables Browser"));
  mpHideVariablesBrowserCheckBox->setToolTip(tr("Hides the variable browser when switching away from plotting perspective."));
  mpHideVariablesBrowserCheckBox->setChecked(true);
  // activate access annotation
  mpActivateAccessAnnotationsLabel = new Label(tr("Activate Access Annotations *"));
  mpActivateAccessAnnotationsComboBox = new QComboBox;
  QStringList activateAccessAnnotationsDescriptions;
  activateAccessAnnotationsDescriptions << tr("Activates the access annotations even for the non-encrypted libraries.")
                      << tr("Activates the access annotations even if the .mol contains a non-encrypted library.")
                      << tr("Deactivates access annotations except for encrypted libraries.");
  mpActivateAccessAnnotationsComboBox->addItem(tr("Always"), GeneralSettingsPage::Always);
  mpActivateAccessAnnotationsComboBox->addItem(tr("When loading .mol file(s)"), GeneralSettingsPage::Loading);
  mpActivateAccessAnnotationsComboBox->addItem(tr("Never"), GeneralSettingsPage::Never);
  mpActivateAccessAnnotationsComboBox->setCurrentIndex(1);
  Utilities::setToolTip(mpActivateAccessAnnotationsComboBox, tr("Options for handling of access annotations"), activateAccessAnnotationsDescriptions);
  // create backup file
  mpCreateBackupFileCheckbox = new QCheckBox(tr("Create a model.bak-mo backup file when deleting a model."));
  mpCreateBackupFileCheckbox->setChecked(true);
  /* Display errors/warnings when new instantiation fails in evaluating graphical annotations */
  mpDisplayNFAPIErrorsWarningsCheckBox = new QCheckBox(tr("Display errors/warnings when instantiating the graphical annotations"));
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
  mpGeneralSettingsGroupBox->setLayout(pGeneralSettingsLayout);
  // Libraries Browser group box
  mpLibrariesBrowserGroupBox = new QGroupBox(tr("Libraries Browser"));
  // library icon size
  mpLibraryIconSizeLabel = new Label(tr("Library Icon Size: *"));
  mpLibraryIconSizeSpinBox = new QSpinBox;
  mpLibraryIconSizeSpinBox->setMinimum(16);
  mpLibraryIconSizeSpinBox->setValue(24);
  // library icon max. text length, value is set later
  mpLibraryIconTextLengthLabel = new Label(tr("Max. Library Icon Text Length to Show: *"));
  mpLibraryIconTextLengthSpinBox = new QSpinBox;
  mpLibraryIconTextLengthSpinBox->setMinimum(0);
  // show protected classes
  mpShowProtectedClasses = new QCheckBox(tr("Show Protected Classes"));
  // show hidden classes
  mpShowHiddenClasses = new QCheckBox(tr("Show Hidden Classes (Ignores the annotation(Protection(access = Access.hide)))"));
  // synchronize Libraries Browser with ModelWidget
  mpSynchronizeWithModelWidgetCheckBox = new QCheckBox(tr("Synchronize with Model Widget"));
  mpSynchronizeWithModelWidgetCheckBox->setChecked(true);
  // Libraries Browser group box layout
  QGridLayout *pLibrariesBrowserLayout = new QGridLayout;
  pLibrariesBrowserLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pLibrariesBrowserLayout->setColumnStretch(1, 1);
  pLibrariesBrowserLayout->addWidget(mpLibraryIconSizeLabel, 0, 0);
  pLibrariesBrowserLayout->addWidget(mpLibraryIconSizeSpinBox, 0, 1);
  pLibrariesBrowserLayout->addWidget(mpLibraryIconTextLengthLabel, 1, 0);
  pLibrariesBrowserLayout->addWidget(mpLibraryIconTextLengthSpinBox, 1, 1);
  pLibrariesBrowserLayout->addWidget(mpShowProtectedClasses, 2, 0, 1, 2);
  pLibrariesBrowserLayout->addWidget(mpShowHiddenClasses, 3, 0, 1, 2);
  pLibrariesBrowserLayout->addWidget(mpSynchronizeWithModelWidgetCheckBox, 4, 0, 1, 2);
  mpLibrariesBrowserGroupBox->setLayout(pLibrariesBrowserLayout);
  // Auto Save
  mpEnableAutoSaveGroupBox = new QGroupBox(tr("Enable Auto Save"));
  mpEnableAutoSaveGroupBox->setToolTip("Auto save feature is experimental. If you encounter unexpected crashes then disable it.");
  mpEnableAutoSaveGroupBox->setCheckable(true);
  mpEnableAutoSaveGroupBox->setChecked(true);
  mpAutoSaveIntervalLabel = new Label(tr("Auto Save Interval:"));
  mpAutoSaveIntervalSpinBox = new QSpinBox;
  mpAutoSaveIntervalSpinBox->setSuffix(tr(" seconds"));
  mpAutoSaveIntervalSpinBox->setRange(60, std::numeric_limits<int>::max());
  mpAutoSaveIntervalSpinBox->setSingleStep(30);
  mpAutoSaveIntervalSpinBox->setValue(300);
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
  QButtonGroup *pWelcomePageViewButtons = new QButtonGroup;
  pWelcomePageViewButtons->addButton(mpHorizontalViewRadioButton);
  pWelcomePageViewButtons->addButton(mpVerticalViewRadioButton);
  // plotting view radio buttons layout
  QHBoxLayout *pWelcomePageViewButtonsLayout = new QHBoxLayout;
  pWelcomePageViewButtonsLayout->addWidget(mpHorizontalViewRadioButton);
  pWelcomePageViewButtonsLayout->addWidget(mpVerticalViewRadioButton);
  // Show/hide latest news checkbox
  mpShowLatestNewsCheckBox = new QCheckBox(tr("Show Latest News"));
  mpShowLatestNewsCheckBox->setChecked(true);
  // Recent files and latest news size
  Label *pRecentFilesAndLatestNewsSizeLabel = new Label(tr("Recent Files and Latest News Size:"));
  mpRecentFilesAndLatestNewsSizeSpinBox = new QSpinBox;
  mpRecentFilesAndLatestNewsSizeSpinBox->setValue(15);
  // Welcome Page layout
  QGridLayout *pWelcomePageGridLayout = new QGridLayout;
  pWelcomePageGridLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pWelcomePageGridLayout->setColumnStretch(1, 1);
  pWelcomePageGridLayout->addLayout(pWelcomePageViewButtonsLayout, 0, 0, 1, 2, Qt::AlignLeft);
  pWelcomePageGridLayout->addWidget(mpShowLatestNewsCheckBox, 1, 0, 1, 2);
  pWelcomePageGridLayout->addWidget(pRecentFilesAndLatestNewsSizeLabel, 2, 0);
  pWelcomePageGridLayout->addWidget(mpRecentFilesAndLatestNewsSizeSpinBox, 2, 1);
  mpWelcomePageGroupBox->setLayout(pWelcomePageGridLayout);

  // Optional Features Box
  mpOptionalFeaturesGroupBox = new QGroupBox(tr("Optional Features"));
  // handle replaceable support
  mpReplaceableSupport = new QCheckBox(tr("Enable Replaceable Support *"));
  //! @todo Remove this once we enable this bydefault in OMC.
  /* Enable new instantiation use in OMC API */
  mpEnableNewInstantiationAPICheckBox = new QCheckBox(tr("Enable new frontend use in the OMC API (faster GUI response)"));
  mpEnableNewInstantiationAPICheckBox->setChecked(true);
  // Optional Features Layout
  QGridLayout *pOptionalFeaturesLayout = new QGridLayout;
  pOptionalFeaturesLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pOptionalFeaturesLayout->addWidget(mpReplaceableSupport, 0, 0);
  pOptionalFeaturesLayout->addWidget(mpEnableNewInstantiationAPICheckBox, 1, 0);
  mpOptionalFeaturesGroupBox->setLayout(pOptionalFeaturesLayout);
  // set the layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addWidget(mpGeneralSettingsGroupBox);
  pMainLayout->addWidget(mpLibrariesBrowserGroupBox);
  pMainLayout->addWidget(mpEnableAutoSaveGroupBox);
  pMainLayout->addWidget(mpWelcomePageGroupBox);
  pMainLayout->addWidget(mpOptionalFeaturesGroupBox);
  setLayout(pMainLayout);
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
  mpWorkingDirectoryTextBox->setText(StringHandler::getExistingDirectory(this, QString("%1 - %2").arg(Helper::applicationName)
                                                                         .arg(Helper::chooseDirectory), NULL));
}

/*!
 * \brief GeneralSettingsPage::selectTerminalCommand
 * Slot activated when mpTerminalCommandBrowseButton clicked signal is raised.
 * Allows user to select a new terminal command.
 */
void GeneralSettingsPage::selectTerminalCommand()
{
  mpTerminalCommandTextBox->setText(StringHandler::getOpenFileName(this, QString("%1 - %2").arg(Helper::applicationName)
                                                                   .arg(Helper::chooseFile), NULL, NULL, NULL));
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
  // system libraries groupbox
  mpSystemLibrariesGroupBox = new QGroupBox(tr("System Libraries *"));
  // system libraries note
  mpSystemLibrariesNoteLabel = new Label(tr("The system libraries are read from the MODELICAPATH and are always read-only."));
  mpSystemLibrariesNoteLabel->setElideMode(Qt::ElideMiddle);
  // MODELICAPATH
  mpModelicaPathLabel = new Label(QString("MODELICAPATH = ").append(Helper::OpenModelicaLibrary));
  mpModelicaPathLabel->setElideMode(Qt::ElideMiddle);
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
  pSystemLibrariesLayout->addWidget(mpModelicaPathLabel, 1, 0);
  pSystemLibrariesLayout->addWidget(mpSystemLibrariesTree, 2, 0);
  pSystemLibrariesLayout->addWidget(mpSystemLibrariesButtonBox, 2, 1);
  mpSystemLibrariesGroupBox->setLayout(pSystemLibrariesLayout);
  // force Modelica load checkbox
  mpForceModelicaLoadCheckBox = new QCheckBox(tr("Force loading of Modelica Standard Library"));
  mpForceModelicaLoadCheckBox->setToolTip(tr("This will make sure that Modelica and ModelicaReference will always load even if user has removed them from the list of system libraries."));
  mpForceModelicaLoadCheckBox->setChecked(true);
  // force Modelica load checkbox
  mpLoadOpenModelicaOnStartupCheckBox = new QCheckBox(tr("Load OpenModelica library on startup"));
  mpLoadOpenModelicaOnStartupCheckBox->setChecked(true);
  // user libraries groupbox
  mpUserLibrariesGroupBox = new QGroupBox(tr("User Libraries *"));
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
  QVBoxLayout *layout = new QVBoxLayout;
  layout->setContentsMargins(0, 0, 0, 0);
  layout->addWidget(mpSystemLibrariesGroupBox);
  layout->addWidget(mpForceModelicaLoadCheckBox);
  layout->addWidget(mpLoadOpenModelicaOnStartupCheckBox);
  layout->addWidget(mpUserLibrariesGroupBox);
  setLayout(layout);
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
  if (mpSystemLibrariesTree->selectedItems().size() > 0)
  {
    mpSystemLibrariesTree->removeItemWidget(mpSystemLibrariesTree->selectedItems().at(0), 0);
    delete mpSystemLibrariesTree->selectedItems().at(0);
  }
}

//! Slot activated when mpEditSystemLibraryButton clicked signal is raised.
//! Opens the AddLibraryWidget in edit mode and pass it the selected tree item.
void LibrariesPage::openEditSystemLibrary()
{
  if (mpSystemLibrariesTree->selectedItems().size() > 0) {
    AddSystemLibraryDialog *pAddSystemLibraryWidget = new AddSystemLibraryDialog(this);
    pAddSystemLibraryWidget->setWindowTitle(QString("%1 - %2").arg(Helper::applicationName, tr("Edit System Library")));
    pAddSystemLibraryWidget->mEditFlag = true;
    int currentIndex = pAddSystemLibraryWidget->mpNameComboBox->findText(mpSystemLibrariesTree->selectedItems().at(0)->text(0), Qt::MatchExactly);
    pAddSystemLibraryWidget->mpNameComboBox->setCurrentIndex(currentIndex);
    pAddSystemLibraryWidget->mpVersionTextBox->setText(mpSystemLibrariesTree->selectedItems().at(0)->text(1));
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
  if (mpUserLibrariesTree->selectedItems().size() > 0)
  {
    mpUserLibrariesTree->removeItemWidget(mpUserLibrariesTree->selectedItems().at(0), 0);
    delete mpUserLibrariesTree->selectedItems().at(0);
  }
}

//! Slot activated when mpEditUserLibraryButton clicked signal is raised.
//! Opens the AddLibraryWidget in edit mode and pass it the selected tree item.
void LibrariesPage::openEditUserLibrary()
{
  if (mpUserLibrariesTree->selectedItems().size() > 0)
  {
    AddUserLibraryDialog *pAddUserLibraryWidget = new AddUserLibraryDialog(this);
    pAddUserLibraryWidget->setWindowTitle(QString("%1 - %2").arg(Helper::applicationName, tr("Edit User Library")));
    pAddUserLibraryWidget->mEditFlag = true;
    pAddUserLibraryWidget->mpPathTextBox->setText(mpUserLibrariesTree->selectedItems().at(0)->text(0));
    int currentIndex = pAddUserLibraryWidget->mpEncodingComboBox->findData(mpUserLibrariesTree->selectedItems().at(0)->text(1));
    if (currentIndex > -1)
      pAddUserLibraryWidget->mpEncodingComboBox->setCurrentIndex(currentIndex);
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
AddSystemLibraryDialog::AddSystemLibraryDialog(LibrariesPage *pLibrariesPage)
  : QDialog(pLibrariesPage), mEditFlag(false)
{
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName, tr("Add System Library")));
  setAttribute(Qt::WA_DeleteOnClose);
  mpLibrariesPage = pLibrariesPage;
  mpNameLabel = new Label(Helper::name);
  mpNameComboBox = new QComboBox;
  foreach (const QString &key, MainWindow::instance()->getOMCProxy()->getAvailableLibraries()) {
    mpNameComboBox->addItem(key, key);
  }

  mpValueLabel = new Label(Helper::version + ":");
  mpVersionTextBox = new QLineEdit("default");
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(addSystemLibrary()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // add buttons
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  QGridLayout *mainLayout = new QGridLayout;
  mainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  mainLayout->addWidget(mpNameLabel, 0, 0);
  mainLayout->addWidget(mpNameComboBox, 0, 1);
  mainLayout->addWidget(mpValueLabel, 1, 0);
  mainLayout->addWidget(mpVersionTextBox, 1, 1);
  mainLayout->addWidget(mpButtonBox, 2, 0, 1, 2, Qt::AlignRight);
  setLayout(mainLayout);
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
 * \brief AddSystemLibraryDialog::addSystemLibrary
 * Slot activated when mpOkButton clicked signal is raised.
 *  Add/Edit the system library in the tree.
 */
void AddSystemLibraryDialog::addSystemLibrary()
{
  // if name text box is empty show error and return
  if (mpNameComboBox->currentText().isEmpty()) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), GUIMessages::getMessage(GUIMessages::ENTER_NAME).arg("a"), Helper::ok);
    return;
  }
  // if value text box is empty show error and return
  if (mpVersionTextBox->text().isEmpty()) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), GUIMessages::getMessage(GUIMessages::ENTER_NAME).arg("the value for a"), Helper::ok);
    return;
  }
  // if user is adding a new library
  if (!mEditFlag) {
    if (nameExists()) {
      QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), GUIMessages::getMessage(GUIMessages::ITEM_ALREADY_EXISTS), Helper::ok);
      return;
    }
    QStringList values;
    values << mpNameComboBox->currentText() << mpVersionTextBox->text();
    mpLibrariesPage->getSystemLibrariesTree()->addTopLevelItem(new QTreeWidgetItem(values));
  } else if (mEditFlag) { // if user is editing old library
    QTreeWidgetItem *pItem = mpLibrariesPage->getSystemLibrariesTree()->selectedItems().at(0);
    if (nameExists(pItem)) {
      QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), GUIMessages::getMessage(GUIMessages::ITEM_ALREADY_EXISTS), Helper::ok);
      return;
    }
    pItem->setText(0, mpNameComboBox->currentText());
    pItem->setText(1, mpVersionTextBox->text());
  }
  accept();
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
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), tr("Please enter the file path."), Helper::ok);
    return;
  }
  // if user is adding a new library
  if (!mEditFlag) {
    if (pathExists()) {
      QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), GUIMessages::getMessage(GUIMessages::ITEM_ALREADY_EXISTS), Helper::ok);
      return;
    }
    QStringList values;
    values << mpPathTextBox->text() << mpEncodingComboBox->itemData(mpEncodingComboBox->currentIndex()).toString();
    mpLibrariesPage->getUserLibrariesTree()->addTopLevelItem(new QTreeWidgetItem(values));
  } else if (mEditFlag) { // if user is editing old library
    QTreeWidgetItem *pItem = mpLibrariesPage->getUserLibrariesTree()->selectedItems().at(0);
    if (pathExists(pItem))
    {
      QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), GUIMessages::getMessage(GUIMessages::ITEM_ALREADY_EXISTS), Helper::ok);
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
  mpLineEndingComboBox = new QComboBox;
  mpLineEndingComboBox->addItem(tr("Windows (CRLF)"), Utilities::CRLFLineEnding);
  mpLineEndingComboBox->addItem(tr("Unix (LF)"), Utilities::LFLineEnding);
#ifndef WIN32
  mpLineEndingComboBox->setCurrentIndex(1);
#endif
  // Byte Order Mark BOM
  mpBOMLabel = new Label(tr("Byte Order Mark (BOM):"));
  mpBOMComboBox = new QComboBox;
  QStringList bomDescriptions;
  bomDescriptions << tr("Always add a BOM when saving a file.")
                  << tr("Save the file with a BOM if it already had one when it was loaded.")
                  << tr("Never write a BOM, possibly deleting a pre-existing one.");
  mpBOMComboBox->addItem(tr("Always Add"), Utilities::AlwaysAddBom);
  mpBOMComboBox->addItem(tr("Keep If Already Present"), Utilities::KeepBom);
  mpBOMComboBox->addItem(tr("Always Delete"), Utilities::AlwaysDeleteBom);
  mpBOMComboBox->setCurrentIndex(1);
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
  mpTabPolicyComboBox = new QComboBox;
  mpTabPolicyComboBox->addItem(tr("Spaces Only"), 0);
  mpTabPolicyComboBox->addItem(tr("Tabs Only"), 1);
  // tab size
  mpTabSizeLabel = new Label(tr("Tab Size:"));
  mpTabSizeSpinBox = new QSpinBox;
  mpTabSizeSpinBox->setRange(1, 20);
  mpTabSizeSpinBox->setValue(4);
  // indent size
  mpIndentSizeLabel = new Label(tr("Indent Size:"));
  mpIndentSpinBox = new QSpinBox;
  mpIndentSpinBox->setRange(1, 20);
  mpIndentSpinBox->setValue(2);
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
  mpSyntaxHighlightingGroupBox->setChecked(true);
  // code folding checkbox
  mpCodeFoldingCheckBox = new QCheckBox(tr("Enable Code Folding"));
  mpCodeFoldingCheckBox->setChecked(true);
  // match parenthesis within comments and quotes
  mpMatchParenthesesCommentsQuotesCheckBox = new QCheckBox(tr("Match Parentheses within Comments and Quotes"));
  // set Syntax Highlighting groupbox layout
  QGridLayout *pSyntaxHighlightingGroupBoxLayout = new QGridLayout;
  pSyntaxHighlightingGroupBoxLayout->addWidget(mpCodeFoldingCheckBox, 0, 0);
  pSyntaxHighlightingGroupBoxLayout->addWidget(mpMatchParenthesesCommentsQuotesCheckBox, 1, 0);
  mpSyntaxHighlightingGroupBox->setLayout(pSyntaxHighlightingGroupBoxLayout);
  // line wrap checkbox
  mpLineWrappingCheckbox = new QCheckBox(tr("Enable Line Wrapping"));
  mpLineWrappingCheckbox->setChecked(true);
  // set Syntax Highlight & Text Wrapping groupbox layout
  QGridLayout *pSyntaxHighlightAndTextWrappingGroupBoxLayout = new QGridLayout;
  pSyntaxHighlightAndTextWrappingGroupBoxLayout->addWidget(mpSyntaxHighlightingGroupBox, 0, 0);
  pSyntaxHighlightAndTextWrappingGroupBoxLayout->addWidget(mpLineWrappingCheckbox, 1, 0);
  mpSyntaxHighlightAndTextWrappingGroupBox->setLayout(pSyntaxHighlightAndTextWrappingGroupBoxLayout);
  // AutoCompleter group box
  mpAutoCompleteGroupBox = new QGroupBox(tr("Autocomplete"));
  // autocompleter checkbox
  mpAutoCompleteCheckBox = new QCheckBox(tr("Enable Autocomplete"));
  mpAutoCompleteCheckBox->setChecked(true);
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
  mpFontSizeSpinBox->setValue(Helper::monospacedFontInfo.pointSizeF());
  mpFontSizeSpinBox->setSingleStep(1);
  // set font groupbox layout
  QGridLayout *pFontGroupBoxLayout = new QGridLayout;
  pFontGroupBoxLayout->addWidget(mpFontFamilyLabel, 0, 0);
  pFontGroupBoxLayout->addWidget(mpFontSizeLabel, 0, 1);
  pFontGroupBoxLayout->addWidget(mpFontFamilyComboBox, 1, 0);
  pFontGroupBoxLayout->addWidget(mpFontSizeSpinBox, 1, 1);
  mpFontGroupBox->setLayout(pFontGroupBoxLayout);
  // set the layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
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
  mpPreserveTextIndentationCheckBox->setChecked(true);
  // code colors widget
  mpCodeColorsWidget = new CodeColorsWidget(this);
  connect(mpCodeColorsWidget, SIGNAL(colorUpdated()), SIGNAL(updatePreview()));
  // Add items to list
  // number (purple)
  new ListWidgetItem("Number", QColor(139, 0, 139), mpCodeColorsWidget->getItemsListWidget());
  // keyword (dark red)
  new ListWidgetItem("Keyword", QColor(139, 0, 0), mpCodeColorsWidget->getItemsListWidget());
  // type (red)
  new ListWidgetItem("Type", QColor(255, 10, 10), mpCodeColorsWidget->getItemsListWidget());
  // function (blue)
  new ListWidgetItem("Function", QColor(0, 0, 255), mpCodeColorsWidget->getItemsListWidget());
  // Quotes (dark green)
  new ListWidgetItem("Quotes", QColor(0, 139, 0), mpCodeColorsWidget->getItemsListWidget());
  // comment (dark green)
  new ListWidgetItem("Comment", QColor(0, 150, 0), mpCodeColorsWidget->getItemsListWidget());
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
  connect(mpOptionsDialog->getTextEditorPage()->getSyntaxHighlightingGroupBox(), SIGNAL(toggled(bool)),
          pModelicaTextHighlighter, SLOT(settingsChanged()));
  connect(mpOptionsDialog->getTextEditorPage()->getMatchParenthesesCommentsQuotesCheckBox(), SIGNAL(toggled(bool)),
          pModelicaTextHighlighter, SLOT(settingsChanged()));
  connect(mpOptionsDialog->getTextEditorPage()->getLineWrappingCheckbox(), SIGNAL(toggled(bool)), this, SLOT(setLineWrapping(bool)));
  // set the layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
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
  new ListWidgetItem("Number", QColor(139, 0, 139), mpCodeColorsWidget->getItemsListWidget());
  // keyword (dark red)
  new ListWidgetItem("Keyword", QColor(139, 0, 0), mpCodeColorsWidget->getItemsListWidget());
  // type (red)
  new ListWidgetItem("Type", QColor(255, 10, 10), mpCodeColorsWidget->getItemsListWidget());
  // Quotes (dark green)
  new ListWidgetItem("Quotes", QColor(0, 139, 0), mpCodeColorsWidget->getItemsListWidget());
  // comment (dark green)
  new ListWidgetItem("Comment", QColor(0, 150, 0), mpCodeColorsWidget->getItemsListWidget());
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
  pMainLayout->setContentsMargins(0, 0, 0, 0);
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
 * \class CompositeModelEditorPage
 * \brief Creates an interface for CompositeModel Text settings.
 */
/*!
 * \brief CompositeModelEditorPage::CompositeModelEditorPage
 * \param pOptionsDialog is the pointer to OptionsDialog
 */
CompositeModelEditorPage::CompositeModelEditorPage(OptionsDialog *pOptionsDialog)
  : QWidget(pOptionsDialog)
{
  mpOptionsDialog = pOptionsDialog;
  // code colors widget
  mpCodeColorsWidget = new CodeColorsWidget(this);
  connect(mpCodeColorsWidget, SIGNAL(colorUpdated()), SIGNAL(updatePreview()));
  // Add items to list
  // tag (blue)
  new ListWidgetItem("Tag", QColor(0, 0, 255), mpCodeColorsWidget->getItemsListWidget());
  // element (blue)
  new ListWidgetItem("Element", QColor(0, 0, 255), mpCodeColorsWidget->getItemsListWidget());
  // quotes (dark red)
  new ListWidgetItem("Quotes", QColor(139, 0, 0), mpCodeColorsWidget->getItemsListWidget());
  // comment (dark green)
  new ListWidgetItem("Comment", QColor(0, 150, 0), mpCodeColorsWidget->getItemsListWidget());
  // preview textbox
  QString previewText;
  previewText.append("<!-- This is a comment. -->\n"
                     "<Model Name=\"model\">\n"
                     "\t<SubModels>\n"
                     "\t\t<SubModel Name=\"submodel\">\n"
                     "\t\t</SubModel>\n"
                     "\t</SubModels>\n"
                     "\t<Connections>\n"
                     "\t\t<Connection From=\"from\" To=\"to\">\n"
                     "\t</Connections>\n"
                     "</Model>\n");
  mpCodeColorsWidget->getPreviewPlainTextEdit()->setPlainText(previewText);
  // highlight preview textbox
  CompositeModelHighlighter *pCompositeModelHighlighter = new CompositeModelHighlighter(this, mpCodeColorsWidget->getPreviewPlainTextEdit());
  connect(this, SIGNAL(updatePreview()), pCompositeModelHighlighter, SLOT(settingsChanged()));
  connect(mpOptionsDialog->getTextEditorPage()->getSyntaxHighlightingGroupBox(), SIGNAL(toggled(bool)),
          pCompositeModelHighlighter, SLOT(settingsChanged()));
  connect(mpOptionsDialog->getTextEditorPage()->getMatchParenthesesCommentsQuotesCheckBox(), SIGNAL(toggled(bool)),
          pCompositeModelHighlighter, SLOT(settingsChanged()));
  connect(mpOptionsDialog->getTextEditorPage()->getLineWrappingCheckbox(), SIGNAL(toggled(bool)), this, SLOT(setLineWrapping(bool)));
  // set the layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->addWidget(mpCodeColorsWidget);
  setLayout(pMainLayout);
}

/*!
 * \brief CompositeModelEditorPage::setColor
 * Sets the color of an item.
 * \param item
 * \param color
 */
void CompositeModelEditorPage::setColor(QString item, QColor color)
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
 * \brief CompositeModelEditorPage::getColor
 * Returns the color of an item.
 * \param item
 * \return
 */
QColor CompositeModelEditorPage::getColor(QString item)
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
 * \brief CompositeModelEditorPage::setLineWrapping
 * Slot activated when mpLineWrappingCheckbox toggled SIGNAL is raised.
 * Sets the mpPreviewPlainTextBox line wrapping mode.
 */
void CompositeModelEditorPage::setLineWrapping(bool enabled)
{
  if (enabled) {
    mpCodeColorsWidget->getPreviewPlainTextEdit()->setLineWrapMode(QPlainTextEdit::WidgetWidth);
  } else {
    mpCodeColorsWidget->getPreviewPlainTextEdit()->setLineWrapMode(QPlainTextEdit::NoWrap);
  }
}

/*!
 * \class OMSimulatorEditorPage
 * \brief Creates an interface for OMS CompositeModel Text settings.
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
  new ListWidgetItem("Tag", QColor(0, 0, 255), mpCodeColorsWidget->getItemsListWidget());
  // element (blue)
  new ListWidgetItem("Element", QColor(0, 0, 255), mpCodeColorsWidget->getItemsListWidget());
  // quotes (dark red)
  new ListWidgetItem("Quotes", QColor(139, 0, 0), mpCodeColorsWidget->getItemsListWidget());
  // comment (dark green)
  new ListWidgetItem("Comment", QColor(0, 150, 0), mpCodeColorsWidget->getItemsListWidget());
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
  pMainLayout->setContentsMargins(0, 0, 0, 0);
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
  new ListWidgetItem("Number", QColor(139, 0, 139), mpCodeColorsWidget->getItemsListWidget());
  // keyword (dark red)
  new ListWidgetItem("Keyword", QColor(139, 0, 0), mpCodeColorsWidget->getItemsListWidget());
  // type (red)
  new ListWidgetItem("Type", QColor(255, 10, 10), mpCodeColorsWidget->getItemsListWidget());
  // Quotes (dark green)
  new ListWidgetItem("Quotes", QColor(0, 139, 0), mpCodeColorsWidget->getItemsListWidget());
  // comment (dark green)
  new ListWidgetItem("Comment", QColor(0, 150, 0), mpCodeColorsWidget->getItemsListWidget());
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
  pMainLayout->setContentsMargins(0, 0, 0, 0);
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
  new ListWidgetItem("Tag", QColor(0, 0, 255), mpCodeColorsWidget->getItemsListWidget());
  // quotes (dark red)
  new ListWidgetItem("Quotes", QColor(139, 0, 0), mpCodeColorsWidget->getItemsListWidget());
  // comment (dark green)
  new ListWidgetItem("Comment", QColor(0, 150, 0), mpCodeColorsWidget->getItemsListWidget());
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
  pMainLayout->setContentsMargins(0, 0, 0, 0);
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
  QButtonGroup *pModelingViewModeButtonGroup = new QButtonGroup;
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
  QButtonGroup *pDefaultViewButtonGroup = new QButtonGroup;
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
  // graphical view tab widget
  QTabWidget *pGraphicalViewsTabWidget = new QTabWidget;
  // Icon View Widget
  QWidget *pIconViewWidget = new QWidget;
  // create Icon View extent points group box
  QGroupBox *pIconViewExtentGroupBox = new QGroupBox(Helper::extent);
  Label *pIconViewLeftLabel = new Label(QString(Helper::left).append(":"));
  mpIconViewLeftSpinBox = new DoubleSpinBox;
  mpIconViewLeftSpinBox->setRange(-std::numeric_limits<double>::max(), std::numeric_limits<double>::max());
  mpIconViewLeftSpinBox->setValue(-100);
  mpIconViewLeftSpinBox->setSingleStep(10);
  Label *pIconViewBottomLabel = new Label(Helper::bottom);
  mpIconViewBottomSpinBox = new DoubleSpinBox;
  mpIconViewBottomSpinBox->setRange(-std::numeric_limits<double>::max(), std::numeric_limits<double>::max());
  mpIconViewBottomSpinBox->setValue(-100);
  mpIconViewBottomSpinBox->setSingleStep(10);
  Label *pIconViewRightLabel = new Label(QString(Helper::right).append(":"));
  mpIconViewRightSpinBox = new DoubleSpinBox;
  mpIconViewRightSpinBox->setRange(-std::numeric_limits<double>::max(), std::numeric_limits<double>::max());
  mpIconViewRightSpinBox->setValue(100);
  mpIconViewRightSpinBox->setSingleStep(10);
  Label *pIconViewTopLabel = new Label(Helper::top);
  mpIconViewTopSpinBox = new DoubleSpinBox;
  mpIconViewTopSpinBox->setRange(-std::numeric_limits<double>::max(), std::numeric_limits<double>::max());
  mpIconViewTopSpinBox->setValue(100);
  mpIconViewTopSpinBox->setSingleStep(10);
  // set the Icon View extent group box layout
  QGridLayout *pIconViewExtentLayout = new QGridLayout;
  pIconViewExtentLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pIconViewExtentLayout->setColumnStretch(1, 1);
  pIconViewExtentLayout->setColumnStretch(3, 1);
  pIconViewExtentLayout->addWidget(pIconViewLeftLabel, 0, 0);
  pIconViewExtentLayout->addWidget(mpIconViewLeftSpinBox, 0, 1);
  pIconViewExtentLayout->addWidget(pIconViewBottomLabel, 0, 2);
  pIconViewExtentLayout->addWidget(mpIconViewBottomSpinBox, 0, 3);
  pIconViewExtentLayout->addWidget(pIconViewRightLabel, 1, 0);
  pIconViewExtentLayout->addWidget(mpIconViewRightSpinBox, 1, 1);
  pIconViewExtentLayout->addWidget(pIconViewTopLabel, 1, 2);
  pIconViewExtentLayout->addWidget(mpIconViewTopSpinBox, 1, 3);
  pIconViewExtentGroupBox->setLayout(pIconViewExtentLayout);
  // create the Icon View grid group box
  QGroupBox *pIconViewGridGroupBox = new QGroupBox(Helper::grid);
  Label *pIconViewGridHorizontalLabel = new Label(QString(Helper::horizontal).append(":"));
  mpIconViewGridHorizontalSpinBox = new DoubleSpinBox;
  mpIconViewGridHorizontalSpinBox->setRange(0, std::numeric_limits<double>::max());
  mpIconViewGridHorizontalSpinBox->setValue(2);
  mpIconViewGridHorizontalSpinBox->setSingleStep(1);
  Label *pIconViewGridVerticalLabel = new Label(QString(Helper::vertical).append(":"));
  mpIconViewGridVerticalSpinBox = new DoubleSpinBox;
  mpIconViewGridVerticalSpinBox->setRange(0, std::numeric_limits<double>::max());
  mpIconViewGridVerticalSpinBox->setValue(2);
  mpIconViewGridVerticalSpinBox->setSingleStep(1);
  // set the Icon View grid group box layout
  QGridLayout *pIconViewGridLayout = new QGridLayout;
  pIconViewGridLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pIconViewGridLayout->setColumnStretch(1, 1);
  pIconViewGridLayout->addWidget(pIconViewGridHorizontalLabel, 0, 0);
  pIconViewGridLayout->addWidget(mpIconViewGridHorizontalSpinBox, 0, 1);
  pIconViewGridLayout->addWidget(pIconViewGridVerticalLabel, 1, 0);
  pIconViewGridLayout->addWidget(mpIconViewGridVerticalSpinBox, 1, 1);
  pIconViewGridGroupBox->setLayout(pIconViewGridLayout);
  // create the Icon View Component group box
  QGroupBox *pIconViewComponentGroupBox = new QGroupBox(Helper::component);
  Label *pIconViewScaleFactorLabel = new Label(Helper::scaleFactor);
  mpIconViewScaleFactorSpinBox = new DoubleSpinBox;
  mpIconViewScaleFactorSpinBox->setRange(0, std::numeric_limits<double>::max());
  mpIconViewScaleFactorSpinBox->setValue(0.1);
  mpIconViewScaleFactorSpinBox->setSingleStep(0.1);
  mpIconViewPreserveAspectRatioCheckBox = new QCheckBox(Helper::preserveAspectRatio);
  mpIconViewPreserveAspectRatioCheckBox->setChecked(true);
  // set the Icon View component group box layout
  QGridLayout *pIconViewComponentLayout = new QGridLayout;
  pIconViewComponentLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pIconViewComponentLayout->setColumnStretch(1, 1);
  pIconViewComponentLayout->addWidget(pIconViewScaleFactorLabel, 0, 0);
  pIconViewComponentLayout->addWidget(mpIconViewScaleFactorSpinBox, 0, 1);
  pIconViewComponentLayout->addWidget(mpIconViewPreserveAspectRatioCheckBox, 1, 0, 1, 2);
  pIconViewComponentGroupBox->setLayout(pIconViewComponentLayout);
  // Icon View Widget Layout
  QVBoxLayout *pIconViewMainLayout = new QVBoxLayout;
  pIconViewMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pIconViewMainLayout->addWidget(pIconViewExtentGroupBox);
  pIconViewMainLayout->addWidget(pIconViewGridGroupBox);
  pIconViewMainLayout->addWidget(pIconViewComponentGroupBox);
  pIconViewWidget->setLayout(pIconViewMainLayout);
  // add Icon View Widget as a tab
  pGraphicalViewsTabWidget->addTab(pIconViewWidget, tr("Icon View"));
  // Digram View Widget
  QWidget *pDiagramViewWidget = new QWidget;
  // create Diagram View extent points group box
  QGroupBox *pDiagramViewExtentGroupBox = new QGroupBox(Helper::extent);
  Label *pDiagramViewLeftLabel = new Label(QString(Helper::left).append(":"));
  mpDiagramViewLeftSpinBox = new DoubleSpinBox;
  mpDiagramViewLeftSpinBox->setRange(-std::numeric_limits<double>::max(), std::numeric_limits<double>::max());
  mpDiagramViewLeftSpinBox->setValue(-100);
  mpDiagramViewLeftSpinBox->setSingleStep(10);
  Label *pDiagramViewBottomLabel = new Label(Helper::bottom);
  mpDiagramViewBottomSpinBox = new DoubleSpinBox;
  mpDiagramViewBottomSpinBox->setRange(-std::numeric_limits<double>::max(), std::numeric_limits<double>::max());
  mpDiagramViewBottomSpinBox->setValue(-100);
  mpDiagramViewBottomSpinBox->setSingleStep(10);
  Label *pDiagramViewRightLabel = new Label(QString(Helper::right).append(":"));
  mpDiagramViewRightSpinBox = new DoubleSpinBox;
  mpDiagramViewRightSpinBox->setRange(-std::numeric_limits<double>::max(), std::numeric_limits<double>::max());
  mpDiagramViewRightSpinBox->setValue(100);
  mpDiagramViewRightSpinBox->setSingleStep(10);
  Label *pDiagramViewTopLabel = new Label(Helper::top);
  mpDiagramViewTopSpinBox = new DoubleSpinBox;
  mpDiagramViewTopSpinBox->setRange(-std::numeric_limits<double>::max(), std::numeric_limits<double>::max());
  mpDiagramViewTopSpinBox->setValue(100);
  mpDiagramViewTopSpinBox->setSingleStep(10);
  // set the Diagram View extent group box layout
  QGridLayout *pDiagramViewExtentLayout = new QGridLayout;
  pDiagramViewExtentLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pDiagramViewExtentLayout->setColumnStretch(1, 1);
  pDiagramViewExtentLayout->setColumnStretch(3, 1);
  pDiagramViewExtentLayout->addWidget(pDiagramViewLeftLabel, 0, 0);
  pDiagramViewExtentLayout->addWidget(mpDiagramViewLeftSpinBox, 0, 1);
  pDiagramViewExtentLayout->addWidget(pDiagramViewBottomLabel, 0, 2);
  pDiagramViewExtentLayout->addWidget(mpDiagramViewBottomSpinBox, 0, 3);
  pDiagramViewExtentLayout->addWidget(pDiagramViewRightLabel, 1, 0);
  pDiagramViewExtentLayout->addWidget(mpDiagramViewRightSpinBox, 1, 1);
  pDiagramViewExtentLayout->addWidget(pDiagramViewTopLabel, 1, 2);
  pDiagramViewExtentLayout->addWidget(mpDiagramViewTopSpinBox, 1, 3);
  pDiagramViewExtentGroupBox->setLayout(pDiagramViewExtentLayout);
  // create the Diagram View grid group box
  QGroupBox *pDiagramViewGridGroupBox = new QGroupBox(Helper::grid);
  Label *pDiagramViewGridHorizontalLabel = new Label(QString(Helper::horizontal).append(":"));
  mpDiagramViewGridHorizontalSpinBox = new DoubleSpinBox;
  mpDiagramViewGridHorizontalSpinBox->setRange(0, std::numeric_limits<double>::max());
  mpDiagramViewGridHorizontalSpinBox->setValue(2);
  mpDiagramViewGridHorizontalSpinBox->setSingleStep(1);
  Label *pDiagramViewGridVerticalLabel = new Label(QString(Helper::vertical).append(":"));
  mpDiagramViewGridVerticalSpinBox = new DoubleSpinBox;
  mpDiagramViewGridVerticalSpinBox->setRange(0, std::numeric_limits<double>::max());
  mpDiagramViewGridVerticalSpinBox->setValue(2);
  mpDiagramViewGridVerticalSpinBox->setSingleStep(1);
  // set the Diagram View grid group box layout
  QGridLayout *pDiagramViewGridLayout = new QGridLayout;
  pDiagramViewGridLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pDiagramViewGridLayout->setColumnStretch(1, 1);
  pDiagramViewGridLayout->addWidget(pDiagramViewGridHorizontalLabel, 0, 0);
  pDiagramViewGridLayout->addWidget(mpDiagramViewGridHorizontalSpinBox, 0, 1);
  pDiagramViewGridLayout->addWidget(pDiagramViewGridVerticalLabel, 1, 0);
  pDiagramViewGridLayout->addWidget(mpDiagramViewGridVerticalSpinBox, 1, 1);
  pDiagramViewGridGroupBox->setLayout(pDiagramViewGridLayout);
  // create the Diagram View Component group box
  QGroupBox *pDiagramViewComponentGroupBox = new QGroupBox(Helper::component);
  Label *pDiagramViewScaleFactorLabel = new Label(Helper::scaleFactor);
  mpDiagramViewScaleFactorSpinBox = new DoubleSpinBox;
  mpDiagramViewScaleFactorSpinBox->setRange(0, std::numeric_limits<double>::max());
  mpDiagramViewScaleFactorSpinBox->setValue(0.1);
  mpDiagramViewScaleFactorSpinBox->setSingleStep(0.1);
  mpDiagramViewPreserveAspectRatioCheckBox = new QCheckBox(Helper::preserveAspectRatio);
  mpDiagramViewPreserveAspectRatioCheckBox->setChecked(true);
  // set the Diagram View component group box layout
  QGridLayout *pDiagramViewComponentLayout = new QGridLayout;
  pDiagramViewComponentLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pDiagramViewComponentLayout->setColumnStretch(1, 1);
  pDiagramViewComponentLayout->addWidget(pDiagramViewScaleFactorLabel, 0, 0);
  pDiagramViewComponentLayout->addWidget(mpDiagramViewScaleFactorSpinBox, 0, 1);
  pDiagramViewComponentLayout->addWidget(mpDiagramViewPreserveAspectRatioCheckBox, 1, 0, 1, 2);
  pDiagramViewComponentGroupBox->setLayout(pDiagramViewComponentLayout);
  // Diagram View Widget Layout
  QVBoxLayout *pDiagramViewMainLayout = new QVBoxLayout;
  pDiagramViewMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pDiagramViewMainLayout->addWidget(pDiagramViewExtentGroupBox);
  pDiagramViewMainLayout->addWidget(pDiagramViewGridGroupBox);
  pDiagramViewMainLayout->addWidget(pDiagramViewComponentGroupBox);
  pDiagramViewWidget->setLayout(pDiagramViewMainLayout);
  // add Diagram View Widget as a tab
  pGraphicalViewsTabWidget->addTab(pDiagramViewWidget, tr("Diagram View"));
  // Graphics groupbox and layout
  QGroupBox *pGraphicsGroupBox = new QGroupBox(tr("Graphics"));
  QGridLayout *pGraphicsGridLayout = new QGridLayout;
  pGraphicsGridLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pGraphicsGridLayout->addWidget(pGraphicalViewsTabWidget, 0, 0);
  pGraphicsGroupBox->setLayout(pGraphicsGridLayout);
  // set Main Layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addWidget(pGeneralGroupBox);
  pMainLayout->addWidget(pGraphicsGroupBox, 0, Qt::AlignTop);
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
  if (value.compare(Helper::iconView) == 0) {
    mpIconViewRadioButton->setChecked(true);
  } else if (value.compare(Helper::textView) == 0) {
    mpTextViewRadioButton->setChecked(true);
  } else if (value.compare(Helper::documentationView) == 0) {
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
    return Helper::iconView;
  } else if (mpTextViewRadioButton->isChecked()) {
    return Helper::textView;
  } else if (mpDocumentationViewRadioButton->isChecked()) {
    return Helper::documentationView;
  } else {
    return Helper::diagramView;
  }
}

void GraphicalViewsPage::setIconViewExtentLeft(double extentLeft)
{
  mpIconViewLeftSpinBox->setValue(extentLeft);
}

double GraphicalViewsPage::getIconViewExtentLeft()
{
  return mpIconViewLeftSpinBox->value();
}

void GraphicalViewsPage::setIconViewExtentBottom(double extentBottom)
{
  mpIconViewBottomSpinBox->setValue(extentBottom);
}

double GraphicalViewsPage::getIconViewExtentBottom()
{
  return mpIconViewBottomSpinBox->value();
}

void GraphicalViewsPage::setIconViewExtentRight(double extentRight)
{
  mpIconViewRightSpinBox->setValue(extentRight);
}

double GraphicalViewsPage::getIconViewExtentRight()
{
  return mpIconViewRightSpinBox->value();
}

void GraphicalViewsPage::setIconViewExtentTop(double extentTop)
{
  mpIconViewTopSpinBox->setValue(extentTop);
}

double GraphicalViewsPage::getIconViewExtentTop()
{
  return mpIconViewTopSpinBox->value();
}

void GraphicalViewsPage::setIconViewGridHorizontal(double gridHorizontal)
{
  mpIconViewGridHorizontalSpinBox->setValue(gridHorizontal);
}

double GraphicalViewsPage::getIconViewGridHorizontal()
{
  return mpIconViewGridHorizontalSpinBox->value();
}

void GraphicalViewsPage::setIconViewGridVertical(double gridVertical)
{
  mpIconViewGridVerticalSpinBox->setValue(gridVertical);
}

double GraphicalViewsPage::getIconViewGridVertical()
{
  return mpIconViewGridVerticalSpinBox->value();
}

void GraphicalViewsPage::setIconViewScaleFactor(double scaleFactor)
{
  mpIconViewScaleFactorSpinBox->setValue(scaleFactor);
}

double GraphicalViewsPage::getIconViewScaleFactor()
{
  return mpIconViewScaleFactorSpinBox->value();
}

void GraphicalViewsPage::setIconViewPreserveAspectRation(bool preserveAspectRation)
{
  mpIconViewPreserveAspectRatioCheckBox->setChecked(preserveAspectRation);
}

bool GraphicalViewsPage::getIconViewPreserveAspectRation()
{
  return mpIconViewPreserveAspectRatioCheckBox->isChecked();
}

void GraphicalViewsPage::setDiagramViewExtentLeft(double extentLeft)
{
  mpDiagramViewLeftSpinBox->setValue(extentLeft);
}

double GraphicalViewsPage::getDiagramViewExtentLeft()
{
  return mpDiagramViewLeftSpinBox->value();
}

void GraphicalViewsPage::setDiagramViewExtentBottom(double extentBottom)
{
  mpDiagramViewBottomSpinBox->setValue(extentBottom);
}

double GraphicalViewsPage::getDiagramViewExtentBottom()
{
  return mpDiagramViewBottomSpinBox->value();
}

void GraphicalViewsPage::setDiagramViewExtentRight(double extentRight)
{
  mpDiagramViewRightSpinBox->setValue(extentRight);
}

double GraphicalViewsPage::getDiagramViewExtentRight()
{
  return mpDiagramViewRightSpinBox->value();
}

void GraphicalViewsPage::setDiagramViewExtentTop(double extentTop)
{
  mpDiagramViewTopSpinBox->setValue(extentTop);
}

double GraphicalViewsPage::getDiagramViewExtentTop()
{
  return mpDiagramViewTopSpinBox->value();
}

void GraphicalViewsPage::setDiagramViewGridHorizontal(double gridHorizontal)
{
  mpDiagramViewGridHorizontalSpinBox->setValue(gridHorizontal);
}

double GraphicalViewsPage::getDiagramViewGridHorizontal()
{
  return mpDiagramViewGridHorizontalSpinBox->value();
}

void GraphicalViewsPage::setDiagramViewGridVertical(double gridVertical)
{
  mpDiagramViewGridVerticalSpinBox->setValue(gridVertical);
}

double GraphicalViewsPage::getDiagramViewGridVertical()
{
  return mpDiagramViewGridVerticalSpinBox->value();
}

void GraphicalViewsPage::setDiagramViewScaleFactor(double scaleFactor)
{
  mpDiagramViewScaleFactorSpinBox->setValue(scaleFactor);
}

double GraphicalViewsPage::getDiagramViewScaleFactor()
{
  return mpDiagramViewScaleFactorSpinBox->value();
}

void GraphicalViewsPage::setDiagramViewPreserveAspectRation(bool preserveAspectRation)
{
  mpDiagramViewPreserveAspectRatioCheckBox->setChecked(preserveAspectRation);
}

bool GraphicalViewsPage::getDiagramViewPreserveAspectRation()
{
  return mpDiagramViewPreserveAspectRatioCheckBox->isChecked();
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
  mpTargetLanguageComboBox = new QComboBox;
  mpTargetLanguageComboBox->addItems(simCodeTarget.validOptions);
  mpTargetLanguageComboBox->setCurrentIndex(mpTargetLanguageComboBox->findText("C"));
  Utilities::setToolTip(mpTargetLanguageComboBox, simCodeTarget.mainDescription, simCodeTarget.descriptions);
  // Target Build
  mpTargetBuildLabel = new Label(tr("Target Build:"));
  mpTargetBuildComboBox = new QComboBox;
#ifdef Q_OS_WIN
  mpTargetBuildComboBox->addItem("MinGW", "gcc");
  mpTargetBuildComboBox->addItem("Visual Studio (msvc)", "msvc");
  mpTargetBuildComboBox->addItem("Visual Studio 2010 (msvc10)", "msvc10");
  mpTargetBuildComboBox->addItem("Visual Studio 2012 (msvc12)", "msvc12");
  mpTargetBuildComboBox->addItem("Visual Studio 2013 (msvc13)", "msvc13");
  mpTargetBuildComboBox->addItem("Visual Studio 2015 (msvc15)", "msvc15");
  mpTargetBuildComboBox->addItem("Visual Studio 2019 (msvc19)", "msvc19");
#else
  mpTargetBuildComboBox->addItem("GNU Make", "gcc");
#endif
  mpTargetBuildComboBox->addItem("vxworks69", "vxworks69");
  mpTargetBuildComboBox->addItem("debugrt", "debugrt");
  connect(mpTargetBuildComboBox, SIGNAL(currentIndexChanged(int)), SLOT(targetBuildChanged(int)));
  // C Compiler
  mpCompilerLabel = new Label(tr("C Compiler:"));
  mpCompilerComboBox = new QComboBox;
  mpCompilerComboBox->setEditable(true);
  mpCompilerComboBox->addItem("");
  mpCompilerComboBox->addItem("gcc");
#ifdef Q_OS_UNIX
  mpCompilerComboBox->addItem("clang");
#endif
  mpCompilerComboBox->lineEdit()->setPlaceholderText(MainWindow::instance()->getOMCProxy()->getCompiler());
  // CXX Compiler
  mpCXXCompilerLabel = new Label(tr("CXX Compiler:"));
  mpCXXCompilerComboBox = new QComboBox;
  mpCXXCompilerComboBox->setEditable(true);
  mpCXXCompilerComboBox->addItem("");
  mpCXXCompilerComboBox->addItem("g++");
#ifdef Q_OS_UNIX
  mpCXXCompilerComboBox->addItem("clang++");
#endif
  mpCXXCompilerComboBox->lineEdit()->setPlaceholderText(MainWindow::instance()->getOMCProxy()->getCXXCompiler());
#ifdef Q_OS_WIN
  mpUseStaticLinkingCheckBox = new QCheckBox(tr("Use static Linking"));
  mpUseStaticLinkingCheckBox->setToolTip(tr("Enables static linking for the simulation executable. Default is dynamic linking."));
#endif
  // ignore command line options annotation checkbox
  mpIgnoreCommandLineOptionsAnnotationCheckBox = new QCheckBox(tr("Ignore __OpenModelica_commandLineOptions annotation"));
  // ignore simulation flags annotation checkbox
  mpIgnoreSimulationFlagsAnnotationCheckBox = new QCheckBox(tr("Ignore __OpenModelica_simulationFlags annotation"));
  /* save class before simulation checkbox */
  mpSaveClassBeforeSimulationCheckBox = new QCheckBox(tr("Save class before simulation"));
  mpSaveClassBeforeSimulationCheckBox->setToolTip(tr("Disabling this will effect the debugger functionality."));
  mpSaveClassBeforeSimulationCheckBox->setChecked(true);
  /* switch to plotting perspective after simulation checkbox */
  mpSwitchToPlottingPerspectiveCheckBox = new QCheckBox(tr("Switch to plotting perspective after simulation"));
  mpSwitchToPlottingPerspectiveCheckBox->setChecked(true);
  /* Close completed SimulationOutputWidgets before simulation checkbox */
  mpCloseSimulationOutputWidgetsBeforeSimulationCheckBox = new QCheckBox(tr("Close completed simulation output windows before simulation"));
  mpCloseSimulationOutputWidgetsBeforeSimulationCheckBox->setChecked(true);
  /* Delete intermediate compilation files checkbox */
  mpDeleteIntermediateCompilationFilesCheckBox = new QCheckBox(tr("Delete intermediate compilation files"));
  mpDeleteIntermediateCompilationFilesCheckBox->setChecked(true);
  /* Delete entire simulation directory checkbox */
  mpDeleteEntireSimulationDirectoryCheckBox = new QCheckBox(tr("Delete entire simulation directory of the model when OMEdit is closed"));
  // simulation output format
  mpOutputGroupBox = new QGroupBox(Helper::output);
  mpStructuredRadioButton = new QRadioButton(tr("Structured"));
  mpStructuredRadioButton->setToolTip(tr("Shows the simulation output in the form of tree structure."));
  mpStructuredRadioButton->setChecked(true);
  mpFormattedTextRadioButton = new QRadioButton(tr("Formatted Text"));
  mpFormattedTextRadioButton->setToolTip(tr("Shows the simulation output in the form of formatted text."));
  QButtonGroup *pOutputButtonGroup = new QButtonGroup;
  pOutputButtonGroup->addButton(mpStructuredRadioButton);
  pOutputButtonGroup->addButton(mpFormattedTextRadioButton);
  // output view buttons layout
  QHBoxLayout *pOutputRadioButtonsLayout = new QHBoxLayout;
  pOutputRadioButtonsLayout->addWidget(mpStructuredRadioButton);
  pOutputRadioButtonsLayout->addWidget(mpFormattedTextRadioButton);
  // display limit
  mpDisplayLimitLabel = new Label(tr("Display Limit:"));
  mpDisplayLimitSpinBox = new QSpinBox;
  mpDisplayLimitSpinBox->setSuffix(" KB");
  mpDisplayLimitSpinBox->setRange(1, std::numeric_limits<int>::max());
  mpDisplayLimitSpinBox->setSingleStep(100);
  mpDisplayLimitSpinBox->setValue(500);
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
  pLayout->setContentsMargins(0, 0, 0, 0);
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
  mpOutputSizeLabel->setToolTip(tr("Specifies the maximum number of rows the Messages Browser may have. "
                                   "If there are more rows then the rows are removed from the beginning."));
  mpOutputSizeSpinBox = new QSpinBox;
  mpOutputSizeSpinBox->setRange(0, std::numeric_limits<int>::max());
  mpOutputSizeSpinBox->setSingleStep(1000);
  mpOutputSizeSpinBox->setSuffix(" rows");
  mpOutputSizeSpinBox->setSpecialValueText(Helper::unlimited);
  // reset messages number before simulation
  mpResetMessagesNumberBeforeSimulationCheckBox = new QCheckBox(tr("Reset messages number before checking, instantiation && simulation"));
  mpResetMessagesNumberBeforeSimulationCheckBox->setChecked(true);
  // clear messages browser before simulation
  mpClearMessagesBrowserBeforeSimulationCheckBox = new QCheckBox(tr("Clear messages browser before checking, instantiation && simulation"));
  // set general groupbox layout
  QGridLayout *pGeneralGroupBoxLayout = new QGridLayout;
  pGeneralGroupBoxLayout->setColumnStretch(1, 1);
  pGeneralGroupBoxLayout->addWidget(mpOutputSizeLabel, 0, 0);
  pGeneralGroupBoxLayout->addWidget(mpOutputSizeSpinBox, 0, 1);
  pGeneralGroupBoxLayout->addWidget(mpResetMessagesNumberBeforeSimulationCheckBox, 1, 0, 1, 2);
  pGeneralGroupBoxLayout->addWidget(mpClearMessagesBrowserBeforeSimulationCheckBox, 2, 0, 1, 2);
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
  mpFontSizeSpinBox->setValue(textBrowser.font().pointSizeF());
  mpFontSizeSpinBox->setSingleStep(1);
  // Notification Color
  mpNotificationColorLabel = new Label(tr("Notification Color:"));
  mpNotificationColorButton = new QPushButton(Helper::pickColor);
  mpNotificationColorButton->setAutoDefault(false);
  connect(mpNotificationColorButton, SIGNAL(clicked()), SLOT(pickNotificationColor()));
  setNotificationColor(Qt::black);
  setNotificationPickColorButtonIcon();
  // Warning Color
  mpWarningColorLabel = new Label(tr("Warning Color:"));
  mpWarningColorButton = new QPushButton(Helper::pickColor);
  mpWarningColorButton->setAutoDefault(false);
  connect(mpWarningColorButton, SIGNAL(clicked()), SLOT(pickWarningColor()));
  setWarningColor(QColor(255, 170, 0));
  setWarningPickColorButtonIcon();
  // Error Color
  mpErrorColorLabel = new Label(tr("Error Color:"));
  mpErrorColorButton = new QPushButton(Helper::pickColor);
  mpErrorColorButton->setAutoDefault(false);
  connect(mpErrorColorButton, SIGNAL(clicked()), SLOT(pickErrorColor()));
  setErrorColor(Qt::red);
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
  pMainLayout->setContentsMargins(0, 0, 0, 0);
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
  mpItemDroppedOnItselfCheckBox->setChecked(true);
  // create the replaceable if partial checkbox
  mpReplaceableIfPartialCheckBox = new QCheckBox(tr("Show model is partial and component is added as replaceable message"));
  mpReplaceableIfPartialCheckBox->setChecked(true);
  // create the inner model name changed checkbox
  mpInnerModelNameChangedCheckBox = new QCheckBox(tr("Show component is declared as inner message"));
  mpInnerModelNameChangedCheckBox->setChecked(true);
  // create the save model for bitmap insertion checkbox
  mpSaveModelForBitmapInsertionCheckBox = new QCheckBox(tr("Show save model for bitmap insertion message"));
  mpSaveModelForBitmapInsertionCheckBox->setChecked(true);
  // create the save model for bitmap insertion checkbox
  mpAlwaysAskForDraggedComponentName = new QCheckBox(tr("Always ask for the dragged component name"));
  mpAlwaysAskForDraggedComponentName->setChecked(true);
  // create the always ask for text editor error
  mpAlwaysAskForTextEditorErrorCheckBox = new QCheckBox(tr("Always ask for what to do with the text editor error"));
  mpAlwaysAskForTextEditorErrorCheckBox->setChecked(true);
  // prompt for old frontend
  mpOldFrontendLabel = new Label(tr("If new frontend for code generation fails?"));
  mpOldFrontendComboBox = new QComboBox;
  mpOldFrontendComboBox->addItem(tr("Always ask for old frontend"), NotificationsPage::AlwaysAskForOF);
  mpOldFrontendComboBox->addItem(tr("Try with old frontend once"), NotificationsPage::TryOnceWithOF);
  mpOldFrontendComboBox->addItem(tr("Switch to old frontend permanently"), NotificationsPage::SwitchPermanentlyToOF);
  mpOldFrontendComboBox->addItem(tr("Keep using new frontend"), NotificationsPage::KeepUsingNF);
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
  pNotificationsLayout->addWidget(mpOldFrontendLabel, 7, 0);
  pNotificationsLayout->addWidget(mpOldFrontendComboBox, 7, 1);
  mpNotificationsGroupBox->setLayout(pNotificationsLayout);
  // set the layout
  QVBoxLayout *pLayout = new QVBoxLayout;
  pLayout->setAlignment(Qt::AlignTop);
  pLayout->setContentsMargins(0, 0, 0, 0);
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
  setLineColor(Qt::black);
  setLinePickColorButtonIcon();
  // Line Pattern
  mpLinePatternLabel = new Label(Helper::pattern);
  mpLinePatternComboBox = StringHandler::getLinePatternComboBox();
  setLinePattern(StringHandler::getLinePatternString(StringHandler::LineSolid));
  // Line Thickness
  mpLineThicknessLabel = new Label(Helper::thickness);
  mpLineThicknessSpinBox = new DoubleSpinBox;
  mpLineThicknessSpinBox->setRange(0, std::numeric_limits<double>::max());
  mpLineThicknessSpinBox->setValue(0.25);
  mpLineThicknessSpinBox->setSingleStep(0.25);
  // Line Arrow
  mpLineStartArrowLabel = new Label(Helper::startArrow);
  mpLineStartArrowComboBox = StringHandler::getStartArrowComboBox();
  mpLineEndArrowLabel = new Label(Helper::endArrow);
  mpLineEndArrowComboBox = StringHandler::getEndArrowComboBox();
  mpLineArrowSizeLabel = new Label(Helper::arrowSize);
  mpLineArrowSizeSpinBox = new DoubleSpinBox;
  mpLineArrowSizeSpinBox->setRange(0, std::numeric_limits<double>::max());
  mpLineArrowSizeSpinBox->setValue(3);
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
  pMainLayout->setContentsMargins(0, 0, 0, 0);
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
  mpFillStyleGroupBox = new QGroupBox(Helper::fillStyle);
  // Fill Color
  mpFillColorLabel = new Label(Helper::color);
  mpFillPickColorButton = new QPushButton(Helper::pickColor);
  mpFillPickColorButton->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Preferred);
  mpFillPickColorButton->setAutoDefault(false);
  connect(mpFillPickColorButton, SIGNAL(clicked()), SLOT(fillPickColor()));
  setFillColor(Qt::black);
  setFillPickColorButtonIcon();
  // Fill Pattern
  mpFillPatternLabel = new Label(Helper::pattern);
  mpFillPatternComboBox = StringHandler::getFillPatternComboBox();
  setFillPattern(StringHandler::getFillPatternString(StringHandler::FillNone));
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
  pMainLayout->setContentsMargins(0, 0, 0, 0);
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
  mpAutoScaleCheckBox->setChecked(true);
  mpAutoScaleCheckBox->setToolTip(tr("Auto scale the plot to fit in view when variable is plotted."));
  // prefix units
  mpPrefixUnitsCheckbox = new QCheckBox(tr("Prefix Units"));
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
  QButtonGroup *pPlottingViewModeButtonGroup = new QButtonGroup;
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
  mpCurvePatternComboBox = new QComboBox;
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
  mpCurveThicknessSpinBox->setValue(1);
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
  mpFilterIntervalSpinBox = new QSpinBox;
  mpFilterIntervalSpinBox->setSuffix(tr(" seconds"));
  mpFilterIntervalSpinBox->setRange(0, std::numeric_limits<int>::max());
  mpFilterIntervalSpinBox->setValue(2);
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
  mpTitleFontSizeLabel = new Label("Title:");
  mpTitleFontSizeSpinBox = new DoubleSpinBox;
  mpTitleFontSizeSpinBox->setRange(6, std::numeric_limits<double>::max());
  mpTitleFontSizeSpinBox->setValue(14);
  mpTitleFontSizeSpinBox->setSingleStep(1);
  mpTitleFontSizeSpinBox->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Preferred);
  mpVerticalAxisTitleFontSizeLabel = new Label("Vertical Axis Title:");
  mpVerticalAxisTitleFontSizeSpinBox = new DoubleSpinBox;
  mpVerticalAxisTitleFontSizeSpinBox->setRange(6, std::numeric_limits<double>::max());
  mpVerticalAxisTitleFontSizeSpinBox->setValue(11);
  mpVerticalAxisTitleFontSizeSpinBox->setSingleStep(1);
  mpVerticalAxisNumbersFontSizeLabel = new Label("Vertical Axis Numbers:");
  mpVerticalAxisNumbersFontSizeSpinBox = new DoubleSpinBox;
  mpVerticalAxisNumbersFontSizeSpinBox->setRange(6, std::numeric_limits<double>::max());
  mpVerticalAxisNumbersFontSizeSpinBox->setValue(10);
  mpVerticalAxisNumbersFontSizeSpinBox->setSingleStep(1);
  mpHorizontalAxisTitleFontSizeLabel = new Label("Horizontal Axis Title:");
  mpHorizontalAxisTitleFontSizeSpinBox = new DoubleSpinBox;
  mpHorizontalAxisTitleFontSizeSpinBox->setRange(6, std::numeric_limits<double>::max());
  mpHorizontalAxisTitleFontSizeSpinBox->setValue(11);
  mpHorizontalAxisTitleFontSizeSpinBox->setSingleStep(1);
  mpHorizontalAxisNumbersFontSizeLabel = new Label("Horizontal Axis Numbers:");
  mpHorizontalAxisNumbersFontSizeSpinBox = new DoubleSpinBox;
  mpHorizontalAxisNumbersFontSizeSpinBox->setRange(6, std::numeric_limits<double>::max());
  mpHorizontalAxisNumbersFontSizeSpinBox->setValue(10);
  mpHorizontalAxisNumbersFontSizeSpinBox->setSingleStep(1);
  mpFooterFontSizeLabel = new Label("Footer:");
  mpFooterFontSizeSpinBox = new DoubleSpinBox;
  mpFooterFontSizeSpinBox->setRange(6, std::numeric_limits<double>::max());
  mpFooterFontSizeSpinBox->setValue(QApplication::font().pointSizeF());
  mpFooterFontSizeSpinBox->setSingleStep(1);
  mpLegendFontSizeLabel = new Label("Legend:");
  mpLegendFontSizeSpinBox = new DoubleSpinBox;
  mpLegendFontSizeSpinBox->setRange(6, std::numeric_limits<double>::max());
  mpLegendFontSizeSpinBox->setValue(QApplication::font().pointSizeF());
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
  pMainLayout->setContentsMargins(0, 0, 0, 0);
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
  mFigaroProcessPath = QString(Helper::OpenModelicaHome).append("/share/jEdit4.5_VisualFigaro/VisualFigaro/figp.exe");
  mpFigaroProcessTextBox = new QLineEdit(mFigaroProcessPath);
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
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->addWidget(mpFigaroGroupBox);
  setLayout(pMainLayout);
}

void FigaroPage::browseFigaroLibraryFile()
{
  mpFigaroDatabaseFileTextBox->setText(StringHandler::getOpenFileName(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseFile),
                                                                      NULL, Helper::figaroFileTypes, NULL));
}

void FigaroPage::browseFigaroOptionsFile()
{
  mpFigaroOptionsFileTextBox->setText(StringHandler::getOpenFileName(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseFile),
                                                                     NULL, Helper::xmlFileTypes, NULL));
}

void FigaroPage::browseFigaroProcessFile()
{
  mpFigaroProcessTextBox->setText(StringHandler::getOpenFileName(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseFile),
                                                                 NULL, Helper::exeFileTypes, NULL));
}

/*!
 * \brief FigaroPage::resetFigaroProcessPath
 * Resets the figaro process path to default.
 */
void FigaroPage::resetFigaroProcessPath()
{
  mpFigaroProcessTextBox->setText(mFigaroProcessPath);
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
#ifdef WIN32
  mpGDBPathTextBox->setPlaceholderText(Utilities::getGDBPath());
#else
  mpGDBPathTextBox->setPlaceholderText("gdb");
#endif
  mpGDBPathBrowseButton = new QPushButton(Helper::browse);
  mpGDBPathBrowseButton->setAutoDefault(false);
  connect(mpGDBPathBrowseButton, SIGNAL(clicked()), SLOT(browseGDBPath()));
  /* GDB Command Timeout */
  mpGDBCommandTimeoutLabel = new Label(tr("GDB Command Timeout:"));
  mpGDBCommandTimeoutSpinBox = new QSpinBox;
  mpGDBCommandTimeoutSpinBox->setSuffix(tr(" seconds"));
  mpGDBCommandTimeoutSpinBox->setRange(30, std::numeric_limits<int>::max());
  mpGDBCommandTimeoutSpinBox->setSingleStep(10);
  mpGDBCommandTimeoutSpinBox->setValue(40);
  /* GDB Output limit */
  mpGDBOutputLimitLabel = new Label(tr("GDB Output Limit:"));
  mpGDBOutputLimitSpinBox = new QSpinBox;
  mpGDBOutputLimitSpinBox->setSuffix(tr(" characters"));
  mpGDBOutputLimitSpinBox->setSpecialValueText(Helper::unlimited);
  mpGDBOutputLimitSpinBox->setRange(0, std::numeric_limits<int>::max());
  mpGDBOutputLimitSpinBox->setSingleStep(10);
  // Display C Frames
  mpDisplayCFramesCheckBox = new QCheckBox(tr("Display C frames"));
  mpDisplayCFramesCheckBox->setChecked(true);
  // Display Unknown Frames
  mpDisplayUnknownFramesCheckBox = new QCheckBox(tr("Display unknown frames"));
  mpDisplayUnknownFramesCheckBox->setChecked(true);
  // clear output on new run
  mpClearOutputOnNewRunCheckBox = new QCheckBox(tr("Clear old output on a new run"));
  mpClearOutputOnNewRunCheckBox->setChecked(true);
  // clear log on new run
  mpClearLogOnNewRunCheckBox = new QCheckBox(tr("Clear old log on a new run"));
  mpClearLogOnNewRunCheckBox->setChecked(true);
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
  // set the layout of Transformational Debugger group
  QGridLayout *pTransformationalDebuggerLayout = new QGridLayout;
  pTransformationalDebuggerLayout->setAlignment(Qt::AlignTop);
  pTransformationalDebuggerLayout->addWidget(mpAlwaysShowTransformationsCheckBox, 0, 0);
  pTransformationalDebuggerLayout->addWidget(mpGenerateOperationsCheckBox, 1, 0);
  mpTransformationalDebuggerGroupBox->setLayout(pTransformationalDebuggerLayout);
  // set the layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setAlignment(Qt::AlignTop);
  pMainLayout->setContentsMargins(0, 0, 0, 0);
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
  if (!path.isEmpty()) {
    mpGDBPathTextBox->setText(path);
  }
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
  QString GDBPath = StringHandler::getOpenFileName(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseFile),
                                                   NULL, "", NULL);
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
  dockerPlarforms << "x86_64-linux-gnu docker run --pull=never multiarch/crossbuild"
                  << "i686-linux-gnu docker run --pull=never multiarch/crossbuild"
                  << "x86_64-w64-mingw32 docker run --pull=never multiarch/crossbuild"
                  << "i686-w64-mingw32 docker run --pull=never multiarch/crossbuild"
                  << "arm-linux-gnueabihf docker run --pull=never multiarch/crossbuild"
                  << "aarch64-linux-gnu docker run --pull=never multiarch/crossbuild";
  foreach (QString dockerPlarform, dockerPlarforms) {
    QCheckBox *pCheckBox = new QCheckBox(dockerPlarform);
    pCheckBox->setProperty(Helper::fmuPlatformNamePropertyId, dockerPlarform);
    pPlatformsLayout->addWidget(pCheckBox);
  }
#ifdef WIN32
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
  mpSolverForCoSimulationComboBox = new QComboBox;
  mpSolverForCoSimulationComboBox->addItem(tr("Explicit Euler"), "");
  mpSolverForCoSimulationComboBox->addItem(tr("CVODE"), "cvode");
  // Model description filters
  OMCInterface::getConfigFlagValidOptions_res fmiFilters = MainWindow::instance()->getOMCProxy()->getConfigFlagValidOptions("fmiFilter");
  mpModelDescriptionFiltersComboBox = new QComboBox;
  mpModelDescriptionFiltersComboBox->addItems(fmiFilters.validOptions);
  mpModelDescriptionFiltersComboBox->setCurrentIndex(mpModelDescriptionFiltersComboBox->findText("internal"));
  Utilities::setToolTip(mpModelDescriptionFiltersComboBox, fmiFilters.mainDescription, fmiFilters.descriptions);
  connect(mpModelDescriptionFiltersComboBox, SIGNAL(currentIndexChanged(QString)), SLOT(enableIncludeSourcesCheckBox(QString)));
  // include resources checkbox
  mpIncludeResourcesCheckBox = new QCheckBox(tr("Include Modelica based resources via loadResource"));
  // include source code checkbox
  mpIncludeSourceCodeCheckBox = new QCheckBox(tr("Include Source Code (model description filter \"blackBox\" will override this, because black box FMUs do never contain their source code.)"));
  mpIncludeSourceCodeCheckBox->setChecked(true);
  enableIncludeSourcesCheckBox(mpModelDescriptionFiltersComboBox->currentText());
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
  pMainLayout->setContentsMargins(0, 0, 0, 0);
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
void FMIPage::enableIncludeSourcesCheckBox(QString modelDescriptionFilter)
{
  if (modelDescriptionFilter.compare(QStringLiteral("blackBox")) == 0) {
    mpIncludeSourceCodeCheckBox->setEnabled(false);
  } else {
    mpIncludeSourceCodeCheckBox->setEnabled(true);
  }
}

/*!
 * \class TLMPage
 * Creates an interface for TLM settings.
 */
TLMPage::TLMPage(OptionsDialog *pOptionsDialog)
  : QWidget(pOptionsDialog)
{
  mpOptionsDialog = pOptionsDialog;
  mpGeneralGroupBox = new QGroupBox(Helper::general);
  // TLM Plugin Path
  mpTLMPluginPathLabel = new Label(tr("Path:"));
  mpTLMPluginPathTextBox = new QLineEdit;
  mpTLMPluginPathTextBox->setPlaceholderText(QString("%1/OMTLMSimulator/bin").arg(Helper::OpenModelicaHome));
  mpBrowseTLMPluginPathButton = new QPushButton(Helper::browse);
  mpBrowseTLMPluginPathButton->setAutoDefault(false);
  connect(mpBrowseTLMPluginPathButton, SIGNAL(clicked()), SLOT(browseTLMPluginPath()));
  // TLM Manager Process
  mpTLMManagerProcessLabel = new Label(tr("Manager Process:"));
  mpTLMManagerProcessTextBox = new QLineEdit;
  mpTLMManagerProcessTextBox->setPlaceholderText(QString("%1/OMTLMSimulator/bin/tlmmanager").arg(Helper::OpenModelicaHome));
  mpBrowseTLMManagerProcessButton = new QPushButton(Helper::browse);
  mpBrowseTLMManagerProcessButton->setAutoDefault(false);
  connect(mpBrowseTLMManagerProcessButton, SIGNAL(clicked()), SLOT(browseTLMManagerProcess()));
  // TLM Monitor Process
  mpTLMMonitorProcessLabel = new Label(tr("Monitor Process:"));
  mpTLMMonitorProcessTextBox = new QLineEdit;
  mpTLMMonitorProcessTextBox->setPlaceholderText(QString("%1/OMTLMSimulator/bin/tlmmonitor").arg(Helper::OpenModelicaHome));
  mpBrowseTLMMonitorProcessButton = new QPushButton(Helper::browse);
  mpBrowseTLMMonitorProcessButton->setAutoDefault(false);
  connect(mpBrowseTLMMonitorProcessButton, SIGNAL(clicked()), SLOT(browseTLMMonitorProcess()));
  // set the layout
  QGridLayout *pGeneralGroupBoxLayout = new QGridLayout;
  pGeneralGroupBoxLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pGeneralGroupBoxLayout->addWidget(mpTLMPluginPathLabel, 0, 0);
  pGeneralGroupBoxLayout->addWidget(mpTLMPluginPathTextBox, 0, 1);
  pGeneralGroupBoxLayout->addWidget(mpBrowseTLMPluginPathButton, 0, 2);
  pGeneralGroupBoxLayout->addWidget(mpTLMManagerProcessLabel, 1, 0);
  pGeneralGroupBoxLayout->addWidget(mpTLMManagerProcessTextBox, 1, 1);
  pGeneralGroupBoxLayout->addWidget(mpBrowseTLMManagerProcessButton, 1, 2);
  pGeneralGroupBoxLayout->addWidget(mpTLMMonitorProcessLabel, 3, 0);
  pGeneralGroupBoxLayout->addWidget(mpTLMMonitorProcessTextBox, 3, 1);
  pGeneralGroupBoxLayout->addWidget(mpBrowseTLMMonitorProcessButton, 3, 2);
  pGeneralGroupBoxLayout->addWidget(new Label(tr("* Default OMTLMSimulator paths are used if above field are empty.")), 4, 0, 1, 3);
  mpGeneralGroupBox->setLayout(pGeneralGroupBoxLayout);
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setAlignment(Qt::AlignTop);
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->addWidget(mpGeneralGroupBox);
  setLayout(pMainLayout);
}

/*!
 * \brief TLMPage::getOMTLMSimulatorPath
 * Returns the OMTLMSimulator path.
 * \return
 */
QString TLMPage::getOMTLMSimulatorPath()
{
  if (mpTLMPluginPathTextBox->text().isEmpty()) {
    return mpTLMPluginPathTextBox->placeholderText();
  } else {
    return mpTLMPluginPathTextBox->text();
  }
}

/*!
 * \brief TLMPage::getOMTLMSimulatorManagerPath
 * Returns the OMTLMSimulator manager path.
 * \return
 */
QString TLMPage::getOMTLMSimulatorManagerPath()
{
  if (mpTLMManagerProcessTextBox->text().isEmpty()) {
    return mpTLMManagerProcessTextBox->placeholderText();
  } else {
    return mpTLMManagerProcessTextBox->text();
  }
}

/*!
 * \brief TLMPage::getOMTLMSimulatorMonitorPath
 * Returns the OMTLMSimulator monitor path.
 * \return
 */
QString TLMPage::getOMTLMSimulatorMonitorPath()
{
  if (mpTLMMonitorProcessTextBox->text().isEmpty()) {
    return mpTLMMonitorProcessTextBox->placeholderText();
  } else {
    return mpTLMMonitorProcessTextBox->text();
  }
}

/*!
 * \brief TLMPage::browseTLMPath
 * Browse TLM path.
 */
void TLMPage::browseTLMPluginPath()
{
  QString path = StringHandler::getExistingDirectory(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseDirectory), NULL);
  path = path.replace('\\', '/');
  mpTLMPluginPathTextBox->setText(path);
  if (mpTLMManagerProcessTextBox->text().isEmpty()) {
#ifdef WIN32
    mpTLMManagerProcessTextBox->setText(mpTLMPluginPathTextBox->text() + "/tlmmanager.exe");
#else
    mpTLMManagerProcessTextBox->setText(mpTLMPluginPathTextBox->text() + "/tlmmanager");
#endif
  }
  if (mpTLMMonitorProcessTextBox->text().isEmpty()) {
#ifdef WIN32
    mpTLMMonitorProcessTextBox->setText(mpTLMPluginPathTextBox->text() + "/tlmmonitor.exe");
#else
    mpTLMMonitorProcessTextBox->setText(mpTLMPluginPathTextBox->text() + "/tlmmonitor");
#endif
  }
}

/*!
 * \brief TLMPage::browseTLMManagerProcess
 * Browse TLM Manager Process.
 */
void TLMPage::browseTLMManagerProcess()
{
  mpTLMManagerProcessTextBox->setText(StringHandler::getOpenFileName(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseFile),
                                                                      NULL, Helper::exeFileTypes, NULL));
}

/*!
 * \brief TLMPage::browseTLMMonitorProcess
 * Browse TLM Monitor Process.
 */
void TLMPage::browseTLMMonitorProcess()
{
  mpTLMMonitorProcessTextBox->setText(StringHandler::getOpenFileName(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseFile),
                                                                     NULL, Helper::exeFileTypes, NULL));
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
  mpCommandLineOptionsTextBox = new QLineEdit("--suppressPath=true");
  mpCommandLineOptionsTextBox->setToolTip(tr("Space separated list of command line options e.g., --suppressPath=true --ignoreInitialUnknowns=true"));
  // logging level
  mpLoggingLevelLabel = new Label(tr("Logging Level:"));
  mpLoggingLevelComboBox = new QComboBox;
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
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->addWidget(mpGeneralGroupBox);
  setLayout(pMainLayout);
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
  pMainLayout->setContentsMargins(0, 0, 0, 0);
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
  mpDescriptionLabel = new Label(tr("The global translation flags are changed. The following models have local translation flags. Select which models local translation flags"
                                    " you want to discard. Discard means that the simulation settings of the models will be reset as if you closed OMEdit and restarted"
                                    " a new session. The new global options will first be applied, and then any further setting saved in the annotations will be applied.\n"
                                    "Double click the model to see its existing local translation flags.\n"));
  mpDescriptionLabel->setWordWrap(true);
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
    if (pChildLibraryTreeItem && pChildLibraryTreeItem->getLibraryType() == LibraryTreeItem::Modelica && !pChildLibraryTreeItem->isSystemLibrary()) {
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
