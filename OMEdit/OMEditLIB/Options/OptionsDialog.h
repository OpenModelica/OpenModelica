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

#ifndef OPTIONSDIALOG_H
#define OPTIONSDIALOG_H

#include "Util/Helper.h"
#include "Util/Utilities.h"
#include "Util/StringHandler.h"
#include "Util/DirectoryOrFileSelector.h"

#include <QFontComboBox>
#include <QStackedWidget>
#include <QDialogButtonBox>
#include <QRadioButton>
#include <QTreeWidget>
#include <QDialog>
#include <QLineEdit>

class GeneralSettingsPage;
class LibrariesPage;
class TextEditorPage;
class ModelicaEditorPage;
class MetaModelicaEditorPage;
class CRMLEditorPage;
class MOSEditorPage;
class OMSimulatorEditorPage;
class CEditorPage;
class HTMLEditorPage;
class GraphicalViewsPage;
class SimulationPage;
class MessagesPage;
class NotificationsPage;
class LineStylePage;
class FillStylePage;
class PlottingPage;
class FigaroPage;
class CRMLPage;
class DebuggerPage;
class FMIPage;
class OMSimulatorPage;
class SensitivityOptimizationPage;
class TraceabilityPage;
class TabSettings;
class StackFramesWidget;
class TranslationFlagsWidget;
class LibraryTreeItem;

class OptionsDialog : public QDialog
{
  Q_OBJECT
private:
  // the only class that is allowed to create and destroy
  friend class MainWindow;

  static void create();
  static void destroy();
  OptionsDialog(QWidget *pParent = 0);

  static OptionsDialog *mpInstance;
public:
  static bool isCreated() {return mpInstance != 0;}
  static OptionsDialog* instance() {
    create();
    return mpInstance;
  }
  void readSettings();
  void readGeneralSettings();
  void readLibrariesSettings();
  void readTextEditorSettings();
  void readModelicaEditorSettings();
  void readMOSEditorSettings();
  void readMetaModelicaEditorSettings();
  void readOMSimulatorEditorSettings();
  void readCRMLEditorSettings();
  void readCEditorSettings();
  void readHTMLEditorSettings();
  void readGraphicalViewsSettings();
  void readSimulationSettings();
  void readMessagesSettings();
  void readNotificationsSettings();
  void readLineStyleSettings();
  void readFillStyleSettings();
  void readPlottingSettings();
  void readFigaroSettings();
  void readCRMLSettings();
  void readDebuggerSettings();
  void readFMISettings();
  void readOMSimulatorSettings();
  void readSensitivityOptimizationSettings();
  void readTraceabilitySettings();
  void saveGeneralSettings();
  void saveNFAPISettings();
  void saveLibrariesSettings();
  void saveTextEditorSettings();
  void saveModelicaEditorSettings();
  void saveMOSEditorSettings();
  void saveMetaModelicaEditorSettings();
  void saveOMSimulatorEditorSettings();
  void saveCRMLEditorSettings();
  void saveCEditorSettings();
  void saveHTMLEditorSettings();
  void saveOMSimulatorSettings();
  void saveSensitivityOptimizationSettings();
  void saveTraceabilitySettings();
  void saveGraphicalViewsSettings();
  void saveSimulationSettings();
  void saveGlobalSimulationSettings();
  void saveMessagesSettings();
  void saveNotificationsSettings();
  void saveLineStyleSettings();
  void saveFillStyleSettings();
  void savePlottingSettings();
  void saveFigaroSettings();
  void saveCRMLSettings();
  void saveDebuggerSettings();
  void saveFMISettings();
  void setUpDialog();
  void addListItems();
  void createPages();
  void addPage(QWidget* pPage);
  GeneralSettingsPage* getGeneralSettingsPage() {return mpGeneralSettingsPage;}
  LibrariesPage* getLibrariesPage() {return mpLibrariesPage;}
  TextEditorPage* getTextEditorPage() {return mpTextEditorPage;}
  ModelicaEditorPage* getModelicaEditorPage() {return mpModelicaEditorPage;}
  MetaModelicaEditorPage* getMetaModelicaEditorPage() {return mpMetaModelicaEditorPage;}
  CRMLEditorPage* getCRMLEditorPage() {return mpCRMLEditorPage;}
  MOSEditorPage* getMOSEditorPage() {return mpMOSEditorPage;}
  OMSimulatorEditorPage* getOMSimulatorEditorPage() {return mpOMSimulatorEditorPage;}
  CEditorPage* getCEditorPage() {return mpCEditorPage;}
  HTMLEditorPage* getHTMLEditorPage() {return mpHTMLEditorPage;}
  GraphicalViewsPage* getGraphicalViewsPage() {return mpGraphicalViewsPage;}
  SimulationPage* getSimulationPage() {return mpSimulationPage;}
  MessagesPage* getMessagesPage() {return mpMessagesPage;}
  NotificationsPage* getNotificationsPage() {return mpNotificationsPage;}
  LineStylePage* getLineStylePage() {return mpLineStylePage;}
  FillStylePage* getFillStylePage() {return mpFillStylePage;}
  PlottingPage* getPlottingPage() {return mpPlottingPage;}
  FigaroPage* getFigaroPage() {return mpFigaroPage;}
  CRMLPage* getCRMLPage() {return mpCRMLPage;}
  DebuggerPage* getDebuggerPage() {return mpDebuggerPage;}
  FMIPage* getFMIPage() {return mpFMIPage;}
  OMSimulatorPage* getOMSimulatorPage() {return mpOMSimulatorPage;}
  SensitivityOptimizationPage* getSensitivityOptimizationPage() {return mpSensitivityOptimizationPage;}
  TraceabilityPage* getTraceabilityPage() {return mpTraceabilityPage;}
  void emitModelicaEditorSettingsChanged() {emit modelicaEditorSettingsChanged();}
  void saveDialogGeometry();
  void show();
  TabSettings getTabSettings();
signals:
  void textSettingsChanged();
  void modelicaEditorSettingsChanged();
  void metaModelicaEditorSettingsChanged();
  void crmlEditorSettingsChanged();
  void mosEditorSettingsChanged();
  void omsimulatorEditorSettingsChanged();
  void cEditorSettingsChanged();
  void HTMLEditorSettingsChanged();
public slots:
  void changePage(QListWidgetItem *current, QListWidgetItem *previous);
  void reject() override;
  void saveSettings();
  void reset();
private:
  bool mDetectChange;
  GeneralSettingsPage *mpGeneralSettingsPage;
  LibrariesPage *mpLibrariesPage;
  TextEditorPage *mpTextEditorPage;
  ModelicaEditorPage *mpModelicaEditorPage;
  MOSEditorPage *mpMOSEditorPage;
  MetaModelicaEditorPage *mpMetaModelicaEditorPage;
  OMSimulatorEditorPage *mpOMSimulatorEditorPage;
  CRMLEditorPage *mpCRMLEditorPage;
  CEditorPage *mpCEditorPage;
  HTMLEditorPage *mpHTMLEditorPage;
  GraphicalViewsPage *mpGraphicalViewsPage;
  SimulationPage *mpSimulationPage;
  QString mMatchingAlgorithm;
  QString mIndexReductionMethod;
  bool mInitialization;
  bool mEvaluateAllParameters;
  bool mNLSanalyticJacobian;
  bool mParmodauto;
  bool mOldInstantiation;
  bool mEnableFMUImport;
  QString mAdditionalTranslationFlags;
  MessagesPage *mpMessagesPage;
  NotificationsPage *mpNotificationsPage;
  LineStylePage *mpLineStylePage;
  FillStylePage *mpFillStylePage;
  PlottingPage *mpPlottingPage;
  FigaroPage *mpFigaroPage;
  CRMLPage *mpCRMLPage;
  DebuggerPage *mpDebuggerPage;
  FMIPage *mpFMIPage;
  OMSimulatorPage *mpOMSimulatorPage;
  SensitivityOptimizationPage *mpSensitivityOptimizationPage;
  TraceabilityPage *mpTraceabilityPage;
  QSettings *mpSettings;
  QListWidget *mpOptionsList;
  QStackedWidget *mpPagesWidget;
  Label *mpChangesEffectLabel;
  QPushButton *mpCancelButton;
  QPushButton *mpOkButton;
  QPushButton *mpResetButton;
  QDialogButtonBox *mpButtonBox;
};

