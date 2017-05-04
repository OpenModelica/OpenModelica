/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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
class CompositeModelEditorPage;
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
class DebuggerPage;
class FMIPage;
class TLMPage;
class TraceabilityPage;
class TabSettings;
class StackFramesWidget;

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
  static OptionsDialog* instance() {return mpInstance;}
  void readSettings();
  void readGeneralSettings();
  void readLibrariesSettings();
  void readTextEditorSettings();
  void readModelicaEditorSettings();
  void readMetaModelicaEditorSettings();
  void readCompositeModelEditorSettings();
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
  void readDebuggerSettings();
  void readFMISettings();
  void readTLMSettings();
  void readTraceabilitySettings();
  void saveGeneralSettings();
  void saveLibrariesSettings();
  void saveTextEditorSettings();
  void saveModelicaEditorSettings();
  void saveMetaModelicaEditorSettings();
  void saveCompositeModelEditorSettings();
  void saveCEditorSettings();
  void saveHTMLEditorSettings();
  void saveTLMSettings();
  void saveTraceabilitySettings();
  void saveGraphicalViewsSettings();
  void saveSimulationSettings();
  void saveMessagesSettings();
  void saveNotificationsSettings();
  void saveLineStyleSettings();
  void saveFillStyleSettings();
  void savePlottingSettings();
  void saveFigaroSettings();
  void saveDebuggerSettings();
  void saveFMISettings();
  void setUpDialog();
  void addListItems();
  void createPages();
  GeneralSettingsPage* getGeneralSettingsPage() {return mpGeneralSettingsPage;}
  LibrariesPage* getLibrariesPage() {return mpLibrariesPage;}
  TextEditorPage* getTextEditorPage() {return mpTextEditorPage;}
  ModelicaEditorPage* getModelicaEditorPage() {return mpModelicaEditorPage;}
  MetaModelicaEditorPage* getMetaModelicaEditorPage() {return mpMetaModelicaEditorPage;}
  CompositeModelEditorPage* getCompositeModelEditorPage() {return mpCompositeModelEditorPage;}
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
  DebuggerPage* getDebuggerPage() {return mpDebuggerPage;}
  FMIPage* getFMIPage() {return mpFMIPage;}
  TLMPage* getTLMPage() {return mpTLMPage;}
  TraceabilityPage* getTraceabilityPage() {return mpTraceabilityPage;}
  void emitModelicaEditorSettingsChanged() {emit modelicaEditorSettingsChanged();}
  void saveDialogGeometry();
  void show();
  TabSettings getTabSettings();
signals:
  void textSettingsChanged();
  void modelicaEditorSettingsChanged();
  void metaModelicaEditorSettingsChanged();
  void compositeModelEditorSettingsChanged();
  void cEditorSettingsChanged();
  void HTMLEditorSettingsChanged();
public slots:
  void changePage(QListWidgetItem *current, QListWidgetItem *previous);
  void reject();
  void saveSettings();
private:
  GeneralSettingsPage *mpGeneralSettingsPage;
  LibrariesPage *mpLibrariesPage;
  TextEditorPage *mpTextEditorPage;
  ModelicaEditorPage *mpModelicaEditorPage;
  MetaModelicaEditorPage *mpMetaModelicaEditorPage;
  CompositeModelEditorPage *mpCompositeModelEditorPage;
  CEditorPage *mpCEditorPage;
  HTMLEditorPage *mpHTMLEditorPage;
  GraphicalViewsPage *mpGraphicalViewsPage;
  SimulationPage *mpSimulationPage;
  MessagesPage *mpMessagesPage;
  NotificationsPage *mpNotificationsPage;
  LineStylePage *mpLineStylePage;
  FillStylePage *mpFillStylePage;
  PlottingPage *mpPlottingPage;
  FigaroPage *mpFigaroPage;
  DebuggerPage *mpDebuggerPage;
  FMIPage *mpFMIPage;
  TLMPage *mpTLMPage;
  TraceabilityPage *mpTraceabilityPage;
  QSettings *mpSettings;
  QListWidget *mpOptionsList;
  QStackedWidget *mpPagesWidget;
  QScrollArea *mpPagesWidgetScrollArea;
  Label *mpChangesEffectLabel;
  QPushButton *mpCancelButton;
  QPushButton *mpOkButton;
  QDialogButtonBox *mpButtonBox;
};