class CodeColorsWidget : public QWidget
{
  Q_OBJECT
public:
  CodeColorsWidget(QWidget *pParent = 0);
  QListWidget* getItemsListWidget() {return mpItemsListWidget;}
  PreviewPlainTextEdit* getPreviewPlainTextEdit() {return mpPreviewPlainTextEdit;}
private:
  QGroupBox *mpColorsGroupBox;
  Label *mpItemsLabel;
  QListWidget *mpItemsListWidget;
  Label *mpItemColorLabel;
  QPushButton *mpItemColorPickButton;
  Label *mpPreviewLabel;
  PreviewPlainTextEdit *mpPreviewPlainTextEdit;
  ListWidgetItem *mpTextItem;
  ListWidgetItem *mpNumberItem;
  ListWidgetItem *mpKeywordItem;
  ListWidgetItem *mpTypeItem;
  ListWidgetItem *mpFunctionItem;
  ListWidgetItem *mpQuotesItem;
  ListWidgetItem *mpCommentItem;
signals:
  void colorUpdated();
private slots:
  void pickColor();
};

class GeneralSettingsPage : public QWidget
{
  Q_OBJECT
public:
  enum AccessAnnotations {
    Always = 0,
    Loading = 1,
    Never = 2
  };
  GeneralSettingsPage(OptionsDialog *pOptionsDialog);
  ComboBox* getLanguageComboBox() {return mpLanguageComboBox;}
  void setWorkingDirectory(QString value) {mpWorkingDirectoryTextBox->setText(value);}
  QString getWorkingDirectory();
  SpinBox* getToolbarIconSizeSpinBox() {return mpToolbarIconSizeSpinBox;}
  void setPreserveUserCustomizations(bool value) {mpPreserveUserCustomizations->setChecked(value);}
  bool getPreserveUserCustomizations() {return mpPreserveUserCustomizations->isChecked();}
  void setTerminalCommand(QString value) {mpTerminalCommandTextBox->setText(value);}
  QString getTerminalCommand() {return mpTerminalCommandTextBox->text();}
  void setTerminalCommandArguments(QString value) {mpTerminalCommandArgumentsTextBox->setText(value);}
  QString getTerminalCommandArguments() {return mpTerminalCommandArgumentsTextBox->text();}
  QCheckBox* getHideVariablesBrowserCheckBox() {return mpHideVariablesBrowserCheckBox;}
  ComboBox* getActivateAccessAnnotationsComboBox() {return mpActivateAccessAnnotationsComboBox;}
  QCheckBox* getCreateBackupFileCheckbox() {return mpCreateBackupFileCheckbox;}
  QCheckBox* getDisplayNFAPIErrorsWarningsCheckBox() {return mpDisplayNFAPIErrorsWarningsCheckBox;}
  SpinBox* getLibraryIconSizeSpinBox() {return mpLibraryIconSizeSpinBox;}
  SpinBox* getLibraryIconTextLengthSpinBox() {return mpLibraryIconTextLengthSpinBox;}
  void setShowProtectedClasses(bool value) {mpShowProtectedClasses->setChecked(value);}
  bool getShowProtectedClasses() {return mpShowProtectedClasses->isChecked();}
  void setShowHiddenClasses(bool value) {mpShowHiddenClasses->setChecked(value);}
  bool getShowHiddenClasses() {return mpShowHiddenClasses->isChecked();}
  QCheckBox* getSynchronizeWithModelWidgetCheckBox() {return mpSynchronizeWithModelWidgetCheckBox;}
  QGroupBox* getEnableAutoSaveGroupBox() {return mpEnableAutoSaveGroupBox;}
  SpinBox* getAutoSaveIntervalSpinBox() {return mpAutoSaveIntervalSpinBox;}
  int getWelcomePageView();
  void setWelcomePageView(int view);
  QCheckBox* getShowLatestNewsCheckBox() {return mpShowLatestNewsCheckBox;}
  SpinBox* getRecentFilesAndLatestNewsSizeSpinBox() {return mpRecentFilesAndLatestNewsSizeSpinBox;}
protected:
  QCheckBox* getEnableCRMLSupportCheckBox() {return mpEnableCRMLSupportCheckBox;}
private:
  friend class OptionsDialog;
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpGeneralSettingsGroupBox;
  Label *mpLanguageLabel;
  ComboBox *mpLanguageComboBox;
  Label *mpWorkingDirectoryLabel;
  QLineEdit *mpWorkingDirectoryTextBox;
  QPushButton *mpWorkingDirectoryBrowseButton;
  Label *mpToolbarIconSizeLabel;
  SpinBox *mpToolbarIconSizeSpinBox;
  QCheckBox *mpPreserveUserCustomizations;
  Label *mpTerminalCommandLabel;
  QLineEdit *mpTerminalCommandTextBox;
  QPushButton *mpTerminalCommandBrowseButton;
  Label *mpTerminalCommandArgumentsLabel;
  QLineEdit *mpTerminalCommandArgumentsTextBox;
  QCheckBox *mpHideVariablesBrowserCheckBox;
  Label *mpActivateAccessAnnotationsLabel;
  ComboBox *mpActivateAccessAnnotationsComboBox;
  QCheckBox *mpCreateBackupFileCheckbox;
  QCheckBox *mpDisplayNFAPIErrorsWarningsCheckBox;
  QCheckBox *mpEnableCRMLSupportCheckBox;
  QGroupBox *mpLibraryBrowserGroupBox;
  Label *mpLibraryIconSizeLabel;
  SpinBox *mpLibraryIconSizeSpinBox;
  Label *mpLibraryIconTextLengthLabel;
  SpinBox *mpLibraryIconTextLengthSpinBox;
  QCheckBox *mpShowProtectedClasses;
  QCheckBox *mpShowHiddenClasses;
  QCheckBox *mpSynchronizeWithModelWidgetCheckBox;
  QGroupBox *mpEnableAutoSaveGroupBox;
  Label *mpAutoSaveIntervalLabel;
  SpinBox *mpAutoSaveIntervalSpinBox;
  Label *mpAutoSaveSecondsLabel;
  QGroupBox *mpWelcomePageGroupBox;
  QRadioButton *mpHorizontalViewRadioButton;
  QRadioButton *mpVerticalViewRadioButton;
  QCheckBox *mpShowLatestNewsCheckBox;
  SpinBox *mpRecentFilesAndLatestNewsSizeSpinBox;
public slots:
  void selectWorkingDirectory();
  void selectTerminalCommand();
  void autoSaveIntervalValueChanged(int value);
};

class LibrariesPage : public QWidget
{
  Q_OBJECT
public:
  LibrariesPage(OptionsDialog *pOptionsDialog);
  QLineEdit *getModelicaPathTextBox() const {return mpModelicaPathTextBox;}
  QCheckBox *getLoadLatestModelicaCheckbox() const {return mpLoadLatestModelicaCheckbox;}
  QTreeWidget* getSystemLibrariesTree() {return mpSystemLibrariesTree;}
  QTreeWidget* getUserLibrariesTree() {return mpUserLibrariesTree;}
  OptionsDialog *mpOptionsDialog;
private:
  QGroupBox *mpSystemLibrariesGroupBox;
  Label *mpModelicaPathLabel;
  QLineEdit *mpModelicaPathTextBox;
  QPushButton *mpModelicaPathBrowseButton;
  Label *mpSystemLibrariesNoteLabel;
  QCheckBox *mpLoadLatestModelicaCheckbox;
  QTreeWidget *mpSystemLibrariesTree;
  QPushButton *mpAddSystemLibraryButton;
  QPushButton *mpRemoveSystemLibraryButton;
  QPushButton *mpEditSystemLibraryButton;
  QDialogButtonBox *mpSystemLibrariesButtonBox;
  QGroupBox *mpUserLibrariesGroupBox;
  QTreeWidget *mpUserLibrariesTree;
  QPushButton *mpAddUserLibraryButton;
  QPushButton *mpRemoveUserLibraryButton;
  QPushButton *mpEditUserLibraryButton;
  QDialogButtonBox *mpUserLibrariesButtonBox;
private slots:
  void selectModelicaPath();
  void openAddSystemLibrary();
  void removeSystemLibrary();
  void openEditSystemLibrary();
  void openAddUserLibrary();
  void removeUserLibrary();
  void openEditUserLibrary();
};

class AddSystemLibraryDialog : public QDialog
{
  Q_OBJECT
public:
  AddSystemLibraryDialog(LibrariesPage *pLibrariesPage, bool editFlag = false);
  bool nameExists(QTreeWidgetItem *pItem = 0);
  QComboBox *getNameComboBox() const {return mpNameComboBox;}
  QComboBox *getVersionsComboBox() const {return mpVersionsComboBox;}
private:
  LibrariesPage *mpLibrariesPage;
  Label *mpNameLabel;
  QComboBox *mpNameComboBox;
  Label *mpValueLabel;
  QComboBox *mpVersionsComboBox;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QPushButton *mpInstallLibraryButton;
  QDialogButtonBox *mpButtonBox;
  bool mEditFlag;

  void getSystemLibraries();
private slots:
  void getLibraryVersions(int index);
  void addSystemLibrary();
  void openInstallLibraryDialog();
};

class AddUserLibraryDialog : public QDialog
{
  Q_OBJECT
public:
  AddUserLibraryDialog(LibrariesPage *pLibrariesPage);
  bool pathExists(QTreeWidgetItem *pItem = 0);

  LibrariesPage *mpLibrariesPage;
  Label *mpPathLabel;
  QLineEdit *mpPathTextBox;
  QPushButton *mpPathBrowseButton;
  Label *mpEncodingLabel;
  QComboBox *mpEncodingComboBox;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
  bool mEditFlag;
private slots:
  void browseUserLibraryPath();
  void addUserLibrary();
};

class TextEditorPage : public QWidget
{
  Q_OBJECT
public:
  TextEditorPage(OptionsDialog *pOptionsDialog);
  ComboBox *getLineEndingComboBox() {return mpLineEndingComboBox;}
  ComboBox *getBOMComboBox() {return mpBOMComboBox;}
  ComboBox *getTabPolicyComboBox() {return mpTabPolicyComboBox;}
  SpinBox *getTabSizeSpinBox() {return mpTabSizeSpinBox;}
  SpinBox *getIndentSpinBox() {return mpIndentSpinBox;}
  QGroupBox* getSyntaxHighlightingGroupBox() {return mpSyntaxHighlightingGroupBox;}
  QCheckBox* getAutoCompleteCheckBox() {return mpAutoCompleteCheckBox;}
  QCheckBox* getCodeFoldingCheckBox() {return mpCodeFoldingCheckBox;}
  QCheckBox* getMatchParenthesesCommentsQuotesCheckBox() {return mpMatchParenthesesCommentsQuotesCheckBox;}
  QCheckBox* getLineWrappingCheckbox() {return mpLineWrappingCheckbox;}
  QFontComboBox* getFontFamilyComboBox() {return mpFontFamilyComboBox;}
  DoubleSpinBox* getFontSizeSpinBox() {return mpFontSizeSpinBox;}
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpFormatGroupBox;
  Label *mpLineEndingLabel;
  ComboBox *mpLineEndingComboBox;
  Label *mpBOMLabel;
  ComboBox *mpBOMComboBox;
  QGroupBox *mpTabsAndIndentation;
  Label *mpTabPolicyLabel;
  ComboBox *mpTabPolicyComboBox;
  Label *mpTabSizeLabel;
  SpinBox *mpTabSizeSpinBox;
  Label *mpIndentSizeLabel;
  SpinBox *mpIndentSpinBox;
  QGroupBox *mpSyntaxHighlightAndTextWrappingGroupBox;
  QGroupBox *mpSyntaxHighlightingGroupBox;
  QGroupBox *mpAutoCompleteGroupBox;
  QCheckBox *mpAutoCompleteCheckBox;
  QCheckBox *mpCodeFoldingCheckBox;
  QCheckBox *mpMatchParenthesesCommentsQuotesCheckBox;
  QCheckBox *mpLineWrappingCheckbox;
  QGroupBox *mpFontGroupBox;
  Label *mpFontFamilyLabel;
  QFontComboBox *mpFontFamilyComboBox;
  Label *mpFontSizeLabel;
  DoubleSpinBox *mpFontSizeSpinBox;
};