class GeneralSettingsPage : public QWidget
{
  Q_OBJECT
public:
  GeneralSettingsPage(OptionsDialog *pOptionsDialog);
  QComboBox* getLanguageComboBox();
  void setWorkingDirectory(QString value);
  QString getWorkingDirectory();
  QSpinBox* getToolbarIconSizeSpinBox() {return mpToolbarIconSizeSpinBox;}
  void setPreserveUserCustomizations(bool value);
  bool getPreserveUserCustomizations();
  void setTerminalCommand(QString value) {mpTerminalCommandTextBox->setText(value);}
  QString getTerminalCommand() {return mpTerminalCommandTextBox->text();}
  void setTerminalCommandArguments(QString value) {mpTerminalCommandArgumentsTextBox->setText(value);}
  QString getTerminalCommandArguments() {return mpTerminalCommandArgumentsTextBox->text();}
  QCheckBox* getHideVariablesBrowserCheckBox() {return mpHideVariablesBrowserCheckBox;}
  QSpinBox* getLibraryIconSizeSpinBox() {return mpLibraryIconSizeSpinBox;}
  void setShowProtectedClasses(bool value);
  bool getShowProtectedClasses();
  void setModelingViewMode(QString value);
  QString getModelingViewMode();
  void setDefaultView(QString value);
  QString getDefaultView();
  QGroupBox* getEnableAutoSaveGroupBox() {return mpEnableAutoSaveGroupBox;}
  QSpinBox* getAutoSaveIntervalSpinBox() {return mpAutoSaveIntervalSpinBox;}
  int getWelcomePageView();
  void setWelcomePageView(int view);
  QCheckBox* getShowLatestNewsCheckBox() {return mpShowLatestNewsCheckBox;}
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpGeneralSettingsGroupBox;
  Label *mpLanguageLabel;
  QComboBox *mpLanguageComboBox;
  Label *mpWorkingDirectoryLabel;
  QLineEdit *mpWorkingDirectoryTextBox;
  QPushButton *mpWorkingDirectoryBrowseButton;
  Label *mpToolbarIconSizeLabel;
  QSpinBox *mpToolbarIconSizeSpinBox;
  QCheckBox *mpPreserveUserCustomizations;
  Label *mpTerminalCommandLabel;
  QLineEdit *mpTerminalCommandTextBox;
  QPushButton *mpTerminalCommandBrowseButton;
  Label *mpTerminalCommandArgumentsLabel;
  QLineEdit *mpTerminalCommandArgumentsTextBox;
  QCheckBox *mpHideVariablesBrowserCheckBox;
  QGroupBox *mpLibrariesBrowserGroupBox;
  Label *mpLibraryIconSizeLabel;
  QSpinBox *mpLibraryIconSizeSpinBox;
  QCheckBox *mpShowProtectedClasses;
  QGroupBox *mpModelingViewModeGroupBox;
  QRadioButton *mpModelingTabbedViewRadioButton;
  QRadioButton *mpModelingSubWindowViewRadioButton;
  QGroupBox *mpDefaultViewGroupBox;
  QRadioButton *mpIconViewRadioButton;
  QRadioButton *mpDiagramViewRadioButton;
  QRadioButton *mpTextViewRadioButton;
  QRadioButton *mpDocumentationViewRadioButton;
  QGroupBox *mpEnableAutoSaveGroupBox;
  Label *mpAutoSaveIntervalLabel;
  QSpinBox *mpAutoSaveIntervalSpinBox;
  Label *mpAutoSaveSecondsLabel;
  QGroupBox *mpWelcomePageGroupBox;
  QRadioButton *mpHorizontalViewRadioButton;
  QRadioButton *mpVerticalViewRadioButton;
  QCheckBox *mpShowLatestNewsCheckBox;
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
  QTreeWidget* getSystemLibrariesTree() {return mpSystemLibrariesTree;}
  QCheckBox* getForceModelicaLoadCheckBox() {return mpForceModelicaLoadCheckBox;}
  QCheckBox* getLoadOpenModelicaLibraryCheckBox() {return mpLoadOpenModelicaOnStartupCheckBox;}
  QTreeWidget* getUserLibrariesTree() {return mpUserLibrariesTree;}
  OptionsDialog *mpOptionsDialog;
private:
  QGroupBox *mpSystemLibrariesGroupBox;
  Label *mpSystemLibrariesNoteLabel;
  QTreeWidget *mpSystemLibrariesTree;
  QPushButton *mpAddSystemLibraryButton;
  QPushButton *mpRemoveSystemLibraryButton;
  QPushButton *mpEditSystemLibraryButton;
  QDialogButtonBox *mpSystemLibrariesButtonBox;
  QCheckBox *mpForceModelicaLoadCheckBox;
  QCheckBox *mpLoadOpenModelicaOnStartupCheckBox;
  QGroupBox *mpUserLibrariesGroupBox;
  QTreeWidget *mpUserLibrariesTree;
  QPushButton *mpAddUserLibraryButton;
  QPushButton *mpRemoveUserLibraryButton;
  QPushButton *mpEditUserLibraryButton;
  QDialogButtonBox *mpUserLibrariesButtonBox;
  Label *mpModelicaPathLabel;
private slots:
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
  AddSystemLibraryDialog(LibrariesPage *pLibrariesPage);
  bool nameExists(QTreeWidgetItem *pItem = 0);

  LibrariesPage *mpLibrariesPage;
  Label *mpNameLabel;
  QComboBox *mpNameComboBox;
  Label *mpValueLabel;
  QLineEdit *mpVersionTextBox;
  QPushButton *mpOkButton;
  bool mEditFlag;
private slots:
  void addSystemLibrary();
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
  QComboBox *getLineEndingComboBox() {return mpLineEndingComboBox;}
  QComboBox *getBOMComboBox() {return mpBOMComboBox;}
  QComboBox *getTabPolicyComboBox() {return mpTabPolicyComboBox;}
  QSpinBox *getTabSizeSpinBox() {return mpTabSizeSpinBox;}
  QSpinBox *getIndentSpinBox() {return mpIndentSpinBox;}
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
  QComboBox *mpLineEndingComboBox;
  Label *mpBOMLabel;
  QComboBox *mpBOMComboBox;
  QGroupBox *mpTabsAndIndentation;
  Label *mpTabPolicyLabel;
  QComboBox *mpTabPolicyComboBox;
  Label *mpTabSizeLabel;
  QSpinBox *mpTabSizeSpinBox;
  Label *mpIndentSizeLabel;
  QSpinBox *mpIndentSpinBox;
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

class CompositeModelEditorPage : public QWidget
{
  Q_OBJECT
public:
  CompositeModelEditorPage(OptionsDialog *pOptionsDialog);
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
  QTabWidget *mpGraphicalViewsTabWidget;
  QWidget *mpIconViewWidget;
  QGroupBox *mpIconViewExtentGroupBox;
  Label *mpIconViewLeftLabel;
  DoubleSpinBox *mpIconViewLeftSpinBox;
  Label *mpIconViewBottomLabel;
  DoubleSpinBox *mpIconViewBottomSpinBox;
  Label *mpIconViewRightLabel;
  DoubleSpinBox *mpIconViewRightSpinBox;
  Label *mpIconViewTopLabel;
  DoubleSpinBox *mpIconViewTopSpinBox;
  QGroupBox *mpIconViewGridGroupBox;
  Label *mpIconViewGridHorizontalLabel;
  DoubleSpinBox *mpIconViewGridHorizontalSpinBox;
  Label *mpIconViewGridVerticalLabel;
  DoubleSpinBox *mpIconViewGridVerticalSpinBox;
  QGroupBox *mpIconViewComponentGroupBox;
  Label *mpIconViewScaleFactorLabel;
  DoubleSpinBox *mpIconViewScaleFactorSpinBox;
  QCheckBox *mpIconViewPreserveAspectRatioCheckBox;
  QWidget *mpDiagramViewWidget;
  QGroupBox *mpDiagramViewExtentGroupBox;
  Label *mpDiagramViewLeftLabel;
  DoubleSpinBox *mpDiagramViewLeftSpinBox;
  Label *mpDiagramViewBottomLabel;
  DoubleSpinBox *mpDiagramViewBottomSpinBox;
  Label *mpDiagramViewRightLabel;
  DoubleSpinBox *mpDiagramViewRightSpinBox;
  Label *mpDiagramViewTopLabel;
  DoubleSpinBox *mpDiagramViewTopSpinBox;
  QGroupBox *mpDiagramViewGridGroupBox;
  Label *mpDiagramViewGridHorizontalLabel;
  DoubleSpinBox *mpDiagramViewGridHorizontalSpinBox;
  Label *mpDiagramViewGridVerticalLabel;
  DoubleSpinBox *mpDiagramViewGridVerticalSpinBox;
  QGroupBox *mpDiagramViewComponentGroupBox;
  Label *mpDiagramViewScaleFactorLabel;
  DoubleSpinBox *mpDiagramViewScaleFactorSpinBox;
  QCheckBox *mpDiagramViewPreserveAspectRatioCheckBox;
};

class SimulationPage : public QWidget
{
  Q_OBJECT
public:
  SimulationPage(OptionsDialog *pOptionsDialog);
  QComboBox* getMatchingAlgorithmComboBox() {return mpMatchingAlgorithmComboBox;}
  QComboBox* getIndexReductionMethodComboBox() {return mpIndexReductionMethodComboBox;}
  QComboBox* getTargetLanguageComboBox() {return mpTargetLanguageComboBox;}
  QComboBox* getTargetCompilerComboBox() {return mpTargetCompilerComboBox;}
  QLineEdit* getOMCFlagsTextBox() {return mpOMCFlagsTextBox;}
  QCheckBox* getIgnoreCommandLineOptionsAnnotationCheckBox() {return mpIgnoreCommandLineOptionsAnnotationCheckBox;}
  QCheckBox* getIgnoreSimulationFlagsAnnotationCheckBox() {return mpIgnoreSimulationFlagsAnnotationCheckBox;}
  QCheckBox* getSaveClassBeforeSimulationCheckBox() {return mpSaveClassBeforeSimulationCheckBox;}
  QCheckBox* getSwitchToPlottingPerspectiveCheckBox() {return mpSwitchToPlottingPerspectiveCheckBox;}
  QCheckBox* getCloseSimulationOutputWidgetsBeforeSimulationCheckBox() {return mpCloseSimulationOutputWidgetsBeforeSimulationCheckBox;}
  void setOutputMode(QString value);
  QString getOutputMode();
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpSimulationGroupBox;
  Label *mpMatchingAlgorithmLabel;
  QComboBox *mpMatchingAlgorithmComboBox;
  Label *mpIndexReductionMethodLabel;
  QComboBox *mpIndexReductionMethodComboBox;
  Label *mpTargetLanguageLabel;
  QComboBox *mpTargetLanguageComboBox;
  Label *mpCompilerLabel;
  QComboBox *mpTargetCompilerComboBox;
  Label *mpOMCFlagsLabel;
  QLineEdit *mpOMCFlagsTextBox;
  QToolButton *mpOMCFlagsHelpButton;
  QCheckBox *mpIgnoreCommandLineOptionsAnnotationCheckBox;
  QCheckBox *mpIgnoreSimulationFlagsAnnotationCheckBox;
  QCheckBox *mpSaveClassBeforeSimulationCheckBox;
  QCheckBox *mpSwitchToPlottingPerspectiveCheckBox;
  QCheckBox *mpCloseSimulationOutputWidgetsBeforeSimulationCheckBox;
  QGroupBox *mpOutputGroupBox;
  QRadioButton *mpStructuredRadioButton;
  QRadioButton *mpFormattedTextRadioButton;
public slots:
  void updateMatchingAlgorithmToolTip(int index);
  void updateIndexReductionToolTip(int index);
  void showOMCFlagsHelp();
};

class MessagesPage : public QWidget
{
  Q_OBJECT
public:
  MessagesPage(OptionsDialog *pOptionsDialog);
  QSpinBox* getOutputSizeSpinBox() {return mpOutputSizeSpinBox;}
  QCheckBox* getResetMessagesNumberBeforeSimulationCheckBox() {return mpResetMessagesNumberBeforeSimulationCheckBox;}
  QCheckBox* getClearMessagesBrowserBeforeSimulationCheckBox() {return mpClearMessagesBrowserBeforeSimulationCheckBox;}
  QFontComboBox* getFontFamilyComboBox() {return mpFontFamilyComboBox;}
  DoubleSpinBox* getFontSizeSpinBox() {return mpFontSizeSpinBox;}
  void setNotificationColor(QColor color) {mNotificaitonColor = color;}
  QColor getNotificationColor() {return mNotificaitonColor;}
  void setNotificationPickColorButtonIcon();
  void setWarningColor(QColor color) {mWarningColor = color;}
  QColor getWarningColor() {return mWarningColor;}
  void setWarningPickColorButtonIcon();
  void setErrorColor(QColor color) {mErrorColor = color;}
  QColor getErrorColor() {return mErrorColor;}
  void setErrorPickColorButtonIcon();
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpGeneralGroupBox;
  Label *mpOutputSizeLabel;
  QSpinBox *mpOutputSizeSpinBox;
  QCheckBox *mpResetMessagesNumberBeforeSimulationCheckBox;
  QCheckBox *mpClearMessagesBrowserBeforeSimulationCheckBox;
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
  NotificationsPage(OptionsDialog *pOptionsDialog);
  QCheckBox* getQuitApplicationCheckBox() {return mpQuitApplicationCheckBox;}
  QCheckBox* getItemDroppedOnItselfCheckBox() {return mpItemDroppedOnItselfCheckBox;}
  QCheckBox* getReplaceableIfPartialCheckBox() {return mpReplaceableIfPartialCheckBox;}
  QCheckBox* getInnerModelNameChangedCheckBox() {return mpInnerModelNameChangedCheckBox;}
  QCheckBox* getSaveModelForBitmapInsertionCheckBox() {return mpSaveModelForBitmapInsertionCheckBox;}
  QCheckBox* getAlwaysAskForDraggedComponentName() {return mpAlwaysAskForDraggedComponentName;}
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpNotificationsGroupBox;
  QCheckBox *mpQuitApplicationCheckBox;
  QCheckBox *mpItemDroppedOnItselfCheckBox;
  QCheckBox *mpReplaceableIfPartialCheckBox;
  QCheckBox *mpInnerModelNameChangedCheckBox;
  QCheckBox *mpSaveModelForBitmapInsertionCheckBox;
  QCheckBox *mpAlwaysAskForDraggedComponentName;
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
  QComboBox *mpLinePatternComboBox;
  Label *mpLineThicknessLabel;
  DoubleSpinBox *mpLineThicknessSpinBox;
  Label *mpLineStartArrowLabel;
  QComboBox *mpLineStartArrowComboBox;
  Label *mpLineEndArrowLabel;
  QComboBox *mpLineEndArrowComboBox;
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
  QComboBox *mpFillPatternComboBox;
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
  void setCurvePattern(int pattern);
  int getCurvePattern();
  void setCurveThickness(qreal thickness);
  qreal getCurveThickness();
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpGeneralGroupBox;
  QCheckBox *mpAutoScaleCheckBox;
  QGroupBox *mpPlottingViewModeGroupBox;
  QRadioButton *mpPlottingTabbedViewRadioButton;
  QRadioButton *mpPlottingSubWindowViewRadioButton;
  QGroupBox *mpCurveStyleGroupBox;
  Label *mpCurvePatternLabel;
  QComboBox *mpCurvePatternComboBox;
  Label *mpCurveThicknessLabel;
  DoubleSpinBox *mpCurveThicknessSpinBox;
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
  QString mFigaroProcessPath;
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
  QString getGDBPathForSettings() {return mpGDBPathTextBox->text();}
  QSpinBox* getGDBCommandTimeoutSpinBox() {return mpGDBCommandTimeoutSpinBox;}
  QSpinBox* getGDBOutputLimitSpinBox() {return mpGDBOutputLimitSpinBox;}
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
  QSpinBox *mpGDBCommandTimeoutSpinBox;
  Label *mpGDBOutputLimitLabel;
  QSpinBox *mpGDBOutputLimitSpinBox;
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
  void setFMIExportVersion(double version);
  double getFMIExportVersion();
  void setFMIExportType(QString type);
  QString getFMIExportType();
  QLineEdit* getFMUNameTextBox() {return mpFMUNameTextBox;}
  QGroupBox* getPlatformsGroupBox() {return mpPlatformsGroupBox;}
  QComboBox* getLinkingComboBox() {return mpLinkingComboBox;}
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
  QLineEdit *mpFMUNameTextBox;
  QGroupBox *mpPlatformsGroupBox;
  QComboBox *mpLinkingComboBox;
};

class TLMPage : public QWidget
{
  Q_OBJECT
public:
  TLMPage(OptionsDialog *pOptionsDialog);
  QLineEdit* getTLMPluginPathTextBox() {return mpTLMPluginPathTextBox;}
  QLineEdit* getTLMManagerProcessTextBox() {return mpTLMManagerProcessTextBox;}
  QLineEdit* getTLMMonitorProcessTextBox() {return mpTLMMonitorProcessTextBox;}
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpGeneralGroupBox;
  Label *mpTLMPluginPathLabel;
  QLineEdit *mpTLMPluginPathTextBox;
  QPushButton *mpBrowseTLMPluginPathButton;
  Label *mpTLMManagerProcessLabel;
  QLineEdit *mpTLMManagerProcessTextBox;
  QPushButton *mpBrowseTLMManagerProcessButton;
  Label *mpTLMMonitorProcessLabel;
  QLineEdit *mpTLMMonitorProcessTextBox;
  QPushButton *mpBrowseTLMMonitorProcessButton;
private slots:
  void browseTLMPluginPath();
  void browseTLMManagerProcess();
  void browseTLMMonitorProcess();
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

#endif // OPTIONSDIALOG_H