class ModelicaEditorPage : public QWidget
{
  Q_OBJECT
public:
  ModelicaEditorPage(OptionsDialog *pOptionsDialog);
  OptionsDialog* getOptionsDialog() {return mpOptionsDialog;}
  QCheckBox *getPreserveTextIndentationCheckBox() {return mpPreserveTextIndentationCheckBox;}
  void setColor(QString item, QColor color);
  QColor getColor(QString item);
  void emitUpdatePreview() {emit updatePreview();}
private:
  OptionsDialog *mpOptionsDialog;
  QCheckBox *mpPreserveTextIndentationCheckBox;
  CodeColorsWidget *mpCodeColorsWidget;
signals:
  void updatePreview();
public slots:
  void setLineWrapping(bool enabled);
};

class MetaModelicaEditorPage : public QWidget
{
  Q_OBJECT
public:
  MetaModelicaEditorPage(OptionsDialog *pOptionsDialog);
  OptionsDialog* getOptionsDialog() {return mpOptionsDialog;}
  void setColor(QString item, QColor color);
  QColor getColor(QString item);
  void emitUpdatePreview() {emit updatePreview();}
private:
  OptionsDialog *mpOptionsDialog;
  CodeColorsWidget *mpCodeColorsWidget;
signals:
  void updatePreview();
public slots:
  void setLineWrapping(bool enabled);
};

class CRMLEditorPage : public QWidget
{
  Q_OBJECT
public:
  CRMLEditorPage(OptionsDialog *pOptionsDialog);
  OptionsDialog* getOptionsDialog() {return mpOptionsDialog;}
  void setColor(QString item, QColor color);
  QColor getColor(QString item);
  void emitUpdatePreview() {emit updatePreview();}
private:
  OptionsDialog *mpOptionsDialog;
  CodeColorsWidget *mpCodeColorsWidget;
signals:
  void updatePreview();
public slots:
  void setLineWrapping(bool enabled);
};

class MOSEditorPage : public QWidget
{
  Q_OBJECT
public:
  MOSEditorPage(OptionsDialog *pOptionsDialog);
  OptionsDialog* getOptionsDialog() {return mpOptionsDialog;}
  void setColor(QString item, QColor color);
  QColor getColor(QString item);
  void emitUpdatePreview() {emit updatePreview();}
private:
  OptionsDialog *mpOptionsDialog;
  CodeColorsWidget *mpCodeColorsWidget;
signals:
  void updatePreview();
public slots:
  void setLineWrapping(bool enabled);
};

class OMSimulatorEditorPage : public QWidget
{
  Q_OBJECT
public:
  OMSimulatorEditorPage(OptionsDialog *pOptionsDialog);
  OptionsDialog* getOptionsDialog() {return mpOptionsDialog;}
  void setColor(QString item, QColor color);
  QColor getColor(QString item);
  void emitUpdatePreview() {emit updatePreview();}
private:
  OptionsDialog *mpOptionsDialog;
  CodeColorsWidget *mpCodeColorsWidget;
signals:
  void updatePreview();
public slots:
  void setLineWrapping(bool enabled);
};

class CEditorPage : public QWidget
{
  Q_OBJECT
public:
  CEditorPage(OptionsDialog *pOptionsDialog);
  OptionsDialog* getOptionsDialog() {return mpOptionsDialog;}
  void setColor(QString item, QColor color);
  QColor getColor(QString item);
  void emitUpdatePreview() {emit updatePreview();}
private:
  OptionsDialog *mpOptionsDialog;
  CodeColorsWidget *mpCodeColorsWidget;
signals:
  void updatePreview();
public slots:
  void setLineWrapping(bool enabled);
};

class HTMLEditorPage : public QWidget
{
  Q_OBJECT
public:
  HTMLEditorPage(OptionsDialog *pOptionsDialog);
  OptionsDialog* getOptionsDialog() {return mpOptionsDialog;}
  void setColor(QString item, QColor color);
  QColor getColor(QString item);
  void emitUpdatePreview() {emit updatePreview();}
private:
  OptionsDialog *mpOptionsDialog;
  CodeColorsWidget *mpCodeColorsWidget;
signals:
  void updatePreview();
public slots:
  void setLineWrapping(bool enabled);
};

class GraphicalViewsPage : public QWidget
{
  Q_OBJECT
public:
  GraphicalViewsPage(OptionsDialog *pOptionsDialog);
  void setModelingViewMode(QString value);
  QString getModelingViewMode();
  void setDefaultView(QString value);
  QString getDefaultView();
  QCheckBox *getMoveConnectorsTogetherCheckBox() const {return mpMoveConnectorsTogetherCheckBox;}
  void setIconViewExtentLeft(double extentLeft);
  double getIconViewExtentLeft();
  void setIconViewExtentBottom(double extentBottom);
  double getIconViewExtentBottom();
  void setIconViewExtentRight(double extentRight);
  double getIconViewExtentRight();
  void setIconViewExtentTop(double extentTop);
  double getIconViewExtentTop();
  void setIconViewGridHorizontal(double gridHorizontal);
  double getIconViewGridHorizontal();
  void setIconViewGridVertical(double gridVertical);
  double getIconViewGridVertical();
  void setIconViewScaleFactor(double scaleFactor);
  double getIconViewScaleFactor();
  void setIconViewPreserveAspectRation(bool preserveAspectRation);
  bool getIconViewPreserveAspectRation();
  void setDiagramViewExtentLeft(double extentLeft);
  double getDiagramViewExtentLeft();
  void setDiagramViewExtentBottom(double extentBottom);
  double getDiagramViewExtentBottom();
  void setDiagramViewExtentRight(double extentRight);
  double getDiagramViewExtentRight();
  void setDiagramViewExtentTop(double extentTop);
  double getDiagramViewExtentTop();
  void setDiagramViewGridHorizontal(double gridHorizontal);
  double getDiagramViewGridHorizontal();
  void setDiagramViewGridVertical(double gridVertical);
  double getDiagramViewGridVertical();
  void setDiagramViewScaleFactor(double scaleFactor);
  double getDiagramViewScaleFactor();
  void setDiagramViewPreserveAspectRation(bool preserveAspectRation);
  bool getDiagramViewPreserveAspectRation();
private:
  OptionsDialog *mpOptionsDialog;
  QRadioButton *mpModelingTabbedViewRadioButton;
  QRadioButton *mpModelingSubWindowViewRadioButton;
  QRadioButton *mpIconViewRadioButton;
  QRadioButton *mpDiagramViewRadioButton;
  QRadioButton *mpTextViewRadioButton;
  QRadioButton *mpDocumentationViewRadioButton;
  QCheckBox *mpMoveConnectorsTogetherCheckBox;
};

class SimulationPage : public QWidget
{
  Q_OBJECT
public:
  SimulationPage(OptionsDialog *pOptionsDialog);
  TranslationFlagsWidget *getTranslationFlagsWidget() const {return mpTranslationFlagsWidget;}
  ComboBox* getTargetLanguageComboBox() {return mpTargetLanguageComboBox;}
  ComboBox* getTargetBuildComboBox() {return mpTargetBuildComboBox;}
  ComboBox* getCompilerComboBox() {return mpCompilerComboBox;}
  ComboBox* getCXXCompilerComboBox() {return mpCXXCompilerComboBox;}
#ifdef Q_OS_WIN
  QCheckBox* getUseStaticLinkingCheckBox() {return mpUseStaticLinkingCheckBox;}
#endif
  void setPostCompilationCommand(const QString & cmd) {mpPostCompilationCommandLineEdit->setText(cmd);}
  QString getPostCompilationCommand() {return mpPostCompilationCommandLineEdit->text().trimmed();}
  QCheckBox* getIgnoreCommandLineOptionsAnnotationCheckBox() {return mpIgnoreCommandLineOptionsAnnotationCheckBox;}
  QCheckBox* getIgnoreSimulationFlagsAnnotationCheckBox() {return mpIgnoreSimulationFlagsAnnotationCheckBox;}
  QCheckBox* getSaveClassBeforeSimulationCheckBox() {return mpSaveClassBeforeSimulationCheckBox;}
  QCheckBox* getSwitchToPlottingPerspectiveCheckBox() {return mpSwitchToPlottingPerspectiveCheckBox;}
  QCheckBox* getCloseSimulationOutputWidgetsBeforeSimulationCheckBox() {return mpCloseSimulationOutputWidgetsBeforeSimulationCheckBox;}
  QCheckBox* getDeleteIntermediateCompilationFilesCheckBox() {return mpDeleteIntermediateCompilationFilesCheckBox;}
  QCheckBox* getDeleteEntireSimulationDirectoryCheckBox() {return mpDeleteEntireSimulationDirectoryCheckBox;}
  void setOutputMode(QString value);
  QString getOutputMode();
  SpinBox* getDisplayLimitSpinBox() {return mpDisplayLimitSpinBox;}
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpSimulationGroupBox;
  QGroupBox *mpTranslationFlagsGroupBox;
  TranslationFlagsWidget *mpTranslationFlagsWidget;
  Label *mpTargetLanguageLabel;
  ComboBox *mpTargetLanguageComboBox;
  Label *mpTargetBuildLabel;
  ComboBox *mpTargetBuildComboBox;
  Label *mpCompilerLabel;
  ComboBox *mpCompilerComboBox;
  Label *mpCXXCompilerLabel;
  ComboBox *mpCXXCompilerComboBox;
#ifdef Q_OS_WIN
  QCheckBox *mpUseStaticLinkingCheckBox;
#endif
  QLineEdit *mpPostCompilationCommandLineEdit;
  QCheckBox *mpIgnoreCommandLineOptionsAnnotationCheckBox;
  QCheckBox *mpIgnoreSimulationFlagsAnnotationCheckBox;
  QCheckBox *mpSaveClassBeforeSimulationCheckBox;
  QCheckBox *mpSwitchToPlottingPerspectiveCheckBox;
  QCheckBox *mpCloseSimulationOutputWidgetsBeforeSimulationCheckBox;
  QCheckBox *mpDeleteIntermediateCompilationFilesCheckBox;
  QCheckBox *mpDeleteEntireSimulationDirectoryCheckBox;
  QGroupBox *mpOutputGroupBox;
  QRadioButton *mpStructuredRadioButton;
  QRadioButton *mpFormattedTextRadioButton;
  Label *mpDisplayLimitLabel;
  SpinBox *mpDisplayLimitSpinBox;
  Label *mpDisplayLimitMBLabel;
public slots:
  void targetBuildChanged(int index);
  void displayLimitValueChanged(int value);
};

class MessagesPage : public QWidget
{
  Q_OBJECT
public:
  MessagesPage(OptionsDialog *pOptionsDialog);
  SpinBox* getOutputSizeSpinBox() {return mpOutputSizeSpinBox;}
  QCheckBox* getResetMessagesNumberBeforeSimulationCheckBox() {return mpResetMessagesNumberBeforeSimulationCheckBox;}
  QCheckBox* getClearMessagesBrowserBeforeSimulationCheckBox() {return mpClearMessagesBrowserBeforeSimulationCheckBox;}
  QCheckBox* getEnlargeMessageBrowserCheckBox() {return mpEnlargeMessageBrowserCheckBox;}
  QFontComboBox* getFontFamilyComboBox() {return mpFontFamilyComboBox;}
  DoubleSpinBox* getFontSizeSpinBox() {return mpFontSizeSpinBox;}
  void setNotificationColor(QColor color) {mNotificaitonColor = color;}
  QColor getNotificationColor() const {return mNotificaitonColor;}
  void setNotificationPickColorButtonIcon();
  void setWarningColor(QColor color) {mWarningColor = color;}
  QColor getWarningColor() const {return mWarningColor;}
  void setWarningPickColorButtonIcon();
  void setErrorColor(QColor color) {mErrorColor = color;}
  QColor getErrorColor() const {return mErrorColor;}
  void setErrorPickColorButtonIcon();
  QColor getColor(const StringHandler::SimulationMessageType type) const;
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpGeneralGroupBox;
  Label *mpOutputSizeLabel;
  SpinBox *mpOutputSizeSpinBox;
  QCheckBox *mpResetMessagesNumberBeforeSimulationCheckBox;
  QCheckBox *mpClearMessagesBrowserBeforeSimulationCheckBox;
  QCheckBox *mpEnlargeMessageBrowserCheckBox;
  QGroupBox *mpFontColorsGroupBox;
  Label *mpFontFamilyLabel;
  QFontComboBox *mpFontFamilyComboBox;
  Label *mpFontSizeLabel;
  DoubleSpinBox *mpFontSizeSpinBox;
  Label *mpNotificationColorLabel;
  QPushButton *mpNotificationColorButton;
  QColor mNotificaitonColor;
  Label *mpWarningColorLabel;
  QPushButton *mpWarningColorButton;
  QColor mWarningColor;
  Label *mpErrorColorLabel;
  QPushButton *mpErrorColorButton;
  QColor mErrorColor;
public slots:
  void pickNotificationColor();
  void pickWarningColor();
  void pickErrorColor();
};

class NotificationsPage : public QWidget
{
  Q_OBJECT
public:
  enum OldFrontend {
    AlwaysAskForOF = 0,
    TryOnceWithOF = 1,
    SwitchPermanentlyToOF = 2,
    KeepUsingNF = 3
  };
  NotificationsPage(OptionsDialog *pOptionsDialog);
  QCheckBox* getQuitApplicationCheckBox() {return mpQuitApplicationCheckBox;}
  QCheckBox* getItemDroppedOnItselfCheckBox() {return mpItemDroppedOnItselfCheckBox;}
  QCheckBox* getReplaceableIfPartialCheckBox() {return mpReplaceableIfPartialCheckBox;}
  QCheckBox* getInnerModelNameChangedCheckBox() {return mpInnerModelNameChangedCheckBox;}
  QCheckBox* getSaveModelForBitmapInsertionCheckBox() {return mpSaveModelForBitmapInsertionCheckBox;}
  QCheckBox* getAlwaysAskForDraggedComponentName() {return mpAlwaysAskForDraggedComponentName;}
  QCheckBox* getAlwaysAskForTextEditorErrorCheckBox() {return mpAlwaysAskForTextEditorErrorCheckBox;}
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpNotificationsGroupBox;
  QCheckBox *mpQuitApplicationCheckBox;
  QCheckBox *mpItemDroppedOnItselfCheckBox;
  QCheckBox *mpReplaceableIfPartialCheckBox;
  QCheckBox *mpInnerModelNameChangedCheckBox;
  QCheckBox *mpSaveModelForBitmapInsertionCheckBox;
  QCheckBox *mpAlwaysAskForDraggedComponentName;
  QCheckBox *mpAlwaysAskForTextEditorErrorCheckBox;
};

class LineStylePage : public QWidget
{
  Q_OBJECT
public:
  LineStylePage(OptionsDialog *pOptionsDialog);
  void setLineColor(QColor color);
  QColor getLineColor();
  void setLinePickColorButtonIcon();
  void setLinePattern(QString pattern);
  QString getLinePattern();
  void setLineThickness(qreal thickness);
  qreal getLineThickness();
  void setLineStartArrow(QString startArrow);
  QString getLineStartArrow();
  void setLineEndArrow(QString endArrow);
  QString getLineEndArrow();
  void setLineArrowSize(qreal size);
  qreal getLineArrowSize();
  void setLineSmooth(bool smooth);
  bool getLineSmooth();
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpLineStyleGroupBox;
  Label *mpLineColorLabel;
  QPushButton *mpLinePickColorButton;
  QColor mLineColor;
  Label *mpLinePatternLabel;
  ComboBox *mpLinePatternComboBox;
  Label *mpLineThicknessLabel;
  DoubleSpinBox *mpLineThicknessSpinBox;
  Label *mpLineStartArrowLabel;
  ComboBox *mpLineStartArrowComboBox;
  Label *mpLineEndArrowLabel;
  ComboBox *mpLineEndArrowComboBox;
  Label *mpLineArrowSizeLabel;
  DoubleSpinBox *mpLineArrowSizeSpinBox;
  Label *mpLineSmoothLabel;
  QCheckBox *mpLineSmoothCheckBox;
public slots:
  void linePickColor();
};

class FillStylePage : public QWidget
{
  Q_OBJECT
public:
  FillStylePage(OptionsDialog *pOptionsDialog);
  void setFillColor(QColor color);
  QColor getFillColor();
  void setFillPickColorButtonIcon();
  void setFillPattern(QString pattern);
  QString getFillPattern();
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpFillStyleGroupBox;
  Label *mpFillColorLabel;
  QPushButton *mpFillPickColorButton;
  QColor mFillColor;
  Label *mpFillPatternLabel;
  ComboBox *mpFillPatternComboBox;
public slots:
  void fillPickColor();
};

class PlottingPage : public QWidget
{
  Q_OBJECT
public:
  PlottingPage(OptionsDialog *pOptionsDialog);
  void setPlottingViewMode(QString value);
  QString getPlottingViewMode();
  QCheckBox* getAutoScaleCheckBox() {return mpAutoScaleCheckBox;}
  QCheckBox* getPrefixUnitsCheckbox() {return mpPrefixUnitsCheckbox;}
  void setCurvePattern(int pattern);
  int getCurvePattern();
  void setCurveThickness(qreal thickness);
  qreal getCurveThickness();
  SpinBox* getFilterIntervalSpinBox() {return mpFilterIntervalSpinBox;}
  DoubleSpinBox *getTitleFontSizeSpinBox() const {return mpTitleFontSizeSpinBox;}
  DoubleSpinBox *getVerticalAxisTitleFontSizeSpinBox() const {return mpVerticalAxisTitleFontSizeSpinBox;}
  DoubleSpinBox *getVerticalAxisNumbersFontSizeSpinBox() const {return mpVerticalAxisNumbersFontSizeSpinBox;}
  DoubleSpinBox *getHorizontalAxisTitleFontSizeSpinBox() const {return mpHorizontalAxisTitleFontSizeSpinBox;}
  DoubleSpinBox *getHorizontalAxisNumbersFontSizeSpinBox() const {return mpHorizontalAxisNumbersFontSizeSpinBox;}
  DoubleSpinBox *getFooterFontSizeSpinBox() const {return mpFooterFontSizeSpinBox;}
  DoubleSpinBox *getLegendFontSizeSpinBox() const {return mpLegendFontSizeSpinBox;}
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpGeneralGroupBox;
  QCheckBox *mpAutoScaleCheckBox;
  QCheckBox *mpPrefixUnitsCheckbox;
  QGroupBox *mpPlottingViewModeGroupBox;
  QRadioButton *mpPlottingTabbedViewRadioButton;
  QRadioButton *mpPlottingSubWindowViewRadioButton;
  QGroupBox *mpCurveStyleGroupBox;
  Label *mpCurvePatternLabel;
  ComboBox *mpCurvePatternComboBox;
  Label *mpCurveThicknessLabel;
  DoubleSpinBox *mpCurveThicknessSpinBox;
  QGroupBox *mpVariableFilterGroupBox;
  Label *mpFilterIntervalHelpLabel;
  Label *mpFilterIntervalLabel;
  SpinBox *mpFilterIntervalSpinBox;
  QGroupBox *mpFontSizeGroupBox;
  Label *mpTitleFontSizeLabel;
  DoubleSpinBox *mpTitleFontSizeSpinBox;
  Label *mpVerticalAxisTitleFontSizeLabel;
  DoubleSpinBox *mpVerticalAxisTitleFontSizeSpinBox;
  Label *mpVerticalAxisNumbersFontSizeLabel;
  DoubleSpinBox *mpVerticalAxisNumbersFontSizeSpinBox;
  Label *mpHorizontalAxisTitleFontSizeLabel;
  DoubleSpinBox *mpHorizontalAxisTitleFontSizeSpinBox;
  Label *mpHorizontalAxisNumbersFontSizeLabel;
  DoubleSpinBox *mpHorizontalAxisNumbersFontSizeSpinBox;
  Label *mpFooterFontSizeLabel;
  DoubleSpinBox *mpFooterFontSizeSpinBox;
  Label *mpLegendFontSizeLabel;
  DoubleSpinBox *mpLegendFontSizeSpinBox;
};

class FigaroPage : public QWidget
{
  Q_OBJECT
public:
  FigaroPage(OptionsDialog *pOptionsDialog);
  QLineEdit* getFigaroDatabaseFileTextBox() {return mpFigaroDatabaseFileTextBox;}
  QLineEdit* getFigaroOptionsTextBox() {return mpFigaroOptionsFileTextBox;}
  QLineEdit* getFigaroProcessTextBox() {return mpFigaroProcessTextBox;}
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpFigaroGroupBox;
  Label *mpFigaroDatabaseFileLabel;
  QLineEdit *mpFigaroDatabaseFileTextBox;
  QPushButton *mpBrowseFigaroDatabaseFileButton;
  Label *mpFigaroOptionsFileLabel;
  QLineEdit *mpFigaroOptionsFileTextBox;
  QPushButton *mpBrowseFigaroOptionsFileButton;
  Label *mpFigaroProcessLabel;
  QLineEdit *mpFigaroProcessTextBox;
  QPushButton *mpBrowseFigaroProcessButton;
  QPushButton *mpResetFigaroProcessButton;
private slots:
  void browseFigaroLibraryFile();
  void browseFigaroOptionsFile();
  void browseFigaroProcessFile();
  void resetFigaroProcessPath();
};

class DebuggerPage : public QWidget
{
  Q_OBJECT
public:
  DebuggerPage(OptionsDialog *pOptionsDialog);
  void setGDBPath(QString path);
  QString getGDBPath();
  QLineEdit* getGDBPathTextBox() {return mpGDBPathTextBox;}
  SpinBox* getGDBCommandTimeoutSpinBox() {return mpGDBCommandTimeoutSpinBox;}
  SpinBox* getGDBOutputLimitSpinBox() {return mpGDBOutputLimitSpinBox;}
  QCheckBox* getDisplayCFramesCheckBox() {return mpDisplayCFramesCheckBox;}
  QCheckBox* getDisplayUnknownFramesCheckBox() {return mpDisplayUnknownFramesCheckBox;}
  QCheckBox* getClearOutputOnNewRunCheckBox() {return mpClearOutputOnNewRunCheckBox;}
  QCheckBox* getClearLogOnNewRunCheckBox() {return mpClearLogOnNewRunCheckBox;}
  QCheckBox* getAlwaysShowTransformationsCheckBox() {return mpAlwaysShowTransformationsCheckBox;}
  QCheckBox* getGenerateOperationsCheckBox() {return mpGenerateOperationsCheckBox;}
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpAlgorithmicDebuggerGroupBox;
  Label *mpGDBPathLabel;
  QLineEdit *mpGDBPathTextBox;
  QPushButton *mpGDBPathBrowseButton;
  Label *mpGDBCommandTimeoutLabel;
  SpinBox *mpGDBCommandTimeoutSpinBox;
  Label *mpGDBOutputLimitLabel;
  SpinBox *mpGDBOutputLimitSpinBox;
  QCheckBox *mpDisplayCFramesCheckBox;
  QCheckBox *mpDisplayUnknownFramesCheckBox;
  QCheckBox *mpClearOutputOnNewRunCheckBox;
  QCheckBox *mpClearLogOnNewRunCheckBox;
  QGroupBox *mpTransformationalDebuggerGroupBox;
  QCheckBox *mpAlwaysShowTransformationsCheckBox;
  QCheckBox *mpGenerateOperationsCheckBox;
public slots:
  void browseGDBPath();
};

class FMIPage : public QWidget
{
  Q_OBJECT
public:
  FMIPage(OptionsDialog *pOptionsDialog);
  void setFMIExportVersion(QString version);
  QString getFMIExportVersion();
  void setFMIExportType(QString type);
  QString getFMIExportType();
  QString getFMIFlags();
  QLineEdit* getFMUNameTextBox() {return mpFMUNameTextBox;}
  QLineEdit* getMoveFMUTextBox() {return mpMoveFMUTextBox;}
  QGroupBox* getPlatformsGroupBox() {return mpPlatformsGroupBox;}
  ComboBox *getSolverForCoSimulationComboBox() const {return mpSolverForCoSimulationComboBox;}
  ComboBox *getModelDescriptionFiltersComboBox() const {return mpModelDescriptionFiltersComboBox;}
  QCheckBox *getIncludeResourcesCheckBox() const {return mpIncludeResourcesCheckBox;}
  QCheckBox *getIncludeSourceCodeCheckBox() const {return mpIncludeSourceCodeCheckBox;}
  QCheckBox *getGenerateDebugSymbolsCheckBox() const {return mpGenerateDebugSymbolsCheckBox;}
  QCheckBox* getDeleteFMUDirectoryAndModelCheckBox() {return mpDeleteFMUDirectoryAndModelCheckBox;}

  static const QString FMU_FULL_CLASS_NAME_DOTS_PLACEHOLDER;
  static const QString FMU_FULL_CLASS_NAME_UNDERSCORES_PLACEHOLDER;
  static const QString FMU_SHORT_CLASS_NAME_PLACEHOLDER;
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpExportGroupBox;
  QGroupBox *mpVersionGroupBox;
  QRadioButton *mpVersion1RadioButton;
  QRadioButton *mpVersion2RadioButton;
  QGroupBox *mpTypeGroupBox;
  QRadioButton *mpModelExchangeRadioButton;
  QRadioButton *mpCoSimulationRadioButton;
  QRadioButton *mpModelExchangeCoSimulationRadioButton;
  Label *mpFMUNameLabel;
  Label *mpMoveFMULabel;
  QLineEdit *mpFMUNameTextBox;
  QLineEdit *mpMoveFMUTextBox;
  QPushButton *mpBrowseFMUDirectoryButton;
  QGroupBox *mpPlatformsGroupBox;
  ComboBox *mpSolverForCoSimulationComboBox;
  ComboBox *mpModelDescriptionFiltersComboBox;
  QCheckBox *mpIncludeResourcesCheckBox;
  QCheckBox *mpIncludeSourceCodeCheckBox;
  QCheckBox *mpGenerateDebugSymbolsCheckBox;
  QGroupBox *mpImportGroupBox;
  QCheckBox *mpDeleteFMUDirectoryAndModelCheckBox;
public slots:
  void selectFMUDirectory();
  void enableIncludeSourcesCheckBox(int index);
};

class OMSimulatorPage : public QWidget
{
  Q_OBJECT
public:
  OMSimulatorPage(OptionsDialog *pOptionsDialog);
  ComboBox* getLoggingLevelComboBox() {return mpLoggingLevelComboBox;}
  QLineEdit* getCommandLineOptionsTextBox() {return mpCommandLineOptionsTextBox;}
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpGeneralGroupBox;
  Label *mpLoggingLevelLabel;
  ComboBox *mpLoggingLevelComboBox;
  Label *mpCommandLineOptionsLabel;
  QLineEdit *mpCommandLineOptionsTextBox;
};

class SensitivityOptimizationPage : public QWidget
{
  Q_OBJECT
public:
  SensitivityOptimizationPage(OptionsDialog *pOptionsDialog);
  QLineEdit *getOMSensBackendPathTextBox() const {return mpOMSensBackendPathTextBox;}
  QLineEdit *getPythonTextBox() const {return mpPythonTextBox;}
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpGeneralGroupBox;
  Label *mpOMSensBackendPathLabel;
  QLineEdit *mpOMSensBackendPathTextBox;
  QPushButton *mpOMSensBackendBrowseButton;
  Label *mpPythonLabel;
  QLineEdit *mpPythonTextBox;
  QPushButton *mpPythonBrowseButton;
private slots:
  void browseOMSensBackendPath();
  void browsePythonExecutable();
};

class TraceabilityPage : public QWidget
{
  Q_OBJECT
public:
  TraceabilityPage(OptionsDialog *pOptionsDialog);
  QGroupBox* getTraceabilityGroupBox() {return mpTraceabilityGroupBox;}
//  QLineEdit* getFMUOutputDirectory() {return mpFMUOutputDirectoryTextBox;}
//  QPushButton *mpBrowseFMUOutputDirectoryButton;
  QPushButton *mpBrowseGitRepositoryButton;
  QLineEdit* getTraceabilityDaemonIpAdress() {return mpTraceabilityDaemonIpAdressTextBox;}
  QLineEdit* getTraceabilityDaemonPort() {return mpTraceabilityDaemonPortTextBox;}
  QLineEdit* getUserName() {return mpUserNameTextBox;}
  QLineEdit* getEmail() {return mpEmailTextBox;}
  QLineEdit* getGitRepository() {return mpGitRepositoryTextBox;}
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpTraceabilityGroupBox;
  Label *mpUserNameLabel;
  QLineEdit *mpUserNameTextBox;
  Label *mpEmailLabel;
  QLineEdit *mpEmailTextBox;
  Label *mpGitRepositoryLabel;
  QLineEdit *mpGitRepositoryTextBox;
//  Label *mpFMUOutputDirectoryLabel;
//  QLineEdit *mpFMUOutputDirectoryTextBox;
  Label *mpTraceabilityDaemonIpAdressLabel;
  QLineEdit *mpTraceabilityDaemonIpAdressTextBox;
  Label *mpTraceabilityDaemonPortLabel;
  QLineEdit *mpTraceabilityDaemonPortTextBox;
private slots:
//  void browseFMUOutputDirectory();
  void browseGitRepository();

};

class DiscardLocalTranslationFlagsDialog : public QDialog
{
  Q_OBJECT
public:
  DiscardLocalTranslationFlagsDialog(QWidget *pParent = 0);
private:
  Label *mpDescriptionLabel;
  Label *mpDescriptionLabel2;
  QListWidget *mpClassesWithLocalTranslationFlagsListWidget;
  QPushButton *mpYesButton;
  QPushButton *mpNoButton;
  QDialogButtonBox *mpButtonBox;

  void listLocalTranslationFlagsClasses(LibraryTreeItem *pLibraryTreeItem);
private slots:
  void selectUnSelectAll(bool checked);
  void discardLocalTranslationFlags();
  void showLocalTranslationFlags(QListWidgetItem *pListWidgetItem);
public slots:
  int exec();
};

class CRMLPage : public QWidget
{
  Q_OBJECT
public:
  CRMLPage(OptionsDialog *pOptionsDialog);
  QLineEdit* getCompilerJarTextBox() {return mpCompilerJarTextBox;}
  QLineEdit* getCompilerCommandLineOptionsTextBox() {return mpCompilerCommandLineOptionsTextBox;}
  QLineEdit* getCompilerProcessTextBox() {return mpCompilerProcessTextBox;}
  DirectoryOrFileSelector* getModelicaLibraries() {return mpModelicaLibraries;}
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpCRMLGroupBox;
  Label *mpCompilerJarLabel;
  QLineEdit *mpCompilerJarTextBox;
  QPushButton *mpBrowseCompilerJarButton;
  QLineEdit *mpRepositoryDirectoryTextBox;
  Label *mpCompilerCommandLineOptionsLabel;
  QLineEdit *mpCompilerCommandLineOptionsTextBox;
  Label *mpCompilerProcessLabel;
  QLineEdit *mpCompilerProcessTextBox;
  QPushButton *mpBrowseCompilerProcessButton;
  QPushButton *mpResetCompilerProcessButton;
  DirectoryOrFileSelector *mpModelicaLibraries;
  DirectoryOrFileSelector *mpModelicaLibraryPaths;
private slots:
  void browseCompilerJar();
  void browseCompilerProcessFile();
  void resetCompilerProcessPath();
};

#endif // OPTIONSDIALOG_H
